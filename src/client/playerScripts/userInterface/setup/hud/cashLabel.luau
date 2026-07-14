-- Roblox Services
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local PlayTween = require(ReplicatedStorage.src.utility.PlayTween)
local Spring = require(ReplicatedStorage.src.utility.Spring)

-->
local CashLabel = {
	Value = 0,
}

-- Private Methods
function CashLabel:pushCashChange(newValue: number)
	local increase = newValue > self.Value
	local change = newValue - self.Value
	if change == 0 then
		return
	end

	local color = increase and Color3.fromRGB(153, 255, 0) or Color3.fromRGB(255, 0, 76)
	local new = self.ChangeLabelTemplate:Clone()
	new.Name = HttpService:GenerateGUID(false)
	new:WaitForChild("Label").Text = `{increase and "+" or "-"} ${NumberShortner(math.abs(change))}`
	new:WaitForChild("Label").TextColor3 = color
	new.Size = UDim2.fromScale(0, 0)
	new.Visible = true
	new.Parent = self.ChangeLabelContainer

	Spring.target(new, 0.9, 7, {
		Size = new:GetAttribute("Size"),
	})

	task.delay(2, function()
		Spring.target(new, 1, 6, {
			Size = UDim2.fromScale(0, 0.4),
		})

		Spring.completed(new, function()
			warn("??")
			new:Destroy()
		end)
	end)
end

function CashLabel:update(newValue: number)
	local increase = newValue > self.Value
	self.Label.Text = `${NumberShortner(newValue)}`

	local color = increase and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 0, 76)
	PlayTween(self.Label, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true, 0), {
		TextColor3 = color,
	}).Completed:Once(function()
		self.Label.TextColor3 = Color3.fromRGB(153, 255, 0)
	end)

	local audioToPlay = increase and "CashIncrease" or "CashSink"
	self.AudioController:PlayAudio(audioToPlay, true, SoundService)
	self.Value = newValue
end

-- LifeCycle
function CashLabel:Init(player: Player)
	self.Label = player.PlayerGui:WaitForChild("Hud"):WaitForChild("Labels"):WaitForChild("Cash"):WaitForChild("Label")
	self.ChangeLabelContainer = player.PlayerGui:WaitForChild("Hud"):WaitForChild("CashRewards")
	self.ChangeLabelTemplate = self.ChangeLabelContainer:WaitForChild("Template")

	self.DataController = knit.GetController("DataController")
	self.AudioController = knit.GetController("AudioController")

	self.Value = self.DataController:GetValue("Cash")

	self:update(self.DataController:GetValue("Cash"))
	self.DataController:GetValueChangedSignal("Cash"):Connect(function(newValue: number)
		self:pushCashChange(newValue)
		self:update(newValue)
	end)
end

return CashLabel
