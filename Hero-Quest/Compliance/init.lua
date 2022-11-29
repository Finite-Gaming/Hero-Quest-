--- Module script loader, similar to Nevermore but without the bloat/old code (https://github.com/Quenty/NevermoreEngine)
-- @classmod Compliance
-- @author frick

local ComplianceConfig = require(script:WaitForChild("ComplianceConfig"))

local RunService = game:GetService("RunService")

local ModulePaths = {}
local LoadedModules = {}

do
    if RunService:IsClient() then
        table.insert(ModulePaths, ComplianceConfig.SHARED_MODULES_PARENT)
    elseif RunService:IsServer() then
        table.insert(ModulePaths, ComplianceConfig.SHARED_MODULES_PARENT)
        table.insert(ModulePaths, ComplianceConfig.SERVER_MODULES_PARENT)
    else
        error("[Compliance] - Required in incorrect environment")
        return
    end

    for index, modulePath in ipairs(ModulePaths) do
        ModulePaths[index] = modulePath:WaitForChild(ComplianceConfig.GENERIC_MODULE_FOLDER_NAME)
    end
end

local function addModule(module)
    if not module:IsA("ModuleScript") then
        return
    end
    assert(not LoadedModules[module.Name], ("Duplicate module %q"):format(module.Name))

    LoadedModules[module.Name] = module
end

for _, modulePath in ipairs(ModulePaths) do
    for _, module in ipairs(modulePath:GetDescendants()) do
        addModule(module)
    end

    modulePath.DescendantAdded:Connect(addModule)
end

return function(moduleName)
    assert(moduleName and typeof(moduleName) == "string")
    local loadedModule = LoadedModules[moduleName]
    assert(loadedModule, ("Module %q does not exist"):format(moduleName))

    return require(loadedModule)
end