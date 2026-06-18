-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local BrainrotSpawnController = knit.CreateController({
	Name = "BrainrotSpawnController",
})

-- Public Methods
function BrainrotSpawnController:Connect() end

function BrainrotSpawnController:Disconnect() end

-- LifeCycle
function BrainrotSpawnController:KnitInit() end

return BrainrotSpawnController
