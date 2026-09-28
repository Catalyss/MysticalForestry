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
            -- Fallback
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
            -- Fallback
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

local SLOT_INDEX = {
    item           = 1,
    crystal        = 2,
    essence_top    = 3,
    essence_left   = 4,
    essence_right  = 5,
    essence_bottom = 6,
    ing_tl         = 7,
    ing_tr         = 8,
    ing_bl         = 9,
    ing_br         = 10,
}

local ESSENCE_SLOTS = { SLOT_INDEX.essence_top, SLOT_INDEX.essence_left, SLOT_INDEX.essence_right, SLOT_INDEX.essence_bottom }
local ING_SLOTS = { SLOT_INDEX.ing_tl, SLOT_INDEX.ing_tr, SLOT_INDEX.ing_bl, SLOT_INDEX.ing_br }

local INFUSER_SLOT_SIZE = 64
local INFUSER_CENTER_SLOT_SIZE = 60
local INFUSER_CENTER_GAP = 8
local INFUSER_RADIUS = 140
local INFUSER_CANVAS_SIZE = 400
local INFUSER_BUTTON_ROW_HEIGHT = 20
local INFUSER_INVENTORY_SIZE = 420

local INFUSER_CANVAS_OFFSET_X = 500
local INFUSER_CANVAS_OFFSET_Y = 60

-- N/E/S/W = essence (the "cross"), diagonals = ingredients.
-- 0deg = straight up, going clockwise.
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
end)

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

-- ============================================================
-- RECIPE / CRAFT LOGIC
-- ============================================================
local find_recipe_for_item
local get_solid_ingredients
local check_ready
local attempt_craft
local validate_infuser_inventory

local function recipe_is_recycling(recipe)
    if recipe.categories then
        for _, cat in pairs(recipe.categories) do
            if cat == "recycling" then return true end
        end
    end
    return false
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
    local custom = infusion_api.get_custom_ingredients(item_name)
    if custom then return custom end

    local recipe = find_recipe_for_item(force, item_name)
    if recipe then return get_solid_ingredients(recipe) end

    return nil
end

check_ready = function(entity)
    local inv = entity.get_inventory(defines.inventory.chest)
    if not inv then return false, "no-inventory" end

    local item_stack = inv[SLOT_INDEX.item]
    if not item_stack.valid_for_read then return false, "no-item" end
    if item_stack.count ~= 1 then return false, "must-supply-exactly-one-item" end

    local recipe = find_recipe_for_item(entity.force, item_stack.name)
    if not recipe then return false, "no-recipe" end

    local ingredients = resolve_ingredients(entity.force, item_stack.name)
    if not ingredients then return false, "no-recipe" end
    if #ingredients > 4 then return false, "too-many-ingredients" end

    local used = {}
    for _, req in ipairs(ingredients) do
        local found = false
        for _, idx in ipairs(ING_SLOTS) do
            if not used[idx] then
                local s = inv[idx]
                if s.valid_for_read and s.name == req.name and s.count >= req.amount then
                    used[idx] = true
                    found = true
                    break
                end
            end
        end
        if not found then return false, "missing-ingredient:" .. req.name end
    end

    local essence_quality_name = nil
    for _, idx in ipairs(ESSENCE_SLOTS) do
        local s = inv[idx]
        if not s.valid_for_read or not is_essence(s.name) then return false, "missing-essence" end
        local q = essence_quality(s.name)
        if essence_quality_name == nil then
            essence_quality_name = q
        elseif essence_quality_name ~= q then
            return false, "mismatched-essence"
        end
        if s.count < INFUSER_ESSENCE_PER_SLOT then return false, "not-enough-essence" end
    end

    local crystal_stack = inv[SLOT_INDEX.crystal]
    if not crystal_stack.valid_for_read or not is_crystal(crystal_stack.name) then
        return false, "missing-crystal"
    end
    if not crystal_matches("mystical-agriculture-" .. essence_quality_name .. "-essence", crystal_stack.name) then
        return false, "crystal-mismatch"
    end

    local target_quality = prototypes.quality[essence_quality_name]
    if not target_quality then return false, "unknown-quality:" .. tostring(essence_quality_name) end

    local current_quality = item_stack.quality
    if current_quality and current_quality.level >= target_quality.level then
        return false, "item-already-at-or-above-target-quality"
    end

    return true, {
        recipe = recipe,
        ingredients = ingredients,
        used_ing_slots = used,
        essence_quality_name = essence_quality_name,
        target_quality = target_quality,
    }
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
    local base_name = inv[SLOT_INDEX.item].name

    inv[SLOT_INDEX.item].clear()

    for _, req in ipairs(info.ingredients) do
        for idx in pairs(info.used_ing_slots) do
            local s = inv[idx]
            if s.valid_for_read and s.name == req.name then
                if s.count > req.amount then
                    s.count = s.count - req.amount
                else
                    s.clear()
                end
                info.used_ing_slots[idx] = nil
                break
            end
        end
    end

    for _, idx in ipairs(ESSENCE_SLOTS) do
        local s = inv[idx]
        if s.count > INFUSER_ESSENCE_PER_SLOT then
            s.count = s.count - INFUSER_ESSENCE_PER_SLOT
        else
            s.clear()
        end
    end

    local crystal_stack = inv[SLOT_INDEX.crystal]
    if crystal_stack.name ~= "mystical-agriculture-master-gaster-crystal" then
        crystal_stack.set_stack { name = "mystical-agriculture-normal-crystal", count = 1, quality = "normal" }
    end

    inv[SLOT_INDEX.item].set_stack {
        name = base_name,
        count = 1,
        quality = info.target_quality.name,
    }

    return true
