-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Config Modules
local brainrotConfig = require(ReplicatedStorage.src.GameConfiguration.General.brainrotConfig)
local mutationConfig = require(ReplicatedStorage.src.GameConfiguration.General.mutationConfig)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

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

-- Private Methods
function BrainrotService:animateBrainrot(brainrotAsset: any)
	local animationController = brainrotAsset and brainrotAsset:FindFirstChildOfClass("AnimationController")
	local animator = animationController and animationController:FindFirstChildOfClass("Animator")
	if not animator then
		animator = InstanceCreator("Animator", "Animator", animationController)
	end

	local animationId = brainrotHandler.GetBrainrotAnimations(brainrotAsset.Name).Idle
	local animationInstance = InstanceCreator("Animation", "IdleAnimation", brainrotAsset, {
		AnimationId = animationId,
	})

	local loadedAnimationTrack = animator:LoadAnimation(animationInstance)
	animationInstance:Destroy()

	loadedAnimationTrack:Play()
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

function BrainrotService:GetBrainrotAsset(brainrotName: string, mutation: string, shouldClone: boolean)
	assert(typeof(brainrotName) == "string", "brainrotName arg must be a string")
	assert(typeof(mutation) == "string", "mutation arg must be a string")

	brainrotName = brainrotHandler.GetBrainrotNameFromReferenceId(brainrotName)
	mutation = typeof(mutation) == "string" and mutation or "Default"

	local brainrotAsset = BrainrotAssets:FindFirstChild(mutation):FindFirstChild(brainrotName)
	if shouldClone then
		brainrotAsset = brainrotAsset:Clone()
		self:animateBrainrot(brainrotAsset)
	end

	return brainrotAsset
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
		totalWeight += brainrotData.SpawnWeight
	end

	if totalWeight <= 0 then
		warn(`No valid spawn weights for rarity: {rarity}`)
		return nil
	end

	local randomWeight = math.random(1, totalWeight)
	local currentWeight = 0

	for brainrotName, brainrotData in pairs(brainrots) do
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
