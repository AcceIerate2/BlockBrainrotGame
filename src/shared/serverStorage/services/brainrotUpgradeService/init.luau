-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Helper Functions
local function isPlayer(player: Player)
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local BrainrotUpgradeService = knit.CreateService({
	Name = "BrainrotUpgradeService",
	Client = {},
})

-- Client Exposed Methods
function BrainrotUpgradeService.Client:Upgrade(player: Player, brainrotReferenceId: string)
	return self.Server:Upgrade(player, brainrotReferenceId)
end

-- Public Methods
function BrainrotUpgradeService:Upgrade(player: Player, brainrotReferenceId: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")

	local inventoryValueObject = self.DataService:GetValueObject(player, "Inventory")
	if not inventoryValueObject:Get()[brainrotReferenceId] then
		return {
			Status = false,
			Reason = `You don't own {brainrotHandler.GetBrainrotDisplayName(brainrotReferenceId)}!`,
		}
	end

	local currentLevel = inventoryValueObject:Get()[brainrotReferenceId].Level

	local costToUpgrade = brainrotHandler.CalculateLevelCost(brainrotReferenceId, currentLevel + 1)
	if not self.CashService:canAfford(player, costToUpgrade) then
		return {
			Status = false,
			Reason = "You can't afford this!",
		}
	end

	self.CashService:manipulatePlayerCash(player, -costToUpgrade, "Addition")
	inventoryValueObject:Update(function(_table)
		_table[brainrotReferenceId].Level += 1
	end)

	local brainrotAsset = self.StandService:GetBrainrotAssetFromReferenceId(player, brainrotReferenceId)
	if brainrotAsset then
		brainrotHandler.UpdateLevel(brainrotAsset, brainrotReferenceId, currentLevel + 1, player)
	end

	return {
		Status = true,
		NewLevel = currentLevel + 1,
		NextLevel = currentLevel + 2,
		CostToUpgrade = brainrotHandler.CalculateLevelCost(brainrotReferenceId, currentLevel + 2),
	}
end

-- LifeCycle
function BrainrotUpgradeService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
	self.StandService = knit.GetService("StandService")
end

return BrainrotUpgradeService
