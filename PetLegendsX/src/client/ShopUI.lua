--[[
    ShopUI.lua
    Lists all gamepasses and prompts purchase via MarketplaceService.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GamepassDatabase = require(Shared.GamepassDatabase)

local script = script
local UIBuilder = require(script.Parent.UIBuilder)
local PlayerData = require(script.Parent.PlayerData)

local LocalPlayer = Players.LocalPlayer

local ShopUI = {}

function ShopUI:Build()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local screen = UIBuilder.New("ScreenGui", {
        Name = "ShopUI", ResetOnSpawn = false, Enabled = false, Parent = pg,
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
        BackgroundTransparency = 1, Text = "SHOP - GAMEPASSES",
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

    for _, g in ipairs(GamepassDatabase.List) do
        local row = UIBuilder.New("Frame", {
            Size = UDim2.new(1, -8, 0, 70),
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            Parent = list,
        }, {UIBuilder.Corner(8)})

        UIBuilder.New("TextLabel", {
            Position = UDim2.fromOffset(10, 6),
            Size = UDim2.new(0.7, 0, 0, 26),
            BackgroundTransparency = 1, Text = g.name,
            TextColor3 = Color3.fromRGB(255,255,255),
            Font = Enum.Font.GothamBold, TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })
        UIBuilder.New("TextLabel", {
            Position = UDim2.fromOffset(10, 34),
            Size = UDim2.new(0.7, 0, 0, 30),
            BackgroundTransparency = 1, Text = g.description,
            TextColor3 = Color3.fromRGB(220,220,220),
            Font = Enum.Font.Gotham, TextScaled = true, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })
        local btn = UIBuilder.New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(140, 40),
            BackgroundColor3 = Color3.fromRGB(60, 120, 60),
            Text = g.priceRobux .. " R$", TextColor3 = Color3.fromRGB(255,255,255),
            Font = Enum.Font.GothamBold, TextScaled = true, Parent = row,
        }, {UIBuilder.Corner(8)})
        btn.MouseButton1Click:Connect(function()
            if g.id and g.id > 0 then
                MarketplaceService:PromptGamePassPurchase(LocalPlayer, g.id)
            else
                btn.Text = "Set ID in GamepassDatabase!"
            end
        end)

        local function refresh(d)
            if d and d.gamepasses and d.gamepasses[g.key] then
                btn.Text = "Owned"
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                btn.AutoButtonColor = false
            end
        end
        PlayerData.Changed:Connect(refresh)
        if PlayerData.data then refresh(PlayerData.data) end
    end

    self.Screen = screen
    return self
end

function ShopUI:Toggle() self.Screen.Enabled = not self.Screen.Enabled end

return ShopUI
