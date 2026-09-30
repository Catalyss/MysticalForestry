require("__MysticalForestry__/prototypes/icons")

local func = {}

--[[
    FILE LAYOUT
      1. Config & shared state
      2. Tree sprite data
      3. Generic helpers (naming, colours, icons, resource lookup)
      4. Shared prototype builders (recycling recipes, seed sets)
      5. Public API
           5a. Colour / localisation helpers
           5b. Quality items (crystals, essences)
           5c. Subgroups
           5d. Essence / crystal recipes
           5e. Resource + custom-item seed sets
           5f. Quality seeds & trigger technologies
           5g. Achievement
      6. Static content (Essence Infuser, placeholder sprite)
]]

-- Okay so I'm keeping this for the forseeable future because I going to be lost and have to rewrite this file again in 7 months again.. again...
-- last time I removed all comment when building files ... no again :(

-- 1. CONFIG & SHARED STATE

local GFX          = "__MysticalForestry__/graphics/"
local MISSING_ICON = GFX .. "missing.png"
local ESSENCE_ICON = GFX .. "tempalte_kwality_essence.png"
local ESSENCE_PREFIX = "mystical-agriculture-"

local techss   = settings.startup["mystical-agriculture-technology-amount"].value
local crafting = settings.startup["mystical-agriculture-crafting-amount"].value

local counter = 0                  -- prefix that makes every generated prototype name unique
local seeds = {}                   -- every ore/custom seed item created (used for quality seeds)
local avoid_dupes = {}             -- output-signature -> true, prevents duplicate seeds
local infusion_crystal_cache = {}  -- { item, quality, previousQuality }
local infusion_seed_cache = {}     -- { item, quality }

-- Ingredients needed to upgrade a seed to a given quality level.
local quality_seed_reciped_items = {
    [0] = { { type = "item", name = "iron-plate", amount = 50 }, { type = "item", name = "copper-plate", amount = 50 } },                                                               -- normal
    [1] = { { type = "item", name = "steel-plate", amount = 50 }, { type = "item", name = "electronic-circuit", amount = 50 } },                                                        -- uncommon
    [2] = { { type = "item", name = "engine-unit", amount = 10 }, { type = "item", name = "advanced-circuit", amount = 75 } },                                                          -- rare
    [3] = { { type = "item", name = "holmium-plate", amount = 100 }, { type = "item", name = "tungsten-plate", amount = 100 }, { type = "item", name = "carbon-fiber", amount = 30 } }, -- epic
    [4] = { { type = "item", name = "wood", amount = 30 } },                                                                                                                            -- legendary
    [5] = { { type = "item", name = "quantum-processor", amount = 30 } }                                                                                                                -- legendary+
}

local SEED_RECIPE_DATA = "mystical-forestry-seed-recipes"

data:extend({
    { type = "mod-data", name = SEED_RECIPE_DATA, data = { entries = {}, trigger_techs = {} } }
})
local seed_recipe_entries = data.raw["mod-data"][SEED_RECIPE_DATA].data.entries
local trigger_techs       = data.raw["mod-data"][SEED_RECIPE_DATA].data.trigger_techs


-- 2. TREE SPRITE DATA (tree_08)
--    Each part is { width, height, shift_x, shift_y } (all drawn at scale 0.5)


local TREE_LETTERS = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" }

local TREE_VARIANTS = {
    { trunk = { 210, 286, -5, -58 }, stump = { 76, 70, 3, -4 },  shadow = { 310, 222, 71, 2 },  leaves = { 262, 282, -6, -77 }, normal = { 260, 222, -5, -91 } },
    { trunk = { 238, 276, -3, -55 }, stump = { 76, 68, 1, -3 },  shadow = { 322, 178, 77, -5 }, leaves = { 322, 306, -3, -70 }, normal = { 322, 206, -2, -95 } },
    { trunk = { 210, 300, 3, -63 },  stump = { 72, 66, 1, -4 },  shadow = { 326, 228, 72, -2 }, leaves = { 252, 294, 6, -83 },  normal = { 254, 260, 6.5, -90 } },
    { trunk = { 166, 228, 1, -45 },  stump = { 74, 68, 4, -5 },  shadow = { 274, 170, 71, 7 },  leaves = { 214, 220, 0, -73 },  normal = { 216, 182, 0.5, -82 } },
    { trunk = { 172, 242, -7, -49 }, stump = { 76, 62, 3, -4 },  shadow = { 296, 150, 65, 5 },  leaves = { 228, 210, 2, -71 },  normal = { 228, 166, 2.5, -79.5 } },
    { trunk = { 166, 272, -3, -55 }, stump = { 70, 64, -1, -3 }, shadow = { 274, 170, 63, -7 }, leaves = { 218, 294, -2, -67 }, normal = { 216, 200, -1, -90.5 } },
    { trunk = { 146, 222, 14, -43 }, stump = { 68, 56, 3, -2 },  shadow = { 272, 138, 64, -8 }, leaves = { 190, 192, 12, -71 }, normal = { 192, 164, 12.5, -77 } },
    { trunk = { 160, 190, -10, -34 }, stump = { 62, 58, -1, -1 }, shadow = { 224, 128, 53, 7 }, leaves = { 218, 174, -9, -54 }, normal = { 218, 152, -8.5, -58.5 } },
    { trunk = { 78, 176, -2, -33 },  stump = { 68, 62, 2, -4 },  shadow = { 186, 102, 45, -5 }, leaves = { 130, 168, 3, -60 },  normal = { 128, 154, 4, -62.5 } },
    { trunk = { 88, 180, 3, -33 },   stump = { 64, 64, 3, -4 },  shadow = { 208, 100, 46, -2 }, leaves = { 162, 160, 3, -56 },  normal = { 162, 148, 4, -58.5 } },
}

local function tree_layer(filename, d, extra)
    local layer = {
        filename = filename,
        width = d[1],
        height = d[2],
        shift = util.by_pixel(d[3], d[4]),
        scale = 0.5,
    }
    for k, v in pairs(extra or {}) do layer[k] = v end
    return layer
end

local function build_tree_pictures(tint)
    local pictures = {}
    for i, v in ipairs(TREE_VARIANTS) do
        local base = GFX .. "Testtree things/tree-08-" .. TREE_LETTERS[i]
        pictures[i] = {
            layers = {
                tree_layer(base .. "-trunk.png", v.trunk, { tint = tint }),
                tree_layer(base .. "-leaves.png", v.leaves, { tint = tint }),
                tree_layer(base .. "-shadow.png", v.shadow, { draw_as_shadow = true }),
            },
            normal_map = tree_layer(base .. "-normal.png", v.normal),
            stump = tree_layer(base .. "-stump.png", v.stump),
        }
    end
    return pictures
end

-- 3. GENERIC HELPERS
-- Naming 

local function item_label(item_name)
    local proto = data.raw.item[item_name]
    if proto and proto.localised_name then
        return proto.localised_name
    end
    return item_name
end

local function get_translated_key(minable, raw_name)
    if minable.results and #minable.results > 0 then
        local first = data.raw.item[minable.results[1].name]
        if first and first.localised_name then
            return first.localised_name
        end
    elseif minable.result then
        local item = data.raw.item[minable.result]
        if item and item.localised_name then
            return item.localised_name
        end
    end
    return raw_name
end

-- Minable results 

local function get_mine_results(minable)
    if minable.results then
        return minable.results
    elseif minable.result then
        return { { type = "item", name = minable.result, amount = minable.count or 1 } }
    end
    return nil
end

local function has_fluid_result(results)
    if not results then return false end
    for _, r in pairs(results) do
        if r.type == "fluid" then return true end
    end
    return false
end

local function make_result_key(results)
    local parts = {}
    for _, r in ipairs(results) do
        table.insert(parts, r.name)
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

-- Returns true the first time a given set of outputs is seen, false afterwards.
local function claim_unique_outputs(results)
    if not results then return false end
    local key = make_result_key(results)
    if avoid_dupes[key] then return false end
    avoid_dupes[key] = true
    return true
end

-- Ingredient entry pointing at the "<counter><name>-log" item if it exists,
-- otherwise at the plain item.
local function log_ingredient(base_name, amount)
    local log_name = counter .. base_name .. "-log"
    return {
        type = "item",
        name = data.raw.item[log_name] and log_name or base_name,
        amount = amount,
        allow_quality = true,
    }
end

local function get_mine_results_as_log(minable, amount, resource_name)
    amount = amount or 1
    local out = {}
    if minable.results then
        for _, v in pairs(minable.results) do
            table.insert(out, log_ingredient(v.name, amount))
        end
    else
        table.insert(out, log_ingredient(minable.result or resource_name, amount))
    end
    return out
end

-- Icons 

local function proto_icon(proto)
    if proto.icon then return proto.icon end
    if proto.icons and #proto.icons > 0 then return proto.icons[1].icon end
    return nil
end

local function get_recipe_icon(minable, has_fluid)
    local name = (minable.results and #minable.results > 0 and minable.results[1].name) or minable.result
    if not name then return MISSING_ICON end
    local proto = (has_fluid and data.raw.fluid or data.raw.item)[name]
    return (proto and proto_icon(proto)) or MISSING_ICON
end

local function tinted_layer(file, tint)
    return { icon = GFX .. file, icon_size = 64, scale = 0.5, tint = tint }
end

local function with_overlay(layers, overlay)
    if overlay then table.insert(layers, overlay) end
    return layers
end

local function recycling_icons(base_file, tint, overlay)
    return with_overlay({
        tinted_layer("recycling.png", tint),
        tinted_layer(base_file, tint),
        tinted_layer("recycling-top.png", tint),
    }, overlay)
end

local function corner_icon(icon, tint)
    return { icon = icon, icon_size = 64, scale = 0.35, tint = tint, shift = { 8, -8 } }
end

-- Recycling recipes 

local function add_recycling_recipe(p)
    data:extend({
        {
            type = "recipe",
            name = p.name,
            categories = { "recycling" },
            subgroup = p.subgroup,
            energy_required = 2,
            ingredients = { { type = "item", name = p.item, amount = 1 } },
            results = { { type = "item", name = p.item, amount = 1, independent_probability = 0.5 } },
            icons = p.icons,
            order = p.order,
            enabled = p.enabled or false,
            allow_productivity = false,
            allow_quality = false,
            localised_name = p.localised_name,
        }
    })
end

-- Quality upgrade ingredients 

local function quality_ingredients(level)
    local index
    if data.raw["quality"]["normal"].level >= level then
        index = 0
    elseif data.raw["quality"]["legendary"].level <= level then
        index = 5
    else
        index = level
    end
    return table.deepcopy(quality_seed_reciped_items[index]) or {}
end

local function sort_crystal_cache()
    table.sort(infusion_crystal_cache, function(a, b) return a.quality.level < b.quality.level end)
end


-- 4. SEED SET BUILDER
--    cfg fields:
--      resource_name, raw_name, minable, results, has_fluid
--      tint, localised, recipe_icon
--      overlay        optional extra icon layer drawn on top of the tree seed
--      tech_name      technology name, or nil to skip the technology
--      recipes_enabled, allow_quality   flags for the processing recipes
--      infuser_item   { name, amount } that goes in the infuser's item slot

local function build_seed_set(cfg)
    local id            = counter
    local resource_name = cfg.resource_name
    local raw_name      = cfg.raw_name
    local minable       = cfg.minable
    local results       = cfg.results
    local has_fluid     = cfg.has_fluid
    local tint          = cfg.tint
    local localised     = cfg.localised
    local overlay       = cfg.overlay

    local seed_name  = id .. raw_name .. "-tree-seed"
    local plant_name = id .. resource_name .. "-tree"
    local icon_name  = resource_name:gsub("-ore$", "")

    -- seed item
    local seed_item = {
        type = "item",
        name = seed_name,
        icons = with_overlay({ tinted_layer("template-tree-seed.png", tint) }, overlay),
        subgroup = "mystical-agriculture-seeds",
        order = "a[seed]-" .. raw_name,
        stack_size = 10,
        plant_result = plant_name,
        place_result = plant_name,
        fuel_categories = { "chemical" },
        fuel_value = "100MJ",
        weight = 10000,
        localised_name = { "item-name.mystical-tree-seed", localised },
    }
    data:extend({ seed_item })
    table.insert(seeds, seed_item)

    add_recycling_recipe({
        name = id .. raw_name .. "-seed-recycling",
        item = seed_name,
        subgroup = "mystical-agriculture-seed-recycling",
        icons = recycling_icons("template-tree-seed.png", tint, overlay),
        order = "a[seed-recycling]-" .. id,
        localised_name = { "recipe-name.seed-recycling", localised },
    })

    -- log items
    local unlocks = {}
    local log_ids = {}
    if minable.results and #minable.results > 0 then
        for _, r in ipairs(minable.results) do
            table.insert(log_ids, { id = r.name, label = item_label(r.name) })
        end
    else
        table.insert(log_ids, { id = resource_name, label = localised })
    end

    for _, log in ipairs(log_ids) do
        data:extend({
            {
                type = "item",
                name = id .. log.id .. "-log",
                icons = { tinted_layer("template-wood.png", tint) },
                subgroup = "mystical-agriculture-woods",
                order = "b[log]-" .. log.id,
                stack_size = 100,
                weight = 2000,
                localised_name = { "item-name.mystical-wood", log.label },
            }
        })
        add_recycling_recipe({
            name = id .. log.id .. "-log-recycling",
            item = id .. log.id .. "-log",
            subgroup = "mystical-agriculture-log-recycling",
            icons = recycling_icons("template-wood.png", tint),
            order = "a[log-recycling]-" .. id,
            localised_name = { "recipe-name.log-recycling", localised },
        })
        table.insert(unlocks, { type = "unlock-recipe", recipe = id .. log.id .. "-log-recycling" })
    end

    -- plant
    data:extend({
        {
            type = "plant",
            name = plant_name,
            icons = with_overlay({ tinted_layer("template-tree-seed.png", tint) }, overlay),
            growth_ticks = 60 * 60 * 5,
            fast_replaceable_group = plant_name,
            agricultural_tower_tint = { primary = tint, secondary = tint, tertiary = tint, quaternary = tint },
            seed = seed_name,
            quality_source = "item",
            quality_affects_yield = true,
            map_color = tint,
            friendly_map_color = tint,
            harvest_results = {
                { type = "item", name = id .. icon_name .. "-log", amount = 4, allow_quality = true },
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
                results = get_mine_results_as_log(minable, 4, resource_name),
            },
            localised_name = { "plant-name.mystical-tree", localised },
            pictures = build_tree_pictures(tint),
        }
    })

    -- recipes
    local category = has_fluid and "crafting-with-fluid" or "crafting"

    -- from-log: logs -> raw resource
    local recipe_results = {}
    for _, r in pairs(results) do
        local copy = {}
        for k, v in pairs(r) do copy[k] = v end
        copy.amount = crafting
        table.insert(recipe_results, copy)
    end

    data:extend({
        {
            type = "recipe",
            name = id .. raw_name .. "-from-log",
            categories = { category },
            subgroup = "mystical-agriculture-processing",
            energy_required = 2,
            ingredients = get_mine_results_as_log(minable, 2, resource_name),
            results = recipe_results,
            icon = cfg.recipe_icon,
            order = "a[from-log]-" .. id,
            enabled = cfg.recipes_enabled,
            allow_productivity = not has_fluid,
            localised_name = { "recipe-name.from-log", localised },
        },
        -- tree-seed-from-log: logs -> seed
        {
            type = "recipe",
            name = id .. raw_name .. "-tree-seed-from-log",
            categories = { "crafting" },
            subgroup = "mystical-agriculture-reprocessing",
            energy_required = 1,
            ingredients = get_mine_results_as_log(minable, 1, resource_name),
            results = { { type = "item", name = seed_name, amount = 1 } },
            order = "c[tree-seed-from-log]-" .. id,
            icons = with_overlay({ tinted_layer("template-wood-processing.png", tint) }, overlay),
            allow_quality = cfg.allow_quality,
            enabled = cfg.recipes_enabled,
            localised_name = { "recipe-name.tree-seed-from-log", localised },
        },
    })

    -- tree-seed-crafting
    -- Fluids are exported as fluids; control.lua swaps them for barrels at runtime
    -- because the infuser can't hold fluids.
        local ingredients = {}
        for _, r in pairs(results) do
        table.insert(ingredients, { type = r.type or "item", name = r.name, amount = 1000 })
        end
        table.insert(seed_recipe_entries, {
            item = cfg.infuser_item,
            ingredients = ingredients,
        return_item = { name = seed_name, amount = 1 },
        })

    -- technology
    if cfg.tech_name then
        table.insert(unlocks, { type = "unlock-recipe", recipe = id .. raw_name .. "-tree-seed-from-log" })
        table.insert(unlocks, { type = "unlock-recipe", recipe = id .. raw_name .. "-from-log" })
        table.insert(unlocks, { type = "unlock-recipe", recipe = id .. raw_name .. "-seed-recycling" })

        local tech = {
            type = "technology",
            name = cfg.tech_name,
            icons = with_overlay({ tinted_layer("template-tree-seed.png", tint) }, overlay),
            hidden = false,
            effects = unlocks,
            prerequisites = { "mystical-trigger-mystical-agriculture-uncommon-essence-tree-seed" },
            localised_name = { "technology-name.mystical-resource-tech", localised },
        }
        if has_fluid then
            tech.research_trigger = { type = "craft-fluid", fluid = raw_name, amount = techss }
        else
            tech.research_trigger = { type = "craft-item", item = { name = raw_name }, count = techss }
        end
        data:extend({ tech })
    end
end

-- 5a. Colour / localisation helpers 

function func.rgb_to_hex(color)
    color = color or { r = 1, g = 1, b = 1 }
    local rgb = {
        color.r or color[1] or 1,
        color.g or color[2] or 1,
        color.b or color[3] or 1,
    }

    -- Convert 0-1 to 0-255 if needed
    if rgb[1] <= 1 and rgb[2] <= 1 and rgb[3] <= 1 then
        for i = 1, 3 do
            rgb[i] = math.ceil(rgb[i] * 255)
        end
    end

    local hex_chars = "0123456789ABCDEF"
    local function to_hex(n)
        n = math.max(0, math.min(255, n))
        local high = math.floor(n / 16) + 1
        local low  = (n % 16) + 1
        return hex_chars:sub(high, high) .. hex_chars:sub(low, low)
    end

    return "#" .. to_hex(rgb[1]) .. to_hex(rgb[2]) .. to_hex(rgb[3])
end

func.get_item_localised_name = item_label

function func.make_colored_quality_name(base_localised, quality)
    return {
        "",
        "[color=" .. func.rgb_to_hex(quality.color) .. "]",
        base_localised,
        " (",
        { "quality-name." .. quality.name },
        ")",
        "[/color]",
    }
end

function func.make_upgrade_recipe_name(from_item, from_quality, to_item, to_quality)
    return {
        "",
        "[color=" .. func.rgb_to_hex(from_quality.color) .. "]",
        item_label(from_item),
        " (", { "quality-name." .. from_quality.name }, ")",
        "[/color] → ",
        "[color=" .. func.rgb_to_hex(to_quality.color) .. "]",
        item_label(to_item),
        " (", { "quality-name." .. to_quality.name }, ")",
        "[/color]",
    }
end

-- 5b. Quality items (crystals & essences) 

function func.create_quality_crystal(quality, previousQuality)
    local crystal = {
        type = "item",
        name = ESSENCE_PREFIX .. quality.name .. "-crystal",
        icons = get_kwality_crsytal_icon(quality),
        subgroup = "mystical-agriculture-crystal",
        order = "a[crystal]-" .. quality.name,
        stack_size = 1,
        weight = 0,
        flags = { "not-stackable" },
        localised_name = { "", func.make_colored_quality_name("Infusion Crystal", quality) },
    }

    -- Only tiers above the lowest spoil down to the tier below
    if previousQuality then
        crystal.spoil_ticks = 60 * 60 * 10 - 1 -- 10 minutes
        crystal.spoil_result = ESSENCE_PREFIX .. previousQuality.name .. "-crystal"
    else
        crystal.spoil_ticks = 60 * 60 * 60 * 24 - 1 -- a full day, just to be annoying :D
        crystal.spoil_result = nil
    end

    table.insert(infusion_crystal_cache,
        { item = crystal, quality = quality, previousQuality = previousQuality or quality })
    sort_crystal_cache()
    data:extend({ crystal })
end

function func.create_master_crystal(previousQuality)
    local crystal = {
        type = "item",
        name = ESSENCE_PREFIX .. "master-gaster-crystal",
        icons = get_master_crsytal_icon(),
        subgroup = "mystical-agriculture-crystal",
        order = "a[crystal]-master-gaster",
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
            "[color=#ff0055]tal[/color]",
        },
    }

    table.insert(infusion_crystal_cache,
        { item = crystal, quality = { name = "master-gaster", level = 999 }, previousQuality = previousQuality })
    sort_crystal_cache()
    data:extend({ crystal })
end

function func.create_quality_essence(quality)
    local raw_name  = ESSENCE_PREFIX .. quality.name .. "-essence"
    local seed_name = raw_name .. "-tree-seed"
    local plant_name = raw_name .. "-tree"
    local tint      = quality.color
    local overlay   = corner_icon(ESSENCE_ICON, tint)
    local seed_label = func.make_colored_quality_name("Essence tree seed", quality)

    -- Essence item
    data:extend({
        {
            type = "item",
            name = raw_name,
            icons = { { icon = ESSENCE_ICON, icon_size = 64, scale = 0.5, tint = tint } },
            subgroup = "mystical-agriculture-essence",
            order = "a[essence]-" .. quality.name,
            stack_size = 1000,
            weight = 10,
            localised_name = { "", func.make_colored_quality_name("Essence", quality) },
        }
    })

    -- Seed item
    local seed_item = {
        type = "item",
        name = seed_name,
        icons = with_overlay({ tinted_layer("template-tree-seed.png", tint) }, overlay),
        subgroup = "mystical-agriculture-seeds",
        order = "a[seed]-" .. raw_name,
        stack_size = 10,
        plant_result = plant_name,
        place_result = plant_name,
        fuel_categories = { "chemical" },
        fuel_value = "100MJ",
        weight = 10000,
        localised_name = { "", seed_label },
    }
    data:extend({ seed_item })
    table.insert(infusion_seed_cache, { item = seed_item, quality = quality })

    add_recycling_recipe({
        name = raw_name .. "-seed-recycling",
        item = seed_name,
        subgroup = "mystical-agriculture-seed-recycling",
        icons = recycling_icons("template-tree-seed.png", tint, overlay),
        order = "a[seed-recycling]-" .. raw_name,
        enabled = (quality.name == "normal"),
        localised_name = { "recipe-name.seed-recycling", seed_label },
    })

    -- Plant
    local harvest = {
        { type = "item", name = raw_name,  amount_min = 5, amount_max = 10, allow_quality = true },
        { type = "item", name = seed_name, amount_min = 1, amount_max = 2,  allow_quality = true },
    }
    data:extend({
        {
            type = "plant",
            name = plant_name,
            icons = with_overlay({ tinted_layer("template-tree-seed.png", tint) }, overlay),
            growth_ticks = 60 * 60 * 5,
            fast_replaceable_group = plant_name,
            agricultural_tower_tint = { primary = tint, secondary = tint, tertiary = tint, quaternary = tint },
            seed = seed_name,
            quality_source = "item",
            quality_affects_yield = true,
            map_color = tint,
            friendly_map_color = tint,
            harvest_results = harvest,
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
                results = harvest,
            },
            localised_name = { "", func.make_colored_quality_name("Essence tree", quality) },
            pictures = build_tree_pictures(tint),
        }
    })
