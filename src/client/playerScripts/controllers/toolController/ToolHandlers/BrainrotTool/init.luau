-->
local BrainrotTool = {}

function BrainrotTool:Bind(tool: Tool)
	local connections = {}

	table.insert(connections, tool.Equipped:Connect(function() end))

	table.insert(connections, tool.Activated:Connect(function() end))

	table.insert(connections, tool.Unequipped:Connect(function() end))

	return connections
end

function BrainrotTool:Disconnect(tool: Tool) end

return BrainrotTool
