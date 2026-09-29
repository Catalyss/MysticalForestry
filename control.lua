script.on_event(defines.events.on_script_trigger_effect, function(event)
    if not event.effect_id then return end
    if string.find(event.effect_id, "MYSTICAL_CRYSTAL", 1, true) then
        local from_quality, to_quality =
            event.effect_id:match("{from=([^,]+),to=([^}]+)}MYSTICAL_CRYSTAL")

        if not from_quality or not to_quality then return end

        local new_item = {
            name = "mystical-agriculture-" .. to_quality .. "-crystal",
            count = 1,
            quality = "normal",
        }

        local entity = event.target_entity

        if not entity then
            game.surfaces[event.surface_index].spill_item_stack {
                position = event.target_position,
                stack = new_item
            }
            return
        end

        if entity.type == "character"
            or entity.type == "container"
            or entity.type == "agricultural-tower"
            or entity.type == "assembling-machine"
        then
            entity.insert(new_item)
        elseif entity.type == "construction-robot" then
            entity.get_inventory(defines.inventory.robot_cargo).insert(new_item)
        elseif entity.type == "inserter" then
            entity.held_stack.set_stack(new_item)
        elseif entity.type == "loader" then
            local line1 = entity.get_transport_line(1)
            if line1.can_insert_at_back() then
                line1.insert_at_back(new_item)
            else
                entity.get_transport_line(2).insert_at_back(new_item)
            end
        else
            entity.insert(new_item)
        end
        return
    end
    if string.find(event.effect_id, "MYSTICAL_SEED", 1, true) then
        local to_quality, item_name =
            event.effect_id:match("{to=([^,]+),item=([^}]+)}MYSTICAL_SEED")

        if not to_quality or not item_name then return end

        local new_item = {
            name = item_name,
            count = 1,
            quality = to_quality,
        }

        local entity = event.target_entity

        if not entity then
            game.surfaces[event.surface_index].spill_item_stack {
                position = event.target_position,
                stack = new_item
            }
            return
        end

        if entity.type == "character"
            or entity.type == "container"
            or entity.type == "agricultural-tower"
            or entity.type == "assembling-machine"
        then
            entity.insert(new_item)
        elseif entity.type == "construction-robot" then
            entity.get_inventory(defines.inventory.robot_cargo).insert(new_item)
        elseif entity.type == "inserter" then
            entity.held_stack.set_stack(new_item)
        elseif entity.type == "loader" then
            local line1 = entity.get_transport_line(1)
            if line1.can_insert_at_back() then
                line1.insert_at_back(new_item)
            else
                entity.get_transport_line(2).insert_at_back(new_item)
            end
        else
            entity.insert(new_item)
        end
        return
    end
end)

local infusion_api = require("infusion_api")

local INFUSER_NAME = "mystical-agriculture-essence-infuser"
local GUI_NAME = "mystical_infuser_gui"
local INFUSER_ESSENCE_PER_SLOT = 10
local INFUSER_CHECK_INTERVAL = 30
local INFUSER_SIGNAL_TRIGGER = { type = "virtual", name = "signal-S" }
local INFUSER_SIGNAL_READY = { type = "virtual", name = "signal-R" }
local INFUSER_SIGNAL_ENTITY = "mystical-agriculture-infuser-signal-combinator"

local RESERVED_CRYSTAL_INDEX = 1

local POOLED_ROLES = {
    "item",
    "essence_top", "essence_left", "essence_right", "essence_bottom",
    "ing_tl", "ing_tr", "ing_bl", "ing_br",
}
local ESSENCE_ROLES = { "essence_top", "essence_left", "essence_right", "essence_bottom" }
local ING_ROLES = { "ing_tl", "ing_tr", "ing_bl", "ing_br" }

local INFUSER_SLOT_SIZE = 64
local INFUSER_CENTER_SLOT_SIZE = 60
local INFUSER_CENTER_GAP = 8
local INFUSER_RADIUS = 140
local INFUSER_CANVAS_SIZE = 400
local INFUSER_BUTTON_ROW_HEIGHT = 20
local INFUSER_INVENTORY_SIZE = 420

local INFUSER_CANVAS_OFFSET_X = 500
local INFUSER_CANVAS_OFFSET_Y = 60

local CIRCLE_RING = {
    { key = "essence_top",    angle = 0   },
    { key = "ing_tr",         angle = 45  },
    { key = "essence_right",  angle = 90  },
    { key = "ing_br",         angle = 135 },
    { key = "essence_bottom", angle = 180 },
    { key = "ing_bl",         angle = 225 },
    { key = "essence_left",   angle = 270 },
    { key = "ing_tl",         angle = 315 },
}

local function circle_offset(angle_deg, radius)
    local rad = math.rad(angle_deg)
    return math.sin(rad) * radius, -math.cos(rad) * radius
end

local INFUSER_PLACEHOLDER_ESSENCE = "item/mystical-agriculture-normal-essence"
local INFUSER_PLACEHOLDER_CRYSTAL = "item/mystical-agriculture-normal-crystal"
local INFUSER_PLACEHOLDER_ANY = "mystical-forestry-placeholder-any"

local function is_essence(name)
    return name:match("^mystical%-agriculture%-.+%-essence$") ~= nil
end

local function is_crystal(name)
    return name == "mystical-agriculture-master-gaster-crystal"
        or name:match("^mystical%-agriculture%-.+%-crystal$") ~= nil
end

local function essence_quality(name)
    return name:match("^mystical%-agriculture%-(.+)%-essence$")
end

local function crystal_quality(name)
    if name == "mystical-agriculture-master-gaster-crystal" then
        return nil
    end
    return name:match("^mystical%-agriculture%-(.+)%-crystal$")
