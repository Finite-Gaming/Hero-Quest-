---
-- @classmod EnemyHealthBar
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local GuiTemplateProvider = require("GuiTemplateProvider")
local ScreenGuiProvider = require("ScreenGuiProvider")

local RunService = game:GetService("RunService")

local EnemyHealthBar = setmetatable({}, BaseObject)
EnemyHealthBar.__index = EnemyHealthBar

function EnemyHealthBar.new(obj)
    local self = setmetatable(BaseObject.new(obj), EnemyHealthBar)

    self._humanoid = self._obj:FindFirstChild("Humanoid")

    if not self._humanoid then
        warn("[EnemyHealthBar] - No Humanoid!")
        self:Destroy()
        return
    end

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("EnemyHealthBar"))

    self._gui = self._maid:AddTask(GuiTemplateProvider:Get("EnemyHealthBarTemplate"))
    self._maid:AddTask(RunService.RenderStepped:Connect(function()
        local rootPart = self._humanoid.RootPart
        if not rootPart then
            return
        end

        local cameraCFrame = workspace.CurrentCamera.CFrame
        local distance = (rootPart.Position - cameraCFrame.Position).Magnitude
        local visiblePercentage = math.clamp(distance - 110, 0, 18)/18

        self._gui.GroupTransparency = visiblePercentage
    end))

    self._healthBar = self._gui.HealthBar
    self:_update()

    self._gui.Parent = self._screenGui

    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        self:_update()
    end))
    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        self:_update()
    end))

    self._maid:AddTask(self._humanoid.Destroying:Connect(function()
        self:Destroy()
    end))
    self._maid:AddTask(self._humanoid.Died:Connect(function()
        self:Destroy()
    end))

    return self
end

function EnemyHealthBar:_update()
    local health, maxHealth = self._humanoid.Health, self._humanoid.MaxHealth
    local healthP = math.clamp(health/maxHealth, 0, 1)

    self._healthBar.BarContainer.Bar.Size = UDim2.fromScale(healthP, 1)
    self._healthBar.BarContainer.Label.Text = ("%i/%i"):format(math.round(health), math.round(maxHealth))
end

return EnemyHealthBar