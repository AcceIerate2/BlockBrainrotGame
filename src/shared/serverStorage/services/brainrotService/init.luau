-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Constants
local BrainrotAssets = ReplicatedStorage.Assets.Brainrots

-->
local BrainrotService = knit.CreateService({
	Name = "BrainrotService",
})

-- Private Methods
-- Public Methods
function BrainrotService:GetBrainrotAsset(brainrotName: string, mutation: string, shouldClone: boolean)
	assert(typeof(brainrotName) == "string", "brainrotName arg must be a string")
	assert(typeof(mutation) == "string", "mutation arg must be a string")

	brainrotName = brainrotHandler.GetBrainrotNameFromReferenceId(brainrotName)
	mutation = typeof(mutation) == "string" and mutation or "Default"

	local brainrotAsset = BrainrotAssets:FindFirstChild(mutation):FindFirstChild(brainrotName)
	return shouldClone and brainrotAsset:Clone() or brainrotAsset
end

-- LifeCycle
function BrainrotService:KnitInit() end

return BrainrotService
