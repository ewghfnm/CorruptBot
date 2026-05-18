--[[
============================================================
   PET LEGENDS X - CLIENT SCRIPT
   Place: StarterPlayer > StarterPlayerScripts
   Type:  LocalScript
   Name:  anything you like (e.g. "PetLegendsX_Client")
============================================================

   This is the entire client. It builds the HUD, all menus,
   the hatch animation, notifications, pet visuals and the
   admin panel (visible only if the server says you're an admin).

   Make sure ReplicatedStorage has a ModuleScript named:
     PetLegendsX_Shared
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local Shared = require(ReplicatedStorage:WaitForChild("PetLegendsX_Shared"))
local Config = Shared.Config
local Util = Shared.Util
local Signal = Shared.Signal
local Remotes = Shared.Remotes
local Rarities = Shared.Rarities
local PetDatabase = Shared.PetDatabase
local EggDatabase = Shared.EggDatabase
local WorldDatabase = Shared.WorldDatabase
local GamepassDatabase = Shared.GamepassDatabase

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =============================================================
-- UI BUILDER HELPERS
-- =============================================================
local function New(className, props, children)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
    end
    if children then for _, c in ipairs(children) do c.Parent = inst end end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end
local function Corner(r) return New("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end
local function Stroke(c, t) return New("UIStroke", {Color = c or Color3.fromRGB(0,0,0), Thickness = t or 2}) end
local function ListLayout(props)
    props = props or {}
    props.Padding = props.Padding or UDim.new(0, 4)
    props.SortOrder = props.SortOrder or Enum.SortOrder.LayoutOrder
    return New("UIListLayout", props)
end
local function GridLayout(props)
    props = props or {}
    props.CellSize = props.CellSize or UDim2.fromOffset(80, 80)
    props.CellPadding = props.CellPadding or UDim2.fromOffset(6, 6)
    return New("UIGridLayout", props)
end

-- =============================================================
-- PLAYER DATA CACHE
-- =============================================================
local PlayerData = {Changed = Signal.new(), data = nil}
Remotes.PlayerDataUpdated.OnClientEvent:Connect(function(d)
    PlayerData.data = d; PlayerData.Changed:Fire(d)
end)
task.spawn(function()
    local ok, d = pcall(function() return Remotes.GetPlayerData:InvokeServer() end)
    if ok and d and not PlayerData.data then PlayerData.data = d; PlayerData.Changed:Fire(d) end
end)

-- =============================================================
-- HUD
-- =============================================================
local hudScreen = New("ScreenGui", {Name="HUD", ResetOnSpawn=false, IgnoreGuiInset=true, Parent=PlayerGui})
local topBar = New("Frame", {Name="TopBar", Size=UDim2.new(1,0,0,50), BackgroundTransparency=1, Parent=hudScreen})
ListLayout({FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6), HorizontalAlignment=Enum.HorizontalAlignment.Center}).Parent = topBar
New("UIPadding", {PaddingTop=UDim.new(0,4), Parent=topBar})

local function makeStat(name, color)
    local f = New("Frame", {Size=UDim2.fromOffset(200,40), BackgroundColor3=Color3.fromRGB(20,20,30), BackgroundTransparency=0.2, Parent=topBar},
        {Corner(10), Stroke(color, 2)})
    local lbl = New("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextScaled=true, Text=name..": 0", Parent=f})
    return lbl
end
local coinsLbl = makeStat("Coins", Color3.fromRGB(255,215,0))
local gemsLbl  = makeStat("Gems",  Color3.fromRGB(0,200,255))
local rbLbl    = makeStat("Rebirths", Color3.fromRGB(255,100,200))

local sideButtons = New("Frame", {Name="SideButtons", AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,10,0.5,0), Size=UDim2.fromOffset(70,400), BackgroundTransparency=1, Parent=hudScreen})
ListLayout({Padding=UDim.new(0,8)}).Parent = sideButtons

local function makeSideButton(name, label, color)
    return New("TextButton", {Name=name, Size=UDim2.fromOffset(70,70),
        BackgroundColor3=color or Color3.fromRGB(40,40,60), TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextScaled=true, Text=label, Parent=sideButtons},
        {Corner(12), Stroke(Color3.fromRGB(255,255,255), 1)})
end
local petsBtn    = makeSideButton("Pets","Pets",Color3.fromRGB(80,50,130))
local eggsBtn    = makeSideButton("Eggs","Eggs",Color3.fromRGB(130,70,50))
local worldsBtn  = makeSideButton("Worlds","Worlds",Color3.fromRGB(50,100,130))
local rebirthBtn = makeSideButton("Rebirth","Rebirth",Color3.fromRGB(140,50,110))
local shopBtn    = makeSideButton("Shop","Shop",Color3.fromRGB(40,120,60))

PlayerData.Changed:Connect(function(d)
    if not d then return end
    coinsLbl.Text = "Coins: " .. Util.FormatNumber(d.coins)
    gemsLbl.Text  = "Gems: "  .. Util.FormatNumber(d.gems)
    rbLbl.Text    = "Rebirths: " .. tostring(d.rebirths or 0)
end)
if PlayerData.data then
    coinsLbl.Text = "Coins: " .. Util.FormatNumber(PlayerData.data.coins)
    gemsLbl.Text  = "Gems: "  .. Util.FormatNumber(PlayerData.data.gems)
    rbLbl.Text    = "Rebirths: " .. tostring(PlayerData.data.rebirths or 0)
end

-- =============================================================
-- NOTIFICATIONS
-- =============================================================
local notifScreen = New("ScreenGui", {Name="Notifications", ResetOnSpawn=false, IgnoreGuiInset=true, Parent=PlayerGui})
local notifStack = New("Frame", {Name="Stack", AnchorPoint=Vector2.new(0.5,1),
    Position=UDim2.new(0.5,0,1,-20), Size=UDim2.fromOffset(420,200), BackgroundTransparency=1, Parent=notifScreen},
    {ListLayout({Padding=UDim.new(0,6), HorizontalAlignment=Enum.HorizontalAlignment.Center, VerticalAlignment=Enum.VerticalAlignment.Bottom})})

local function showToast(message, color)
    local toast = New("TextLabel", {Size=UDim2.fromOffset(420,36),
        BackgroundColor3=Color3.fromRGB(15,15,25), BackgroundTransparency=0.05,
        TextColor3=color or Color3.fromRGB(255,255,255), Font=Enum.Font.GothamBold,
        TextScaled=true, Text=message, Parent=notifStack},
        {Corner(8), Stroke(color or Color3.fromRGB(255,255,255), 2)})
    toast.BackgroundTransparency = 1; toast.TextTransparency = 1
    TweenService:Create(toast, TweenInfo.new(0.2), {BackgroundTransparency=0.05, TextTransparency=0}):Play()
    task.delay(4, function()
        TweenService:Create(toast, TweenInfo.new(0.4), {BackgroundTransparency=1, TextTransparency=1}):Play()
        task.wait(0.5); toast:Destroy()
    end)
end
Remotes.Notification.OnClientEvent:Connect(function(msg) showToast(tostring(msg), Color3.fromRGB(255,230,120)) end)
Remotes.ServerAnnounce.OnClientEvent:Connect(function(msg) showToast(tostring(msg), Color3.fromRGB(255,100,100)) end)

-- =============================================================
-- HATCH ANIMATION
-- =============================================================
Remotes.HatchResult.OnClientEvent:Connect(function(_, results)
    if not results or #results == 0 then return end
    local screen = New("ScreenGui", {Name="HatchScreen", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=100, Parent=PlayerGui})
    local backdrop = New("Frame", {Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.4, Parent=screen})
    local container = New("Frame", {AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(800,280), BackgroundTransparency=1, Parent=screen},
        {ListLayout({FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,12),
            HorizontalAlignment=Enum.HorizontalAlignment.Center, VerticalAlignment=Enum.VerticalAlignment.Center})})
    for _, r in ipairs(results) do
        local rdef = Rarities.GetByName(r.rarity) or {color=Color3.new(1,1,1), glow=Color3.new(1,1,1)}
        local card = New("Frame", {Size=UDim2.fromOffset(220,260),
            BackgroundColor3=rdef.color, BackgroundTransparency=0.1, Parent=container},
            {Corner(16), Stroke(rdef.glow, 3)})
        New("TextLabel", {Size=UDim2.new(1,0,0,30), Position=UDim2.fromOffset(0,10),
            BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,255,255),
            Font=Enum.Font.GothamBold, TextScaled=true,
            Text=(r.tier and r.tier~="Standard" and (r.tier.." ") or "")
                .. (r.mutation and (string.upper(r.mutation:sub(1,1))..r.mutation:sub(2).." ") or "")
                .. r.rarity, Parent=card})
        New("TextLabel", {AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.new(0.9,0,0,60), BackgroundTransparency=1, Text=r.name,
            TextColor3=Color3.fromRGB(255,255,255), Font=Enum.Font.GothamBlack, TextScaled=true, Parent=card})
        if r.isHuge then
            New("TextLabel", {AnchorPoint=Vector2.new(0.5,1), Position=UDim2.new(0.5,0,1,-10),
                Size=UDim2.new(0.9,0,0,30), BackgroundTransparency=1, Text="HUGE!",
                TextColor3=Color3.fromRGB(255,255,0), Font=Enum.Font.GothamBlack, TextScaled=true, Parent=card})
        end
        card.Size = UDim2.fromOffset(0,0)
        TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size=UDim2.fromOffset(220,260)}):Play()
    end
    task.delay(Config.HATCH_ANIMATION_TIME + 1.0, function()
        TweenService:Create(backdrop, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
        task.wait(0.4); screen:Destroy()
    end)
end)

