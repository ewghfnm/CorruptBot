--[[
    GamepassService.lua
    Real ownership goes through MarketplaceService. The admin panel can also force-grant
    a gamepass for testing. Owned gamepasses are cached on player data.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GamepassDatabase = require(Shared.GamepassDatabase)
local Config = require(Shared.Config)

local GamepassService = {}
local DataService

function GamepassService:Init(deps)
    DataService = deps.DataService

    Players.PlayerAdded:Connect(function(plr) self:_refresh(plr) end)
    for _, plr in ipairs(Players:GetPlayers()) do task.spawn(function() self:_refresh(plr) end) end

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, gamepassId, purchased)
        if purchased then self:_refresh(plr) end
    end)
end

function GamepassService:_refresh(plr)
    local d = DataService:Get(plr); if not d then
        -- Wait for data to load
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
    -- ExtraEquip slot bonus
    if d.gamepasses.ExtraEquip then
        d.equippedSlots = Config.MAX_EQUIPPED_PETS_GAMEPASS
    end
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
    DataService:MarkDirty(plr)
    return true
end

function GamepassService:Revoke(plr, key)
    local d = DataService:Get(plr); if not d then return false end
    d.gamepasses[key] = nil
    if key == "ExtraEquip" then d.equippedSlots = Config.MAX_EQUIPPED_PETS_DEFAULT end
    DataService:MarkDirty(plr)
    return true
end

return GamepassService
