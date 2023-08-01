---
-- @classmod CameraTrigger
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ClientClassBinders = require("ClientClassBinders")
local CaptionShowcaseClient = require("CaptionShowcaseClient")
local UserDataClient = require("UserDataClient")

local IS_NEW_PLAYER = not UserDataClient:HasPlayedDungeon()

local CameraTrigger = setmetatable({}, BaseObject)
CameraTrigger.__index = CameraTrigger

function CameraTrigger.new(obj)
    local self = setmetatable(BaseObject.new(obj), CameraTrigger)

    self._triggerPart = self._obj:WaitForChild("Trigger")
    self._posAttachment = self._triggerPart:WaitForChild("CameraPosition")
    self._targetValue = self._obj:WaitForChild("Target")

    self._triggerPart.Transparency = 1

    if IS_NEW_PLAYER then
        self._clientZone = ClientClassBinders.ClientZone:BindAsync(self._triggerPart)
        self._maid:AddTask(self._clientZone.Touched:Connect(function(hitPart, character)
            if self._touched then
                ClientClassBinders.ClientZone:Unbind(self._triggerPart)
                return
            end

            CaptionShowcaseClient:Showcase(
                self._posAttachment.WorldPosition,
                self._targetValue.Value.Position,
                self._obj:GetAttribute("CaptionText"),
                self._obj:GetAttribute("DisplayTime"),
                self._obj:GetAttribute("ReadSpeed")
            )
        end))
    end

    return self
end

return CameraTrigger