-- =============================================================
-- GENERIC MENU BUILDER
-- =============================================================
local function buildMenu(title, w, h, color)
    local screen = New("ScreenGui", {Name=title.."UI", ResetOnSpawn=false, Enabled=false, Parent=PlayerGui})
    local panel = New("Frame", {AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(w,h), BackgroundColor3=Color3.fromRGB(25,25,35), Parent=screen},
        {Corner(14), Stroke(color or Color3.fromRGB(255,255,255), 2)})
    New("TextLabel", {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1, Text=title,
        TextColor3=Color3.fromRGB(255,255,255), Font=Enum.Font.GothamBlack, TextScaled=true, Parent=panel})
    local closeBtn = New("TextButton", {Size=UDim2.fromOffset(36,36), Position=UDim2.new(1,-42,0,6),
        BackgroundColor3=Color3.fromRGB(180,50,50), Text="X", TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextScaled=true, Parent=panel}, {Corner(8)})
    closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)
    return screen, panel
end

-- =============================================================
-- EGG UI
-- =============================================================
local eggScreen, eggPanel = buildMenu("EGGS", 720, 480)
local eggList = New("ScrollingFrame", {Size=UDim2.new(1,-20,1,-60), Position=UDim2.fromOffset(10,50),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=6,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0), Parent=eggPanel},
    {ListLayout({Padding=UDim.new(0,8)})})

