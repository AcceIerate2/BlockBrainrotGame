-- Roblox Services
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local FormatTime = require(ReplicatedStorage.src.utility.FormatTime)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local Spring = require(ReplicatedStorage.src.utility.Spring)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)
local luckyBlockHandler = require(ReplicatedStorage.src.utility.luckyBlockHandler)

-- Config Modules
local luckyBlocksConfig = require(ReplicatedStorage.src.GameConfiguration.General.luckyBlocksConfig)

-- Helper Functions
local function isPlayer(player: Player): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local LuckyBlockService = knit.CreateService({
	Name = "LuckyBlockService",
	Connections = {} :: { [Player]: { [any]: { RBXScriptConnection } } },
})

-- Private Methods
function LuckyBlockService:addUiHeader(luckyBlock) end

-- Public Methods
function LuckyBlockService:RngItem(luckyBlockName: string, itemType: "Brainrots" | "Mutations")
	assert(typeof(luckyBlockName) == "string", "luckyBlockName arg must be a string")
	local items = luckyBlocksConfig.LuckyBlocks[luckyBlockName][itemType]
	if not items then
		return nil
	end

	local totalWeight = 0
	for _, itemData in pairs(items) do
		totalWeight += itemData.SpawnWeight
	end

	if totalWeight <= 0 then
		return nil
	end

	local randomWeight = math.random(1, totalWeight)
	local currentWeight = 0

	for itemName, itemData in pairs(items) do
		currentWeight += itemData.SpawnWeight
		if randomWeight <= currentWeight then
			return itemName, itemData
		end
	end

	return nil
end

function LuckyBlockService:GetBlockAsset(luckyBlock: string, shouldClone: boolean)
	assert(typeof(luckyBlock) == "string", "luckyBlock arg must be a string")
	local luckyBlockAsset = ReplicatedStorage.Assets.LuckyBlocks:FindFirstChild(luckyBlock)
	if shouldClone then
		luckyBlockAsset = luckyBlockAsset:Clone()
		luckyBlockHandler.AddUiHeader(luckyBlockAsset, luckyBlock)
		luckyBlockHandler.AnimateBlock(luckyBlockAsset)
		luckyBlockAsset.PrimaryPart.CanCollide = false
		luckyBlockAsset.PrimaryPart.CanQuery = false
	end
	return luckyBlockAsset
end

function LuckyBlockService:RevealBrainrot(player: Player, luckyBlock: any)
	assert(isPlayer(player), "player arg must be a Player Instance")

	self.InventoryService:Remove(player, luckyBlock.Name)
	self.InventoryService:RemoveTool(player, luckyBlock.Name)

	local level = luckyBlock:GetAttribute("Level")
	local brainrot = self:RngItem(luckyBlock.Name:split("_")[1], "Brainrots")
	local mutation = self:RngItem(luckyBlock.Name:split("_")[1], "Mutations") or "Default"
	local guid = HttpService:GenerateGUID(false)
	local referenceId = `{brainrot}_{guid}`

	local stand = self.StandService:GetStandFromBrainrotReferenceId(player, luckyBlock.Name)
	local standProfileReference = self.StandService:getProfileReference(stand)

	self:DisconnectAssetConnections(player, luckyBlock)
	self.Connections[player][luckyBlock] = nil

	self.InventoryService:Give(player, referenceId, "BrainrotTool", {
		Level = level,
		Mutation = mutation,
		Type = "Brainrot",
	}, true)

	self.StandService:removeBrainrot(standProfileReference, true)
	self.StandService:placeBrainrot(standProfileReference, referenceId, true)

	local brainrotAsset = stand.Brainrot:FindFirstChildOfClass("Model")
	brainrotAsset:FindFirstChildOfClass("MeshPart").Transparency = 1
	brainrotAsset:FindFirstChildOfClass("MeshPart"):FindFirstChildOfClass("BillboardGui").Enabled = false

	local duration = 6
	for i = 12, 1, -1 do
		for brainrotReferenceId: string, data in
			pairs(luckyBlocksConfig.LuckyBlocks[luckyBlock.Name:split("_")[1]].Brainrots)
		do
			local newBrainrot = brainrotHandler.GetBrainrotAsset(brainrotReferenceId, "Default", true, true)
			newBrainrot:PivotTo(stand.Placeholder:GetPivot())
			newBrainrot.Parent = workspace

			InstanceCreator("Highlight", "Highlight", newBrainrot, {
				FillTransparency = 0,
				OutlineTransparency = 1,
				FillColor = Color3.fromRGB(0, 0, 0),
				DepthMode = Enum.HighlightDepthMode.Occluded,
			})

			local scale = newBrainrot:GetScale()
			newBrainrot:ScaleTo(0.01)
			Spring.target(newBrainrot, 0.75, duration, {
				Scale = scale,
			})

			duration -= 0.25

			local completed = false
			Spring.completed(newBrainrot, function()
				newBrainrot:Destroy()
				completed = true
			end)

			repeat
				task.wait()
			until completed
		end
	end

	brainrotAsset:FindFirstChildOfClass("MeshPart").Transparency = 0
	brainrotAsset:FindFirstChildOfClass("MeshPart"):FindFirstChildOfClass("BillboardGui").Enabled = true

	Spring.target(brainrotAsset, 2, 6, {
		Scale = brainrotAsset:GetScale() * 1.25,
	})

	Spring.completed(brainrotAsset, function()
		brainrotAsset:ScaleTo(brainrotAsset:GetAttribute("DefaultScale"))
	end)
