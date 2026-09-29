-- infusion.lua
-- Custom infuser rules. Every field is checked against the matching
-- infuser slot: nil requires the slot to be EMPTY, a string is matched
-- as an exact item name first, then as a Lua pattern (escape hyphens
-- as %- when writing a real pattern), and a table {name=, amount=}
-- requires that exact item with at least that count.
--
-- return_item / return_crystal accept:
--   nil                                    -- untouched / not applicable
--   "item-name"                            -- always produce 1
--   "item-name,5"                          -- always produce 5
--   "item-name,5-10"                       -- always produce a random 5-10
--   "a,20%;b,80%"                          -- weighted pick of exactly one (chance of nothing if weights < 100)
--   "a,50%,5-10;b,50%,1-20"                -- weighted pick, each option its own amount range
-- A table form is also accepted:
--   { { name = "a", weight = 20 }, { name = "b", weight = 80, min = 1, max = 5 } }

return {
    {
        item           = { name = "^mystical%-agriculture%-.+%-essence%-tree%-seed$", amount = 1 },
        crystal        = { name = "^mystical%-agriculture%-.+%-crystal$", amount = 1 },
        essence_top    = nil,
        essence_left   = nil,
        essence_right  = nil,
        essence_bottom = nil,
        ing_tl         = { name = "iron-ore", amount = 250 },
        ing_tr         = { name = "iron-ore", amount = 250 },
        ing_bl         = { name = "iron-ore", amount = 250 },
        ing_br         = { name = "iron-ore", amount = 250 },
        return_item    = { name = "^.+iron%-ore%-tree%-seed$", amount = 1 },
        return_crystal = nil,
        craft_use_essence = false,
        craft_use_crystal = true,
        return_quality = false,
        return_consumed_crystal = true,
    },
}