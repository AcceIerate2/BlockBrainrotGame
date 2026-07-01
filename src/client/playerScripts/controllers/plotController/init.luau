-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local PlotController = knit.CreateController({
	Name = "PlotController",
})

-- Private Methods
function PlotController:syncPlot()
	local ok: boolean, plotAsset = self.PlotService:GetPlotAsset():await()
	self.PlotAsset = ok and plotAsset
	return plotAsset
end

-- Public Methods
function PlotController:GetSpawn()
	return self.PlotAsset:WaitForChild("Spawn")
end

function PlotController:GetPlotAsset()
	return self.PlotAsset
end

-- LifeCycle
function PlotController:KnitInit()
	self.PlotService = knit.GetService("PlotService")
	self:syncPlot()
end

return PlotController
