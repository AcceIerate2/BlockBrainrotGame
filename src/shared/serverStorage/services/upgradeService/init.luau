-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local upgradeConfig = require(ReplicatedStorage.src.GameConfiguration.General.upgradeConfig)

-- Helper Functions
local function isPlayer(player: Player): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local UpgradeService = knit.CreateService({
	Name = "UpgradeService",
})

-- Client Exposed Methods
function UpgradeService.Client:Upgrade(player: Player, upgradeType: string, upgradeAmount: number)
	return self.Server:Upgrade(player, upgradeType, upgradeAmount)
end

-- Private Methods
function UpgradeService:isValidUpgradeType(upgradeType: string)
	return typeof(upgradeConfig.Upgrades[upgradeType]) == "table"
end

function UpgradeService:isValidUpgradeAmount(upgradeType: string, upgradeAmount: number)
	return upgradeConfig.Upgrades[upgradeType].Limits[upgradeAmount] == true
end

function UpgradeService:reachedMaxLevel(upgradeType: string, level: number)
	if upgradeConfig.Upgrades[upgradeType].MaxLevel <= -1 then
		return false
	end
	return level >= upgradeConfig.Upgrades[upgradeType].MaxLevel
end

function UpgradeService:getUpgradeCost(upgradeType: string, level: number)
	assert(typeof(upgradeType) == "string", "upgradeType arg must be a string")
	assert(typeof(level) == "number", "level arg must be a number")
	local upgradeData = upgradeConfig.Upgrades[upgradeType]
	return upgradeData.BaseCost * upgradeData.Multiplier ^ level
end

-- Public Methods
function UpgradeService:Upgrade(player: Player, upgradeType: string, upgradeAmount: number)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(upgradeType) == "string", "upgradeType arg must be a string")
	assert(typeof(upgradeAmount) == "number", "upgradeAmount arg must be a number")

	if not self:isValidUpgradeType(upgradeType) then
		return {
			Status = false,
			Reason = "Invalid Upgrade",
		}
	end

	if not self:isValidUpgradeAmount(upgradeType, upgradeAmount) then
		return {
			Status = false,
			Reason = "Invalid Upgrade Amount",
		}
	end

	local valueObject = self.DataService:GetValueObject(player, upgradeType == "Carry" and "MaxHold" or upgradeType)

	local currentData = valueObject:Get()
	local baseUpgradeAmount = upgradeAmount
	local actualUpgradeAmount = baseUpgradeAmount

	if upgradeType == "Blocks" then
		local blockMultiplier = self.DataService:GetValue(player, "BlockMultiplier") or 1
		actualUpgradeAmount = math.max(1, math.round(baseUpgradeAmount * blockMultiplier))

		if currentData.Value + actualUpgradeAmount > self.DataService:GetValue(player, "MaxBlocks").Value then
			return {
				Status = false,
				Reason = "You've reached your limit! Upgrade Max Blocks to buy more!",
			}
		end
	end

	if self:reachedMaxLevel(upgradeType, currentData.Level + baseUpgradeAmount) then
		return {
			Status = false,
			Reason = "Max Level",
		}
	end

	local costToUpgrade = self:getUpgradeCost(upgradeType, currentData.Level + baseUpgradeAmount)

	if not self.CashService:canAfford(player, costToUpgrade) then
		return {
			Status = false,
			Reason = `You need ${NumberShortner(costToUpgrade - self.DataService:GetValue(player, "Cash"))} more!`,
		}
	end

	self.CashService:manipulatePlayerCash(player, -costToUpgrade, "Addition")

	valueObject:Update(function(_table)
		_table.Value += actualUpgradeAmount
		_table.Level += baseUpgradeAmount
	end)

	local newData = valueObject:Get()

	return {
		Status = true,
		NewLevel = newData.Level,
		NewValue = newData.Value,
		AmountGained = actualUpgradeAmount,
		CostToUpgrade = self:getUpgradeCost(upgradeType, newData.Level + baseUpgradeAmount),
	}
end

-- LifeCycle
function UpgradeService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
end

return UpgradeService
