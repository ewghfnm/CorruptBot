--[[
    EggUI.lua
    Egg list with hatch chances. Hatch buttons (1, 3, Auto).
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local EggDatabase = require(Shared.EggDatabase)
local PetDatabase = require(Shared.PetDatabase)
local Rarities = require(Shared.Rarities)
local Util = require(Shared.Util)

local script = script
local UIBuilder = require(script.Parent.UIBuilder)
local PlayerData = require(script.Parent.PlayerData)

local LocalPlayer = Players.LocalPlayer

local EggUI = {}

function EggUI:Build()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local screen = UIBuilder.New("ScreenGui", {
        Name = "EggUI", ResetOnSpawn = false, Enabled = false, Parent = pg,
    })
    local panel = UIBuilder.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(720, 480),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        Parent = screen,
    }, {UIBuilder.Corner(14), UIBuilder.Stroke(Color3.fromRGB(255,255,255), 2)})

    UIBuilder.New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1, Text = "EGGS",
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
        Size = UDim2.new(1, -20, 1, -60),
        Position = UDim2.fromOffset(10, 50),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0),
        Parent = panel,
    }, {UIBuilder.ListLayout({Padding = UDim.new(0, 8)})})

    for _, egg in ipairs(EggDatabase.List) do
        local row = UIBuilder.New("Frame", {
            Size = UDim2.new(1, -8, 0, 100),
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            Parent = list,
        }, {UIBuilder.Corner(10)})

        UIBuilder.New("TextLabel", {
            Position = UDim2.fromOffset(12, 8),
            Size = UDim2.new(0.4, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = egg.name .. "  (" .. egg.world .. ")",
            TextColor3 = Color3.fromRGB(255,255,255),
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
            TextScaled = true, Parent = row,
        })
        UIBuilder.New("TextLabel", {
            Position = UDim2.fromOffset(12, 36),
            Size = UDim2.new(0.4, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = "Cost: " .. Util.FormatNumber(egg.cost) .. " " .. egg.currency,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
            TextScaled = true, Parent = row,
        })

        -- Odds list
        local oddsBox = UIBuilder.New("Frame", {
            Position = UDim2.fromOffset(12, 60),
            Size = UDim2.new(0.55, 0, 0, 30),
            BackgroundTransparency = 1, Parent = row,
        }, {UIBuilder.ListLayout({FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)})})

        local total = 0
        for _, e in ipairs(egg.pets) do total = total + e.weight end
        for _, e in ipairs(egg.pets) do
            local def = PetDatabase.GetById(e.id)
            if def then
                local pct = (e.weight / total) * 100
                local r = Rarities.GetByName(def.rarity) or {color = Color3.new(1,1,1)}
                UIBuilder.New("TextLabel", {
                    Size = UDim2.fromOffset(80, 22),
                    BackgroundColor3 = r.color, BackgroundTransparency = 0.2,
                    TextColor3 = Color3.fromRGB(255,255,255),
                    Font = Enum.Font.GothamBold, TextScaled = true,
                    Text = string.format("%s %.2f%%", def.rarity, pct),
                    Parent = oddsBox,
                }, {UIBuilder.Corner(6)})
            end
        end

        -- Hatch buttons
        local function hatchBtn(label, count, x)
            local b = UIBuilder.New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, x, 0, 12),
                Size = UDim2.fromOffset(100, 32),
                BackgroundColor3 = Color3.fromRGB(80, 140, 60),
                Text = label, TextColor3 = Color3.fromRGB(255,255,255),
                Font = Enum.Font.GothamBold, TextScaled = true, Parent = row,
            }, {UIBuilder.Corner(8)})
            b.MouseButton1Click:Connect(function()
                if count == "auto" then
                    local d = PlayerData.data
                    local current = d and d.autoHatchEgg
                    Remotes.SetAutoHatch:FireServer(current == egg.id and nil or egg.id)
                else
                    Remotes.HatchEgg:FireServer(egg.id, count)
                end
            end)
            return b
        end
        hatchBtn("Hatch 1", 1, -12)
        hatchBtn("Hatch 3", 3, -120)
        hatchBtn("Auto",   "auto", -228)
    end

    self.Screen = screen
    return self
end

function EggUI:Toggle()
    self.Screen.Enabled = not self.Screen.Enabled
end

return EggUI
