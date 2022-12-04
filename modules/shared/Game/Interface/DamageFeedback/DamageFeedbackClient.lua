---
-- @classmod DamageFeedbackClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TweenService = game:GetService("TweenService")

local Network = require("Network")
local DamageFeedbackConstants = require("DamageFeedbackConstants")
local GuiTemplateProvider = require("GuiTemplateProvider")
local DebugVisualizer = require("DebugVisualizer")

local LEAST_DAMAGE = Color3.new(1, 1, 0)
local MOST_DAMAGE = Color3.new(1, 0, 1)

local DISPLAY_TIME = 2
local FADE_DELAY = 1
local POSITION_OFFSET = Vector3.new(0.5, 0.5, 0.5)
local VERTICAL_OFFSET = 4

local DamageFeedbackClient = {}

function DamageFeedbackClient:Init()
    self._randomObject = Random.new()

    Network:GetRemoteEvent(DamageFeedbackConstants.REMOTE_EVENT_NAME).OnClientEvent:Connect(function(...)
        self:_handleClientEvent(...)
    end)
end

function DamageFeedbackClient:_handleClientEvent(humanoid, damage, position)
    local dummyPart = DebugVisualizer:GhostPart()
    local randomPos = position + self:_getRandomOffset()
    dummyPart.Transparency = 1
    dummyPart.Position = randomPos

    local indicator = GuiTemplateProvider:Get("HitIndicatorTemplate")
    local canvasGroup = indicator.CanvasGroup
    local label = canvasGroup.Label

    label.Text = damage
    label.TextColor3 = LEAST_DAMAGE:Lerp(MOST_DAMAGE, damage/humanoid.MaxHealth)
    indicator.Parent = dummyPart
    dummyPart.Parent = workspace.Terrain

    TweenService:Create(
        dummyPart,
        TweenInfo.new(DISPLAY_TIME, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
        {Position = randomPos + Vector3.new(0, VERTICAL_OFFSET, 0)}
    ):Play()
    local fadeTween = TweenService:Create(
        canvasGroup,
        TweenInfo.new(DISPLAY_TIME - FADE_DELAY, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
        {GroupTransparency = 1}
    )
    task.delay(FADE_DELAY, function()
        fadeTween:Play()
    end)

    fadeTween.Completed:Connect(function()
        fadeTween:Destroy()
        dummyPart:Destroy()
    end)

    if humanoid:GetAttribute("IsDummy") then
        self:_shakeDummy(humanoid.Parent, position)
    end
end

function DamageFeedbackClient:_shakeDummy(dummy, hitPosition)
    local dummyPivot = dummy.WorldPivot

    -- TODO
end

function DamageFeedbackClient:_getRandomOffset()
    return Vector3.new(
        self._randomObject:NextInteger(-POSITION_OFFSET.X, POSITION_OFFSET.X),
        self._randomObject:NextInteger(-POSITION_OFFSET.Y, POSITION_OFFSET.Y),
        self._randomObject:NextInteger(-POSITION_OFFSET.Z, POSITION_OFFSET.Z)
    )
end

return DamageFeedbackClient