for _, egg in ipairs(EggDatabase.List) do
    local row = New("Frame", {Size=UDim2.new(1,-8,0,100), BackgroundColor3=Color3.fromRGB(40,40,55), Parent=eggList}, {Corner(10)})
    New("TextLabel", {Position=UDim2.fromOffset(12,8), Size=UDim2.new(0.4,0,0,28), BackgroundTransparency=1,
        Text=egg.name.."  ("..egg.world..")", TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, TextScaled=true, Parent=row})
    New("TextLabel", {Position=UDim2.fromOffset(12,36), Size=UDim2.new(0.4,0,0,24), BackgroundTransparency=1,
        Text="Cost: "..Util.FormatNumber(egg.cost).." "..egg.currency, TextColor3=Color3.fromRGB(220,220,220),
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, TextScaled=true, Parent=row})
    local oddsBox = New("Frame", {Position=UDim2.fromOffset(12,60), Size=UDim2.new(0.55,0,0,30),
        BackgroundTransparency=1, Parent=row},
        {ListLayout({FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6)})})
    local total = 0
    for _, e in ipairs(egg.pets) do total += e.weight end
    for _, e in ipairs(egg.pets) do
        local def = PetDatabase.GetById(e.id)
        if def then
            local pct = (e.weight / total) * 100
            local r = Rarities.GetByName(def.rarity) or {color=Color3.new(1,1,1)}
            New("TextLabel", {Size=UDim2.fromOffset(80,22), BackgroundColor3=r.color, BackgroundTransparency=0.2,
                TextColor3=Color3.fromRGB(255,255,255), Font=Enum.Font.GothamBold, TextScaled=true,
                Text=string.format("%s %.2f%%", def.rarity, pct), Parent=oddsBox}, {Corner(6)})
        end
    end
    local function hatchBtn(label, count, x)
        local b = New("TextButton", {AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,x,0,12),
            Size=UDim2.fromOffset(100,32), BackgroundColor3=Color3.fromRGB(80,140,60),
            Text=label, TextColor3=Color3.fromRGB(255,255,255), Font=Enum.Font.GothamBold, TextScaled=true, Parent=row},
            {Corner(8)})
        b.MouseButton1Click:Connect(function()
            if count == "auto" then
                local d = PlayerData.data
                local current = d and d.autoHatchEgg
                Remotes.SetAutoHatch:FireServer(current == egg.id and nil or egg.id)
            else
                Remotes.HatchEgg:FireServer(egg.id, count)
            end
        end)
    end
    hatchBtn("Hatch 1", 1, -12)
    hatchBtn("Hatch 3", 3, -120)
    hatchBtn("Auto",   "auto", -228)
