--[[
    Notifications.lua
    Bottom-of-screen toast notifications. Listens to:
        - Remotes.Notification (private to one player)
        - Remotes.ServerAnnounce (server-wide, e.g. rare hatches)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local script = script
local UIBuilder = require(script.Parent.UIBuilder)

local LocalPlayer = Players.LocalPlayer

local Notifications = {}

local screen
local function ensureScreen()
    if screen and screen.Parent then return screen end
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    screen = UIBuilder.New("ScreenGui", {
        Name = "Notifications", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = pg,
    })
    UIBuilder.New("Frame", {
        Name = "Stack", AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -20),
        Size = UDim2.fromOffset(420, 200),
        BackgroundTransparency = 1, Parent = screen,
    }, {UIBuilder.ListLayout({
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    })})
    return screen
end

local function show(message, color)
    local s = ensureScreen()
    local stack = s:WaitForChild("Stack")
    local toast = UIBuilder.New("TextLabel", {
        Size = UDim2.fromOffset(420, 36),
        BackgroundColor3 = Color3.fromRGB(15, 15, 25),
        BackgroundTransparency = 0.05,
        TextColor3 = color or Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold, TextScaled = true, Text = message,
        Parent = stack,
    }, {UIBuilder.Corner(8), UIBuilder.Stroke(color or Color3.fromRGB(255,255,255), 2)})

    toast.BackgroundTransparency = 1
    toast.TextTransparency = 1
    TweenService:Create(toast, TweenInfo.new(0.2), {BackgroundTransparency = 0.05, TextTransparency = 0}):Play()

    task.delay(4, function()
        TweenService:Create(toast, TweenInfo.new(0.4), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        task.wait(0.5)
        toast:Destroy()
    end)
end

function Notifications:Init()
    Remotes.Notification.OnClientEvent:Connect(function(msg)
        show(tostring(msg), Color3.fromRGB(255, 230, 120))
    end)
    Remotes.ServerAnnounce.OnClientEvent:Connect(function(msg)
        show(tostring(msg), Color3.fromRGB(255, 100, 100))
    end)
end

return Notifications
