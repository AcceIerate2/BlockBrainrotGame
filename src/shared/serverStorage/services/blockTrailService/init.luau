-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local BlockTrailService = knit.CreateService({
	Name = "BlockTrailService",
	Client = {},
})

-- Client Exposed Methods
-- Private Methods
-- Public Methods
-- LifeCycle
function BlockTrailService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

function BlockTrailService:KnitStart() end

return BlockTrailService
