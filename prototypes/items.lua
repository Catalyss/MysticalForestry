require("__MysticalForestry__/prototypes/icons")


local function get_mine_results_as_log(minable,ammtnb,resource_name)
  if minable.results then
    local results = {}
    for _, value in pairs(minable.results) do
      if(data.raw.item[value.name .. "-log"]) then table.insert(results, { type = "item", name = value.name .. "-log", amount = ammtnb or 1, allow_quality = true })
      else table.insert(results, { type = "item", name = value.name, amount = ammtnb or 1, allow_quality = true })
      end
    end
    return results
  elseif minable.result then
    if(data.raw.item[minable.result .. "-log"]) then return { { type = "item", name = minable.result .. "-log", amount = ammtnb or 1, allow_quality = true  } }
    else return { { type = "item", name = minable.result, amount = ammtnb or 1, allow_quality = true  } }
    end
  else
    if(data.raw.item[resource_name .. "-log"]) then return { { type = "item", name = resource_name.. "-log", amount = ammtnb or 1, allow_quality = true  } }
    else return { { type = "item", name = resource_name, amount = ammtnb or 1, allow_quality = true  } }
    end
  end
end

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



    local icon_name = resource_name:gsub("-ore$", "")
    local tint = get_resource_tint(resource_name, resource_proto)

    data:extend({
      {
        type = "item",
        name = raw_name .. "-tree-seed",
        icons = { {
          icon = "__MysticalForestry__/graphics/template-tree-seed.png",
          icon_size = 64,
          scale = 0.5,
          tint = tint,
        } },
        subgroup = "mystical-agriculture-seeds",
        order = "a[seed]-" .. raw_name,
        stack_size = 10,
        plant_result = resource_name .. "-tree",
        place_result = resource_name .. "-tree",
        fuel_category = "chemical",
        fuel_value = "100MJ",
        weight = 10000,
        localised_name = { "item-name.mystical-tree-seed", tranlatedkey }
      }
    })

    if minable.results and #minable.results > 0 then
      for _, r in ipairs(minable.results) do
        local ttk = r.name
        local first_result = data.raw.item[r.name]
        if first_result and first_result.localised_name then
          ttk = first_result.localised_name
        end
        data:extend({
          {
            type = "item",
            name = r.name .. "-log",
            icons = { {
              icon = "__MysticalForestry__/graphics/template-wood.png",
              icon_size = 64,
              scale = 0.5,
              tint = tint,
            } },
            subgroup = "mystical-agriculture-woods",
            order = "b[log]-" .. r.name,
            stack_size = 100,
            weight = 2000,
            localised_name = { "item-name.mystical-wood", ttk }
          }
        })
      end
    else
      data:extend({
        {
          type = "item",
          name = resource_name .. "-log",
          icons = { {
            icon = "__MysticalForestry__/graphics/template-wood.png",
            icon_size = 64,
            scale = 0.5,
            tint = tint,
          } },
          subgroup = "mystical-agriculture-woods",
          order = "b[log]-" .. resource_name,
          stack_size = 100,
          weight = 2000,
          localised_name = { "item-name.mystical-wood", tranlatedkey }
        }
      })
    end

    local results = get_mine_results(minable)
    if results then
      local has_fluid = false
      for _, r in pairs(results) do
        if r.type == "fluid" then has_fluid = true end
      end


      local recipe_icon = "__MysticalForestry__/graphics/missing.png"

      if minable.results and #minable.results > 0 then
        local first_result_name = minable.results[1].name
        local item_proto
        if has_fluid then
          item_proto = data.raw.fluid[first_result_name]
        else
          item_proto = data.raw.item[first_result_name]
        end
        if item_proto then
          if item_proto.icon then
            recipe_icon = item_proto.icon
          elseif item_proto.icons and #item_proto.icons > 0 then
            recipe_icon = item_proto.icons[1].icon
          end
        end
      elseif minable.result then
        local item_proto
        if has_fluid then
          item_proto = data.raw.fluid[minable.result]
        else
          item_proto = data.raw.item[minable.result]
        end
        if item_proto then
          if item_proto.icon then
            recipe_icon = item_proto.icon
          elseif item_proto.icons and #item_proto.icons > 0 then
            recipe_icon = item_proto.icons[1].icon
          end
        end
      end

      data:extend({
        {
          type = "recipe",
          name = raw_name .. "-from-log",
          category = "crafting",
          subgroup = "mystical-agriculture-processing",
          icon = recipe_icon,
          energy_required = 2,
          ingredients = get_mine_results_as_log(minable,1,resource_name),
          results = results,
          enabled = false,
          allow_productivity = not has_fluid,
          localised_name = { "recipe-name.from-log", tranlatedkey },
        }
      })
    end
  end
end
