---
-- @classmod Pet
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local PetConstants = require("PetConstants")
local ModelUtils = require("ModelUtils")

local Pet = setmetatable({}, BaseObject)
Pet.__index = Pet

function Pet.new(obj)
    local self = setmetatable(BaseObject.new(obj), Pet)

    self._ownerValue = assert(self._obj:FindFirstChild(PetConstants.OWNER_VALUE_NAME))
    self._maid:AddTask(self._obj)

    for _, part in ipairs(ModelUtils.getParts(self._obj)) do
        part:SetNetworkOwner(self._ownerValue.Value)
    end

    self._maid:AddTask(self._ownerValue.Value.Character.AncestryChanged:Connect(function(_, newParent)
        if newParent == nil then
            self:Destroy()
        end
    end))

    self._animationFolder = self._obj:FindFirstChild("Animations")
    if self._animationFolder then
        self._animationController = self._obj:FindFirstChild("AnimationController")
        if not self._animationController then
            self._animationController = Instance.new("AnimationController")
            self._animationController.Parent = self._obj
        end

        local idleAnimation = self._animationFolder:FindFirstChild("Idle")
        if idleAnimation then
            local idleTrack = self._animationController:LoadAnimation(idleAnimation) -- wahjsaoo!!! DEPRECATED BAHA boowomp.mp3
            idleTrack:Play()
        end
    end

    return self
end

return Pet