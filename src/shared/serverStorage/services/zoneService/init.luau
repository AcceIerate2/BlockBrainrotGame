-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)

-- Types
type PlayerZoneProfile = {
	Asset: BasePart,
	ZoneType: string?,
}

type ZoneProfile = {
	Connections: { RBXScriptConnection },
	PlayersInZone: { Player },
}

-- Helper Functions
local function isPlayer(player: Player): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local ZoneService = knit.CreateService({
	Name = "ZoneService",

	Client = {
		EnteredZone = knit.CreateSignal(),
		LeftZone = knit.CreateSignal(),
	},

	PlayerProfiles = {},
	ZoneProfiles = {},
})

-- Private Methods
function ZoneService:getZoneProfile(zone): ZoneProfile?
	return self.ZoneProfiles[zone]
end

function ZoneService:playerInZone(zoneProfile: ZoneProfile, player: Player): number?
	assert(typeof(zoneProfile) == "table", "zoneProfile arg must be a table")
	assert(isPlayer(player), "player arg must be a Player Instance")

	return table.find(zoneProfile.PlayersInZone, player)
end

function ZoneService:listenToZoneEntriesAndExits(zone: BasePart)
	if self:getZoneProfile(zone) then
		return
	end

	self.ZoneProfiles[zone] = {
		Connections = {},
		PlayersInZone = {},
	}

	local zoneProfileReference = self:getZoneProfile(zone) :: ZoneProfile

	table.insert(
		zoneProfileReference.Connections,
		zone.Touched:Connect(function(partThatTouched)
			if partThatTouched.Name ~= "HumanoidRootPart" then
				return
			end

			local character = partOfCharacter(partThatTouched)
			if not character then
				return
			end

			local playerThatEntered = Players:GetPlayerFromCharacter(character)
			if not playerThatEntered then
				return
			end

			local index = self:playerInZone(zoneProfileReference, playerThatEntered)
			if index then
				return
			end

			table.insert(zoneProfileReference.PlayersInZone, playerThatEntered)

			local oldProfile = self.PlayerProfiles[playerThatEntered]
			local lastZoneType = oldProfile and oldProfile.ZoneType or nil
			local zoneType = zone:GetAttribute("ZoneType")

			self.PlayerProfiles[playerThatEntered] = {
				Asset = zone,
				ZoneType = zoneType,
			}

			self.Client.EnteredZone:Fire(playerThatEntered, {
				Asset = zone,
				ZoneType = zoneType,
				LastZoneType = lastZoneType,
			})

			if lastZoneType == "BlockTrail" and zoneType == "SpawnArea" then
				if not self.CarryService:PlayerIsCarrying(playerThatEntered) then
					self.BlockTrailService:RefundBlocks(playerThatEntered)
				else
					local brainrotNames = self.CarryService:GetActiveBrainrots(playerThatEntered) :: { string }
					for _, brainrotName: string in pairs(brainrotNames) do
						local newGuid = HttpService:GenerateGUID(false)
						local referenceId = `{brainrotName}_{newGuid}`
						self.InventoryService:Give(playerThatEntered, referenceId, "BrainrotTool", {
							Mutation = "Default",
						})
					end

					self.CarryService:DropAll(playerThatEntered, false)
					self.BlockTrailService:ClearBlocks(playerThatEntered)
				end
			end
		end)
	)

	table.insert(
		zoneProfileReference.Connections,
		zone.TouchEnded:Connect(function(partThatTouched)
			if partThatTouched.Name ~= "HumanoidRootPart" then
				return
			end

			local character = partOfCharacter(partThatTouched)
			if not character then
				return
			end

			local playerThatLeft = Players:GetPlayerFromCharacter(character)
			if not playerThatLeft then
				return
			end

			local index = self:playerInZone(zoneProfileReference, playerThatLeft)
			if not index then
				return
			end

			table.remove(zoneProfileReference.PlayersInZone, index)

			local oldProfile = self.PlayerProfiles[playerThatLeft]
			local zoneType = zone:GetAttribute("ZoneType")
			if not oldProfile or oldProfile.Asset ~= zone then
				return
			end

			local lastZoneType = oldProfile.ZoneType
			self.PlayerProfiles[playerThatLeft] = nil

			self.Client.LeftZone:Fire(playerThatLeft, {
				Asset = zone,
				ZoneType = zoneType,
				LastZoneType = lastZoneType,
			})
		end)
	)
end

function ZoneService:disconnectZone(zone: BasePart)
	local zoneProfileReference = self:getZoneProfile(zone)
	if not zoneProfileReference then
		return
	end

	for _, connection: RBXScriptConnection in ipairs(zoneProfileReference.Connections) do
		connection:Disconnect()
	end

	for player: Player, profile: PlayerZoneProfile in pairs(self.PlayerProfiles) do
		if profile.Asset == zone then
			self.PlayerProfiles[player] = nil
		end
	end

	table.clear(zoneProfileReference.PlayersInZone)
	table.clear(zoneProfileReference.Connections)

	self.ZoneProfiles[zone] = nil
end

function ZoneService:listenToZoneChanges()
	for _, zone in ipairs(CollectionService:GetTagged("Zone")) do
		if zone:IsA("BasePart") then
			self:listenToZoneEntriesAndExits(zone)
		end
	end

	CollectionService:GetInstanceAddedSignal("Zone"):Connect(function(zone)
		if zone:IsA("BasePart") then
			self:listenToZoneEntriesAndExits(zone)
		end
	end)

	CollectionService:GetInstanceRemovedSignal("Zone"):Connect(function(zone)
		if zone:IsA("BasePart") then
			self:disconnectZone(zone)
		end
	end)
end

function ZoneService:cleanupPlayer(player: Player)
	self.PlayerProfiles[player] = nil

	for _, zoneProfile: ZoneProfile in pairs(self.ZoneProfiles) do
		local index = table.find(zoneProfile.PlayersInZone, player)
		if index then
			table.remove(zoneProfile.PlayersInZone, index)
		end
	end
end

-- Public Methods
function ZoneService:GetPlayerZone(player: Player)
	local profile = self.PlayerProfiles[player]
	return profile and profile.ZoneType or nil
end

function ZoneService:GetPlayerZoneProfile(player: Player)
	return self.PlayerProfiles[player]
end

-- LifeCycle
function ZoneService:KnitInit()
	self.CarryService = knit.GetService("CarryService")
	self.BlockTrailService = knit.GetService("BlockTrailService")
	self.InventoryService = knit.GetService("InventoryService")
end

function ZoneService:KnitStart()
	self:listenToZoneChanges()
	Players.PlayerRemoving:Connect(function(player)
		self:cleanupPlayer(player)
	end)
end

return ZoneService
