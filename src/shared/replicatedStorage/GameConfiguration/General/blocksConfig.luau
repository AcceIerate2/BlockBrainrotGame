local BlocksConfig = {}

BlocksConfig.DefaultWalkSpeed = 16
BlocksConfig.DefaultBlock = "DirtBlock"
BlocksConfig.Blocks = {
	DirtBlock = {
		Cost = 0,
		WalkSpeedMultiplier = 1,
	},

	WoodenBlock = {
		Cost = 10,
		WalkSpeedMultiplier = 2,
	},
}

return BlocksConfig
