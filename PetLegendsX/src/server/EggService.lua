--[[
    EggService.lua
    Egg purchasing & hatching, including:
      - Huge pet roll
      - Pity system (Mythical+ guarantee, Legendary+ guarantee)
      - Lucky gamepass multipliers
      - Mutation roll (small chance)
      - Server announcement on rare hatches
      - Multi-hatch (1 / 3 / 8) and Auto Hatch
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local EggDatabase = require(Shared.EggDatabase)
local PetDatabase = require(Shared.PetDatabase)
local Rarities = require(Shared.Rarities)
local Util = require(Shared.Util)
local Remotes = require(Shared.Remotes)

local EggService = {}
local DataService, CurrencyService, PetService, GamepassService, AnnouncementService

function EggService:Init(deps)
    DataService = deps.DataService
    CurrencyService = deps.CurrencyService
    PetService = deps.PetService
    GamepassService = deps.GamepassService
    AnnouncementService = deps.AnnouncementService

    Remotes.HatchEgg.OnServerEvent:Connect(function(plr, eggId, count)
        self:HandleHatchRequest(plr, eggId, count)
    end)
    Remotes.SetAutoHatch.OnServerEvent:Connect(function(plr, eggId)
        local d = DataService:Get(plr); if not d then return end
        if eggId == nil or EggDatabase.GetById(eggId) then
            d.autoHatchEgg = eggId
            DataService:MarkDirty(plr)
        end
    end)

    -- Auto hatch loop
    task.spawn(function()
        while true do
            task.wait(Config.AUTO_HATCH_INTERVAL)
            for _, plr in ipairs(Players:GetPlayers()) do
                local d = DataService:Get(plr)
                if d and d.autoHatchEgg and GamepassService:Owns(plr, "AutoHatch") then
                    self:HandleHatchRequest(plr, d.autoHatchEgg, 1, true)
                end
            end
        end
    end)
end

function EggService:_luckMultiplier(player)
    local m = 1
    if GamepassService:Owns(player, "SuperLucky") then m += 0.5 end
    if GamepassService:Owns(player, "UltraLucky") then m += 1.5 end
    return m
end

function EggService:_rollMutation()
    -- 1% mutation chance overall
    if math.random() > 0.01 then return nil end
    local options = {"shiny", "glowing", "corrupted", "celestial", "void", "infernal"}
    return options[math.random(1, #options)]
end

function EggService:_rollTier()
    -- 2% Golden, 0.4% Rainbow, 0.05% DarkMatter
    local r = math.random()
    if r < 0.0005 then return "DarkMatter"
    elseif r < 0.004 then return "Rainbow"
    elseif r < 0.024 then return "Golden"
    else return "Standard" end
end

function EggService:_pickPet(egg, data, luck)
    -- Huge pet roll first
    local hugeChance = (egg.hugeChance or 0) * luck
    if hugeChance > 0 and math.random() < hugeChance then
        local pool = egg.hugePool or {}
        if #pool > 0 then return pool[math.random(1, #pool)], true end
    end

    -- Pity guarantees
    local stats = data.stats
    local guaranteed
    if stats.pity_mythical >= Config.PITY_MYTHICAL_AFTER then
        guaranteed = "Mythical"
    elseif stats.pity_legendary >= Config.PITY_LEGENDARY_AFTER then
        guaranteed = "Legendary"
    end

    -- Filter pool by guaranteed rarity if any
    local pool = egg.pets
    if guaranteed then
        local filtered = {}
        for _, e in ipairs(pool) do
            local def = PetDatabase.GetById(e.id)
            if def and Rarities.IsAtLeast(def.rarity, guaranteed) then
                table.insert(filtered, e)
            end
        end
        if #filtered > 0 then pool = filtered end
    end

    local id = Util.WeightedPick(pool, luck)
    return id, false
end

function EggService:HandleHatchRequest(player, eggId, count, fromAuto)
    local egg = EggDatabase.GetById(eggId); if not egg then return end
    count = math.clamp(tonumber(count) or 1, 1, 8)

    -- Gate multi-hatches behind gamepasses
    if count > 1 and not GamepassService:Owns(player, "TripleHatch") then count = 1 end
    if count > 3 then count = 3 end -- octuple is reserved for a future "MegaHatch" gamepass

    local d = DataService:Get(player); if not d then return end

    -- Check world unlocked
    if egg.world and not d.unlockedWorlds[egg.world] then
        Remotes.Notification:FireClient(player, "World " .. egg.world .. " is locked.")
        return
    end

    local totalCost = egg.cost * count
    if not CurrencyService:Spend(player, egg.currency, totalCost) then
        Remotes.Notification:FireClient(player, "Not enough " .. egg.currency .. ".")
        return
    end

    local results = {}
    local luck = self:_luckMultiplier(player)
    for i = 1, count do
        local petId, isHuge = self:_pickPet(egg, d, luck)
        local def = PetDatabase.GetById(petId)
        if def then
            local tier = isHuge and "Standard" or self:_rollTier()
            local mutation = self:_rollMutation()
            local pet = PetService:GivePet(player, petId, {tier = tier, mutation = mutation})
            d.stats.totalHatches += 1

            -- Update pity counters
            if Rarities.IsAtLeast(def.rarity, "Mythical") then
                d.stats.pity_mythical = 0
            else
                d.stats.pity_mythical += 1
            end
            if Rarities.IsAtLeast(def.rarity, "Legendary") then
                d.stats.pity_legendary = 0
            else
                d.stats.pity_legendary += 1
            end

            table.insert(results, {
                uid = pet.uid, id = petId, name = def.name, rarity = def.rarity,
                tier = tier, mutation = mutation, isHuge = isHuge,
            })

            -- Server-wide announcement on rare hatches
            local rIdx = (Rarities.GetByName(def.rarity) or {}).index or 0
            if isHuge or rIdx >= Config.ANNOUNCE_RARITY_INDEX then
                AnnouncementService:Broadcast(string.format(
                    "%s just hatched a %s%s %s!",
                    player.DisplayName,
                    tier ~= "Standard" and (tier .. " ") or "",
                    def.rarity,
                    def.name
                ))
            end
        end
    end

    DataService:MarkDirty(player)
    Remotes.HatchResult:FireClient(player, eggId, results)
end

return EggService
