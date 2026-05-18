--[[
============================================================
   PET LEGENDS X - SERVER SCRIPT
   Place: ServerScriptService
   Type:  Script  (regular Script, NOT a ModuleScript)
   Name:  anything you like (e.g. "PetLegendsX_Server")
============================================================

   This is the entire server. It requires the shared module
   from ReplicatedStorage and runs every game system:
   data saving, pets, eggs, breakables, currency, rebirth,
   gamepasses, and the admin command handler.

   Make sure ReplicatedStorage has a ModuleScript named:
     PetLegendsX_Shared
   ...containing the Shared file's contents.
]]

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
local EnchantDatabase = Shared.EnchantDatabase

-- =============================================================
-- DATA SERVICE
-- =============================================================
local store = DataStoreService:GetDataStore(Config.DATASTORE_NAME)

local DataService = {
    PlayerData = {},
    DataLoaded = Signal.new(),
    DataChanged = Signal.new(),
}

local function defaultData()
    return {
        coins = Config.STARTING_COINS,
        gems = Config.STARTING_GEMS,
        rebirths = 0,
        unlockedWorlds = {Meadow = true},
        currentWorld = "Meadow",
        pets = {},
        stats = {pity_legendary = 0, pity_mythical = 0, totalHatches = 0},
        boosts = {},
        gamepasses = {},
        autoHatchEgg = nil,
        equippedSlots = Config.MAX_EQUIPPED_PETS_DEFAULT,
    }
end

function DataService:Get(player) return self.PlayerData[player.UserId] end

function DataService:MarkDirty(player)
    local d = self.PlayerData[player.UserId]
    if d then self.DataChanged:Fire(player, d) end
end

function DataService:_load(player)
    local key = "u_" .. player.UserId
    local ok, raw = pcall(function() return store:GetAsync(key) end)
    if not ok then warn("[DataService] Load failed: " .. tostring(raw)); raw = nil end
    local data = raw or defaultData()
    local def = defaultData()
    for k, v in pairs(def) do if data[k] == nil then data[k] = v end end
    if not data.stats then data.stats = def.stats end
    self.PlayerData[player.UserId] = data
    self.DataLoaded:Fire(player, data)
end

function DataService:_save(player)
    local data = self.PlayerData[player.UserId]
    if not data then return end
    local key = "u_" .. player.UserId
    local ok, err = pcall(function() store:SetAsync(key, data) end)
    if not ok then warn("[DataService] Save failed: " .. tostring(err)) end
end

function DataService:Init()
    Players.PlayerAdded:Connect(function(plr) self:_load(plr) end)
    for _, plr in ipairs(Players:GetPlayers()) do task.spawn(function() self:_load(plr) end) end

    Players.PlayerRemoving:Connect(function(plr)
        self:_save(plr)
        self.PlayerData[plr.UserId] = nil
    end)

    task.spawn(function()
        while true do
            task.wait(Config.AUTOSAVE_INTERVAL)
            for _, plr in ipairs(Players:GetPlayers()) do self:_save(plr) end
        end
    end)

    game:BindToClose(function()
        if RunService:IsStudio() then return end
        for _, plr in ipairs(Players:GetPlayers()) do self:_save(plr) end
        task.wait(2)
    end)
end

-- =============================================================
-- CURRENCY SERVICE
-- =============================================================
local CurrencyService = {}
local VALID_CUR = {coins = true, gems = true}

function CurrencyService:Get(player, currency)
    local d = DataService:Get(player); if not d then return 0 end
    return d[currency] or 0
end
function CurrencyService:Add(player, currency, amount)
    if not VALID_CUR[currency] or not amount or amount < 0 then return false end
    local d = DataService:Get(player); if not d then return false end
    d[currency] = (d[currency] or 0) + amount
    DataService:MarkDirty(player); return true
