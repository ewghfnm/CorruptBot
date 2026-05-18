--[[
    EnchantDatabase.lua
    Foundation only. Apply effects in PetService when computing stats.
    Each enchant has tiers I-V which scale the bonus.
]]

local Enchants = {
    {id = "coin_boost",    name = "Coin Boost",   stat = "coinMultiplier", perTier = 0.10}, -- +10% per tier
    {id = "damage_boost",  name = "Damage Boost", stat = "damage",         perTier = 0.15},
    {id = "crit_chance",   name = "Crit Chance",  stat = "critChance",     perTier = 0.05},
    {id = "speed",         name = "Speed",        stat = "walkspeed",      perTier = 1.0},
    {id = "chest_breaker", name = "Chest Breaker",stat = "chestDamage",    perTier = 0.20},
    {id = "lucky_eggs",    name = "Lucky Eggs",   stat = "luck",           perTier = 0.05},
    {id = "ultra_lucky",   name = "Ultra Lucky",  stat = "luck",           perTier = 0.15},
    {id = "xp_boost",      name = "XP Boost",     stat = "xpMultiplier",   perTier = 0.20},
    {id = "gem_finder",    name = "Gem Finder",   stat = "gemMultiplier",  perTier = 0.25},
}

local byId = {}
for _, e in ipairs(Enchants) do byId[e.id] = e end

local M = {}
M.List = Enchants
function M.GetById(id) return byId[id] end
return M
