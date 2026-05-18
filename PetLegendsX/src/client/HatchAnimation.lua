--[[
    HatchAnimation.lua
    Plays a dramatic full-screen reveal when the server fires HatchResult.
    Stacks results visually so triple-hatches show all three.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Rarities = require(Shared.Rarities)
local Config = require(Shared.Config)

local script = script
local UIBuilder = require(script.Parent.UIBuilder)

local LocalPlayer = Players.LocalPlayer

local HatchAnimation = {}

function HatchAnimation:Play(eggId, results)
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local screen = UIBuilder.New("ScreenGui", {
        Name = "HatchScreen", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 100, Parent = pg,
    })
    local backdrop = UIBuilder.New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.4, Parent = screen,
    })

    local container = UIBuilder.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(800, 280),
        BackgroundTransparency = 1, Parent = screen,
    }, {UIBuilder.ListLayout({
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 12),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })})

    for _, r in ipairs(results) do
        local rdef = Rarities.GetByName(r.rarity) or {color = Color3.new(1,1,1), glow = Color3.new(1,1,1)}
        local card = UIBuilder.New("Frame", {
            Size = UDim2.fromOffset(220, 260),
            BackgroundColor3 = rdef.color,
            BackgroundTransparency = 0.1,
            Parent = container,
        }, {UIBuilder.Corner(16), UIBuilder.Stroke(rdef.glow, 3)})

        UIBuilder.New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.fromOffset(0, 10),
            BackgroundTransparency = 1,
            Text = (r.tier and r.tier ~= "Standard" and (r.tier .. " ") or "")
                  .. (r.mutation and (string.upper(r.mutation:sub(1,1)) .. r.mutation:sub(2) .. " ") or "")
                  .. r.rarity,
            TextColor3 = Color3.fromRGB(255,255,255),
            Font = Enum.Font.GothamBold, TextScaled = true,
            Parent = card,
        })
        UIBuilder.New("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(0.9, 0, 0, 60),
            BackgroundTransparency = 1,
            Text = r.name,
            TextColor3 = Color3.fromRGB(255,255,255),
            Font = Enum.Font.GothamBlack, TextScaled = true,
            Parent = card,
        })
        if r.isHuge then
            UIBuilder.New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -10),
                Size = UDim2.new(0.9, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "HUGE!",
                TextColor3 = Color3.fromRGB(255, 255, 0),
                Font = Enum.Font.GothamBlack, TextScaled = true,
                Parent = card,
            })
        end

        card.Size = UDim2.fromOffset(0, 0)
        TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
            Size = UDim2.fromOffset(220, 260),
        }):Play()
    end

    task.delay(Config.HATCH_ANIMATION_TIME + 1.0, function()
        TweenService:Create(backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.4)
        screen:Destroy()
    end)
end

function HatchAnimation:Init()
    Remotes.HatchResult.OnClientEvent:Connect(function(eggId, results)
        if results and #results > 0 then self:Play(eggId, results) end
    end)
end

return HatchAnimation
