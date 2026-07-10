-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)
local luckyBlockHandler = require(ReplicatedStorage.src.utility.luckyBlockHandler)

-- Constants
local LocalPlayer = Players.LocalPlayer

-->
local BrainrotGiftController = knit.CreateController({
	Name = "BrainrotGiftController",
	ProximityPrompts = {},
	PlayerConnections = {},
})

-- Private Methods
function BrainrotGiftController:clear()
	for proximityPrompt: ProximityPrompt, connectionData: { Connection: RBXScriptConnection, Player: Player } in
		pairs(self.ProximityPrompts)
	do
		if typeof(connectionData.Connection) == "RBXScriptConnection" then
			connectionData.Connection:Disconnect()
		end

		if typeof(self.PlayerConnections[connectionData.Player]) == "RBXScriptConnection" then
			self.PlayerConnections[connectionData.Player]:Disconnect()
			self.PlayerConnections[connectionData.Player] = nil
		end

		proximityPrompt:Destroy()
	end
end

function BrainrotGiftController:show(brainrotReferenceId: string, mutation: string, type: string)
	assert(
		typeof(brainrotReferenceId) == "string",
		"brainrotReferenceId arg must be a string" .. " " .. `{typeof(brainrotReferenceId)}`
	)

	for _, player in pairs(Players:GetPlayers()) do
		if player == LocalPlayer then
			continue
		end

		task.spawn(function()
			if not player.Character then
				player.CharacterAdded:Wait()
			end

			local newPrompt = InstanceCreator("ProximityPrompt", "GiftProximityPrompt", player.Character, {
				ActionText = `Gift{type == "Brainrot" and (mutation ~= "Default" and " " .. mutation or "") or ""} {brainrotHandler.GetBrainrotDisplayName(
					brainrotReferenceId
				)}?`,
			}) :: ProximityPrompt

			self.PlayerConnections[player] = player.CharacterAdded:Connect(function(newCharacter)
				newPrompt.Parent = newCharacter
			end)

			self.ProximityPrompts[newPrompt] = {
				Connection = newPrompt.Triggered:Connect(function(playerWhoTriggered: Player)
					if playerWhoTriggered ~= LocalPlayer then
						return
					end

					self:Gift(player.Name, brainrotReferenceId, mutation, type)
				end),
				Player = player,
				Prompt = newPrompt,
			}
		end)
	end
end

function BrainrotGiftController:getPromptProfileFromPlayer(player: Player)
	for proximityPrompt: ProximityPrompt, connectionData: { Connection: RBXScriptConnection, Player: Player } in
		pairs(self.ProximityPrompts)
	do
		if connectionData.Player == player then
			return connectionData
		end
	end
	return
end

function BrainrotGiftController:RequestToGiftPlayer(
	playerNameToGiftTo: string,
	brainrotReferenceId: string,
	mutation: string,
	type: string
)
	return self.BrainrotGiftService:RequestToGiftPlayer({
		Name = playerNameToGiftTo,
		BrainrotReferenceId = brainrotReferenceId,
		Mutation = mutation,
		Type = type,
	})
end

-- Public Methods
function BrainrotGiftController:Gift(
	playerNameToGiftTo: string,
	brainrotReferenceId: string,
	mutation: string,
	type: string
)
	self:RequestToGiftPlayer(playerNameToGiftTo, brainrotReferenceId, mutation, type)
		:andThen(function(response)
			warn(response)
		end)
		:catch(warn)
end

function BrainrotGiftController:ToggleGiftProximityPrompts(
	toggle: boolean,
	brainrotReferenceId: string,
	mutation: string,
	type: string
)
	assert(typeof(toggle) == "boolean", "toggle arg must be a boolean")
	self:clear()
	if toggle then
		self:show(brainrotReferenceId, mutation, type)
	end
end

-- LifeCycle
function BrainrotGiftController:KnitInit()
	self.BrainrotGiftService = knit.GetService("BrainrotGiftService")
	Players.PlayerRemoving:Connect(function(playerRemoving: Player)
		local connection = self.PlayerConnections[playerRemoving]
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
		self.PlayerConnections[playerRemoving] = nil

		local profile = self:getPromptProfileFromPlayer(playerRemoving)
		if profile then
			if typeof(profile.Connection) == "RBXScriptConnection" then
				profile.Connection:Disconnect()
			end

			self.ProximityPrompts[profile.Prompt]:Destroy()
			self.ProximityPrompts[profile.Prompt] = nil
		end
	end)
end

return BrainrotGiftController
