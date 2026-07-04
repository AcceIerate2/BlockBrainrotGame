-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Constants
local BrainrotSpawns = workspace.src.BrainrotSpawns

-- Types
type ZoneProfile = {
	Brainrots: { any },
}

-->
local BrainrotSpawnService = knit.CreateService({
	Name = "BrainrotSpawnService",
	MaxBrainrotsPerZone = 10,
	BrainrotLifeTimeDuration = 60,
	ZoneProfiles = {},

	Client = {},
})

-- Private Methods
function BrainrotSpawnService:getZoneProfile(brainrotSpawn)
	return self.ZoneProfiles[brainrotSpawn]
end

function BrainrotSpawnService:getCFrame(base: BasePart, asset: Model, cFrames: { CFrame }): CFrame
	assert(typeof(base) == "Instance" and base:IsA("BasePart"), "base arg must be a BasePart")
	assert(typeof(asset) == "Instance" and asset:IsA("Model"), "asset arg must be a Model")
	assert(typeof(cFrames) == "table", "cFrames arg must be a table")

	local random = Random.new()

	local assetSize = asset:GetExtentsSize()
	local baseCFrame = base:GetPivot()
	local baseSize = base.Size

	local padding = 4
	local minDistance = math.max(assetSize.X, assetSize.Z) + padding

	local maxX = math.max((baseSize.X / 2) - (assetSize.X / 2), 0)
	local maxZ = math.max((baseSize.Z / 2) - (assetSize.Z / 2), 0)

	local function isFarEnough(candidateCFrame: CFrame): boolean
		local candidateLocalPosition = baseCFrame:PointToObjectSpace(candidateCFrame.Position)

		for _, existingCFrame in ipairs(cFrames) do
			local existingLocalPosition = baseCFrame:PointToObjectSpace(existingCFrame.Position)

			local deltaX = candidateLocalPosition.X - existingLocalPosition.X
			local deltaZ = candidateLocalPosition.Z - existingLocalPosition.Z

			local distance = math.sqrt(deltaX * deltaX + deltaZ * deltaZ)

			if distance < minDistance then
				return false
			end
		end

		return true
	end

	local attempts = 80
	local fallbackCFrame = baseCFrame

	for _ = 1, attempts do
		local x = random:NextNumber(-maxX, maxX)
		local z = random:NextNumber(-maxZ, maxZ)
		local rotationY = math.rad(random:NextInteger(0, 360))

		local candidateCFrame = baseCFrame * CFrame.new(x, 0, z) * CFrame.Angles(0, rotationY, 0)
		fallbackCFrame = candidateCFrame

		if isFarEnough(candidateCFrame) then
			return candidateCFrame
		end
	end

	warn("Could not find spaced brainrot spawn position after attempts; using fallback")
	return fallbackCFrame
end

function BrainrotSpawnService:preloadBrainrotSpawns()
	for _, brainrotSpawn in pairs(BrainrotSpawns:GetChildren()) do
		self.ZoneProfiles[brainrotSpawn] = {
			Brainrots = {},
			CFrames = {},
		}

		for i = self.MaxBrainrotsPerZone, 1, -1 do
			self:SpawnBrainrot(brainrotSpawn, true)
		end
	end
end

function BrainrotSpawnService:getBrainrotProfile(brainrotAsset)
	for _, zoneProfile: ZoneProfile in pairs(self.ZoneProfiles) do
		for brainrotKey, brainrotProfile in pairs(zoneProfile.Brainrots) do
			if brainrotKey == brainrotAsset then
				return brainrotProfile
			end
		end
	end
	return nil
end

