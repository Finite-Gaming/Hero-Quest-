---
-- @classmod ContentHelper
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local ContentHelperConstants = require("ContentHelperConstants")

local RunService = game:GetService("RunService")

local VALID_CLASSES = {
    Model = true;
    Folder = true;
    Terrain = true;
    Animation = true;
    Decal = true;
    Sound = true;
    Texture = true;
    SurfaceAppearance = true;
    MaterialVariant = true;

    ImageButton = true;
    ImageLabel = true;

    MeshPart = true;
    Mesh = true;
}

local SERVICES = {
    workspace;
    game:GetService("Lighting");
    game:GetService("MaterialService");
    game:GetService("ReplicatedFirst");
    game:GetService("ReplicatedStorage");
    game:GetService("StarterGui");
    game:GetService("StarterPack");
    game:GetService("SoundService");
}

local ContentHelper = {}

function ContentHelper:Init()
    self._remoteFunction = Network:GetRemoteFunction(ContentHelperConstants.REMOTE_FUNCTION_NAME)

    if RunService:IsServer() then
        self._assetCount = self:GetAssetCount()

        function self._remoteFunction.OnServerInvoke()
            return self._assetCount
        end
    end
end

function ContentHelper:GetServerTotal()
    if not self._serverTotal then
        self._serverTotal = self._remoteFunction:InvokeServer()
    end

    return self._serverTotal
end

function ContentHelper:_validateObj(obj)
    return VALID_CLASSES[obj.ClassName]
end

function ContentHelper:GetAllAssets()
    local assets = {}

    for _, service in ipairs(SERVICES) do
        for _, obj in ipairs(service:GetChildren()) do
            if self:_validateObj(obj) then
                table.insert(assets, obj)
            end
        end
    end

    return assets
end

function ContentHelper:GetAssetCount()
    local assetCount = 0

    for _, service in ipairs(SERVICES) do
        for _, obj in ipairs(service:GetChildren()) do
            if self:_validateObj(obj) then
                assetCount += 1
            end
        end
    end

    return assetCount
end

return ContentHelper