---
-- @classmod CombatBinder
-- @author unknown, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local CombatClient = require("CombatClient")

local CombatBinder = {}

function CombatBinder:Init()
    self._equippedTools = {}

    self:_handleBackpack(Players.LocalPlayer:FindFirstChildWhichIsA("Backpack"))
    Players.LocalPlayer.ChildAdded:Connect(function(child)
        self:_handleBackpack(child)
    end)
end

warn("Stage 1")

function CombatBinder:_handleBackpack(backpack)
	warn("Stage 2")
	if backpack and backpack:IsA("Backpack") then
		warn("Stage 3")
		for _, child in ipairs(backpack:GetChildren()) do
			warn("Stage A")
			self:_handleTool(backpack, child)
		end
		backpack.ChildAdded:Connect(function(child)
            self:_handleTool(backpack, child)
        end)
	end
end

function CombatBinder:_handleTool(backpack, tool)
    warn("Stage 4")
    if tool:IsA("Tool") then
        warn("Stage 5")
        --warn("Tool found.", tool)
        if tool:GetAttribute("AnimationType") and tool:GetAttribute("CombatType") then
            warn("Stage 6")
            if self._equippedTools[tool] then
                warn("Stage 7")
                return
            end
            self._equippedTools[tool] = true

            CombatClient:BindTool(tool)
            warn("Stage 8")
            tool.AncestryChanged:Connect(function()
                warn("Stage 9")
                if not tool:IsDescendantOf(backpack) then
                    warn("Stage 10")
                    self._equippedTools[tool] = nil
                end
            end)
        end
    end
end

return CombatBinder