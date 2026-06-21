-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local SellController = knit.CreateController({
	Name = "SellController",
})

-- Private Methods
-- Public Methods
function SellController:SellBrainrot(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	warn(`Selling specific Brainrot: {brainrotReferenceId}`)
end

function SellController:SellAllBrainrots()
	warn(`Selling all brainrots`)
end

-- LifeCycle
function SellController:KnitInit()
	self.BrainrotService = knit.GetService("BrainrotService")
end

return SellController