end
function CurrencyService:Spend(player, currency, amount)
    if not VALID_CUR[currency] or not amount or amount < 0 then return false end
    local d = DataService:Get(player); if not d then return false end
    if (d[currency] or 0) < amount then return false end
    d[currency] -= amount
    DataService:MarkDirty(player); return true
end
function CurrencyService:Set(player, currency, amount)
    if not VALID_CUR[currency] then return false end
    local d = DataService:Get(player); if not d then return false end
    d[currency] = math.max(0, amount)
    DataService:MarkDirty(player); return true
end

-- =============================================================
-- PET SERVICE
-- =============================================================
local TIER_MULTIPLIERS = {Standard=1, Golden=2, Rainbow=5, DarkMatter=10}
local PetService = {}

local function findPetIndex(data, uid)
    for i, p in ipairs(data.pets) do
        if p.uid == uid then return i, p end
    end
end

function PetService:GivePet(player, petId, opts)
    opts = opts or {}
    local def = PetDatabase.GetById(petId); if not def then return nil end
    local d = DataService:Get(player); if not d then return nil end
    local pet = {
        uid = Util.NewGuid(), id = petId, level = 1, xp = 0,
        tier = opts.tier or "Standard", mutation = opts.mutation,
        locked = false, favorite = false, equipped = false, enchants = {},
    }
    table.insert(d.pets, pet)
    DataService:MarkDirty(player)
    return pet
end

function PetService:RemovePet(player, uid)
    local d = DataService:Get(player); if not d then return false end
    local i, p = findPetIndex(d, uid)
    if not i or p.locked then return false end
    table.remove(d.pets, i); DataService:MarkDirty(player); return true
end

function PetService:LockPet(player, uid, locked)
    local d = DataService:Get(player); if not d then return false end
    local _, p = findPetIndex(d, uid); if not p then return false end
    p.locked = locked and true or false
    DataService:MarkDirty(player); return true
end

function PetService:GetEquippedCount(data)
    local n = 0
    for _, p in ipairs(data.pets) do if p.equipped then n += 1 end end
    return n
end

function PetService:EquipPet(player, uid)
    local d = DataService:Get(player); if not d then return false end
    local _, pet = findPetIndex(d, uid); if not pet then return false end
    if pet.equipped then return true end
    local maxSlots = d.equippedSlots or Config.MAX_EQUIPPED_PETS_DEFAULT
    if self:GetEquippedCount(d) >= maxSlots then return false end
    pet.equipped = true; DataService:MarkDirty(player); return true
end

function PetService:UnequipPet(player, uid)
    local d = DataService:Get(player); if not d then return false end
    local _, pet = findPetIndex(d, uid); if not pet then return false end
    pet.equipped = false; DataService:MarkDirty(player); return true
end

local function petStats(pet)
    local def = PetDatabase.GetById(pet.id); if not def then return 0, 0 end
    local tierMul = TIER_MULTIPLIERS[pet.tier] or 1
    local levelMul = 1 + (pet.level - 1) * 0.05
    local damage = def.damage * tierMul * levelMul
    local coinMul = def.coinMultiplier * tierMul
    for _, ench in ipairs(pet.enchants or {}) do
        local edef = EnchantDatabase.GetById(ench.id); if edef then
            local bonus = edef.perTier * (ench.tier or 1)
            if edef.stat == "damage" then damage *= (1 + bonus)
            elseif edef.stat == "coinMultiplier" then coinMul *= (1 + bonus) end
        end
    end
    return damage, coinMul
end

function PetService:ComputePlayerStats(player)
    local d = DataService:Get(player); if not d then return {damage=1, coinMul=1} end
    local td, tc = 0, 0
    for _, p in ipairs(d.pets) do
        if p.equipped then local dmg, cm = petStats(p); td += dmg; tc += cm end
    end
    if td == 0 then td = 1 end
    if tc == 0 then tc = 1 end
    local rb = Config.REBIRTH_MULTIPLIER ^ (d.rebirths or 0)
    return {damage = td * rb, coinMul = tc * rb}
end

