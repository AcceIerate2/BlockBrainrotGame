-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local AnimationService = knit.CreateService({
	Name = "AnimationService",
	Client = { Play = knit.CreateSignal() },
})

-- LifeCycle
function AnimationService:KnitInit() end

return AnimationService
