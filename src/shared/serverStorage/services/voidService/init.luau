-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)

-->
local VoidService = knit.CreateService({
	Name = "VoidService",
	Client = {},
	Connections = {} :: { [BasePart]: RBXScriptConnection },
})

-- Private Methods
function VoidService:connectPart(basePart: BasePart)
	self:disconnectPart(basePart)
	self.Connections[basePart] = basePart.Touched:Connect(function(partThatTouched)
		local character = partOfCharacter(partThatTouched)
		if not character then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid.Health ~= 0 then
			humanoid.Health = 0
			if self.CarryService:PlayerIsCarrying(player) then
				self.BlockTrailService:ClearBlocks(player)
				self.CarryService:DropAll(player, true)
			else
				self.BlockTrailService:RefundBlocks(player)
			end
		end
	end)
end

function VoidService:disconnectPart(basePart: BasePart)
	local connection = self.Connections[basePart]
	if typeof(connection) == "RBXScriptConnection" then
		connection:Disconnect()
	end
	self.Connections[basePart] = nil
end

function VoidService:listenToTagChanges()
	for _, voidPart in pairs(CollectionService:GetTagged("Void")) do
		self:connectPart(voidPart)
	end

	CollectionService:GetInstanceAddedSignal("Void"):Connect(function(voidPart)
		self:connectPart(voidPart)
	end)

	CollectionService:GetInstanceRemovedSignal("Void"):Connect(function(voidPart)
		self:disconnectPart(voidPart)
	end)
end

-- LifeCycle
function VoidService:KnitInit()
	self.BlockTrailService = knit.GetService("BlockTrailService")
	self.CarryService = knit.GetService("CarryService")
end

function VoidService:KnitStart()
	self:listenToTagChanges()
end

return VoidService