function PetService:AddXP(player, amount)
    local d = DataService:Get(player); if not d then return end
    local changed = false
    for _, p in ipairs(d.pets) do
        if p.equipped and p.level < Config.MAX_PET_LEVEL then
            p.xp = (p.xp or 0) + amount
            local need = Config.PET_XP_PER_LEVEL(p.level)
            while p.xp >= need and p.level < Config.MAX_PET_LEVEL do
                p.xp -= need; p.level += 1
                need = Config.PET_XP_PER_LEVEL(p.level); changed = true
            end
        end
    end
    if changed then DataService:MarkDirty(player) end
end

-- =============================================================
-- ANNOUNCEMENT SERVICE
-- =============================================================
local AnnouncementService = {}
function AnnouncementService:Broadcast(message)
    for _, plr in ipairs(Players:GetPlayers()) do
        Remotes.ServerAnnounce:FireClient(plr, message)
    end
end

-- =============================================================
-- GAMEPASS SERVICE
-- =============================================================
local GamepassService = {}

function GamepassService:_refresh(plr)
    local d = DataService:Get(plr); if not d then
        task.delay(2, function() self:_refresh(plr) end); return
    end
    d.gamepasses = d.gamepasses or {}
    for _, g in ipairs(GamepassDatabase.List) do
        if g.id and g.id > 0 then
            local ok, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, g.id)
            end)
            if ok and owns then d.gamepasses[g.key] = true end
        end
    end
    if d.gamepasses.ExtraEquip then d.equippedSlots = Config.MAX_EQUIPPED_PETS_GAMEPASS end
    if d.gamepasses.FasterWalk and plr.Character then
        local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = 24 end
    end
    DataService:MarkDirty(plr)
end

function GamepassService:Owns(plr, key)
    local d = DataService:Get(plr); if not d then return false end
    return (d.gamepasses or {})[key] == true
end

function GamepassService:Grant(plr, key)
    local g = GamepassDatabase.GetByKey(key); if not g then return false end
    local d = DataService:Get(plr); if not d then return false end
    d.gamepasses[key] = true
    if key == "ExtraEquip" then d.equippedSlots = Config.MAX_EQUIPPED_PETS_GAMEPASS end
    DataService:MarkDirty(plr); return true
end

function GamepassService:Revoke(plr, key)
    local d = DataService:Get(plr); if not d then return false end
    d.gamepasses[key] = nil
    if key == "ExtraEquip" then d.equippedSlots = Config.MAX_EQUIPPED_PETS_DEFAULT end
    DataService:MarkDirty(plr); return true
end

function GamepassService:Init()
    Players.PlayerAdded:Connect(function(plr) self:_refresh(plr) end)
    for _, plr in ipairs(Players:GetPlayers()) do task.spawn(function() self:_refresh(plr) end) end
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, _, purchased)
        if purchased then self:_refresh(plr) end
    end)
end

-- =============================================================
-- EGG SERVICE
-- =============================================================
local EggService = {}

function EggService:_luckMultiplier(player)
    local m = 1
    if GamepassService:Owns(player, "SuperLucky") then m += 0.5 end
    if GamepassService:Owns(player, "UltraLucky") then m += 1.5 end
    return m
end

