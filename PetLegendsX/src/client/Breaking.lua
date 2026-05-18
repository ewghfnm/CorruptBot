--[[
    Breaking.lua
    Auto-attack the closest breakable in front of the player. The server is fully
    authoritative; this just fires hit requests at a fixed rate.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local LocalPlayer = Players.LocalPlayer

local HIT_INTERVAL = 0.15
local MAX_RANGE = 18

local last = 0
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - last < HIT_INTERVAL then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local breakablesFolder = Workspace:FindFirstChild("Breakables")
    if not breakablesFolder then return end

    local best, bestDist
    for _, worldFolder in ipairs(breakablesFolder:GetChildren()) do
        for _, b in ipairs(worldFolder:GetChildren()) do
            local hb = b:FindFirstChild("Hitbox") or b.PrimaryPart
            if hb then
                local dist = (hb.Position - hrp.Position).Magnitude
                if dist < MAX_RANGE and (not bestDist or dist < bestDist) then
                    best, bestDist = b, dist
                end
            end
        end
    end
    if best then
        last = now
        Remotes.RequestBreakHit:FireServer(best)
    end
end)

return {}
