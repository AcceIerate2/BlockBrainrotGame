-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local upgradeConfig = require(ReplicatedStorage.src.GameConfiguration.General.upgradeConfig)

-->
local UpgradeController = knit.CreateController({
	Name = "UpgradeController",
	UpdateUpgradeDetails = Signal.new(),
})

-- Private Methods
-- Public Methods
function UpgradeController:GetCostToUpgrade(upgradeType: string): number
	local level = self:GetUpgradeLevel(upgradeType)
	local upgradeData = upgradeConfig.Upgrades[upgradeType]
	return upgradeType == "Blocks" and upgradeData.BaseCast or upgradeData.BaseCost * upgradeData.Multiplier ^ level
end

function UpgradeController:GetUpgradeLevel(upgradeType: string)
	return self.DataController:GetValue(upgradeType == "Carry" and "MaxHold" or upgradeType).Level
end

function UpgradeController:GetUpgradeValue(upgradeType: string)
	return self.DataController:GetValue(upgradeType == "Carry" and "MaxHold" or upgradeType).Value
end

function UpgradeController:Upgrade(upgradeType: string, upgradeAmount: number)
	assert(typeof(upgradeType) == "string", "upgradeType arg must be a string")
	assert(typeof(upgradeAmount) == "number", "upgradeAmount arg must be a number")
	self.UpgradeService
		:Upgrade(upgradeType, upgradeAmount)
		:andThen(
			function(
				response: { Status: boolean, Reason: string?, NewLevel: number, NewValue: number, CostToUpgrade: number }
			)
				warn(response)
				if not response.Status and typeof(response.Reason) == "string" then
					self.NotificationController:Push({
						Message = response.Reason,
						Color = Color3.fromRGB(255, 0, 0),
						Sound = "Decline",
					})
					return
				end

				self.UpdateUpgradeDetails:Fire({
					UpgradeType = upgradeType,
					Level = response.NewLevel,
					Value = response.NewValue,
					CostToUpgrade = response.CostToUpgrade,
				})
			end
		)
		:catch(warn)
end

-- LifeCycle
function UpgradeController:KnitInit()
	self.UpgradeService = knit.GetService("UpgradeService")
	self.NotificationController = knit.GetController("NotificationController")
	self.DataController = knit.GetController("DataController")
end

function UpgradeController:KnitStart()
	task.spawn(function()
		Players.LocalPlayer:WaitForChild("ClientReady")
		for upgradeType: string, upgradeData in pairs(upgradeConfig.Upgrades) do
			self.UpdateUpgradeDetails:Fire({
				UpgradeType = upgradeType,
				CostToUpgrade = self:GetCostToUpgrade(upgradeType),
				Level = self:GetUpgradeLevel(upgradeType),
				Value = self:GetUpgradeValue(upgradeType),
			})
		end
	end)
end

return UpgradeController
