-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local blocksConfig = require(ReplicatedStorage.src.GameConfiguration.General.blocksConfig)

-- Helper Functions
local function isPlayer(player: Player)
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local BlockService = knit.CreateService({
	Name = "BlockService",
	Client = {},
})

-- Client Exposed Methods
function BlockService.Client:Toggle(player: Player, blockName: string)
	return self.Server:Toggle(player, blockName)
end

-- Private Methods
function BlockService:blockIsEquipped(player: Player, blockName: string): boolean
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(blockName) == "string", "blockName arg must be a string")
	return self.DataService:GetValue(player, "EquippedBlock") == blockName
end

-- Public Methods
function BlockService:OwnsBlock(player: Player, blockName: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(blockName) == "string", "blockName arg must be a string")
	return self.DataService:GetValue(player, "OwnedBlocks")[blockName] ~= nil
end

function BlockService:GiveBlock(player: Player, blockName: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(blockName) == "string", "blockName arg must be a string")

	if self:OwnsBlock(player, blockName) then
		return
	end

	self.DataService:GetValueObject(player, "OwnedBlocks"):Update(function(_oldTable)
		_oldTable[blockName] = true
	end)
end

function BlockService:Toggle(player: Player, blockName: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(blockName) == "string", "blockName arg must be a string")

	if self:blockIsEquipped(player, blockName) then
		return {
			Status = false,
			Reason = `{blockName} is already Equipped!`,
		}
	end

	if not self:OwnsBlock(player, blockName) then
		local blockConfig = blocksConfig.Blocks[blockName]
		local canAfford = self.CashService:canAfford(player, blockConfig.Cost)
		if not canAfford then
			return {
				Status = false,
				Reason = `You need ${NumberShortner(blockConfig.Cost - self.DataService:GetValue(player, "Cash"))} more`,
			}
		end

		self.CashService:manipulatePlayerCash(player, -blockConfig.Cost, "Addition")
		self:GiveBlock(player, blockName)
	end

	self.DataService:GetValueObject(player, "EquippedBlock"):Set(blockName)

	return {
		Status = true,
		Equipped = true,
	}
end

-- LifeCycle
function BlockService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
end

return BlockService
