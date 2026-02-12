require("__MysticalForestry__/prototypes/icons")
local func = {}
local seeds = {}
local infusion_crystal_cache = {}
local infusion_seed_cache = {}
local quality_seed_reciped_items = {
    [0] = { { type = "item", name = "iron-plate", amount = 50 }, { type = "item", name = "copper-plate", amount = 50 } },           -- normal
    [1] = { { type = "item", name = "steel-plate", amount = 50 }, { type = "item", name = "electronic-circuit", amount = 50 } },    -- uncommon
    [2] = { { type = "item", name = "engine-unit", amount = 10 }, { type = "item", name = "advanced-circuit", amount = 75 } },      -- rare
    [3] = { { type = "item", name = "holmium-plate", amount = 100 }, { type = "item", name = "tungsten-plate", amount = 100 }, { type = "item", name = "carbon-fiber", amount = 30 } }, -- epic
    [4] = { { type = "item", name = "wood", amount = 30 } },                                                        -- legendary
    [5] = { { type = "item", name = "quantum-processor", amount = 30 } }                                                              -- legendary
}

-- Settings
local techss = settings.startup["mystical-agriculture-technology-amount"].value
local crafting = settings.startup["mystical-agriculture-crafting-amount"].value

local counter = 0

-- Tree visual data (tree_08)
local tree_08 = { -- tree-08
    {             -- a
        trunk = { width = 210, height = 286, shift = util.by_pixel(-5, -58), scale = 0.5 },
        stump = { width = 76, height = 70, shift = util.by_pixel(3, -4), scale = 0.5 },
        shadow = { width = 310, height = 222, shift = util.by_pixel(71, 2), scale = 0.5 },
        leaves = { width = 262, height = 282, shift = util.by_pixel(-6, -77), scale = 0.5 },
        normal = { width = 260, height = 222, shift = util.by_pixel(-5, -91), scale = 0.5 }
    },
    { -- b
        trunk = { width = 238, height = 276, shift = util.by_pixel(-3, -55), scale = 0.5 },
        stump = { width = 76, height = 68, shift = util.by_pixel(1, -3), scale = 0.5 },
        shadow = { width = 322, height = 178, shift = util.by_pixel(77, -5), scale = 0.5 },
        leaves = { width = 322, height = 306, shift = util.by_pixel(-3, -70), scale = 0.5 },
        normal = { width = 322, height = 206, shift = util.by_pixel(-2, -95), scale = 0.5 }
    },
    { -- c
        trunk = { width = 210, height = 300, shift = util.by_pixel(3, -63), scale = 0.5 },
        stump = { width = 72, height = 66, shift = util.by_pixel(1, -4), scale = 0.5 },
        shadow = { width = 326, height = 228, shift = util.by_pixel(72, -2), scale = 0.5 },
        leaves = { width = 252, height = 294, shift = util.by_pixel(6, -83), scale = 0.5 },
        normal = { width = 254, height = 260, shift = util.by_pixel(6.5, -90), scale = 0.5 }
    },
    { -- d
        trunk = { width = 166, height = 228, shift = util.by_pixel(1, -45), scale = 0.5 },
        stump = { width = 74, height = 68, shift = util.by_pixel(4, -5), scale = 0.5 },
        shadow = { width = 274, height = 170, shift = util.by_pixel(71, 7), scale = 0.5 },
        leaves = { width = 214, height = 220, shift = util.by_pixel(0, -73), scale = 0.5 },
        normal = { width = 216, height = 182, shift = util.by_pixel(0.5, -82), scale = 0.5 }
    },
    { -- e
        trunk = { width = 172, height = 242, shift = util.by_pixel(-7, -49), scale = 0.5 },
        stump = { width = 76, height = 62, shift = util.by_pixel(3, -4), scale = 0.5 },
        shadow = { width = 296, height = 150, shift = util.by_pixel(65, 5), scale = 0.5 },
        leaves = { width = 228, height = 210, shift = util.by_pixel(2, -71), scale = 0.5 },
        normal = { width = 228, height = 166, shift = util.by_pixel(2.5, -79.5), scale = 0.5 }
    },
    { -- f
        trunk = { width = 166, height = 272, shift = util.by_pixel(-3, -55), scale = 0.5 },
        stump = { width = 70, height = 64, shift = util.by_pixel(-1, -3), scale = 0.5 },
        shadow = { width = 274, height = 170, shift = util.by_pixel(63, -7), scale = 0.5 },
        leaves = { width = 218, height = 294, shift = util.by_pixel(-2, -67), scale = 0.5 },
        normal = { width = 216, height = 200, shift = util.by_pixel(-1, -90.5), scale = 0.5 }
    },
    { -- g
        trunk = { width = 146, height = 222, shift = util.by_pixel(14, -43), scale = 0.5 },
        stump = { width = 68, height = 56, shift = util.by_pixel(3, -2), scale = 0.5 },
        shadow = { width = 272, height = 138, shift = util.by_pixel(64, -8), scale = 0.5 },
        leaves = { width = 190, height = 192, shift = util.by_pixel(12, -71), scale = 0.5 },
        normal = { width = 192, height = 164, shift = util.by_pixel(12.5, -77), scale = 0.5 }
    },
    { -- h
        trunk = { width = 160, height = 190, shift = util.by_pixel(-10, -34), scale = 0.5 },
        stump = { width = 62, height = 58, shift = util.by_pixel(-1, -1), scale = 0.5 },
        shadow = { width = 224, height = 128, shift = util.by_pixel(53, 7), scale = 0.5 },
        leaves = { width = 218, height = 174, shift = util.by_pixel(-9, -54), scale = 0.5 },
        normal = { width = 218, height = 152, shift = util.by_pixel(-8.5, -58.5), scale = 0.5 }
    },
    { -- i
        trunk = { width = 78, height = 176, shift = util.by_pixel(-2, -33), scale = 0.5 },
        stump = { width = 68, height = 62, shift = util.by_pixel(2, -4), scale = 0.5 },
        shadow = { width = 186, height = 102, shift = util.by_pixel(45, -5), scale = 0.5 },
        leaves = { width = 130, height = 168, shift = util.by_pixel(3, -60), scale = 0.5 },
        normal = { width = 128, height = 154, shift = util.by_pixel(4, -62.5), scale = 0.5 }
    },
    { -- j
        trunk = { width = 88, height = 180, shift = util.by_pixel(3, -33), scale = 0.5 },
        stump = { width = 64, height = 64, shift = util.by_pixel(3, -4), scale = 0.5 },
        shadow = { width = 208, height = 100, shift = util.by_pixel(46, -2), scale = 0.5 },
        leaves = { width = 162, height = 160, shift = util.by_pixel(3, -56), scale = 0.5 },
        normal = { width = 162, height = 148, shift = util.by_pixel(4, -58.5), scale = 0.5 }
    }
}

local letters = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" }

-- Helper functions
local function make_tree_variation(base_path, variant, tint)
    return {
        layers = {
            {
                filename = base_path .. "-trunk.png",
                width = variant.trunk.width,
                height = variant.trunk.height,
                shift = variant.trunk.shift,
                scale = variant.trunk.scale,
                tint = tint
            },
            {
                filename = base_path .. "-leaves.png",
                width = variant.leaves.width,
                height = variant.leaves.height,
                shift = variant.leaves.shift,
                scale = variant.leaves.scale,
                tint = tint
            },
            {
                filename = base_path .. "-shadow.png",
                width = variant.shadow.width,
                height = variant.shadow.height,
                shift = variant.shadow.shift,
                scale = variant.shadow.scale,
                draw_as_shadow = true
            }
        },
        normal_map = {
            filename = base_path .. "-normal.png",
            width = variant.normal.width,
            height = variant.normal.height,
            shift = variant.normal.shift,
            scale = variant.normal.scale
        },
        stump = {
            filename = base_path .. "-stump.png",
            width = variant.stump.width,
            height = variant.stump.height,
            shift = variant.stump.shift,
            scale = variant.stump.scale
        }
    }
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

