-- infusion_api.lua
local base_rules = require("infusion")

local INTERFACE_NAME = "mystical-forestry-infusion"

local ALL_SLOT_KEYS = {
    "item", "crystal",
    "essence_top", "essence_left", "essence_right", "essence_bottom",
    "ing_tl", "ing_tr", "ing_bl", "ing_br",
}
local ESSENCE_KEYS = { "essence_top", "essence_left", "essence_right", "essence_bottom" }

local api = {}
local warned = {}

api.EMPTY = "\0__MYSTICAL_EMPTY__\0"

local function fail(reason)
    log("[MysticalForestry] infusion API: " .. reason)
    return false, reason
end

local function ensure_storage()
    storage.infusion_removed_base = storage.infusion_removed_base or {}
    storage.infusion_custom_rules = storage.infusion_custom_rules or {}
    storage.infusion_custom_next_id = storage.infusion_custom_next_id or 1
    return storage.infusion_removed_base, storage.infusion_custom_rules
end

local function clamp_to_stack(item_name, amount, context)
    local proto = prototypes.item[item_name]
    local size = proto and proto.stack_size or nil
    if size and amount > size then
        local key = context .. ":" .. item_name
        if not warned[key] then
            warned[key] = true
            log(string.format(
                "[MysticalForestry] %s wants %d x %s but its stack size is %d — clamped.",
                context, amount, item_name, size))
        end
        return size
    end
    return amount
end


local function name_matches(pattern_name, actual_name)
    if actual_name == pattern_name then return true end
    local ok, matched = pcall(string.match, actual_name, pattern_name)
    return ok and matched ~= nil
end

local function has_pattern_chars(s)
    return s:find("[%^%$%(%)%%%.%[%]%*%+%-%?]") ~= nil
end


local item_name_cache = {}
local sorted_item_names = nil

local function all_item_names_sorted()
    if sorted_item_names then return sorted_item_names end
    sorted_item_names = {}
    for name in pairs(prototypes.item) do
        table.insert(sorted_item_names, name)
    end
    table.sort(sorted_item_names)
    return sorted_item_names
end

local function resolve_item_name(pattern)
    if prototypes.item[pattern] then return pattern end -- fast path: exact name

    if item_name_cache[pattern] ~= nil then
        local cached = item_name_cache[pattern]
        return cached ~= false and cached or nil
    end

    for _, name in ipairs(all_item_names_sorted()) do
        local ok, matched = pcall(string.match, name, pattern)
        if ok and matched then
            item_name_cache[pattern] = name
            return name
        end
    end

    item_name_cache[pattern] = false
    if not warned["resolve:" .. pattern] then
        warned["resolve:" .. pattern] = true
        log("[MysticalForestry] output pattern '" .. pattern .. "' matched no known item.")
    end
    return nil
end

-- result-spec parsing (return_item / return_crystal)
-- Accepts, in order of precedence:
--   { name = pattern, amount = N }         -- simple single output (name may be regex)
--   "item-name" / "item-name,5" / "a,5-10" -- string DSL
--   "a,20%;b,80%" / "a,50%,5-10;b,50%,..." -- weighted string DSL
--   { { name=, weight=, min=, max= }, ... } -- weighted table DSL

local function parse_amount_token(token)
    local a, b = token:match("^(%d+)%-(%d+)$")
    if a then return tonumber(a), tonumber(b) end
    local n = token:match("^(%d+)$")
    if n then return tonumber(n), tonumber(n) end
    return nil
end

local function parse_result_string(spec)
    local options = {}
    local any_weight = false

    for entry in spec:gmatch("[^;]+") do
        local parts = {}
        for part in entry:gmatch("[^,]+") do
            table.insert(parts, part:match("^%s*(.-)%s*$"))
        end
        local name = parts[1]
        local min_amt, max_amt = 1, 1
        local weight = nil

        for i = 2, #parts do
            local p = parts[i]
            local w = p:match("^(%d+)%%$")
            if w then
                weight = tonumber(w)
                any_weight = true
            else
                local a, b = parse_amount_token(p)
                if a then min_amt, max_amt = a, b end
            end
        end

        table.insert(options, { name = name, min = min_amt, max = max_amt, weight = weight })
    end

    return options, any_weight
end

local function normalise_result(spec)
    if spec == nil then return nil end

    -- simple single-output shape: {name=pattern, amount=N}
    if type(spec) == "table" and spec.name and not spec[1] then
        local amt = spec.amount or 1
        return { weighted = false, options = { { name = spec.name, min = amt, max = amt, weight = nil } } }
    end

    local options, any_weight
    if type(spec) == "string" then
        options, any_weight = parse_result_string(spec)
    elseif type(spec) == "table" then
        options = {}
        any_weight = false
        for _, o in ipairs(spec) do
            local min_amt = o.min or o.amount or 1
            local max_amt = o.max or o.amount or min_amt
            table.insert(options, { name = o.name, min = min_amt, max = max_amt, weight = o.weight })
            if o.weight then any_weight = true end
        end
    else
        return nil
    end

    if any_weight then
        for _, o in ipairs(options) do
            if not o.weight then
                return nil, "all options need a weight when any option specifies one"
            end
        end
    end

    return { weighted = any_weight, options = options }