end

local function crystal_matches(essence_name, crystal_name)
    if crystal_name == "mystical-agriculture-master-gaster-crystal" then
        return true
    end
    local e = essence_quality(essence_name)
    local c = crystal_quality(crystal_name)
    return e ~= nil and c ~= nil and e == c
end

script.on_init(function()
    storage.infusers = {}
    storage.infuser_last_signal = {}
    storage.infuser_combinators = {}
    storage.infuser_selected_rule = {}
    -- [unit_number] = { [role] = { name = item_name, count = N } }
    storage.infuser_slot_types = {}
end)

local function get_assignments(unit_number)
    storage.infuser_slot_types[unit_number] = storage.infuser_slot_types[unit_number] or {}
    return storage.infuser_slot_types[unit_number]
end

local function link_combinator_to_red(entity, combinator)
    local ok, err = pcall(function()
        local entity_conn = entity.get_wire_connector(defines.wire_connector_id.circuit_red, true)
        local combinator_conn = combinator.get_wire_connector(defines.wire_connector_id.circuit_red, true)
        entity_conn.connect_to(combinator_conn, false)
    end)
    if not ok then
        log("[MysticalForestry] Failed to link infuser combinator to red wire: " .. tostring(err))
    end
end

local function register_infuser(entity)
    storage.infusers = storage.infusers or {}
    storage.infusers[entity.unit_number] = entity

    if prototypes.entity[INFUSER_SIGNAL_ENTITY] then
        local combinator = entity.surface.create_entity {
            name = INFUSER_SIGNAL_ENTITY,
            position = entity.position,
            force = entity.force,
        }
        storage.infuser_combinators = storage.infuser_combinators or {}
        storage.infuser_combinators[entity.unit_number] = combinator
        link_combinator_to_red(entity, combinator)
    end
end

local function unregister_infuser(unit_number)
    if storage.infusers then storage.infusers[unit_number] = nil end
    if storage.infuser_last_signal then storage.infuser_last_signal[unit_number] = nil end
    if storage.infuser_selected_rule then storage.infuser_selected_rule[unit_number] = nil end
    if storage.infuser_slot_types then storage.infuser_slot_types[unit_number] = nil end
    if storage.infuser_combinators then
        local combinator = storage.infuser_combinators[unit_number]
        if combinator and combinator.valid then combinator.destroy() end
        storage.infuser_combinators[unit_number] = nil
    end
end

local function on_entity_built(event)
    local entity = event.entity or event.created_entity
    if not entity or not entity.valid then return end
    if entity.name ~= INFUSER_NAME then return end
    register_infuser(entity)
end

script.on_event({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive,
}, on_entity_built)

local function on_entity_removed(event)
    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.name ~= INFUSER_NAME then return end
    unregister_infuser(entity.unit_number)
end

script.on_event({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
    defines.events.script_raised_destroy,
}, on_entity_removed)


local function insert_pooled(entity, role, item_name, count)
    local inv = entity.get_inventory(defines.inventory.chest)
    local assignments = get_assignments(entity.unit_number)
    local remaining = count
    local proto = prototypes.item[item_name]
    local max_stack = proto and proto.stack_size or count

    -- merge into existing matching stacks first
    for i = 2, #inv do -- index 1 reserved for crystal
        if remaining <= 0 then break end
        local s = inv[i]
        if s.valid_for_read and s.name == item_name then
            local space = max_stack - s.count
            if space > 0 then
                local add = math.min(space, remaining)
                s.count = s.count + add
                remaining = remaining - add
            end
        end
    end
    -- then fill empty slots
    for i = 2, #inv do
        if remaining <= 0 then break end
        local s = inv[i]
        if not s.valid_for_read then
            local add = math.min(max_stack, remaining)
            s.set_stack({ name = item_name, count = add })
            remaining = remaining - add
        end
    end

    local inserted = count - remaining
    if inserted > 0 then
        local entry = assignments[role]
        if not entry then
            entry = { name = item_name, count = 0 }
            assignments[role] = entry
        end
        entry.count = entry.count + inserted
    end
    return inserted
end

local function withdraw_pooled(entity, role)
    local assignments = get_assignments(entity.unit_number)
    local entry = assignments[role]
    if not entry then return nil, 0 end

    local proto = prototypes.item[entry.name]
    local max_stack = proto and proto.stack_size or 1
    local take = math.min(max_stack, entry.count)
    if take <= 0 then return nil, 0 end

    local inv = entity.get_inventory(defines.inventory.chest)
    inv.remove({ name = entry.name, count = take })
    entry.count = entry.count - take
    local name = entry.name
    if entry.count <= 0 then assignments[role] = nil end
    return name, take
end

local function consume_pooled(entity, role, amount)
    if amount <= 0 then return end
    local assignments = get_assignments(entity.unit_number)
    local entry = assignments[role]
    if not entry then return end
    local inv = entity.get_inventory(defines.inventory.chest)
    local actual = math.min(amount, entry.count)
    if actual <= 0 then return end
    inv.remove({ name = entry.name, count = actual })
    entry.count = entry.count - actual
    if entry.count <= 0 then assignments[role] = nil end
end

local find_recipe_for_item
local get_solid_ingredients
local check_ready
local check_ready_quality_upgrade
local attempt_craft
local validate_infuser_inventory
local gather_slot_snapshot

local function recipe_is_recycling(recipe)
    if recipe.categories then
        for _, cat in pairs(recipe.categories) do
            if cat == "recycling" then return true end
        end
    end
    return false
end

