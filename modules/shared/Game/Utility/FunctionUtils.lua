---
-- @classmod FunctionUtils
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local FunctionUtils = {}

function FunctionUtils.rCallAPI(map, method, ...)
    local args = {...}
    return task.spawn(function()
        local tries = 0
        local success, err = pcall(map[method], map, unpack(args))

        while not success and tries < 5 do
            warn(("[rCallAPI Error] - %s"):format(err))
            success, err = pcall(map[method], map, unpack(args))
            tries += 1
            task.wait(0.5)
        end
    end)
end

function FunctionUtils.rCallAPIAsync(map, method, ...)
    local tries = 0
    local success, err = pcall(map[method], map, ...)

    while not success and tries < 5 do
        warn(("[rCallAPIAsync Error] - %s"):format(err))
        success, err = pcall(map[method], map, ...)
        tries += 1
        task.wait(0.5)
    end

    if not success then
        warn("bruh dang")
        return
    end

    return err
end

return FunctionUtils