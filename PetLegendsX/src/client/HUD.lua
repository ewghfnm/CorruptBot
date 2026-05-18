--[[
    HUD.lua
    Top-of-screen coins/gems/rebirths display + side buttons that open menus.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Util = require(Shared.Util)
local Remotes = require(Shared.Remotes)

local script = script
local UIBuilder = require(script.Parent.UIBuilder)
local PlayerData = require(script.Parent.PlayerData)

local LocalPlayer = Players.LocalPlayer

local HUD = {}

function HUD:Build()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local screen = UIBuilder.New("ScreenGui", {
        Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = pg,
    })

    local topBar = UIBuilder.New("Frame", {
        Name = "TopBar", Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1, Parent = screen,
    })

    local function makeStat(name, color)
        local f = UIBuilder.New("Frame", {
            Size = UDim2.fromOffset(200, 40),
            BackgroundColor3 = Color3.fromRGB(20, 20, 30),
            BackgroundTransparency = 0.2,
            Parent = topBar,
        }, {UIBuilder.Corner(10), UIBuilder.Stroke(color, 2)})
        local lbl = UIBuilder.New("TextLabel", {
            Name = "Label", Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255,255,255),
            Font = Enum.Font.GothamBold, TextScaled = true, Text = name .. ": 0",
            Parent = f,
        })
        return f, lbl
    end

    local layout = UIBuilder.ListLayout({
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })
    layout.Parent = topBar

    UIBuilder.New("UIPadding", {PaddingTop = UDim.new(0, 4), Parent = topBar})

    local _, coinsLbl = makeStat("Coins", Color3.fromRGB(255, 215, 0))
    local _, gemsLbl  = makeStat("Gems",  Color3.fromRGB(0, 200, 255))
    local _, rbLbl    = makeStat("Rebirths", Color3.fromRGB(255, 100, 200))

    -- Side buttons
    local side = UIBuilder.New("Frame", {
        Name = "SideButtons", AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(70, 320),
        BackgroundTransparency = 1, Parent = screen,
    })
    UIBuilder.ListLayout({Padding = UDim.new(0, 8)}).Parent = side

    local buttons = {}
    local function makeButton(name, label, color)
        local b = UIBuilder.New("TextButton", {
            Name = name, Size = UDim2.fromOffset(70, 70),
            BackgroundColor3 = color or Color3.fromRGB(40, 40, 60),
            TextColor3 = Color3.fromRGB(255,255,255),
            Font = Enum.Font.GothamBold, TextScaled = true, Text = label,
            Parent = side,
        }, {UIBuilder.Corner(12), UIBuilder.Stroke(Color3.fromRGB(255,255,255), 1)})
        buttons[name] = b
        return b
    end
    makeButton("Pets",     "Pets",   Color3.fromRGB(80, 50, 130))
    makeButton("Eggs",     "Eggs",   Color3.fromRGB(130, 70, 50))
    makeButton("Worlds",   "Worlds", Color3.fromRGB(50, 100, 130))
    makeButton("Rebirth",  "Rebirth",Color3.fromRGB(140, 50, 110))
    makeButton("Shop",     "Shop",   Color3.fromRGB(40, 120, 60))
    -- Admin button is added later if applicable

    local function refresh(d)
        if not d then return end
        coinsLbl.Text = "Coins: " .. Util.FormatNumber(d.coins)
        gemsLbl.Text  = "Gems: "  .. Util.FormatNumber(d.gems)
        rbLbl.Text    = "Rebirths: " .. tostring(d.rebirths or 0)
    end
    PlayerData.Changed:Connect(refresh)
    if PlayerData.data then refresh(PlayerData.data) end

    self.Screen = screen
    self.Buttons = buttons
    return self
end

return HUD
