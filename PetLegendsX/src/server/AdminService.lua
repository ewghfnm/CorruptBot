--[[
    AdminService.lua
    Authoritative admin command handler. All commands are validated against the
    admin list in Config (UserIDs or usernames). NEVER trust the client-side admin flag.

    Supported commands (sent via Remotes.AdminCommand):
        {action="givePet",   target=<userId>, petId="meadow_dog", tier="Golden", mutation="shiny"}
        {action="giveCoins", target=<userId>, amount=1000}
        {action="giveGems",  target=<userId>, amount=100}
        {action="setCoins",  target=<userId>, amount=5e9}
        {action="setGems",   target=<userId>, amount=10000}
        {action="grantGamepass",  target=<userId>, key="VIP"}
        {action="revokeGamepass", target=<userId>, key="VIP"}
        {action="setRebirths",    target=<userId>, amount=50}
        {action="unlockAllWorlds",target=<userId>}
        {action="forceHatch",     target=<userId>, eggId="egg_meadow", count=10}
        {action="kick",     target=<userId>, reason="..."}
        {action="announce", message="..."}
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PetDatabase = require(Shared.PetDatabase)
local WorldDatabase = require(Shared.WorldDatabase)
local Remotes = require(Shared.Remotes)

local AdminService = {}
local DataService, CurrencyService, PetService, GamepassService, EggService, AnnouncementService

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

local function findPlayer(targetIdOrName)
    if type(targetIdOrName) == "number" then
        return Players:GetPlayerByUserId(targetIdOrName)
    end
    local lname = string.lower(tostring(targetIdOrName))
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.lower(plr.Name) == lname then return plr end
    end
end

function AdminService:Init(deps)
    DataService = deps.DataService
    CurrencyService = deps.CurrencyService
    PetService = deps.PetService
    GamepassService = deps.GamepassService
    EggService = deps.EggService
    AnnouncementService = deps.AnnouncementService

    Remotes.IsAdmin.OnServerInvoke = function(plr) return isAdmin(plr) end

    Remotes.AdminCommand.OnServerEvent:Connect(function(plr, cmd)
        if not isAdmin(plr) then
            warn("[AdminService] Non-admin attempted command: " .. plr.Name)
            return
        end
        if type(cmd) ~= "table" or type(cmd.action) ~= "string" then return end
        self:Handle(plr, cmd)
    end)
end

function AdminService:Handle(adminPlr, cmd)
    local target = cmd.target and findPlayer(cmd.target) or adminPlr
    local function notify(msg) Remotes.Notification:FireClient(adminPlr, "[Admin] " .. msg) end

    if cmd.action == "givePet" then
        if not target then return notify("Target not found.") end
        local def = PetDatabase.GetById(cmd.petId)
        if not def then return notify("Unknown pet id: " .. tostring(cmd.petId)) end
        PetService:GivePet(target, cmd.petId, {
            tier = cmd.tier or "Standard",
            mutation = cmd.mutation,
        })
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
        else
            notify("Unknown gamepass key: " .. tostring(cmd.key))
        end

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
        for i = 1, math.clamp(tonumber(cmd.count) or 1, 1, 50) do
            EggService:HandleHatchRequest(target, cmd.eggId, 1, true)
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

return AdminService
