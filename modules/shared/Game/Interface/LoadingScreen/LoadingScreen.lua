--- Refactored loading screen
-- @classmod LoadingScreen
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local StarterGui = game:GetService("StarterGui")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local GuiTemplateProvider = require("GuiTemplateProvider")
local ScreenGuiProvider = require("ScreenGuiProvider")
local Maid = require("Maid")
local Network = require("Network")
local CharacterServiceConstants = require("CharacterServiceConstants")
local LoadingScreenConstants = require("LoadingScreenConstants")

local CAMERA_ROT_SPEED = 10
local STAGE_NAMES = LoadingScreenConstants.STAGE_NAMES

local LoadingScreen = {}
-- We use the "service" format here as this script should be ran exclusively once
function LoadingScreen:Init()
    self._maid = Maid.new()
    self._camera = workspace.CurrentCamera
    self._randomObject = Random.new()

    self._startTick = os.clock() -- Used to track how many dots should be displayed on stage text
    self._lastStageUpdate = self._startTick -- Used to track when stage name should be changed
    self._stageText = STAGE_NAMES[self._randomObject:NextInteger(1, #STAGE_NAMES)] -- Pick a random stage name to display on startup

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("LoadingScreen")) -- Add this to the maid so all descendants are destroyed on demand
    self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._screenGui.IgnoreGuiInset = true

    self._totalAssets = 0
    self._loadedAssets = 0

    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- Disable the backpack while loading
    self:_setupGui()
    self:_gatherAssets()

    self:_updateLoadingBar()
    self._gui.Parent = self._screenGui
    ReplicatedFirst:RemoveDefaultLoadingScreen()

    self._maid.LoadingBarUpdate = RunService.RenderStepped:Connect(function()
        self:_updateLoadingBar()
        self:_updateStageName()
    end)
    self._maid:AddTask(task.spawn(function() -- Add this thread so when the skip button is pressed execution is stopped immediately
        self:_loadAssets()
        self:_showMap()
    end))
end

function LoadingScreen:_showMap()
    self._maid.LoadingBarUpdate = nil
    self:_enableCameraSpin()
    local TWEEN_INFO = TweenInfo.new(3, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

    TweenService:Create(
        self._mapCanvas,
        TWEEN_INFO,
        {
            GroupTransparency = 0.55;
            Size = UDim2.fromScale(1.15, 1.15);
        }
    ):Play() -- Expand the map image and make it more visible

    TweenService:Create(self._gui, TWEEN_INFO, {BackgroundTransparency = 0.45}):Play() -- Fade the black background out a bit
    TweenService:Create(self._playMenuCanvas, TWEEN_INFO, {GroupTransparency = 0}):Play() -- Fade the play button in
    TweenService:Create(self._loadingBarCanvas, TweenInfo.new(1), {GroupTransparency = 1}):Play() -- Fade the loading bar out
end

function LoadingScreen:_enableCameraSpin()
    local cameraPart = ReplicatedFirst:WaitForChild("LoadingCameraPart")
    local focusAttachment = cameraPart:WaitForChild("FocusAttachment")
    local cameraDistance = (cameraPart.Position - focusAttachment.WorldPosition).Magnitude

    local totalRotation = 0

    self._maid:AddTask(RunService.RenderStepped:Connect(function(dt)
        totalRotation += dt
        self._camera.CFrame = CFrame.new(focusAttachment.WorldPosition) * CFrame.Angles(math.rad(33), math.rad((totalRotation) * CAMERA_ROT_SPEED), 0) * CFrame.new(0, 0, cameraDistance)
		self._camera.Focus = focusAttachment.WorldCFrame
    end))
end

function LoadingScreen:_playGame()
    Network:GetRemoteFunction(CharacterServiceConstants.DONE_LOADING_REMOTE_FUNCTION_NAME):InvokeServer()
    self._maid:Destroy()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) -- Re-enable the backpack
end

function LoadingScreen:_loadAssets()
    local iteration = 0
    for asset, _ in pairs(self._preloadedAssets) do
        iteration += 1
        task.spawn(function()
            ContentProvider:PreloadAsync({asset})
            self._loadedAssets += 1
            self._preloadedAssets[asset] = nil
        end)
        if iteration % 256 == 0 then -- Wait every 256 iterations
            task.wait()
        end
    end
end

function LoadingScreen:_gatherAssets()
    self._preloadedAssets = {}
    local services = {
        workspace;
        game:GetService("ReplicatedStorage");
        game:GetService("StarterPack");
        StarterGui;
    }

    for _, service in ipairs(services) do
        for _, asset in ipairs(service:GetDescendants()) do
            self:_handleAssetAdded(asset)
        end
        self._maid:AddTask(service.DescendantAdded:Connect(function(asset) -- Load any assets replicated late
            self:_handleAssetAdded(asset)
        end))
    end
end

function LoadingScreen:_handleAssetAdded(obj)
    self._totalAssets += 1
    self._preloadedAssets[obj] = true
end

function LoadingScreen:_setupGui()
    -- Clone loading screen
    self._gui = GuiTemplateProvider:Get("LoadingScreenTemplate")
    self._mainFrame = self._gui.MainFrame

    -- Define all important gui objects for easier use
    self._mapCanvas = self._gui.Map
    self._loadingBarCanvas = self._mainFrame.LoadingBar
    self._playMenuCanvas = self._mainFrame.PlayMenu

    self._mapImage = self._mapCanvas.Map

    self._skipButton = self._loadingBarCanvas.SkipButton
    self._statusText = self._loadingBarCanvas.Status
    self._barContainer = self._loadingBarCanvas.BarBackground.BarContainer
    self._loadingBar = self._barContainer.Bar
    self._percentLoadedLabel = self._barContainer.Label

    self._playButton = self._playMenuCanvas.PlayButton
    self._playIconShadow = self._playButton.PlayIconShadow

    self._percentLoadedText = self._percentLoadedLabel.Text

    -- Make play button temporarily invisible
    self._playMenuCanvas.GroupTransparency = 1

    -- Add button listeners
    self._skipButton.Activated:Connect(function()
        self:_playGame()
    end)
    self._playButton.Activated:Connect(function()
        self:_playGame()
    end)
end

function LoadingScreen:_updateLoadingBar()
    local percentLoaded = (self._loadedAssets/self._totalAssets)
    percentLoaded = percentLoaded ~= percentLoaded and 0 or percentLoaded -- Guaranteeing that percentLoaded will never be "nan" so we dont display a wack number
    self._loadingBar.Size = UDim2.fromScale(percentLoaded, 1)
    self._percentLoadedLabel.Text = self._percentLoadedText:format(100 * percentLoaded)
end

function LoadingScreen:_updateStageName()
    local updateTick = os.clock()
    if updateTick - self._lastStageUpdate > 3 then
        self._stageText = STAGE_NAMES[self._randomObject:NextInteger(1, #self._stageText)]
        self._lastStageUpdate = updateTick
    end

    self._statusText.Text = self._stageText:format(("."):rep(((updateTick * 2) % 3) + 1))
end

return LoadingScreen