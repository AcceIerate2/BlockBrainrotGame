-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local BlockTrailService = knit.CreateService({
	Name = "BlockTrailService",
	Client = {
		ClearLocalTrail = knit.CreateSignal(),
	},

	PlayerBlocks = {} :: { [Player]: number },
	Blocks = {} :: { [Player]: { BasePart } },
})

-- Client Exposed Methods
function BlockTrailService.Client:ValidatePlace(player: Player, blockCFrame: CFrame)
	return self.Server:ValidatePlace(player, blockCFrame)
end

-- Private Methods
-- Public Methods
function BlockTrailService:ClearBlocks(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	self.PlayerBlocks[player] = nil
end

function BlockTrailService:RefundBlocks(player: Player, clearLocalTrail: boolean)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local blocksValueObject = self.DataService:GetValueObject(player, "Blocks")
	if not blocksValueObject then
		return
	end

	blocksValueObject:Update(function(_table)
		_table.Value += (self.PlayerBlocks[player] or 0)
	end)
	self:ClearBlocks(player)

	if clearLocalTrail then
		self.Client.ClearLocalTrail:Fire(player)
	end
end

function BlockTrailService:ValidatePlace(player: Player, blockCFrame: CFrame)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(blockCFrame) == "CFrame", "blockCFrame arg must be a CFrame")

	local blocksValueObject = self.DataService:GetValueObject(player, "Blocks")
	if blocksValueObject:Get().Value < 1 then
		return {
			Status = false,
			Reason = "NotEnoughBlocks",
		}
	end

	blocksValueObject:Update(function(_table)
		_table.Value = _table.Value - 1
	end)

	if typeof(self.PlayerBlocks[player]) ~= "number" then
		self.PlayerBlocks[player] = 0
	end
	self.PlayerBlocks[player] += 1

	return {
		Status = true,
	}
end

-- LifeCycle
function BlockTrailService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

function BlockTrailService:KnitStart() end

return BlockTrailService
