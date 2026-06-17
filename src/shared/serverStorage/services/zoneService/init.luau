-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)

-- Types
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
function ZoneService:getZoneProfile(zone): ZoneProfile
	return self.ZoneProfiles[zone]
end

function ZoneService:playerInZone(zoneProfile: ZoneProfile, player: Player): number | nil
	assert(typeof(zoneProfile) == "table", "zoneProfile arg must be a table")
	assert(isPlayer(player), "player arg must be a Player Instance")
	return table.find(zoneProfile.PlayersInZone, player)
end

function ZoneService:listenToZoneEntriesAndExits(zone)
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
			self.PlayerProfiles[playerThatEntered] = zone:GetAttribute("ZoneType")

			self.Client.EnteredZone:Fire(playerThatEntered, {
				Asset = zone,
				ZoneType = zone:GetAttribute("ZoneType"),
			})
		end)
	)

	table.insert(
		zoneProfileReference.Connections,
		zone.TouchEnded:Connect(function(partThatTouched)
			local character = partOfCharacter(partThatTouched)
			if not character then
				return
			end

			local playerThatLeft = Players:GetPlayerFromCharacter(character)
			if not playerThatLeft then
				return
			end

			local index = self:playerInZone(zoneProfileReference, playerThatLeft)
			if index then
				zoneProfileReference.PlayersInZone[index] = nil
				self.PlayerProfiles[playerThatLeft] = nil

				self.Client.LeftZone:Fire(playerThatLeft, {
					Asset = zone,
					ZoneType = zone:GetAttribute("ZoneType"),
				})
			end
		end)
	)
end

function ZoneService:disconnectZone(zone)
	-- Disconnect Connections
	local zoneProfileReference = self:getZoneProfile(zone) :: ZoneProfile
	for _, connection: RBXScriptConnection in pairs(zoneProfileReference) do
		connection:Disconnect()
	end

	-- Clear Players
	for player: Player, zoneType: string in pairs(self.PlayerProfiles) do
		if zoneType == zone:GetAttribute("ZoneType") then
			self.PlayerProfiles[player] = nil
		end
	end
	table.clear(zoneProfileReference.PlayersInZone)
	zoneProfileReference.PlayersInZone = nil

	-- Clear Entry
	self.ZoneProfiles[zone] = nil
end

function ZoneService:listenToZoneChanges()
	for _, zone in pairs(CollectionService:GetTagged("Zone")) do
		self:listenToZoneEntriesAndExits(zone)
	end

	CollectionService:GetInstanceAddedSignal("Zone"):Connect(function(zone)
		self:listenToZoneEntriesAndExits(zone)
	end)

	CollectionService:GetInstanceRemovedSignal("Zone"):Connect(function(zone)
		self:disconnectZone(zone)
	end)
end

-- Public Methods
function ZoneService:GetPlayerZone(player: Player)
	return self.PlayerProfiles[player]
end

-- LifeCycle
function ZoneService:KnitStart()
	self:listenToZoneChanges()
end

return ZoneService
