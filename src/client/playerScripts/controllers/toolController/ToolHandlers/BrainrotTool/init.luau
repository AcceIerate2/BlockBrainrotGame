-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local BrainrotTool = {
	StandController = knit.GetController("StandController"),
}

function BrainrotTool:Bind(tool: Tool)
	local connections = {}

	table.insert(
		connections,
		tool.Equipped:Connect(function()
			self.StandController:ToggleProximityPromptVisibility(true)
		end)
	)

	table.insert(connections, tool.Activated:Connect(function() end))

	table.insert(
		connections,
		tool.Unequipped:Connect(function()
			self.StandController:ToggleProximityPromptVisibility(false)
		end)
	)

	return connections
end

function BrainrotTool:Disconnect(tool: Tool)
	self.StandController:ToggleProximityPromptVisibility(false)
end

return BrainrotTool
