-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local SafeFunctionCaller = require(ReplicatedStorage.src.utility.SafeFunctionCaller)

-- Helper Functions
local function isPlayer(player: Player): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local GroupRewardService = knit.CreateService({
	Name = "GroupRewardService",
	Client = {},
})

-- Client Exposed Methods
function GroupRewardService.Client:ClaimReward(player: Player)
	return self.Server:ClaimReward(player)
end

-- Private Methods
function GroupRewardService:playerInGroup(player: Player): boolean
	local status: boolean, inGroup: boolean = SafeFunctionCaller(player.IsInGroupAsync, player, 35678105)
	return status and inGroup or false
end

function GroupRewardService:rewardPlayer(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	warn("Gave Reward")
end

-- Public Methods
function GroupRewardService:RewardClaimed(player: Player): boolean
	assert(isPlayer(player), "player arg must be a Player Instance")
	return self.DataService:GetValue(player, "GroupRewardClaimed")
end

function GroupRewardService:ClaimReward(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	if self:RewardClaimed(player) then
		return {
			Status = false,
			Reason = "You already claimed this!",
		}
	end

	if not self:playerInGroup(player) then
		return {
			Status = false,
			Reason = "You are not in the group!",
		}
	end

	self:rewardPlayer(player)
	self.DataService:GetValueObject(player, "GroupRewardClaimed"):Set(true)

	return { Status = false }
end

-- LifeCycle
function GroupRewardService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.InventoryService = knit.GetService("InventoryService")
end

return GroupRewardService
