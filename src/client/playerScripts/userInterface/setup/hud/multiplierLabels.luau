-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local PlayTween = require(ReplicatedStorage.src.utility.PlayTween)

-->
local MultiplierLabels = {}

-- Private Methods
function MultiplierLabels:updateMultiplier(mutliplierName: string)
	local newValue = self.DataController:GetValue(mutliplierName)
	local frame = self.Container:WaitForChild(mutliplierName)
	frame:WaitForChild("Label").Text = `x{newValue}`
	PlayTween(frame, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true, 0), {
		Size = frame:GetAttribute("PopSize"),
	}).Completed:Once(function()
		frame.Size = frame:GetAttribute("DefaultSize")
	end)
end

-- LifeCycle
function MultiplierLabels:Init(player: Player)
	self.DataController = knit.GetController("DataController")

	self.Player = player
	self.Container = self.Player.PlayerGui:WaitForChild("Hud"):WaitForChild("Multipliers")

	self:updateMultiplier("CashMultiplier")
	self:updateMultiplier("BlockMultiplier")
	self:updateMultiplier("WalkSpeedMultiplier")

	self.DataController:GetValueChangedSignal("CashMultiplier"):Connect(function(newValue: number)
		self:updateMultiplier("CashMultiplier")
	end)

	self.DataController:GetValueChangedSignal("BlockMultiplier"):Connect(function(newValue: number)
		self:updateMultiplier("BlockMultiplier")
	end)

	self.DataController:GetValueChangedSignal("Equipp"):Connect(function(newValue: number)
		self:updateMultiplier("WalkSpeedMultiplier")
	end)
end

return MultiplierLabels
