local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")

local UIBlur = require("UIBlur")

local uiTransitionDuration = script:GetAttribute("UITransitionDuration") or 0.25

local UIManager = {}

local uiChanged = Instance.new("BindableEvent")
UIManager.UIChanged = uiChanged.Event

function UIManager:GetActiveUI(): string
	return self.ActiveUI
end

function UIManager:SetActiveUI(guiName: string?)
	self.ActiveUI = guiName
	uiChanged:Fire(guiName)
end

function UIManager:CloseActiveUI()
	self:SetActiveUI(nil)
end

function UIManager:Bind(guiName: string, callback: (boolean) -> (), button: GuiButton?, ...: Enum.KeyCode)
	local function toggleUI()
		if self:GetActiveUI() == guiName then
			self:CloseActiveUI()
		else
			self:SetActiveUI(guiName)
		end
	end
	
	-- If a button was specified
	if button then
		button.Activated:Connect(toggleUI)
	end
	-- If there's at least one keybind
	if (...) then
		ContextActionService:BindAction(string.format("%s_UIButton", guiName), function(actionName, userInputState)
			if userInputState == Enum.UserInputState.Begin then
				toggleUI()
			end
			return Enum.ContextActionResult.Pass
		end, false, ...)
	end
	
	self.UIChanged:Connect(function(currentGuiName)
		if currentGuiName == guiName then
			callback(true)
		else
			callback(false)
		end
	end)
end

local canvasReady = {}
local activeTweens = {}
local viewportPositions = {}
local viewportAnchors = {}

local showTweenInfo = TweenInfo.new(uiTransitionDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local hideTweenInfo = TweenInfo.new(uiTransitionDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
function UIManager:TweenCanvas(canvas: GuiObject, state: boolean)
	if activeTweens[canvas] then
		activeTweens[canvas]:Cancel()
		activeTweens[canvas] = nil
	end
	
	if not viewportPositions[canvas] then
		viewportPositions[canvas] = canvas.Position
	end
	if not viewportAnchors[canvas] then
		viewportAnchors[canvas] = canvas.AnchorPoint
	end
	
	local viewportPositionOffScreen = UDim2.new(viewportPositions[canvas].X, UDim.new(0, 0))
	local viewportAnchor = viewportAnchors[canvas]
	local viewportAnchorOffScreen = Vector2.new(viewportAnchor.X, math.max(1, viewportAnchor.Y))

	if not canvasReady[canvas] then
		canvasReady[canvas] = true
		canvas.Position = viewportPositionOffScreen
		canvas.AnchorPoint = viewportAnchorOffScreen
	end
	
	-- Create transitional tween	
	local tween
	if state then
		canvas.Visible = true
		
		tween = TweenService:Create(canvas, showTweenInfo, {
			Position = viewportPositions[canvas],
			AnchorPoint = viewportAnchors[canvas]
		})
	else
		tween = TweenService:Create(canvas, hideTweenInfo, {
			Position = viewportPositionOffScreen,
			AnchorPoint = viewportAnchorOffScreen,
			Visible = false
		})
		tween.Completed:Connect(function()
			canvas.Visible = false
		end)
	end
	
	-- Play the tween
	tween:Play()
	activeTweens[canvas] = tween

	tween.Completed:Wait()
	tween:Destroy()
	activeTweens[canvas] = nil
end

UIManager.UIChanged:Connect(function(currentGuiName)
	if not currentGuiName then
		UIBlur:Disable()
	else
		UIBlur:Enable()
	end
end)

local function addCloseButton(button: GuiButton)
	button.Activated:Connect(function()
		UIManager:CloseActiveUI()
	end)
end
for _, closeButton in ipairs(CollectionService:GetTagged("UIClose")) do
	task.spawn(addCloseButton, closeButton)
end
CollectionService:GetInstanceAddedSignal("UIClose"):Connect(addCloseButton)

return UIManager