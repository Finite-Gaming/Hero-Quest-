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
local sortedScripts = {}

for _, serviceName in ipairs(services) do
    for _, script in ipairs(game:GetService(serviceName):GetDescendants()) do
        if scripts[script.ClassName] then
            scriptss += 1
            local lineCount = #script.Source:split("\n")
            table.insert(sortedScripts, {script.Name, lineCount})
            lines += lineCount
        end
    end
end

table.sort(sortedScripts, function(a, b)
    return b[2] > a[2]
end)
local str = ""
for _, data in ipairs(sortedScripts) do
    str = ("%s%s: %i\n"):format(str, data[1], data[2])
end

warn(str)
warn(lines)
print(scriptss)