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
end
