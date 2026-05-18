--[[
    CurrencyService.lua
    Add/spend coins and gems. All currency mutations go through here so we have
    a single choke point for boosts/multipliers later.
]]

local CurrencyService = {}

local DataService

function CurrencyService:Init(deps)
    DataService = deps.DataService
end

local VALID = {coins = true, gems = true}

function CurrencyService:Get(player, currency)
    local d = DataService:Get(player)
    if not d then return 0 end
    return d[currency] or 0
end

function CurrencyService:Add(player, currency, amount)
    if not VALID[currency] then return false end
    if amount == nil or amount < 0 then return false end
    local d = DataService:Get(player); if not d then return false end
    d[currency] = (d[currency] or 0) + amount
    DataService:MarkDirty(player)
    return true
end

function CurrencyService:Spend(player, currency, amount)
    if not VALID[currency] then return false end
    if amount == nil or amount < 0 then return false end
    local d = DataService:Get(player); if not d then return false end
    if (d[currency] or 0) < amount then return false end
    d[currency] -= amount
    DataService:MarkDirty(player)
    return true
end

function CurrencyService:Set(player, currency, amount)
    if not VALID[currency] then return false end
    local d = DataService:Get(player); if not d then return false end
    d[currency] = math.max(0, amount)
    DataService:MarkDirty(player)
    return true
end

return CurrencyService
