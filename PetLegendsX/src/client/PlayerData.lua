--[[
    PlayerData.lua
    Client-side cache of the player's data, kept in sync via PlayerDataUpdated remote.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Signal)

local PlayerData = {Changed = Signal.new(), data = nil}

Remotes.PlayerDataUpdated.OnClientEvent:Connect(function(d)
    PlayerData.data = d
    PlayerData.Changed:Fire(d)
end)

task.spawn(function()
    local ok, d = pcall(function() return Remotes.GetPlayerData:InvokeServer() end)
    if ok and d and not PlayerData.data then
        PlayerData.data = d
        PlayerData.Changed:Fire(d)
    end
end)

return PlayerData
