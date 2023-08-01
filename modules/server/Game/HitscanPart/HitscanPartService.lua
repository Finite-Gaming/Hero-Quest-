---
-- @classmod HitscanPartService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerClassBinders = require("ServerClassBinders")
local ServerTemplateProvider = require("ServerTemplateProvider")

local HitscanPartService = {}

function HitscanPartService:Init()
    self._folder = workspace:FindFirstChild("HitscanParts")
    if not self._folder then
        self._folder = Instance.new("Folder")
        self._folder.Name = "HitscanParts"
        self._folder.Parent = workspace
    end
end

function HitscanPartService:_addPart(part, properties, damageRange, lifetime, hitWindow)
    damageRange = damageRange or NumberRange.new(10, 10)
    lifetime = lifetime or 1
    hitWindow = hitWindow or 0.2

    part.CanCollide = false
    part.Anchored = true
    part.CanQuery = false
    part.CanTouch = false

    for property, value in pairs(properties) do
        if property == "Transparency" then
            continue
        end

        part[property] = value
    end

    part.Transparency = 1

    part:SetAttribute("TargetTransparency", properties.Transparency or 0)
    part:SetAttribute("Lifetime", workspace:GetServerTimeNow() + lifetime)
    part:SetAttribute("HitWindow", hitWindow)
    part:SetAttribute("Damage", damageRange)

    ServerClassBinders.HitscanPart:Bind(part)

    part.Parent = self._folder

    task.delay(lifetime, function()
        part:Destroy()
    end)
end

function HitscanPartService:Add(...)
    self:_addPart(Instance.new("Part"), ...)
end

function HitscanPartService:AddPattern(presetName, ...)
    local part = ServerTemplateProvider:Get(("Hitscan_%sTemplate"):format(presetName))
    self:_addPart(part, ...)
end

return HitscanPartService