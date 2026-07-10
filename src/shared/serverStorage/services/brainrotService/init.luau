-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Config Modules
local brainrotConfig = require(ReplicatedStorage.src.GameConfiguration.General.brainrotConfig)
local mutationConfig = require(ReplicatedStorage.src.GameConfiguration.General.mutationConfig)

-- Constants
local BrainrotAssets = ReplicatedStorage.Assets.Brainrots

-- Helper Functions
local function isPlayer(player: Player)
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local BrainrotService = knit.CreateService({
	Name = "BrainrotService",
})

-- Client Exposed Methods
function BrainrotService.Client:SellBrainrot(player: Player, brainrotReferenceId: string)
	return self.Server:SellBrainrot(player, brainrotReferenceId)
end

function BrainrotService.Client:SellBrainrots(player: Player, brainrotReferenceIds: { string })
	return self.Server:SellBrainrots(player, brainrotReferenceIds)
end

-- Public Methods
function BrainrotService:SellBrainrot(player: Player, brainrotReferenceId: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")

	local brainrotData = self.DataService:GetValue(player, "Inventory")[brainrotReferenceId]
	if typeof(brainrotData) ~= "table" then
		return {
			Status = false,
			Reason = `You don't own this brainrot!`,
		}
	end

	local stand = self.StandService:GetStandFromBrainrotReferenceId(player, brainrotReferenceId)
	if stand then
		return {
			Status = false,
			Reason = `Remove {brainrotHandler.GetBrainrotDisplayName(brainrotReferenceId)} from its stand to sell!`,
		}
	end

	local level = brainrotData.Level
	local cost = brainrotHandler.GetBrainrotCost(brainrotReferenceId, level)

	self.InventoryService:Remove(player, brainrotReferenceId)
	self.CashService:manipulatePlayerCash(player, cost, "Addition")

	return {
		Status = true,
		SoldBrainrot = brainrotReferenceId,
		Cost = cost,
	}
end

function BrainrotService:SellBrainrots(player: Player, brainrotReferenceIds: { string })
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(brainrotReferenceIds) == "table", "brainrotReferenceIds arg must be a table")

	if #brainrotReferenceIds < 1 then
		return {
			Status = false,
			Reason = "Nothing to sell",
		}
	end

	for _, brainrotReferenceId: string in pairs(brainrotReferenceIds) do
		self:SellBrainrot(player, brainrotReferenceId)
	end

	return {
		Status = true,
	}
end

function BrainrotService:RngBrainrot(rarity: string)
	assert(typeof(rarity) == "string", "rarity arg must be a string")
	local brainrots = brainrotConfig[rarity]
	if not brainrots then
		warn(`Invalid rarity: {rarity}`)
		return nil
	end

	local totalWeight = 0
	for _, brainrotData in pairs(brainrots) do
		if brainrotData.Excluded then
			continue
		end
		totalWeight += brainrotData.SpawnWeight
	end

	if totalWeight <= 0 then
		warn(`No valid spawn weights for rarity: {rarity}`)
		return nil
	end

	local randomWeight = math.random(1, totalWeight)
	local currentWeight = 0

	for brainrotName, brainrotData in pairs(brainrots) do
		if brainrotData.Excluded then
			continue
		end

		currentWeight += brainrotData.SpawnWeight

		if randomWeight <= currentWeight then
			return brainrotName, brainrotData
		end
	end

	return nil
end

function BrainrotService:RngMutation()
	local mutations = mutationConfig

	local totalWeight = 0
	for mutation: string, data in pairs(mutations) do
		totalWeight += data.Weight
	end

	if totalWeight <= 0 then
		return nil
	end

	local randomWeight = math.random(1, totalWeight)
	local currentWeight = 0

	for mutation, mutationData in pairs(mutations) do
		currentWeight += mutationData.Weight

		if randomWeight <= currentWeight then
			return mutation, mutationData
		end
	end

	return nil
end

-- LifeCycle
function BrainrotService:KnitInit()
	self.InventoryService = knit.GetService("InventoryService")
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
	self.StandService = knit.GetService("StandService")

	for _, mutationFolder in pairs(BrainrotAssets:GetChildren()) do
		for _, brainrot in pairs(mutationFolder:GetChildren()) do
			local meshPart = brainrot:FindFirstChildOfClass("MeshPart")
			if meshPart then
				meshPart.CanCollide = false
				meshPart.Anchored = true
			end
		end
	end
end

return BrainrotService
