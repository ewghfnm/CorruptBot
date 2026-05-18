--[[
    PetDatabase.lua
    Defines every pet in the game. Add as many as you want here.
    `id` must be unique. `damage` and `coinMultiplier` are base stats.
    `model` is optional and points to a model name in ReplicatedStorage.PetModels.
]]

local Pets = {
    -- ============= MEADOW =============
    {id = "meadow_dog",      name = "Meadow Dog",      rarity = "Common",    damage = 1,    coinMultiplier = 1.0,  world = "Meadow"},
    {id = "meadow_cat",      name = "Meadow Cat",      rarity = "Common",    damage = 1.2,  coinMultiplier = 1.0,  world = "Meadow"},
    {id = "meadow_bunny",    name = "Bunny",           rarity = "Uncommon",  damage = 2,    coinMultiplier = 1.1,  world = "Meadow"},
    {id = "meadow_fox",      name = "Sly Fox",         rarity = "Rare",      damage = 5,    coinMultiplier = 1.2,  world = "Meadow"},
    {id = "meadow_bear",     name = "Brave Bear",      rarity = "Epic",      damage = 12,   coinMultiplier = 1.5,  world = "Meadow"},
    {id = "meadow_dragon",   name = "Meadow Dragon",   rarity = "Legendary", damage = 35,   coinMultiplier = 2.0,  world = "Meadow"},
    {id = "meadow_unicorn",  name = "Mystic Unicorn",  rarity = "Mythical",  damage = 100,  coinMultiplier = 3.0,  world = "Meadow"},

    -- ============= CANDY KINGDOM =============
    {id = "candy_gummy",     name = "Gummy Bear",      rarity = "Common",    damage = 6,    coinMultiplier = 1.5,  world = "Candy"},
    {id = "candy_lolli",     name = "Lollipop Pup",    rarity = "Uncommon",  damage = 12,   coinMultiplier = 1.6,  world = "Candy"},
    {id = "candy_choco",     name = "Chocolate Wolf",  rarity = "Rare",      damage = 25,   coinMultiplier = 1.8,  world = "Candy"},
    {id = "candy_donut",     name = "Donut Dragon",    rarity = "Epic",      damage = 60,   coinMultiplier = 2.2,  world = "Candy"},
    {id = "candy_cupcake",   name = "Cupcake Phoenix", rarity = "Legendary", damage = 180,  coinMultiplier = 3.0,  world = "Candy"},
    {id = "candy_king",      name = "Candy King",      rarity = "Mythical",  damage = 500,  coinMultiplier = 4.5,  world = "Candy"},

    -- ============= CYBER CITY =============
    {id = "cyber_drone",     name = "Cyber Drone",     rarity = "Common",    damage = 30,   coinMultiplier = 2.0,  world = "Cyber"},
    {id = "cyber_bot",       name = "Neon Bot",        rarity = "Uncommon",  damage = 60,   coinMultiplier = 2.2,  world = "Cyber"},
    {id = "cyber_hacker",    name = "Hacker Cat",      rarity = "Rare",      damage = 130,  coinMultiplier = 2.5,  world = "Cyber"},
    {id = "cyber_mech",      name = "Battle Mech",     rarity = "Epic",      damage = 300,  coinMultiplier = 3.2,  world = "Cyber"},
    {id = "cyber_ai",        name = "Rogue AI",        rarity = "Legendary", damage = 900,  coinMultiplier = 4.5,  world = "Cyber"},
    {id = "cyber_overlord",  name = "Cyber Overlord",  rarity = "Mythical",  damage = 2500, coinMultiplier = 6.0,  world = "Cyber"},

    -- ============= VOLCANO =============
    {id = "volcano_imp",     name = "Lava Imp",        rarity = "Rare",      damage = 700,    coinMultiplier = 4.0,  world = "Volcano"},
    {id = "volcano_phoenix", name = "Phoenix",         rarity = "Epic",      damage = 1800,   coinMultiplier = 5.0,  world = "Volcano"},
    {id = "volcano_demon",   name = "Magma Demon",     rarity = "Legendary", damage = 5000,   coinMultiplier = 6.5,  world = "Volcano"},
    {id = "volcano_titan",   name = "Inferno Titan",   rarity = "Mythical",  damage = 14000,  coinMultiplier = 9.0,  world = "Volcano"},
    {id = "volcano_god",     name = "God of Fire",     rarity = "Secret",    damage = 80000,  coinMultiplier = 20.0, world = "Volcano"},

    -- ============= OCEAN =============
    {id = "ocean_fish",      name = "Tropical Fish",   rarity = "Uncommon",  damage = 4000,    coinMultiplier = 7.0,  world = "Ocean"},
    {id = "ocean_shark",     name = "Hammer Shark",    rarity = "Rare",      damage = 12000,   coinMultiplier = 9.0,  world = "Ocean"},
    {id = "ocean_kraken",    name = "Kraken",          rarity = "Legendary", damage = 50000,   coinMultiplier = 14.0, world = "Ocean"},
    {id = "ocean_leviathan", name = "Leviathan",       rarity = "Mythical",  damage = 150000,  coinMultiplier = 22.0, world = "Ocean"},

    -- ============= FROZEN PEAKS =============
    {id = "frozen_penguin",  name = "Frost Penguin",   rarity = "Rare",      damage = 80000,    coinMultiplier = 18.0, world = "Frozen"},
    {id = "frozen_yeti",     name = "Yeti",            rarity = "Epic",      damage = 200000,   coinMultiplier = 25.0, world = "Frozen"},
    {id = "frozen_dragon",   name = "Ice Dragon",      rarity = "Legendary", damage = 600000,   coinMultiplier = 40.0, world = "Frozen"},
    {id = "frozen_queen",    name = "Frost Queen",     rarity = "Mythical",  damage = 1.8e6,    coinMultiplier = 60.0, world = "Frozen"},

    -- ============= EGYPT =============
    {id = "egypt_scarab",    name = "Golden Scarab",   rarity = "Rare",      damage = 1.2e6,   coinMultiplier = 50.0,  world = "Egypt"},
    {id = "egypt_anubis",    name = "Anubis Hound",    rarity = "Legendary", damage = 8e6,     coinMultiplier = 90.0,  world = "Egypt"},
    {id = "egypt_pharaoh",   name = "Pharaoh",         rarity = "Mythical",  damage = 3e7,     coinMultiplier = 140.0, world = "Egypt"},
    {id = "egypt_sphinx",    name = "Sphinx",          rarity = "Secret",    damage = 1.5e8,   coinMultiplier = 300.0, world = "Egypt"},

    -- ============= SPACE =============
    {id = "space_alien",     name = "Alien",           rarity = "Epic",      damage = 6e7,    coinMultiplier = 200.0, world = "Space"},
    {id = "space_astronaut", name = "Astro Pup",       rarity = "Legendary", damage = 2e8,    coinMultiplier = 350.0, world = "Space"},
    {id = "space_starbeast", name = "Star Beast",      rarity = "Mythical",  damage = 9e8,    coinMultiplier = 600.0, world = "Space"},

    -- ============= SAMURAI =============
    {id = "samurai_kitsune", name = "Kitsune",         rarity = "Legendary", damage = 1.2e9,  coinMultiplier = 900.0,  world = "Samurai"},
    {id = "samurai_dragon",  name = "Sakura Dragon",   rarity = "Mythical",  damage = 5e9,    coinMultiplier = 1500.0, world = "Samurai"},
    {id = "samurai_oni",     name = "Demon Oni",       rarity = "Secret",    damage = 2e10,   coinMultiplier = 4000.0, world = "Samurai"},

    -- ============= HEAVEN =============
    {id = "heaven_angel",    name = "Cherub",          rarity = "Mythical",  damage = 3e10,   coinMultiplier = 6000.0,  world = "Heaven"},
    {id = "heaven_seraph",   name = "Seraph",          rarity = "Divine",    damage = 1.5e11, coinMultiplier = 12000.0, world = "Heaven"},

    -- ============= VOID =============
    {id = "void_wraith",     name = "Void Wraith",     rarity = "Mythical", damage = 8e11,    coinMultiplier = 25000.0,  world = "Void"},
    {id = "void_lord",       name = "Void Lord",       rarity = "Secret",   damage = 4e12,    coinMultiplier = 60000.0,  world = "Void"},
    {id = "void_corrupted",  name = "Corrupted One",   rarity = "Divine",   damage = 2e13,    coinMultiplier = 150000.0, world = "Void"},

    -- ============= COSMIC =============
    {id = "cosmic_nebula",   name = "Nebula Beast",    rarity = "Mythical",  damage = 1e14, coinMultiplier = 4e5, world = "Cosmic"},
    {id = "cosmic_blackhole",name = "Black Hole",      rarity = "Secret",    damage = 8e14, coinMultiplier = 1e6, world = "Cosmic"},
    {id = "cosmic_universe", name = "Universe",        rarity = "Divine",    damage = 5e15, coinMultiplier = 4e6, world = "Cosmic"},
    {id = "cosmic_creator",  name = "The Creator",     rarity = "Exclusive", damage = 3e16, coinMultiplier = 1e7, world = "Cosmic"},

    -- ============= HUGE PETS (extremely rare, dedicated rarity) =============
    {id = "huge_meadow_dog",   name = "Huge Meadow Dog",  rarity = "Huge", damage = 1e8,  coinMultiplier = 1000,   world = "Meadow"},
    {id = "huge_candy_king",   name = "Huge Candy King",  rarity = "Huge", damage = 1e10, coinMultiplier = 10000,  world = "Candy"},
    {id = "huge_cyber_overlord",name = "Huge Cyber Overlord", rarity = "Huge", damage = 1e12, coinMultiplier = 1e5, world = "Cyber"},
    {id = "huge_phoenix",      name = "Huge Phoenix",     rarity = "Huge", damage = 1e14, coinMultiplier = 1e6,    world = "Volcano"},
    {id = "huge_kraken",       name = "Huge Kraken",      rarity = "Huge", damage = 1e16, coinMultiplier = 1e7,    world = "Ocean"},
    {id = "huge_creator",      name = "Huge Creator",     rarity = "Huge", damage = 1e18, coinMultiplier = 1e9,    world = "Cosmic"},

    -- ============= ADMIN =============
    {id = "admin_kiro",        name = "Admin Kiro",      rarity = "Admin", damage = 1e25, coinMultiplier = 1e15, world = "Admin"},
}

local byId = {}
for _, p in ipairs(Pets) do
    p.tier = "Standard" -- Default tier; mutations applied at runtime: Golden(2x), Rainbow(5x), DarkMatter(10x)
    byId[p.id] = p
end

local M = {}
M.List = Pets

function M.GetById(id)
    return byId[id]
end

function M.GetByWorld(world)
    local out = {}
    for _, p in ipairs(Pets) do
        if p.world == world then table.insert(out, p) end
    end
    return out
end

return M
