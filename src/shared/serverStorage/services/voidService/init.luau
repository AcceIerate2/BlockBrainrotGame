-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local VoidService = knit.CreateService({
	Name = "VoidService",
	Client = {},
})

-- Private Methods

-- LifeCycle
function VoidService:KnitInit() end

return VoidService
