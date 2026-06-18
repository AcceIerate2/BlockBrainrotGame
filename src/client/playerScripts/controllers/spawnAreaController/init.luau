-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local SpawnAreaController = knit.CreateController({
	Name = "SpawnAreaController",
})

-- Pubic Methods
function SpawnAreaController:Connect(payload: { Asset: any, ZoneType: string, LastZoneType: string })
	self.BlockTrailController:ClearLocalTrail()
end

function SpawnAreaController:Disconnect() end

-- LifeCycle
function SpawnAreaController:KnitInit()
	self.BlockTrailController = knit.GetController("BlockTrailController")
end

return SpawnAreaController
