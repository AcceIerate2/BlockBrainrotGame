-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local AudioService = knit.CreateService({
	Name = "AudioService",
})

return AudioService
