-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Helper Functions->
local BrainrotTool = {
	StandController = knit.GetController("StandController"),
	AnimationController = knit.GetController("AnimationController"),
	BrainrotGiftController = knit.GetController("BrainrotGiftController"),
	BrainrotToolService = knit.GetService("BrainrotToolService"),

	TempInstances = {},
	TempConnections = {},
	BrainrotAsset = nil,
}

-- Private Methods
function BrainrotTool:equip(toolName: string, type: string)
	assert(typeof(toolName) == "string", "toolName arg must be a string")
	assert(typeof(type) == "string", "type arg must be a string")

	self:unequip()

	local mutation = type == "Brainrot" and brainrotHandler.GetMutationFromBrainrotReferenceId(toolName)
	self.BrainrotToolService:ShowBrainrot(toolName, mutation, type)
	self.AnimationController:play("FrontHold")
end

function BrainrotTool:unequip()
	local carriedBrainrotAssetToDestroy = workspace:FindFirstChild(`{Players.LocalPlayer.Name}_CarriedBrainrot`)
	if carriedBrainrotAssetToDestroy then
		carriedBrainrotAssetToDestroy:Destroy()
	end

	self.BrainrotToolService:HideBrainrot()
	self.AnimationController:stop("FrontHold")
end

-- Public Methods
function BrainrotTool:Bind(tool: Tool)
	local connections = {}

	table.insert(
		connections,
		tool.Equipped:Connect(function()
			self.StandController:ToggleProximityPromptVisibility(true)
			self.BrainrotGiftController:ToggleGiftProximityPrompts(
				true,
				tool.Name,
				tool:GetAttribute("Mutation"),
				tool:GetAttribute("Type")
			)
			self:equip(tool.Name, tool:GetAttribute("Type"))
		end)
	)

	table.insert(connections, tool.Activated:Connect(function() end))

	table.insert(
		connections,
		tool.Unequipped:Connect(function()
			self.StandController:ToggleProximityPromptVisibility(false)
			self.BrainrotGiftController:ToggleGiftProximityPrompts(false)
			self:unequip()
		end)
	)

	return connections
end

function BrainrotTool:Disconnect(tool: Tool)
	self.StandController:ToggleProximityPromptVisibility(false)
	self.BrainrotGiftController:ToggleGiftProximityPrompts(false)
	self:unequip()
end

return BrainrotTool