local function get_mine_results_as_log(minable, ammtnb, resource_name, counter)
    ammtnb = ammtnb or 1

    if minable.results then
        local results = {}
        for _, value in pairs(minable.results) do
            local log_name = counter .. value.name .. "-log"
            if data.raw.item[log_name] then
                table.insert(results, { type = "item", name = log_name, amount = ammtnb, allow_quality = true })
            else
                table.insert(results, { type = "item", name = value.name, amount = ammtnb, allow_quality = true })
            end
        end
        return results
    elseif minable.result then
        local log_name = counter .. minable.result .. "-log"
        if data.raw.item[log_name] then
            return { { type = "item", name = log_name, amount = ammtnb, allow_quality = true } }
        else
            return { { type = "item", name = minable.result, amount = ammtnb, allow_quality = true } }
        end
    else
        local log_name = counter .. resource_name .. "-log"
        if data.raw.item[log_name] then
            return { { type = "item", name = log_name, amount = ammtnb, allow_quality = true } }
        else
            return { { type = "item", name = resource_name, amount = ammtnb, allow_quality = true } }
        end
    end
end

local function get_translated_key(minable, raw_name)
    if minable.results and #minable.results > 0 then
        local first_result = data.raw.item[minable.results[1].name]
        if first_result and first_result.localised_name then
            return first_result.localised_name
        end
    elseif minable.result then
        local item = data.raw.item[minable.result]
        if item and item.localised_name then
            return item.localised_name
        end
    end
    return raw_name
end

local function get_recipe_icon(minable, has_fluid)
    local recipe_icon = "__MysticalForestry__/graphics/missing.png"

    if minable.results and #minable.results > 0 then
        local first_result_name = minable.results[1].name
        local item_proto = has_fluid and data.raw.fluid[first_result_name] or data.raw.item[first_result_name]
        if item_proto then
            if item_proto.icon then
                recipe_icon = item_proto.icon
            elseif item_proto.icons and #item_proto.icons > 0 then
                recipe_icon = item_proto.icons[1].icon
            end
        end
    elseif minable.result then
        local item_proto = has_fluid and data.raw.fluid[minable.result] or data.raw.item[minable.result]
        if item_proto then
            if item_proto.icon then
                recipe_icon = item_proto.icon
            elseif item_proto.icons and #item_proto.icons > 0 then
                recipe_icon = item_proto.icons[1].icon
            end
        end
    end

    return recipe_icon
end

local function has_fluid_result(results)
    if not results then return false end
    for _, r in pairs(results) do
        if r.type == "fluid" then
            return true
        end
    end
    return false
end

function func.rgb_to_hex(color)
    color = color or { r = 1, g = 1, b = 1 }
    local rgb = {
        color.r or color[1] or 1,
        color.g or color[2] or 1,
        color.b or color[3] or 1
    }

    -- Convert 0-1 to 0-255 if needed
    if rgb[1] <= 1 and rgb[2] <= 1 and rgb[3] <= 1 then
        for i = 1, 3 do
            rgb[i] = math.ceil(rgb[i] * 255)
        end
    end

    local function to_hex(n)
        n               = math.max(0, math.min(255, n))
        local hex_chars = "0123456789ABCDEF"
        local high      = math.floor(n / 16) + 1
        local low       = (n % 16) + 1
        return hex_chars:sub(high, high) .. hex_chars:sub(low, low)
    end

    local hex = ""
    for i = 1, 3 do
        hex = hex .. to_hex(rgb[i])
    end
    return "#" .. hex
end

function func.get_item_localised_name(item_name)
    local proto = data.raw.item[item_name]
    if proto and proto.localised_name then
        return proto.localised_name
    end
    return item_name
end

function func.make_colored_quality_name(base_localised, quality)
    return {
        "",
        "[color=" .. func.rgb_to_hex(quality.color) .. "]",
        base_localised,
        " (",
        { "quality-name." .. quality.name },
        ")",
        "[/color]"
    }
end

function func.make_upgrade_recipe_name(from_item, from_quality, to_item, to_quality)
    return {
        "",
        "[color=" .. func.rgb_to_hex(from_quality.color) .. "]",
        func.get_item_localised_name(from_item),
        " (", { "quality-name." .. from_quality.name }, ")",
        "[/color] → ",
        "[color=" .. func.rgb_to_hex(to_quality.color) .. "]",
        func.get_item_localised_name(to_item),
        " (", { "quality-name." .. to_quality.name }, ")",
        "[/color]"
    }
end

local function create_log_recycling_recipe(raw_name, counter, minable, recipe_icon, tranlatedkey)
    data:extend({
        {
            type = "recipe",
            name = counter .. raw_name .. "-log-recycling",
            category = "recycling",
            subgroup = "mystical-agriculture-log-recycling",
            energy_required = 2,
            ingredients = {
                { type = "item", name = counter .. raw_name .. "-log", amount = 1 }
            },
            results = {
                { type = "item", name = counter .. raw_name .. "-log", amount = 1, probability = 0.5 }
            },
            icons = recipe_icon,
            order = "a[log-recycling]-" .. counter,
            enabled = false,
            allow_productivity = false,
            allow_quality = false,
            localised_name = { "recipe-name.log-recycling", tranlatedkey },
        }
    })
end

local function create_seed_recycling_recipe(raw_name, counter, minable, recipe_icon, tranlatedkey)
    data:extend({
        {
            type = "recipe",
            name = counter .. raw_name .. "-seed-recycling",
            category = "recycling",
            subgroup = "mystical-agriculture-seed-recycling",
            energy_required = 2,
            ingredients = {
                { type = "item", name = counter .. raw_name .. "-tree-seed", amount = 1 }
            },
            results = {
                { type = "item", name = counter .. raw_name .. "-tree-seed", amount = 1, probability = 0.5 }
            },
            icons = recipe_icon,
            order = "a[seed-recycling]-" .. counter,
            enabled = false,
            allow_productivity = false,
            allow_quality = false,
            localised_name = { "recipe-name.seed-recycling", tranlatedkey },
        }
    })
end

function func.create_quality_crystal(quality, previousQuality)
    local crystal = {
        type = "item",
        name = "mystical-agriculture-" .. quality.name .. "-crystal",
        icons = get_kwality_crsytal_icon(quality),
        subgroup = "mystical-agriculture-crystal",
        order = "a[crystal]-" .. quality.name,
        stack_size = 1,
        weight = 0,
        flags = { "not-stackable" },
        localised_name = {
            "", func.make_colored_quality_name("Infusion Crystal", quality) }

    }

    -- Only tiers above lowest should spoil
    if previousQuality then
        crystal.spoil_ticks = 60 * 60 * 10 - 1 -- 10 minutes
        crystal.spoil_result = "mystical-agriculture-" .. previousQuality.name .. "-crystal"
    else
        crystal.spoil_ticks = 60 * 60 * 60 * 24 - 1 -- take a full day to spoil, just to be annoying :D
        crystal.spoil_result = nil
    end

    table.insert(infusion_crystal_cache,
        { item = crystal, quality = quality, previousQuality = previousQuality or quality })

    data:extend({ crystal })
end

