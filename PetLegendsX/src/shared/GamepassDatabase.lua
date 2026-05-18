--[[
    GamepassDatabase.lua
    Replace the placeholder IDs (0) with your real Roblox gamepass IDs.
    The "key" is what server-side code references (e.g. "AutoHatch").
]]

local Gamepasses = {
    {key = "AutoHatch",      id = 0, name = "Auto Hatch",        priceRobux = 399,  description = "Hatch eggs automatically while in an egg area."},
    {key = "TripleHatch",    id = 0, name = "Triple Hatch",      priceRobux = 799,  description = "Hatch 3 eggs at once."},
    {key = "ExtraEquip",     id = 0, name = "Extra Equip Slots", priceRobux = 499,  description = "Equip up to 6 pets at once."},
    {key = "SuperLucky",     id = 0, name = "Super Lucky",       priceRobux = 999,  description = "+50% better odds on all hatches."},
    {key = "UltraLucky",     id = 0, name = "Ultra Lucky",       priceRobux = 1499, description = "+150% better odds on all hatches. Stacks with Super Lucky."},
    {key = "FasterWalk",     id = 0, name = "Faster Walkspeed",  priceRobux = 299,  description = "+8 walkspeed."},
    {key = "VIP",            id = 0, name = "VIP",               priceRobux = 799,  description = "VIP tag, gold chat color, +25% coins, access to VIP area."},
}

local byKey, byId = {}, {}
for _, g in ipairs(Gamepasses) do
    byKey[g.key] = g
    if g.id and g.id > 0 then byId[g.id] = g end
end

local M = {}
M.List = Gamepasses

function M.GetByKey(key) return byKey[key] end
function M.GetById(id) return byId[id] end

return M
