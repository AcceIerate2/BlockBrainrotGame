-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)
local promise = require(ReplicatedStorage.src.Packages.promise)

-- Local Types
type Config = {
	Title: string,
	Message: string,
	OptionLabels: {
		Option1: string,
		Option2: string,
	},
	Duration: number,
}

-- Helper Functions
local function isPlayer(player: Player): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local ConfirmationService = knit.CreateService({
	Name = "ConfirmationService",

	Connections = {},
	RequestsById = {},

	Client = {
		Prompt = knit.CreateSignal(),
	},
})

-- Client Exposed Methods
function ConfirmationService.Client:Respond(
	player: Player,
	requestId: string,
	response: { Option1: boolean, Option2: boolean }
)
	local service = self.Server

	local requestData = service.RequestsById[requestId]
	if not requestData then
		return false
	end

	if requestData.OtherPlayer ~= player then
		return false
	end

	service:FinishRequest(requestData.Player, requestData.OtherPlayer, {
		Status = true,
		Response = response,
	})

	return true
end

-- Public Methods
function ConfirmationService:Prompt(player: Player, otherPlayer: Player, otherConfig: Config)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(isPlayer(otherPlayer), "otherPlayer arg must be a Player Instance")
	assert(typeof(otherConfig) == "table", "otherConfig arg must be a table")

	if not self.Connections[player] then
		self.Connections[player] = {}
	end

	if self.Connections[player][otherPlayer] then
		return { Status = false, Reason = `{otherPlayer.DisplayName} already has a pending request` }
	end

	local requestId = HttpService:GenerateGUID(false)
	self.Connections[player][otherPlayer] = {
		RequestId = requestId,
		OtherPlayer = otherPlayer,
		Connections = {},
	}

	local profile = self.Connections[player][otherPlayer]
	self.RequestsById[requestId] = {
		Player = player,
		OtherPlayer = otherPlayer,
	}

	profile.Promise = promise.new(function(resolve, reject, onCancel)
		profile.Resolve = resolve
		profile.Reject = reject

		onCancel(function()
			self:CleanupRequest(player, otherPlayer)
		end)

		table.insert(
			profile.Connections,
			Players.PlayerRemoving:Connect(function(leavingPlayer)
				if leavingPlayer == player then
					self:FinishRequest(player, otherPlayer, {
						Status = false,
						Reason = `{player.Name} left the game`,
					})
				elseif leavingPlayer == otherPlayer then
					self:FinishRequest(player, otherPlayer, {
						Status = false,
						Reason = `{otherPlayer.Name} left the game`,
					})
				end
			end)
		)

		self.Client.Prompt:Fire(otherPlayer, requestId, otherConfig)

		local duration = math.max(otherConfig.Duration or 10, 1)
		task.delay(duration, function()
			warn("Timer ran out")
			local currentProfile = self.Connections[player] and self.Connections[player][otherPlayer]
			if currentProfile ~= profile then
				return
			end

			self:FinishRequest(player, otherPlayer, {
				Status = false,
				Reason = `{otherPlayer.Name} failed to decide in time`,
			})
		end)
	end)

	return {
		Status = true,
		Promise = profile.Promise,
	}
end

function ConfirmationService:FinishRequest(player: Player, otherPlayer: Player, result)
	local profile = self.Connections[player] and self.Connections[player][otherPlayer]
	if not profile then
		return
	end

	local resolve = profile.Resolve

	self:CleanupRequest(player, otherPlayer)

	if resolve then
		resolve(result)
	end
end

function ConfirmationService:CleanupRequest(player: Player, otherPlayer: Player)
	local profile = self.Connections[player] and self.Connections[player][otherPlayer]
	if not profile then
		return
	end

	for _, connection in pairs(profile.Connections or {}) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end

	if profile.RequestId then
		self.RequestsById[profile.RequestId] = nil
	end

	self.Connections[player][otherPlayer] = nil

	if next(self.Connections[player]) == nil then
		self.Connections[player] = nil
	end
end

function ConfirmationService:DisconnectRequest(player: Player, otherPlayer: Player, cancelPromise: boolean?)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(isPlayer(otherPlayer), "otherPlayer arg must be a Player Instance")

	local profile = self.Connections[player] and self.Connections[player][otherPlayer]
	if not profile then
		return
	end

	local requestPromise = profile.Promise

	self:CleanupRequest(player, otherPlayer)

	if cancelPromise and requestPromise then
		requestPromise:cancel()
	end
end

function ConfirmationService:DisconnectPlayer(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")

	local playerConnections = self.Connections[player]
	if not playerConnections then
		return
	end

	for otherPlayer in pairs(playerConnections) do
		self:DisconnectRequest(player, otherPlayer, true)
	end
end

return ConfirmationService
