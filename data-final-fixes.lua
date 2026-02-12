local func = require("functions")

local toweranywhere = settings.startup["mystical-agriculture-tower-anywhere"].value

if toweranywhere and data.raw["agricultural-tower"] then
  for name, tower in pairs(data.raw["agricultural-tower"]) do
    tower.surface_conditions = nil
  end
end


if allow_all then
    
else
    func.create_craft_category()

    local previousQuality = nil
    for _, kwa in pairs(data.raw["quality"]) do
        if kwa.name == "quality-unknown" then
            goto continue
        end
        func.create_quality_essence(kwa)
        func.create_quality_crystal(kwa, previousQuality)
        previousQuality = kwa
        ::continue::
    end
    func.create_master_crystal(previousQuality)


    if custom_items and custom_items ~= "" then
        local items = {}

        for item in string.gmatch(custom_items, '([^,]+)') do
            table.insert(items, item:match("^%s*(.-)%s*$"))
        end

        for _, item_name in ipairs(items) do
            local item_proto = data.raw["item"][item_name]
            if item_proto then
                func.create_custom_prototypes(item_proto, true, true, false)
            else
                error("Mystical Agriculture: Item '" .. item_name .. "' not found. Skipping.")
            end
        end
    end

    func.create_essence_recipe()

    if qualityseeds then
        if mods["quality-plants"] then
            func.create_quality_seed_recipe()
        else
            error(
            "Mystical Agriculture: Quality Seeds setting is enabled, but Quality Plants mod is not present. Please install Quality Plants or disable the setting.")
        end
    end
    func.trigger_tech_p2()
    func.generate_trigger_techs()
    func.add_achievement()
end
