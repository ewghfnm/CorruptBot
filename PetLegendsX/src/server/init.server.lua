--[[
    init.server.lua
    Boots all server services in order, wiring them together.
]]

local script = script
local serverScripts = script.Parent

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes) -- creates Remotes folder

local DataService          = require(serverScripts.DataService)
local CurrencyService      = require(serverScripts.CurrencyService)
local PetService           = require(serverScripts.PetService)
local AnnouncementService  = require(serverScripts.AnnouncementService)
local GamepassService      = require(serverScripts.GamepassService)
local EggService           = require(serverScripts.EggService)
local BreakingService      = require(serverScripts.BreakingService)
local RebirthService       = require(serverScripts.RebirthService)
local AdminService         = require(serverScripts.AdminService)

DataService:Init()
CurrencyService:Init({DataService = DataService})
PetService:Init({DataService = DataService})
AnnouncementService:Init()
GamepassService:Init({DataService = DataService})
EggService:Init({
    DataService = DataService,
    CurrencyService = CurrencyService,
    PetService = PetService,
    GamepassService = GamepassService,
    AnnouncementService = AnnouncementService,
})
BreakingService:Init({
    DataService = DataService,
    CurrencyService = CurrencyService,
    PetService = PetService,
})
RebirthService:Init({
    DataService = DataService,
    CurrencyService = CurrencyService,
})
AdminService:Init({
    DataService = DataService,
    CurrencyService = CurrencyService,
    PetService = PetService,
    GamepassService = GamepassService,
    EggService = EggService,
    AnnouncementService = AnnouncementService,
})

-- Equip / unequip / lock / delete remotes
local Players = game:GetService("Players")
Remotes.EquipPet.OnServerEvent:Connect(function(plr, uid)   PetService:EquipPet(plr, uid)   end)
Remotes.UnequipPet.OnServerEvent:Connect(function(plr, uid) PetService:UnequipPet(plr, uid) end)
Remotes.LockPet.OnServerEvent:Connect(function(plr, uid, locked) PetService:LockPet(plr, uid, locked) end)
Remotes.DeletePet.OnServerEvent:Connect(function(plr, uid) PetService:RemovePet(plr, uid) end)

-- Push player data to client whenever it changes
DataService.DataChanged:Connect(function(plr, data)
    Remotes.PlayerDataUpdated:FireClient(plr, data)
end)
DataService.DataLoaded:Connect(function(plr, data)
    Remotes.PlayerDataUpdated:FireClient(plr, data)
end)

Remotes.GetPlayerData.OnServerInvoke = function(plr)
    return DataService:Get(plr)
end

print("[PetLegendsX] Server booted.")
