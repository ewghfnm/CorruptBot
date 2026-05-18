--[[
    RebirthUI.lua
    Simple rebirth confirmation popup.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Config = require(Shared.Config)
local Util = require(Shared.Util)

local script = script
local UIBuilder = require(script.Parent.UIBuilder)
local PlayerData = require(script.Parent.PlayerData)

local LocalPlayer = Players.LocalPlayer

local RebirthUI = {}

function RebirthUI:Build()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local screen = UIBuilder.New("ScreenGui", {
        Name = "RebirthUI", ResetOnSpawn = false, Enabled = false, Parent = pg,
    })
    local panel = UIBuilder.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(420, 260),
        BackgroundColor3 = Color3.fromRGB(40, 20, 50),
        Parent = screen,
    }, {UIBuilder.Corner(14), UIBuilder.Stroke(Color3.fromRGB(255, 100, 200), 3)})

    UIBuilder.New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1, Text = "REBIRTH",
        TextColor3 = Color3.fromRGB(255, 100, 200),
        Font = Enum.Font.GothamBlack, TextScaled = true, Parent = panel,
    })
    local info = UIBuilder.New("TextLabel", {
        Position = UDim2.fromOffset(20, 50),
        Size = UDim2.new(1, -40, 0, 110),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.Gotham, TextScaled = true, TextWrapped = true,
        Text = "...", Parent = panel,
    })
    local btn = UIBuilder.New("TextButton", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -16),
        Size = UDim2.fromOffset(220, 40),
        BackgroundColor3 = Color3.fromRGB(180, 50, 130),
        Text = "Rebirth!", TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold, TextScaled = true, Parent = panel,
    }, {UIBuilder.Corner(8)})
    btn.MouseButton1Click:Connect(function()
        Remotes.Rebirth:FireServer()
    end)
    local closeBtn = UIBuilder.New("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -34, 0, 6),
        BackgroundColor3 = Color3.fromRGB(180, 50, 50),
        Text = "X", TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold, TextScaled = true, Parent = panel,
    }, {UIBuilder.Corner(6)})
    closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

    local function refresh(d)
        if not d then return end
        local cost = math.floor(Config.REBIRTH_BASE_COST * (Config.REBIRTH_COST_SCALE ^ (d.rebirths or 0)))
        local nextMul = Config.REBIRTH_MULTIPLIER ^ ((d.rebirths or 0) + 1)
        info.Text = string.format(
            "Rebirths: %d\nCost: %s coins\nAfter rebirth: %sx multiplier (resets coins & worlds)",
            d.rebirths or 0, Util.FormatNumber(cost), Util.FormatNumber(nextMul)
        )
    end
    PlayerData.Changed:Connect(refresh)
    if PlayerData.data then refresh(PlayerData.data) end

    self.Screen = screen
    return self
end

function RebirthUI:Toggle() self.Screen.Enabled = not self.Screen.Enabled end

return RebirthUI
