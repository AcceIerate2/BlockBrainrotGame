-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local rebirthConfig = require(ReplicatedStorage.src.GameConfiguration.General.rebirthConfig)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local RebirthService = knit.CreateService({
	Name = "RebirthService",
	Client = {},
})

-- Client Exposed Methods
function RebirthService.Client:Rebirth(player: Player)
	return self.Server:Rebirth(player)
end

-- Public Methods
function RebirthService:Rebirth(player: Player, skip: boolean?)
	assert(isPlayer(player), "player arg must be a Player Instance")

	local rebirthsValueObject = self.DataService:GetValueObject(player, "Rebirths")
	local currentRebirths = rebirthsValueObject:Get()

	-- Validate
	local rebirthRequirement = rebirthConfig.CalculateCostToRebirth(currentRebirths)
	local requirementValue = self.DataService:GetValue(player, rebirthConfig.RequirementValue)

	if not skip and requirementValue.Value < rebirthRequirement then
		return {
			Status = false,
			Reason = "You don't meet the requirements yet!",
			Required = rebirthRequirement,
			Current = requirementValue.Value,
		}
	end

	local newRebirths = currentRebirths + 1

	-- Reset values for rebirth
	if not skip then
		for valueType: string, data: { Level: number?, Value: number } in pairs(rebirthConfig.Reset) do
			local valueObject = self.DataService:GetValueObject(player, valueType)
			local currentValue = valueObject:Get()

			if typeof(currentValue) == "table" then
				local resetData = {
					Value = data.Value,
				}

				if typeof(data.Level) == "number" then
					resetData.Level = data.Level
				end

				valueObject:Set(resetData)
			else
				valueObject:Set(data.Value)
			end
		end
	end

	-- Reward player
	for rewardType: string, _ in pairs(rebirthConfig.Rewards) do
		local rewardValueObject = self.DataService:GetValueObject(player, rewardType)

		if rewardType == "CashMultiplier" then
			rewardValueObject:Set(rebirthConfig.CalculateCashMultiplier(newRebirths))
		elseif rewardType == "BlockMultiplier" then
			rewardValueObject:Set(rebirthConfig.CalculateBlockMultiplier(newRebirths))
		else
			warn(`Unknown rebirth reward type: {rewardType}`)
		end
	end

	--
	rebirthsValueObject:Set(newRebirths)
	self.PlotService:UpdateCashMultiplierLabel(player)

	return {
		Status = true,
		Rebirths = newRebirths,
		CashMultiplier = rebirthConfig.CalculateCashMultiplier(newRebirths),
		BlockMultiplier = rebirthConfig.CalculateBlockMultiplier(newRebirths),
		NextRequirement = rebirthConfig.CalculateCostToRebirth(newRebirths),
	}
end

-- LifeCycle
function RebirthService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.PlotService = knit.GetService("PlotService")
end

return RebirthService
