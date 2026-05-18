--[[
    Signal.lua
    Tiny event class used internally by services.
]]

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({_listeners = {}}, Signal)
end

function Signal:Connect(fn)
    table.insert(self._listeners, fn)
    local connected = true
    return {
        Disconnect = function()
            if not connected then return end
            connected = false
            for i, l in ipairs(self._listeners) do
                if l == fn then table.remove(self._listeners, i); break end
            end
        end,
    }
end

function Signal:Fire(...)
    for _, fn in ipairs(self._listeners) do
        task.spawn(fn, ...)
    end
end

return Signal
