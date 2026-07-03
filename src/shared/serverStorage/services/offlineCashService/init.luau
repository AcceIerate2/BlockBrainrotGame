-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Config Modules
local offlineCashConfig = require(ReplicatedStorage.src.GameConfiguration.General.offlineCashConfig)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local OfflineCashService = knit.CreateService({
	Name = "OfflineCashService",
	Client = {},
	ClaimedProfiles = {},
})

-- Client Exposed Methods
function OfflineCashService.Client:CalculateOfflineCashReward(player: Player): number
	return self.Server:CalculateOfflineCashReward(player)
end

function OfflineCashService.Client:RewardPlayerOfflineCash(player: Player)
	return self.Server:RewardPlayerOfflineCash(player)
end

-- Public Methods
function OfflineCashService:GetLastSessionTimeStamp(player: Player): number
	assert(isPlayer(player), "player arg must be a Player Instance")
	return self.DataService:GetValue(player, "LastSession")
end

function OfflineCashService:CalculateOfflineCashReward(player: Player): number
	assert(isPlayer(player), "player arg must be a Player Instance")
	local lastSessionTimeStamp = self:GetLastSessionTimeStamp(player)
	local now = os.time()

	local offlineDuration = math.clamp(now - (lastSessionTimeStamp or now), 0, offlineCashConfig.MaxOfflineSeconds)
	local totalIncome = 0
	local reward

	local brainrots =
		self.StandService:GetBrainrotsOnStand(player) :: { { BrainrotReferenceId: string, Mutation: string } }
	for _, brainrotConfig in pairs(brainrots) do
		local income = brainrotHandler.GetBrainrotIncomeRate(brainrotConfig.BrainrotReferenceId, nil, player)
		totalIncome += income
	end

	reward = totalIncome * offlineDuration * offlineCashConfig.OfflineEfficiency
	return reward
end

function OfflineCashService:RewardPlayerOfflineCash(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local reward = self:CalculateOfflineCashReward(player)
	if reward <= 0 then
		return { Status = false }
	end

	self.ClaimedProfiles[player] = true
	self.CashService:manipulatePlayerCash(player, reward, "Addition")
	return {
		Status = true,
	}
end

function OfflineCashService:ClearPlayerReferences(player: Player)
	self.ClaimedProfiles[player] = nil
end

-- LifeCycle
function OfflineCashService:KnitInit()
	self.CashService = knit.GetService("CashService")
	self.StandService = knit.GetService("StandService")
	self.DataService = knit.GetService("DataService")
end

return OfflineCashService
