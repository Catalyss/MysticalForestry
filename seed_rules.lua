local api = require("infusion_api")

local MOD_DATA = "mystical-forestry-seed-recipes"
local ING_SLOTS = { "ing_tl", "ing_tr", "ing_bl", "ing_br" }
local ESSENCE_SLOTS = { "essence_top", "essence_left", "essence_right", "essence_bottom" }

local M = {}

-- api slot patterns are Lua patterns: escape + anchor to get an exact match
local function escape(s)
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

local function exact(name, amount)
    return { name = "^" .. escape(name) .. "$", amount = amount }
end

-- Fluids can't go in the infuser: use the filled barrel from the base game's
-- "fill-<fluid>-barrel" recipe instead. Resolved at runtime so it works no
-- matter when the barrel recipes were generated in the data stage.
local function resolve_ingredient(ing)
    if ing.type ~= "fluid" then
        return ing.name, ing.amount
    end

    local recipe = prototypes.recipe["fill-" .. ing.name .. "-barrel"]
    if not recipe then
        return nil, "fluid '" .. ing.name .. "' has no barrel recipe"
    end

    local per_barrel, barrel
    for _, i in ipairs(recipe.ingredients) do
        if i.type == "fluid" and i.name == ing.name then per_barrel = i.amount end
    end
    for _, p in ipairs(recipe.products) do
        if p.type == "item" then barrel = p.name end
    end
    if not (per_barrel and barrel and per_barrel > 0) then
        return nil, "could not read barrel recipe for fluid '" .. ing.name .. "'"
    end

    return barrel, math.ceil(ing.amount / per_barrel)
end

local function build_rule(entry)
    local ingredients = entry.ingredients or {}
    if #ingredients > #ING_SLOTS then
        return nil, "more than " .. #ING_SLOTS .. " ingredients"
    end

    local rule = {
        return_item = entry.return_item,
        return_crystal = entry.return_crystal,
    }

    -- item slot
    if entry.item == false then
        rule.item = api.EMPTY
    elseif entry.item then
        rule.item = exact(entry.item.name, entry.item.amount)
    end

    -- crystal slot: false = must be empty, otherwise not used by the rule
    if entry.crystal == false then
        rule.crystal = api.EMPTY
    else
        rule.craft_use_crystal = false
    end

    -- essence slots: either one explicit essence in the top slot, or unused
    if entry.essence_top then
        rule.essence_top = exact(entry.essence_top.name, entry.essence_top.amount)
        for i = 2, #ESSENCE_SLOTS do rule[ESSENCE_SLOTS[i]] = api.EMPTY end
    else
        rule.craft_use_essence = false
    end

    -- ingredient slots (unused ones must be empty so we never collide with the
    -- 4-ingredient base rules)
    for i, slot in ipairs(ING_SLOTS) do
        local ing = ingredients[i]
        if ing then
            local name, amount = resolve_ingredient(ing)
            if not name then return nil, amount end
            rule[slot] = exact(name, amount)
        else
            rule[slot] = api.EMPTY
        end
    end

    return rule
end

function M.register()
    -- remove what we registered last time so re-running never duplicates
    storage.seed_rule_ids = storage.seed_rule_ids or {}
    for _, id in ipairs(storage.seed_rule_ids) do api.remove_rule(id) end
    storage.seed_rule_ids = {}

    local md = prototypes.mod_data[MOD_DATA]
    local added, skipped = 0, 0

    if md then
        for i, entry in ipairs(md.data.entries) do
            local rule, err = build_rule(entry)
            local id = rule and api.add_rule(rule)
            if id then
                table.insert(storage.seed_rule_ids, id)
                added = added + 1
            else
                skipped = skipped + 1
                local target = entry.return_item and (entry.return_item.name or "?") or "?"
                log(string.format("[MysticalForestry] seed rule #%d (-> %s) skipped: %s", i, target, tostring(err)))
            end
        end
    else
        log("[MysticalForestry] mod-data '" .. MOD_DATA .. "' not found, no seed rules registered")
    end

    log(string.format("[MysticalForestry] seed rules registered: %d added, %d skipped", added, skipped))

    -- dump every active infuser rule (base + custom) to factorio-current.log
    api.log_rules()
end

-- The infuser is scripted, so "craft-item" research triggers never fire for what
-- it produces. Call this for every item the infuser outputs to research the
-- technology that used to be triggered by crafting it.
function M.unlock_triggers(force, item_name)
    local md = prototypes.mod_data[MOD_DATA]
    local tech_name = md and md.data.trigger_techs and md.data.trigger_techs[item_name]
    local tech = tech_name and force.technologies[tech_name]
    if not tech or tech.researched then return end

    for _, prerequisite in pairs(tech.prerequisites) do
        if not prerequisite.researched then return end
    end
    tech.researched = true
end

return M
