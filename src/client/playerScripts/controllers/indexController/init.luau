-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)
local Signal = require(ReplicatedStorage.src.Packages.Signal)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Config Modules
local mutationConfig = require(ReplicatedStorage.src.GameConfiguration.General.mutationConfig)

-- Constants
local BrainrotsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Brainrots")
local DefaultBrainrots = BrainrotsFolder:WaitForChild("Default")

-->
local IndexController = knit.CreateController({
	Name = "IndexController",
	Index = (function()
		local _table = {}
		for mutation: string, _ in pairs(mutationConfig) do
			_table[mutation] = {}
		end
		return _table
	end)(),

	Signals = {
		Added = Signal.new(),
		ToggleMutationScrollingFrame = Signal.new(),
	},
})

-- Private Methods
function IndexController:sync()
	for _, brainrotAsset in pairs(DefaultBrainrots:GetChildren()) do
		for mutation: string, _table in pairs(self.Index) do
			_table[brainrotAsset.Name] = self:Owned(brainrotAsset.Name, mutation)
		end
	end
end

function IndexController:listenToIndexService()
	self.IndexService.Added:Connect(function(brainrotName: string, mutation: string)
		self.Index[mutation][brainrotName] = true
		self.Signals.Added:Fire(brainrotName, mutation)
	end)
end

-- Public Methods
function IndexController:ToggleMutationScrollingFrame(mutation: string)
	assert(typeof(mutation) == "string", "mutation arg must be a string")
	self.Signals.ToggleMutationScrollingFrame:Fire(mutation)
end

function IndexController:Owned(brainrotReferenceId: string, mutation: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	assert(typeof(mutation) == "string", "mutation arg must be a string")
	return self.DataController:GetValue("Index")[mutation][brainrotHandler.GetBrainrotNameFromReferenceId(
		brainrotReferenceId
	)] ~= nil
end

function IndexController:GetIndexState()
	return self.Index
end

-- LifeCycle
function IndexController:KnitInit()
	self.IndexService = knit.GetService("IndexService")
	self.DataController = knit.GetController("DataController")
end

function IndexController:KnitStart()
	self:listenToIndexService()
	self:sync()
end

return IndexController
