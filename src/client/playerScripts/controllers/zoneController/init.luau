-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)

-- Helper Functions
local function characterInZone(character): (boolean, string?)
	for _, limb in pairs(character:GetChildren()) do
		if not limb:IsA("BasePart") then
			continue
		end

		local partsInPart = workspace:GetPartsInPart(limb)
		for _, partInPart in pairs(partsInPart) do
			if partInPart:HasTag("Zone") then
				return true, partInPart:GetAttribute("ZoneType")
			end
		end
	end
	return false
end

-->
local ZoneController = knit.CreateController({
	Name = "ZoneController",
	Zone = nil,
	ZoneChanged = Signal.new(),

	ZoneConnections = {} :: { [any]: { RBXScriptConnection } },
})

-- Private Methods
function ZoneController:updateZone(newZone: string)
	self.Zone = newZone
	self.ZoneChanged:Fire(newZone)
end

function ZoneController:connectZone(zone)
	self.ZoneConnections[zone] = {}
	table.insert(
		self.ZoneConnections[zone],
		zone.Touched:connect(function(partThatTouched: BasePart)
			local character = partOfCharacter(partThatTouched)
			if not character then
				return
			end

			local playerThatTouched = Players:GetPlayerFromCharacter(character)
			if not playerThatTouched or playerThatTouched ~= Players.LocalPlayer then
				return
			end

			local zoneType = zone:GetAttribute("ZoneType")
			local controller = knit.GetController(`{zoneType}Controller`)
			if controller and typeof(controller.Connect) == "function" then
				controller:Connect({ LastZoneType = self.Zone, Asset = zone, ZoneType = zoneType })
			end
			self:updateZone(zoneType)
		end)
	)

	table.insert(
		self.ZoneConnections[zone],
		zone.TouchEnded:Connect(function(partThatTouched: BasePart)
			local character = partOfCharacter(partThatTouched)
			if not character then
				return
			end

			local playerThatTouched = Players:GetPlayerFromCharacter(character)
			if not playerThatTouched or playerThatTouched ~= Players.LocalPlayer then
				return
			end

			local zoneType = zone:GetAttribute("ZoneType")
			local inZone: boolean, currentZone: string? = characterInZone(character)
			if inZone and currentZone == zoneType then
				return
			end

			if currentZone == "SpawnArea" then
				self.BlockTrailController:ClearLocalTrail()
			end

			local controller = knit.GetController(`{zoneType}Controller`)
			if controller and typeof(controller.Disconnect) == "function" then
				controller:Disconnect({ LastZoneType = self.Zone, Asset = zone, ZoneType = zoneType })
			end
		end)
	)
end

function ZoneController:disconnectZone(zone)
	if not self.ZoneConnections[zone] then
		return
	end

	for _, connection in pairs(self.ZoneConnections[zone]) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end

	table.clear(self.ZoneConnections[zone])
	self.ZoneConnections[zone] = nil
end

-- LifeCycle
function ZoneController:KnitInit()
	self.BlockTrailController = knit.GetController("BlockTrailController")
end

function ZoneController:KnitStart()
	for _, zone in pairs(CollectionService:GetTagged("Zone")) do
		self:connectZone(zone)
	end

	CollectionService:GetInstanceAddedSignal("Zone"):Connect(function(zone)
		if not self.ZoneConnections[zone] then
			self:connectZone(zone)
		end
	end)

	CollectionService:GetInstanceRemovedSignal("Zone"):Connect(function(zone)
		self:disconnectZone(zone)
	end)
end

return ZoneController