-- the fix for the essence-sharing bug.
gather_slot_snapshot = function(entity)
    local inv = entity.get_inventory(defines.inventory.chest)
    local assignments = get_assignments(entity.unit_number)
    local snapshot = {}

    local crystal_stack = inv[RESERVED_CRYSTAL_INDEX]
    snapshot.crystal = crystal_stack.valid_for_read and { name = crystal_stack.name, count = crystal_stack.count } or nil

    for _, role in ipairs(POOLED_ROLES) do
        local entry = assignments[role]
        if entry and entry.count > 0 then
            snapshot[role] = { name = entry.name, count = entry.count }
        else
            assignments[role] = nil
            snapshot[role] = nil
        end
    end

    return snapshot
end

find_recipe_for_item = function(force, item_name)
    local recipes = force.recipes

    local direct = recipes[item_name]
    if direct and direct.enabled and not recipe_is_recycling(direct) then
        for _, p in pairs(direct.products) do
            if p.type == "item" and p.name == item_name then
                return direct
            end
        end
    end

    for _, recipe in pairs(recipes) do
        if recipe.enabled and not recipe_is_recycling(recipe) then
            for _, p in pairs(recipe.products) do
                if p.type == "item" and p.name == item_name then
                    return recipe
                end
            end
        end
    end

    return nil
end

get_solid_ingredients = function(recipe)
    local list = {}
    for _, ing in pairs(recipe.ingredients) do
        if ing.type ~= "fluid" then
            table.insert(list, { name = ing.name, amount = ing.amount })
        end
    end
    return list
end

local function resolve_ingredients(force, item_name)
    local recipe = find_recipe_for_item(force, item_name)
    if recipe then return get_solid_ingredients(recipe) end
    return nil
end

-- quality-upgrade fallback, now batched
check_ready_quality_upgrade = function(entity)
    local inv = entity.get_inventory(defines.inventory.chest)
    local snapshot = gather_slot_snapshot(entity)

    local item_entry = snapshot.item
    if not item_entry then return false, "no-item" end
    local batch = item_entry.count
    if batch < 1 then return false, "no-item" end

    local ingredients = resolve_ingredients(entity.force, item_entry.name)
    if not ingredients then return false, "no-recipe" end
    if #ingredients > 4 then return false, "too-many-ingredients" end

    local used_roles = {}
    for _, req in ipairs(ingredients) do
        local needed = req.amount * batch
        local found = false
        for _, role in ipairs(ING_ROLES) do
            if not used_roles[role] then
                local entry = snapshot[role]
                if entry and entry.name == req.name and entry.count >= needed then
                    used_roles[role] = true
                    found = true
                    break
                end
            end
        end
        if not found then return false, "missing-ingredient:" .. req.name end
    end

    local essence_quality_name = nil
    for _, role in ipairs(ESSENCE_ROLES) do
        local entry = snapshot[role]
        if not entry or not is_essence(entry.name) then return false, "missing-essence" end
        local q = essence_quality(entry.name)
        if essence_quality_name == nil then
            essence_quality_name = q
        elseif essence_quality_name ~= q then
            return false, "mismatched-essence"
        end
        if entry.count < INFUSER_ESSENCE_PER_SLOT * batch then return false, "not-enough-essence" end
    end

    local crystal_entry = snapshot.crystal
    if not crystal_entry or not is_crystal(crystal_entry.name) then
        return false, "missing-crystal"
    end
    if not crystal_matches("mystical-agriculture-" .. essence_quality_name .. "-essence", crystal_entry.name) then
        return false, "crystal-mismatch"
    end

    local target_quality = prototypes.quality[essence_quality_name]
    if not target_quality then return false, "unknown-quality:" .. tostring(essence_quality_name) end

    -- Best-effort check: since the item role is pooled by NAME only
    local sample_quality = nil
    for i = 2, #inv do
        local s = inv[i]
        if s.valid_for_read and s.name == item_entry.name then
            sample_quality = s.quality
            break
        end
    end
    if sample_quality and sample_quality.level >= target_quality.level then
        return false, "item-already-at-or-above-target-quality"
    end

    return true, {
        ingredients = ingredients,
        batch = batch,
        essence_quality_name = essence_quality_name,
        target_quality = target_quality,
    }
end

--  dispatcher 
check_ready = function(entity)
    local inv = entity.get_inventory(defines.inventory.chest)
    if not inv then return false, "no-inventory" end

    local snapshot = gather_slot_snapshot(entity)
    local rule_id, rule_or_candidates = infusion_api.find_rule(snapshot)

    local function finalize_rule(id, rule)
        local totals = infusion_api.aggregate_requirements(rule, POOLED_ROLES, snapshot)
        for name, needed in pairs(totals) do
            local have = 0
            local assignments = get_assignments(entity.unit_number)
            for _, role in ipairs(POOLED_ROLES) do
                local entry = assignments[role]
                if entry and entry.name == name then have = have + entry.count end
            end
            if have < needed then return false, "insufficient-pooled:" .. name end
        end
        return true, { kind = "rule", rule_id = id, rule = rule }
    end

    if rule_id then
        return finalize_rule(rule_id, rule_or_candidates)
    elseif rule_or_candidates then
        local chosen = storage.infuser_selected_rule[entity.unit_number]
        for _, id in ipairs(rule_or_candidates) do
            if id == chosen then
                return finalize_rule(id, infusion_api.get_rule(id))
            end
        end
        return false, "ambiguous-recipe:" .. table.concat(rule_or_candidates, ",")
    end

    local ok, info = check_ready_quality_upgrade(entity)
    if not ok then return false, info end
    info.kind = "quality_upgrade"
    return true, info
end

