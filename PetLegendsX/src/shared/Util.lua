--[[
    Util.lua
    Misc helpers used by both server & client.
]]

local Util = {}

function Util.WeightedPick(entries, luckMultiplier)
    -- entries: {{id=..., weight=...}, ...}
    -- luckMultiplier: rare items (lower weight) get boosted weight
    luckMultiplier = luckMultiplier or 1
    local total = 0
    local adjusted = {}
    for _, e in ipairs(entries) do
        -- Boost rare items (low weight) more than common items
        local w = e.weight
        if luckMultiplier > 1 and w < 5 then
            w = w * luckMultiplier
        end
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

function Util.FormatNumber(n)
    if n == nil then return "0" end
    if n < 1000 then
        return tostring(math.floor(n))
    end
    local suffixes = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}
    local i = 0
    local v = n
    while v >= 1000 and i < #suffixes do
        v = v / 1000
        i = i + 1
    end
    return string.format("%.2f%s", v, suffixes[i] or "")
end

function Util.NewGuid()
    -- Compact unique-ish id
    local t = tostring(os.time())
    local r = tostring(math.random(0, 1e9))
    return t .. "_" .. r
end

function Util.Clamp(n, lo, hi)
    if n < lo then return lo end
    if n > hi then return hi end
    return n
end

function Util.DeepCopy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Util.DeepCopy(v) end
    return out
end

return Util
