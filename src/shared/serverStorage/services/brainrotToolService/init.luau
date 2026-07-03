-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

local function getMainPart(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function setPhysics(model: Model)
	for _, descendant in pairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
end

local function weldModel(model: Model, mainPart: BasePart)
	for _, descendant in pairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= mainPart then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "BrainrotInternalWeld"
			weld.Part0 = mainPart
			weld.Part1 = descendant
			weld.Parent = mainPart
		end
	end
end

-->
local BrainrotToolService = knit.CreateService({
	Name = "BrainrotToolService",

	CarriedBrainrots = {},

	Client = {},
})

-- Client Exposed Methods
function BrainrotToolService.Client:ShowBrainrot(player: Player, brainrotReferenceId: string, mutation: string)
	return self.Server:ShowBrainrot(player, brainrotReferenceId, mutation)
end

function BrainrotToolService.Client:HideBrainrot(player: Player)
	return self.Server:HideBrainrot(player)
end

-- Public Methods
function BrainrotToolService:HideBrainrot(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")

	local oldBrainrot = self.CarriedBrainrots[player]
	if oldBrainrot then
		oldBrainrot:Destroy()
		self.CarriedBrainrots[player] = nil
	end
end

function BrainrotToolService:ShowBrainrot(player: Player, brainrotReferenceId: string, mutation: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	assert(typeof(mutation) == "string", "mutation arg must be a string")

	local character = player.Character
	if not character then
		return
	end

	local upperTorso = character:FindFirstChild("UpperTorso")
	if not upperTorso or not upperTorso:IsA("BasePart") then
		return
	end

	local inventory = self.DataService:GetValue(player, "Inventory")
	if not inventory or inventory[brainrotReferenceId] == nil then
		return
	end

	-- Stops exploiters from showing brainrots they are not actually holding.
	local tool = character:FindFirstChild(brainrotReferenceId)
	if not tool or not tool:IsA("Tool") then
		return
	end

	self:HideBrainrot(player)

	local brainrotName = brainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)

	local brainrotAsset = brainrotHandler.GetBrainrotAsset(brainrotName, mutation, true)
	if not brainrotAsset then
		return
	end

	brainrotHandler.UpdateLevel(
		brainrotAsset,
		brainrotReferenceId,
		brainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId, player),
		player
	)

	brainrotHandler.ToggleCountdownState(brainrotAsset, false)

	local mainPart = getMainPart(brainrotAsset)
	if not mainPart then
		brainrotAsset:Destroy()
		return
	end

	brainrotAsset.PrimaryPart = mainPart
	brainrotAsset.Name = player.Name .. "_CarriedBrainrot"

	setPhysics(brainrotAsset)
	weldModel(brainrotAsset, mainPart)

	local extentsSize = brainrotAsset:GetExtentsSize()

	-- Simple server offset math.
	local carryCFrame = upperTorso.CFrame * CFrame.new(0, 0, -1.25) * CFrame.new(0, 0, -(extentsSize.Z / 2))

	brainrotAsset:PivotTo(carryCFrame)
	brainrotAsset.Parent = workspace

	local carryWeld = Instance.new("WeldConstraint")
	carryWeld.Name = "BrainrotCarryWeld"
	carryWeld.Part0 = upperTorso
	carryWeld.Part1 = mainPart
	carryWeld.Parent = mainPart

	pcall(function()
		mainPart:SetNetworkOwner(player)
	end)

	self.CarriedBrainrots[player] = brainrotAsset
end

-- LifeCycle
function BrainrotToolService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

function BrainrotToolService:KnitStart()
	Players.PlayerRemoving:Connect(function(player)
		self:HideBrainrot(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterRemoving:Connect(function()
			self:HideBrainrot(player)
		end)
	end)

	for _, player in pairs(Players:GetPlayers()) do
		player.CharacterRemoving:Connect(function()
			self:HideBrainrot(player)
		end)
	end
end

return BrainrotToolService