-- Public Methods
function BrainrotSpawnService:DestroyBrainrot(brainrotAsset)
	local profileReference = self:getBrainrotProfile(brainrotAsset)
	for _, connection: RBXScriptConnection in pairs(profileReference.Connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end

	table.clear(profileReference.Connections)
	profileReference.ProximityPrompt:Destroy()
	brainrotAsset:Destroy()
	self.ZoneProfiles[profileReference.BrainrotSpawn].Brainrots[brainrotAsset] = nil
end

function BrainrotSpawnService:BrainrotDestroyed(brainrotAsset)
	brainrotAsset:SetAttribute("State", "Destroying")
	self:DestroyBrainrot(brainrotAsset)
end

function BrainrotSpawnService:BrainrotDropped(brainrotAsset)
	local profile = self:getBrainrotProfile(brainrotAsset)
	profile.State = "Idle"
	brainrotHandler.ToggleCountdownState(brainrotAsset, true)
	brainrotAsset:SetAttribute("State", "Idle")
end

function BrainrotSpawnService:SpawnBrainrot(brainrotSpawn, replace: boolean)
	local rarity = brainrotSpawn.Name
	local brainrotName = self.BrainrotService:RngBrainrot(rarity)
	local mutation = self.BrainrotService:RngMutation()

	local zoneProfile = self:getZoneProfile(brainrotSpawn) :: ZoneProfile
	local brainrotAsset = brainrotHandler.GetBrainrotAsset(brainrotName, mutation, true)

	local cFrame = self:getCFrame(brainrotSpawn.Base, brainrotAsset, zoneProfile.CFrames)
	table.insert(zoneProfile.CFrames, cFrame)

	brainrotAsset:PivotTo(cFrame)
	brainrotAsset:SetAttribute("OriginalCFrame", cFrame)
	brainrotAsset:SetAttribute("Mutation", mutation)
	brainrotAsset:SetAttribute("DefaultScale", brainrotAsset:GetScale())

	local expiresAt = os.time() + self.BrainrotLifeTimeDuration
	brainrotAsset:SetAttribute("ExpiresAt", expiresAt)
	brainrotAsset:SetAttribute("State", "Idle")

	local proximityPrompt = InstanceCreator("ProximityPrompt", "ProximityPrompt", brainrotAsset.PrimaryPart, {
		ActionText = "Pick Up",
		HoldDuration = 0.5,
	}) :: ProximityPrompt

	zoneProfile.Brainrots[brainrotAsset] = {
		BrainrotSpawn = brainrotSpawn,
		State = "Idle",
		SecondsLeft = self.BrainrotLifeTimeDuration,
		ProximityPrompt = proximityPrompt,
		Connections = {},
	}

	local profileReference = zoneProfile.Brainrots[brainrotAsset]
	table.insert(
		profileReference.Connections,
		proximityPrompt.Triggered:Connect(function(playerWhoTriggered: Player)
			if profileReference.State ~= "Idle" then
				return
			end

			brainrotAsset:SetAttribute("State", "Carrying")

			profileReference.State = "Carrying"
			proximityPrompt.Enabled = false

			brainrotHandler.ToggleCountdownState(brainrotAsset, false)
			self.CarryService:Carry(playerWhoTriggered, brainrotAsset)
		end)
	)

	local elapsed = 0
	table.insert(
		profileReference.Connections,
		RunService.Heartbeat:Connect(function(deltaTime: number)
			if elapsed < 1 then
				elapsed += deltaTime
				return
			end

			if profileReference.State ~= "Idle" then
				return
			end

			proximityPrompt.Enabled = true

			elapsed = 0
			profileReference.SecondsLeft -= 1
			if profileReference.SecondsLeft < 1 then
				self:DestroyBrainrot(brainrotAsset)
				if replace then
					self:SpawnBrainrot(brainrotSpawn, true)
				end
			end
		end)
	)

	brainrotAsset.Parent = brainrotSpawn.Brainrots
end

-- LifeCycle
function BrainrotSpawnService:KnitInit()
	self.BrainrotService = knit.GetService("BrainrotService")
	self.CarryService = knit.GetService("CarryService")
end

function BrainrotSpawnService:KnitStart()
	self:preloadBrainrotSpawns()
end

return BrainrotSpawnService