end

local function eject_stack(entity, stack)
    if not stack.valid_for_read then return end
    entity.surface.spill_item_stack {
        position = entity.position,
        stack = stack,
        enable_looted = false,
        force_to_surface = true,
    }
    stack.clear()
end

validate_infuser_inventory = function(entity)
    local inv = entity.get_inventory(defines.inventory.chest)
    if not inv then return end

    local crystal_stack = inv[SLOT_INDEX.crystal]
    if crystal_stack.valid_for_read and not is_crystal(crystal_stack.name) then
        eject_stack(entity, crystal_stack)
    end

    for _, idx in ipairs(ESSENCE_SLOTS) do
        local s = inv[idx]
        if s.valid_for_read and not is_essence(s.name) then
            eject_stack(entity, s)
        end
    end

    local item_stack = inv[SLOT_INDEX.item]
    if item_stack.valid_for_read then
        local ingredients = resolve_ingredients(entity.force, item_stack.name)
        if ingredients then
            local allowed = {}
            for _, ing in ipairs(ingredients) do
                allowed[ing.name] = true
            end
            for _, idx in ipairs(ING_SLOTS) do
                local s = inv[idx]
                if s.valid_for_read and not allowed[s.name] then
                    eject_stack(entity, s)
                end
            end
        end
    end
end

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
local open_infusers = {}        -- [player_index] = entity
local infuser_slot_buttons = {} -- [player_index] = { [key] = LuaGuiElement }

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

local function slot_accepts(slot_key, item_name)
    if slot_key == "crystal" then
        return is_crystal(item_name)
    elseif slot_key:match("^essence_") then
        return is_essence(item_name)
    end
    return true
end

local function placeholder_for_slot(slot_key)
    if slot_key == "crystal" then
        return INFUSER_PLACEHOLDER_CRYSTAL
    elseif slot_key and slot_key:match("^essence_") then
        return INFUSER_PLACEHOLDER_ESSENCE
    end
    return INFUSER_PLACEHOLDER_ANY
end

local function placeholder_tooltip_for_slot(slot_key)
    if slot_key == "crystal" then
        return "Place a quality crystal here"
    elseif slot_key == "item" then
        return "Place the item to infuse here"
    elseif slot_key and slot_key:match("^essence_") then
        return "Place essence here (all four must match)"
    elseif slot_key and slot_key:match("^ing_") then
        return "Place a matching recipe ingredient here"
    end
    return nil
end

