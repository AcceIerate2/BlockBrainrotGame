-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local NetworkOwnerHandler = require(ReplicatedStorage.src.utility.NetworkOwnerHandler)

-- Types
type Profile = {
	Amount: number,
	IsCarrying: boolean,
	Assets: { [any]: { Instances: { any }, Asset: any, Index: number } },
}

-- Helper functions
local function isPlayer(player: Player)
	return typeof(player) == "Instance" and player:IsA("Player")
end

local function toggleMeshPart(meshPart: MeshPart, toggle: boolean)
	assert(typeof(meshPart) == "Instance" and meshPart:IsA("MeshPart"), "meshPart arg must be a MeshPart")
	assert(typeof(toggle) == "boolean", "toggle arg must be a boolean")
	meshPart.Anchored = not toggle
	meshPart.CanCollide = false
	meshPart.CanTouch = false
	meshPart.Massless = true
end

local function getAttachments(character: any, meshPart: MeshPart, yOffset, amount: number): (Attachment, Attachment)
	assert(typeof(character) ~= "nil", "character arg should not be nil")
	local headAttachment = InstanceCreator("Attachment", `CarryHeadAttachment_{amount}`, character.Head, {
		CFrame = CFrame.new(0, yOffset, 0),
	}) :: Attachment

	local meshPartAttachment = InstanceCreator("Attachment", `CarryAssetAttachment`, meshPart, {
		CFrame = CFrame.new(0, -meshPart.Size.Y / 2, 0),
	}) :: Attachment

	return headAttachment, meshPartAttachment
end

local function connectAlignPosition(
	headAttachment: Attachment,
	meshPartAttachment: Attachment,
	parent: any
): AlignPosition
	assert(
		typeof(headAttachment) == "Instance" and headAttachment:IsA("Attachment"),
		"headAttachment arg must be an Attachment"
	)

	assert(
		typeof(meshPartAttachment) == "Instance" and meshPartAttachment:IsA("Attachment"),
		"meshPartAttachment arg must be an Attachment"
	)

	return InstanceCreator("AlignPosition", "AlignPosition", parent, {
		Attachment0 = meshPartAttachment,
		Attachment1 = headAttachment,
		MaxForce = math.huge,
		Responsiveness = 200,
		MaxTorque = math.huge,
		Enabled = true,
	}) :: AlignPosition
end

local function connectAlignOrientation(
	headAttachment: Attachment,
	meshPartAttachment: Attachment,
	parent: any
): AlignOrientation
	assert(
		typeof(headAttachment) == "Instance" and headAttachment:IsA("Attachment"),
		"headAttachment arg must be an Attachment"
	)

	assert(
		typeof(meshPartAttachment) == "Instance" and meshPartAttachment:IsA("Attachment"),
		"meshPartAttachment arg must be an Attachment"
	)

	return InstanceCreator("AlignOrientation", "AlignOrientation", parent, {
		Attachment0 = meshPartAttachment,
		Attachment1 = headAttachment,
		MaxForce = math.huge,
		Responsiveness = 200,
		MaxTorque = math.huge,
		Enabled = true,
	}) :: AlignOrientation
end

-->
local CarryService = knit.CreateService({
	Name = "CarryService",
	Client = {
		BrainrotAdded = knit.CreateSignal(),
		BrainrotRemoved = knit.CreateSignal(),
	},
	Profiles = {},
})

-- Client Exposed Methods
function CarryService.Client:Drop(player: Player, shouldDrop: boolean)
	return self.Server:Drop(player, shouldDrop)
end

-- Private Methods
function CarryService:calculateAttachmentYOffset(player: Player): number
	assert(isPlayer(player), "player arg must be a Player Instance")
	local head = player.Character and player.Character:FindFirstChild("Head") :: any
	local offset = head.Size.Y / 2

	local profile = self:getProfile(player) :: Profile
	for asset, assetData in pairs(profile.Assets) do
		local height = asset:GetExtentsSize().Y
		offset += height
	end

	return offset
end

function CarryService:getProfile(player: Player): Profile
	assert(isPlayer(player), "player arg must be a Player Instance")
	return self.Profiles[player]
end

