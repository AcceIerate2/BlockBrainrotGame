-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local CollisionHandler = require(ReplicatedStorage.src.utility.CollisionHandler)
local AvatarHeadshot = require(ReplicatedStorage.src.utility.AvatarHeadshot)

-->
local PlayerService = knit.CreateService({
	Name = "PlayerService",
	Client = {},
	DisconnectFunctions = {},
	LoadedClients = {},
})

-- Client Exposed Methods
function PlayerService.Client:ClientReady(player: Player)
	return self.Server:clientReady(player)
end

-- Private Methods
function PlayerService:clientReady(player: Player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "player arg must be a Player Instance")
	self.LoadedClients[player] = true
end

function PlayerService:load(player: Player)
	self.DisconnectFunctions[player] = {}
	local playerDisconnectFunctions = self.DisconnectFunctions[player]

	-- ProfileStoreService
	local profile, profileStoreDisconnectFunction = self.ProfileStoreService:newSession(player)
	playerDisconnectFunctions.profileStoreDisconnectFunction = profileStoreDisconnectFunction

	-- DataService
	playerDisconnectFunctions.dataServiceDisconnectFunction = self.DataService:ConnectProfile(player, profile.Data)

	-- Avatar Headshot
	self.DataService:GetValueObject(player, "AvatarHeadshotAssetId"):Set(AvatarHeadshot(player))

	-- InventoryService
	playerDisconnectFunctions.inventoryServiceDisconnectFunction = self.InventoryService:LoadTools(player)

	-- PlotService
	playerDisconnectFunctions.playerServiceDisconnectFunction = self.PlotService:ConnectPlot(player)

	-- CarryService
	playerDisconnectFunctions.carryServiceDisconnectFunction = self.CarryService:Connect(player)

	-- IndexService
	self.IndexService:Sync(player)

	-- Gamepasses
	self.MonetizationService:loadGamepasses(player)

	-- BadgeService
	self.BadgeService:awardWelcomeBadges(player)

	-- CharacterAdded Connection
	local function characterAdded(Character: Model)
		CollisionHandler.ToggleCollisionProperties(Character, {
			CollisionGroup = "PlayerCollisions",
		}, {})

		local plot = self.PlotService:GetPlotStateFromPlayer(player).Asset
		local offset = Vector3.new(0, Character:GetExtentsSize().Y / 2, 0)
		Character:PivotTo(plot.Spawn:GetPivot() + offset)
	end

	if player.Character then
		characterAdded(player.Character)
	end
	player.CharacterAdded:Connect(characterAdded)

	-- Signal Player is ready
	InstanceCreator("BoolValue", "Synced", player)
end

function PlayerService:unload(player: Player)
	self.BlockTrailService:ClearBlocks(player)
	self.OfflineCashService:ClearPlayerReferences(player)

	local playerDisconnectFunctions = self.DisconnectFunctions[player]
	if not TypeCheck.table(playerDisconnectFunctions) then
		return
	end

	for disconnectFunctionName: string, data in pairs(playerDisconnectFunctions) do
		local functionToCall = data["Function"]
		assert(typeof(functionToCall) == "function", `{disconnectFunctionName} does not have a function to call`)

		local args = data["Args"]
		assert(TypeCheck.table(args), "Args must be a table")

		functionToCall(table.unpack(data["Args"]))
	end

	self.DisconnectFunctions[player] = nil
	self.LoadedClients[player] = nil
end

-- LifeCycle
function PlayerService:KnitInit()
	self.ProfileStoreService = knit.GetService("ProfileStoreService")
	self.DataService = knit.GetService("DataService")
	self.MonetizationService = knit.GetService("MonetizationService")
	self.BadgeService = knit.GetService("BadgeService")
	self.InventoryService = knit.GetService("InventoryService")
	self.PlotService = knit.GetService("PlotService")
	self.BlockTrailService = knit.GetService("BlockTrailService")
	self.CarryService = knit.GetService("CarryService")
	self.IndexService = knit.GetService("IndexService")
	self.OfflineCashService = knit.GetService("OfflineCashService")

	-- Player Connections
	Players.PlayerAdded:Connect(function(player: Player)
		self:load(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self:unload(player)
	end)

	-- if the server shuts down
	game:BindToClose(function()
		local playersInServer = Players:GetPlayers()
		for _, player in pairs(playersInServer) do
			self:unload(player)
		end
	end)

	print(`PlayerService Initiated.`)
end

function PlayerService:KnitStart()
	Players.RespawnTime = 1
end

return PlayerService
