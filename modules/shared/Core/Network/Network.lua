--- Provides remote events/functions
-- @classmod Network
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")

local NetworkConstants = require("NetworkConstants")

local Network = {}

if RunService:IsClient() then
    function Network:GetRemoteEvent(remoteEventName)
        return NetworkConstants.STORAGE_PARENT:WaitForChild(NetworkConstants.REMOTE_EVENT_FOLDER_NAME):WaitForChild(remoteEventName)
    end

    function Network:GetRemoteFunction(remoteFunctionName)
        return NetworkConstants.STORAGE_PARENT:WaitForChild(NetworkConstants.REMOTE_FUNCTION_FOLDER_NAME):WaitForChild(remoteFunctionName)
    end
else
    function Network:GetRemoteEvent(remoteEventName)
        local storageFolder = self:_getStorage(NetworkConstants.REMOTE_EVENT_FOLDER_NAME)
        local remoteEvent = storageFolder:FindFirstChild(remoteEventName)

        if not remoteEvent then
            remoteEvent = Instance.new("RemoteEvent")
            remoteEvent.Name = remoteEventName
            remoteEvent.Parent = storageFolder
        end

        return remoteEvent
    end

    function Network:GetRemoteFunction(remoteFunctionName)
        local storageFolder = self:_getStorage(NetworkConstants.REMOTE_FUNCTION_FOLDER_NAME)
        local remoteFunction = storageFolder:FindFirstChild(remoteFunctionName)

        if not remoteFunction then
            remoteFunction = Instance.new("RemoteFunction")
            remoteFunction.Name = remoteFunctionName
            remoteFunction.Parent = storageFolder
        end

        return remoteFunction
    end

    function Network:_getStorage(name)
        local storageFolder = NetworkConstants.STORAGE_PARENT:FindFirstChild(name)
        if not storageFolder then
            storageFolder = Instance.new("Folder")
            storageFolder.Name = name
            storageFolder.Parent = NetworkConstants.STORAGE_PARENT
        end

        return storageFolder
    end
end

return Network