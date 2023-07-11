---
-- @classmod ExitButtonMixin
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Signal = require("Signal")

local ExitButtonMixin = {}

function ExitButtonMixin:Add(class)
    class.EnabledChanged = Signal.new()

    class.IsEnabled = self.IsEnabled
    class.SetEnabled = self.SetEnabled

    local exitButton = class._gui.MainFrame:FindFirstChild("ExitButton")

    if exitButton then
        exitButton.Activated:Connect(function()
            class:SetEnabled(false)
        end)
    end
end

function ExitButtonMixin:IsEnabled()
    return self._screenGui.Enabled
end

function ExitButtonMixin:SetEnabled(bool)
    self._screenGui.Enabled = bool
    self.EnabledChanged:Fire(bool)
end

return ExitButtonMixin