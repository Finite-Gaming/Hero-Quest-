local services = {
    "Workspace";
    "ReplicatedStorage";
    "ServerScriptService";
    "ServerStorage";
    "Lighting";
    "StarterPlayer";
}

local scripts = {
    ["LocalScript"] = true;
    ["Script"] = true;
    ["ModuleScript"] = true;
}

local lines = 0
local scriptss = 0

for _, serviceName in ipairs(services) do
    for _, script in ipairs(game:GetService(serviceName):GetDescendants()) do
        if scripts[script.ClassName] then
            scriptss += 1
            lines += #script.Source:split("\n")
            warn(script.Name,  #script.Source:split("\n"))
        end
    end
end

warn(lines)
print(scriptss)