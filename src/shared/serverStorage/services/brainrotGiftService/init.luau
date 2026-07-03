-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local BrainrotGiftService = knit.CreateService({
	Name = "BrainrotGiftService",
	Client = {},
})

--[[
	self.BrainrotGiftService
		:Gift({
			Name = playerNameToGiftTo,
			brainrotReferenceId = brainrotReferenceId,
			Mutation = mutation,
		})
		:andThen(function(response)
			warn(response)
		end)
		:catch(warn)
]]

-- Client Exposed Methods
function BrainrotGiftService.Client:Gift(
	player: Player,
	data: { Name: string, BrainrotReferenceId: string, Mutation: string }
)
	warn(player, data)
	return self.Server:Gift(player, data)
end

-- Public Methods
function BrainrotGiftService:Gift(player: Player, data: { Name: string, BrainrotReferenceId: string, Mutation: string })
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(data) == "table", "data arg must be a table")

	warn(data, "??")
	local sendingPlayerOwnsBrainrot = self.DataService:GetValue(player, "Inventory")[data.BrainrotReferenceId]
	if not sendingPlayerOwnsBrainrot then
		return {
			Status = false,
			Reason = `You don't own{data.Mutation ~= "Default" and " " .. data.Mutation or ""} {brainrotHandler.GetBrainrotDisplayName(
				data.BrainrotReferenceId
			)}!`,
		}
	end

	local otherPlayer = Players:FindFirstChild(data.Name)
	if not otherPlayer then
		return {
			Status = false,
			Reason = `{data.Name} left the game`,
		}
	end

	self.InventoryService:Remove(player, data.BrainrotReferenceId)
	self.InventoryService:RemoveTool(player, data.BrainrotReferenceId)

	self.InventoryService:Give(otherPlayer, data.BrainrotReferenceId, "BrainrotTool", {
		Mutation = data.Mutation or "Default",
		Level = 1,
	})

	return {
		Status = true,
	}
end

-- LifeCycle
function BrainrotGiftService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.InventoryService = knit.GetService("InventoryService")
end

return BrainrotGiftService
