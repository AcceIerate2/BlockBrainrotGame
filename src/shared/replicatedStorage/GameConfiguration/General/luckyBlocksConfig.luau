local LuckyBlocksConfig = {}
LuckyBlocksConfig.Rarities = {
	Common = "CommonLuckyBlock",
	Uncommon = "UncommonLuckyBlock",
}

LuckyBlocksConfig.LuckyBlocks = {}
LuckyBlocksConfig.LuckyBlocks.CommonLuckyBlock = {
	Brainrots = {
		TungTungTungSahur = {
			SpawnWeight = 25,
		},

		["67"] = {
			SpawnWeight = 30,
		},
	},

	Mutations = {
		Default = {
			SpawnWeight = 50,
		},

		Golden = {
			SpawnWeight = 30,
		},

		Toxic = {
			SpawnWeight = 20,
		},
	},

	Icon = "rbxassetid://131800338499018",
	UnlockDuration = 10,
	AnimationId = "rbxassetid://97017523120121",
}

LuckyBlocksConfig.LuckyBlocks.UncommonLuckyBlock = {
	Brainrots = {
		TungTungTungSahur = {
			SpawnWeight = 25,
		},

		["67"] = {
			SpawnWeight = 30,
		},
	},

	Mutations = {
		Default = {
			SpawnWeight = 50,
		},

		Golden = {
			SpawnWeight = 30,
		},

		Toxic = {
			SpawnWeight = 20,
		},
	},

	Icon = "rbxassetid://131800338499018",
	UnlockDuration = 10,
	AnimationId = "rbxassetid://97017523120121",
}

return LuckyBlocksConfig
