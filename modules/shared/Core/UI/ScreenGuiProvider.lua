--- Provides a ScreenGui given a name, created if it doesnt exist, and parented to PlayerGui
-- @classmod ScreenGuiProvider
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local ScreenGuiProvider = {}

function ScreenGuiProvider:Get(guiName)
    local gui = Instance.new("ScreenGui")
    gui.Name = guiName
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = Players.LocalPlayer.PlayerGui

    return gui
end

return ScreenGuiProvider