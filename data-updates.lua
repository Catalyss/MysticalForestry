require("prototypes.category")
require("prototypes.icons")
local func = require("functions")
local allow_all = settings.startup["mystical-agriculture-all-items"].value
local custom_items = settings.startup["mystical-agriculture-custom-items"].value
local qualityseeds = settings.startup["mystical-agriculture-quality-seeds"].value



local function has_flag(flags, flag)
    if not flags then return false end
    for _, f in pairs(flags) do
        if f == flag then return true end
    end
    return false
end



if allow_all then
    local ALLOWED_TYPES = {
        item = true,
        tool = true,
        ammo = true,
        capsule = true,
        ["item-with-entity-data"] = true,
    }
    for key, _ in pairs(ALLOWED_TYPES) do
        for _, v in pairs(data.raw[key]) do
            if v.name ~= "item-unknown"
                and not v.hidden
                and v.stack_size
                and not (v.flags and has_flag(v.flags, "hidden"))
            then
                func.create_custom_prototypes(v, v)
            end
        end
    end
else
    func.initialize_prototypes()
    func.create_craft_category()

    local previousQuality = nil
    local kwalit = table.deepcopy(data.raw["quality"])
    
    table.sort(kwalit, function(a, b)
        return a.quality.level < b.quality.level
    end)

    for _, kwa in pairs(kwalit) do
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
