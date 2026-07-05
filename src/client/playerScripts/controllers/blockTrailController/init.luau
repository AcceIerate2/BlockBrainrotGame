-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local blocksConfig = require(ReplicatedStorage.src.GameConfiguration.General.blocksConfig)

-- Constants
local Player = Players.LocalPlayer
local BlockAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Blocks")
local CellSize = 4
local BlockHeight = 4

-- Helper Functions
local function isDead(): boolean
	return Player.Character
			and Player.Character:FindFirstChildOfClass("Humanoid")
			and Player.Character.Humanoid.Health < 1
		or false
end

local function getWorldPosition(): Vector3?
	local character = Player.Character
	if not character then
		return nil
	end

	local primaryPart = character.PrimaryPart
	if not primaryPart then
		return nil
	end

	return primaryPart.Position
end

local function getCellFromWorldPosition(base: BasePart, worldPosition: Vector3): (number?, number?)
	local localPosition = base.CFrame:PointToObjectSpace(worldPosition)

	local gridX = localPosition.X + base.Size.X / 2
	local gridZ = localPosition.Z + base.Size.Z / 2

	if gridX < 0 or gridZ < 0 or gridX >= base.Size.X or gridZ >= base.Size.Z then
		return nil, nil
	end

	local cellX = math.floor(gridX / CellSize)
	local cellZ = math.floor(gridZ / CellSize)

	return cellX, cellZ
end

local function getBlockCFrameFromCell(base: BasePart, cellX: number, cellZ: number): CFrame
	local localX = -base.Size.X / 2 + cellX * CellSize + CellSize / 2
	local localZ = -base.Size.Z / 2 + cellZ * CellSize + CellSize / 2
	local localY = base.Size.Y / 2 + BlockHeight / 2

	return base.CFrame * CFrame.new(localX, localY, localZ)
end

local function getBlockAsset(blockName: string): BasePart?
	assert(typeof(blockName) == "string", "blockName arg must be a string")

	local blockAsset = BlockAssets:FindFirstChild(blockName)
	if not blockAsset then
		warn(`Block asset [{blockName}] does not exist`)
		return nil
	end

	local clone = blockAsset:Clone()
	if not clone:IsA("BasePart") then
		warn(`Block asset [{blockName}] must be a BasePart for this prototype`)
		clone:Destroy()
		return nil
	end

	return clone
end

local function getCellKey(zone: Instance, cellX: number, cellZ: number): string
	return `{zone.Name}_{cellX}_{cellZ}`
end

-->
local BlockTrailController = knit.CreateController({
	Name = "BlockTrailController",

	Connection = nil,
	WaitForEnoughBlocks = false,

	LastCellX = nil,
	LastCellZ = nil,

	BlockIndex = 0,

	PlacedBlocks = {},
	PlacedCells = {},
})

-- Private Methods
function BlockTrailController:getBlockAsset(): BasePart?
	return getBlockAsset(self.DataController:GetValue("EquippedBlock"))
end

function BlockTrailController:getLastPlacedBlock(): (number?, BasePart?)
	for index = self.BlockIndex, 1, -1 do
		local block = self.PlacedBlocks[index]

		if block and block.Parent then
			return index, block
		end
	end

	return nil, nil
end

