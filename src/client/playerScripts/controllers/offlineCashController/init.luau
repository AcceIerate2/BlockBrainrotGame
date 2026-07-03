-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local OfflineCashController = knit.CreateController({
	Name = "OfflineCashController",
	Claimed = false,
	Reward = nil,
	Signals = {
		UpdateCashLabel = Signal.new(),
	},
})

-- Public Methods
function OfflineCashController:CalculateOfflineCashReward(): number
	if typeof(self.Reward) == "number" then
		return self.Reward
	end

	local ok: boolean, reward: number = self.OfflineCashService:CalculateOfflineCashReward():await()
	self.Reward = ok and typeof(reward) == "number" and reward or 90
	return self.Reward
end

function OfflineCashController:RequestToClaimOfflineCash()
	if self.Claimed then
		return
	end

	self.OfflineCashService
		:RewardPlayerOfflineCash()
		:andThen(function(response: { Status: boolean })
			if response.Status then
				self.Claimed = true

				if self.PanelController.ActivePanel == "OfflineReward" then
					self.PanelController:togglePanel("OfflineReward")
				end
			end
		end)
		:catch(warn)
end

-- LifeCycle
function OfflineCashController:KnitInit()
	self.OfflineCashService = knit.GetService("OfflineCashService")
	self.PanelController = knit.GetController("PanelController")
end

function OfflineCashController:KnitStart()
	Players.LocalPlayer:WaitForChild("ClientReady")
	local reward = self:CalculateOfflineCashReward()
	if reward > 0 then
		self.Signals.UpdateCashLabel:Fire(reward)
		self.PanelController:togglePanel("OfflineReward")
	end
end

return OfflineCashController
