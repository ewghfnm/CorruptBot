--[[
    BreakingService.lua
    Spawns breakable objects in Workspace.Breakables (one folder per world) and handles
    damage requests from clients. Drops coins (and rarely gems) when destroyed.

    Clients fire RequestBreakHit(breakableInstance) with no other args - server validates
    distance and rate. Damage is computed entirely server-side from PetService stats.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local WorldDatabase = require(Shared.WorldDatabase)

local BreakingService = {}
local PetService, CurrencyService, DataService

local BREAK_COOLDOWN = 0.10 -- max 10 hits/sec per player
local lastHit = setmetatable({}, {__mode = "k"})

local function ensureFolder(name, parent)
    local f = parent:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
    end
    return f
end

local function makeBreakable(world, position)
    local model = Instance.new("Model")
    model.Name = "Breakable"
    local part = Instance.new("Part")
    part.Name = "Hitbox"
    part.Size = Vector3.new(6, 6, 6)
    part.Position = position
    part.Anchored = true
    part.BrickColor = BrickColor.new("Bright orange")
    part.Material = Enum.Material.Wood
    part.Parent = model
    model.PrimaryPart = part

    local hpVal = Instance.new("NumberValue")
    hpVal.Name = "HP"
    -- HP scales with world coinMultiplier so higher worlds have tougher chests
    local wDef = WorldDatabase.GetById(world)
    hpVal.Value = 100 * (wDef and wDef.coinMultiplier or 1)
    hpVal.Parent = model

    local maxHpVal = Instance.new("NumberValue")
    maxHpVal.Name = "MaxHP"
    maxHpVal.Value = hpVal.Value
    maxHpVal.Parent = model

    local worldVal = Instance.new("StringValue")
    worldVal.Name = "World"
    worldVal.Value = world
    worldVal.Parent = model

    return model
end

function BreakingService:Init(deps)
    PetService = deps.PetService
    CurrencyService = deps.CurrencyService
    DataService = deps.DataService

    local rootFolder = ensureFolder("Breakables", Workspace)

    -- Spawn a few breakables for each world (stacked at simple coordinates).
    -- In production you'd place them by hand in Studio. Here we generate basics so the
    -- world is non-empty out of the box.
    for i, world in ipairs(WorldDatabase.List) do
        local wf = ensureFolder(world.id, rootFolder)
        if #wf:GetChildren() == 0 then
            for j = 1, 6 do
                local pos = Vector3.new(
                    (i - 1) * 200 + j * 10 - 30,
                    5,
                    0
                )
                local b = makeBreakable(world.id, pos)
                b.Parent = wf
            end
        end
    end

    Remotes.RequestBreakHit.OnServerEvent:Connect(function(plr, breakable)
        self:HandleHit(plr, breakable)
    end)

    -- Respawn loop
    task.spawn(function()
        while true do
            task.wait(2)
            for _, world in ipairs(WorldDatabase.List) do
                local wf = rootFolder:FindFirstChild(world.id)
                if wf and #wf:GetChildren() < 6 then
                    -- Fill missing
                    for j = 1, 6 - #wf:GetChildren() do
                        local pos = Vector3.new(
                            (world.order - 1) * 200 + j * 10 - 30 + math.random(-3, 3),
                            5,
                            math.random(-10, 10)
                        )
                        local b = makeBreakable(world.id, pos)
                        b.Parent = wf
                    end
                end
            end
        end
    end)
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
        if math.random() < 0.01 then
            CurrencyService:Add(player, "gems", 1)
        end
        PetService:AddXP(player, math.floor(5 * (wDef and wDef.coinMultiplier or 1)))
        breakable:Destroy()
    end
end

return BreakingService
