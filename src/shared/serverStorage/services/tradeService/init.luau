-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local TradeService = knit.CreateService({
	Name = "TradeService",
})

-- LifeCycle
function TradeService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

return TradeService