attempt_craft = function(entity, player)
    local ok, info = check_ready(entity)
    if not ok then
        if player then
            player.create_local_flying_text {
                text = "Cannot craft: " .. tostring(info),
                create_at_cursor = true,
            }
        end
        return false
    end

    local inv = entity.get_inventory(defines.inventory.chest)
    local assignments = get_assignments(entity.unit_number)

    if info.kind == "quality_upgrade" then
        local batch = info.batch
        local item_entry = assignments.item
        local item_name = item_entry.name

        for _, req in ipairs(info.ingredients) do
            for _, role in ipairs(ING_ROLES) do
                local entry = assignments[role]
                if entry and entry.name == req.name then
                    consume_pooled(entity, role, req.amount * batch)
                    break
                end
            end
        end

        for _, role in ipairs(ESSENCE_ROLES) do
            consume_pooled(entity, role, INFUSER_ESSENCE_PER_SLOT * batch)
        end

        local crystal_stack = inv[RESERVED_CRYSTAL_INDEX]
        if crystal_stack.name ~= "mystical-agriculture-master-gaster-crystal" then
            crystal_stack.set_stack { name = "mystical-agriculture-normal-crystal", count = 1, quality = "normal" }
        end

        -- transform the whole batch in place to the target quality
        inv.remove({ name = item_name, count = batch })
        inv.insert({ name = item_name, count = batch, quality = info.target_quality.name })

        return true
    end

    -- info.kind == "rule"
    local rule = info.rule

    do
        local pattern, require_empty = infusion_api.effective_field(rule, "item")
        local amount = infusion_api.required_amount(pattern)
        if not require_empty and amount > 0 then
            consume_pooled(entity, "item", amount)
        end
    end

    do
        local pattern, require_empty = infusion_api.effective_field(rule, "crystal")
        local amount = infusion_api.required_amount(pattern)
        if not require_empty and amount > 0 then
            local s = inv[RESERVED_CRYSTAL_INDEX]
            if s.count > amount then s.count = s.count - amount else s.clear() end
        end
    end

    local totals = infusion_api.aggregate_requirements(rule, POOLED_ROLES, gather_slot_snapshot(entity))
    for name, amount in pairs(totals) do
        local remaining = amount
        for _, role in ipairs(POOLED_ROLES) do
            if remaining <= 0 then break end
            local entry = assignments[role]
            if entry and entry.name == name then
                local take = math.min(entry.count, remaining)
                consume_pooled(entity, role, take)
                remaining = remaining - take
            end
        end
    end

    if rule.craft_use_essence ~= false and rule.essence_top == nil then
        for _, role in ipairs(ESSENCE_ROLES) do
            consume_pooled(entity, role, INFUSER_ESSENCE_PER_SLOT)
        end
    end

    local return_item = infusion_api.get_return_item(rule)
    local rolled_item = infusion_api.roll(return_item, "return_item")
    if rolled_item then
        local quality_name = nil
        if rule.return_quality then
            local snapshot = gather_slot_snapshot(entity)
            local essence_entry = snapshot.essence_top
            if essence_entry then
                quality_name = essence_entry.name:match("^mystical%-agriculture%-(.+)%-essence$")
            end
        end
        if quality_name then
            inv.insert({ name = rolled_item.name, count = rolled_item.amount, quality = quality_name })
        else
            inv.insert({ name = rolled_item.name, count = rolled_item.amount })
        end
        local entry = assignments.item
        if not entry then entry = { name = rolled_item.name, count = 0 }; assignments.item = entry end
        if entry.name == rolled_item.name then
            entry.count = entry.count + rolled_item.amount
        else
            entry.name = rolled_item.name
            entry.count = rolled_item.amount
        end
    end

    local return_crystal = infusion_api.get_return_crystal(rule)
    local rolled_crystal = infusion_api.roll(return_crystal, "return_crystal")
    if rolled_crystal then
        inv[RESERVED_CRYSTAL_INDEX].set_stack({ name = rolled_crystal.name, count = rolled_crystal.amount, quality = "normal" })
    elseif rule.return_consumed_crystal and rule.craft_use_crystal ~= false then
        local crystal_stack = inv[RESERVED_CRYSTAL_INDEX]
        if crystal_stack.valid_for_read and crystal_stack.name ~= "mystical-agriculture-master-gaster-crystal" then
            crystal_stack.set_stack { name = "mystical-agriculture-normal-crystal", count = 1, quality = "normal" }
        end
    end

    storage.infuser_selected_rule[entity.unit_number] = nil
    return true
end

-- Overflow (unassigned physical items) is stuffed
validate_infuser_inventory = function(entity) end

script.on_nth_tick(INFUSER_CHECK_INTERVAL, function()
    if not storage.infusers then return end
    for unit_number, entity in pairs(storage.infusers) do
        if entity.valid then
            validate_infuser_inventory(entity)
        else
            unregister_infuser(unit_number)
        end
    end
end)

local function read_trigger_signal(entity)
    local network = entity.get_circuit_network(defines.wire_connector_id.circuit_green)
    if network then
        return network.get_signal(INFUSER_SIGNAL_TRIGGER) or 0
    end
    return 0
end

script.on_nth_tick(6, function()
    if not storage.infusers then return end
    storage.infuser_last_signal = storage.infuser_last_signal or {}

    for unit_number, entity in pairs(storage.infusers) do
        if entity.valid then
            local signal = read_trigger_signal(entity)
            local last = storage.infuser_last_signal[unit_number] or 0

            if signal > 0 and last <= 0 then
                attempt_craft(entity, nil)
            end

            storage.infuser_last_signal[unit_number] = signal

            local combinator = storage.infuser_combinators and storage.infuser_combinators[unit_number]
            if combinator and combinator.valid then
                local ready = check_ready(entity)
                local ok, cb = pcall(function() return combinator.get_or_create_control_behavior() end)
                if ok and cb then
                    local section = cb.get_section(1) or cb.add_section()
                    section.set_slot(1, { value = INFUSER_SIGNAL_READY, min = ready and 1 or 0 })
                end
            end
        else
            unregister_infuser(unit_number)
        end
    end
end)

