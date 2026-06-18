-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Config Modules
local brainrotConfig = require(ReplicatedStorage.src.GameConfiguration.General.brainrotConfig)
local mutationConfig = require(ReplicatedStorage.src.GameConfiguration.General.mutationConfig)

-- Constants
local BrainrotAssets = ReplicatedStorage.Assets.Brainrots

-->
local BrainrotService = knit.CreateService({
	Name = "BrainrotService",
})

-- Private Methods
-- Public Methods
function BrainrotService:GetBrainrotAsset(brainrotName: string, mutation: string, shouldClone: boolean)
	assert(typeof(brainrotName) == "string", "brainrotName arg must be a string")
	assert(typeof(mutation) == "string", "mutation arg must be a string")

	brainrotName = brainrotHandler.GetBrainrotNameFromReferenceId(brainrotName)
	mutation = typeof(mutation) == "string" and mutation or "Default"

	local brainrotAsset = BrainrotAssets:FindFirstChild(mutation):FindFirstChild(brainrotName)
	return shouldClone and brainrotAsset:Clone() or brainrotAsset
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