function CarryService:canCarryMore(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	return self.DataService:GetValue(player, "MaxHold").Value > self:getProfile(player).Amount
end

function CarryService:getLatestBrainrotAssetProfile(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local highestIndex = 0
	local brainrotConfigToReturn

	local profile = self:getProfile(player) :: Profile
	for asset, assetConfig in pairs(profile.Assets) do
		if assetConfig.Index > highestIndex then
			highestIndex = assetConfig.Index
			brainrotConfigToReturn = assetConfig
		end
	end

	return brainrotConfigToReturn.Asset
end

-- Public Methods
function CarryService:GetActiveBrainrots(player: Player): { string }
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self:getProfile(player) :: Profile
	local brainrotNames = {}
	for asset, _ in pairs(profile.Assets) do
		table.insert(brainrotNames, asset.Name)
	end
	return brainrotNames
end

function CarryService:PlayerIsCarrying(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	return typeof(self:getProfile(player)) == "table" and self:getProfile(player).IsCarrying or false
end

function CarryService:Carry(player: Player, brainrotAsset: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(brainrotAsset) ~= "nil", "brainrotAsset arg must not be nil")
	if not self:canCarryMore(player) or not player.Character then
		return
	end

	local humanoid, head = player.Character:FindFirstChildOfClass("Humanoid"), player.Character:FindFirstChild("Head")
	if not humanoid or humanoid.Health < 1 or not head then
		return
	end

	local meshPart = brainrotAsset:FindFirstChildOfClass("MeshPart")
	toggleMeshPart(meshPart, true)
	NetworkOwnerHandler(meshPart, player)

	local profile = self:getProfile(player) :: Profile
	profile.IsCarrying = true
	profile.Amount += 1

	local headAttachment: Attachment, meshPartAttachment: Attachment =
		getAttachments(player.Character, meshPart, self:calculateAttachmentYOffset(player), profile.Amount)
	local alignPosition: AlignPosition = connectAlignPosition(headAttachment, meshPartAttachment, meshPart)
	local alignOrientation: AlignOrientation = connectAlignOrientation(headAttachment, meshPartAttachment, meshPart)

	profile.Assets[brainrotAsset] = {
		Instances = {},
		Asset = brainrotAsset,
		Index = profile.Amount,
	}

	table.insert(profile.Assets[brainrotAsset].Instances, headAttachment)
	table.insert(profile.Assets[brainrotAsset].Instances, meshPartAttachment)
	table.insert(profile.Assets[brainrotAsset].Instances, alignPosition)
	table.insert(profile.Assets[brainrotAsset].Instances, alignOrientation)

	self.Client.BrainrotAdded:Fire(player, { Amount = profile.Amount })
end

function CarryService:DropSpecific(player: Player, asset: any, shouldDrop: boolean)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(shouldDrop) == "boolean", "shouldDrop arg must be a boolean")
	local profile = self:getProfile(player) :: Profile

	local assetConfig = profile.Assets[asset]
	for _, instance in pairs(assetConfig.Instances) do
		instance:Destroy()
	end
	table.clear(assetConfig.Instances)

	local meshPart = asset:FindFirstChildOfClass("MeshPart")
	NetworkOwnerHandler(meshPart, nil)
	toggleMeshPart(meshPart, false)

	profile.Assets[asset] = nil
	profile.Amount -= 1
	if profile.Amount <= 0 then
		profile.IsCarrying = false
	end

	if not shouldDrop then
		self.BrainrotSpawnService:BrainrotDestroyed(asset)
	elseif shouldDrop and player.Character then
		local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = player.Character:GetDescendants()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local raycast = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -1000, 0), raycastParams)
		if raycast and raycast.Instance then
			asset:PivotTo(CFrame.new(raycast.Position))
		else
			local originalCFrame = asset:GetAttribute("OriginalCFrame")
			if typeof(originalCFrame) == "CFrame" then
				asset:PivotTo(originalCFrame)
			end
		end

		self.BrainrotSpawnService:BrainrotDropped(asset)
		self.Client.BrainrotRemoved:Fire(player, { Amount = profile.Amount })
	end
end

function CarryService:Drop(player: Player, shouldDrop: boolean)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local asset = self:getLatestBrainrotAssetProfile(player)
	if typeof(asset) == "Instance" then
		self:DropSpecific(player, asset, shouldDrop)
	end
end

function CarryService:DropAll(player: Player, shouldDropAll: boolean)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(shouldDropAll) == "boolean", "shouldDropAll arg must be a boolean")
	local profile = self:getProfile(player) :: Profile
	for asset, _ in pairs(profile.Assets) do
		self:DropSpecific(player, asset, shouldDropAll)
	end
	self.Client.BrainrotRemoved:Fire(player, { Amount = 0 })
end

function CarryService:Connect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	self.Profiles[player] = {
		Amount = 0,
		IsCarrying = false,
		Assets = {},
	}

	return {
		Function = self.Disconnect,
		Args = {
			self,
			player,
		},
	}
end

function CarryService:Disconnect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self:getProfile(player) :: Profile
	self:DropAll(player, false)

	task.defer(function()
		profile.Amount = 0
		profile.IsCarrying = false
		self.Profiles[player] = nil
	end)
end

-- LifeCycle
function CarryService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.BrainrotSpawnService = knit.GetService("BrainrotSpawnService")
end

return CarryService