end

-- 5c. Subgroups 

function func.create_craft_category()
    local function add_subgroup(name, order)
        data:extend({
            {
                type = "item-subgroup",
                name = name,
                group = "mystical-agricultures",
                order = order,
                icon = GFX .. "template-categoryIcon.png",
                icon_size = 64,
                localised_name = { "item-group-name.mystical-agricultures" },
            }
        })
    end

    add_subgroup("mystical-agriculture-essence-tree-up", "zzzzzz0")
    add_subgroup("mystical-agriculture-crystal-up", "zzzzzz00")
    add_subgroup("mystical-agriculture-infused-items", "zzzzzz000")

    local quality_list = {}
    for _, q in pairs(data.raw["quality"]) do
        if q.name ~= "quality-unknown" then
            table.insert(quality_list, q)
        end
    end
    table.sort(quality_list, function(a, b) return a.level < b.level end)

    for idx, q in ipairs(quality_list) do
        add_subgroup("mystical-agriculture-essence-up-" .. q.name, string.format("zzzzzzz%02d", idx))
    end

    add_subgroup("mystical-agriculture-essence-up-master-gaster", string.format("zzzzzzz%02d", #quality_list + 1))
end

-- 5d. Essence / crystal recipes 

function func.create_essence_recipe()
    local recipes = {}
    sort_crystal_cache()

    -- Base (normal tier) essence seed: infuser rule, no item/crystal input.
    -- 28% chance of 1-4 seeds, always returns a normal crystal.
    table.insert(seed_recipe_entries, {
        item = false,
        crystal = false,
        ingredients = {
            { type = "item", name = "iron-ore",   amount = 1000 },
            { type = "item", name = "copper-ore", amount = 1000 },
            { type = "item", name = "coal",       amount = 1000 },
            { type = "item", name = "stone",      amount = 1000 },
        },
        return_item = { { name = "mystical-agriculture-normal-essence-tree-seed", weight = 28, min = 1, max = 4 } },
        return_crystal = { name = "mystical-agriculture-normal-crystal", amount = 1 },
    })

    for i, value in ipairs(infusion_crystal_cache) do
        local current  = value.quality
        local previous = value.previousQuality

        if previous then
            local current_essence  = ESSENCE_PREFIX .. current.name .. "-essence"
            local previous_essence = ESSENCE_PREFIX .. previous.name .. "-essence"
            local is_upgrade = current.level ~= previous.level and data.raw.item[current_essence] ~= nil

            -- Essence tree seed upgrade: infuser rule
            --   previous seed (item slot) + 100 essence (essence_top) + tier materials
            if is_upgrade then
                table.insert(seed_recipe_entries, {
                    item = { name = previous_essence .. "-tree-seed", amount = 1 },
                    essence_top = { name = current_essence, amount = 100 },
                    ingredients = quality_ingredients(current.level),
                    return_item = { name = current_essence .. "-tree-seed", amount = 1 },
                })
            end

            -- Essence upgrade using any crystal tier >= current tier
            if is_upgrade then
                for j = i, #infusion_crystal_cache do
                    local crystal_tier = infusion_crystal_cache[j].quality
                    local crystal_name = ESSENCE_PREFIX .. crystal_tier.name .. "-crystal"
                    table.insert(recipes, {
                        type = "recipe",
                        name = "mystical-agriculture-essence-upgrade-" ..
                            previous.name .. "-to-" .. current.name .. "-using-" .. crystal_tier.name,
                        categories = { "crafting" },
                        subgroup = "mystical-agriculture-essence-up-" .. current.name,
                        energy_required = 5,
                        order = string.format("b[upgrade]-%02d", crystal_tier.level),
                        main_product = current_essence,
                        ingredients = {
                            { type = "item", name = previous_essence, amount = 1000 },
                            { type = "item", name = crystal_name,     amount = 1 },
                        },
                        results = {
                            { type = "item", name = current_essence, amount = 1 },
                            { type = "item", name = crystal_name,    amount = 1 },
                        },
                        enabled = false,
                        allow_productivity = false,
                        allow_quality = false,
                        localised_name = { "recipe-name.essence-upgrade", item_label(previous_essence), item_label(current_essence) },
                    })
                end
            end

            -- Crystal infusion (lower -> higher tier)
            local next_quality = current.next
            if next_quality then
                local current_crystal = ESSENCE_PREFIX .. current.name .. "-crystal"
                local next_crystal    = ESSENCE_PREFIX .. next_quality .. "-crystal"
                table.insert(recipes, {
                    type = "recipe",
                    name = "mystical-agriculture-crystal-infuse-" .. current.name .. "-to-" .. next_quality,
                    categories = { "crafting" },
                    subgroup = "mystical-agriculture-crystal-up",
                    energy_required = 5,
                    main_product = next_crystal,
                    order = string.format("b[upgrade]-%02d", current.level),
                    ingredients = {
                        { type = "item", name = current_essence, amount = 1000 },
                        { type = "item", name = current_crystal, amount = 1 },
                    },
                    results = {
                        {
                            type = "item",
                            name = next_crystal,
                            amount = 1,
                            reset_freshness_on_craft = true,
                            always_fresh = true,
                        },
                    },
                    enabled = false,
                    allow_productivity = false,
                    allow_quality = false,
                    localised_name = { "recipe-name.crystal-infuse", item_label(current_crystal), item_label(next_crystal) },
                })
            end
        end
    end

    -- Master crystal: one of every essence + the highest normal crystal
    -- (last cache entry is the master crystal itself, so take the one before it)
    local highest_crystal = infusion_crystal_cache[#infusion_crystal_cache - 1].quality

    local master_ingredients = {}
    for _, value in ipairs(infusion_crystal_cache) do
        local essence = ESSENCE_PREFIX .. value.quality.name .. "-essence"
        if data.raw.item[essence] then
            table.insert(master_ingredients, { type = "item", name = essence, amount = 1000 })
        end
    end
    table.insert(master_ingredients,
        { type = "item", name = ESSENCE_PREFIX .. highest_crystal.name .. "-crystal", amount = 1 })

    data:extend({
        {
            type = "recipe",
            name = "mystical-agriculture-master-gaster-crystal",
            categories = { "crafting" },
            subgroup = "mystical-agriculture-crystal-up",
            energy_required = 10,
            ingredients = master_ingredients,
            results = {
                {
                    type = "item",
                    name = "mystical-agriculture-master-gaster-crystal",
                    amount = 1,
                    quality = highest_crystal.name, -- master inherits highest quality
                },
            },
            enabled = false,
            allow_productivity = false,
            allow_quality = false,
            order = "zzzzzzz99",
        }
    })

    data:extend(recipes)
end

-- 5e. Resource + custom-item seed sets 

-- Every minable resource gets a seed set (unless another resource already
-- produces the same outputs).
function func.initialize_prototypes()
    for resource_name, resource_proto in pairs(data.raw.resource) do
        local minable = resource_proto.minable

        if minable then
            counter = counter + 1
            local results = get_mine_results(minable)

            if claim_unique_outputs(results) then
                local raw_name = (minable.results and #minable.results > 0 and minable.results[1].name)
                    or minable.result
                    or resource_name

                build_seed_set({
                    resource_name   = resource_name,
                    raw_name        = raw_name,
                    minable         = minable,
                    results         = results,
                    has_fluid       = has_fluid_result(results),
                    tint            = get_resource_tint(resource_name, resource_proto),
                    localised       = get_translated_key(minable, resource_name),
                    recipe_icon     = get_recipe_icon(minable, has_fluid_result(results)),
                    overlay         = nil,
                    tech_name       = counter .. "mystical-" .. raw_name,
                    recipes_enabled = false,
                    allow_quality   = false,
                    infuser_item    = { name = "mystical-agriculture-normal-essence-tree-seed", amount = 1 },
                })
            end
        end
    end
end

local function find_resource_for_item(item_name)
    for res_name, res_proto in pairs(data.raw.resource) do
        local minable = res_proto.minable
        if minable then
            if minable.result == item_name then
                return res_name, res_proto
            elseif minable.results then
                for _, result in pairs(minable.results) do
                    if result.name == item_name then
                        return res_name, res_proto
                    end
                end
            end
        end
    end
    return nil, nil
end

-- Builds a seed set for an arbitrary item (used by other files for custom seeds).
function func.create_custom_prototypes(item_proto, has_tech, use_custom_icon, enabled_by_default, custom_icon)
    item_proto = item_proto or {}
    if not item_proto.name then
        item_proto.name = counter .. "unknown-item"
    end

    local item_name = item_proto.name
    local resource_name, resource_proto = find_resource_for_item(item_name)

    -- No resource found: fake a minable structure from the item itself
    if not resource_proto then
        resource_name = item_name
        resource_proto = { name = item_name, minable = { result = item_name, count = 1 } }
    end

    local minable = resource_proto.minable
    if not minable then return end

    counter = counter + 1
    local results = get_mine_results(minable)
    if not claim_unique_outputs(results) then return end

    local has_fluid = has_fluid_result(results)

    local tint
    if item_proto.color_hint and item_proto.color_hint.tint then
        tint = item_proto.color_hint.tint
    elseif item_proto.random_tint_color then
        tint = item_proto.random_tint_color
    else
        tint = get_resource_tint(resource_name, resource_proto)
    end

    local recipe_icon = get_recipe_icon(minable, has_fluid)
    if item_proto.icon then
        recipe_icon = item_proto.icon
    elseif item_proto.icons and #item_proto.icons > 0 then
        recipe_icon = item_proto.icons[1].icon
    end

    -- Small icon drawn in the corner of every icon of this set
    local overlay = custom_icon
    if not overlay and use_custom_icon then
        overlay = { icon = recipe_icon, icon_size = 64, scale = 0.35, shift = { 8, -8 } }
    end

    build_seed_set({
        resource_name   = resource_name,
        raw_name        = item_name,
        minable         = minable,
        results         = results,
        has_fluid       = has_fluid,
        tint            = tint,
        localised       = item_proto.localised_name or get_translated_key(minable, item_name),
        recipe_icon     = recipe_icon,
        overlay         = overlay,
        tech_name       = has_tech and ("mystical-" .. item_name) or nil,
        recipes_enabled = enabled_by_default or false,
        allow_quality   = nil,
        infuser_item    = { name = "wood", amount = 1 },
    })
end

-- 5f. Quality seeds & trigger technologies 

function func.place_icon_on_item(itemPrototype, qualityPrototype)
    if not itemPrototype.icons then
        itemPrototype.icons = { { icon = itemPrototype.icon, icon_size = itemPrototype.icon_size } }
        func.insert_quality_icons(itemPrototype, qualityPrototype)
        itemPrototype.icon = nil
        return itemPrototype.icons
    end
    return func.insert_quality_icons(itemPrototype, qualityPrototype)
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
    local seed = table.deepcopy(name)
    local base_name = seed.name

    seed.hidden = true
    seed.hidden_in_factoriopedia = true
    seed.subgroup = "mystical-agriculture-seeds"
    seed.order = "zzzzzzzzzzzzzzzzzzzzzzzz" .. base_name .. "-" .. quality.name
    seed.place_result = nil
    seed.localised_name = {
        "",
        "[color=" .. func.rgb_to_hex(quality.color) .. "]",
        item_label(base_name),
        " (", { "quality-name." .. quality.name }, ")",
        "[/color]",
    }
    seed.spoil_result = nil
    seed.spoil_ticks = 1
    seed.spoil_to_trigger_result = {
        items_per_trigger = 1,
        trigger = {
            type = "direct",
            action_delivery = {
                type = "instant",
                source_effects = {
                    {
                        type = "script",
                        effect_id = "{to=" .. quality.name .. ",item=" .. base_name .. "}MYSTICAL_SEED",
                    },
                },
            },
        },
    }

    seed.name = quality.name .. "-" .. base_name
    seed.icons = func.place_icon_on_item(seed, quality)

    data:extend({ seed })
    return seed
end

function func.create_quality_seed_recipe()
    table.sort(infusion_seed_cache, function(a, b) return a.quality.level < b.quality.level end)

    for _, s in pairs(seeds) do
        local cc = 0
        local previous_crystal = nil

        for _, crystal in ipairs(infusion_crystal_cache) do
            if not previous_crystal then
                previous_crystal = crystal
            elseif crystal.previousQuality.name == previous_crystal.quality.name
                and previous_crystal.quality.next == crystal.quality.name then
                local q = crystal.quality

                if q.name ~= "normal" and q.name ~= "quality-unknown" then
                    local intermediate = func.create_intermediate_seed(s, q)
                    local seed_name = intermediate.name

                    -- The previous quality seed can't be used as ingredient (quality can't be
                    -- applied to a normal recipe), so the base seed is always used.
                    local ingredients = quality_ingredients(q.level)
                    table.insert(ingredients, { type = "item", name = s.name, amount = 1 })
                    table.insert(ingredients,
                        { type = "item", name = ESSENCE_PREFIX .. q.name .. "-essence", amount = 100 })

                    data:extend({
                        {
                            type = "recipe",
                            name = "mystical-agriculture-" .. seed_name .. "-crafting",
                            categories = { "crafting" },
                            subgroup = "mystical-agriculture-quality-seed-crafting",
                            energy_required = 1,
                            order = cc .. "a[crafting]-" .. s.name,
                            ingredients = ingredients,
                            main_product = seed_name,
                            results = { { type = "item", name = seed_name, amount = 1 } },
                            enabled = false,
                            hidden = false,
                            localised_name = { "recipe-name.quality-seed-crafting", item_label(seed_name) },
                        },
                        {
                            type = "technology",
                            name = "mystical-trigger-" .. seed_name,
                            icons = intermediate.icons,
                            effects = {
                                { type = "unlock-recipe", recipe = "mystical-agriculture-" .. seed_name .. "-crafting" },
                                { type = "unlock-recipe", recipe = ESSENCE_PREFIX .. q.name .. "-essence-seed-recycling" },
                            },
                            prerequisites = {
                                "mystical-trigger-" .. ESSENCE_PREFIX .. q.name .. "-essence-tree-seed",
                                "mystical-trigger-" .. ESSENCE_PREFIX .. q.name .. "-crystal",
                            },
                            localised_name = { "technology-name.mystical-ressource-seed-tech", item_label(seed_name) },
                            order = "zzzzz[quality-seed-tech]-mystical-trigger-" .. seed_name,
                            research_trigger = {
                                type = "craft-item",
                                item = { name = ESSENCE_PREFIX .. q.name .. "-essence" },
                                count = 1,
                            },
                        },
                    })
                    cc = cc + 1
                end

                previous_crystal = crystal
            end
        end
    end
end

-- Chain of technologies: crafting one tier's item unlocks the next tier.
function func.trigger_tech_p2()
    local previous_seed, previous_tech = nil, nil
    table.sort(infusion_seed_cache, function(a, b) return a.quality.level < b.quality.level end)

    for _, seed in ipairs(infusion_seed_cache) do
        if previous_seed then
            local tech = {
                type = "technology",
                name = "mystical-trigger-" .. seed.item.name,
                icons = seed.item.icons,
                effects = {
                    { type = "unlock-recipe", recipe = "mystical-agriculture-" .. seed.quality.name .. "-essence-seed-recycling" },
                },
                prerequisites = previous_tech and { previous_tech.name } or nil,
                localised_name = { "technology-name.mystical-essence-seed-tech", item_label(seed.item.name) },
                order = "zzzzz[quality-seed-tech]-mystical-trigger-" .. seed.item.name,
                research_trigger = { type = "craft-item", item = { name = previous_seed.item.name }, count = 1 },
            }
            data:extend({ tech })
            trigger_techs[previous_seed.item.name] = tech.name
            previous_tech = tech
        end
        previous_seed = seed
    end
end

function func.generate_trigger_techs()
    local previous_crystal, previous_tech = nil, nil
    sort_crystal_cache()

    for i, crystal in ipairs(infusion_crystal_cache) do
        if previous_crystal then
            local effects
            if crystal.quality.name == "master-gaster" then
                effects = { { type = "unlock-recipe", recipe = "mystical-agriculture-master-gaster-crystal" } }
            else
                effects = {
                    { type = "unlock-recipe",
                      recipe = "mystical-agriculture-crystal-infuse-" .. previous_crystal.quality.name .. "-to-" .. crystal.quality.name },
                }
                for j = i, #infusion_crystal_cache do
                    local tier = infusion_crystal_cache[j].quality
                    local recipe_name = "mystical-agriculture-essence-upgrade-" ..
                        previous_crystal.quality.name .. "-to-" .. crystal.quality.name .. "-using-" .. tier.name

                    if not data.raw["recipe"][recipe_name] then
                        error("you might be using an unsupported quality mods and the added quality does not match wiht the expected level please tell me which mod is it so i can either make it incompatible or make a patch")
                    end
                    if crystal.quality.level ~= previous_crystal.quality.level
                        and data.raw.item[ESSENCE_PREFIX .. crystal.quality.name .. "-essence"] then
                        table.insert(effects, { type = "unlock-recipe", recipe = recipe_name })
                    end
                end
            end

            local tech = {
                type = "technology",
                name = "mystical-trigger-" .. crystal.item.name,
                icons = crystal.item.icons,
                effects = effects,
                prerequisites = previous_tech and { previous_tech.name } or nil,
                localised_name = { "technology-name.mystical-crystal-tech", item_label(crystal.item.name) },
                order = "zzzzz[quality-crystal-tech]-mystical-trigger-" .. crystal.item.name,
                research_trigger = { type = "craft-item", item = { name = previous_crystal.item.name }, count = 1 },
            }
            data:extend({ tech })
            trigger_techs[previous_crystal.item.name] = tech.name
            previous_tech = tech
        end
        previous_crystal = crystal
    end
end

-- 5g. Achievement 

function func.add_achievement()
    data:extend({
        {
            type = "achievement",
            name = "craft-master-gaster-crystal",
            icon = GFX .. "where_is_my_gauntlet.png",
            icon_size = 127,
            order = "g[progress]-z[master-gaster-crystal]",
            achievement_type = "craft-item",
            item_product = ESSENCE_PREFIX .. "master-gaster-crystal",
            amount = 1,
            allowed_without_fight = false,
            localised_name = { "", "Where is my gauntlet ?" },
            localised_description = { "", "I love shiny rocks too" },
        }
    })
end

-- Essence Infuser 

local INFUSER_NAME = "mystical-agriculture-essence-infuser"
local INFUSER_ICON = GFX .. "Mystical-Infuser.png"

local infuser_container = {
    type = "container",
    name = INFUSER_NAME,
    icon = INFUSER_ICON,
    icon_size = 1000,
    icon_mipmaps = 4,
    flags = { "placeable-player", "player-creation", "not-rotatable" },
    minable = { mining_time = 0.5, result = INFUSER_NAME },
    max_health = 300,
    corpse = "small-remnants",
    inventory_size = 50000,
    collision_box = { { -1.4, -1.4 }, { 1.4, 1.4 } },
    selection_box = { { -1.6, -1.6 }, { 1.6, 1.6 } },
    picture = {
        layers = {
            {
                filename = INFUSER_ICON,
                priority = "high",
                width = 1000,
                height = 1000,
                shift = { 0, .5 },
                scale = 0.3,
            },
            {
                filename = GFX .. "Mystical-Infuser-shadow.png",
                priority = "high",
                width = 1000,
                height = 1000,
                shift = { 0, .5 },
                draw_as_shadow = true,
                scale = 0.3,
            },
        },
    },
    open_sound = { filename = "__base__/sound/machine-open.ogg", volume = 0.6 },
    close_sound = { filename = "__base__/sound/machine-close.ogg", volume = 0.6 },
    impact_category = "metal",
}

local base_chest = data.raw["container"]["steel-chest"]
if base_chest and base_chest.circuit_connector then
    infuser_container.circuit_wire_max_distance = base_chest.circuit_wire_max_distance
    infuser_container.circuit_connector = base_chest.circuit_connector
else
    log("[MysticalForestry] steel-chest has no circuit_connector on this Factorio version — Essence Infuser will not support wires until this is addressed.")
end

data:extend({
    {
        type = "item",
        name = INFUSER_NAME,
        icon = INFUSER_ICON,
        icon_size = 1000,
        icon_mipmaps = 4,
        subgroup = "mystical-agriculture-machines",
        order = "zz[essence-infuser]",
        place_result = INFUSER_NAME,
        stack_size = 50,
    },
    {
        type = "recipe",
        name = INFUSER_NAME,
        enabled = true,
        ingredients = {
            { type = "item", name = "steel-plate",     amount = 20 },
            { type = "item", name = "iron-gear-wheel", amount = 10 },
            { type = "item", name = "stone-brick",     amount = 20 },
        },
        results = { { type = "item", name = INFUSER_NAME, amount = 1 } },
    },
    infuser_container,
})

-- Placeholder sprite 

data:extend({
    {
        type = "sprite",
        name = "mystical-forestry-placeholder-any",
        filename = GFX .. "template-categoryIcon.png",
        width = 64,
        height = 64,
    }
})

return func