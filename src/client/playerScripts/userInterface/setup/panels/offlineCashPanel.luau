-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-->
local OfflineCashPanel = {}

function OfflineCashPanel:Init(player: Player)
	self.OfflineCashController = knit.GetController("OfflineCashController")

	self.Player = player
	self.Panel = player.PlayerGui:WaitForChild("Panels"):WaitForChild("OfflineReward")

	self.OfflineCashController.Signals.UpdateCashLabel:Connect(function(reward: number)
		self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrame"):WaitForChild("Reward"):WaitForChild("Label").Text =
			`${NumberShortner(reward)}`
	end)
end

return OfflineCashPanel
