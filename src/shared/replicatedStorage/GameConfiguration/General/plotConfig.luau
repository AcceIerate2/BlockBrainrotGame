local PlotConfig = {}

PlotConfig.MaxLevel = 24
PlotConfig.BaseUpgradeCost = 10

function PlotConfig.CalculateUpgradeCost(level: number)
	assert(typeof(level) == "number", "level arg must be a number")
	return PlotConfig.BaseUpgradeCost * (1.25 ^ (level + 1))
end

return PlotConfig
