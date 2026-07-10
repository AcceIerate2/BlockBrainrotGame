-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Types
type Data = {
	Title: string,
	Message: string,
	Options: { Option1: string, Option2: string },
	Duration: number,
}

-->
local ConfirmationPanel = {}

-- Private Methods
function ConfirmationPanel:updateCountdown(secondsLeft: number)
	self.Panel
		:WaitForChild("Body")
		:WaitForChild("ScrollingFrame")
		:WaitForChild("Buttons")
		:WaitForChild("Option1")
		:WaitForChild("Countdown").Text =
		`{secondsLeft}s`
end

function ConfirmationPanel:syncPanel(config: Data)
	self.Panel:WaitForChild("Header"):WaitForChild("Title").Text = config.Title
	self.Panel
		:WaitForChild("Body")
		:WaitForChild("ScrollingFrame")
		:WaitForChild("Buttons")
		:WaitForChild("Option1")
		:WaitForChild("Label").Text =
		config.Options.Option1

	self.Panel
		:WaitForChild("Body")
		:WaitForChild("ScrollingFrame")
		:WaitForChild("Buttons")
		:WaitForChild("Option2")
		:WaitForChild("Label").Text =
		config.Options.Option2

	self:updateCountdown(config.Duration or 10)
	self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrame"):WaitForChild("Title").Text = config.Message
end

-- LifeCycle
function ConfirmationPanel:Init(player: Player)
	self.Panel = player.PlayerGui:WaitForChild("Panels"):WaitForChild("Confirmation")
	self.ConfirmationController = knit.GetController("ConfirmationController")
	self.ConfirmationController.Signals.SyncPanel:Connect(function(config: Data)
		self:syncPanel(config)
	end)

	self.ConfirmationController.Signals.SyncCountdown:Connect(function(secondsLeft: number)
		self:updateCountdown(secondsLeft)
	end)
end

return ConfirmationPanel
