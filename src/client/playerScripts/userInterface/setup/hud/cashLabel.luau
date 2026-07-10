-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local PlayTween = require(ReplicatedStorage.src.utility.PlayTween)

-->
local CashLabel = {
	Value = 0,
}

-- Private Methods
function CashLabel:update(newValue: number)
	local increase = newValue > self.Value
	self.Label.Text = `${NumberShortner(newValue)}`

	local color = increase and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 0, 76)
	PlayTween(self.Label, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true, 0), {
		TextColor3 = color,
	}).Completed:Once(function()
		self.Label.TextColor3 = Color3.fromRGB(200, 255, 0)
	end)

	local audioToPlay = increase and "CashIncrease" or "CashSink"
	self.AudioController:PlayAudio(audioToPlay, true, SoundService)
	self.Value = newValue
end

-- LifeCycle
function CashLabel:Init(player: Player)
	self.Label = player.PlayerGui:WaitForChild("Hud"):WaitForChild("Labels"):WaitForChild("Cash"):WaitForChild("Label")
	self.DataController = knit.GetController("DataController")
	self.AudioController = knit.GetController("AudioController")

	self.Value = self.DataController:GetValue("Cash")

	self:update(self.DataController:GetValue("Cash"))
	self.DataController:GetValueChangedSignal("Cash"):Connect(function(newValue: number)
		self:update(newValue)
	end)
end

return CashLabel
