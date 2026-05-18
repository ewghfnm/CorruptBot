--[[
    Config.lua
    Global tunables for Pet Legends X.
    Edit values here to balance the game.
]]

local Config = {}

-- Hatch animation/length
Config.HATCH_ANIMATION_TIME = 1.5

-- Pity system: guarantee a Mythical+ after this many consecutive non-Mythical hatches
Config.PITY_MYTHICAL_AFTER = 250
-- Pity system: guarantee a Legendary+ after this many consecutive non-Legendary hatches
Config.PITY_LEGENDARY_AFTER = 75

-- Currency starting values
Config.STARTING_COINS = 100
Config.STARTING_GEMS = 0

-- Pets
Config.MAX_EQUIPPED_PETS_DEFAULT = 3
Config.MAX_EQUIPPED_PETS_GAMEPASS = 6
Config.MAX_PET_LEVEL = 100
Config.PET_XP_PER_LEVEL = function(level) return 100 * level ^ 1.5 end

-- Rebirth
Config.REBIRTH_BASE_COST = 1e6
Config.REBIRTH_COST_SCALE = 2.5      -- cost = base * scale^rebirths
Config.REBIRTH_MULTIPLIER = 2.0      -- coin/damage multiplier per rebirth

-- Breaking
Config.BREAKABLE_RESPAWN_TIME = 8

-- Server announcements (rarity index >= this triggers a server-wide announcement)
Config.ANNOUNCE_RARITY_INDEX = 6 -- Mythical and above

-- Admin user IDs (replace with your real Roblox user IDs)
Config.ADMIN_USER_IDS = {
    -- 1234567890,
}
-- Admin usernames (case-insensitive). Easier than IDs while testing.
Config.ADMIN_USERNAMES = {
    -- "YourRobloxUsername",
}

-- DataStore
Config.DATASTORE_NAME = "PetLegendsX_Save_v1"
Config.AUTOSAVE_INTERVAL = 60 -- seconds

-- Auto hatch (gamepass) interval in seconds
Config.AUTO_HATCH_INTERVAL = 1.0

return Config
