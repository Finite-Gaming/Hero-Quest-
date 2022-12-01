local buttonColors = {
	Gray = {
		Over = "rbxassetid://9687374982",
		Normal = "rbxassetid://9688651975"
	},
	Green = {
		Over = "rbxassetid://9687376245",
		Normal = "rbxassetid://9688652773"
	},
	Blue = {
		Over = "rbxassetid://9420319733",
		Normal = "rbxassetid://9420318649"
	},
	Red = {
		Over = "rbxassetid://9688653664",
		Normal = "rbxassetid://9688654750"
	}
}

local UIButton = {}

function UIButton:Enable(button: ImageButton, newColor: string?)
	local color = newColor or button:GetAttribute("Color") or "Blue"
	assert(buttonColors[color], string.format("%s is not a valid button color.", color))
	
	if newColor then
		button:SetAttribute("Color", newColor)
	end
	
	button.ImageColor3 = Color3.new(1, 1, 1)
	button.Image = buttonColors[color].Normal
	button.PressedImage = buttonColors[color].Normal
	button.HoverImage = buttonColors[color].Over
	button.Active = true
end
function UIButton:Disable(button: ImageButton)
	button.ImageColor3 = Color3.new(0.87, 0.87, 0.87)
	button.Image = buttonColors.Gray.Normal
	button.PressedImage = buttonColors.Gray.Normal
	button.HoverImage = buttonColors.Gray.Normal
	button.Active = false
end

return UIButton