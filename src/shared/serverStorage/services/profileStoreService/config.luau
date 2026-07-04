-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config Modules
local blocksConfig = require(ReplicatedStorage.src.GameConfiguration.General.blocksConfig)
local mutationConfig = require(ReplicatedStorage.src.GameConfiguration.General.mutationConfig)

-->
return {
	DataTemplate = {
		Cash = 5000000,
		Rebirths = 0,
		Inventory = {
			["67"] = {
				Quantity = 1,
				Handler = "BrainrotTool",
				Mutation = "Default",
				Level = 1,
			},
		},

		Index = (function()
			local _table = {}
			for mutation: string, _ in pairs(mutationConfig) do
				_table[mutation] = {}
			end
			return _table
		end)(),

		Blocks = {
			Value = 15,
			Level = 0,
		},

		MaxBlocks = {
			Value = 15,
			Level = 0,
		},

		EquippedBlock = blocksConfig.DefaultBlock,
		OwnedBlocks = {
			[blocksConfig.DefaultBlock] = true,
		},

		ExtraPlotFloors = 0,
		ExtraPlotStands = 0,
		TakenStands = {},

		MaxHold = {
			Value = 1,
			Level = 0,
		},

		BlockMultiplier = 1,
		CashMultiplier = 1,
		WalkSpeedMultiplier = 1,

		LastSession = 0,
		JoinedBefore = false,
		AvatarHeadshotAssetId = "",

		PurchaseHistory = {},
	},
}
