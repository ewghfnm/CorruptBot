--[[
    PetFollow.lua
    Local-only visual rendering of equipped pets following the player.
    Reads PlayerData and spawns simple colored parts (or a model from
    ReplicatedStorage.PetModels[petId] if present) that orbit/follow the character.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetDatabase = require(Shared.PetDatabase)
local Rarities = require(Shared.Rarities)

local script = script
local PlayerData = require(script.Parent.PlayerData)

local LocalPlayer = Players.LocalPlayer

local PetFollow = {}
local rendered = {} -- [uid] = Model

local function buildPetModel(pet, def)
    local existingTemplate = ReplicatedStorage:FindFirstChild("PetModels")
    if existingTemplate then
        local t = existingTemplate:FindFirstChild(pet.id)
        if t then return t:Clone() end
    end
    local r = Rarities.GetByName(def.rarity) or {color = Color3.new(1,1,1)}
    local model = Instance.new("Model")
    model.Name = "ClientPet_" .. pet.uid
    local part = Instance.new("Part")
    part.Size = pet.tier == "Standard" and Vector3.new(2,2,2) or Vector3.new(2.5, 2.5, 2.5)
    if def.rarity == "Huge" then part.Size = Vector3.new(8, 8, 8) end
    part.Color = r.color
    part.Material = Enum.Material.Neon
    part.Anchored = true
    part.CanCollide = false
    part.Massless = true
    part.Parent = model
    model.PrimaryPart = part
    return model
end

local function clearAll()
    for _, m in pairs(rendered) do
        if m.Parent then m:Destroy() end
    end
    rendered = {}
end

PlayerData.Changed:Connect(function(d)
    if not d then return end
    -- Destroy stale ones
    local equippedById = {}
    for _, p in ipairs(d.pets or {}) do
        if p.equipped then equippedById[p.uid] = p end
    end
    for uid, m in pairs(rendered) do
        if not equippedById[uid] then
            m:Destroy(); rendered[uid] = nil
        end
    end
    -- Spawn new ones
    for uid, p in pairs(equippedById) do
        if not rendered[uid] then
            local def = PetDatabase.GetById(p.id)
            if def then
                local model = buildPetModel(p, def)
                model.Parent = workspace
                rendered[uid] = model
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local i = 0
    local count = 0
    for _ in pairs(rendered) do count += 1 end
    if count == 0 then return end
    local now = tick()
    for _, model in pairs(rendered) do
        i += 1
        local angle = (i / count) * math.pi * 2 + now * 0.5
        local r = 5
        local pos = hrp.Position + Vector3.new(math.cos(angle) * r, 1, math.sin(angle) * r)
        if model.PrimaryPart then
            model:PivotTo(CFrame.new(pos))
        end
    end
end)

LocalPlayer.CharacterRemoving:Connect(clearAll)

return PetFollow
