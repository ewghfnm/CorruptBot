--[[
    WorldsUI.lua
    World list with unlock buttons.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local WorldDatabase = require(Shared.WorldDatabase)
local Util = require(Shared.Util)

local script = script
local UIBuilder = require(script.Parent.UIBuilder)
local PlayerData = require(script.Parent.PlayerData)

local LocalPlayer = Players.LocalPlayer

local WorldsUI = {}

function WorldsUI:Build()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local screen = UIBuilder.New("ScreenGui", {
        Name = "WorldsUI", ResetOnSpawn = false, Enabled = false, Parent = pg,
    })
    local panel = UIBuilder.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(640, 480),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        Parent = screen,
    }, {UIBuilder.Corner(14), UIBuilder.Stroke(Color3.fromRGB(255,255,255), 2)})

    UIBuilder.New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1, Text = "WORLDS",
        TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBlack, TextScaled = true, Parent = panel,
    })
    local closeBtn = UIBuilder.New("TextButton", {
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -42, 0, 6),
        BackgroundColor3 = Color3.fromRGB(180, 50, 50),
        Text = "X", TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold, TextScaled = true, Parent = panel,
    }, {UIBuilder.Corner(8)})
    closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

    local list = UIBuilder.New("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 50),
        Size = UDim2.new(1, -20, 1, -60),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0),
        Parent = panel,
    }, {UIBuilder.ListLayout({Padding = UDim.new(0, 6)})})

    local function render(d)
        if not d then return end
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for _, w in ipairs(WorldDatabase.List) do
            local owned = d.unlockedWorlds[w.id]
            local row = UIBuilder.New("Frame", {
                Size = UDim2.new(1, -8, 0, 60),
                BackgroundColor3 = owned and Color3.fromRGB(40, 60, 40) or Color3.fromRGB(40, 40, 55),
                Parent = list,
            }, {UIBuilder.Corner(8)})
            UIBuilder.New("TextLabel", {
                Position = UDim2.fromOffset(10, 6),
                Size = UDim2.new(0.6, 0, 0, 28),
                BackgroundTransparency = 1,
                Text = w.name,
                TextColor3 = Color3.fromRGB(255,255,255),
                Font = Enum.Font.GothamBold, TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
            })
            UIBuilder.New("TextLabel", {
                Position = UDim2.fromOffset(10, 32),
                Size = UDim2.new(0.6, 0, 0, 22),
                BackgroundTransparency = 1,
                Text = string.format("Cost: %s coins  |  Rebirth req: %d  |  Coin x%s",
                    Util.FormatNumber(w.unlockCost), w.rebirthRequired or 0, Util.FormatNumber(w.coinMultiplier)),
                TextColor3 = Color3.fromRGB(220,220,220),
                Font = Enum.Font.Gotham, TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
            })
            local btn = UIBuilder.New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(120, 36),
                BackgroundColor3 = owned and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(60, 120, 60),
                Text = owned and "Unlocked" or "Unlock",
                TextColor3 = Color3.fromRGB(255,255,255),
                Font = Enum.Font.GothamBold, TextScaled = true, Parent = row,
            }, {UIBuilder.Corner(8)})
            if not owned then
                btn.MouseButton1Click:Connect(function()
                    Remotes.UnlockWorld:FireServer(w.id)
                end)
            end
        end
    end

    PlayerData.Changed:Connect(render)
    if PlayerData.data then render(PlayerData.data) end

    self.Screen = screen
    return self
end

function WorldsUI:Toggle() self.Screen.Enabled = not self.Screen.Enabled end

return WorldsUI
