--[[
    InventoryUI.lua
    Pet inventory: equip/unequip, lock, delete. Search and rarity filter.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local PetDatabase = require(Shared.PetDatabase)
local Rarities = require(Shared.Rarities)
local Util = require(Shared.Util)

local script = script
local UIBuilder = require(script.Parent.UIBuilder)
local PlayerData = require(script.Parent.PlayerData)

local LocalPlayer = Players.LocalPlayer

local InventoryUI = {}

function InventoryUI:Build()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local screen = UIBuilder.New("ScreenGui", {
        Name = "InventoryUI", ResetOnSpawn = false, Enabled = false, Parent = pg,
    })
    local panel = UIBuilder.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(800, 540),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        Parent = screen,
    }, {UIBuilder.Corner(14), UIBuilder.Stroke(Color3.fromRGB(255,255,255), 2)})

    UIBuilder.New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1, Text = "PETS",
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

    local search = UIBuilder.New("TextBox", {
        Position = UDim2.fromOffset(12, 50),
        Size = UDim2.fromOffset(300, 32),
        BackgroundColor3 = Color3.fromRGB(40, 40, 55),
        TextColor3 = Color3.fromRGB(255,255,255),
        PlaceholderText = "Search...", Font = Enum.Font.Gotham,
        TextScaled = true, Text = "",
        Parent = panel,
    }, {UIBuilder.Corner(8)})

    local equippedLabel = UIBuilder.New("TextLabel", {
        Position = UDim2.fromOffset(330, 50),
        Size = UDim2.fromOffset(300, 32),
        BackgroundTransparency = 1,
        Text = "Equipped: 0/3", TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold, TextScaled = true, Parent = panel,
    })

    local grid = UIBuilder.New("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 90),
        Size = UDim2.new(1, -20, 1, -100),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0),
        Parent = panel,
    }, {UIBuilder.GridLayout({CellSize = UDim2.fromOffset(150, 170)})})

    local function render(d)
        if not d then return end
        for _, c in ipairs(grid:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local equippedCount = 0
        local query = string.lower(search.Text or "")
        for _, p in ipairs(d.pets or {}) do
            local def = PetDatabase.GetById(p.id); if not def then continue end
            if p.equipped then equippedCount += 1 end
            if query ~= "" and not string.find(string.lower(def.name), query, 1, true) then continue end

            local r = Rarities.GetByName(def.rarity) or {color = Color3.new(1,1,1), glow = Color3.new(1,1,1)}
            local card = UIBuilder.New("Frame", {
                BackgroundColor3 = r.color, BackgroundTransparency = 0.15,
                Parent = grid,
            }, {UIBuilder.Corner(10), UIBuilder.Stroke(p.equipped and Color3.fromRGB(0,255,0) or r.glow, p.equipped and 3 or 1)})

            UIBuilder.New("TextLabel", {
                Size = UDim2.new(1, -8, 0, 24),
                Position = UDim2.fromOffset(4, 4),
                BackgroundTransparency = 1, Text = def.name,
                TextColor3 = Color3.fromRGB(255,255,255),
                Font = Enum.Font.GothamBold, TextScaled = true, Parent = card,
            })
            UIBuilder.New("TextLabel", {
                Size = UDim2.new(1, -8, 0, 18),
                Position = UDim2.fromOffset(4, 28),
                BackgroundTransparency = 1,
                Text = (p.tier ~= "Standard" and (p.tier .. " ") or "") ..
                       (p.mutation and (p.mutation .. " ") or "") .. def.rarity,
                TextColor3 = Color3.fromRGB(255,255,255),
                Font = Enum.Font.Gotham, TextScaled = true, Parent = card,
            })
            UIBuilder.New("TextLabel", {
                Size = UDim2.new(1, -8, 0, 18),
                Position = UDim2.fromOffset(4, 48),
                BackgroundTransparency = 1,
                Text = string.format("Lv %d  Dmg %s", p.level or 1, Util.FormatNumber(def.damage)),
                TextColor3 = Color3.fromRGB(220,220,220),
                Font = Enum.Font.Gotham, TextScaled = true, Parent = card,
            })

            local function makeBtn(text, x, y, w, color, fn)
                local b = UIBuilder.New("TextButton", {
                    Position = UDim2.fromOffset(x, y),
                    Size = UDim2.fromOffset(w, 24),
                    BackgroundColor3 = color,
                    TextColor3 = Color3.fromRGB(255,255,255),
                    Font = Enum.Font.GothamBold, TextScaled = true, Text = text,
                    Parent = card,
                }, {UIBuilder.Corner(6)})
                b.MouseButton1Click:Connect(fn)
                return b
            end
            local equipText = p.equipped and "Unequip" or "Equip"
            makeBtn(equipText, 6, 100, 138, Color3.fromRGB(60, 120, 60), function()
                if p.equipped then Remotes.UnequipPet:FireServer(p.uid)
                else Remotes.EquipPet:FireServer(p.uid) end
            end)
            local lockText = p.locked and "Unlock" or "Lock"
            makeBtn(lockText, 6, 128, 66, Color3.fromRGB(80, 80, 130), function()
                Remotes.LockPet:FireServer(p.uid, not p.locked)
            end)
            local delBtn = makeBtn("Delete", 78, 128, 66, Color3.fromRGB(150, 50, 50), function()
                Remotes.DeletePet:FireServer(p.uid)
            end)
            if p.locked then delBtn.AutoButtonColor = false; delBtn.BackgroundColor3 = Color3.fromRGB(80,30,30) end
        end
        local maxSlots = d.equippedSlots or 3
        equippedLabel.Text = string.format("Equipped: %d/%d", equippedCount, maxSlots)
    end

    PlayerData.Changed:Connect(render)
    if PlayerData.data then render(PlayerData.data) end
    search:GetPropertyChangedSignal("Text"):Connect(function() render(PlayerData.data) end)

    self.Screen = screen
    return self
end

function InventoryUI:Toggle()
    self.Screen.Enabled = not self.Screen.Enabled
end

return InventoryUI