end

local function roll_result(result, context)
    if not result then return nil end

    local function finalize(o, amount)
        if amount <= 0 then return nil end
        local resolved = resolve_item_name(o.name)
        if not resolved then return nil end
        return { name = resolved, amount = clamp_to_stack(resolved, amount, context) }
    end

    if result.weighted then
        local total = 0
        for _, o in ipairs(result.options) do total = total + o.weight end
        if total > 100 then
            for _, o in ipairs(result.options) do o.weight = o.weight * 100 / total end
            total = 100
        end

        local roll = math.random() * 100
        local acc = 0
        for _, o in ipairs(result.options) do
            acc = acc + o.weight
            if roll <= acc then
                return finalize(o, math.random(o.min, o.max))
            end
        end
        return nil
    else
        if #result.options > 1 and not warned[context .. ":multi"] then
            warned[context .. ":multi"] = true
            log("[MysticalForestry] " .. context .. " has multiple un-weighted result options; only the first is used.")
        end
        local o = result.options[1]
        if not o then return nil end
        return finalize(o, math.random(o.min, o.max))
    end
end

local function match_field(pattern, entry, require_empty)
    if require_empty then
        return entry == nil
    end
    if pattern == nil then
        return true
    end
    if entry == nil then
        return false
    end
    return name_matches(pattern.name, entry.name) and entry.count >= (pattern.amount or 1)
end

-- Returns pattern, require_empty
local function effective_field(rule, key)
    local v = rule[key]

    local is_essence = false
    for _, k in ipairs(ESSENCE_KEYS) do if k == key then is_essence = true break end end
    local is_crystal_key = (key == "crystal")

    if v == api.EMPTY then return nil, true end
    if v ~= nil then return v, false end

    if is_essence then
        if rule.craft_use_essence == false then return nil, false end
        return { name = "^mystical%-agriculture%-.+%-essence$", amount = 1 }, false
    end
    if is_crystal_key then
        if rule.craft_use_crystal == false then return nil, false end
        return { name = "^mystical%-agriculture%-.+%-crystal$", amount = 1 }, false
    end

    return nil, false
end

local function rule_matches(rule, snapshot)
    for _, key in ipairs(ALL_SLOT_KEYS) do
        local pattern, require_empty = effective_field(rule, key)
        if not match_field(pattern, snapshot[key], require_empty) then
            return false
        end
    end
    return true
end

local function rule_still_possible(rule, snapshot)
    for _, key in ipairs(ALL_SLOT_KEYS) do
        local pattern, require_empty = effective_field(rule, key)
        local entry = snapshot[key]
        if require_empty then
            if entry ~= nil then return false end
        elseif pattern ~= nil then
            if entry ~= nil and not match_field(pattern, entry, false) then
                return false
            end
        end
    end
    return true
end

local function specificity(rule)
    local score = 0
    for _, key in ipairs(ALL_SLOT_KEYS) do
        local pattern, require_empty = effective_field(rule, key)
        if require_empty then
            score = score + 2
        elseif type(pattern) == "table" then
            score = score + (has_pattern_chars(pattern.name) and 1 or 3)
        end
    end
    return score
end

local function required_amount(pattern)
    if type(pattern) == "table" then return pattern.amount or 1 end
    return 0
end

local function each_rule(callback)
    local removed_base = ensure_storage()
    for i, rule in ipairs(base_rules) do
        local id = "base:" .. i
        if not removed_base[id] then callback(id, rule) end
    end
    local _, custom = ensure_storage()
    for id, rule in pairs(custom) do
        callback(id, rule)
    end
end

function api.get_rule(id)
    if id:match("^base:") then
        local i = tonumber(id:match("^base:(%d+)$"))
        return base_rules[i]
    end
    local _, custom = ensure_storage()
    return custom[id]
end

function api.find_rule(snapshot)
    local matches = {}
    each_rule(function(id, rule)
        if rule_matches(rule, snapshot) then
            table.insert(matches, { id = id, rule = rule, score = specificity(rule) })
        end
    end)

    if #matches == 0 then return nil, nil end

    table.sort(matches, function(a, b) return a.score > b.score end)
    if #matches == 1 or matches[1].score > matches[2].score then
        return matches[1].id, matches[1].rule
    end

    local top = matches[1].score
    local tied = {}
    for _, m in ipairs(matches) do
        if m.score == top then table.insert(tied, m.id) end
    end
    return nil, tied
end

function api.candidate_rules(snapshot)
    local out = {}
    each_rule(function(id, rule)
        if rule_still_possible(rule, snapshot) then
            table.insert(out, { id = id, rule = rule })
        end
    end)
    return out
end

