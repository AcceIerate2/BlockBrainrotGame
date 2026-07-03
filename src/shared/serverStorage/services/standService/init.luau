-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)
local promise = require(ReplicatedStorage.src.Packages.promise)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Types
type StandProfile = {
	Asset: any,
	ProximityPrompt: ProximityPrompt,
	Connections: { [string]: RBXScriptConnection },
	Brainrot: any,
	Mutation: string,
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

function StandService:placeBrainrot(standProfile: StandProfile, brainrotReferenceId: string, save: boolean?)
	assert(typeof(standProfile) == "table", "standProfile arg must be a table")
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")

	if standProfile.Taken then
		warn(`Stand is taken? - StandService:placeBrainrot - Line 56`)
		return
	end

	local mutation = brainrotHandler.GetMutationFromBrainrotReferenceId(brainrotReferenceId, standProfile.Owner)
	standProfile.Brainrot = brainrotHandler.GetBrainrotAsset(
		brainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId),
		mutation,
		true
	)

	brainrotHandler.ToggleCountdownState(standProfile.Brainrot, false)
	standProfile.Taken = true

	standProfile.Brainrot.Name = brainrotReferenceId
	standProfile.Brainrot:PivotTo(standProfile.Asset.Placeholder:GetPivot())
	standProfile.Brainrot.Parent = standProfile.Asset.Brainrot
	standProfile.Mutation = mutation

	local elapsed = 0
	standProfile.Connections.CashConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if elapsed < 1 then
			elapsed += deltaTime
			return
		end
		elapsed = 0

		local incomeRate = brainrotHandler.GetBrainrotIncomeRate(
			brainrotReferenceId,
			brainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId, standProfile.Owner),
			standProfile.Owner
		)

		standProfile.Asset.Cash.Value += incomeRate
		standProfile.Cash += incomeRate
	end)

	self.Client.BrainrotPlaced:Fire(standProfile.Owner, standProfile.Asset, brainrotReferenceId)
	if save then
		self.DataService:GetValueObject(standProfile.Owner, "TakenStands"):Update(function(_table)
			_table[standProfile.Asset:GetAttribute("Index")] = brainrotReferenceId
		end)
	end
end

function StandService:removeBrainrot(standProfile: StandProfile, save: boolean?)
	if typeof(standProfile.Brainrot) == "Instance" then
		standProfile.Brainrot:Destroy()
		standProfile.Brainrot = nil
	end

	standProfile.Taken = false
	if typeof(standProfile.Connections.CashConnection) == "RBXScriptConnection" then
		standProfile.Connections.CashConnection:Disconnect()
	end

	self.Client.BrainrotRemoved:Fire(standProfile.Owner, standProfile.Asset)

	if save then
		self.DataService:GetValueObject(standProfile.Owner, "TakenStands"):Update(function(_table)
			_table[standProfile.Asset:GetAttribute("Index")] = nil
		end)
	end
end

-- Public Methods
function StandService:GetBrainrotsOnStand(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")

	local plotAsset = self.PlotService:GetPlotStateFromPlayer(player).Asset
	local stands = plotAsset.Stands

	local brainrots = {}
	for _, stand in pairs(stands:GetChildren()) do
		local profile = self:getProfileReference(stand)
		if not profile.Taken then
			continue
		end

		table.insert(brainrots, {
			BrainrotReferenceId = profile.Brainrot.Name,
			Mutation = profile.Mutation,
		})
	end

	return brainrots
end

function StandService:GetStandFromBrainrotReferenceId(player: Player, brainrotReferenceId: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")

	for standAsset, standProfile: StandProfile in pairs(self.Profiles) do
		if
			standProfile.Owner == player
			and standProfile.Taken
			and typeof(standProfile.Brainrot) == "Instance"
			and standProfile.Brainrot.Name == brainrotReferenceId
		then
			return standAsset
		end
	end

	return nil
end

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
		Mutation = "Default",
		Taken = false,
		Cash = 0,
		Owner = player,
	}

	local profileReference = self:getProfileReference(standAsset) :: StandProfile
	local takenBrainrotReferenceId = self.DataService:GetValue(player, "TakenStands")[standAsset:GetAttribute("Index")]
	if takenBrainrotReferenceId then
		self:placeBrainrot(profileReference, takenBrainrotReferenceId)
		self.InventoryService:RemoveTool(player, takenBrainrotReferenceId)
	end

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
					self.InventoryService
						:GiveTool(player, profileReference.Brainrot.Name, "BrainrotTool")
						:SetAttribute("Mutation", profileReference.Mutation)
				end
				self:removeBrainrot(profileReference, true)

				if tool then
					self:placeBrainrot(profileReference, brainrotReferenceId, true)
					self.InventoryService:RemoveTool(player, brainrotReferenceId)
				end
			else
				if
					typeof(tool) == "Instance"
					and tool:IsA("Tool")
					and tool:GetAttribute("Handler") == "BrainrotTool"
				then
					self:placeBrainrot(profileReference, brainrotReferenceId, true)
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
			return
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
	self.PlotService = knit.GetService("PlotService")
end

function StandService:KnitStart()
	ReplicatedStorage.Assets.PlotAssets.StandTemplate.ProximityPrompt.ProximityPrompt.Enabled = false
end

return StandService
