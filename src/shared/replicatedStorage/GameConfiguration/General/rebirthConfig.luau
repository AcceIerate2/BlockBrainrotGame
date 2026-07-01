-->
local RebirthConfig = {}

RebirthConfig.ArithmeticTypes = {
	Addition = "Addition",
	Multiplication = "Multiplication",
	Power = "Power",
}

RebirthConfig.RequirementValue = "MaxBlocks"

RebirthConfig.RequirementConfig = {
	Base = 25,
	Increment = 15,
	ArithmeticType = RebirthConfig.ArithmeticTypes.Addition,
}

RebirthConfig.Rewards = {
	CashMultiplier = {
		Base = 1,
		Increment = 0.25,
		ArithmeticType = RebirthConfig.ArithmeticTypes.Addition,
	},

	BlockMultiplier = {
		Base = 1,
		Increment = 0.25,
		ArithmeticType = RebirthConfig.ArithmeticTypes.Addition,
	},
}

RebirthConfig.Reset = {
	Cash = {
		Value = 0,
	},
	Blocks = {
		Value = 15,
		Level = 0,
	},
	MaxBlocks = {
		Value = 15,
		Level = 0,
	},
}

-- Helper Functions
local function calculateValue(base: number, increment: number, arithmeticType: string, rebirths: number)
	assert(typeof(base) == "number", "base arg must be a number")
	assert(typeof(increment) == "number", "increment arg must be a number")
	assert(typeof(arithmeticType) == "string", "arithmeticType arg must be a string")
	assert(typeof(rebirths) == "number", "rebirths arg must be a number")

	if arithmeticType == RebirthConfig.ArithmeticTypes.Addition then
		return base + (increment * rebirths)
	end

	if arithmeticType == RebirthConfig.ArithmeticTypes.Multiplication then
		return base * (increment ^ rebirths)
	end

	if arithmeticType == RebirthConfig.ArithmeticTypes.Power then
		return base + (rebirths ^ increment)
	end

	error(`Invalid arithmeticType: {arithmeticType}`)
end

-- Public Utility Functions
function RebirthConfig.CalculateCostToRebirth(rebirths: number)
	assert(typeof(rebirths) == "number", "rebirths arg must be a number")

	local requirement = RebirthConfig.RequirementConfig

	return math.floor(calculateValue(requirement.Base, requirement.Increment, requirement.ArithmeticType, rebirths))
end

function RebirthConfig.CalculateCashMultiplier(rebirths: number)
	assert(typeof(rebirths) == "number", "rebirths arg must be a number")

	local reward = RebirthConfig.Rewards.CashMultiplier

	return calculateValue(reward.Base, reward.Increment, reward.ArithmeticType, rebirths)
end

function RebirthConfig.CalculateBlockMultiplier(rebirths: number)
	assert(typeof(rebirths) == "number", "rebirths arg must be a number")

	local reward = RebirthConfig.Rewards.BlockMultiplier

	return calculateValue(reward.Base, reward.Increment, reward.ArithmeticType, rebirths)
end

return RebirthConfig
