--[[
    PetService.lua
    All pet inventory/equipment logic. Computes a player's combined damage and
    coin multiplier from their equipped pets, applying tier (Standard/Golden/Rainbow/DarkMatter),
    rebirth multiplier and active enchants.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PetDatabase = require(Shared.PetDatabase)
local EnchantDatabase = require(Shared.EnchantDatabase)
local Config = require(Shared.Config)
local Util = require(Shared.Util)

local PetService = {}
local DataService

local TIER_MULTIPLIERS = {
    Standard   = 1,
    Golden     = 2,
    Rainbow    = 5,
    DarkMatter = 10,
}

function PetService:Init(deps)
    DataService = deps.DataService
end

function PetService:_findPetIndex(data, uid)
    for i, p in ipairs(data.pets) do
        if p.uid == uid then return i, p end
    end
end

function PetService:GivePet(player, petId, opts)
    opts = opts or {}
    local def = PetDatabase.GetById(petId); if not def then return nil end
    local d = DataService:Get(player); if not d then return nil end

    local pet = {
        uid = Util.NewGuid(),
        id = petId,
        level = 1,
        xp = 0,
        tier = opts.tier or "Standard",
        mutation = opts.mutation, -- "shiny" / "glowing" / "corrupted" / "celestial" / "void" / "infernal" or nil
        locked = false,
        favorite = false,
        equipped = false,
        enchants = {}, -- {{id="coin_boost", tier=1}, ...}
    }
    table.insert(d.pets, pet)
    DataService:MarkDirty(player)
    return pet
end

function PetService:RemovePet(player, uid)
    local d = DataService:Get(player); if not d then return false end
    local i, p = self:_findPetIndex(d, uid)
    if not i or p.locked then return false end
    table.remove(d.pets, i)
    DataService:MarkDirty(player)
    return true
end

function PetService:LockPet(player, uid, locked)
    local d = DataService:Get(player); if not d then return false end
    local _, p = self:_findPetIndex(d, uid); if not p then return false end
    p.locked = locked and true or false
    DataService:MarkDirty(player); return true
end

function PetService:GetEquippedCount(data)
    local n = 0
    for _, p in ipairs(data.pets) do if p.equipped then n += 1 end end
    return n
end

function PetService:EquipPet(player, uid)
    local d = DataService:Get(player); if not d then return false end
    local _, pet = self:_findPetIndex(d, uid); if not pet then return false end
    if pet.equipped then return true end
    local maxSlots = d.equippedSlots or Config.MAX_EQUIPPED_PETS_DEFAULT
    if self:GetEquippedCount(d) >= maxSlots then return false end
    pet.equipped = true
    DataService:MarkDirty(player); return true
end

function PetService:UnequipPet(player, uid)
    local d = DataService:Get(player); if not d then return false end
    local _, pet = self:_findPetIndex(d, uid); if not pet then return false end
    pet.equipped = false
    DataService:MarkDirty(player); return true
end

function PetService:_petStats(pet)
    local def = PetDatabase.GetById(pet.id); if not def then return 0, 0 end
    local tierMul = TIER_MULTIPLIERS[pet.tier] or 1
    local levelMul = 1 + (pet.level - 1) * 0.05    -- +5% per level
    local damage = def.damage * tierMul * levelMul
    local coinMul = def.coinMultiplier * tierMul

    -- Apply enchants
    for _, ench in ipairs(pet.enchants or {}) do
        local edef = EnchantDatabase.GetById(ench.id); if edef then
            local bonus = edef.perTier * (ench.tier or 1)
            if edef.stat == "damage" then damage *= (1 + bonus)
            elseif edef.stat == "coinMultiplier" then coinMul *= (1 + bonus)
            end
        end
    end
    return damage, coinMul
end

function PetService:ComputePlayerStats(player)
    local d = DataService:Get(player); if not d then return {damage = 1, coinMul = 1} end
    local totalDamage, totalCoinMul = 0, 0
    for _, p in ipairs(d.pets) do
        if p.equipped then
            local dmg, cm = self:_petStats(p)
            totalDamage += dmg
            totalCoinMul += cm
        end
    end
    if totalDamage == 0 then totalDamage = 1 end
    if totalCoinMul == 0 then totalCoinMul = 1 end

    -- Rebirth multiplier
    local rb = (Config.REBIRTH_MULTIPLIER ^ (d.rebirths or 0))
    totalDamage *= rb
    totalCoinMul *= rb

    return {damage = totalDamage, coinMul = totalCoinMul}
end

function PetService:AddXP(player, amount)
    local d = DataService:Get(player); if not d then return end
    local changed = false
    for _, p in ipairs(d.pets) do
        if p.equipped and p.level < Config.MAX_PET_LEVEL then
            p.xp = (p.xp or 0) + amount
            local need = Config.PET_XP_PER_LEVEL(p.level)
            while p.xp >= need and p.level < Config.MAX_PET_LEVEL do
                p.xp -= need
                p.level += 1
                need = Config.PET_XP_PER_LEVEL(p.level)
                changed = true
            end
        end
    end
    if changed then DataService:MarkDirty(player) end
end

return PetService