local creating_gui = false
local open_infusers = {}
local infuser_slot_buttons = {}

local function bring_infuser_slots_to_front(player)
    local slot_buttons = infuser_slot_buttons[player.index]
    if not slot_buttons then return end
    for _, button in pairs(slot_buttons) do
        if button.valid then
            local ok, err = pcall(function() button.bring_to_front() end)
            if not ok then
                log("[MysticalForestry] bring_to_front failed: " .. tostring(err))
                break
            end
        end
    end
end

script.on_event(defines.events.on_tick, function()
    for player_index in pairs(open_infusers) do
        local player = game.players[player_index]
        if player and player.valid then
            bring_infuser_slots_to_front(player)
        end
    end
end)

-- Narrows acceptance to the currently-still-possible custom rules,
-- then falls back to the built-in quality-upgrade behavior

local function role_accepts(entity, role, item_name)
    if role == "crystal" then return is_crystal(item_name) end

    local snapshot = gather_slot_snapshot(entity)
    local candidates = infusion_api.candidate_rules(snapshot)

    for _, c in ipairs(candidates) do
        local pattern, require_empty = infusion_api.effective_field(c.rule, role)
        if not require_empty and pattern ~= nil then
            local ok
            if type(pattern) == "table" then
                ok = (pattern.name == item_name)
            elseif item_name == pattern then
                ok = true
            else
                local success, matched = pcall(string.match, item_name, pattern)
                ok = success and matched ~= nil
            end
            if ok then return true end
        end
    end

    if role:match("^essence_") then return is_essence(item_name) end
    if role == "item" then return true end
    if role:match("^ing_") then
        local item_entry = get_assignments(entity.unit_number).item
        if item_entry then
            local real_ings = resolve_ingredients(entity.force, item_entry.name)
            if real_ings then
                for _, ing in ipairs(real_ings) do
                    if ing.name == item_name then return true end
                end
            end
        end
    end
    return false
end

local function placeholder_for_role(role)
    if role == "crystal" then return INFUSER_PLACEHOLDER_CRYSTAL end
    if role:match("^essence_") then return INFUSER_PLACEHOLDER_ESSENCE end
    return INFUSER_PLACEHOLDER_ANY
end

local function placeholder_tooltip_for_role(role)
    if role == "item" then return "Place the item to infuse here (any quantity)" end
    if role == "crystal" then return "Place a quality crystal here" end
    if role:match("^essence_") then return "Assign an essence type here" end
    return "Assign an ingredient type here"
end

local function set_stack_sprite(button, stack)
    if not button or not button.valid then return end
    if stack and stack.valid_for_read then
        button.sprite = "item/" .. stack.name
        button.number = stack.count
        if stack.quality then
            button.tooltip = { "", stack.prototype.localised_name, " (", { "quality-name." .. stack.quality.name }, ")" }
        else
            button.tooltip = stack.prototype.localised_name
        end
    else
        button.sprite = placeholder_for_role("crystal")
        button.number = nil
        button.tooltip = placeholder_tooltip_for_role("crystal")
    end
end

local function set_pooled_sprite(button, role, name, count)
    if not button or not button.valid then return end
    if name then
        button.sprite = "item/" .. name
        button.number = count
        local proto = prototypes.item[name]
        button.tooltip = proto and proto.localised_name or name
    else
        button.sprite = placeholder_for_role(role)
        button.number = nil
        button.tooltip = placeholder_tooltip_for_role(role)
    end
end

local function set_hint_sprite(button, name, amount)
    if not button or not button.valid then return end
    button.sprite = "item/" .. name
    button.number = amount * -1
    local proto = prototypes.item[name]
    button.tooltip = { "", "Needs: ", proto and proto.localised_name or name, " x", amount }
end

local function compute_infuser_slot_positions(frame_location)
    local base_x = frame_location.x + INFUSER_CANVAS_OFFSET_X
    local base_y = frame_location.y + INFUSER_CANVAS_OFFSET_Y
    local center_x = base_x + INFUSER_CANVAS_SIZE / 2
    local center_y = base_y + INFUSER_CANVAS_SIZE / 2

    local positions = {}
    for _, ring in ipairs(CIRCLE_RING) do
        local dx, dy = circle_offset(ring.angle, INFUSER_RADIUS)
        positions[ring.key] = {
            x = center_x + dx - INFUSER_SLOT_SIZE / 2,
            y = center_y + dy - INFUSER_SLOT_SIZE / 2,
        }
    end

    local stack_height = INFUSER_CENTER_SLOT_SIZE * 2 + INFUSER_CENTER_GAP
    local stack_top = center_y - stack_height / 2
    positions.item = { x = center_x - INFUSER_CENTER_SLOT_SIZE / 2, y = stack_top }
    positions.crystal = {
        x = center_x - INFUSER_CENTER_SLOT_SIZE / 2,
        y = stack_top + INFUSER_CENTER_SLOT_SIZE + INFUSER_CENTER_GAP,
    }

    return positions
end

local function reposition_infuser_slots(player)
    local frame = player.gui.screen[GUI_NAME]
    if not frame or not frame.valid then return end

    local slot_buttons = infuser_slot_buttons[player.index]
    if not slot_buttons then return end

    local positions = compute_infuser_slot_positions(frame.location)
    for key, button in pairs(slot_buttons) do
        if button.valid and positions[key] then
            button.location = positions[key]
        end
    end

    bring_infuser_slots_to_front(player)
end

