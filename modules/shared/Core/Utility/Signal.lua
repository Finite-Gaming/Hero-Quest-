--- Basic signal class
-- @classmod Signal
-- @author frick

local HttpService = game:GetService("HttpService")

local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)

    self._connections = {}
    self._tempConnections = {}

    return self
end

function Signal:Connect(func)
    local holder = {}
    local signal = self
    local id = HttpService:GenerateGUID()

    function holder:Disconnect()
        signal._connections[id] = nil
    end

    self._connections[id] = func

    return holder
end

function Signal:Once(func)
    self._tempConnections[#self._tempConnections + 1] = func
end

function Signal:Wait()
    local currentThread = coroutine.running()

    self:Once(function(...)
        coroutine.resume(currentThread, ...)
    end)

    return coroutine.yield()
end

function Signal:Fire(...)
    for i, v in pairs(self._tempConnections) do
        task.spawn(v, ...)

        self._tempConnections[i] = nil
    end

    for _, v in pairs(self._connections) do
        task.spawn(v, ...)
    end
end

function Signal:Destroy()
    setmetatable(self, nil)
end

return Signal