local function set_slot_sprite(button, stack, slot_key)
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
        button.number = nil
        if slot_key then
            button.sprite = placeholder_for_slot(slot_key)
            button.tooltip = placeholder_tooltip_for_slot(slot_key)
        else
            button.sprite = nil
            button.tooltip = nil
        end
    end
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

    for key in pairs(SLOT_INDEX) do
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
            set_slot_sprite(slot, inventory[i])
        end
    end
    reposition_infuser_slots(player)
end

local function get_ingredient_hints(entity, inv)
    local item_stack = inv[SLOT_INDEX.item]
    if not item_stack.valid_for_read then return nil end

    local recipe = find_recipe_for_item(entity.force, item_stack.name)
    if not recipe then return nil end

    local ingredients = resolve_ingredients(entity.force, item_stack.name)
    if not ingredients then return nil end

    local unmet = {}
    local used = {}
    for _, req in ipairs(ingredients) do
        local satisfied = false
        for _, idx in ipairs(ING_SLOTS) do
            if not used[idx] then
                local s = inv[idx]
                if s.valid_for_read and s.name == req.name then
                    used[idx] = true
                    satisfied = true
                    break
                end
            end
        end
        if not satisfied then
            table.insert(unmet, req)
        end
    end

    local hints = {}
    local n = 1
    for _, idx in ipairs(ING_SLOTS) do
        if not inv[idx].valid_for_read and unmet[n] then
            hints[idx] = unmet[n]
            n = n + 1
        end
    end
    return hints
end

local function set_ingredient_hint(button, req)
    if not button or not button.valid then return end
    button.number = nil
    button.sprite = "item/" .. req.name
    button.number = req.amount*-1
    local proto = prototypes.item[req.name]
    button.tooltip = { "", "Needs: ", proto and proto.localised_name or req.name, " x", req.amount }
end

local function refresh_infuser_gui(player)
    local entity = open_infusers[player.index]
    if not entity or not entity.valid then return end

    local inv = entity.get_inventory(defines.inventory.chest)
    if not inv then return end

    local slot_buttons = infuser_slot_buttons[player.index]
    if not slot_buttons then return end

    local hints = get_ingredient_hints(entity, inv)

    for key, idx in pairs(SLOT_INDEX) do
        local button = slot_buttons[key]
        local hint = hints and hints[idx]
        if hint and not inv[idx].valid_for_read then
            set_ingredient_hint(button, hint)
        else
            set_slot_sprite(button, inv[idx], key)
        end
    end

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

    -- Character inventory panel
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
            set_slot_sprite(slot, inventory[i])
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
            attempt_craft(entity, player)
            refresh_infuser_gui(player)
        end
        refresh_inventory_gui(player)
        return
    end

    local infuser_key = string.match(element.name, "^infuser_slot_(.+)$")
if infuser_key then
    player.print("[DEBUG] slot click registered: " .. infuser_key) -- TEMP

    local entity = open_infusers[player.index]
    if not entity or not entity.valid then
        player.print("[DEBUG] no valid entity") -- TEMP
        refresh_inventory_gui(player)
        return
    end

    local inv = entity.get_inventory(defines.inventory.chest)
    if not inv then
        player.print("[DEBUG] get_inventory(chest) returned nil") -- TEMP
        refresh_inventory_gui(player)
        return
    end

    local idx = SLOT_INDEX[infuser_key]
    if not idx then
        player.print("[DEBUG] no SLOT_INDEX entry for " .. infuser_key) -- TEMP
        refresh_inventory_gui(player)
        return
    end

    player.print("[DEBUG] cursor has item: " .. tostring(player.cursor_stack.valid_for_read)) -- TEMP

    local slot = inv[idx]
    local cursor = player.cursor_stack

        if event.button == defines.mouse_button_type.left then
            if not cursor.valid_for_read then
                if slot.valid_for_read then
                    cursor.swap_stack(slot)
                end
            elseif not slot_accepts(infuser_key, cursor.name) then
                player.create_local_flying_text {
                    text = "That doesn't go there.",
                    create_at_cursor = true,
                }
            elseif slot.valid_for_read and slot.name == cursor.name and slot.quality == cursor.quality then
                cursor.transfer_stack(slot)
            else
                cursor.swap_stack(slot)
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