local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

workspace.Lobby.Assets:Destroy()

require("ServerClassBinders"):Init()