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
        local to_quality,item_name =
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