local function slot_size_for_key(key)
    if key == "item" or key == "crystal" then
        return INFUSER_CENTER_SLOT_SIZE
    end
    return INFUSER_SLOT_SIZE
end

local function create_infuser_floating_slots(player)
    local slot_buttons = {}
    local all_keys = { "crystal" }
    for _, r in ipairs(POOLED_ROLES) do table.insert(all_keys, r) end

    for _, key in ipairs(all_keys) do
        local size = slot_size_for_key(key)
        local button = player.gui.screen.add {
            type = "sprite-button",
            name = "infuser_slot_" .. key,
            style = "inventory_slot",
            width = size,
            height = size,
        }
        button.style.margin = 0
        slot_buttons[key] = button
    end

    infuser_slot_buttons[player.index] = slot_buttons
    reposition_infuser_slots(player)
    bring_infuser_slots_to_front(player)
end

local function destroy_infuser_floating_slots(player)
    local slot_buttons = infuser_slot_buttons[player.index]
    if slot_buttons then
        for _, button in pairs(slot_buttons) do
            if button.valid then button.destroy() end
        end
    end
    infuser_slot_buttons[player.index] = nil
end

local function refresh_inventory_gui(player)
    local gui = player.gui.screen[GUI_NAME]
    if not gui or not gui.valid then return end

    local inventory = player.get_main_inventory()
    if not inventory then return end

    local inventory_table =
        gui.content.Charater.VerticalFlow.VFINV.verticalScrollPane.inv_table
    if not inventory_table or not inventory_table.valid then return end

    for i = 1, #inventory do
        local slot = inventory_table["inventory_slot_" .. i]
        if slot and slot.valid then
            local s = inventory[i]
            if s.valid_for_read then
                slot.sprite = "item/" .. s.name
                slot.number = s.count
            else
                slot.sprite = nil
                slot.number = nil
            end
        end
    end
    reposition_infuser_slots(player)
end

local function refresh_overflow_panel(player, entity)
    local gui = player.gui.screen[GUI_NAME]
    if not gui or not gui.valid then return end
    local overflow_table = gui.content.Insfuser.overflow_scroll.overflow_table
    if not overflow_table or not overflow_table.valid then return end
    overflow_table.clear()

    local inv = entity.get_inventory(defines.inventory.chest)
    local assignments = get_assignments(entity.unit_number)
    local assigned_names = {}
    for _, entry in pairs(assignments) do assigned_names[entry.name] = true end

    local crystal_name = inv[RESERVED_CRYSTAL_INDEX].valid_for_read and inv[RESERVED_CRYSTAL_INDEX].name or nil

    local seen = {}
    for i = 2, #inv do
        local s = inv[i]
        if s.valid_for_read and s.name ~= crystal_name and not assigned_names[s.name] and not seen[s.name] then
            seen[s.name] = true
            overflow_table.add {
                type = "sprite-button",
                name = "overflow_slot_" .. s.name,
                style = "inventory_slot",
                sprite = "item/" .. s.name,
                number = inv.get_item_count(s.name),
                width = 40, height = 40,
            }
        end
    end
end

local function refresh_recipe_select_button(player, entity)
    local gui = player.gui.screen[GUI_NAME]
    if not gui or not gui.valid then return end
    local button = gui.content.Insfuser.craft_row.infuser_select_recipe_button
    if not button or not button.valid then return end

    local snapshot = gather_slot_snapshot(entity)
    local rule_id, rule_or_candidates = infusion_api.find_rule(snapshot)

    if rule_id then
        button.enabled = false
        button.caption = "Recipe"
        button.tooltip = "Recipe is unambiguous"
    elseif rule_or_candidates then
        button.enabled = true
        local chosen = storage.infuser_selected_rule[entity.unit_number]
        local idx_of_chosen = 0
        for i, id in ipairs(rule_or_candidates) do
            if id == chosen then idx_of_chosen = i break end
        end
        button.caption = "Recipe (" .. idx_of_chosen .. "/" .. #rule_or_candidates .. ")"
        button.tooltip = "Multiple recipes match — click to cycle through them"
    else
        button.enabled = false
        button.caption = "Recipe"
        button.tooltip = "No matching custom recipe"
    end
end

local function compute_hints(entity, snapshot)
    local hints = {}
    local candidates = infusion_api.candidate_rules(snapshot)

    if #candidates == 1 then
        for _, u in ipairs(infusion_api.unmet_requirements(candidates[1].rule, snapshot)) do
            hints[u.key] = { name = u.name, amount = u.amount }
        end
    elseif #candidates == 0 then
        local item_entry = snapshot.item
        if item_entry then
            local real_ings = resolve_ingredients(entity.force, item_entry.name)
            if real_ings then
                local used = {}
                for _, req in ipairs(real_ings) do
                    local satisfied = false
                    for _, role in ipairs(ING_ROLES) do
                        if not used[role] then
                            local e = snapshot[role]
                            if e and e.name == req.name then
                                used[role] = true
                                satisfied = true
                                break
                            end
                        end
                    end
                    if not satisfied then
                        for _, role in ipairs(ING_ROLES) do
                            if not used[role] and not snapshot[role] and not hints[role] then
                                hints[role] = { name = req.name, amount = req.amount }
                                used[role] = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    return hints
end

