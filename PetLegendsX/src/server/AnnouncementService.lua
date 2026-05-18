--[[
    AnnouncementService.lua
    Sends server-wide announcements to every connected client.
]]

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local AnnouncementService = {}

function AnnouncementService:Init() end

function AnnouncementService:Broadcast(message)
    for _, plr in ipairs(Players:GetPlayers()) do
        Remotes.ServerAnnounce:FireClient(plr, message)
    end
end

return AnnouncementService
