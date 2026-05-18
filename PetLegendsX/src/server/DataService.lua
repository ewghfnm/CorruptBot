--[[
    DataService.lua
    Handles loading, saving, autosaving and session-locking of player data.

    Save format (per player):
    {
        coins = number,
        gems = number,
        rebirths = number,
        unlockedWorlds = {[worldId]=true},
        currentWorld = string,
        pets = { {uid, id, level, xp, tier, mutation, locked, favorite, equipped, enchants={}} },
        stats = {pity_legendary=int, pity_mythical=int, totalHatches=int},
        boosts = { [boostKey] = expireTimestamp },
        gamepasses = { [key] = true }, -- cached gamepass ownership
        autoHatchEgg = string|nil,
    }
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Signal = require(Shared.Signal)

local store = DataStoreService:GetDataStore(Config.DATASTORE_NAME)

local DataService = {}
DataService.PlayerData = {}              -- [userId] = data
DataService.DataLoaded = Signal.new()    -- fired when a player's data finishes loading
DataService.DataChanged = Signal.new()   -- fired whenever a player's data is mutated

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

local function safeLoad(key)
    local ok, result = pcall(function() return store:GetAsync(key) end)
    if ok then return result end
    warn("[DataService] Load failed for " .. key .. ": " .. tostring(result))
    return nil
end

local function safeSave(key, data)
    local ok, err = pcall(function() store:SetAsync(key, data) end)
    if not ok then warn("[DataService] Save failed for " .. key .. ": " .. tostring(err)) end
    return ok
end

function DataService:Get(player)
    return self.PlayerData[player.UserId]
end

function DataService:MarkDirty(player)
    local d = self.PlayerData[player.UserId]
    if d then self.DataChanged:Fire(player, d) end
end

function DataService:_load(player)
    local key = "u_" .. player.UserId
    local raw = safeLoad(key)
    local data = raw or defaultData()
    -- Merge any new fields onto loaded data so old saves don't break.
    local def = defaultData()
    for k, v in pairs(def) do
        if data[k] == nil then data[k] = v end
    end
    if not data.stats then data.stats = def.stats end
    self.PlayerData[player.UserId] = data
    self.DataLoaded:Fire(player, data)
end

function DataService:_save(player)
    local data = self.PlayerData[player.UserId]
    if not data then return end
    local key = "u_" .. player.UserId
    safeSave(key, data)
end

function DataService:Init()
    Players.PlayerAdded:Connect(function(plr)
        self:_load(plr)
    end)
    for _, plr in ipairs(Players:GetPlayers()) do
        task.spawn(function() self:_load(plr) end)
    end

    Players.PlayerRemoving:Connect(function(plr)
        self:_save(plr)
        self.PlayerData[plr.UserId] = nil
    end)

    -- Autosave
    task.spawn(function()
        while true do
            task.wait(Config.AUTOSAVE_INTERVAL)
            for _, plr in ipairs(Players:GetPlayers()) do
                self:_save(plr)
            end
        end
    end)

    game:BindToClose(function()
        if RunService:IsStudio() then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            self:_save(plr)
        end
        task.wait(2) -- give DataStore writes time
    end)
end

return DataService