local function refresh_infuser_gui(player)
    local entity = open_infusers[player.index]
    if not entity or not entity.valid then return end

    local inv = entity.get_inventory(defines.inventory.chest)
    if not inv then return end

    local slot_buttons = infuser_slot_buttons[player.index]
    if not slot_buttons then return end

    set_stack_sprite(slot_buttons.crystal, inv[RESERVED_CRYSTAL_INDEX])

    local snapshot = gather_slot_snapshot(entity)
    local hints = compute_hints(entity, snapshot)
    local assignments = get_assignments(entity.unit_number)

    for _, role in ipairs(POOLED_ROLES) do
        local button = slot_buttons[role]
        local entry = assignments[role]
        if entry then
            set_pooled_sprite(button, role, entry.name, entry.count)
        elseif hints[role] then
            set_hint_sprite(button, hints[role].name, hints[role].amount)
        else
            set_pooled_sprite(button, role, nil, nil)
        end
    end

    refresh_recipe_select_button(player, entity)
    refresh_overflow_panel(player, entity)
    bring_infuser_slots_to_front(player)
end

local function build_infuser_gui(event)
    local player = game.players[event.player_index]
    local entity = event.entity

    if player.gui.screen[GUI_NAME] then
        player.gui.screen[GUI_NAME].destroy()
    end
    destroy_infuser_floating_slots(player)

    local frame = player.gui.screen.add {
        type = "frame",
        name = GUI_NAME,
        direction = "vertical",
        style = "inset_frame_container_frame",
        top_padding = 4,
        bottom_padding = 8,
        left_padding = 8,
        right_padding = 8,
        use_header_filler = true,
    }
    frame.auto_center = true

    local titlebar = frame.add { type = "flow", name = "titlebar", direction = "horizontal" }

    local drag_bar = titlebar.add {
        type = "empty-widget",
        name = "drag_bar",
        style = "draggable_space_header",
        drag_target = frame,
    }
    drag_bar.style.horizontally_stretchable = true
    drag_bar.style.height = 24

    local title = titlebar.add {
        type = "label",
        name = "title",
        caption = entity.localised_name,
        style = "frame_title",
    }
    title.drag_target = frame
    titlebar.drag_target = frame

    local title_spacer = titlebar.add { type = "empty-widget", name = "title_spacer" }
    title_spacer.style.horizontally_stretchable = true

    titlebar.add {
        type = "sprite-button",
        name = "close_button",
        sprite = "utility/close",
        style = "frame_action_button",
        tooltip = { "gui.close" },
    }

    local inside_shallow_frame = frame.add {
        type = "frame",
        name = "content",
        style = "inside_shallow_frame",
        direction = "horizontal",
    }

    local Charater = inside_shallow_frame.add {
        type = "frame",
        name = "Charater",
        style = "entity_frame",
        padding = 12,
        use_header_filler = false,
        direction = "horizontal",
    }
    local VF = Charater.add { type = "flow", direction = "vertical", name = "VerticalFlow", style = "vertical_flow", vertical_spacing = 4 }
    VF.add { type = "label", caption = "Character", name = "CLabel", single_line = true }
    local VFINV = VF.add { type = "flow", direction = "vertical", name = "VFINV", style = "vertical_flow" }
    local scrollPance = VFINV.add { type = "scroll-pane", direction = "vertical", name = "verticalScrollPane" }
    scrollPance.style.width = INFUSER_INVENTORY_SIZE
    scrollPance.style.height = INFUSER_INVENTORY_SIZE
    local InventoryTable = scrollPance.add {
        type = "table",
        column_count = 10,
        direction = "horizontal",
        name = "inv_table",
        style = "slot_table",
        padding = 4,
        vertical_spacing = 4,
    }

    local inventory = player.get_main_inventory()
    if inventory then
        for i = 1, #inventory do
            local slot = InventoryTable.add {
                type = "sprite-button",
                name = "inventory_slot_" .. i,
                style = "inventory_slot",
                width = 40,
                height = 40,
                natural_width = 40,
                natural_height = 40,
                padding = 0,
            }
            local s = inventory[i]
            if s.valid_for_read then
                slot.sprite = "item/" .. s.name
                slot.number = s.count
            end
        end
    end

    local Insfuser = inside_shallow_frame.add {
        type = "frame",
        name = "Insfuser",
        style = "entity_frame",
        padding = 12,
        use_header_filler = false,
        direction = "vertical",
    }

    local canvas_spacer = Insfuser.add { type = "empty-widget", name = "infuser_canvas_spacer" }
    canvas_spacer.style.width = INFUSER_CANVAS_SIZE
    canvas_spacer.style.height = INFUSER_CANVAS_SIZE

    local craft_row = Insfuser.add { type = "flow", name = "craft_row", direction = "horizontal" }
    craft_row.style.width = INFUSER_CANVAS_SIZE
    craft_row.style.height = INFUSER_BUTTON_ROW_HEIGHT

    local craft_button = craft_row.add { type = "button", name = "infuser_craft_button", caption = "Craft" }
    craft_button.style.height = INFUSER_BUTTON_ROW_HEIGHT
    craft_button.style.padding = 0

    local select_recipe_button = craft_row.add { type = "button", name = "infuser_select_recipe_button", caption = "Recipe" }
    select_recipe_button.style.height = INFUSER_BUTTON_ROW_HEIGHT
    select_recipe_button.style.padding = 0
    select_recipe_button.enabled = false

    Insfuser.add { type = "label", caption = "Overflow", name = "overflow_label" }
    local overflow_scroll = Insfuser.add { type = "scroll-pane", name = "overflow_scroll", direction = "vertical" }
    overflow_scroll.style.width = INFUSER_CANVAS_SIZE
    overflow_scroll.style.height = 120
    overflow_scroll.add {
        type = "table",
        name = "overflow_table",
        column_count = 8,
        style = "slot_table",
    }

    open_infusers[player.index] = entity
    player.opened = frame

    create_infuser_floating_slots(player)
    refresh_infuser_gui(player)
end

