---
-- @classmod DungeonTimerClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local DungeonData = require("DungeonData")
local TimeUtils = require("TimeUtils")

local RunService = game:GetService("RunService")

local DungeonTimerClient = {}

function DungeonTimerClient:Init()
    self._screenGui = ScreenGuiProvider:Get("DungeonTimerGui")
    self._screenGui.IgnoreGuiInset = true
    self._screenGui.Enabled = true

    self._gui = GuiTemplateProvider:Get("DungeonTimerTemplate")
    self._timeLabel = self._gui.Header.TimeLabel

    self._dungeonEndTime = workspace:GetAttribute("DungeonEndTime")
    self._dungeonTotalTime = DungeonData[workspace:GetAttribute("DungeonTag")].PlayTime * 60
    if not self._dungeonEndTime then
        workspace:GetAttributeChangedSignal("DungeonEndTime"):Connect(function()
            self._dungeonEndTime = workspace:GetAttribute("DungeonEndTime")
        end)
    end

    self:Update()
    RunService.Heartbeat:Connect(function()
        self:Update()
    end)

    self._gui.Parent = self._screenGui
end

function DungeonTimerClient:Update()
    local timeLeft = (self._dungeonEndTime or math.huge) - workspace:GetServerTimeNow()
    if timeLeft >= self._dungeonTotalTime then
        self._timeLabel.Text = TimeUtils.formatM_S_MS(self._dungeonTotalTime)
    else
        self._timeLabel.Text = TimeUtils.formatM_S_MS(math.clamp(timeLeft, 0, self._dungeonTotalTime))
    end
end

return DungeonTimerClient