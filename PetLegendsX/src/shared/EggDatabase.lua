--[[
    EggDatabase.lua
    Each egg has a list of {petId, weight} entries. Higher weight = more common.
    Total weight does not need to sum to anything specific; it's normalized.
    `hugeChance` is a flat % roll BEFORE the normal table; if it hits, picks a random Huge pet from `hugePool`.
]]

local Eggs = {
    {
        id = "egg_meadow",
        name = "Meadow Egg",
        world = "Meadow",
        cost = 100,
        currency = "coins",
        hugeChance = 1 / 5e6, -- 1 in 5,000,000
        hugePool = {"huge_meadow_dog"},
        pets = {
            {id = "meadow_dog",     weight = 60},
            {id = "meadow_cat",     weight = 60},
            {id = "meadow_bunny",   weight = 25},
            {id = "meadow_fox",     weight = 10},
            {id = "meadow_bear",    weight = 4},
            {id = "meadow_dragon",  weight = 0.9},
            {id = "meadow_unicorn", weight = 0.1},
        },
    },
    {
        id = "egg_candy",
        name = "Candy Egg",
        world = "Candy",
        cost = 5000,
        currency = "coins",
        hugeChance = 1 / 5e6,
        hugePool = {"huge_candy_king"},
        pets = {
            {id = "candy_gummy",   weight = 60},
            {id = "candy_lolli",   weight = 25},
            {id = "candy_choco",   weight = 10},
            {id = "candy_donut",   weight = 4},
            {id = "candy_cupcake", weight = 0.9},
            {id = "candy_king",    weight = 0.1},
        },
    },
    {
        id = "egg_cyber",
        name = "Cyber Egg",
        world = "Cyber",
        cost = 250000,
        currency = "coins",
        hugeChance = 1 / 5e6,
        hugePool = {"huge_cyber_overlord"},
        pets = {
            {id = "cyber_drone",    weight = 60},
            {id = "cyber_bot",      weight = 25},
            {id = "cyber_hacker",   weight = 10},
            {id = "cyber_mech",     weight = 4},
            {id = "cyber_ai",       weight = 0.9},
            {id = "cyber_overlord", weight = 0.1},
        },
    },
    {
        id = "egg_volcano",
        name = "Volcano Egg",
        world = "Volcano",
        cost = 10e6,
        currency = "coins",
        hugeChance = 1 / 5e6,
        hugePool = {"huge_phoenix"},
        pets = {
            {id = "volcano_imp",     weight = 50},
            {id = "volcano_phoenix", weight = 25},
            {id = "volcano_demon",   weight = 10},
            {id = "volcano_titan",   weight = 1},
            {id = "volcano_god",     weight = 0.05},
        },
    },
    {
        id = "egg_ocean",
        name = "Ocean Egg",
        world = "Ocean",
        cost = 5e8,
        currency = "coins",
        hugeChance = 1 / 5e6,
        hugePool = {"huge_kraken"},
        pets = {
            {id = "ocean_fish",      weight = 50},
            {id = "ocean_shark",     weight = 25},
            {id = "ocean_kraken",    weight = 5},
            {id = "ocean_leviathan", weight = 0.5},
        },
    },
    {
        id = "egg_cosmic",
        name = "Cosmic Egg",
        world = "Cosmic",
        cost = 50,
        currency = "gems",
        hugeChance = 1 / 1e6,
        hugePool = {"huge_creator"},
        pets = {
            {id = "cosmic_nebula",    weight = 30},
            {id = "cosmic_blackhole", weight = 1},
            {id = "cosmic_universe",  weight = 0.1},
            {id = "cosmic_creator",   weight = 0.01},
        },
    },
}

local byId = {}
for _, e in ipairs(Eggs) do byId[e.id] = e end

local M = {}
M.List = Eggs

function M.GetById(id) return byId[id] end

return M
