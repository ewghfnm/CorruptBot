--[[
============================================================
   PET LEGENDS X - SHARED MODULE
   Place: ReplicatedStorage
   Type:  ModuleScript
   Name:  PetLegendsX_Shared
============================================================

   This file holds everything both the server and client need:
   config, databases (pets/eggs/worlds/gamepasses/enchants),
   rarities, util helpers, a tiny Signal class, and the Remotes
   folder/setup.

   Edit the values near the top of each section to balance the game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = {}

-- =============================================================
-- CONFIG (tweak these to balance the game)
-- =============================================================
Shared.Config = {
    HATCH_ANIMATION_TIME = 1.5,

    -- Pity guarantees
    PITY_MYTHICAL_AFTER  = 250,
    PITY_LEGENDARY_AFTER = 75,

    -- Starting currency
    STARTING_COINS = 100,
    STARTING_GEMS  = 0,

    -- Pets
    MAX_EQUIPPED_PETS_DEFAULT  = 3,
    MAX_EQUIPPED_PETS_GAMEPASS = 6,
    MAX_PET_LEVEL = 100,
    PET_XP_PER_LEVEL = function(level) return 100 * level ^ 1.5 end,

    -- Rebirth
    REBIRTH_BASE_COST  = 1e6,
    REBIRTH_COST_SCALE = 2.5,
    REBIRTH_MULTIPLIER = 2.0,

    -- Breaking
    BREAKABLE_RESPAWN_TIME = 8,

    -- Server-wide announcement on rarity index >= this
    ANNOUNCE_RARITY_INDEX = 6,

    -- ADMIN ACCESS - put YOUR Roblox UserId or username here
    ADMIN_USER_IDS  = {
        -- 1234567890,
    },
    ADMIN_USERNAMES = {
        -- "YourRobloxUsername",
    },

    -- DataStore
    DATASTORE_NAME = "PetLegendsX_Save_v1",
    AUTOSAVE_INTERVAL = 60,
    AUTO_HATCH_INTERVAL = 1.0,
}

-- =============================================================
-- UTIL
-- =============================================================
Shared.Util = {}

function Shared.Util.WeightedPick(entries, luckMultiplier)
    luckMultiplier = luckMultiplier or 1
    local total = 0
    local adjusted = {}
    for _, e in ipairs(entries) do
        local w = e.weight
        if luckMultiplier > 1 and w < 5 then w = w * luckMultiplier end
        table.insert(adjusted, {id = e.id, weight = w})
        total = total + w
    end
    local roll = math.random() * total
    local acc = 0
    for _, e in ipairs(adjusted) do
        acc = acc + e.weight
        if roll <= acc then return e.id end
    end
    return adjusted[#adjusted].id
end

function Shared.Util.FormatNumber(n)
    if n == nil then return "0" end
    if n < 1000 then return tostring(math.floor(n)) end
    local suffixes = {"K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
    local i, v = 0, n
    while v >= 1000 and i < #suffixes do v = v / 1000; i = i + 1 end
    return string.format("%.2f%s", v, suffixes[i] or "")
end

function Shared.Util.NewGuid()
    return tostring(os.time()) .. "_" .. tostring(math.random(0, 1e9))
end

-- =============================================================
-- SIGNAL (mini event class)
-- =============================================================
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({_listeners = {}}, Signal)
end
function Signal:Connect(fn)
    table.insert(self._listeners, fn)
    return {Disconnect = function()
        for i, l in ipairs(self._listeners) do
            if l == fn then table.remove(self._listeners, i); break end
        end
    end}
end
function Signal:Fire(...)
    for _, fn in ipairs(self._listeners) do task.spawn(fn, ...) end
end
Shared.Signal = Signal

-- =============================================================
-- RARITIES
-- =============================================================
Shared.Rarities = {
    List = {
        {name = "Common",     color = Color3.fromRGB(180,180,180), glow = Color3.fromRGB(255,255,255)},
        {name = "Uncommon",   color = Color3.fromRGB(100,220,100), glow = Color3.fromRGB(150,255,150)},
        {name = "Rare",       color = Color3.fromRGB(80,140,255),  glow = Color3.fromRGB(150,200,255)},
        {name = "Epic",       color = Color3.fromRGB(180,80,255),  glow = Color3.fromRGB(220,150,255)},
        {name = "Legendary",  color = Color3.fromRGB(255,180,50),  glow = Color3.fromRGB(255,220,100)},
        {name = "Mythical",   color = Color3.fromRGB(255,80,80),   glow = Color3.fromRGB(255,150,150)},
        {name = "Secret",     color = Color3.fromRGB(40,40,40),    glow = Color3.fromRGB(255,0,200)},
        {name = "Divine",     color = Color3.fromRGB(255,240,200), glow = Color3.fromRGB(255,255,255)},
        {name = "Exclusive",  color = Color3.fromRGB(255,50,200),  glow = Color3.fromRGB(255,150,255)},
        {name = "Huge",       color = Color3.fromRGB(255,215,0),   glow = Color3.fromRGB(255,255,0)},
        {name = "Admin",      color = Color3.fromRGB(255,0,0),     glow = Color3.fromRGB(255,100,100)},
    },
}
do
    local n2i = {}
    for i, r in ipairs(Shared.Rarities.List) do r.index = i; n2i[r.name] = i end
    function Shared.Rarities.GetByName(n) local i = n2i[n]; return i and Shared.Rarities.List[i] or nil end
    function Shared.Rarities.GetByIndex(i) return Shared.Rarities.List[i] end
    function Shared.Rarities.IsAtLeast(rarity, threshold)
        local a, b = n2i[rarity], n2i[threshold]
        if not a or not b then return false end
        return a >= b
    end
end

-- =============================================================
-- WORLDS
-- =============================================================
Shared.WorldDatabase = {
    List = {
        {id="Meadow",  name="Spawn Meadow",   unlockCost=0,      coinMultiplier=1,    rebirthRequired=0},
        {id="Candy",   name="Candy Kingdom",  unlockCost=25000,  coinMultiplier=5,    rebirthRequired=0},
        {id="Cyber",   name="Cyber City",     unlockCost=5e6,    coinMultiplier=25,   rebirthRequired=0},
        {id="Volcano", name="Volcano Core",   unlockCost=5e8,    coinMultiplier=100,  rebirthRequired=1},
        {id="Ocean",   name="Ocean Paradise", unlockCost=5e10,   coinMultiplier=500,  rebirthRequired=2},
        {id="Frozen",  name="Frozen Peaks",   unlockCost=5e12,   coinMultiplier=2500, rebirthRequired=3},
        {id="Egypt",   name="Ancient Egypt",  unlockCost=5e14,   coinMultiplier=1e4,  rebirthRequired=5},
        {id="Space",   name="Space Station",  unlockCost=5e16,   coinMultiplier=5e4,  rebirthRequired=8},
        {id="Samurai", name="Samurai World",  unlockCost=5e18,   coinMultiplier=2e5,  rebirthRequired=12},
        {id="Heaven",  name="Heaven Realm",   unlockCost=5e20,   coinMultiplier=1e6,  rebirthRequired=18},
        {id="Void",    name="Void Realm",     unlockCost=5e22,   coinMultiplier=5e6,  rebirthRequired=25},
        {id="Cosmic",  name="Cosmic Infinity",unlockCost=5e24,   coinMultiplier=2e7,  rebirthRequired=35},
    },
}
do
    local byId = {}
    for i, w in ipairs(Shared.WorldDatabase.List) do w.order = i; byId[w.id] = w end
    function Shared.WorldDatabase.GetById(id) return byId[id] end
end

-- =============================================================
-- PETS
-- =============================================================
Shared.PetDatabase = {
    List = {
        -- MEADOW
        {id="meadow_dog",      name="Meadow Dog",     rarity="Common",    damage=1,    coinMultiplier=1.0, world="Meadow"},
        {id="meadow_cat",      name="Meadow Cat",     rarity="Common",    damage=1.2,  coinMultiplier=1.0, world="Meadow"},
        {id="meadow_bunny",    name="Bunny",          rarity="Uncommon",  damage=2,    coinMultiplier=1.1, world="Meadow"},
        {id="meadow_fox",      name="Sly Fox",        rarity="Rare",      damage=5,    coinMultiplier=1.2, world="Meadow"},
        {id="meadow_bear",     name="Brave Bear",     rarity="Epic",      damage=12,   coinMultiplier=1.5, world="Meadow"},
        {id="meadow_dragon",   name="Meadow Dragon",  rarity="Legendary", damage=35,   coinMultiplier=2.0, world="Meadow"},
        {id="meadow_unicorn",  name="Mystic Unicorn", rarity="Mythical",  damage=100,  coinMultiplier=3.0, world="Meadow"},
        -- CANDY
        {id="candy_gummy",     name="Gummy Bear",      rarity="Common",    damage=6,    coinMultiplier=1.5, world="Candy"},
        {id="candy_lolli",     name="Lollipop Pup",    rarity="Uncommon",  damage=12,   coinMultiplier=1.6, world="Candy"},
        {id="candy_choco",     name="Chocolate Wolf",  rarity="Rare",      damage=25,   coinMultiplier=1.8, world="Candy"},
        {id="candy_donut",     name="Donut Dragon",    rarity="Epic",      damage=60,   coinMultiplier=2.2, world="Candy"},
        {id="candy_cupcake",   name="Cupcake Phoenix", rarity="Legendary", damage=180,  coinMultiplier=3.0, world="Candy"},
        {id="candy_king",      name="Candy King",      rarity="Mythical",  damage=500,  coinMultiplier=4.5, world="Candy"},
        -- CYBER
        {id="cyber_drone",     name="Cyber Drone",     rarity="Common",    damage=30,   coinMultiplier=2.0, world="Cyber"},
        {id="cyber_bot",       name="Neon Bot",        rarity="Uncommon",  damage=60,   coinMultiplier=2.2, world="Cyber"},
        {id="cyber_hacker",    name="Hacker Cat",      rarity="Rare",      damage=130,  coinMultiplier=2.5, world="Cyber"},
        {id="cyber_mech",      name="Battle Mech",     rarity="Epic",      damage=300,  coinMultiplier=3.2, world="Cyber"},
        {id="cyber_ai",        name="Rogue AI",        rarity="Legendary", damage=900,  coinMultiplier=4.5, world="Cyber"},
        {id="cyber_overlord",  name="Cyber Overlord",  rarity="Mythical",  damage=2500, coinMultiplier=6.0, world="Cyber"},
        -- VOLCANO
        {id="volcano_imp",     name="Lava Imp",        rarity="Rare",      damage=700,    coinMultiplier=4.0,  world="Volcano"},
        {id="volcano_phoenix", name="Phoenix",         rarity="Epic",      damage=1800,   coinMultiplier=5.0,  world="Volcano"},
        {id="volcano_demon",   name="Magma Demon",     rarity="Legendary", damage=5000,   coinMultiplier=6.5,  world="Volcano"},
        {id="volcano_titan",   name="Inferno Titan",   rarity="Mythical",  damage=14000,  coinMultiplier=9.0,  world="Volcano"},
        {id="volcano_god",     name="God of Fire",     rarity="Secret",    damage=80000,  coinMultiplier=20.0, world="Volcano"},
        -- OCEAN
        {id="ocean_fish",      name="Tropical Fish",   rarity="Uncommon",  damage=4000,    coinMultiplier=7.0,  world="Ocean"},
        {id="ocean_shark",     name="Hammer Shark",    rarity="Rare",      damage=12000,   coinMultiplier=9.0,  world="Ocean"},
        {id="ocean_kraken",    name="Kraken",          rarity="Legendary", damage=50000,   coinMultiplier=14.0, world="Ocean"},
        {id="ocean_leviathan", name="Leviathan",       rarity="Mythical",  damage=150000,  coinMultiplier=22.0, world="Ocean"},
        -- FROZEN
        {id="frozen_penguin",  name="Frost Penguin",   rarity="Rare",      damage=80000,    coinMultiplier=18.0, world="Frozen"},
        {id="frozen_yeti",     name="Yeti",            rarity="Epic",      damage=200000,   coinMultiplier=25.0, world="Frozen"},
        {id="frozen_dragon",   name="Ice Dragon",      rarity="Legendary", damage=600000,   coinMultiplier=40.0, world="Frozen"},
        {id="frozen_queen",    name="Frost Queen",     rarity="Mythical",  damage=1.8e6,    coinMultiplier=60.0, world="Frozen"},
        -- EGYPT
        {id="egypt_scarab",    name="Golden Scarab",   rarity="Rare",      damage=1.2e6,   coinMultiplier=50.0,  world="Egypt"},
        {id="egypt_anubis",    name="Anubis Hound",    rarity="Legendary", damage=8e6,     coinMultiplier=90.0,  world="Egypt"},
        {id="egypt_pharaoh",   name="Pharaoh",         rarity="Mythical",  damage=3e7,     coinMultiplier=140.0, world="Egypt"},
        {id="egypt_sphinx",    name="Sphinx",          rarity="Secret",    damage=1.5e8,   coinMultiplier=300.0, world="Egypt"},
        -- SPACE
        {id="space_alien",     name="Alien",           rarity="Epic",      damage=6e7, coinMultiplier=200.0, world="Space"},
        {id="space_astronaut", name="Astro Pup",       rarity="Legendary", damage=2e8, coinMultiplier=350.0, world="Space"},
        {id="space_starbeast", name="Star Beast",      rarity="Mythical",  damage=9e8, coinMultiplier=600.0, world="Space"},
        -- SAMURAI
        {id="samurai_kitsune", name="Kitsune",         rarity="Legendary", damage=1.2e9, coinMultiplier=900.0,  world="Samurai"},
        {id="samurai_dragon",  name="Sakura Dragon",   rarity="Mythical",  damage=5e9,   coinMultiplier=1500.0, world="Samurai"},
        {id="samurai_oni",     name="Demon Oni",       rarity="Secret",    damage=2e10,  coinMultiplier=4000.0, world="Samurai"},
        -- HEAVEN
        {id="heaven_angel",    name="Cherub",          rarity="Mythical",  damage=3e10,   coinMultiplier=6000.0,  world="Heaven"},
        {id="heaven_seraph",   name="Seraph",          rarity="Divine",    damage=1.5e11, coinMultiplier=12000.0, world="Heaven"},
        -- VOID
        {id="void_wraith",     name="Void Wraith",     rarity="Mythical", damage=8e11, coinMultiplier=25000.0,  world="Void"},
        {id="void_lord",       name="Void Lord",       rarity="Secret",   damage=4e12, coinMultiplier=60000.0,  world="Void"},
        {id="void_corrupted",  name="Corrupted One",   rarity="Divine",   damage=2e13, coinMultiplier=150000.0, world="Void"},
        -- COSMIC
        {id="cosmic_nebula",   name="Nebula Beast",    rarity="Mythical",  damage=1e14, coinMultiplier=4e5, world="Cosmic"},
        {id="cosmic_blackhole",name="Black Hole",      rarity="Secret",    damage=8e14, coinMultiplier=1e6, world="Cosmic"},
        {id="cosmic_universe", name="Universe",        rarity="Divine",    damage=5e15, coinMultiplier=4e6, world="Cosmic"},
        {id="cosmic_creator",  name="The Creator",     rarity="Exclusive", damage=3e16, coinMultiplier=1e7, world="Cosmic"},
        -- HUGE PETS
        {id="huge_meadow_dog",      name="Huge Meadow Dog",     rarity="Huge", damage=1e8,  coinMultiplier=1000,  world="Meadow"},
        {id="huge_candy_king",      name="Huge Candy King",     rarity="Huge", damage=1e10, coinMultiplier=10000, world="Candy"},
        {id="huge_cyber_overlord",  name="Huge Cyber Overlord", rarity="Huge", damage=1e12, coinMultiplier=1e5,   world="Cyber"},
        {id="huge_phoenix",         name="Huge Phoenix",        rarity="Huge", damage=1e14, coinMultiplier=1e6,   world="Volcano"},
        {id="huge_kraken",          name="Huge Kraken",         rarity="Huge", damage=1e16, coinMultiplier=1e7,   world="Ocean"},
        {id="huge_creator",         name="Huge Creator",        rarity="Huge", damage=1e18, coinMultiplier=1e9,   world="Cosmic"},
        -- ADMIN
        {id="admin_kiro",      name="Admin Kiro",      rarity="Admin", damage=1e25, coinMultiplier=1e15, world="Admin"},
    },
}
do
    local byId = {}
    for _, p in ipairs(Shared.PetDatabase.List) do p.tier = "Standard"; byId[p.id] = p end
    function Shared.PetDatabase.GetById(id) return byId[id] end
end

-- =============================================================
-- EGGS
-- =============================================================
Shared.EggDatabase = {
    List = {
        {id="egg_meadow", name="Meadow Egg", world="Meadow", cost=100,  currency="coins", hugeChance=1/5e6, hugePool={"huge_meadow_dog"}, pets={
            {id="meadow_dog",weight=60},{id="meadow_cat",weight=60},{id="meadow_bunny",weight=25},
            {id="meadow_fox",weight=10},{id="meadow_bear",weight=4},{id="meadow_dragon",weight=0.9},
            {id="meadow_unicorn",weight=0.1},
        }},
        {id="egg_candy", name="Candy Egg", world="Candy", cost=5000, currency="coins", hugeChance=1/5e6, hugePool={"huge_candy_king"}, pets={
            {id="candy_gummy",weight=60},{id="candy_lolli",weight=25},{id="candy_choco",weight=10},
            {id="candy_donut",weight=4},{id="candy_cupcake",weight=0.9},{id="candy_king",weight=0.1},
        }},
        {id="egg_cyber", name="Cyber Egg", world="Cyber", cost=250000, currency="coins", hugeChance=1/5e6, hugePool={"huge_cyber_overlord"}, pets={
            {id="cyber_drone",weight=60},{id="cyber_bot",weight=25},{id="cyber_hacker",weight=10},
            {id="cyber_mech",weight=4},{id="cyber_ai",weight=0.9},{id="cyber_overlord",weight=0.1},
        }},
        {id="egg_volcano", name="Volcano Egg", world="Volcano", cost=10e6, currency="coins", hugeChance=1/5e6, hugePool={"huge_phoenix"}, pets={
            {id="volcano_imp",weight=50},{id="volcano_phoenix",weight=25},{id="volcano_demon",weight=10},
            {id="volcano_titan",weight=1},{id="volcano_god",weight=0.05},
        }},
        {id="egg_ocean", name="Ocean Egg", world="Ocean", cost=5e8, currency="coins", hugeChance=1/5e6, hugePool={"huge_kraken"}, pets={
            {id="ocean_fish",weight=50},{id="ocean_shark",weight=25},{id="ocean_kraken",weight=5},
            {id="ocean_leviathan",weight=0.5},
        }},
        {id="egg_cosmic", name="Cosmic Egg", world="Cosmic", cost=50, currency="gems", hugeChance=1/1e6, hugePool={"huge_creator"}, pets={
            {id="cosmic_nebula",weight=30},{id="cosmic_blackhole",weight=1},
            {id="cosmic_universe",weight=0.1},{id="cosmic_creator",weight=0.01},
        }},
    },
}
do
    local byId = {}
    for _, e in ipairs(Shared.EggDatabase.List) do byId[e.id] = e end
    function Shared.EggDatabase.GetById(id) return byId[id] end
end

-- =============================================================
-- GAMEPASSES (replace id=0 with your real Roblox gamepass IDs)
-- =============================================================
Shared.GamepassDatabase = {
    List = {
        {key="AutoHatch",   id=0, name="Auto Hatch",        priceRobux=399,  description="Hatch eggs automatically."},
        {key="TripleHatch", id=0, name="Triple Hatch",      priceRobux=799,  description="Hatch 3 eggs at once."},
        {key="ExtraEquip",  id=0, name="Extra Equip Slots", priceRobux=499,  description="Equip up to 6 pets at once."},
        {key="SuperLucky",  id=0, name="Super Lucky",       priceRobux=999,  description="+50% better odds."},
        {key="UltraLucky",  id=0, name="Ultra Lucky",       priceRobux=1499, description="+150% better odds."},
        {key="FasterWalk",  id=0, name="Faster Walkspeed",  priceRobux=299,  description="+8 walkspeed."},
        {key="VIP",         id=0, name="VIP",               priceRobux=799,  description="VIP tag, +25% coins, gold chat."},
    },
}
do
    local byKey, byId = {}, {}
    for _, g in ipairs(Shared.GamepassDatabase.List) do
        byKey[g.key] = g
        if g.id and g.id > 0 then byId[g.id] = g end
    end
    function Shared.GamepassDatabase.GetByKey(k) return byKey[k] end
    function Shared.GamepassDatabase.GetById(i) return byId[i] end
end

-- =============================================================
-- ENCHANTS (data only; mechanics applied in pet stat calc)
-- =============================================================
Shared.EnchantDatabase = {
    List = {
        {id="coin_boost",    name="Coin Boost",    stat="coinMultiplier", perTier=0.10},
        {id="damage_boost",  name="Damage Boost",  stat="damage",         perTier=0.15},
        {id="crit_chance",   name="Crit Chance",   stat="critChance",     perTier=0.05},
        {id="speed",         name="Speed",         stat="walkspeed",      perTier=1.0},
        {id="chest_breaker", name="Chest Breaker", stat="chestDamage",    perTier=0.20},
        {id="lucky_eggs",    name="Lucky Eggs",    stat="luck",           perTier=0.05},
        {id="ultra_lucky",   name="Ultra Lucky",   stat="luck",           perTier=0.15},
        {id="xp_boost",      name="XP Boost",      stat="xpMultiplier",   perTier=0.20},
        {id="gem_finder",    name="Gem Finder",    stat="gemMultiplier",  perTier=0.25},
    },
}
do
    local byId = {}
    for _, e in ipairs(Shared.EnchantDatabase.List) do byId[e.id] = e end
    function Shared.EnchantDatabase.GetById(id) return byId[id] end
end

-- =============================================================
-- REMOTES (lazy-create on first require)
-- =============================================================
local function getOrCreate(folder, className, name)
    local existing = folder:FindFirstChild(name)
    if existing then return existing end
    if RunService:IsServer() then
        local inst = Instance.new(className)
        inst.Name = name
        inst.Parent = folder
        return inst
    else
        return folder:WaitForChild(name, 10)
    end
end

local remotesFolder = ReplicatedStorage:FindFirstChild("PetLegendsX_Remotes")
if not remotesFolder then
    if RunService:IsServer() then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "PetLegendsX_Remotes"
        remotesFolder.Parent = ReplicatedStorage
    else
        remotesFolder = ReplicatedStorage:WaitForChild("PetLegendsX_Remotes", 10)
    end
end

Shared.Remotes = {
    HatchEgg          = getOrCreate(remotesFolder, "RemoteEvent",    "HatchEgg"),
    PlayerDataUpdated = getOrCreate(remotesFolder, "RemoteEvent",    "PlayerDataUpdated"),
    HatchResult       = getOrCreate(remotesFolder, "RemoteEvent",    "HatchResult"),
    EquipPet          = getOrCreate(remotesFolder, "RemoteEvent",    "EquipPet"),
    UnequipPet        = getOrCreate(remotesFolder, "RemoteEvent",    "UnequipPet"),
    LockPet           = getOrCreate(remotesFolder, "RemoteEvent",    "LockPet"),
    DeletePet         = getOrCreate(remotesFolder, "RemoteEvent",    "DeletePet"),
    UnlockWorld       = getOrCreate(remotesFolder, "RemoteEvent",    "UnlockWorld"),
    Rebirth           = getOrCreate(remotesFolder, "RemoteEvent",    "Rebirth"),
    Notification      = getOrCreate(remotesFolder, "RemoteEvent",    "Notification"),
    ServerAnnounce    = getOrCreate(remotesFolder, "RemoteEvent",    "ServerAnnounce"),
    AdminCommand      = getOrCreate(remotesFolder, "RemoteEvent",    "AdminCommand"),
    RequestBreakHit   = getOrCreate(remotesFolder, "RemoteEvent",    "RequestBreakHit"),
    SetAutoHatch      = getOrCreate(remotesFolder, "RemoteEvent",    "SetAutoHatch"),
    GetPlayerData     = getOrCreate(remotesFolder, "RemoteFunction", "GetPlayerData"),
    IsAdmin           = getOrCreate(remotesFolder, "RemoteFunction", "IsAdmin"),
}

return Shared
