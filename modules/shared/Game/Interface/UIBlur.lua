local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local UIBlur = {}

local blur = Instance.new("BlurEffect")
blur.Enabled = false
blur.Size = 12
blur.Parent = Lighting

local activeTween
local function stopTween()
	if activeTween then
		activeTween:Cancel()
	end
end

function UIBlur:SetEnabled(bool)
    if bool then
        self:Enable()
    else
        self:Disable()
    end
end

function UIBlur:Enable()
	blur.Enabled = true
	stopTween()
	activeTween = TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
		Size = 12;
	})
	activeTween:Play()
end

function UIBlur:Disable()
	stopTween()
	activeTween = TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
		Size = 0,
		Enabled = false
	})
	activeTween:Play()
end

return UIBlur