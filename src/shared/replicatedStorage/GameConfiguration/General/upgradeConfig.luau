local UpgradeConfig = {}

UpgradeConfig.Upgrades = {
	Blocks = {
		Limits = {
			[1] = true,
			[10] = true,
		},

		BaseCost = 10,
		Multiplier = 1,
		MaxLevel = -1,
	},

	MaxBlocks = {
		Limits = {
			[1] = true,
			[10] = true,
		},

		BaseCost = 10,
		Multiplier = 1.1,
		MaxLevel = -1,
	},

	Carry = {
		Limits = {
			[1] = true,
		},

		BaseCost = 10,
		Multiplier = 2,
		MaxLevel = 3,
	},
}

return UpgradeConfig
