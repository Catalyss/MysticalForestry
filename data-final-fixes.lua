require("prototypes.category") 
require("prototypes.icons") 
require("prototypes.items")
require("prototypes.plants")
require("prototypes.recipes")
require("prototypes.technologies")

local toweranywhere = settings.startup["mystical-agriculture-tower-anywhere"].value

if toweranywhere and data.raw["agricultural-tower"] then
  for name, tower in pairs(data.raw["agricultural-tower"]) do
    tower.surface_conditions = nil
  end
end