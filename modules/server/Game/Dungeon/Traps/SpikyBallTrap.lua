---
-- @classmod SpikyBallTrap
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ServerClassBinders = require("ServerClassBinders")

local RunService = game:GetService("RunService")

local BURST_COUNT = 6
local SPREAD = 40
local FIRE_COOLDOWN = 1

local SpikyBallTrap = setmetatable({}, BaseObject)
SpikyBallTrap.__index = SpikyBallTrap

function SpikyBallTrap.new(obj)
    local self = setmetatable(BaseObject.new(obj), SpikyBallTrap)

    self._randomObject = Random.new()
    self._spreadAngle = math.rad(SPREAD)

    self._projectileOutputs = {}
    for _, attachment in ipairs(self._obj:GetDescendants()) do
        if not attachment:IsA("Attachment") then
            warn("not attachmetn ")
            continue
        end
        if attachment.Name ~= "ProjectileOutput" then
            warn("not output")
            continue
        end

        self._projectileOutputs[attachment] = ServerClassBinders.ProjectileOutput:BindAsync(attachment)
    end

    print("bound")
    self._lastFire = 0
    self._maid:AddTask(RunService.Heartbeat:Connect(function()
        local fireTime = os.clock()
        if fireTime - self._lastFire < FIRE_COOLDOWN then
            return
        end
        self._lastFire = fireTime

        self:Fire()
    end))

    return self
end

function SpikyBallTrap:Fire()
    for _ = 1, BURST_COUNT do
        for attachment, projectileOutput in pairs(self._projectileOutputs) do
            projectileOutput:FireGlobal(self:_getRandomDirection(attachment))
        end
    end
end

function SpikyBallTrap:_getRandomDirection(attachment)
    return -(attachment.WorldCFrame * CFrame.Angles(
		self._randomObject:NextNumber(-self._spreadAngle, self._spreadAngle),
		self._randomObject:NextNumber(-self._spreadAngle, self._spreadAngle),
		self._randomObject:NextNumber(-self._spreadAngle, self._spreadAngle)
	)).RightVector
end

return SpikyBallTrap