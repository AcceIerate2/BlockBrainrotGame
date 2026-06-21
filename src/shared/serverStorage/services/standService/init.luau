-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)
local promise = require(ReplicatedStorage.src.Packages.promise)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Types
type StandProfile = {
	Asset: any,
	ProximityPrompt: ProximityPrompt,
	Connections: { [string]: RBXScriptConnection },
	Brainrot: any,
	Taken: boolean,
	Cash: number,
	Owner: Player,
}

-- Helper Functions
local function isPlayer(player: Player): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local StandService = knit.CreateService({
	Name = "StandService",
	Client = {
		BrainrotPlaced = knit.CreateSignal(),
		BrainrotRemoved = knit.CreateSignal(),
	},

	Profiles = {},
})

-- Client Exposed Methods
function StandService.Client:CollectCash(player: Player, standAsset: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	return self.Server:CollectCash(player, standAsset)
end

-- Private Methods
function StandService:getProfileReference(standAsset): StandProfile
	return self.Profiles[standAsset]
end

function StandService:placeBrainrot(standProfile: StandProfile, brainrotReferenceId: string)
	assert(typeof(standProfile) == "table", "standProfile arg must be a table")
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")

	if standProfile.Taken then
		warn(`Stand is taken?`)
		return
	end

	local mutation = brainrotHandler.GetMutationFromBrainrotReferenceId(brainrotReferenceId, standProfile.Owner)
	standProfile.Brainrot = self.BrainrotService:GetBrainrotAsset(brainrotReferenceId, mutation, true)
	standProfile.Taken = true

	standProfile.Brainrot.Name = brainrotReferenceId
	standProfile.Brainrot:PivotTo(standProfile.Asset.Placeholder:GetPivot())
	standProfile.Brainrot.Parent = standProfile.Asset.Brainrot

	local elapsed = 0
	standProfile.Connections.CashConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if elapsed < 1 then
			elapsed += deltaTime
			return
		end
		elapsed = 0

		standProfile.Asset.Cash.Value += 1
		standProfile.Cash += 1
	end)

	self.Client.BrainrotPlaced:Fire(standProfile.Owner, standProfile.Asset, brainrotReferenceId)
end

function StandService:removeBrainrot(standProfile: StandProfile)
	if typeof(standProfile.Brainrot) == "Instance" then
		standProfile.Brainrot:Destroy()
		standProfile.Brainrot = nil
	end

	standProfile.Taken = false
	if typeof(standProfile.Connections.CashConnection) == "RBXScriptConnection" then
		standProfile.Connections.CashConnection:Disconnect()
	end

	self.Client.BrainrotRemoved:Fire(standProfile.Owner, standProfile.Asset)
end

-- Public Methods
function StandService:CollectCash(player: Player, standAsset)
	local profileReference = self:getProfileReference(standAsset) :: StandProfile
	if profileReference.Owner ~= player then
		return {
			Status = false,
		}
	end

	local cashToCollect = profileReference.Cash
	self.DataService:GetValueObject(player, "Cash"):Set(self.DataService:GetValue(player, "Cash") + cashToCollect)

	profileReference.Cash = 0
	standAsset.Cash.Value = 0

	return {
		Status = true,
	}
end

function StandService:ConnectStand(player: Player, standAsset: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	self:DisconnectStand(player, standAsset)
	self.Profiles[standAsset] = {
		Asset = standAsset,
		ProximityPrompt = standAsset.ProximityPrompt.ProximityPrompt,
		Connections = {},
		Brainrot = nil,
		Taken = false,
		Cash = 0,
		Owner = player,
	}

	local profileReference = self:getProfileReference(standAsset) :: StandProfile
	table.insert(
		profileReference.Connections,
		profileReference.ProximityPrompt.Triggered:Connect(function(playerWhoTriggered: Player)
			if playerWhoTriggered ~= player then
				return
			end

			local tool = self.InventoryService:GetPlayerEquippedTool(player)
			local brainrotReferenceId = tool and tool.Name

			if profileReference.Taken then
				if typeof(profileReference.Brainrot) == "Instance" then
					self.InventoryService:GiveTool(player, profileReference.Brainrot.Name, "BrainrotTool")
				end
				self:removeBrainrot(profileReference)

				if tool then
					self:placeBrainrot(profileReference, brainrotReferenceId)
					self.InventoryService:RemoveTool(player, brainrotReferenceId)
				end
			else
				if
					typeof(tool) == "Instance"
					and tool:IsA("Tool")
					and tool:GetAttribute("Handler") == "BrainrotTool"
				then
					self:placeBrainrot(profileReference, brainrotReferenceId)
					self.InventoryService:RemoveTool(player, brainrotReferenceId)
				end
			end
		end)
	)
end

function StandService:DisconnectStand(player: Player, standAsset: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	return promise.new(function(resolve, reject, onCancel)
		local profileReference = self:getProfileReference(standAsset) :: StandProfile
		if not profileReference then
			resolve()
		end

		-- Disconnect Connections
		for _, connection: RBXScriptConnection in pairs(profileReference.Connections) do
			connection:Disconnect()
		end

		-- Destroy Brainrot
		if typeof(profileReference.Brainrot) == "Instance" then
			profileReference.Brainrot:Destroy()
		end

		self.Profiles[standAsset] = nil
		resolve()
	end)
end

-- LifeCycle
function StandService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.InventoryService = knit.GetService("InventoryService")
	self.BrainrotService = knit.GetService("BrainrotService")
end

function StandService:KnitStart()
	ReplicatedStorage.Assets.PlotAssets.StandTemplate.ProximityPrompt.ProximityPrompt.Enabled = false
end

return StandService
