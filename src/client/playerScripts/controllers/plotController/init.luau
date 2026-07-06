-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local plotConfig = require(ReplicatedStorage.src.GameConfiguration.General.plotConfig)

-->
local PlotController = knit.CreateController({
	Name = "PlotController",
})

-- Private Methods
function PlotController:getUpgradeUI()
	return self.PlotAsset and self.PlotAsset:WaitForChild("UpgradeSign"):WaitForChild("UI"):WaitForChild("SurfaceGui")
end

function PlotController:refreshUpgradeLabel()
	local level = self.DataController:GetValue("PlotUpgradeLevel")
	local costToUpgrade = plotConfig.CalculateUpgradeCost(level)

	self:getUpgradeUI():WaitForChild("Upgrades").Text = `{level}/{plotConfig.MaxLevel}`

	if level < plotConfig.MaxLevel then
		self:getUpgradeUI():WaitForChild("UpgradePlot"):WaitForChild("Label").Text = `${NumberShortner(costToUpgrade)}`
	else
		self:getUpgradeUI():WaitForChild("UpgradePlot"):WaitForChild("Label").Text = `Max Level`
	end
end

function PlotController:connectUpgradeButton()
	local containerUI = self:getUpgradeUI()
	local button = containerUI:WaitForChild("UpgradePlot")
	self.ButtonsController:link(button)
	self:refreshUpgradeLabel()
	containerUI.Enabled = true
end

function PlotController:syncPlot()
	local ok: boolean, plotAsset = self.PlotService:GetPlotAsset():await()
	self.PlotAsset = ok and plotAsset
	return plotAsset
end

-- Public Methods
function PlotController:UpgradePlot()
	self.PlotService
		:UpgradePlot()
		:andThen(function(response: { Status: boolean, Reason: string? })
			if not response.Status then
				self.NotificationController:Push({
					Message = response.Reason,
					Color = Color3.fromRGB(255, 0, 0),
					Sound = "Decline",
				})
			end
		end)
		:catch(warn)
end

function PlotController:GetSpawn()
	return self.PlotAsset:WaitForChild("Spawn")
end

function PlotController:GetPlotAsset()
	return self.PlotAsset
end

-- LifeCycle
function PlotController:KnitInit()
	self.PlotService = knit.GetService("PlotService")
	self.DataController = knit.GetController("DataController")
	self.ButtonsController = knit.GetController("ButtonsController")
	self.NotificationController = knit.GetController("NotificationController")

	self:syncPlot()
	self:connectUpgradeButton()
end

function PlotController:KnitStart()
	self.DataController:GetValueChangedSignal("PlotUpgradeLevel"):Connect(function()
		self:refreshUpgradeLabel()
	end)
end

return PlotController