function BlockTrailController:place(zone: Instance, cellX: number, cellZ: number, blockCFrame: CFrame)
	assert(typeof(cellX) == "number", "cellX arg must be a number")
	assert(typeof(cellZ) == "number", "cellZ arg must be a number")
	assert(typeof(blockCFrame) == "CFrame", "blockCFrame arg must be a CFrame")

	if self.WaitForEnoughBlocks == true then
		return
	end

	local cellKey = getCellKey(zone, cellX, cellZ)
	if self.PlacedCells[cellKey] then
		return
	end

	local blockAsset = self:getBlockAsset()
	if not blockAsset then
		return
	end

	self.BlockIndex += 1

	local trailIndex = self.BlockIndex

	blockAsset.Name = `Block_{trailIndex}`
	blockAsset:SetAttribute("TrailIndex", trailIndex)
	blockAsset:SetAttribute("CellKey", cellKey)
	blockAsset:SetAttribute("OwnerUserId", Player.UserId)
	blockAsset:AddTag("Block")

	blockAsset.Anchored = true
	blockAsset.CanCollide = true
	blockAsset:PivotTo(blockCFrame)
	blockAsset.Parent = workspace

	self.PlacedBlocks[trailIndex] = blockAsset
	self.PlacedCells[cellKey] = trailIndex

	self.BlockTrailService
		:ValidatePlace(blockCFrame)
		:andThen(function(response)
			if response.Status then
				return
			end

			if blockAsset.Parent then
				blockAsset:Destroy()
			end

			self.PlacedBlocks[trailIndex] = nil
			self.PlacedCells[cellKey] = nil

			if response.Reason == "NotEnoughBlocks" then
				self.WaitForEnoughBlocks = true
			end
		end)
		:catch(warn)
end

-- Public Methods
function BlockTrailController:ClearLocalTrail()
	for _, block in pairs(self.PlacedBlocks) do
		if block and block.Parent then
			block:Destroy()
		end
	end

	table.clear(self.PlacedBlocks)
	table.clear(self.PlacedCells)

	self.BlockIndex = 0
	self.LastCellX = nil
	self.LastCellZ = nil
	self.WaitForEnoughBlocks = false
end

function BlockTrailController:Connect(payload: { Asset: any, ZoneType: string, LastZoneType: string })
	local zone = payload.Asset
	local base = zone.Parent:FindFirstChild("Base")
	if not base or not base:IsA("BasePart") then
		return
	end

	self:Disconnect()
	self.LastCellX = nil
	self.LastCellZ = nil

	local block = self.DataController:GetValue("EquippedBlock")
	local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = blocksConfig.DefaultWalkSpeed * blocksConfig.Blocks[block].WalkSpeedMultiplier
	end

	self.Connection = RunService.RenderStepped:Connect(function()
		if self.WaitForEnoughBlocks == true or isDead() or self.ZoneController.Zone ~= "BlockTrail" then
			return
		end

		local worldPosition = getWorldPosition()
		if not worldPosition then
			return
		end

		local cellX, cellZ = getCellFromWorldPosition(base, worldPosition)
		if cellX == nil or cellZ == nil then
			return
		end

		if self.LastCellX == cellX and self.LastCellZ == cellZ then
			return
		end

		self.LastCellX = cellX
		self.LastCellZ = cellZ

		local blockCFrame = getBlockCFrameFromCell(base, cellX, cellZ)
		self:place(zone, cellX, cellZ, blockCFrame)
	end)
end

function BlockTrailController:Disconnect()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end

	self.LastCellX = nil
	self.LastCellZ = nil

	local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = blocksConfig.DefaultWalkSpeed
	end
end

-- LifeCycle
function BlockTrailController:KnitInit()
	self.BlockTrailService = knit.GetService("BlockTrailService")
	self.DataController = knit.GetController("DataController")
	self.NotificationController = knit.GetController("NotificationController")
	self.ZoneController = knit.GetController("ZoneController")
end

function BlockTrailController:KnitStart()
	local function update(remainingBlocks: number)
		self.WaitForEnoughBlocks = remainingBlocks < 1 or false
	end

	update(self.DataController:GetValue("Blocks").Value)
	self.DataController:GetValueChangedSignal("Blocks"):Connect(function(data: { Value: number, Level: number })
		update(data.Value)
	end)

	self.DataController:GetValueChangedSignal("EquippedBlock"):Connect(function(newBlock: string)
		if #self.PlacedBlocks >= 1 then
			local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = blocksConfig.DefaultWalkSpeed * blocksConfig.Blocks[newBlock].WalkSpeedMultiplier
			end
		end
	end)

	self.ZoneController.ZoneChanged:Connect(function(newZone: string)
		if newZone == "BrainrotSpawn" or newZone == "BlockTrail" then
			return
		end
		self:ClearLocalTrail()
	end)
end

return BlockTrailController
