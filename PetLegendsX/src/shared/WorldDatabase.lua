--[[
    WorldDatabase.lua
    All worlds in the game. Order = unlock order.
    `unlockCost` is in coins. Set 0 for the spawn world.
]]

local Worlds = {
    {id = "Meadow",  name = "Spawn Meadow",   unlockCost = 0,        coinMultiplier = 1,    rebirthRequired = 0},
    {id = "Candy",   name = "Candy Kingdom",  unlockCost = 25000,    coinMultiplier = 5,    rebirthRequired = 0},
    {id = "Cyber",   name = "Cyber City",     unlockCost = 5e6,      coinMultiplier = 25,   rebirthRequired = 0},
    {id = "Volcano", name = "Volcano Core",   unlockCost = 5e8,      coinMultiplier = 100,  rebirthRequired = 1},
    {id = "Ocean",   name = "Ocean Paradise", unlockCost = 5e10,     coinMultiplier = 500,  rebirthRequired = 2},
    {id = "Frozen",  name = "Frozen Peaks",   unlockCost = 5e12,     coinMultiplier = 2500, rebirthRequired = 3},
    {id = "Egypt",   name = "Ancient Egypt",  unlockCost = 5e14,     coinMultiplier = 1e4,  rebirthRequired = 5},
    {id = "Space",   name = "Space Station",  unlockCost = 5e16,     coinMultiplier = 5e4,  rebirthRequired = 8},
    {id = "Samurai", name = "Samurai World",  unlockCost = 5e18,     coinMultiplier = 2e5,  rebirthRequired = 12},
    {id = "Heaven",  name = "Heaven Realm",   unlockCost = 5e20,     coinMultiplier = 1e6,  rebirthRequired = 18},
    {id = "Void",    name = "Void Realm",     unlockCost = 5e22,     coinMultiplier = 5e6,  rebirthRequired = 25},
    {id = "Cosmic",  name = "Cosmic Infinity",unlockCost = 5e24,     coinMultiplier = 2e7,  rebirthRequired = 35},
}

local byId = {}
for i, w in ipairs(Worlds) do
    w.order = i
    byId[w.id] = w
end

local M = {}
M.List = Worlds

function M.GetById(id) return byId[id] end

return M
