-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local CollisionHandler = require(ReplicatedStorage.src.utility.CollisionHandler)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Helper Functions
local function getBrainrotAsset(brainrotName: string, mutation: string)
	assert(typeof(brainrotName) == "string", "brainrotName arg must be a string")
	assert(typeof(mutation) == "string", "mutation arg must be a string")
	return ReplicatedStorage:WaitForChild("Assets")
		:WaitForChild("Brainrots")
		:WaitForChild(mutation)
		:WaitForChild(brainrotName)
		:Clone()
end

-->
local BrainrotTool = {
	StandController = knit.GetController("StandController"),
}

-- Private Methods
function BrainrotTool:equip(toolName: string)
	assert(typeof(toolName) == "string", "toolName arg must be a string")

	local brainrotName = brainrotHandler.GetBrainrotNameFromReferenceId(toolName)
	local mutation = brainrotHandler.GetMutationFromBrainrotReferenceId(toolName)

	self.BrainrotAsset = getBrainrotAsset(brainrotName, mutation)
	CollisionHandler.ToggleCollisionProperties(self.BrainrotAsset, {
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Anchored = false,
		Massless = true,
	}, {})

	self.AnimationController:play("Carry")
end

function BrainrotTool:unequip()
	self.BrainrotAsset:Destroy()
	self.AnimationController:stop("Carry")
end

-- Public Methods
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
