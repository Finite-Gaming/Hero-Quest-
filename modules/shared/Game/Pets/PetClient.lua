---
-- @classmod PetClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local AlignCFrame = require("AlignCFrame")
local Raycaster = require("Raycaster")
local PetConstants = require("PetConstants")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PET_OFFSET = CFrame.new(3, 0, 1)
local IDLE_OFFSET = CFrame.new(0, 2.2, 0) -- these should be defined as values under the pet later on

local PetClient = setmetatable({}, BaseObject)
PetClient.__index = PetClient

function PetClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), PetClient)

    self._ownerValue = self._obj:WaitForChild(PetConstants.OWNER_VALUE_NAME)
    if self._ownerValue.Value ~= Players.LocalPlayer then
        return
    end

    self._character = assert(Players.LocalPlayer.Character)
    self._rootPart = self._character:WaitForChild("HumanoidRootPart")

    self._raycaster = Raycaster.new(nil, function(raycastResult)
        local character = raycastResult.Instance:FindFirstChildWhichIsA("Model")
        if not character then
            return false
        end

        if Players:FindFirstChild(character.Name) then
            return true
        end
    end)
    self._raycaster:Ignore({self._character, workspace.Terrain.Pets})

    self._hitbox = self._obj:WaitForChild("Hitbox")

    self._att0, self._att1 = self._maid:AddTask(Instance.new("Attachment")), self._maid:AddTask(Instance.new("Attachment"))

    self._att1.CFrame = self._hitbox.CFrame

    self._att0.Parent = self._hitbox
    self._att1.Parent = workspace.Terrain

    self._alignCFrame = AlignCFrame.new(self._att0, self._att1)
    self._alignCFrame.Responsiveness = 20

    self._alignCFrame.Parent = self._hitbox
    self._update = self._updateGround-- dont forget to change based on walk type (attribute)

    self._maid:AddTask(RunService.Heartbeat:Connect(function()
        self:_update()
    end))
    self._alignCFrame.Enabled = true

    return self
end

function PetClient:_updateGround()
    local rootCFrame = self._rootPart.CFrame
    local raycastResult = self._raycaster:Cast((rootCFrame * PET_OFFSET).Position, -Vector3.yAxis * 8)
    local petPosition

    if raycastResult then
        petPosition = raycastResult.Position
    else
        petPosition = (rootCFrame * IDLE_OFFSET).Position
    end

    petPosition += Vector3.new(0, self._hitbox.Size.Y/2, 0)
    self._att1.CFrame = CFrame.lookAt(petPosition, petPosition + rootCFrame.LookVector)
end

return PetClient