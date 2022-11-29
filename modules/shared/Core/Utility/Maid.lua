--- Maid class for managing things
-- @classmod Maid
-- @author frick

local ContextActionService = game:GetService("ContextActionService")

local Maid = {}

function Maid.new()
    local self = setmetatable({
        _tasks = {};
        _boundActions = {};
    }, Maid)

    return self
end

function Maid:AddTask(obj)
    table.insert(self._tasks, obj)
    return obj
end

function Maid:BindAction(name, ...)
    self._boundActions[name] = true
    ContextActionService:BindAction(name, ...)
end

function Maid:BindActionAtPriority(name, ...)
    self._boundActions[name] = true
    ContextActionService:BindActionAtPriority(name, ...)
end

function Maid:UnbindAction(name)
    self._boundActions[name] = nil
    ContextActionService:UnbindAction(name)
end

function Maid:Destroy()
    for actionName, _ in pairs(self._boundActions) do
        ContextActionService:UnbindAction(actionName)
    end

    for i, obj in pairs(self._tasks) do
        self:_cleanTask(obj)
        self._tasks[i] = nil
    end

    setmetatable(self, nil)
end

function Maid:_cleanTask(obj)
    if obj then
        local taskType = typeof(obj)

        if taskType == "function" then
            obj()
        elseif taskType == "Instance" or (taskType == "table" and obj.Destroy) then
            obj:Destroy()
        elseif taskType == "RBXScriptConnection" or (taskType == "table" and obj.Disconnect) then
            obj:Disconnect()
        elseif taskType == "thread" then
            task.cancel(obj)
        else
            warn(("[Maid] - Unknown task type %q, ignoring")
                :format(taskType), obj, tostring(obj), debug.traceback())
        end
    end
end

function Maid:__index(index)
    return Maid[index] or self._tasks[index]
end

function Maid:__newindex(index, obj)
    assert(not Maid[index], "Index reserved")
    local oldObj = self._tasks[index]

    if oldObj == obj then
        --warn("[Maid] - Attempt to overwrite with same task, ignoring", obj, debug.traceback())
        return
    end

    if oldObj then
        self:_cleanTask(oldObj)
    end

    self._tasks[index] = obj
end

return Maid