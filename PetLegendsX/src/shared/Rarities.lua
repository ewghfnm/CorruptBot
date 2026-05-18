--[[
    Rarities.lua
    All pet rarities. Order matters: higher index = rarer.
    Includes the user-requested "Huge" rarity at the top.
]]

local Rarities = {
    -- index, name, color (RGB), glow color, label text color
    {name = "Common",     color = Color3.fromRGB(180, 180, 180), glow = Color3.fromRGB(255, 255, 255)},
    {name = "Uncommon",   color = Color3.fromRGB(100, 220, 100), glow = Color3.fromRGB(150, 255, 150)},
    {name = "Rare",       color = Color3.fromRGB(80, 140, 255),  glow = Color3.fromRGB(150, 200, 255)},
    {name = "Epic",       color = Color3.fromRGB(180, 80, 255),  glow = Color3.fromRGB(220, 150, 255)},
    {name = "Legendary",  color = Color3.fromRGB(255, 180, 50),  glow = Color3.fromRGB(255, 220, 100)},
    {name = "Mythical",   color = Color3.fromRGB(255, 80, 80),   glow = Color3.fromRGB(255, 150, 150)},
    {name = "Secret",     color = Color3.fromRGB(40, 40, 40),    glow = Color3.fromRGB(255, 0, 200)},
    {name = "Divine",     color = Color3.fromRGB(255, 240, 200), glow = Color3.fromRGB(255, 255, 255)},
    {name = "Exclusive",  color = Color3.fromRGB(255, 50, 200),  glow = Color3.fromRGB(255, 150, 255)},
    {name = "Huge",       color = Color3.fromRGB(255, 215, 0),   glow = Color3.fromRGB(255, 255, 0)},
    {name = "Admin",      color = Color3.fromRGB(255, 0, 0),     glow = Color3.fromRGB(255, 100, 100)},
}

local nameToIndex = {}
for i, r in ipairs(Rarities) do
    r.index = i
    nameToIndex[r.name] = i
end

local M = {}
M.List = Rarities

function M.GetByName(name)
    local i = nameToIndex[name]
    return i and Rarities[i] or nil
end

function M.GetByIndex(i)
    return Rarities[i]
end

function M.IsAtLeast(rarityName, thresholdName)
    local a = nameToIndex[rarityName]
    local b = nameToIndex[thresholdName]
    if not a or not b then return false end
    return a >= b
end

return M
