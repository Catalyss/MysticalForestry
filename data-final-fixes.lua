local func = require("functions")

local allow_all = settings.startup["mystical-agriculture-all-items"].value
local toweranywhere = settings.startup["mystical-agriculture-tower-anywhere"].value
local custom_items = settings.startup["mystical-agriculture-custom-items"].value
local qualityseeds = settings.startup["mystical-agriculture-quality-seeds"].value

if toweranywhere and data.raw["agricultural-tower"] then
  for name, tower in pairs(data.raw["agricultural-tower"]) do
    tower.surface_conditions = nil
  end
end


if allow_all then
    
else
    
end
