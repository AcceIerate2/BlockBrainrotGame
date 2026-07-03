-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local rebirthConfig = require(ReplicatedStorage.src.GameConfiguration.General.rebirthConfig)

-->
local RebirthController = knit.CreateController({
	Name = "RebirthController",
	Signals = {
		UpdateRequirement = Signal.new(),
		UpdateRewards = Signal.new(),
	},
})

-- Private Methods
function RebirthController:update()
	local currentRebirths = self.DataController:GetValue("Rebirths")
	local requirementValue = self.DataController:GetValue(rebirthConfig.RequirementValue)

	self.Signals.UpdateRequirement:Fire({
		Current = requirementValue.Value,
		Requirement = rebirthConfig.CalculateCostToRebirth(currentRebirths),
	})

	self.Signals.UpdateRewards:Fire(self:GetRewards())
end

-- Public Methods
function RebirthController:Rebirth()
	self.RebirthService
		:Rebirth()
		:andThen(function(response: { Status: boolean, Reason: string? })
			warn(response)
		end)
		:catch(warn)
end

function RebirthController:GetRewards()
	local currentRebirths = self.DataController:GetValue("Rebirths")

	return {
		CashMultiplier = {
			Current = rebirthConfig.CalculateCashMultiplier(currentRebirths),
			Next = rebirthConfig.CalculateCashMultiplier(currentRebirths + 1),
		},

		BlockMultiplier = {
			Current = rebirthConfig.CalculateBlockMultiplier(currentRebirths),
			Next = rebirthConfig.CalculateBlockMultiplier(currentRebirths + 1),
		},
	}
end

function RebirthController:GetRequirement()
	return {
		Current = self.DataController:GetValue(rebirthConfig.RequirementValue).Value,
		Requirement = rebirthConfig.CalculateCostToRebirth(self.DataController:GetValue("Rebirths")),
	}
end

-- LifeCycle
function RebirthController:KnitInit()
	self.RebirthService = knit.GetService("RebirthService")
	self.DataController = knit.GetController("DataController")
end

function RebirthController:KnitStart()
	self.DataController:GetValueChangedSignal(rebirthConfig.RequirementValue):Connect(function()
		self:update()
	end)

	self.DataController:GetValueChangedSignal("Rebirths"):Connect(function()
		self:update()
	end)

	self:update()
end

return RebirthController