function func.create_master_crystal(previousQuality)
    local crystal = {
        type = "item",
        name = "mystical-agriculture-" .. "master" .. "-crystal",
        icons = get_master_crsytal_icon(),
        subgroup = "mystical-agriculture-crystal",
        order = "a[crystal]-" .. "master",
        stack_size = 1,
        weight = 1000000,
        flags = { "not-stackable" },
        localised_name = {
            "",
            "[color=#ff0000]Mas[/color]",
            "[color=#e5ff00]ter [/color]",
            "[color=#00ff00]Infu[/color]",
            "[color=#00a0ff]sion [/color]",
            "[color=#ff00ff]Crys[/color]",
            "[color=#ff0055]tal[/color]"
        }


    }
    table.insert(infusion_crystal_cache,
        { item = crystal, quality = { name = "master", level = 999 }, previousQuality = previousQuality })
    data:extend({ crystal })
end

function func.create_quality_essence(quality)
    data:extend({
        {
            type = "item",
            name = "mystical-agriculture-" .. quality.name .. "-essence",
            icons = { {
                icon = "__MysticalForestry__/graphics/tempalte_kwality_essence.png", --template-essence
                icon_size = 64,
                scale = 0.5,
                tint = quality.color,
            } },
            subgroup = "mystical-agriculture-essence",
            order = "a[essence]-" .. quality.name,
            stack_size = 1000,
            weight = 10,
            localised_name = { "", func.make_colored_quality_name("Essence", quality) }
        }
    })

    local resource_name = "mystical-agriculture-" .. quality.name .. "-essence"
    local resource_proto = {
        name = "mystical-agriculture-" .. quality.name .. "-essence",
        minable = {
            result = "mystical-agriculture-" .. quality.name .. "-essence",
            count = 1
        }
    }
    local minable = resource_proto.minable
    local recipe_icon = get_recipe_icon(minable, false)
    local tint = quality.color
    local tranlatedkey = get_translated_key(minable, resource_name)
    local raw_name = "mystical-agriculture-" .. quality.name .. "-essence"


    local seed_item = {
        type = "item",
        name = raw_name .. "-tree-seed",
        icons = { {
            icon = "__MysticalForestry__/graphics/template-tree-seed.png",
            icon_size = 64,
            scale = 0.5,
            tint = tint,
        }, {
            icon = recipe_icon,
            scale = 0.35,
            tint = tint,
            icon_size = 64,
            shift = { 8, -8 },
        }, },
        subgroup = "mystical-agriculture-seeds",
        order = "a[seed]-" .. raw_name,
        stack_size = 10,
        plant_result = resource_name .. "-tree",
        place_result = resource_name .. "-tree",
        fuel_category = "chemical",
        fuel_value = "100MJ",
        weight = 10000,
        localised_name = { "", func.make_colored_quality_name("Essence tree seed", quality) }
    }
    data:extend({ seed_item })
    table.insert(infusion_seed_cache, { item = seed_item, quality = quality })
    data:extend({
        {
            type = "recipe",
            name = raw_name .. "-seed-recycling",
            category = "recycling",
            subgroup = "mystical-agriculture-seed-recycling",
            energy_required = 2,
            ingredients = {
                { type = "item", name = raw_name .. "-tree-seed", amount = 1 }
            },
            results = {
                { type = "item", name = raw_name .. "-tree-seed", amount = 1, probability = 0.5 }
            },
            icons =
            { {
                icon = "__MysticalForestry__/graphics/recycling.png",
                icon_size = 64,
                scale = 0.5,
                tint = tint,
            }, {
                icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                icon_size = 64,
                scale = 0.5,
                tint = tint,
            }, {
                icon = "__MysticalForestry__/graphics/recycling-top.png",
                icon_size = 64,
                scale = 0.5,
                tint = tint,
            }, {
                icon = recipe_icon,
                scale = 0.35,
                tint = tint,
                icon_size = 64,
                shift = { 8, -8 },
            }, },
            order = "a[seed-recycling]-" .. raw_name,
            enabled = false,
            allow_productivity = false,
            allow_quality = false,
            localised_name = { "recipe-name.seed-recycling", func.make_colored_quality_name("Essence tree seed", quality) },
        }
    })

    local pictures = {}
    for i, variant in ipairs(tree_08) do
        table.insert(
            pictures,
            make_tree_variation(
                "__MysticalForestry__/graphics/Testtree things/tree-08-" .. letters[i],
                variant,
                tint
            )
        )
    end

    local icon_name = resource_name:gsub("-ore$", "")
    -- Create plant
    data:extend({
        {
            type = "plant",
            name = resource_name .. "-tree",
            icons = { {
                icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                icon_size = 64,
                scale = 0.5,
                tint = tint,
            }, {
                icon = recipe_icon,
                scale = 0.35,
                tint = tint,
                icon_size = 64,
                shift = { 8, -8 },
            }, },
            growth_ticks = 60 * 60 * 5,
            fast_replaceable_group = resource_name .. "-tree",
            agricultural_tower_tint = {
                primary = tint,
                secondary = tint,
                tertiary = tint,
                quaternary = tint,
            },
            seed = raw_name .. "-tree-seed",
            quality_source = "item",
            quality_affects_yield = true,
            map_color = tint,
            friendly_map_color = tint,
            harvest_results = {
                { type = "item", name = minable.result,           amount_min = 5, amount_max = 10, allow_quality = true },
                { type = "item", name = raw_name .. "-tree-seed", amount_min = 1, amount_max = 2,  allow_quality = true },
            },
            allowed_effects = { "quality" },
            flags = { "placeable-neutral", "placeable-off-grid", "breaths-air", "not-upgradable" },
            selectable_in_game = true,
            collision_box = { { -0.398438, -0.398438 }, { 0.398438, 0.398438 } },
            selection_box = { { -0.898, -2.2 }, { 0.898, 0.598 } },
            minable = {
                mineable = true,
                transfer_entity_health_to_products = true,
                include_in_show_counts = true,
                mining_time = 0.5,
                results = {
                    { type = "item", name = minable.result,           amount_min = 5, amount_max = 10, allow_quality = true },
                    { type = "item", name = raw_name .. "-tree-seed", amount_min = 1, amount_max = 2,  allow_quality = true },
                }
            },
            localised_name = { "", func.make_colored_quality_name("Essence tree", quality) },
            pictures = pictures
        }
    })
end

