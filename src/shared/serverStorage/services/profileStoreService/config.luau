-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config Modules
local blocksConfig = require(ReplicatedStorage.src.GameConfiguration.General.blocksConfig)

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

		MaxHold = {
			Value = 1,
			Level = 0,
		},

		LastSeen = 0,
		JoinedBefore = false,
		AvatarHeadshotAssetId = "",

		PurchaseHistory = {},
	},
}
