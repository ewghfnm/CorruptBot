--[[
    AdminUI.lua
    Visible only to admins (Remotes.IsAdmin returns true).
    Provides buttons + text inputs for every admin action.

    All actions are sent via Remotes.AdminCommand. The server validates the sender
    against Config.ADMIN_USER_IDS / ADMIN_USERNAMES; clients cannot escalate.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local PetDatabase = require(Shared.PetDatabase)
local EggDatabase = require(Shared.EggDatabase)
local GamepassDatabase = require(Shared.GamepassDatabase)
local Rarities = require(Shared.Rarities)

local script = script
local UIBuilder = require(script.Parent.UIBuilder)

local LocalPlayer = Players.LocalPlayer

local AdminUI = {}

local function send(cmd)
    Remotes.AdminCommand:FireServer(cmd)
end

local function targetUserId(textbox)
    -- Accepts numeric UserId or empty (defaults to self)
    local v = tonumber(textbox.Text)
    if v then return v end
    if textbox.Text ~= "" then return textbox.Text end -- send as username, server resolves
    return nil
end

function AdminUI:Build()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local screen = UIBuilder.New("ScreenGui", {
        Name = "AdminUI", ResetOnSpawn = false, Enabled = false, Parent = pg,
    })
    local panel = UIBuilder.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(820, 560),
        BackgroundColor3 = Color3.fromRGB(15, 5, 5),
        Parent = screen,
    }, {UIBuilder.Corner(14), UIBuilder.Stroke(Color3.fromRGB(255, 50, 50), 3)})

    UIBuilder.New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1, Text = "ADMIN PANEL",
        TextColor3 = Color3.fromRGB(255, 80, 80),
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

    -- ===== Target picker =====
    local targetBox
    do
        UIBuilder.New("TextLabel", {
            Position = UDim2.fromOffset(20, 50),
            Size = UDim2.fromOffset(180, 28),
            BackgroundTransparency = 1, Text = "Target (UserId or Username):",
            TextColor3 = Color3.fromRGB(255,255,255),
            Font = Enum.Font.Gotham, TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
        })
        targetBox = UIBuilder.New("TextBox", {
            Position = UDim2.fromOffset(210, 50),
            Size = UDim2.fromOffset(220, 28),
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            TextColor3 = Color3.fromRGB(255,255,255),
            Text = "", PlaceholderText = "(blank = yourself)",
            Font = Enum.Font.Gotham, TextScaled = true, Parent = panel,
        }, {UIBuilder.Corner(6)})
    end

    local content = UIBuilder.New("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 90),
        Size = UDim2.new(1, -20, 1, -100),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0),
        Parent = panel,
    }, {UIBuilder.ListLayout({Padding = UDim.new(0, 8)})})

    local function section(title)
        local f = UIBuilder.New("Frame", {
            Size = UDim2.new(1, -10, 0, 80),
            BackgroundColor3 = Color3.fromRGB(30, 15, 15),
            Parent = content,
        }, {UIBuilder.Corner(10)})
        UIBuilder.New("TextLabel", {
            Position = UDim2.fromOffset(10, 4),
            Size = UDim2.new(1, -20, 0, 22),
            BackgroundTransparency = 1, Text = title,
            TextColor3 = Color3.fromRGB(255, 150, 150),
            Font = Enum.Font.GothamBold, TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
        })
        return f
    end

    local function smallButton(parent, text, x, y, w, color, fn)
        local b = UIBuilder.New("TextButton", {
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, 30),
            BackgroundColor3 = color,
            TextColor3 = Color3.fromRGB(255,255,255),
            Font = Enum.Font.GothamBold, TextScaled = true, Text = text,
            Parent = parent,
        }, {UIBuilder.Corner(6)})
        b.MouseButton1Click:Connect(fn)
        return b
    end
    local function input(parent, x, y, w, ph, default)
        local t = UIBuilder.New("TextBox", {
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, 30),
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            TextColor3 = Color3.fromRGB(255,255,255),
            Text = default or "", PlaceholderText = ph,
            Font = Enum.Font.Gotham, TextScaled = true, Parent = parent,
        }, {UIBuilder.Corner(6)})
        return t
    end

    -- ===== Currency section =====
    do
        local s = section("Currency")
        s.Size = UDim2.new(1, -10, 0, 110)
        local coinsIn = input(s, 10, 36, 140, "amount", "1000000")
        smallButton(s, "Give Coins", 160, 36, 100, Color3.fromRGB(60,120,60), function()
            send({action="giveCoins", target=targetUserId(targetBox), amount=tonumber(coinsIn.Text)})
        end)
        smallButton(s, "Set Coins", 270, 36, 100, Color3.fromRGB(120,90,40), function()
            send({action="setCoins", target=targetUserId(targetBox), amount=tonumber(coinsIn.Text)})
        end)
        local gemsIn = input(s, 10, 72, 140, "amount", "10000")
        smallButton(s, "Give Gems", 160, 72, 100, Color3.fromRGB(60,120,120), function()
            send({action="giveGems", target=targetUserId(targetBox), amount=tonumber(gemsIn.Text)})
        end)
        smallButton(s, "Set Gems", 270, 72, 100, Color3.fromRGB(40,90,120), function()
            send({action="setGems", target=targetUserId(targetBox), amount=tonumber(gemsIn.Text)})
        end)
    end

    -- ===== Pets section =====
    do
        local s = section("Give Pet")
        s.Size = UDim2.new(1, -10, 0, 130)
        -- Pet id dropdown approximation: textbox preloaded with a list label
        local petIdBox = input(s, 10, 36, 220, "pet id", "meadow_dog")
        local tierBox = input(s, 240, 36, 120, "tier", "Standard")
        local mutBox  = input(s, 370, 36, 140, "mutation (optional)", "")
        smallButton(s, "Give Pet", 520, 36, 110, Color3.fromRGB(80, 60, 130), function()
            send({
                action="givePet", target=targetUserId(targetBox),
                petId=petIdBox.Text, tier=tierBox.Text ~= "" and tierBox.Text or nil,
                mutation=mutBox.Text ~= "" and mutBox.Text or nil,
            })
        end)
        -- Quick give Huge buttons
        local x = 10
        for _, p in ipairs(PetDatabase.List) do
            if p.rarity == "Huge" then
                smallButton(s, "Huge: " .. p.name, x, 76, 180, Color3.fromRGB(200, 150, 30), function()
                    send({action="givePet", target=targetUserId(targetBox), petId=p.id})
                end)
                x += 188
                if x > 600 then break end
            end
        end
    end

    -- ===== Force Hatch section =====
    do
        local s = section("Force Hatch")
        s.Size = UDim2.new(1, -10, 0, 80)
        local eggBox = input(s, 10, 36, 200, "egg id", "egg_meadow")
        local cntBox = input(s, 220, 36, 80, "count", "10")
        smallButton(s, "Force Hatch", 310, 36, 130, Color3.fromRGB(140, 80, 30), function()
            send({action="forceHatch", target=targetUserId(targetBox), eggId=eggBox.Text, count=tonumber(cntBox.Text)})
        end)
        -- Also list available eggs as quick buttons
        local x = 10
        local s2 = section("Eggs (click to force-hatch 1)")
        s2.Size = UDim2.new(1, -10, 0, 80)
        for _, egg in ipairs(EggDatabase.List) do
            smallButton(s2, egg.name, x, 36, 130, Color3.fromRGB(80, 60, 30), function()
                send({action="forceHatch", target=targetUserId(targetBox), eggId=egg.id, count=1})
            end)
            x += 138
            if x > 660 then break end
        end
    end

    -- ===== Gamepasses =====
    do
        local s = section("Gamepasses (admin grant / revoke)")
        s.Size = UDim2.new(1, -10, 0, 110)
        local x, y = 10, 36
        for _, g in ipairs(GamepassDatabase.List) do
            smallButton(s, "Grant: " .. g.key, x, y, 130, Color3.fromRGB(60, 90, 130), function()
                send({action="grantGamepass", target=targetUserId(targetBox), key=g.key})
            end)
            smallButton(s, "Revoke", x + 134, y, 70, Color3.fromRGB(120, 50, 50), function()
                send({action="revokeGamepass", target=targetUserId(targetBox), key=g.key})
            end)
            x += 220
            if x > 600 then x = 10; y += 36 end
        end
    end

    -- ===== Misc =====
    do
        local s = section("Misc")
        s.Size = UDim2.new(1, -10, 0, 110)
        local rbBox = input(s, 10, 36, 100, "rebirths", "10")
        smallButton(s, "Set Rebirths", 120, 36, 130, Color3.fromRGB(140, 60, 130), function()
            send({action="setRebirths", target=targetUserId(targetBox), amount=tonumber(rbBox.Text)})
        end)
        smallButton(s, "Unlock All Worlds", 260, 36, 160, Color3.fromRGB(60, 130, 130), function()
            send({action="unlockAllWorlds", target=targetUserId(targetBox)})
        end)
        local annBox = input(s, 10, 72, 380, "announcement message", "")
        smallButton(s, "Announce", 400, 72, 110, Color3.fromRGB(180, 80, 50), function()
            send({action="announce", message=annBox.Text})
        end)
        smallButton(s, "Kick Target", 520, 72, 110, Color3.fromRGB(180, 60, 60), function()
            send({action="kick", target=targetUserId(targetBox), reason="Kicked by admin"})
        end)
    end

    self.Screen = screen
    return self
end

function AdminUI:Toggle() self.Screen.Enabled = not self.Screen.Enabled end

return AdminUI
