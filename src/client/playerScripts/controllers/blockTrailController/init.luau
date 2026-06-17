-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local BlockTrailController = knit.CreateController({
	Name = "BlockTrailController",
})

function BlockTrailController:Connect() end

function BlockTrailController:Disconnect() end

-- LifeCycle
function BlockTrailController:KnitInit()
	self.BlockTrailService = knit.GetService("BlockTrailService")
end

return BlockTrailController
