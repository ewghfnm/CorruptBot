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

    -- World layout
    WORLD_SIZE = 250,    -- size of each world's baseplate (square)
    WORLD_SPACING = 400, -- distance between world centers
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
        {id="Meadow",  name="Spawn Meadow",   unlockCost=0,      coinMultiplier=1,    rebirthRequired=0,
            theme={ground=Color3.fromRGB(86,180,86),   sky=Color3.fromRGB(120,200,255), groundMat=Enum.Material.Grass,         decorColors={Color3.fromRGB(40,140,40),Color3.fromRGB(180,220,80)}, music=0}},
        {id="Candy",   name="Candy Kingdom",  unlockCost=25000,  coinMultiplier=5,    rebirthRequired=0,
            theme={ground=Color3.fromRGB(255,170,210), sky=Color3.fromRGB(255,200,230), groundMat=Enum.Material.SmoothPlastic, decorColors={Color3.fromRGB(255,80,150),Color3.fromRGB(255,255,150),Color3.fromRGB(180,80,255)}, music=0}},
        {id="Cyber",   name="Cyber City",     unlockCost=5e6,    coinMultiplier=25,   rebirthRequired=0,
            theme={ground=Color3.fromRGB(30,30,50),    sky=Color3.fromRGB(20,10,40),    groundMat=Enum.Material.Metal,         decorColors={Color3.fromRGB(0,255,200),Color3.fromRGB(255,0,200),Color3.fromRGB(0,150,255)}, music=0}},
        {id="Volcano", name="Volcano Core",   unlockCost=5e8,    coinMultiplier=100,  rebirthRequired=1,
            theme={ground=Color3.fromRGB(70,30,30),    sky=Color3.fromRGB(120,30,20),   groundMat=Enum.Material.Slate,         decorColors={Color3.fromRGB(255,80,30),Color3.fromRGB(255,150,30),Color3.fromRGB(120,40,40)}, music=0}},
        {id="Ocean",   name="Ocean Paradise", unlockCost=5e10,   coinMultiplier=500,  rebirthRequired=2,
            theme={ground=Color3.fromRGB(240,220,160), sky=Color3.fromRGB(150,220,255), groundMat=Enum.Material.Sand,          decorColors={Color3.fromRGB(0,180,255),Color3.fromRGB(255,180,150),Color3.fromRGB(120,255,200)}, music=0}},
        {id="Frozen",  name="Frozen Peaks",   unlockCost=5e12,   coinMultiplier=2500, rebirthRequired=3,
            theme={ground=Color3.fromRGB(220,240,255), sky=Color3.fromRGB(180,210,240), groundMat=Enum.Material.Glacier,       decorColors={Color3.fromRGB(180,220,255),Color3.fromRGB(255,255,255),Color3.fromRGB(120,200,255)}, music=0}},
        {id="Egypt",   name="Ancient Egypt",  unlockCost=5e14,   coinMultiplier=1e4,  rebirthRequired=5,
            theme={ground=Color3.fromRGB(230,200,120), sky=Color3.fromRGB(255,200,120), groundMat=Enum.Material.Sand,          decorColors={Color3.fromRGB(220,180,80),Color3.fromRGB(180,140,60),Color3.fromRGB(255,220,100)}, music=0}},
        {id="Space",   name="Space Station",  unlockCost=5e16,   coinMultiplier=5e4,  rebirthRequired=8,
            theme={ground=Color3.fromRGB(60,60,80),    sky=Color3.fromRGB(0,0,15),      groundMat=Enum.Material.Metal,         decorColors={Color3.fromRGB(120,120,180),Color3.fromRGB(60,200,255),Color3.fromRGB(255,255,255)}, music=0}},
        {id="Samurai", name="Samurai World",  unlockCost=5e18,   coinMultiplier=2e5,  rebirthRequired=12,
            theme={ground=Color3.fromRGB(180,140,80),  sky=Color3.fromRGB(255,200,220), groundMat=Enum.Material.WoodPlanks,    decorColors={Color3.fromRGB(255,180,200),Color3.fromRGB(180,40,40),Color3.fromRGB(60,30,20)}, music=0}},
        {id="Heaven",  name="Heaven Realm",   unlockCost=5e20,   coinMultiplier=1e6,  rebirthRequired=18,
            theme={ground=Color3.fromRGB(255,250,220), sky=Color3.fromRGB(255,255,240), groundMat=Enum.Material.Marble,        decorColors={Color3.fromRGB(255,240,180),Color3.fromRGB(255,255,255),Color3.fromRGB(255,220,120)}, music=0}},
        {id="Void",    name="Void Realm",     unlockCost=5e22,   coinMultiplier=5e6,  rebirthRequired=25,
            theme={ground=Color3.fromRGB(40,20,60),    sky=Color3.fromRGB(20,0,30),     groundMat=Enum.Material.Slate,         decorColors={Color3.fromRGB(140,40,200),Color3.fromRGB(80,20,120),Color3.fromRGB(200,80,255)}, music=0}},
        {id="Cosmic",  name="Cosmic Infinity",unlockCost=5e24,   coinMultiplier=2e7,  rebirthRequired=35,
            theme={ground=Color3.fromRGB(20,20,40),    sky=Color3.fromRGB(0,0,0),       groundMat=Enum.Material.Neon,          decorColors={Color3.fromRGB(255,100,255),Color3.fromRGB(100,200,255),Color3.fromRGB(255,255,100)}, music=0}},
        -- New expansion worlds
        {id="Jungle",  name="Jungle Ruins",   unlockCost=12000,  coinMultiplier=3,    rebirthRequired=0,
            theme={ground=Color3.fromRGB(60,140,60),   sky=Color3.fromRGB(150,200,150), groundMat=Enum.Material.Grass,         decorColors={Color3.fromRGB(20,100,20),Color3.fromRGB(120,180,60),Color3.fromRGB(180,220,100)}, music=0}},
        {id="Desert",  name="Sun Dunes",      unlockCost=2e6,    coinMultiplier=15,   rebirthRequired=0,
            theme={ground=Color3.fromRGB(240,210,140), sky=Color3.fromRGB(255,220,150), groundMat=Enum.Material.Sand,          decorColors={Color3.fromRGB(220,180,80),Color3.fromRGB(180,140,80),Color3.fromRGB(120,80,40)}, music=0}},
        {id="Pirate",  name="Pirate Cove",    unlockCost=2e8,    coinMultiplier=70,   rebirthRequired=1,
            theme={ground=Color3.fromRGB(120,90,50),   sky=Color3.fromRGB(140,180,200), groundMat=Enum.Material.WoodPlanks,    decorColors={Color3.fromRGB(80,40,20),Color3.fromRGB(180,140,80),Color3.fromRGB(40,80,140)}, music=0}},
        {id="Steam",   name="Steampunk City", unlockCost=2e10,   coinMultiplier=350,  rebirthRequired=2,
            theme={ground=Color3.fromRGB(120,80,50),   sky=Color3.fromRGB(180,140,100), groundMat=Enum.Material.Metal,         decorColors={Color3.fromRGB(180,120,60),Color3.fromRGB(140,100,40),Color3.fromRGB(80,40,20)}, music=0}},
        {id="Mushroom",name="Mushroom Glade", unlockCost=2e12,   coinMultiplier=1500, rebirthRequired=3,
            theme={ground=Color3.fromRGB(100,140,80),  sky=Color3.fromRGB(200,180,255), groundMat=Enum.Material.Grass,         decorColors={Color3.fromRGB(220,80,80),Color3.fromRGB(255,150,100),Color3.fromRGB(150,80,180)}, music=0}},
        {id="Faerie",  name="Faerie Forest",  unlockCost=2e14,   coinMultiplier=7000, rebirthRequired=5,
            theme={ground=Color3.fromRGB(120,200,180), sky=Color3.fromRGB(255,180,220), groundMat=Enum.Material.Grass,         decorColors={Color3.fromRGB(255,150,200),Color3.fromRGB(150,255,200),Color3.fromRGB(200,150,255)}, music=0}},
        {id="Crystal", name="Crystal Caves",  unlockCost=2e16,   coinMultiplier=3e4,  rebirthRequired=7,
            theme={ground=Color3.fromRGB(80,80,140),   sky=Color3.fromRGB(60,40,100),   groundMat=Enum.Material.Slate,         decorColors={Color3.fromRGB(120,200,255),Color3.fromRGB(255,100,200),Color3.fromRGB(150,255,180)}, music=0}},
        {id="Storm",   name="Storm Realm",    unlockCost=2e18,   coinMultiplier=1.5e5,rebirthRequired=10,
            theme={ground=Color3.fromRGB(60,70,90),    sky=Color3.fromRGB(40,40,60),    groundMat=Enum.Material.Slate,         decorColors={Color3.fromRGB(255,255,150),Color3.fromRGB(180,200,255),Color3.fromRGB(80,90,120)}, music=0}},
        {id="Dino",    name="Dino Land",      unlockCost=2e20,   coinMultiplier=8e5,  rebirthRequired=14,
            theme={ground=Color3.fromRGB(140,160,80),  sky=Color3.fromRGB(180,210,140), groundMat=Enum.Material.Grass,         decorColors={Color3.fromRGB(80,140,40),Color3.fromRGB(160,100,40),Color3.fromRGB(220,180,100)}, music=0}},
        {id="Robot",   name="Robot Factory",  unlockCost=2e22,   coinMultiplier=4e6,  rebirthRequired=20,
            theme={ground=Color3.fromRGB(100,100,120), sky=Color3.fromRGB(80,90,120),   groundMat=Enum.Material.Metal,         decorColors={Color3.fromRGB(180,180,200),Color3.fromRGB(255,150,80),Color3.fromRGB(80,200,255)}, music=0}},
        {id="Underworld",name="Underworld",   unlockCost=2e23,   coinMultiplier=2e7,  rebirthRequired=28,
            theme={ground=Color3.fromRGB(40,15,15),    sky=Color3.fromRGB(40,0,0),      groundMat=Enum.Material.Slate,         decorColors={Color3.fromRGB(255,40,20),Color3.fromRGB(120,20,20),Color3.fromRGB(80,10,10)}, music=0}},
        {id="Eternity",name="Eternity",       unlockCost=2e26,   coinMultiplier=1e8,  rebirthRequired=50,
            theme={ground=Color3.fromRGB(255,255,255), sky=Color3.fromRGB(180,200,255), groundMat=Enum.Material.Neon,          decorColors={Color3.fromRGB(255,255,180),Color3.fromRGB(180,255,255),Color3.fromRGB(255,180,255)}, music=0}},
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
        -- More Huge pets across the new worlds
        {id="huge_jungle_tiger",    name="Huge Jungle Tiger",   rarity="Huge", damage=2e8,  coinMultiplier=2000,  world="Jungle"},
        {id="huge_pharaoh",         name="Huge Pharaoh",        rarity="Huge", damage=5e15, coinMultiplier=2e6,   world="Egypt"},
        {id="huge_yeti_king",       name="Huge Yeti King",      rarity="Huge", damage=5e13, coinMultiplier=5e5,   world="Frozen"},
        {id="huge_sun_serpent",     name="Huge Sun Serpent",    rarity="Huge", damage=1e9,  coinMultiplier=15000, world="Desert"},
        {id="huge_pirate_lord",     name="Huge Pirate Lord",    rarity="Huge", damage=1e11, coinMultiplier=80000, world="Pirate"},
        {id="huge_steam_titan",     name="Huge Steam Titan",    rarity="Huge", damage=1e13, coinMultiplier=4e5,   world="Steam"},
        {id="huge_mushroom_god",    name="Huge Mushroom God",   rarity="Huge", damage=5e13, coinMultiplier=1.5e6, world="Mushroom"},
        {id="huge_faerie_queen",    name="Huge Faerie Queen",   rarity="Huge", damage=1e15, coinMultiplier=8e6,   world="Faerie"},
        {id="huge_crystal_dragon",  name="Huge Crystal Dragon", rarity="Huge", damage=5e16, coinMultiplier=3e7,   world="Crystal"},
        {id="huge_storm_god",       name="Huge Storm God",      rarity="Huge", damage=1e18, coinMultiplier=1.5e8, world="Storm"},
        {id="huge_t_rex",           name="Huge T-Rex",          rarity="Huge", damage=5e18, coinMultiplier=8e8,   world="Dino"},
        {id="huge_mega_robot",      name="Huge Mega Robot",     rarity="Huge", damage=1e20, coinMultiplier=4e9,   world="Robot"},
        {id="huge_underworld_lord",name="Huge Underworld Lord", rarity="Huge", damage=5e21, coinMultiplier=2e10,  world="Underworld"},
        {id="huge_eternal",         name="Huge Eternal",        rarity="Huge", damage=1e23, coinMultiplier=1e11,  world="Eternity"},
        -- Extra meadow pets
        {id="meadow_squirrel",     name="Squirrel",           rarity="Common",    damage=1.4,   coinMultiplier=1.0, world="Meadow"},
        {id="meadow_deer",         name="Forest Deer",        rarity="Uncommon",  damage=2.5,   coinMultiplier=1.1, world="Meadow"},
        {id="meadow_owl",          name="Wise Owl",           rarity="Rare",      damage=6,     coinMultiplier=1.3, world="Meadow"},
        {id="meadow_griffin",      name="Mini Griffin",       rarity="Epic",      damage=15,    coinMultiplier=1.6, world="Meadow"},
        -- Jungle world pets
        {id="jungle_monkey",   name="Cheeky Monkey",   rarity="Common",    damage=2,    coinMultiplier=1.4, world="Jungle"},
        {id="jungle_parrot",   name="Tropic Parrot",   rarity="Uncommon",  damage=4,    coinMultiplier=1.5, world="Jungle"},
        {id="jungle_panther",  name="Black Panther",   rarity="Rare",      damage=10,   coinMultiplier=1.7, world="Jungle"},
        {id="jungle_anaconda", name="Anaconda",        rarity="Epic",      damage=22,   coinMultiplier=1.9, world="Jungle"},
        {id="jungle_jaguar",   name="Jade Jaguar",     rarity="Legendary", damage=70,   coinMultiplier=2.4, world="Jungle"},
        {id="jungle_tiger",    name="Spirit Tiger",    rarity="Mythical",  damage=220,  coinMultiplier=3.6, world="Jungle"},
        -- Extra candy
        {id="candy_jellybean", name="Jelly Bean",      rarity="Common",    damage=7,    coinMultiplier=1.5, world="Candy"},
        {id="candy_marshmallow",name="Marshmallow Man",rarity="Uncommon",  damage=14,   coinMultiplier=1.7, world="Candy"},
        {id="candy_taffy",     name="Taffy Twirl",     rarity="Rare",      damage=30,   coinMultiplier=1.9, world="Candy"},
        -- Desert world pets
        {id="desert_camel",    name="Sand Camel",      rarity="Common",    damage=8,    coinMultiplier=1.7, world="Desert"},
        {id="desert_lizard",   name="Heat Lizard",     rarity="Uncommon",  damage=18,   coinMultiplier=1.9, world="Desert"},
        {id="desert_scorpion", name="Sand Scorpion",   rarity="Rare",      damage=40,   coinMultiplier=2.2, world="Desert"},
        {id="desert_meerkat",  name="Sneaky Meerkat",  rarity="Epic",      damage=80,   coinMultiplier=2.6, world="Desert"},
        {id="desert_jinn",     name="Desert Jinn",     rarity="Legendary", damage=240,  coinMultiplier=3.4, world="Desert"},
        {id="desert_serpent",  name="Sun Serpent",     rarity="Mythical",  damage=750,  coinMultiplier=5.0, world="Desert"},
        -- Extra cyber
        {id="cyber_glitch",    name="Glitch Sprite",   rarity="Uncommon",  damage=70,   coinMultiplier=2.3, world="Cyber"},
        {id="cyber_virus",     name="Trojan Virus",    rarity="Rare",      damage=160,  coinMultiplier=2.6, world="Cyber"},
        -- Extra volcano
        {id="volcano_salamander",name="Lava Salamander",rarity="Common",   damage=400,  coinMultiplier=3.5, world="Volcano"},
        {id="volcano_basilisk",name="Magma Basilisk",  rarity="Rare",      damage=1100, coinMultiplier=4.5, world="Volcano"},
        -- Pirate world pets
        {id="pirate_parrot",   name="Pirate Parrot",   rarity="Common",    damage=600,  coinMultiplier=4.0, world="Pirate"},
        {id="pirate_crab",     name="Cannon Crab",     rarity="Uncommon",  damage=1200, coinMultiplier=4.4, world="Pirate"},
        {id="pirate_skeleton", name="Skele Crew",      rarity="Rare",      damage=2800, coinMultiplier=5.0, world="Pirate"},
        {id="pirate_captain",  name="Captain Cutlass", rarity="Epic",      damage=6500, coinMultiplier=6.0, world="Pirate"},
        {id="pirate_ghost_ship",name="Ghost Ship",     rarity="Legendary", damage=18000,coinMultiplier=7.5, world="Pirate"},
        {id="pirate_lord",     name="Pirate Lord",     rarity="Mythical",  damage=55000,coinMultiplier=10.0,world="Pirate"},
        -- Extra ocean
        {id="ocean_dolphin",   name="Dolphin",         rarity="Common",    damage=3500, coinMultiplier=6.5, world="Ocean"},
        {id="ocean_octopus",   name="Octopus",         rarity="Uncommon",  damage=8000, coinMultiplier=8.0, world="Ocean"},
        {id="ocean_seahorse",  name="Crystal Seahorse",rarity="Epic",      damage=30000,coinMultiplier=11.0,world="Ocean"},
        -- Steam world pets
        {id="steam_cogling",   name="Cogling",         rarity="Common",    damage=8e4,  coinMultiplier=20.0, world="Steam"},
        {id="steam_clockmouse",name="Clock Mouse",     rarity="Uncommon",  damage=1.5e5,coinMultiplier=24.0, world="Steam"},
        {id="steam_brassbull", name="Brass Bull",      rarity="Rare",      damage=4e5,  coinMultiplier=28.0, world="Steam"},
        {id="steam_zeppelin",  name="Zeppelin Pup",    rarity="Epic",      damage=1.2e6,coinMultiplier=34.0, world="Steam"},
        {id="steam_inventor",  name="Mad Inventor",    rarity="Legendary", damage=4.5e6,coinMultiplier=44.0, world="Steam"},
        {id="steam_titan",     name="Steam Titan",     rarity="Mythical",  damage=1.5e7,coinMultiplier=65.0, world="Steam"},
        -- Extra frozen
        {id="frozen_seal",     name="Frost Seal",      rarity="Common",    damage=6e4,  coinMultiplier=16.0, world="Frozen"},
        {id="frozen_wolf",     name="Snow Wolf",       rarity="Uncommon",  damage=1.5e5,coinMultiplier=21.0, world="Frozen"},
        -- Mushroom world pets
        {id="mush_sporeling",  name="Sporeling",       rarity="Common",    damage=4e6,  coinMultiplier=45.0, world="Mushroom"},
        {id="mush_toadstool",  name="Toadstool Toad",  rarity="Uncommon",  damage=8e6,  coinMultiplier=52.0, world="Mushroom"},
        {id="mush_psilo",      name="Psilo Pixie",     rarity="Rare",      damage=2e7,  coinMultiplier=60.0, world="Mushroom"},
        {id="mush_fungal",     name="Fungal Beast",    rarity="Epic",      damage=6e7,  coinMultiplier=75.0, world="Mushroom"},
        {id="mush_grandfungus",name="Grandfungus",     rarity="Legendary", damage=2e8,  coinMultiplier=95.0, world="Mushroom"},
        {id="mush_god",        name="Mushroom God",    rarity="Mythical",  damage=8e8,  coinMultiplier=140.0,world="Mushroom"},
        -- Extra egypt
        {id="egypt_cat",       name="Bastet Cat",      rarity="Uncommon",  damage=8e5,  coinMultiplier=42.0, world="Egypt"},
        {id="egypt_jackal",    name="Sand Jackal",     rarity="Rare",      damage=2e6,  coinMultiplier=55.0, world="Egypt"},
        -- Faerie world pets
        {id="faerie_pixie",    name="Pixie",           rarity="Common",    damage=2e7,  coinMultiplier=80.0,  world="Faerie"},
        {id="faerie_sprite",   name="Wisp Sprite",     rarity="Uncommon",  damage=5e7,  coinMultiplier=95.0,  world="Faerie"},
        {id="faerie_unicorn",  name="Faerie Unicorn",  rarity="Rare",      damage=1.5e8,coinMultiplier=120.0, world="Faerie"},
        {id="faerie_pegasus",  name="Pegasus",         rarity="Epic",      damage=4.5e8,coinMultiplier=160.0, world="Faerie"},
        {id="faerie_alicorn",  name="Alicorn",         rarity="Legendary", damage=1.4e9,coinMultiplier=220.0, world="Faerie"},
        {id="faerie_queen",    name="Faerie Queen",    rarity="Mythical",  damage=4.5e9,coinMultiplier=320.0, world="Faerie"},
        -- Extra space
        {id="space_satellite", name="Satellite Pet",   rarity="Uncommon",  damage=3e7,  coinMultiplier=160.0, world="Space"},
        {id="space_meteor",    name="Meteor Pup",      rarity="Rare",      damage=8e7,  coinMultiplier=210.0, world="Space"},
        {id="space_galactic",  name="Galactic Lord",   rarity="Secret",    damage=2e10, coinMultiplier=2000.0,world="Space"},
        -- Crystal world pets
        {id="crystal_shard",   name="Crystal Shard",   rarity="Common",    damage=4e9,  coinMultiplier=400.0,  world="Crystal"},
        {id="crystal_geode",   name="Geode Beast",     rarity="Uncommon",  damage=1e10, coinMultiplier=480.0,  world="Crystal"},
        {id="crystal_prism",   name="Prism Bird",      rarity="Rare",      damage=3e10, coinMultiplier=600.0,  world="Crystal"},
        {id="crystal_diamond", name="Diamond Wolf",    rarity="Epic",      damage=9e10, coinMultiplier=800.0,  world="Crystal"},
        {id="crystal_rainbow", name="Rainbow Dragon",  rarity="Legendary", damage=3e11, coinMultiplier=1100.0, world="Crystal"},
        {id="crystal_overlord",name="Crystal Overlord",rarity="Mythical",  damage=1e12, coinMultiplier=1600.0, world="Crystal"},
        -- Storm world pets
        {id="storm_breeze",    name="Breeze Sprite",   rarity="Common",    damage=1.5e10,coinMultiplier=1500.0, world="Storm"},
        {id="storm_thunder",   name="Thunder Hound",   rarity="Uncommon",  damage=4e10,  coinMultiplier=1800.0, world="Storm"},
        {id="storm_cyclone",   name="Cyclone Falcon",  rarity="Rare",      damage=1.2e11,coinMultiplier=2300.0, world="Storm"},
        {id="storm_lightning", name="Lightning Tiger", rarity="Epic",      damage=3.5e11,coinMultiplier=2900.0, world="Storm"},
        {id="storm_typhoon",   name="Typhoon Drake",   rarity="Legendary", damage=1.2e12,coinMultiplier=3800.0, world="Storm"},
        {id="storm_god",       name="Storm God",       rarity="Mythical",  damage=4e12,  coinMultiplier=5500.0, world="Storm"},
        -- Extra samurai
        {id="samurai_neko",    name="Neko Spirit",     rarity="Uncommon",  damage=8e8,  coinMultiplier=750.0,  world="Samurai"},
        {id="samurai_tengu",   name="Tengu",           rarity="Rare",      damage=2e9,  coinMultiplier=900.0,  world="Samurai"},
        -- Dino world pets
        {id="dino_compy",      name="Compy",           rarity="Common",    damage=8e11, coinMultiplier=8000.0,  world="Dino"},
        {id="dino_raptor",     name="Raptor",          rarity="Uncommon",  damage=2e12, coinMultiplier=9500.0,  world="Dino"},
        {id="dino_steg",       name="Stegosaurus",     rarity="Rare",      damage=6e12, coinMultiplier=12000.0, world="Dino"},
        {id="dino_brachio",    name="Brachiosaurus",   rarity="Epic",      damage=1.8e13,coinMultiplier=16000.0, world="Dino"},
        {id="dino_t_rex",      name="T-Rex",           rarity="Legendary", damage=6e13, coinMultiplier=22000.0, world="Dino"},
        {id="dino_spinosaurus",name="Spinosaurus",     rarity="Mythical",  damage=2e14, coinMultiplier=32000.0, world="Dino"},
        -- Extra heaven
        {id="heaven_putti",    name="Putti",           rarity="Uncommon",  damage=2e10,  coinMultiplier=4000.0, world="Heaven"},
        {id="heaven_archangel",name="Archangel",       rarity="Legendary", damage=4e11,  coinMultiplier=20000.0,world="Heaven"},
        -- Robot world pets
        {id="robot_drone",     name="Patrol Drone",    rarity="Common",    damage=4e13, coinMultiplier=80000.0,  world="Robot"},
        {id="robot_servitor",  name="Servitor Bot",    rarity="Uncommon",  damage=1e14, coinMultiplier=100000.0, world="Robot"},
        {id="robot_mech",      name="War Mech",        rarity="Rare",      damage=3e14, coinMultiplier=140000.0, world="Robot"},
        {id="robot_titan",     name="Titan Bot",       rarity="Epic",      damage=9e14, coinMultiplier=200000.0, world="Robot"},
        {id="robot_overmind",  name="Overmind",        rarity="Legendary", damage=3e15, coinMultiplier=300000.0, world="Robot"},
        {id="robot_megabot",   name="Mega Bot",        rarity="Mythical",  damage=1e16, coinMultiplier=450000.0, world="Robot"},
        -- Extra void
        {id="void_shadow",     name="Shadow Hound",    rarity="Uncommon",  damage=4e11, coinMultiplier=18000.0, world="Void"},
        {id="void_eldritch",   name="Eldritch Watcher",rarity="Epic",      damage=2e12, coinMultiplier=42000.0, world="Void"},
        -- Underworld pets
        {id="under_imp",       name="Hell Imp",        rarity="Common",    damage=2e15, coinMultiplier=400000.0,  world="Underworld"},
        {id="under_hound",     name="Hellhound",       rarity="Uncommon",  damage=5e15, coinMultiplier=500000.0,  world="Underworld"},
        {id="under_wraith",    name="Lava Wraith",     rarity="Rare",      damage=1.5e16,coinMultiplier=650000.0, world="Underworld"},
        {id="under_devil",     name="Devil Knight",    rarity="Epic",      damage=4.5e16,coinMultiplier=900000.0, world="Underworld"},
        {id="under_demon_king",name="Demon King",      rarity="Legendary", damage=1.5e17,coinMultiplier=1.4e6,    world="Underworld"},
        {id="under_lord",      name="Underworld Lord", rarity="Mythical",  damage=5e17,  coinMultiplier=2.2e6,    world="Underworld"},
        {id="under_satan",     name="The Adversary",   rarity="Secret",    damage=2e18,  coinMultiplier=4e6,      world="Underworld"},
        -- Extra cosmic
        {id="cosmic_quasar",   name="Quasar Pup",      rarity="Mythical",  damage=2e14, coinMultiplier=8e5, world="Cosmic"},
        {id="cosmic_singularity",name="Singularity",   rarity="Divine",    damage=1.5e16,coinMultiplier=8e6, world="Cosmic"},
        -- Eternity pets (endgame)
        {id="eternity_chronos",name="Chronos",         rarity="Legendary", damage=5e18, coinMultiplier=4e7, world="Eternity"},
        {id="eternity_nyx",    name="Nyx",             rarity="Mythical",  damage=2e19, coinMultiplier=1e8, world="Eternity"},
        {id="eternity_void",   name="Eternal Void",    rarity="Secret",    damage=1e20, coinMultiplier=4e8, world="Eternity"},
        {id="eternity_aeon",   name="Aeon",            rarity="Divine",    damage=5e20, coinMultiplier=1.5e9,world="Eternity"},
        {id="eternity_omega",  name="Omega",           rarity="Exclusive", damage=2e21, coinMultiplier=5e9, world="Eternity"},
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
            {id="cosmic_quasar",weight=10},{id="cosmic_singularity",weight=0.5},
        }},
        -- Expansion eggs
        {id="egg_jungle", name="Jungle Egg", world="Jungle", cost=2500, currency="coins", hugeChance=1/5e6, hugePool={"huge_jungle_tiger"}, pets={
            {id="jungle_monkey",weight=60},{id="jungle_parrot",weight=40},{id="jungle_panther",weight=15},
            {id="jungle_anaconda",weight=5},{id="jungle_jaguar",weight=0.8},{id="jungle_tiger",weight=0.1},
        }},
        {id="egg_desert", name="Desert Egg", world="Desert", cost=1e6, currency="coins", hugeChance=1/5e6, hugePool={"huge_sun_serpent"}, pets={
            {id="desert_camel",weight=60},{id="desert_lizard",weight=30},{id="desert_scorpion",weight=10},
            {id="desert_meerkat",weight=4},{id="desert_jinn",weight=0.7},{id="desert_serpent",weight=0.08},
        }},
        {id="egg_pirate", name="Pirate Egg", world="Pirate", cost=1e8, currency="coins", hugeChance=1/5e6, hugePool={"huge_pirate_lord"}, pets={
            {id="pirate_parrot",weight=55},{id="pirate_crab",weight=25},{id="pirate_skeleton",weight=10},
            {id="pirate_captain",weight=4},{id="pirate_ghost_ship",weight=0.8},{id="pirate_lord",weight=0.08},
        }},
        {id="egg_steam", name="Steampunk Egg", world="Steam", cost=1e10, currency="coins", hugeChance=1/5e6, hugePool={"huge_steam_titan"}, pets={
            {id="steam_cogling",weight=55},{id="steam_clockmouse",weight=25},{id="steam_brassbull",weight=10},
            {id="steam_zeppelin",weight=4},{id="steam_inventor",weight=0.8},{id="steam_titan",weight=0.08},
        }},
        {id="egg_mushroom", name="Mushroom Egg", world="Mushroom", cost=1e12, currency="coins", hugeChance=1/5e6, hugePool={"huge_mushroom_god"}, pets={
            {id="mush_sporeling",weight=55},{id="mush_toadstool",weight=25},{id="mush_psilo",weight=10},
            {id="mush_fungal",weight=4},{id="mush_grandfungus",weight=0.8},{id="mush_god",weight=0.08},
        }},
        {id="egg_faerie", name="Faerie Egg", world="Faerie", cost=1e14, currency="coins", hugeChance=1/5e6, hugePool={"huge_faerie_queen"}, pets={
            {id="faerie_pixie",weight=55},{id="faerie_sprite",weight=25},{id="faerie_unicorn",weight=10},
            {id="faerie_pegasus",weight=4},{id="faerie_alicorn",weight=0.8},{id="faerie_queen",weight=0.08},
        }},
        {id="egg_crystal", name="Crystal Egg", world="Crystal", cost=1e16, currency="coins", hugeChance=1/5e6, hugePool={"huge_crystal_dragon"}, pets={
            {id="crystal_shard",weight=55},{id="crystal_geode",weight=25},{id="crystal_prism",weight=10},
            {id="crystal_diamond",weight=4},{id="crystal_rainbow",weight=0.8},{id="crystal_overlord",weight=0.08},
        }},
        {id="egg_storm", name="Storm Egg", world="Storm", cost=1e18, currency="coins", hugeChance=1/5e6, hugePool={"huge_storm_god"}, pets={
            {id="storm_breeze",weight=55},{id="storm_thunder",weight=25},{id="storm_cyclone",weight=10},
            {id="storm_lightning",weight=4},{id="storm_typhoon",weight=0.8},{id="storm_god",weight=0.08},
        }},
        {id="egg_dino", name="Dino Egg", world="Dino", cost=1e20, currency="coins", hugeChance=1/5e6, hugePool={"huge_t_rex"}, pets={
            {id="dino_compy",weight=55},{id="dino_raptor",weight=25},{id="dino_steg",weight=10},
            {id="dino_brachio",weight=4},{id="dino_t_rex",weight=0.8},{id="dino_spinosaurus",weight=0.08},
        }},
        {id="egg_robot", name="Robot Egg", world="Robot", cost=1e22, currency="coins", hugeChance=1/5e6, hugePool={"huge_mega_robot"}, pets={
            {id="robot_drone",weight=55},{id="robot_servitor",weight=25},{id="robot_mech",weight=10},
            {id="robot_titan",weight=4},{id="robot_overmind",weight=0.8},{id="robot_megabot",weight=0.08},
        }},
        {id="egg_underworld", name="Underworld Egg", world="Underworld", cost=2000, currency="gems", hugeChance=1/2e6, hugePool={"huge_underworld_lord"}, pets={
            {id="under_imp",weight=50},{id="under_hound",weight=25},{id="under_wraith",weight=10},
            {id="under_devil",weight=4},{id="under_demon_king",weight=0.8},{id="under_lord",weight=0.1},
            {id="under_satan",weight=0.005},
        }},
        {id="egg_eternity", name="Eternity Egg", world="Eternity", cost=50000, currency="gems", hugeChance=1/1e6, hugePool={"huge_eternal"}, pets={
            {id="eternity_chronos",weight=20},{id="eternity_nyx",weight=5},
            {id="eternity_void",weight=0.5},{id="eternity_aeon",weight=0.05},{id="eternity_omega",weight=0.005},
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
    TeleportToWorld   = getOrCreate(remotesFolder, "RemoteEvent",    "TeleportToWorld"),
    GetPlayerData     = getOrCreate(remotesFolder, "RemoteFunction", "GetPlayerData"),
    IsAdmin           = getOrCreate(remotesFolder, "RemoteFunction", "IsAdmin"),
}

return Shared
