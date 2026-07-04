-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Constants
local BrainrotSpawns = workspace:WaitForChild("src"):WaitForChild("BrainrotSpawns")

-->
local BrainrotSpawnController = knit.CreateController({
	Name = "BrainrotSpawnController",
	ConnectionProfiles = {},
})

-- Private Methods
function BrainrotSpawnController:getProfileReference(brainrotAsset: any)
	return self.ConnectionProfiles[brainrotAsset]
end

function BrainrotSpawnController:connect(brainrotAsset: any)
	self:disconnect(brainrotAsset)
	self.ConnectionProfiles[brainrotAsset] = {}

	local profileReference = self:getProfileReference(brainrotAsset)

	local elapsed = 0
	local _delay = 0

	table.insert(
		profileReference,
		RunService.RenderStepped:Connect(function(deltaTime: number)
			if not brainrotAsset or not brainrotAsset.Parent or brainrotAsset:GetAttribute("Destroying") then
				self:disconnect(brainrotAsset)
				return
			end

			elapsed += deltaTime
			if elapsed < 1 then
				return
			end

			elapsed = 0
			if brainrotAsset:GetAttribute("State") ~= "Idle" then
				_delay += 1
				return
			end

			local secondsLeft = math.clamp((brainrotAsset:GetAttribute("ExpiresAt") - os.time()) + _delay, 0, math.huge)
			brainrotHandler.UpdateCountdown(brainrotAsset, `{secondsLeft}s`)
		end)
	)
end

function BrainrotSpawnController:disconnect(brainrotAsset)
	local connections = self:getProfileReference(brainrotAsset)
	if typeof(connections) ~= "table" then
		return
	end

	-- Disconnect Connections
	for _, connection: RBXScriptConnection in pairs(connections) do
		connection:Disconnect()
	end

	-- Clear Reference
	self.ConnectionProfiles[brainrotAsset] = nil
end

-- LifeCycle
function BrainrotSpawnController:KnitStart()
	for _, brainrotSpawn in pairs(BrainrotSpawns:GetChildren()) do
		local brainrots = brainrotSpawn:WaitForChild("Brainrots")
		brainrots.ChildAdded:Connect(function(brainrotAsset)
			self:connect(brainrotAsset)
		end)

		brainrots.ChildRemoved:Connect(function(brainrotAsset)
			self:disconnect(brainrotAsset)
		end)

		for _, brainrotAsset in pairs(brainrots:GetChildren()) do
			if self:getProfileReference(brainrotAsset) then
				continue
			end
			self:connect(brainrotAsset)
		end
	end
end

return BrainrotSpawnController
