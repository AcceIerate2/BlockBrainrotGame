-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)
local Signal = require(ReplicatedStorage.src.Packages.Signal)

-- Config Modules
local blocksConfig = require(ReplicatedStorage.src.GameConfiguration.General.blocksConfig)

-- Types
type BlockState = {
	Equipped: boolean,
	Owned: boolean,
}

-->
local BlockController = knit.CreateController({
	Name = "BlockController",
	States = {},
	UpdateCardState = Signal.new(), -- :Fire(cardName: string, props: {Equipped: boolean, Owned: boolean})
})

-- Private Methods
function BlockController:listenToDataController()
	self.DataController:GetValueChangedSignal("EquippedBlock"):Connect(function(equippedBlock: string)
		assert(typeof(equippedBlock) == "string", "equippedBlock arg must be a string")
		for blockName: string, blockState: BlockState in pairs(self.States) do
			blockState.Equipped = blockName == equippedBlock
			self.UpdateCardState:Fire(blockName, blockState)
		end
	end)

	self.DataController
		:GetValueChangedSignal("OwnedBlocks")
		:Connect(function(ownedBlocks: { [string]: { Cost: number } })
			assert(typeof(ownedBlocks) == "table", "ownedBlocks arg must be a table")
			for blockName: string, blockState: BlockState in pairs(self.States) do
				blockState.Owned = ownedBlocks[blockName] ~= nil or false
				self.UpdateCardState:Fire(blockName, blockState)
			end
		end)
end

-- Public Methods
function BlockController:IsEquipped(blockName: string): boolean
	assert(typeof(blockName) == "string", "blockName arg must be a string")
	return self.States[blockName].Equipped
end

function BlockController:OwnsBlock(blockName: string): boolean
	assert(typeof(blockName) == "string", "blockName")
	return self.States[blockName].Owned
end

function BlockController:GetBlockState(blockName: string)
	return self.States[blockName]
end

function BlockController:GetState(blockName: string)
	assert(typeof(blockName) == "string", "blockName")
	return self.States[blockName]
end

function BlockController:ToggleBlock(blockName: string)
	assert(typeof(blockName) == "string", "blockName arg must be a string")
	self.BlockService
		:Toggle(blockName)
		:andThen(function(response: { Status: boolean })
			warn(response)
		end)
		:catch(warn)
end

-- LifeCycle
function BlockController:KnitInit()
	self.BlockService = knit.GetService("BlockService")
	self.DataController = knit.GetController("DataController")

	for blockName: string, _ in pairs(blocksConfig.Blocks) do
		self.States[blockName] = {
			Equipped = self.DataController:GetValue("EquippedBlock") == blockName or false,
			Owned = self.DataController:GetValue("OwnedBlocks")[blockName] or false,
		}
	end
end

function BlockController:KnitStart()
	self:listenToDataController()
end

return BlockController
