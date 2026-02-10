require("__MysticalForestry__/prototypes/icons")

local techss = settings.startup["mystical-agriculture-technology-amount"].value


local function get_mine_results(minable)
  if minable.results then
    return minable.results
  elseif minable.result then
    return { { type = "item", name = minable.result, amount = minable.count or 1 } }
  else
    return nil
  end
end

for resource_name, resource_proto in pairs(data.raw.resource) do
  local minable = resource_proto.minable
  if minable then
    local raw_name
    if minable.results and #minable.results > 0 then
      raw_name = minable.results[1].name
    else
      raw_name = minable.result or resource_name
    end

    local tranlatedkey = raw_name
    if minable.results and #minable.results > 0 then
        local first_result = data.raw.item[minable.results[1].name]
        if first_result and first_result.localised_name then
            tranlatedkey = first_result.localised_name
        end
    elseif minable.result then
        local item = data.raw.item[minable.result]
        if item and item.localised_name then
            tranlatedkey = item.localised_name
        end
    end


    local tint = get_resource_tint(resource_name, resource_proto)

    local results = get_mine_results(minable)
    local has_fluid = false
    if results then
      for _, r in pairs(results) do
        if r.type == "fluid" then has_fluid = true end
      end
    end

    local tech = {
      type = "technology",
      name = "mystical-" .. raw_name,
      icons = { {
        icon = "__MysticalForestry__/graphics/template-tree-seed.png",
        icon_size = 64,
        scale = 0.5,
        tint = tint,
      } },
      effects = {
        { type = "unlock-recipe", recipe = raw_name .. "-tree-seed-crafting" },
        { type = "unlock-recipe", recipe = raw_name .. "-tree-seed-from-log" },
        { type = "unlock-recipe", recipe = raw_name .. "-from-log" }
      },
      localised_name = { "technology-name.mystical-resource-tech", tranlatedkey }

    }

    if not has_fluid then
      tech.research_trigger = {
        type = "craft-item",
        item = { name = raw_name },
        count = techss
      }
    else
      tech.research_trigger = {
        type = "craft-fluid",
        fluid = raw_name,
        amount = techss
      }
    end

    data:extend({ tech })
  end
end
