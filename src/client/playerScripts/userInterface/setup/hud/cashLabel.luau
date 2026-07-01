-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-->
local CashLabel = {}

-- Private Methods
function CashLabel:update(newValue: number)
	self.Label.Text = `${NumberShortner(newValue)}`
end

-- LifeCycle
function CashLabel:Init(player: Player)
	self.Label = player.PlayerGui:WaitForChild("Hud"):WaitForChild("Labels"):WaitForChild("Cash"):WaitForChild("Label")
	self.DataController = knit.GetController("DataController")

	self:update(self.DataController:GetValue("Cash"))
	self.DataController:GetValueChangedSignal("Cash"):Connect(function(newValue: number)
		self:update(newValue)
	end)
end

return CashLabel
