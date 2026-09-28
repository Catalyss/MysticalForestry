-- infusion_api.lua
-- Custom infusion recipes plus the public remote interface for other mods.
local base = require("infusion")

local INTERFACE_NAME = "mystical-forestry-infusion"
local MAX_INGREDIENTS = 4 -- one per corner slot in the infuser GUI

local api = {}
local warned = {} -- log-spam guard only, not game state

local function fail(reason)
    log("[MysticalForestry] infusion API: " .. reason)
    return false, reason
end

local function get_overrides() return storage.infusion_overrides or {} end
local function get_removed() return storage.infusion_removed or {} end

local function ensure_storage()
    storage.infusion_overrides = storage.infusion_overrides or {}
    storage.infusion_removed = storage.infusion_removed or {}
    return storage.infusion_overrides, storage.infusion_removed
end

local function normalise(entry)
    if not entry then return nil end
    if entry.ingredients then return entry end
    return { ingredients = entry }
end

local function copy_ingredients(list)
    local out = {}
    for _, ing in ipairs(list) do
        out[#out + 1] = { name = ing.name, amount = ing.amount }
    end
    return out
end

local function effective_entry(item_name)
    local override = get_overrides()[item_name]
    if override then return override end
    if get_removed()[item_name] then return nil end
    return normalise(base[item_name])
end

local function validate_ingredients(list)
    if type(list) ~= "table" then return false, "ingredients must be a list" end
    if #list == 0 then return false, "ingredients list is empty" end
    if #list > MAX_INGREDIENTS then
        return false, "at most " .. MAX_INGREDIENTS .. " ingredients are supported"
    end
    local seen = {}
    for _, ing in ipairs(list) do
        if type(ing) ~= "table" or type(ing.name) ~= "string" then
            return false, "each ingredient needs a string 'name'"
        end
        if not prototypes.item[ing.name] then
            return false, "unknown item '" .. ing.name .. "'"
        end
        if type(ing.amount) ~= "number" or ing.amount < 1 or ing.amount % 1 ~= 0 then
            return false, "amount for '" .. ing.name .. "' must be a positive integer"
        end
        if seen[ing.name] then
            return false, "duplicate ingredient '" .. ing.name .. "'"
        end
        seen[ing.name] = true
    end
    return true
end

function api.get_custom_ingredients(item_name)
    local entry = effective_entry(item_name)
    if not entry then return nil end
    for _, ing in ipairs(entry.ingredients) do
        if not prototypes.item[ing.name] then
            if not warned[item_name] then
                warned[item_name] = true
                log("[MysticalForestry] infusion recipe for '" .. item_name ..
                    "' references unknown item '" .. tostring(ing.name) .. "'; ignoring it.")
            end
            return nil
        end
    end
    return entry.ingredients
end


function api.get_recipe(item_name)
    local entry = effective_entry(item_name)
    if not entry then return nil end
    return { ingredients = copy_ingredients(entry.ingredients) }
end

function api.set_recipe(item_name, ingredients)
    if type(item_name) ~= "string" or not prototypes.item[item_name] then
        return fail("unknown item '" .. tostring(item_name) .. "'")
    end
    local ok, reason = validate_ingredients(ingredients)
    if not ok then return fail(reason) end

    local overrides, removed = ensure_storage()
    overrides[item_name] = { ingredients = copy_ingredients(ingredients) }
    removed[item_name] = nil
    return true
end

function api.remove_recipe(item_name)
    if type(item_name) ~= "string" then return fail("item name must be a string") end
    local overrides, removed = ensure_storage()
    overrides[item_name] = nil
    removed[item_name] = true
    return true
end

function api.add_ingredient(item_name, ingredient)
    if type(ingredient) ~= "table" then return fail("ingredient must be a table") end
    local entry = effective_entry(item_name)
    local list = entry and copy_ingredients(entry.ingredients) or {}
    local found = false
    for _, ing in ipairs(list) do
        if ing.name == ingredient.name then
            ing.amount = ingredient.amount
            found = true
            break
        end
    end
    if not found then
        list[#list + 1] = { name = ingredient.name, amount = ingredient.amount }
    end
    return api.set_recipe(item_name, list)
end

function api.remove_ingredient(item_name, ingredient_name)
    local entry = effective_entry(item_name)
    if not entry then return fail("no custom recipe for '" .. tostring(item_name) .. "'") end
    local list = {}
    for _, ing in ipairs(entry.ingredients) do
        if ing.name ~= ingredient_name then
            list[#list + 1] = { name = ing.name, amount = ing.amount }
        end
    end
    if #list == #entry.ingredients then
        return fail("'" .. tostring(item_name) .. "' has no ingredient '" .. tostring(ingredient_name) .. "'")
    end
    if #list == 0 then
        return fail("cannot remove the last ingredient; use remove_recipe instead")
    end
    return api.set_recipe(item_name, list)
end

function api.list_recipes()
    local out = {}
    for item_name in pairs(base) do
        if effective_entry(item_name) then out[item_name] = api.get_recipe(item_name) end
    end
    for item_name in pairs(get_overrides()) do
        out[item_name] = api.get_recipe(item_name)
    end
    return out
end

remote.add_interface(INTERFACE_NAME, {
    get_recipe        = api.get_recipe,
    set_recipe        = api.set_recipe,
    remove_recipe     = api.remove_recipe,
    add_ingredient    = api.add_ingredient,
    remove_ingredient = api.remove_ingredient,
    list_recipes      = api.list_recipes,
})

return api



--local function register_infusions()
--    if not remote.interfaces["mystical-forestry-infusion"] then return end
--
--    remote.call("mystical-forestry-infusion", "set_recipe", "my-gadget", {
--        { name = "iron-plate", amount = 10 },
--        { name = "my-widget",  amount = 2 },
--    })
--    remote.call("mystical-forestry-infusion", "add_ingredient", "solar-panel", { name = "steel-plate", amount = 2 })
--    remote.call("mystical-forestry-infusion", "remove_ingredient", "solar-panel", "copper-cable")
--end
--
--script.on_init(register_infusions)
--script.on_configuration_changed(register_infusions)

--that how other mods would call this I guess ??
--i think this should work :D