end
eggsBtn.MouseButton1Click:Connect(function() eggScreen.Enabled = not eggScreen.Enabled end)

-- =============================================================
-- INVENTORY UI
-- =============================================================
local invScreen, invPanel = buildMenu("PETS", 800, 540)
local invSearch = New("TextBox", {Position=UDim2.fromOffset(12,50), Size=UDim2.fromOffset(300,32),
    BackgroundColor3=Color3.fromRGB(40,40,55), TextColor3=Color3.fromRGB(255,255,255),
    PlaceholderText="Search...", Font=Enum.Font.Gotham, TextScaled=true, Text="", Parent=invPanel}, {Corner(8)})
local invEquippedLbl = New("TextLabel", {Position=UDim2.fromOffset(330,50), Size=UDim2.fromOffset(300,32),
    BackgroundTransparency=1, Text="Equipped: 0/3", TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBold, TextScaled=true, Parent=invPanel})
local invGrid = New("ScrollingFrame", {Position=UDim2.fromOffset(10,90), Size=UDim2.new(1,-20,1,-100),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=6,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0), Parent=invPanel},
    {GridLayout({CellSize=UDim2.fromOffset(150,170)})})

local function renderInventory(d)
    if not d then return end
    for _, c in ipairs(invGrid:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local equippedCount = 0
    local query = string.lower(invSearch.Text or "")
    for _, p in ipairs(d.pets or {}) do
        local def = PetDatabase.GetById(p.id); if not def then continue end
        if p.equipped then equippedCount += 1 end
        if query ~= "" and not string.find(string.lower(def.name), query, 1, true) then continue end
        local r = Rarities.GetByName(def.rarity) or {color=Color3.new(1,1,1), glow=Color3.new(1,1,1)}
        local card = New("Frame", {BackgroundColor3=r.color, BackgroundTransparency=0.15, Parent=invGrid},
            {Corner(10), Stroke(p.equipped and Color3.fromRGB(0,255,0) or r.glow, p.equipped and 3 or 1)})
        New("TextLabel", {Size=UDim2.new(1,-8,0,24), Position=UDim2.fromOffset(4,4),
            BackgroundTransparency=1, Text=def.name, TextColor3=Color3.fromRGB(255,255,255),
            Font=Enum.Font.GothamBold, TextScaled=true, Parent=card})
        New("TextLabel", {Size=UDim2.new(1,-8,0,18), Position=UDim2.fromOffset(4,28),
            BackgroundTransparency=1,
            Text=(p.tier ~= "Standard" and (p.tier.." ") or "")
                .. (p.mutation and (p.mutation.." ") or "") .. def.rarity,
            TextColor3=Color3.fromRGB(255,255,255), Font=Enum.Font.Gotham, TextScaled=true, Parent=card})
        New("TextLabel", {Size=UDim2.new(1,-8,0,18), Position=UDim2.fromOffset(4,48),
            BackgroundTransparency=1,
            Text=string.format("Lv %d  Dmg %s", p.level or 1, Util.FormatNumber(def.damage)),
            TextColor3=Color3.fromRGB(220,220,220), Font=Enum.Font.Gotham, TextScaled=true, Parent=card})
        local function makeBtn(text, x, y, w, color, fn)
            local b = New("TextButton", {Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(w,24),
                BackgroundColor3=color, TextColor3=Color3.fromRGB(255,255,255),
                Font=Enum.Font.GothamBold, TextScaled=true, Text=text, Parent=card}, {Corner(6)})
            b.MouseButton1Click:Connect(fn); return b
        end
        makeBtn(p.equipped and "Unequip" or "Equip", 6, 100, 138, Color3.fromRGB(60,120,60), function()
            if p.equipped then Remotes.UnequipPet:FireServer(p.uid)
            else Remotes.EquipPet:FireServer(p.uid) end
        end)
        makeBtn(p.locked and "Unlock" or "Lock", 6, 128, 66, Color3.fromRGB(80,80,130), function()
            Remotes.LockPet:FireServer(p.uid, not p.locked)
        end)
        local delBtn = makeBtn("Delete", 78, 128, 66, Color3.fromRGB(150,50,50), function()
            Remotes.DeletePet:FireServer(p.uid)
        end)
        if p.locked then delBtn.AutoButtonColor = false; delBtn.BackgroundColor3 = Color3.fromRGB(80,30,30) end
    end
    invEquippedLbl.Text = string.format("Equipped: %d/%d", equippedCount, d.equippedSlots or 3)
end
PlayerData.Changed:Connect(renderInventory)
if PlayerData.data then renderInventory(PlayerData.data) end
invSearch:GetPropertyChangedSignal("Text"):Connect(function() renderInventory(PlayerData.data) end)
petsBtn.MouseButton1Click:Connect(function() invScreen.Enabled = not invScreen.Enabled end)

-- =============================================================
-- WORLDS UI
-- =============================================================
local worldScreen, worldPanel = buildMenu("WORLDS", 640, 480)
local worldList = New("ScrollingFrame", {Position=UDim2.fromOffset(10,50), Size=UDim2.new(1,-20,1,-60),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=6,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0), Parent=worldPanel},
    {ListLayout({Padding=UDim.new(0,6)})})

