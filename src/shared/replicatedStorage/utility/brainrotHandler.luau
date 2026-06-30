-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local brainrotConfig = require(ReplicatedStorage.src.GameConfiguration.General.brainrotConfig)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local BrainrotHandler = {}

function BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId: string)
	return brainrotReferenceId:find("_") and brainrotReferenceId:split("_")[1] or brainrotReferenceId
end

function BrainrotHandler.GetBrainrotDisplayName(brainrotReferenceId: string)
	local name = brainrotReferenceId:find("_") and brainrotReferenceId:split("_")[1] or brainrotReferenceId
	return name:gsub("%u", " %0"):gsub("^%s+", "")
end

function BrainrotHandler.GetMutationFromBrainrotReferenceId(brainrotReferenceId: string, player: Player?): string
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")

	local mutation
	if RunService:IsServer() then
		mutation = knit.GetService("DataService"):GetValue(player, "Inventory")[brainrotReferenceId].Mutation
			or "Default"
	elseif RunService:IsClient() then
		mutation = knit.GetController("DataController"):GetValue("Inventory")[brainrotReferenceId].Mutation
	end

	return typeof(mutation) == "string" and mutation or "Default"
end

function BrainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId: string, player: Player?): number
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")

	local level
	if RunService:IsServer() then
		level = knit.GetService("DataService"):GetValue(player, "Inventory")[brainrotReferenceId].Level or 1
	elseif RunService:IsClient() then
		level = knit.GetController("DataController"):GetValue("Inventory")[brainrotReferenceId].Level or 1
	end

	return typeof(level) == "number" and level or 1
end

function BrainrotHandler.GetBrainrotRarity(brainrotReferenceId: string): string
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local brainrotName = BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)
	for rarity, brainrots in pairs(brainrotConfig) do
		if brainrots[brainrotName] then
			return rarity
		end
	end
	return "Common"
end

function BrainrotHandler.GetBrainrotIncomeRate(brainrotReferenceId: string, level: number?, player: Player)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local _level = level or BrainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId, player)
	return BrainrotHandler.GetBrainrotBaseIncomeRate(brainrotReferenceId) * 1.1 ^ _level
end

function BrainrotHandler.GetBrainrotBaseIncomeRate(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local brainrotName = BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)
	local rarity = BrainrotHandler.GetBrainrotRarity(brainrotReferenceId)
	return brainrotConfig[rarity][brainrotName].IncomeRate
end

function BrainrotHandler.GetBrainrotBaseCost(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	return BrainrotHandler.GetBrainrotBaseIncomeRate(brainrotReferenceId) * 10
end

function BrainrotHandler.GetBrainrotCost(brainrotReferenceId: string, level: number?, player: Player?)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local _level = level or BrainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId, player)
	return BrainrotHandler.GetBrainrotBaseCost(brainrotReferenceId) * (_level ^ 1.2)
end

function BrainrotHandler.CalculateLevelCost(brainrotReferenceId: string, level: number)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	assert(typeof(level) == "number", "level arg must be a number")
	local baseCost = BrainrotHandler.GetBrainrotBaseCost(brainrotReferenceId)
	return baseCost * (level ^ 1.2)
end

function BrainrotHandler.GetBrainrotIcon(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local brainrotName = BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)
	local rarity = BrainrotHandler.GetBrainrotRarity(brainrotReferenceId)
	return brainrotConfig[rarity][brainrotName].Icon
end

function BrainrotHandler.GetBrainrotAnimations(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local brainrotName = BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)
	local rarity = BrainrotHandler.GetBrainrotRarity(brainrotReferenceId)
	return brainrotConfig[rarity][brainrotName].AnimationIds
end

return BrainrotHandler
