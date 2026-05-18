--[[
    init.client.lua
    Boots all client UI modules and wires the HUD buttons to toggles.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local script = script
local clientScripts = script.Parent

local HUD            = require(clientScripts.HUD)
local Notifications  = require(clientScripts.Notifications)
local HatchAnimation = require(clientScripts.HatchAnimation)
local EggUI          = require(clientScripts.EggUI)
local InventoryUI    = require(clientScripts.InventoryUI)
local WorldsUI       = require(clientScripts.WorldsUI)
local RebirthUI      = require(clientScripts.RebirthUI)
local ShopUI         = require(clientScripts.ShopUI)
local AdminUI        = require(clientScripts.AdminUI)
require(clientScripts.PetFollow)
require(clientScripts.Breaking)

local LocalPlayer = Players.LocalPlayer

local hud = HUD:Build()
Notifications:Init()
HatchAnimation:Init()

local eggUI = EggUI:Build()
local invUI = InventoryUI:Build()
local worldsUI = WorldsUI:Build()
local rebirthUI = RebirthUI:Build()
local shopUI = ShopUI:Build()

hud.Buttons.Pets.MouseButton1Click:Connect(function()    invUI:Toggle()     end)
hud.Buttons.Eggs.MouseButton1Click:Connect(function()    eggUI:Toggle()     end)
hud.Buttons.Worlds.MouseButton1Click:Connect(function()  worldsUI:Toggle()  end)
hud.Buttons.Rebirth.MouseButton1Click:Connect(function() rebirthUI:Toggle() end)
hud.Buttons.Shop.MouseButton1Click:Connect(function()    shopUI:Toggle()    end)

-- Admin button + UI (only if server says we're admin)
local ok, isAdmin = pcall(function() return Remotes.IsAdmin:InvokeServer() end)
if ok and isAdmin then
    local adminUI = AdminUI:Build()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local sideButtons = hud.Screen:WaitForChild("SideButtons")
    local adminBtn = Instance.new("TextButton")
    adminBtn.Name = "Admin"
    adminBtn.Size = UDim2.fromOffset(70, 70)
    adminBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    adminBtn.TextColor3 = Color3.fromRGB(255,255,255)
    adminBtn.Font = Enum.Font.GothamBold
    adminBtn.TextScaled = true
    adminBtn.Text = "ADMIN"
    adminBtn.Parent = sideButtons
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = adminBtn
    adminBtn.MouseButton1Click:Connect(function() adminUI:Toggle() end)

    -- Optional: hotkey F4 to toggle admin
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.F4 then adminUI:Toggle() end
    end)
end

print("[PetLegendsX] Client booted.")