local function renderWorlds(d)
    if not d then return end
    for _, c in ipairs(worldList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for _, w in ipairs(WorldDatabase.List) do
        local owned = d.unlockedWorlds[w.id]
        local row = New("Frame", {Size=UDim2.new(1,-8,0,60),
            BackgroundColor3=owned and Color3.fromRGB(40,60,40) or Color3.fromRGB(40,40,55), Parent=worldList}, {Corner(8)})
        New("TextLabel", {Position=UDim2.fromOffset(10,6), Size=UDim2.new(0.6,0,0,28),
            BackgroundTransparency=1, Text=w.name, TextColor3=Color3.fromRGB(255,255,255),
            Font=Enum.Font.GothamBold, TextScaled=true, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
        New("TextLabel", {Position=UDim2.fromOffset(10,32), Size=UDim2.new(0.6,0,0,22),
            BackgroundTransparency=1,
            Text=string.format("Cost: %s coins  |  Rebirth req: %d  |  Coin x%s",
                Util.FormatNumber(w.unlockCost), w.rebirthRequired or 0, Util.FormatNumber(w.coinMultiplier)),
            TextColor3=Color3.fromRGB(220,220,220), Font=Enum.Font.Gotham, TextScaled=true,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
        local btn = New("TextButton", {AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
            Size=UDim2.fromOffset(120,36),
            BackgroundColor3=owned and Color3.fromRGB(100,100,100) or Color3.fromRGB(60,120,60),
            Text=owned and "Unlocked" or "Unlock", TextColor3=Color3.fromRGB(255,255,255),
            Font=Enum.Font.GothamBold, TextScaled=true, Parent=row}, {Corner(8)})
        if not owned then
            btn.MouseButton1Click:Connect(function() Remotes.UnlockWorld:FireServer(w.id) end)
        end
    end
end
PlayerData.Changed:Connect(renderWorlds)
if PlayerData.data then renderWorlds(PlayerData.data) end
worldsBtn.MouseButton1Click:Connect(function() worldScreen.Enabled = not worldScreen.Enabled end)

-- =============================================================
-- REBIRTH UI
-- =============================================================
local rbScreen, rbPanel = buildMenu("REBIRTH", 420, 260, Color3.fromRGB(255,100,200))
local rbInfo = New("TextLabel", {Position=UDim2.fromOffset(20,50), Size=UDim2.new(1,-40,0,110),
    BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.Gotham, TextScaled=true, TextWrapped=true, Text="...", Parent=rbPanel})
local rbBtn = New("TextButton", {AnchorPoint=Vector2.new(0.5,1), Position=UDim2.new(0.5,0,1,-16),
    Size=UDim2.fromOffset(220,40), BackgroundColor3=Color3.fromRGB(180,50,130),
    Text="Rebirth!", TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBold, TextScaled=true, Parent=rbPanel}, {Corner(8)})
rbBtn.MouseButton1Click:Connect(function() Remotes.Rebirth:FireServer() end)
local function renderRebirth(d)
    if not d then return end
    local cost = math.floor(Config.REBIRTH_BASE_COST * (Config.REBIRTH_COST_SCALE ^ (d.rebirths or 0)))
    local nextMul = Config.REBIRTH_MULTIPLIER ^ ((d.rebirths or 0) + 1)
    rbInfo.Text = string.format("Rebirths: %d\nCost: %s coins\nAfter rebirth: %sx multiplier (resets coins & worlds)",
        d.rebirths or 0, Util.FormatNumber(cost), Util.FormatNumber(nextMul))
end
PlayerData.Changed:Connect(renderRebirth)
if PlayerData.data then renderRebirth(PlayerData.data) end
rebirthBtn.MouseButton1Click:Connect(function() rbScreen.Enabled = not rbScreen.Enabled end)

-- =============================================================
-- SHOP UI
-- =============================================================
local shopScreen, shopPanel = buildMenu("SHOP - GAMEPASSES", 640, 480)
local shopList = New("ScrollingFrame", {Position=UDim2.fromOffset(10,50), Size=UDim2.new(1,-20,1,-60),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=6,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0), Parent=shopPanel},
    {ListLayout({Padding=UDim.new(0,6)})})

for _, g in ipairs(GamepassDatabase.List) do
    local row = New("Frame", {Size=UDim2.new(1,-8,0,70), BackgroundColor3=Color3.fromRGB(40,40,55), Parent=shopList}, {Corner(8)})
    New("TextLabel", {Position=UDim2.fromOffset(10,6), Size=UDim2.new(0.7,0,0,26),
        BackgroundTransparency=1, Text=g.name, TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextScaled=true, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
    New("TextLabel", {Position=UDim2.fromOffset(10,34), Size=UDim2.new(0.7,0,0,30),
        BackgroundTransparency=1, Text=g.description, TextColor3=Color3.fromRGB(220,220,220),
        Font=Enum.Font.Gotham, TextScaled=true, TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
    local btn = New("TextButton", {AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
        Size=UDim2.fromOffset(140,40), BackgroundColor3=Color3.fromRGB(60,120,60),
        Text=g.priceRobux.." R$", TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextScaled=true, Parent=row}, {Corner(8)})
    btn.MouseButton1Click:Connect(function()
        if g.id and g.id > 0 then MarketplaceService:PromptGamePassPurchase(LocalPlayer, g.id)
        else btn.Text = "Set ID in DB!" end
    end)
    PlayerData.Changed:Connect(function(d)
        if d and d.gamepasses and d.gamepasses[g.key] then
            btn.Text = "Owned"; btn.BackgroundColor3 = Color3.fromRGB(80,80,80); btn.AutoButtonColor = false
        end
    end)
end
shopBtn.MouseButton1Click:Connect(function() shopScreen.Enabled = not shopScreen.Enabled end)

-- =============================================================
-- ADMIN UI (server-gated)
-- =============================================================
local function buildAdminUI()
    local screen, panel = buildMenu("ADMIN PANEL", 820, 560, Color3.fromRGB(255,50,50))
    panel.BackgroundColor3 = Color3.fromRGB(15,5,5)

    local targetBox
    do
        New("TextLabel", {Position=UDim2.fromOffset(20,50), Size=UDim2.fromOffset(180,28),
            BackgroundTransparency=1, Text="Target (UserId or Username):",
            TextColor3=Color3.fromRGB(255,255,255), Font=Enum.Font.Gotham, TextScaled=true,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=panel})
        targetBox = New("TextBox", {Position=UDim2.fromOffset(210,50), Size=UDim2.fromOffset(220,28),
            BackgroundColor3=Color3.fromRGB(40,40,55), TextColor3=Color3.fromRGB(255,255,255),
            Text="", PlaceholderText="(blank = yourself)", Font=Enum.Font.Gotham, TextScaled=true,
            Parent=panel}, {Corner(6)})
    end
    local function targetUserId()
        local v = tonumber(targetBox.Text); if v then return v end
        if targetBox.Text ~= "" then return targetBox.Text end
        return nil
    end
    local function send(cmd) Remotes.AdminCommand:FireServer(cmd) end

    local content = New("ScrollingFrame", {Position=UDim2.fromOffset(10,90), Size=UDim2.new(1,-20,1,-100),
        BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=6,
        AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0), Parent=panel},
        {ListLayout({Padding=UDim.new(0,8)})})

    local function section(title, h)
        local f = New("Frame", {Size=UDim2.new(1,-10,0,h or 80),
            BackgroundColor3=Color3.fromRGB(30,15,15), Parent=content}, {Corner(10)})
        New("TextLabel", {Position=UDim2.fromOffset(10,4), Size=UDim2.new(1,-20,0,22),
            BackgroundTransparency=1, Text=title, TextColor3=Color3.fromRGB(255,150,150),
            Font=Enum.Font.GothamBold, TextScaled=true,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=f})
        return f
    end
    local function smallButton(parent, text, x, y, w, color, fn)
        local b = New("TextButton", {Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(w,30),
            BackgroundColor3=color, TextColor3=Color3.fromRGB(255,255,255),
            Font=Enum.Font.GothamBold, TextScaled=true, Text=text, Parent=parent}, {Corner(6)})
        b.MouseButton1Click:Connect(fn); return b
    end
    local function input(parent, x, y, w, ph, default)
        return New("TextBox", {Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(w,30),
            BackgroundColor3=Color3.fromRGB(40,40,55), TextColor3=Color3.fromRGB(255,255,255),
            Text=default or "", PlaceholderText=ph, Font=Enum.Font.Gotham, TextScaled=true,
            Parent=parent}, {Corner(6)})
    end

    -- Currency
    do
        local s = section("Currency", 110)
        local coinsIn = input(s, 10, 36, 140, "amount", "1000000")
        smallButton(s, "Give Coins", 160, 36, 100, Color3.fromRGB(60,120,60), function()
            send({action="giveCoins", target=targetUserId(), amount=tonumber(coinsIn.Text)})
        end)
        smallButton(s, "Set Coins", 270, 36, 100, Color3.fromRGB(120,90,40), function()
            send({action="setCoins", target=targetUserId(), amount=tonumber(coinsIn.Text)})
        end)
        local gemsIn = input(s, 10, 72, 140, "amount", "10000")
        smallButton(s, "Give Gems", 160, 72, 100, Color3.fromRGB(60,120,120), function()
            send({action="giveGems", target=targetUserId(), amount=tonumber(gemsIn.Text)})
        end)
        smallButton(s, "Set Gems", 270, 72, 100, Color3.fromRGB(40,90,120), function()
            send({action="setGems", target=targetUserId(), amount=tonumber(gemsIn.Text)})
        end)
    end
    -- Pets
    do
        local s = section("Give Pet", 130)
        local petIdBox = input(s, 10, 36, 220, "pet id", "meadow_dog")
        local tierBox = input(s, 240, 36, 120, "tier", "Standard")
        local mutBox  = input(s, 370, 36, 140, "mutation (optional)", "")
        smallButton(s, "Give Pet", 520, 36, 110, Color3.fromRGB(80,60,130), function()
            send({action="givePet", target=targetUserId(),
                petId=petIdBox.Text,
                tier=tierBox.Text~="" and tierBox.Text or nil,
                mutation=mutBox.Text~="" and mutBox.Text or nil})
        end)
        local x = 10
        for _, p in ipairs(PetDatabase.List) do
            if p.rarity == "Huge" then
                smallButton(s, "Huge: "..p.name, x, 76, 180, Color3.fromRGB(200,150,30), function()
                    send({action="givePet", target=targetUserId(), petId=p.id})
                end)
                x += 188
                if x > 600 then break end
            end
        end
    end
    -- Force Hatch
    do
        local s = section("Force Hatch", 80)
        local eggBox = input(s, 10, 36, 200, "egg id", "egg_meadow")
        local cntBox = input(s, 220, 36, 80, "count", "10")
        smallButton(s, "Force Hatch", 310, 36, 130, Color3.fromRGB(140,80,30), function()
            send({action="forceHatch", target=targetUserId(), eggId=eggBox.Text, count=tonumber(cntBox.Text)})
        end)
        local s2 = section("Eggs (click to force-hatch 1)", 80)
        local x = 10
        for _, egg in ipairs(EggDatabase.List) do
            smallButton(s2, egg.name, x, 36, 130, Color3.fromRGB(80,60,30), function()
                send({action="forceHatch", target=targetUserId(), eggId=egg.id, count=1})
            end)
            x += 138
            if x > 660 then break end
        end
    end
    -- Gamepasses
    do
        local s = section("Gamepasses (admin grant / revoke)", 110)
        local x, y = 10, 36
        for _, g in ipairs(GamepassDatabase.List) do
            smallButton(s, "Grant: "..g.key, x, y, 130, Color3.fromRGB(60,90,130), function()
                send({action="grantGamepass", target=targetUserId(), key=g.key})
            end)
            smallButton(s, "Revoke", x+134, y, 70, Color3.fromRGB(120,50,50), function()
                send({action="revokeGamepass", target=targetUserId(), key=g.key})
            end)
            x += 220
            if x > 600 then x = 10; y += 36 end
        end
    end
    -- Misc
    do
        local s = section("Misc", 110)
        local rbBox = input(s, 10, 36, 100, "rebirths", "10")
        smallButton(s, "Set Rebirths", 120, 36, 130, Color3.fromRGB(140,60,130), function()
            send({action="setRebirths", target=targetUserId(), amount=tonumber(rbBox.Text)})
        end)
        smallButton(s, "Unlock All Worlds", 260, 36, 160, Color3.fromRGB(60,130,130), function()
            send({action="unlockAllWorlds", target=targetUserId()})
        end)
        local annBox = input(s, 10, 72, 380, "announcement message", "")
        smallButton(s, "Announce", 400, 72, 110, Color3.fromRGB(180,80,50), function()
            send({action="announce", message=annBox.Text})
        end)
        smallButton(s, "Kick Target", 520, 72, 110, Color3.fromRGB(180,60,60), function()
            send({action="kick", target=targetUserId(), reason="Kicked by admin"})
        end)
    end
    return screen
end

local ok, isAdmin = pcall(function() return Remotes.IsAdmin:InvokeServer() end)
if ok and isAdmin then
    local adminScreen = buildAdminUI()
    local adminBtn = makeSideButton("Admin", "ADMIN", Color3.fromRGB(180,30,30))
    adminBtn.MouseButton1Click:Connect(function() adminScreen.Enabled = not adminScreen.Enabled end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.F4 then adminScreen.Enabled = not adminScreen.Enabled end
    end)
end

-- =============================================================
-- BREAKING (auto-attack closest breakable)
-- =============================================================
local HIT_INTERVAL = 0.15
local MAX_RANGE = 24
local lastBreakHit = 0
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastBreakHit < HIT_INTERVAL then return end
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
        lastBreakHit = now
        Remotes.RequestBreakHit:FireServer(best)
    end
end)

-- =============================================================
-- PET FOLLOW (visual orbit)
-- =============================================================
local rendered = {}
local function buildPetVisual(pet, def)
    local templateFolder = ReplicatedStorage:FindFirstChild("PetModels")
    if templateFolder then
        local t = templateFolder:FindFirstChild(pet.id)
        if t then return t:Clone() end
    end
    local r = Rarities.GetByName(def.rarity) or {color=Color3.new(1,1,1)}
    local model = Instance.new("Model")
    model.Name = "ClientPet_" .. pet.uid
    local part = Instance.new("Part")
    part.Size = pet.tier == "Standard" and Vector3.new(2,2,2) or Vector3.new(2.5,2.5,2.5)
    if def.rarity == "Huge" then part.Size = Vector3.new(8,8,8) end
    part.Color = r.color; part.Material = Enum.Material.Neon
    part.Anchored = true; part.CanCollide = false; part.Massless = true
    part.Parent = model; model.PrimaryPart = part
    return model
end

PlayerData.Changed:Connect(function(d)
    if not d then return end
    local equippedById = {}
    for _, p in ipairs(d.pets or {}) do if p.equipped then equippedById[p.uid] = p end end
    for uid, m in pairs(rendered) do
        if not equippedById[uid] then m:Destroy(); rendered[uid] = nil end
    end
    for uid, p in pairs(equippedById) do
        if not rendered[uid] then
            local def = PetDatabase.GetById(p.id)
            if def then
                local model = buildPetVisual(p, def)
                model.Parent = Workspace
                rendered[uid] = model
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local count = 0
    for _ in pairs(rendered) do count += 1 end
    if count == 0 then return end
    local now = tick()
    local i = 0
    for _, model in pairs(rendered) do
        i += 1
        local angle = (i / count) * math.pi * 2 + now * 0.5
        local r = 5
        local pos = hrp.Position + Vector3.new(math.cos(angle) * r, 1, math.sin(angle) * r)
        if model.PrimaryPart then model:PivotTo(CFrame.new(pos)) end
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    for _, m in pairs(rendered) do m:Destroy() end
    rendered = {}
end)

print("[PetLegendsX] Client booted.")

-- =============================================================
-- TELEPORTER & EGG VENDOR INTERACTION
-- =============================================================
local TELEPORT_COOLDOWN = 3
local lastTeleport = 0
local lastVendorHatch = 0
local VENDOR_HATCH_COOLDOWN = 0.6

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local now = os.clock()

    local worldsFolder = Workspace:FindFirstChild("PetLegendsX_Worlds")
    if not worldsFolder then return end

    -- Quick check using simple distance to pads
    for _, worldModel in ipairs(worldsFolder:GetChildren()) do
        for _, child in ipairs(worldModel:GetChildren()) do
            if child:IsA("BasePart") then
                if string.sub(child.Name, 1, 9) == "Teleport_" then
                    if now - lastTeleport > TELEPORT_COOLDOWN then
                        if (child.Position - hrp.Position).Magnitude < 6 then
                            local target = child:FindFirstChild("TargetWorld")
                            if target then
                                lastTeleport = now
                                Remotes.TeleportToWorld:FireServer(target.Value)
                            end
                        end
                    end
                elseif string.sub(child.Name, 1, 11) == "EggVendor_" then
                    if now - lastVendorHatch > VENDOR_HATCH_COOLDOWN then
                        if (child.Position - hrp.Position).Magnitude < 6 then
                            local eggIdVal = child:FindFirstChild("EggId")
                            if eggIdVal then
                                lastVendorHatch = now
                                Remotes.HatchEgg:FireServer(eggIdVal.Value, 1)
                            end
                        end
                    end
                end
            end
        end
    end
end)
