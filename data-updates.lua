-- NOTE: with "all items" enabled this must run in data-final-fixes so every other
-- mod's items already exist when the snapshot below is taken.

require("prototypes.category")
require("prototypes.icons")
local func = require("functions")

local allow_all = settings.startup["mystical-agriculture-all-items"].value
local custom_items = settings.startup["mystical-agriculture-custom-items"].value
local qualityseeds = settings.startup["mystical-agriculture-quality-seeds"].value


local ITEM_TYPES = {
    "item", "tool", "ammo", "capsule", "gun", "module", "armor",
    "repair-tool", "rail-planner", "item-with-entity-data",
}

local OWN_PREFIX = "mystical-agriculture-" -- e.g. the Essence Infuser item defined by functions.lua

local function has_flag(flags, flag)
    if not flags then return false end
    for _, f in pairs(flags) do
        if f == flag then return true end
    end
    return false
end

local function is_recycling(recipe)
    if recipe.category == "recycling" then return true end
    for _, c in pairs(recipe.categories or {}) do
        if c == "recycling" then return true end
    end
    for _, c in pairs(recipe.additional_categories or {}) do
        if c == "recycling" then return true end
    end
    return false
end

-- Returns two sets (item name -> true):
--   has_craft         a non-recycling recipe produces it            (step 2)
--   has_visible_craft ...and at least one such recipe is not hidden (step 3)
local function collect_crafts()
    local has_craft, has_visible_craft = {}, {}

    local function mark(name, visible)
        has_craft[name] = true
        if visible then has_visible_craft[name] = true end
    end

    for _, recipe in pairs(data.raw.recipe) do
        if not is_recycling(recipe) then
            local visible = not recipe.hidden
            if recipe.results then
                for _, r in pairs(recipe.results) do
                    if (r.type or "item") == "item" then mark(r.name, visible) end
                end
            elseif recipe.result then
                mark(recipe.result, visible)
            end
        end
    end

    return has_craft, has_visible_craft
end

local function is_valid_item(proto)
    return proto.name ~= "item-unknown"
        and not proto.hidden
        and not proto.parameter
        and not has_flag(proto.flags, "hidden")
        and proto.name:sub(1, #OWN_PREFIX) ~= OWN_PREFIX
end

-- Recipes make several of an item per craft, which is an error for items that
-- can't stack (stack size 1 / "not-stackable": wires, vehicles, armor...).
local function is_stackable(proto)
    return proto.stack_size ~= nil
        and proto.stack_size > 1
        and not has_flag(proto.flags, "not-stackable")
end

local item_snapshot = {}

if allow_all then
    local has_craft, has_visible_craft = collect_crafts()
    local stats = { considered = 0, invalid = 0, unstackable = 0, no_craft = 0, hidden_craft = 0, kept = 0 }

    for _, item_type in ipairs(ITEM_TYPES) do                -- step 1
        for _, proto in pairs(data.raw[item_type] or {}) do
            stats.considered = stats.considered + 1

            if not is_valid_item(proto) then
                stats.invalid = stats.invalid + 1
            elseif not is_stackable(proto) then
                stats.unstackable = stats.unstackable + 1
            elseif not has_craft[proto.name] then            -- step 2
                stats.no_craft = stats.no_craft + 1
            elseif not has_visible_craft[proto.name] then    -- step 3
                stats.hidden_craft = stats.hidden_craft + 1
            else
                stats.kept = stats.kept + 1
                table.insert(item_snapshot, table.deepcopy(proto))
            end
        end
    end

    -- stable order => stable generated prototype names
    table.sort(item_snapshot, function(a, b) return a.name < b.name end)

    log(string.format(
        "[MysticalForestry] all-items filter: %d considered, %d invalid/hidden, %d unstackable, %d without a craft, %d with only hidden crafts, %d kept",
        stats.considered, stats.invalid, stats.unstackable, stats.no_craft, stats.hidden_craft, stats.kept))
end


func.initialize_prototypes()
func.create_craft_category()

local qualities = {}
for _, quality in pairs(data.raw["quality"]) do
    if quality.name ~= "quality-unknown" then
        table.insert(qualities, table.deepcopy(quality))
    end
end
table.sort(qualities, function(a, b) return a.level < b.level end)

local previousQuality = nil
for _, quality in ipairs(qualities) do
    func.create_quality_essence(quality)
    func.create_quality_crystal(quality, previousQuality)
    previousQuality = quality
end
func.create_master_crystal(previousQuality)

if allow_all then
    -- every kept item has a visible craft, so its "craft N of it" tech is reachable
    for _, proto in ipairs(item_snapshot) do
        func.create_custom_prototypes(proto, true, true, false)
    end
elseif custom_items and custom_items ~= "" then
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