function EggService:_rollMutation()
    if math.random() > 0.01 then return nil end
    local opts = {"shiny","glowing","corrupted","celestial","void","infernal"}
    return opts[math.random(1, #opts)]
end

function EggService:_rollTier()
    local r = math.random()
    if r < 0.0005 then return "DarkMatter"
    elseif r < 0.004 then return "Rainbow"
    elseif r < 0.024 then return "Golden"
    else return "Standard" end
end

function EggService:_pickPet(egg, data, luck)
    local hugeChance = (egg.hugeChance or 0) * luck
    if hugeChance > 0 and math.random() < hugeChance then
        local pool = egg.hugePool or {}
        if #pool > 0 then return pool[math.random(1, #pool)], true end
    end
    local stats = data.stats
    local guaranteed
    if stats.pity_mythical >= Config.PITY_MYTHICAL_AFTER then guaranteed = "Mythical"
    elseif stats.pity_legendary >= Config.PITY_LEGENDARY_AFTER then guaranteed = "Legendary" end
    local pool = egg.pets
    if guaranteed then
        local filtered = {}
        for _, e in ipairs(pool) do
            local def = PetDatabase.GetById(e.id)
            if def and Rarities.IsAtLeast(def.rarity, guaranteed) then table.insert(filtered, e) end
        end
        if #filtered > 0 then pool = filtered end
    end
    return Util.WeightedPick(pool, luck), false
end

function EggService:HandleHatchRequest(player, eggId, count)
    local egg = EggDatabase.GetById(eggId); if not egg then return end
    count = math.clamp(tonumber(count) or 1, 1, 8)
    if count > 1 and not GamepassService:Owns(player, "TripleHatch") then count = 1 end
    if count > 3 then count = 3 end

    local d = DataService:Get(player); if not d then return end
    if egg.world and not d.unlockedWorlds[egg.world] then
        Remotes.Notification:FireClient(player, "World " .. egg.world .. " is locked.")
        return
    end
    local totalCost = egg.cost * count
    if not CurrencyService:Spend(player, egg.currency, totalCost) then
        Remotes.Notification:FireClient(player, "Not enough " .. egg.currency .. ".")
        return
    end

    local results = {}
    local luck = self:_luckMultiplier(player)
    for i = 1, count do
        local petId, isHuge = self:_pickPet(egg, d, luck)
        local def = PetDatabase.GetById(petId)
        if def then
            local tier = isHuge and "Standard" or self:_rollTier()
            local mutation = self:_rollMutation()
            local pet = PetService:GivePet(player, petId, {tier=tier, mutation=mutation})
            d.stats.totalHatches += 1
            if Rarities.IsAtLeast(def.rarity, "Mythical") then d.stats.pity_mythical = 0
            else d.stats.pity_mythical += 1 end
            if Rarities.IsAtLeast(def.rarity, "Legendary") then d.stats.pity_legendary = 0
            else d.stats.pity_legendary += 1 end
            table.insert(results, {
                uid=pet.uid, id=petId, name=def.name, rarity=def.rarity,
                tier=tier, mutation=mutation, isHuge=isHuge,
            })
            local rIdx = (Rarities.GetByName(def.rarity) or {}).index or 0
            if isHuge or rIdx >= Config.ANNOUNCE_RARITY_INDEX then
                AnnouncementService:Broadcast(string.format(
                    "%s just hatched a %s%s %s!",
                    player.DisplayName,
                    tier ~= "Standard" and (tier .. " ") or "",
                    def.rarity, def.name
                ))
            end
        end
    end
    DataService:MarkDirty(player)
    Remotes.HatchResult:FireClient(player, eggId, results)
end

function EggService:Init()
    Remotes.HatchEgg.OnServerEvent:Connect(function(plr, eggId, count) self:HandleHatchRequest(plr, eggId, count) end)
    Remotes.SetAutoHatch.OnServerEvent:Connect(function(plr, eggId)
        local d = DataService:Get(plr); if not d then return end
        if eggId == nil or EggDatabase.GetById(eggId) then
            d.autoHatchEgg = eggId; DataService:MarkDirty(plr)
        end
    end)
    task.spawn(function()
        while true do
            task.wait(Config.AUTO_HATCH_INTERVAL)
            for _, plr in ipairs(Players:GetPlayers()) do
                local d = DataService:Get(plr)
                if d and d.autoHatchEgg and GamepassService:Owns(plr, "AutoHatch") then
                    self:HandleHatchRequest(plr, d.autoHatchEgg, 1)
                end
            end
        end
    end)
end

-- =============================================================
-- BREAKING SERVICE
-- =============================================================
local BreakingService = {}
local BREAK_COOLDOWN = 0.10
local lastHit = setmetatable({}, {__mode="k"})

local function ensureFolder(name, parent)
    local f = parent:FindFirstChild(name)
    if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = parent end
    return f
end

local function makeBreakable(world, position)
    local model = Instance.new("Model")
    model.Name = "Breakable"
    local part = Instance.new("Part")
    part.Name = "Hitbox"; part.Size = Vector3.new(6,6,6); part.Position = position
    part.Anchored = true; part.BrickColor = BrickColor.new("Bright orange")
    part.Material = Enum.Material.Wood; part.Parent = model
    model.PrimaryPart = part
    local hpVal = Instance.new("NumberValue"); hpVal.Name = "HP"
    local wDef = WorldDatabase.GetById(world)
    hpVal.Value = 100 * (wDef and wDef.coinMultiplier or 1); hpVal.Parent = model
    local maxHpVal = Instance.new("NumberValue"); maxHpVal.Name = "MaxHP"
    maxHpVal.Value = hpVal.Value; maxHpVal.Parent = model
    local worldVal = Instance.new("StringValue"); worldVal.Name = "World"
    worldVal.Value = world; worldVal.Parent = model
    return model
end

function BreakingService:HandleHit(player, breakable)
    if typeof(breakable) ~= "Instance" or not breakable:IsA("Model") then return end
    if not breakable:IsDescendantOf(Workspace) then return end
    local hp = breakable:FindFirstChild("HP")
    local worldVal = breakable:FindFirstChild("World")
    if not hp or not worldVal then return end
    local char = player.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hitbox = breakable:FindFirstChild("Hitbox") or breakable.PrimaryPart
    if not hitbox or (hrp.Position - hitbox.Position).Magnitude > 25 then return end
    local now = os.clock()
    if (lastHit[player] or 0) + BREAK_COOLDOWN > now then return end
    lastHit[player] = now
    local d = DataService:Get(player); if not d then return end
    if not d.unlockedWorlds[worldVal.Value] then return end
    local stats = PetService:ComputePlayerStats(player)
    hp.Value -= stats.damage
    if hp.Value <= 0 then
        local wDef = WorldDatabase.GetById(worldVal.Value)
        local coinReward = math.floor(10 * (wDef and wDef.coinMultiplier or 1) * stats.coinMul)
        CurrencyService:Add(player, "coins", coinReward)
        if math.random() < 0.01 then CurrencyService:Add(player, "gems", 1) end
        PetService:AddXP(player, math.floor(5 * (wDef and wDef.coinMultiplier or 1)))
        breakable:Destroy()
    end
end

function BreakingService:Init()
    local rootFolder = ensureFolder("Breakables", Workspace)
    for _, world in ipairs(WorldDatabase.List) do
        local wf = ensureFolder(world.id, rootFolder)
        if #wf:GetChildren() == 0 then
            for j = 1, 6 do
                local pos = Vector3.new((world.order - 1) * 200 + j * 10 - 30, 5, 0)
                local b = makeBreakable(world.id, pos); b.Parent = wf
            end
        end
    end
    Remotes.RequestBreakHit.OnServerEvent:Connect(function(plr, breakable) self:HandleHit(plr, breakable) end)
    task.spawn(function()
        while true do
            task.wait(2)
            for _, world in ipairs(WorldDatabase.List) do
                local wf = rootFolder:FindFirstChild(world.id)
                if wf and #wf:GetChildren() < 6 then
                    for j = 1, 6 - #wf:GetChildren() do
                        local pos = Vector3.new(
                            (world.order - 1) * 200 + j * 10 - 30 + math.random(-3, 3),
                            5, math.random(-10, 10)
                        )
                        local b = makeBreakable(world.id, pos); b.Parent = wf
                    end
                end
            end
        end
    end)
end

-- =============================================================
-- REBIRTH SERVICE
-- =============================================================
local RebirthService = {}

function RebirthService:GetRebirthCost(rebirths)
    return math.floor(Config.REBIRTH_BASE_COST * (Config.REBIRTH_COST_SCALE ^ rebirths))
end

function RebirthService:HandleRebirth(player)
    local d = DataService:Get(player); if not d then return end
    local cost = self:GetRebirthCost(d.rebirths)
    if (d.coins or 0) < cost then
        Remotes.Notification:FireClient(player, "You need " .. cost .. " coins to rebirth.")
        return
    end
    d.coins = 0; d.rebirths += 1
    d.unlockedWorlds = {Meadow = true}; d.currentWorld = "Meadow"
    DataService:MarkDirty(player)
    Remotes.Notification:FireClient(player, "Rebirth! You are now rebirth " .. d.rebirths .. ".")
end

function RebirthService:HandleUnlockWorld(player, worldId)
    local d = DataService:Get(player); if not d then return end
    local w = WorldDatabase.GetById(worldId); if not w then return end
    if d.unlockedWorlds[worldId] then return end
    if (d.rebirths or 0) < (w.rebirthRequired or 0) then
        Remotes.Notification:FireClient(player, "Need " .. w.rebirthRequired .. " rebirths."); return
    end
    if (d.coins or 0) < (w.unlockCost or 0) then
        Remotes.Notification:FireClient(player, "Not enough coins."); return
    end
    if w.unlockCost > 0 then
        if not CurrencyService:Spend(player, "coins", w.unlockCost) then return end
    end
    d.unlockedWorlds[worldId] = true; d.currentWorld = worldId
    DataService:MarkDirty(player)
    Remotes.Notification:FireClient(player, "Unlocked " .. w.name .. "!")
end

function RebirthService:Init()
    Remotes.Rebirth.OnServerEvent:Connect(function(plr) self:HandleRebirth(plr) end)
    Remotes.UnlockWorld.OnServerEvent:Connect(function(plr, worldId) self:HandleUnlockWorld(plr, worldId) end)
end

-- =============================================================
-- ADMIN SERVICE
-- =============================================================
local AdminService = {}

local function isAdmin(player)
    for _, id in ipairs(Config.ADMIN_USER_IDS) do
        if player.UserId == id then return true end
    end
    local lname = string.lower(player.Name)
    for _, name in ipairs(Config.ADMIN_USERNAMES) do
        if string.lower(name) == lname then return true end
    end
    return false
end

local function findPlayer(idOrName)
    if type(idOrName) == "number" then return Players:GetPlayerByUserId(idOrName) end
    local lname = string.lower(tostring(idOrName))
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.lower(plr.Name) == lname then return plr end
    end
end

function AdminService:Handle(adminPlr, cmd)
    local target = cmd.target and findPlayer(cmd.target) or adminPlr
    local function notify(msg) Remotes.Notification:FireClient(adminPlr, "[Admin] " .. msg) end

    if cmd.action == "givePet" then
        if not target then return notify("Target not found.") end
        local def = PetDatabase.GetById(cmd.petId)
        if not def then return notify("Unknown pet id: " .. tostring(cmd.petId)) end
        PetService:GivePet(target, cmd.petId, {tier=cmd.tier or "Standard", mutation=cmd.mutation})
        notify("Gave " .. def.name .. " to " .. target.Name)
    elseif cmd.action == "giveCoins" then
        if not target then return notify("Target not found.") end
        CurrencyService:Add(target, "coins", tonumber(cmd.amount) or 0)
        notify("Gave " .. tostring(cmd.amount) .. " coins to " .. target.Name)
    elseif cmd.action == "giveGems" then
        if not target then return notify("Target not found.") end
        CurrencyService:Add(target, "gems", tonumber(cmd.amount) or 0)
        notify("Gave " .. tostring(cmd.amount) .. " gems to " .. target.Name)
    elseif cmd.action == "setCoins" then
        if not target then return notify("Target not found.") end
        CurrencyService:Set(target, "coins", tonumber(cmd.amount) or 0)
        notify("Set coins=" .. tostring(cmd.amount) .. " on " .. target.Name)
    elseif cmd.action == "setGems" then
        if not target then return notify("Target not found.") end
        CurrencyService:Set(target, "gems", tonumber(cmd.amount) or 0)
        notify("Set gems=" .. tostring(cmd.amount) .. " on " .. target.Name)
    elseif cmd.action == "grantGamepass" then
        if not target then return notify("Target not found.") end
        if GamepassService:Grant(target, cmd.key) then
            notify("Granted gamepass " .. tostring(cmd.key) .. " to " .. target.Name)
        else notify("Unknown gamepass key: " .. tostring(cmd.key)) end
    elseif cmd.action == "revokeGamepass" then
        if not target then return notify("Target not found.") end
        GamepassService:Revoke(target, cmd.key)
        notify("Revoked gamepass " .. tostring(cmd.key) .. " from " .. target.Name)
    elseif cmd.action == "setRebirths" then
        if not target then return notify("Target not found.") end
        local d = DataService:Get(target); if not d then return end
        d.rebirths = math.max(0, tonumber(cmd.amount) or 0)
        DataService:MarkDirty(target)
        notify("Set rebirths=" .. d.rebirths .. " on " .. target.Name)
    elseif cmd.action == "unlockAllWorlds" then
        if not target then return notify("Target not found.") end
        local d = DataService:Get(target); if not d then return end
        for _, w in ipairs(WorldDatabase.List) do d.unlockedWorlds[w.id] = true end
        DataService:MarkDirty(target)
        notify("Unlocked all worlds on " .. target.Name)
    elseif cmd.action == "forceHatch" then
        if not target then return notify("Target not found.") end
        for _ = 1, math.clamp(tonumber(cmd.count) or 1, 1, 50) do
            EggService:HandleHatchRequest(target, cmd.eggId, 1)
        end
    elseif cmd.action == "kick" then
        if not target then return notify("Target not found.") end
        target:Kick(tostring(cmd.reason or "Kicked by admin"))
    elseif cmd.action == "announce" then
        AnnouncementService:Broadcast("[ANNOUNCEMENT] " .. tostring(cmd.message or ""))
    else
        notify("Unknown action: " .. tostring(cmd.action))
    end
end

function AdminService:Init()
    Remotes.IsAdmin.OnServerInvoke = function(plr) return isAdmin(plr) end
    Remotes.AdminCommand.OnServerEvent:Connect(function(plr, cmd)
        if not isAdmin(plr) then warn("[Admin] Non-admin attempted command: " .. plr.Name); return end
        if type(cmd) ~= "table" or type(cmd.action) ~= "string" then return end
        self:Handle(plr, cmd)
    end)
end

-- =============================================================
-- BOOT EVERYTHING
-- =============================================================
DataService:Init()
GamepassService:Init()
EggService:Init()
BreakingService:Init()
RebirthService:Init()
AdminService:Init()

-- Equip / unequip / lock / delete remotes
Remotes.EquipPet.OnServerEvent:Connect(function(plr, uid)   PetService:EquipPet(plr, uid)   end)
Remotes.UnequipPet.OnServerEvent:Connect(function(plr, uid) PetService:UnequipPet(plr, uid) end)
Remotes.LockPet.OnServerEvent:Connect(function(plr, uid, locked) PetService:LockPet(plr, uid, locked) end)
Remotes.DeletePet.OnServerEvent:Connect(function(plr, uid) PetService:RemovePet(plr, uid) end)

-- Broadcast data changes to client
DataService.DataChanged:Connect(function(plr, data) Remotes.PlayerDataUpdated:FireClient(plr, data) end)
DataService.DataLoaded:Connect(function(plr, data) Remotes.PlayerDataUpdated:FireClient(plr, data) end)
Remotes.GetPlayerData.OnServerInvoke = function(plr) return DataService:Get(plr) end

print("[PetLegendsX] Server booted.")
