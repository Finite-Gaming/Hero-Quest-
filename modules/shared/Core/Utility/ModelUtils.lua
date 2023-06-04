--- Utility functions for models
-- @classmod ModelUtils
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DebugVisualizer = require("DebugVisualizer")

local CollectionService = game:GetService("CollectionService")

local ModelUtils = {}

function ModelUtils.getParts(model)
    local parts = {}
    for _, part in ipairs(model:GetDescendants()) do
        if not part:IsA("BasePart") then
            continue
        end

        table.insert(parts, part)
    end

    return parts
end

function ModelUtils.getPrimaryModel(descendant, parent)
    local model = descendant
    while model and model.Parent ~= parent and model.Parent ~= game do
        model = model.Parent
    end

    return model and model.Parent ~= game and model or nil
end

function ModelUtils.createBasePart(model)
	local modelCFrame = model:GetBoundingBox()
    modelCFrame = CFrame.new(modelCFrame.Position)

	local basePart = DebugVisualizer:DebugPart()

	basePart.Size = Vector3.zero
	basePart.Name = "BasePart"

	basePart.CFrame = modelCFrame
    basePart.Parent = model

	model.PrimaryPart = basePart

	return basePart
end

function ModelUtils.createDisplayClone(model)
    model = model:Clone()
    if model:IsA("Tool") then
        local vModel = Instance.new("Model")
        vModel.Name = model.Name
        for _, child in ipairs(model:GetChildren()) do
            child.Parent = vModel
        end

        model:Destroy()
        model = vModel
    end

    ModelUtils.createBasePart(model)

    for _, tag in ipairs(CollectionService:GetTags(model)) do
        CollectionService:RemoveTag(model, tag)
    end
    for _, obj in ipairs(model:GetDescendants()) do
        if not obj:IsA("BasePart") and not obj:IsA("Model") and not obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        end
    end

    return model
end

return ModelUtils