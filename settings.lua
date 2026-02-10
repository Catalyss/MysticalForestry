--data:extend({
--  {
--    type = "bool-setting",
--    name = "mystical-agriculture-all-items",
--    setting_type = "startup",
--    default_value = false,
--    order = "zzz",
--    localised_name = { "setting-name.mystical-agriculture-all-items" },
--  }
--})
--unused for now 
data:extend({
  {
    type = "bool-setting",
    name = "mystical-agriculture-tower-anywhere",
    setting_type = "startup",
    default_value = true,
    order = "a",
    localised_name = { "setting-name.mystical-agriculture-tower-anywhere" },
  }
})

data:extend({
  {
    type = "bool-setting",
    name = "mystical-agriculture-hide-tech",
    setting_type = "startup",
    default_value = true,
    order = "a",
    localised_name = { "setting-name.mystical-agriculture-hide-tech" },
  }
})

data:extend({
  {
    type = "int-setting",
    name = "mystical-agriculture-technology-amount",
    setting_type = "startup",
    default_value = 1000,
    maximum_value = 4294967295,
    minimum_value = 1,
    order = "b",
    localised_name = { "setting-name.mystical-agriculture-technology" },
  }
})

data:extend({
  {
    type = "int-setting",
    name = "mystical-agriculture-crafting-amount",
    setting_type = "startup",
    default_value = 1,
    maximum_value = 65535,
    minimum_value = 1,
    order = "c",
    localised_name = { "setting-name.mystical-agriculture-crafting-amount" },
  }
})
