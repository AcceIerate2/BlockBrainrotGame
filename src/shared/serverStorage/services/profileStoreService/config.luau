-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config Modules
local blocksConfig = require(ReplicatedStorage.src.GameConfiguration.General.blocksConfig)
local mutationConfig = require(ReplicatedStorage.src.GameConfiguration.General.mutationConfig)

-->
return {
	DataTemplate = {
		Cash = 0,
		Rebirths = 0,
		Inventory = {},

		GroupRewardClaimed = false,

		Index = (function()
			local _table = {}
			for mutation: string, _ in pairs(mutationConfig) do
				_table[mutation] = {}
			end
			return _table
		end)(),

		Blocks = {
			Value = 20,
			Level = 0,
		},

		MaxBlocks = {
			Value = 20,
			Level = 0,
		},

		EquippedBlock = blocksConfig.DefaultBlock,
		OwnedBlocks = {
			[blocksConfig.DefaultBlock] = true,
		},

		PlotUpgradeLevel = 0,
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

		LuckyBlockCountdowns = {},
		PurchaseHistory = {},
	},
}
