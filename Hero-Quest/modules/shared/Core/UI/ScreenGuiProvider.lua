--- Provides a ScreenGui given a name, created if it doesnt exist, and parented to PlayerGui
-- @classmod ScreenGuiProvider
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local ScreenGuiProvider = {}

function ScreenGuiProvider:Get(guiName)
    local gui = Players.LocalPlayer.PlayerGui:FindFirstChild(guiName)

    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = guiName
        gui.Parent = Players.LocalPlayer.PlayerGui
    end

    return gui
end

return ScreenGuiProvider