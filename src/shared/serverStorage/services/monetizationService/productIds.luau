-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local rebirthConfig = require(ReplicatedStorage.src.GameConfiguration.General.rebirthConfig)

-->
local ProductIds = {}

-- Skip Rebirth
ProductIds[rebirthConfig.SkipRebirthId] = function(player: Player)
	warn(player)
	knit.GetService("RebirthService"):Rebirth(player, true)
	return true
end

return ProductIds
