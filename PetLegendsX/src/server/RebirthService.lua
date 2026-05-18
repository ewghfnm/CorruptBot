--[[
    RebirthService.lua
    Spend coins to rebirth. Resets coins and unlocked worlds (back to Meadow), grants
    a permanent multiplier (handled in PetService).
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local WorldDatabase = require(Shared.WorldDatabase)
local Remotes = require(Shared.Remotes)

local RebirthService = {}
local DataService, CurrencyService

function RebirthService:Init(deps)
    DataService = deps.DataService
    CurrencyService = deps.CurrencyService

    Remotes.Rebirth.OnServerEvent:Connect(function(plr) self:HandleRebirth(plr) end)
    Remotes.UnlockWorld.OnServerEvent:Connect(function(plr, worldId) self:HandleUnlockWorld(plr, worldId) end)
end

function RebirthService:GetRebirthCost(rebirths)
    return math.floor(Config.REBIRTH_BASE_COST * (Config.REBIRTH_COST_SCALE ^ rebirths))
end

function RebirthService:HandleRebirth(player)
    local d = DataService:Get(player); if not d then return end
    local cost = self:GetRebirthCost(d.rebirths)
    if (d.coins or 0) < cost then
        Remotes.Notification:FireClient(player, "You need " .. cost .. " coins to rebirth.")
        return
    end
    d.coins = 0
    d.rebirths += 1
    d.unlockedWorlds = {Meadow = true}
    d.currentWorld = "Meadow"
    DataService:MarkDirty(player)
    Remotes.Notification:FireClient(player, "Rebirth! You are now rebirth " .. d.rebirths .. ".")
end

function RebirthService:HandleUnlockWorld(player, worldId)
    local d = DataService:Get(player); if not d then return end
    local w = WorldDatabase.GetById(worldId); if not w then return end
    if d.unlockedWorlds[worldId] then return end
    if (d.rebirths or 0) < (w.rebirthRequired or 0) then
        Remotes.Notification:FireClient(player, "Need " .. w.rebirthRequired .. " rebirths.")
        return
    end
    if (d.coins or 0) < (w.unlockCost or 0) then
        Remotes.Notification:FireClient(player, "Not enough coins.")
        return
    end
    if w.unlockCost > 0 then
        if not CurrencyService:Spend(player, "coins", w.unlockCost) then return end
    end
    d.unlockedWorlds[worldId] = true
    d.currentWorld = worldId
    DataService:MarkDirty(player)
    Remotes.Notification:FireClient(player, "Unlocked " .. w.name .. "!")
end

return RebirthService