-- List of { key, name, amount } for every concrete requirement 
function api.unmet_requirements(rule, snapshot)
    local unmet = {}
    for _, key in ipairs(ALL_SLOT_KEYS) do
        local pattern, require_empty = effective_field(rule, key)
        if not require_empty and type(pattern) == "table" then
            local entry = snapshot[key]
            if not entry or not name_matches(pattern.name, entry.name) or entry.count < (pattern.amount or 1) then
                local resolved = resolve_item_name(pattern.name)
                if resolved then
                    table.insert(unmet, { key = key, name = resolved, amount = pattern.amount or 1 })
                end
            end
        end
    end
    return unmet
end

function api.item_allowed_in_slot(key, item_name)
    local allowed = false
    each_rule(function(id, rule)
        if allowed then return end
        local pattern, require_empty = effective_field(rule, key)
        if not require_empty and pattern ~= nil then
            if name_matches(pattern.name, item_name) then
                allowed = true
            end
        end
    end)
    return allowed
end

-- Sums required amounts by RESOLVED item name
function api.aggregate_requirements(rule, keys, snapshot)
    local totals = {}
    for _, key in ipairs(keys) do
        local pattern, require_empty = effective_field(rule, key)
        if not require_empty and type(pattern) == "table" then
            local entry = snapshot and snapshot[key]
            local name = entry and entry.name or nil
            if name then
                totals[name] = (totals[name] or 0) + (pattern.amount or 1)
            end
        end
    end
    return totals
end

function api.required_amount(pattern) return required_amount(pattern) end
function api.effective_field(rule, key) return effective_field(rule, key) end
function api.all_slot_keys() return ALL_SLOT_KEYS end

function api.get_return_item(rule) return normalise_result(rule.return_item) end
function api.get_return_crystal(rule) return normalise_result(rule.return_crystal) end
function api.roll(result, context) return roll_result(result, context) end

function api.add_rule(rule)
    if type(rule) ~= "table" then return fail("rule must be a table") end
    for _, key in ipairs(ALL_SLOT_KEYS) do
        local v = rule[key]
        if v ~= nil and v ~= api.EMPTY and type(v) ~= "table" then
            return fail("field '" .. key .. "' must be nil, EMPTY, or a table")
        end
    end
    local _, custom = ensure_storage()
    local id = "custom:" .. storage.infusion_custom_next_id
    storage.infusion_custom_next_id = storage.infusion_custom_next_id + 1
    custom[id] = rule
    return id
end

function api.remove_rule(id)
    if type(id) ~= "string" then return fail("id must be a string") end
    if id:match("^base:") then
        local removed_base = ensure_storage()
        removed_base[id] = true
        return true
    end
    local _, custom = ensure_storage()
    if not custom[id] then return fail("no rule with id '" .. id .. "'") end
    custom[id] = nil
    return true
end

function api.list_rules()
    local out = {}
    each_rule(function(id, rule) out[id] = rule end)
    return out
end

local function readable_name(name)
    local inner = name:match("^%^(.*)%$$")
    if inner then
        local plain = (inner:gsub("%%(.)", "%1"))
        if prototypes.item[plain] then return plain end
    end
    return name
end

local function describe_field(rule, key)
    local pattern, require_empty = effective_field(rule, key)
    if require_empty then return key .. "=EMPTY" end
    if type(pattern) ~= "table" then return nil end -- unconstrained slot
    return string.format("%s=%s x%d", key, readable_name(pattern.name), pattern.amount or 1)
end

local function describe_result(spec)
    local result = normalise_result(spec)
    if not result then return "-" end
    local parts = {}
    for _, o in ipairs(result.options) do
        local text = resolve_item_name(o.name) or (o.name .. " (unresolved)")
        text = text .. (o.min == o.max and (" x" .. o.min) or (" x" .. o.min .. "-" .. o.max))
        if result.weighted then text = text .. " @" .. o.weight .. "%" end
        table.insert(parts, text)
    end
    return table.concat(parts, "; ")
end

function api.log_rules()
    local ids = {}
    each_rule(function(id) table.insert(ids, id) end)
    table.sort(ids, function(a, b)
        local pa, na = a:match("^(%a+):(%d+)$")
        local pb, nb = b:match("^(%a+):(%d+)$")
        if pa ~= pb then return pa < pb end
        return tonumber(na) < tonumber(nb)
    end)

    log(string.format("[MysticalForestry] infusion rules: %d active", #ids))
    for _, id in ipairs(ids) do
        local rule = api.get_rule(id)
        local inputs = {}
        for _, key in ipairs(ALL_SLOT_KEYS) do
            local d = describe_field(rule, key)
            if d then table.insert(inputs, d) end
        end
        log(string.format("[MysticalForestry]   %s: %s => item: %s | crystal: %s",
            id, table.concat(inputs, ", "), describe_result(rule.return_item), describe_result(rule.return_crystal)))
    end
end

remote.add_interface(INTERFACE_NAME, {
    add_rule              = api.add_rule,
    remove_rule           = api.remove_rule,
    get_rule              = api.get_rule,
    list_rules            = api.list_rules,
    item_allowed_in_slot  = api.item_allowed_in_slot,
})

return api