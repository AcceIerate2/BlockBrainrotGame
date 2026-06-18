-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local HudController = knit.CreateController({
	Name = "HudController",
	Signals = {
		ToggleDropButtonVisibility = Signal.new(),
	},
})

function HudController:ToggleDropButtonVisibility(toggle: boolean)
	self.Signals.ToggleDropButtonVisibility:Fire(toggle)
end

-- LifeCycle
function HudController:KnitInit() end

return HudController