end

function LuckyBlockService:ConnectTimer(player: Player, luckyBlock: any, expiresAt: number)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(expiresAt) == "number", "expiresAt arg must be a number")

	luckyBlock:SetAttribute("Level", math.random(1, 10))
	if
		self.DataService:GetValue(player, "Inventory")[luckyBlock.Name]
		and not self.DataService:GetValue(player, "Inventory")[luckyBlock.Name].ExpiresAt
	then
		self.DataService:GetValueObject(player, "Inventory"):Update(function(_table)
			_table[luckyBlock.Name].ExpiresAt = expiresAt
		end)
	end

	local profile = self.Connections[player]
	if profile[luckyBlock] then
		warn(`LuckyBlock already exists in profile connections`)
		return
	end

	profile[luckyBlock] = {}

	local stand = self.StandService:GetStandFromBrainrotReferenceId(player, luckyBlock.Name)
	local proximityPrompt =
		InstanceCreator("ProximityPrompt", "ProximityPrompt_LuckyBlockReveal", stand:WaitForChild("ProximityPrompt"), {
			ActionText = "Reveal",
			ObjectText = luckyBlockHandler.GetDisplayNameFromReferenceId(luckyBlock.Name),
			HoldDuration = 0,
			UIOffset = Vector2.new(0, -80),
			RequiresLineOfSight = false,
			MaxActivationDistance = 5,
			KeyboardKeyCode = Enum.KeyCode.F,
			GamepadKeyCode = Enum.KeyCode.ButtonY,
		}) :: ProximityPrompt

	local secondsLeft = math.clamp(expiresAt - os.time(), 0, math.huge)
	proximityPrompt.ActionText = `Not Ready ({secondsLeft > 60 and FormatTime(
		secondsLeft,
		secondsLeft <= 3600 and true or false
	) or secondsLeft})`
	luckyBlockHandler.UpdateCountdown(luckyBlock, secondsLeft)

	luckyBlockHandler.ToggleCountdownState(luckyBlock, true)
	local elapsed = 0
	table.insert(
		profile[luckyBlock],
		RunService.Heartbeat:Connect(function(deltaTime: number)
			elapsed += deltaTime
			if elapsed < 1 then
				return
			end

			elapsed = 0
			secondsLeft = math.clamp(expiresAt - os.time(), 0, math.huge)
			luckyBlockHandler.UpdateCountdown(luckyBlock, secondsLeft)
			proximityPrompt.ActionText = `Not Ready ({secondsLeft > 60 and FormatTime(
				secondsLeft,
				secondsLeft <= 3600 and true or false
			) or secondsLeft})`

			if secondsLeft < 1 then
				proximityPrompt.ActionText = `Reveal`
				luckyBlockHandler.ToggleCountdownState(luckyBlock, false)
				self:DisconnectAssetConnections(player, luckyBlock)

				table.insert(
					profile[luckyBlock],
					proximityPrompt.Triggered:Connect(function(playerWhoTriggered: Player)
						if playerWhoTriggered == player then
							proximityPrompt:Destroy()
							self:RevealBrainrot(player, luckyBlock)
						end
					end)
				)
			end
		end)
	)
end

function LuckyBlockService:DisconnectAssetConnections(player: Player, luckyBlock: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self.Connections[player]
	for _, connection in pairs(profile[luckyBlock] or {}) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	table.clear(profile[luckyBlock] or {})
end

function LuckyBlockService:ConnectPlayer(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	self.Connections[player] = {}
	for referenceId: string, expiresAt: number in pairs(self.DataService:GetValue(player, "LuckyBlockCountdowns")) do
		local blockAsset = self.StandService:GetLuckyBlockFromReferenceId(player, referenceId)
		self:ConnectTimer(player, blockAsset)
	end

	return {
		Function = self.DisconnectPlayer,
		Args = {
			self,
			player,
		},
	}
end

function LuckyBlockService:DisconnectPlayer(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self.Connections[player]
	for luckyBlockAsset, connections in pairs(profile) do
		for _, connection: RBXScriptConnection in pairs(connections) do
			if typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			end
		end
		table.clear(connections)
	end
	self.Connections[player] = nil
end

-- LifeCycle
function LuckyBlockService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.InventoryService = knit.GetService("InventoryService")
	self.StandService = knit.GetService("StandService")
end

return LuckyBlockService