function func.create_craft_category()
    data:extend({
        {
            type = "item-subgroup",
            name = "mystical-agriculture-essence-tree-up",
            group = "mystical-agricultures",
            order = "zzzzzz0",
            icon = "__MysticalForestry__/graphics/template-categoryIcon.png",
            icon_size = 64,
            localised_name = { "item-group-name.mystical-agricultures" },
        },
    })
    data:extend({
        {
            type = "item-subgroup",
            name = "mystical-agriculture-crystal-up",
            group = "mystical-agricultures",
            order = "zzzzzz00",
            icon = "__MysticalForestry__/graphics/template-categoryIcon.png",
            icon_size = 64,
            localised_name = { "item-group-name.mystical-agricultures" },
        },
    })

    local quality_list = {}
    for _, q in pairs(data.raw["quality"]) do
        if q.name ~= "quality-unknown" then
            table.insert(quality_list, q)
        end
    end

    table.sort(quality_list, function(a, b)
        return a.level < b.level
    end)

    for idx, k in ipairs(quality_list) do
        data:extend({
            {
                type = "item-subgroup",
                name = "mystical-agriculture-essence-up-" .. k.name,
                group = "mystical-agricultures",
                order = string.format("zzzzzzz%02d", idx),
                icon = "__MysticalForestry__/graphics/template-categoryIcon.png",
                icon_size = 64,
                localised_name = { "item-group-name.mystical-agricultures" },
            },
        })
    end

    data:extend({
        {
            type = "item-subgroup",
            name = "mystical-agriculture-essence-up-" .. "master",
            group = "mystical-agricultures",
            order = string.format("zzzzzzz%02d", quality_list and #quality_list + 1 or 0),
            icon = "__MysticalForestry__/graphics/template-categoryIcon.png",
            icon_size = 64,
            localised_name = { "item-group-name.mystical-agricultures" },
        },
    })
end

function func.create_essence_recipe()
    local recipes = {}

    -- Base (Normal) Tier Recipe
    table.sort(infusion_crystal_cache, function(a, b)
        return a.quality.level < b.quality.level
    end)
    table.insert(recipes, {
        type = "recipe",
        name = "mystical-agriculture-essence-base",
        category = "crafting",
        subgroup = "mystical-agriculture-essence-tree-up",
        energy_required = 5,
        main_product = "mystical-agriculture-normal-essence-tree-seed",
        order = string.format(
            "a[upgrade]-%02d",
            0 -- original essence tier
        ),
        ingredients = {
            { type = "item", name = "iron-ore",   amount = 1000 },
            { type = "item", name = "copper-ore", amount = 1000 },
            { type = "item", name = "coal",       amount = 1000 },
            { type = "item", name = "stone",      amount = 1000 },
        },
        results = {
            {
                type = "item",
                name = "mystical-agriculture-normal-essence-tree-seed",
                amount_min = 1,
                amount_max = 4,
                probability = 0.28
            },
            {
                type = "item",
                name = "mystical-agriculture-normal-crystal",
                amount = 1
            }
        },
        enabled = true,
        allow_productivity = false,
        allow_quality = false,
        localised_name = { "recipe-name.quality-seed-crafting", func.get_item_localised_name("mystical-agriculture-normal-essence") }
    })

    for i, value in ipairs(infusion_crystal_cache) do
        if value.previousQuality then
            local current = value.quality
            local previous = value.previousQuality
            -- inside the recipe generation loop
            if current.level ~= previous.level and data.raw.item["mystical-agriculture-" .. current.name .. "-essence"] then
                local sname = "mystical-agriculture-" .. current.name .. "-essence-tree-seed"
                local ingredients = {}
                local ingredients = {}
                if data.raw["quality"]["normal"].level >= current.level then
                    ingredients = table.deepcopy(quality_seed_reciped_items[0]) or {}
                elseif data.raw["quality"]["legendary"].level <= current.level then
                    ingredients = table.deepcopy(quality_seed_reciped_items[5]) or {}
                else
                    ingredients = table.deepcopy(quality_seed_reciped_items[current.level]) or {}
                end

                if not previous then
                    table.insert(ingredients, { type = "item", name = sname, amount = 1 })
                else
                    table.insert(ingredients,
                    { type = "item", name = "mystical-agriculture-" .. previous.name .. "-essence-tree-seed", amount = 1 })
                end
                table.insert(ingredients,
                    { type = "item", name = "mystical-agriculture-" .. current.name .. "-essence", amount = 100 })
                data:extend({
                    {
                        type = "recipe",
                        name = "mystical-agriculture-" .. sname .. "-crafting",
                        category = "crafting",
                        subgroup = "mystical-agriculture-essence-tree-up",
                        energy_required = 1,
                        order = string.format(
                            "b[upgrade]-%02d",
                            current.level -- original essence tier
                        ),
                        ingredients = ingredients,
                        main_product = "mystical-agriculture-" .. current.name .. "-essence-tree-seed",
                        results = { { type = "item", name = "mystical-agriculture-" .. current.name .. "-essence-tree-seed", amount = 1 } },
                        enabled = false,
                        hidden = false,
                        localised_name = { "recipe-name.quality-seed-crafting", func.get_item_localised_name("mystical-agriculture-" .. current.name .. "-essence") }
                    }
                })
            end

            -- Any crystal tier >= current tier
            for j = i, #infusion_crystal_cache do
                local crystalTier = infusion_crystal_cache[j].quality
                local recipe_order = string.format(
                    "b[upgrade]-%02d",
                    crystalTier.level
                )
                if current.level ~= previous.level and data.raw.item["mystical-agriculture-" .. current.name .. "-essence"] then
                    table.insert(recipes, {
                        type = "recipe",
                        name =
                            "mystical-agriculture-essence-upgrade-" ..
                            previous.name .. "-to-" ..
                            current.name .. "-using-" ..
                            crystalTier.name,

                        category = "crafting",
                        subgroup = "mystical-agriculture-essence-up-" .. current.name,
                        energy_required = 5,
                        order = recipe_order,

                        main_product =
                            "mystical-agriculture-" .. current.name .. "-essence",

                        ingredients = {
                            {
                                type = "item",
                                name = "mystical-agriculture-" .. previous.name .. "-essence",
                                amount = 1000
                            },
                            {
                                type = "item",
                                name = "mystical-agriculture-" .. crystalTier.name .. "-crystal",
                                amount = 1
                            }
                        },

                        results = {
                            {
                                type = "item",
                                name = "mystical-agriculture-" .. current.name .. "-essence",
                                amount = 1
                            },
                            {
                                type = "item",
                                name = "mystical-agriculture-" .. crystalTier.name .. "-crystal",
                                amount = 1
                            }
                        },

                        enabled = false,
                        allow_productivity = false,
                        allow_quality = false,
                        localised_name = { "recipe-name.essence-upgrade", func.get_item_localised_name("mystical-agriculture-" .. previous.name .. "-essence"), func.get_item_localised_name("mystical-agriculture-" .. current.name .. "-essence") }
                    })
                end
            end
            -- Crystal Infusion (Lower → Higher Tier)
            if value.quality.next then
                table.insert(recipes, {
                    type = "recipe",
                    name = "mystical-agriculture-crystal-infuse-" .. current.name .. "-to-" .. value.quality.next,
                    category = "crafting",
                    subgroup = "mystical-agriculture-crystal-up",
                    energy_required = 5,
                    main_product = "mystical-agriculture-" .. value.quality.next .. "-crystal",
                    reset_freshness_on_craft = true,
                    result_is_always_fresh = true,
                    order = string.format(
                        "b[upgrade]-%02d",
                        current.level -- original essence tier
                    ),
                    ingredients = {
                        {
                            type = "item",
                            name = "mystical-agriculture-" .. current.name .. "-essence",
                            amount = 1000
                        },
                        {
                            type = "item",
                            name = "mystical-agriculture-" .. current.name .. "-crystal",
                            amount = 1
                        }
                    },
                    results = {
                        {
                            type = "item",
                            name = "mystical-agriculture-" .. value.quality.next .. "-crystal",
                            amount = 1
                        }
                    },
                    enabled = false,
                    allow_productivity = false,
                    allow_quality = false,

                    localised_name = { "recipe-name.crystal-infuse", func.get_item_localised_name("mystical-agriculture-" .. current.name .. "-crystal"), func.get_item_localised_name("mystical-agriculture-" .. value.quality.next .. "-crystal") }
                })
            end
        end
    end

    -- get highest tier crystal
    local highest_crystal = infusion_crystal_cache[#infusion_crystal_cache - 1].quality
    local master_crystal_name = "mystical-agriculture-master-crystal"

    -- gather all essence ingredients
    local essence_ingredients = {}
    for _, value in ipairs(infusion_crystal_cache) do
        if data.raw.item["mystical-agriculture-" .. value.quality.name .. "-essence"] then
            table.insert(essence_ingredients, {
                type = "item",
                name = "mystical-agriculture-" .. value.quality.name .. "-essence",
                amount = 1000
            })
        end
    end

    -- add highest tier crystal ingredient
    table.insert(essence_ingredients, {
        type = "item",
        name = "mystical-agriculture-" .. highest_crystal.name .. "-crystal",
        amount = 1
    })

    -- define master crystal recipe
    data:extend({
        {
            type = "recipe",
            name = "mystical-agriculture-master-crystal",
            category = "crafting",
            subgroup = "mystical-agriculture-crystal-up",
            energy_required = 10,
            ingredients = essence_ingredients,
            results = {
                {
                    type = "item",
                    name = master_crystal_name,
                    amount = 1,
                    quality = highest_crystal.name -- master inherits highest quality
                }
            },
            enabled = false,
            allow_productivity = false,
            allow_quality = false,
            order = "zzzzzzz99"
        }
    })

    data:extend(recipes)
end

-- Main processing loop - optimized to iterate only once

function func.initialize_prototypes()
    for resource_name, resource_proto in pairs(data.raw.resource) do
        local minable = resource_proto.minable

        if minable then
            counter = counter + 1

            -- Extract basic info once
            local raw_name = (minable.results and #minable.results > 0 and minable.results[1].name) or minable.result or
                resource_name
            local icon_name = resource_name:gsub("-ore$", "")
            local tint = get_resource_tint(resource_name, resource_proto)
            local tranlatedkey = get_translated_key(minable, raw_name)
            local results = get_mine_results(minable)
            local has_fluid = has_fluid_result(results)


            -- ITEMS CREATION


            -- Create seed item

            local seeds_item = {
                type = "item",
                name = counter .. raw_name .. "-tree-seed",
                icons = { {
                    icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                    icon_size = 64,
                    scale = 0.5,
                    tint = tint,
                } },
                subgroup = "mystical-agriculture-seeds",
                order = "a[seed]-" .. raw_name,
                stack_size = 10,
                plant_result = counter .. resource_name .. "-tree",
                place_result = counter .. resource_name .. "-tree",
                fuel_category = "chemical",
                fuel_value = "100MJ",
                weight = 10000,
                localised_name = { "item-name.mystical-tree-seed", tranlatedkey }
            }
            data:extend({ seeds_item })

            table.insert(seeds, seeds_item)

            create_seed_recycling_recipe(
                raw_name,
                counter,
                minable,
                { {
                    icon = "__MysticalForestry__/graphics/recycling.png",
                    icon_size = 64,
                    scale = 0.5,
                    tint = tint,
                }, {
                    icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                    icon_size = 64,
                    scale = 0.5,
                    tint = tint,
                }, {
                    icon = "__MysticalForestry__/graphics/recycling-top.png",
                    icon_size = 64,
                    scale = 0.5,
                    tint = tint,
                } },
                tranlatedkey)
            local logrc = {}
            -- Create log items
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
                            name = counter .. r.name .. "-log",
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
                    table.insert(logrc, { type = "unlock-recipe", recipe = counter .. r.name .. "-log-recycling" })
                    create_log_recycling_recipe(
                        r.name,
                        counter,
                        minable,
                        { {
                            icon = "__MysticalForestry__/graphics/recycling.png",
                            icon_size = 64,
                            scale = 0.5,
                            tint = tint,
                        }, {
                            icon = "__MysticalForestry__/graphics/template-wood.png",
                            icon_size = 64,
                            scale = 0.5,
                            tint = tint,
                        }, {
                            icon = "__MysticalForestry__/graphics/recycling-top.png",
                            icon_size = 64,
                            scale = 0.5,
                            tint = tint,
                        } },
                        tranlatedkey)
                end
            else
                data:extend({
                    {
                        type = "item",
                        name = counter .. resource_name .. "-log",
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
                table.insert(logrc, { type = "unlock-recipe", recipe = counter .. resource_name .. "-log-recycling" })
                create_log_recycling_recipe(
                    resource_name,
                    counter,
                    minable,
                    { {
                        icon = "__MysticalForestry__/graphics/recycling.png",
                        icon_size = 64,
                        scale = 0.5,
                        tint = tint,
                    }, {
                        icon = "__MysticalForestry__/graphics/template-wood.png",
                        icon_size = 64,
                        scale = 0.5,
                        tint = tint,
                    }, {
                        icon = "__MysticalForestry__/graphics/recycling-top.png",
                        icon_size = 64,
                        scale = 0.5,
                        tint = tint,
                    } },
                    tranlatedkey)
            end



            -- PLANT CREATION


            -- Generate tree pictures
            local pictures = {}
            for i, variant in ipairs(tree_08) do
                table.insert(
                    pictures,
                    make_tree_variation(
                        "__MysticalForestry__/graphics/Testtree things/tree-08-" .. letters[i],
                        variant,
                        tint
                    )
                )
            end

            -- Create plant
            data:extend({
                {
                    type = "plant",
                    name = counter .. resource_name .. "-tree",
                    icons = { {
                        icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                        icon_size = 64,
                        scale = 0.5,
                        tint = tint,
                    } },
                    growth_ticks = 60 * 60 * 5,
                    fast_replaceable_group = counter .. resource_name .. "-tree",
                    agricultural_tower_tint = {
                        primary = tint,
                        secondary = tint,
                        tertiary = tint,
                        quaternary = tint,
                    },
                    seed = counter .. raw_name .. "-tree-seed",
                    quality_source = "item",
                    quality_affects_yield = true,
                    map_color = tint,
                    friendly_map_color = tint,
                    harvest_results = {
                        {
                            type = "item",
                            name = counter .. icon_name .. "-log",
                            amount = 4,
                            allow_quality = true
                        }
                    },
                    allowed_effects = { "quality" },
                    flags = { "placeable-neutral", "placeable-off-grid", "breaths-air", "not-upgradable" },
                    selectable_in_game = true,
                    collision_box = { { -0.398438, -0.398438 }, { 0.398438, 0.398438 } },
                    selection_box = { { -0.898, -2.2 }, { 0.898, 0.598 } },
                    minable = {
                        mineable = true,
                        transfer_entity_health_to_products = true,
                        include_in_show_counts = true,
                        mining_time = 0.5,
                        results = get_mine_results_as_log(minable, 4, resource_name, counter)
                    },
                    localised_name = { "plant-name.mystical-tree", tranlatedkey },
                    pictures = pictures
                }
            })


            -- RECIPES CREATION


            if results then
                local recipe_icon = get_recipe_icon(minable, has_fluid)

                -- Prepare results with crafting amounts
                local recipe_results = {}
                for _, r in pairs(results) do
                    local result_copy = {}
                    for k, v in pairs(r) do
                        result_copy[k] = v
                    end
                    result_copy.amount = crafting
                    table.insert(recipe_results, result_copy)
                end

                -- Recipe: from-log
                data:extend({
                    {
                        type = "recipe",
                        name = counter .. raw_name .. "-from-log",
                        category = has_fluid and "crafting-with-fluid" or "crafting",
                        subgroup = "mystical-agriculture-processing",
                        energy_required = 2,
                        ingredients = get_mine_results_as_log(minable, 2, resource_name, counter),
                        results = recipe_results,
                        icon = recipe_icon,
                        order = "a[from-log]-" .. counter,
                        enabled = false,
                        allow_productivity = not has_fluid,
                        localised_name = { "recipe-name.from-log", tranlatedkey },
                    }
                })

                -- Recipe: tree-seed-crafting
                local seed_crafting_ingredients = {}
                for _, r in pairs(results) do
                    table.insert(seed_crafting_ingredients, { type = r.type or "item", name = r.name, amount = 100 })
                end

                table.insert(seed_crafting_ingredients,
                    { type = "item", name = "mystical-agriculture-normal-essence-tree-seed", amount = 1 })

                data:extend({
                    {
                        type = "recipe",
                        name = counter .. raw_name .. "-tree-seed-crafting",
                        category = has_fluid and "crafting-with-fluid" or "crafting",
                        subgroup = "mystical-agriculture-infusion",
                        energy_required = 2,
                        ingredients = seed_crafting_ingredients,
                        results = { { type = "item", name = counter .. raw_name .. "-tree-seed", amount = 1 } },
                        order = "b[tree-seed-crafting]-" .. counter,
                        icons = { {
                            icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                            icon_size = 64,
                            scale = 0.5,
                            tint = tint,
                        } },
                        allow_quality = false,
                        enabled = false,
                        localised_name = { "recipe-name.tree-seed-crafting", tranlatedkey },
                    }
                })

                -- Recipe: tree-seed-from-log
                data:extend({
                    {
                        type = "recipe",
                        name = counter .. raw_name .. "-tree-seed-from-log",
                        category = "crafting",
                        subgroup = "mystical-agriculture-reprocessing",
                        energy_required = 1,
                        ingredients = get_mine_results_as_log(minable, 1, resource_name, counter),
                        results = { { type = "item", name = counter .. raw_name .. "-tree-seed", amount = 1 } },
                        order = "c[tree-seed-from-log]-" .. counter,
                        icons = { {
                            icon = "__MysticalForestry__/graphics/template-wood-processing.png",
                            icon_size = 64,
                            scale = 0.5,
                            tint = tint,
                        } },
                        allow_quality = false,
                        enabled = false,
                        localised_name = { "recipe-name.tree-seed-from-log", tranlatedkey },
                    }
                })
            end

            -- TECHNOLOGY CREATION
            table.insert(logrc, { type = "unlock-recipe", recipe = counter .. raw_name .. "-tree-seed-crafting" })
            table.insert(logrc, { type = "unlock-recipe", recipe = counter .. raw_name .. "-tree-seed-from-log" })
            table.insert(logrc, { type = "unlock-recipe", recipe = counter .. raw_name .. "-from-log" })
            table.insert(logrc, { type = "unlock-recipe", recipe = counter .. raw_name .. "-seed-recycling" })
            local tech = {
                type = "technology",
                name = "mystical-" .. raw_name,
                icons = { {
                    icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                    icon_size = 64,
                    scale = 0.5,
                    tint = tint,
                } },
                hidden = false,
                effects = logrc,
                prerequisites = { "mystical-trigger-mystical-agriculture-uncommon-essence-tree-seed" },
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
end

function func.create_custom_prototypes(item_proto, has_tech, use_custom_icon, enabled_by_default, custom_icon)
    -- Validate input
    if not item_proto or not item_proto.name then
        item_proto.name = counter .. "unknown-item"
    end

    local item_name = item_proto.name

    -- Try to find associated resource
    local resource_proto = nil
    local resource_name = nil

    -- Search for a resource that produces this item
    for res_name, res_proto in pairs(data.raw.resource) do
        if res_proto.minable then
            local minable = res_proto.minable

            -- Check if this resource produces the item
            if minable.result == item_name then
                resource_proto = res_proto
                resource_name = res_name
                break
            elseif minable.results then
                for _, result in pairs(minable.results) do
                    if result.name == item_name then
                        resource_proto = res_proto
                        resource_name = res_name
                        break
                    end
                end
                if resource_name then break end
            end
        end
    end

    -- If no resource found, create a synthetic minable structure from the item
    if not resource_proto then
        resource_name = item_name
        resource_proto = {
            name = item_name,
            minable = {
                result = item_name,
                count = 1
            }
        }
    end

    local minable = resource_proto.minable



    if minable then
        counter = counter + 1

        -- Extract basic info once
        local raw_name = item_name -- Use the item name directly
        local icon_name = resource_name:gsub("-ore$", "")

        -- Get tint - use item's color_hint or derive from resource
        local tint = nil
        if item_proto.color_hint and item_proto.color_hint.tint then
            tint = item_proto.color_hint.tint
        elseif item_proto.random_tint_color then
            tint = item_proto.random_tint_color
        else
            tint = get_resource_tint(resource_name, resource_proto)
        end

        -- Get localised name - use item's localised_name if available
        local tranlatedkey = item_proto.localised_name or get_translated_key(minable, raw_name)

        -- Get results
        local results = get_mine_results(minable)
        local has_fluid = has_fluid_result(results)


        local recipe_icon = get_recipe_icon(minable, has_fluid)
        if item_proto.icon then
            recipe_icon = item_proto.icon
        elseif item_proto.icons and #item_proto.icons > 0 then
            recipe_icon = item_proto.icons[1].icon
        end



        -- ITEMS CREATION


        -- Create seed item
        local seed_item = {
            type = "item",
            name = counter .. raw_name .. "-tree-seed",
            icons = { {
                icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                icon_size = 64,
                scale = 0.5,
                tint = tint,
            }, custom_icon or {
                icon = recipe_icon,
                scale = use_custom_icon and 0.35 or 0, -- Only show the original icon if use_custom_icon is true
                icon_size = 64,
                shift = { 8, -8 },                     -- Shift the original icon to the top-right corner
            }, },
            subgroup = "mystical-agriculture-seeds",
            order = "a[seed]-" .. raw_name,
            stack_size = 10,
            plant_result = counter .. resource_name .. "-tree",
            place_result = counter .. resource_name .. "-tree",
            fuel_category = "chemical",
            fuel_value = "100MJ",
            weight = 10000,
            localised_name = { "item-name.mystical-tree-seed", tranlatedkey }
        }

        data:extend({ seed_item })

        table.insert(seeds, seed_item)

        create_seed_recycling_recipe(
            raw_name,
            counter,
            minable,
            { {
                icon = "__MysticalForestry__/graphics/recycling.png",
                icon_size = 64,
                scale = 0.5,
                tint = tint,
            }, {
                icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                icon_size = 64,
                scale = 0.5,
                tint = tint,
            }, {
                icon = "__MysticalForestry__/graphics/recycling-top.png",
                icon_size = 64,
                scale = 0.5,
                tint = tint,
            }, custom_icon or {
                icon = recipe_icon,
                use_custom_icon and 0.35 or 0,
                icon_size = 64,
                shift = { 8, -8 }, -- Shift the original icon to the top-right corner
            }, },
            tranlatedkey)

        local logrc = {}
        -- Create log items
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
                        name = counter .. r.name .. "-log",
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
                table.insert(logrc, { type = "unlock-recipe", recipe = counter .. r.name .. "-log-recycling" })
                create_log_recycling_recipe(
                    r.name,
                    counter,
                    minable,
                    { {
                        icon = "__MysticalForestry__/graphics/recycling.png",
                        icon_size = 64,
                        scale = 0.5,
                        tint = tint,
                    }, {
                        icon = "__MysticalForestry__/graphics/template-wood.png",
                        icon_size = 64,
                        scale = 0.5,
                        tint = tint,
                    }, {
                        icon = "__MysticalForestry__/graphics/recycling-top.png",
                        icon_size = 64,
                        scale = 0.5,
                        tint = tint,
                    } },
                    tranlatedkey)
            end
        else
            data:extend({
                {
                    type = "item",
                    name = counter .. resource_name .. "-log",
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
            table.insert(logrc, { type = "unlock-recipe", recipe = counter .. resource_name .. "-log-recycling" })
            create_log_recycling_recipe(
                resource_name,
                counter,
                minable,
                { {
                    icon = "__MysticalForestry__/graphics/recycling.png",
                    icon_size = 64,
                    scale = 0.5,
                    tint = tint,
                }, {
                    icon = "__MysticalForestry__/graphics/template-wood.png",
                    icon_size = 64,
                    scale = 0.5,
                    tint = tint,
                }, {
                    icon = "__MysticalForestry__/graphics/recycling-top.png",
                    icon_size = 64,
                    scale = 0.5,
                    tint = tint,
                } },
                tranlatedkey)
        end



        -- PLANT CREATION


        -- Generate tree pictures
        local pictures = {}
        for i, variant in ipairs(tree_08) do
            table.insert(
                pictures,
                make_tree_variation(
                    "__MysticalForestry__/graphics/Testtree things/tree-08-" .. letters[i],
                    variant,
                    tint
                )
            )
        end

        -- Create plant
        data:extend({
            {
                type = "plant",
                name = counter .. resource_name .. "-tree",
                icons = { {
                    icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                    icon_size = 64,
                    scale = 0.5,
                    tint = tint,
                }, custom_icon or {
                    icon = recipe_icon,
                    use_custom_icon and 0.35 or 0,
                    icon_size = 64,
                    shift = { 8, -8 }, -- Shift the original icon to the top-right corner
                }, },
                growth_ticks = 60 * 60 * 5,
                fast_replaceable_group = counter .. resource_name .. "-tree",
                agricultural_tower_tint = {
                    primary = tint,
                    secondary = tint,
                    tertiary = tint,
                    quaternary = tint,
                },
                seed = counter .. raw_name .. "-tree-seed",
                quality_source = "item",
                quality_affects_yield = true,
                map_color = tint,
                friendly_map_color = tint,
                harvest_results = {
                    {
                        type = "item",
                        name = counter .. icon_name .. "-log",
                        amount = 4,
                        allow_quality = true
                    }
                },
                allowed_effects = { "quality" },
                flags = { "placeable-neutral", "placeable-off-grid", "breaths-air", "not-upgradable" },
                selectable_in_game = true,
                collision_box = { { -0.398438, -0.398438 }, { 0.398438, 0.398438 } },
                selection_box = { { -0.898, -2.2 }, { 0.898, 0.598 } },
                minable = {
                    mineable = true,
                    transfer_entity_health_to_products = true,
                    include_in_show_counts = true,
                    mining_time = 0.5,
                    results = get_mine_results_as_log(minable, 4, resource_name, counter)
                },
                localised_name = { "plant-name.mystical-tree", tranlatedkey },
                pictures = pictures
            }
        })


        -- RECIPES CREATION


        if results then
            -- Prepare results with crafting amounts
            local recipe_results = {}
            for _, r in pairs(results) do
                local result_copy = {}
                for k, v in pairs(r) do
                    result_copy[k] = v
                end
                result_copy.amount = crafting
                table.insert(recipe_results, result_copy)
            end

            -- Recipe: from-log
            data:extend({
                {
                    type = "recipe",
                    name = counter .. raw_name .. "-from-log",
                    category = has_fluid and "crafting-with-fluid" or "crafting",
                    subgroup = "mystical-agriculture-processing",
                    energy_required = 2,
                    ingredients = get_mine_results_as_log(minable, 2, resource_name, counter),
                    results = recipe_results,
                    icon = recipe_icon,
                    order = "a[from-log]-" .. counter,
                    enabled = enabled_by_default or false,
                    allow_productivity = not has_fluid,
                    localised_name = { "recipe-name.from-log", tranlatedkey },
                }
            })

            -- Recipe: tree-seed-crafting
            local seed_crafting_ingredients = {}
            for _, r in pairs(results) do
                table.insert(seed_crafting_ingredients, { type = r.type or "item", name = r.name, amount = 100 })
            end

            -- Check for wood and add/update it
            local has_wood = false
            for _, ingredient in pairs(seed_crafting_ingredients) do
                if ingredient.name == "wood" then
                    has_wood = true
                    ingredient.amount = ingredient.amount + 1
                    break
                end
            end
            if not has_wood then
                table.insert(seed_crafting_ingredients, { type = "item", name = "wood", amount = 1 })
            end

            data:extend({
                {
                    type = "recipe",
                    name = counter .. raw_name .. "-tree-seed-crafting",
                    category = has_fluid and "crafting-with-fluid" or "crafting",
                    subgroup = "mystical-agriculture-infusion",
                    energy_required = 2,
                    ingredients = seed_crafting_ingredients,
                    results = { { type = "item", name = counter .. raw_name .. "-tree-seed", amount = 1 } },
                    order = "b[tree-seed-crafting]-" .. counter,
                    icons = { {
                        icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                        icon_size = 64,
                        scale = 0.5,
                        tint = tint,
                    }, custom_icon or {
                        icon = recipe_icon,
                        use_custom_icon and 0.35 or 0,
                        icon_size = 64,
                        shift = { 8, -8 }, -- Shift the original icon to the top-right corner
                    }, },
                    enabled = enabled_by_default or false,
                    localised_name = { "recipe-name.tree-seed-crafting", tranlatedkey },
                }
            })

            -- Recipe: tree-seed-from-log
            data:extend({
                {
                    type = "recipe",
                    name = counter .. raw_name .. "-tree-seed-from-log",
                    category = "crafting",
                    subgroup = "mystical-agriculture-reprocessing",
                    energy_required = 1,
                    ingredients = get_mine_results_as_log(minable, 1, resource_name, counter),
                    results = { { type = "item", name = counter .. raw_name .. "-tree-seed", amount = 1 } },
                    order = "c[tree-seed-from-log]-" .. counter,
                    icons = { {
                        icon = "__MysticalForestry__/graphics/template-wood-processing.png",
                        icon_size = 64,
                        scale = 0.5,
                        tint = tint,
                    }, custom_icon or {
                        icon = recipe_icon,
                        use_custom_icon and 0.35 or 0,
                        icon_size = 64,
                        shift = { 8, -8 }, -- Shift the original icon to the top-right corner
                    }, },
                    enabled = enabled_by_default or false,
                    localised_name = { "recipe-name.tree-seed-from-log", tranlatedkey },
                }
            })
        end


        -- TECHNOLOGY CREATION


        table.insert(logrc, { type = "unlock-recipe", recipe = counter .. raw_name .. "-tree-seed-crafting" })
        table.insert(logrc, { type = "unlock-recipe", recipe = counter .. raw_name .. "-tree-seed-from-log" })
        table.insert(logrc, { type = "unlock-recipe", recipe = counter .. raw_name .. "-from-log" })
        table.insert(logrc, { type = "unlock-recipe", recipe = counter .. raw_name .. "-seed-recycling" })
        local tech = {
            type = "technology",
            name = "mystical-" .. raw_name,
            icons = { {
                icon = "__MysticalForestry__/graphics/template-tree-seed.png",
                icon_size = 64,
                scale = 0.5,
                tint = tint,
            }, custom_icon or {
                icon = recipe_icon,
                use_custom_icon and 0.35 or 0,
                icon_size = 64,
                shift = { 8, -8 }, -- Shift the original icon to the top-right corner
            }, },
            hidden = false,
            effects = logrc,
            prerequisites = { "mystical-trigger-mystical-agriculture-uncommon-essence-tree-seed" },
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

        if has_tech then data:extend({ tech }) end
    end
end

function func.place_icon_on_item(itemPrototype, qualityPrototype)
    local icons = {}
    if itemPrototype.icons then
        icons = func.insert_quality_icons(itemPrototype, qualityPrototype)
    else
        itemPrototype.icons = { { icon = itemPrototype.icon, icon_size = itemPrototype.icon_size } }
        icons = func.insert_quality_icons(itemPrototype, qualityPrototype)
        itemPrototype.icon = nil
    end
    return icons
end

function func.insert_quality_icons(itemPrototype, qualityPrototype)
    if qualityPrototype.icons then
        for _, icon in pairs(qualityPrototype.icons) do
            table.insert(itemPrototype.icons,
                { icon = icon.icon, tint = icon.tint, icon_size = icon.icon_size, scale = 0.25, shift = { -10, 10 } })
        end
    else
        table.insert(itemPrototype.icons,
            { icon = qualityPrototype.icon, icon_size = qualityPrototype.icon_size, scale = 0.25, shift = { -10, 10 } })
    end
    return itemPrototype.icons
end

function func.create_intermediate_seed(name, quality)
    local newResult = table.deepcopy(name)

    newResult.hidden = true
    newResult.hidden_in_factoriopedia = true
    newResult.subgroup = "mystical-agriculture-seeds"
    newResult.order = "zzzzzzzzzzzzzzzzzzzzzzzz" .. newResult.name .. "-" .. quality.name
    newResult.place_result = nil

    newResult.localised_name = { "", "[color=" .. func.rgb_to_hex(quality.color) .. "]", func.get_item_localised_name(
        newResult.name),
        " (", { "quality-name." .. quality.name }, ")", "[/color]" }
    newResult.spoil_result = nil
    newResult.spoil_ticks = 1
    newResult.spoil_to_trigger_result = {
        items_per_trigger = 1,
        trigger = {
            type = "direct",
            action_delivery = {
                type = "instant",
                source_effects = {
                    {
                        type = "script",
                        effect_id = "{to=" .. quality.name .. ",item=" .. newResult.name .. "}MYSTICAL_SEED"
                    }
                }
            }
        }
    }

    newResult.name = quality.name .. "-" .. newResult.name
    newResult.icons = func.place_icon_on_item(newResult, quality)

    data:extend({ newResult })
    return newResult
end

function func.create_quality_seed_recipe()
    local quality_list = {}
    for _, q in pairs(data.raw["quality"]) do
        if q.name ~= "quality-unknown" then
            table.insert(quality_list, q)
        end
    end

    table.sort(quality_list, function(a, b)
        return a.level < b.level
    end)

    for _, s in pairs(seeds) do
        local cc = 0
        local previousQuality
        for _, q in ipairs(quality_list) do
            if q.name == "normal" or q.name == "quality-unknown" then goto continue end
            local sseed_name = func.create_intermediate_seed(s, q)
            local seed_name = sseed_name.name
            -- add to upgrade seed's quality
            -- first check if the quality level is lower than normal if so just use normal's item and if it is higher than legendary then just use legendary's item
            local ingredients
            if data.raw["quality"]["normal"].level >= q.level then
                ingredients = table.deepcopy(quality_seed_reciped_items["normal"])
            elseif data.raw["quality"]["legendary"].level <= q.level then
                ingredients = table.deepcopy(quality_seed_reciped_items["legendary"])
            else
                ingredients = table.deepcopy(quality_seed_reciped_items[q.name])
            end
            if not previousQuality then
                table.insert(ingredients, { type = "item", name = s.name, amount = 1 })
            else
                table.insert(ingredients, { type = "item", name = s.name, amount = 1 }) -- would put the previous quality seed as ingredient but you can't add quality to normal recipe because I'm stupid
            end
            table.insert(ingredients,
                { type = "item", name = "mystical-agriculture-" .. q.name .. "-essence", amount = 100 })
            data:extend({
                {
                    type = "recipe",
                    name = "mystical-agriculture-" .. seed_name .. "-crafting",
                    category = "crafting",
                    subgroup = "mystical-agriculture-quality-seed-crafting",
                    energy_required = 1,
                    order = cc .. "a[crafting]-" .. s.name,
                    ingredients = ingredients,
                    main_product = seed_name,
                    results = { { type = "item", name = seed_name, amount = 1 } },
                    enabled = false,
                    hidden = false,
                    localised_name = { "recipe-name.quality-seed-crafting", func.get_item_localised_name(seed_name) },
                }
            })
            local tech = {
                type = "technology",
                name = "mystical-trigger-" .. sseed_name.name,
                icons = sseed_name.icons,
                effects = { { type = "unlock-recipe", recipe = "mystical-agriculture-" .. seed_name .. "-crafting" } },
                prerequisites = { "mystical-trigger-mystical-agriculture-" .. q.name .. "-essence-tree-seed", "mystical-trigger-mystical-agriculture-" .. q.name .. "-crystal" },
                localised_name = { "technology-name.mystical-ressource-seed-tech", func.get_item_localised_name(sseed_name.name) },
                order = "zzzzz[quality-seed-tech]-" .. "mystical-trigger-" .. sseed_name.name
            }
            tech.research_trigger = {
                type = "craft-item",
                item = { name = "mystical-agriculture-" .. q.name .. "-essence" },
                count = 1
            }
            data:extend({ tech })
            --mystical-trigger-mystical-agriculture-uncommon-essence-tree-seed
            cc = cc + 1
            previousQuality = q
            ::continue::
        end
    end
end

function func.trigger_tech_p2()
    local previousseed = nil
    local previoustech = nil
    for i, seed in ipairs(infusion_seed_cache) do
        if previousseed ~= nil then
            local eff
            if seed.quality.next == nil then
                eff = nil
            else
                eff = { { type = "unlock-recipe", recipe = "mystical-agriculture-" .. seed.item.name .. "-crafting" } }
            end
            local tech = {
                type = "technology",
                name = "mystical-trigger-" .. seed.item.name,
                icons = seed.item.icons,
                effects = eff,
                prerequisites = previoustech and { previoustech.name } or nil,
                localised_name = { "technology-name.mystical-essence-seed-tech", func.get_item_localised_name(seed.item.name) },
                order = "zzzzz[quality-seed-tech]-" .. "mystical-trigger-" .. seed.item.name
            }
            tech.research_trigger = {
                type = "craft-item",
                item = { name = previousseed.item.name },
                count = 1
            }
            data:extend({ tech })
            previoustech = tech
        end
        previousseed = seed
    end
end

function func.generate_trigger_techs()
    local previousCrycrystal
    local previoustech = nil
    for i, crystal in ipairs(infusion_crystal_cache) do
        if crystal.quality.level ~= crystal.previousQuality.level then
            local eff
            if previousCrycrystal.quality.next == nil then
                eff = { { type = "unlock-recipe", recipe = "mystical-agriculture-master-crystal" } }
            else
                eff = { { type = "unlock-recipe", recipe = "mystical-agriculture-crystal-infuse-" .. previousCrycrystal.quality.name .. "-to-" .. crystal.quality.name } }
                table.insert(eff,
                    {
                        type = "unlock-recipe",
                        recipe = "mystical-agriculture-essence-upgrade-" ..
                            previousCrycrystal.quality.name ..
                            "-to-" .. crystal.quality.name .. "-using-" .. crystal.quality.name
                    })
            end
            local tech = {
                type = "technology",
                name = "mystical-trigger-" .. crystal.item.name,
                icons = crystal.item.icons,
                effects = eff,
                prerequisites = previoustech and { previoustech.name } or nil,
                localised_name = { "technology-name.mystical-crystal-tech", func.get_item_localised_name(crystal.item.name) },
                order = "zzzzz[quality-seed-tech]-" .. "mystical-trigger-" .. crystal.item.name
            }
            tech.research_trigger = {
                type = "craft-item",
                item = { name = previousCrycrystal.item.name },
                count = 1
            }

            data:extend({ tech })
            previoustech = tech
        end
        previousCrycrystal = crystal
    end
end

function func.add_achievement()
    data:extend({
        {
            name = "craft-master-crystal",
            icon = "__MysticalForestry__/graphics/where_is_my_gauntlet.png",
            icon_size = 127,

            order = "g[progress]-z[master-crystal]",

            type = "achievement",
            achievement_type = "craft-item",
            item_product = "mystical-agriculture-" .. "master" .. "-crystal",
            amount = 1,
            allowed_without_fight = false,
            localised_name = {"","Where is my gauntlet ?"},
            localised_description = {"","I love shiny rocks too"}
        }
    })
end


return func
