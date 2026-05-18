--[[
    Remotes.lua
    Lazily creates and returns RemoteEvents/RemoteFunctions in ReplicatedStorage.Remotes.
    Both server and client require this module.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
    folder = Instance.new("Folder")
    folder.Name = "Remotes"
    folder.Parent = ReplicatedStorage
end

local function getOrCreate(className, name)
    local existing = folder:FindFirstChild(name)
    if existing then return existing end
    if RunService:IsServer() then
        local inst = Instance.new(className)
        inst.Name = name
        inst.Parent = folder
        return inst
    else
        return folder:WaitForChild(name, 10)
    end
end

local Remotes = {}

-- Events (server -> client / client -> server)
Remotes.HatchEgg          = getOrCreate("RemoteEvent",    "HatchEgg")
Remotes.PlayerDataUpdated = getOrCreate("RemoteEvent",    "PlayerDataUpdated")
Remotes.HatchResult       = getOrCreate("RemoteEvent",    "HatchResult")
Remotes.EquipPet          = getOrCreate("RemoteEvent",    "EquipPet")
Remotes.UnequipPet        = getOrCreate("RemoteEvent",    "UnequipPet")
Remotes.LockPet           = getOrCreate("RemoteEvent",    "LockPet")
Remotes.DeletePet         = getOrCreate("RemoteEvent",    "DeletePet")
Remotes.UnlockWorld       = getOrCreate("RemoteEvent",    "UnlockWorld")
Remotes.Rebirth           = getOrCreate("RemoteEvent",    "Rebirth")
Remotes.Notification      = getOrCreate("RemoteEvent",    "Notification")
Remotes.ServerAnnounce    = getOrCreate("RemoteEvent",    "ServerAnnounce")
Remotes.AdminCommand      = getOrCreate("RemoteEvent",    "AdminCommand")
Remotes.RequestBreakHit   = getOrCreate("RemoteEvent",    "RequestBreakHit")
Remotes.SetAutoHatch      = getOrCreate("RemoteEvent",    "SetAutoHatch")

-- Functions (client requests data)
Remotes.GetPlayerData     = getOrCreate("RemoteFunction", "GetPlayerData")
Remotes.IsAdmin           = getOrCreate("RemoteFunction", "IsAdmin")

return Remotes