script.on_event(defines.events.on_gui_opened, function(event)
    if creating_gui then return end
    if not event.entity or event.entity.name ~= INFUSER_NAME then return end

    creating_gui = true
    local ok, err = pcall(build_infuser_gui, event)
    creating_gui = false

    if not ok then
        log("[MysticalForestry] Failed to build infuser GUI: " .. tostring(err))
    end
end)

script.on_event(defines.events.on_gui_location_changed, function(event)
    local element = event.element
    if not element or not element.valid then return end
    if element.name ~= GUI_NAME then return end

    local player = game.players[event.player_index]
    reposition_infuser_slots(player)
end)

script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not element or not element.valid then return end

    local player = game.players[event.player_index]

    if element.name == "close_button" then
        if player.gui.screen[GUI_NAME] then
            player.gui.screen[GUI_NAME].destroy()
        end
        destroy_infuser_floating_slots(player)
        open_infusers[player.index] = nil
        refresh_inventory_gui(player)
        return
    end

    if element.name == "infuser_craft_button" then
        local entity = open_infusers[player.index]
        if entity and entity.valid then
            local success = attempt_craft(entity, player)
            if success then
                player.create_local_flying_text { text = "Infusion complete!", create_at_cursor = true }
            end
            refresh_infuser_gui(player)
        end
        refresh_inventory_gui(player)
        return
    end

    if element.name == "infuser_select_recipe_button" then
        local entity = open_infusers[player.index]
        if entity and entity.valid then
            local snapshot = gather_slot_snapshot(entity)
            local rule_id, candidates = infusion_api.find_rule(snapshot)
            if not rule_id and candidates then
                local chosen = storage.infuser_selected_rule[entity.unit_number]
                local next_index = 1
                for i, id in ipairs(candidates) do
                    if id == chosen then next_index = i + 1 break end
                end
                if next_index > #candidates then next_index = 1 end
                storage.infuser_selected_rule[entity.unit_number] = candidates[next_index]
            end
            refresh_infuser_gui(player)
        end
        return
    end

    local overflow_name = string.match(element.name, "^overflow_slot_(.+)$")
    if overflow_name then
        local entity = open_infusers[player.index]
        if entity and entity.valid then
            local inv = entity.get_inventory(defines.inventory.chest)
            local cursor = player.cursor_stack
            if not cursor.valid_for_read then
                local proto = prototypes.item[overflow_name]
                local size = proto and proto.stack_size or 1
                local have = inv.get_item_count(overflow_name)
                local take = math.min(size, have)
                if take > 0 then
                    inv.remove({ name = overflow_name, count = take })
                    cursor.set_stack({ name = overflow_name, count = take })
                end
            end
            refresh_infuser_gui(player)
            refresh_inventory_gui(player)
        end
        return
    end

    local infuser_key = string.match(element.name, "^infuser_slot_(.+)$")
    if infuser_key then
        local entity = open_infusers[player.index]
        if not entity or not entity.valid then refresh_inventory_gui(player) return end

        local inv = entity.get_inventory(defines.inventory.chest)
        if not inv then refresh_inventory_gui(player) return end

        local cursor = player.cursor_stack

        if infuser_key == "crystal" then
            local slot = inv[RESERVED_CRYSTAL_INDEX]
            if event.button == defines.mouse_button_type.left then
                if not cursor.valid_for_read then
                    if slot.valid_for_read then cursor.swap_stack(slot) end
                elseif not is_crystal(cursor.name) then
                    player.create_local_flying_text { text = "That doesn't go there.", create_at_cursor = true }
                elseif slot.valid_for_read and slot.name == cursor.name and slot.quality == cursor.quality then
                    cursor.transfer_stack(slot)
                else
                    cursor.swap_stack(slot)
                end
            end
        else
            local assignments = get_assignments(entity.unit_number)
            local assigned = assignments[infuser_key]

            if event.button == defines.mouse_button_type.left then
                if not cursor.valid_for_read then
                    local name, take = withdraw_pooled(entity, infuser_key)
                    if name and take > 0 then
                        cursor.set_stack({ name = name, count = take })
                    end
                else
                    if assigned and assigned.name ~= cursor.name then
                        player.create_local_flying_text { text = "That doesn't go there.", create_at_cursor = true }
                    elseif not assigned and not role_accepts(entity, infuser_key, cursor.name) then
                        player.create_local_flying_text { text = "That doesn't go there.", create_at_cursor = true }
                    else
                        local inserted = insert_pooled(entity, infuser_key, cursor.name, cursor.count)
                        if inserted > 0 then
                            if inserted >= cursor.count then cursor.clear() else cursor.count = cursor.count - inserted end
                        end
                    end
                end
            end
        end

        refresh_infuser_gui(player)
        refresh_inventory_gui(player)
        return
    end

    local inventory_index = string.match(element.name, "^inventory_slot_(%d+)$")
    if inventory_index then
        inventory_index = tonumber(inventory_index)
        local inventory = player.get_main_inventory()
        if not inventory then return end

        local slot = inventory[inventory_index]
        if not slot or not slot.valid then return end

        local cursor = player.cursor_stack

        if event.button == defines.mouse_button_type.left then
            if not cursor.valid_for_read then
                if slot.valid_for_read then
                    cursor.swap_stack(slot)
                end
            else
                if slot.valid_for_read and slot.name == cursor.name and slot.quality == cursor.quality then
                    cursor.transfer_stack(slot)
                else
                    cursor.swap_stack(slot)
                end
            end
        end
        refresh_inventory_gui(player)
        return
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if creating_gui then return end

    local player = game.players[event.player_index]
    if player.gui.screen[GUI_NAME] then
        player.gui.screen[GUI_NAME].destroy()
    end
    destroy_infuser_floating_slots(player)
    open_infusers[event.player_index] = nil
end)