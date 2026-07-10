-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local GroupRewardController = knit.CreateController({
	Name = "GroupRewardController",
})

-- Public Methods
function GroupRewardController:ClaimReward()
	self.GroupRewardService
		:ClaimReward()
		:andThen(function(response: { Status: boolean, Reason: string? })
			if not response.Status then
				self.NotificationController:Push({
					Message = response.Reason,
					Color = Color3.fromRGB(255, 0, 0),
					Sound = "Decline",
				})
				return
			end
		end)
		:catch(warn)
end

-- LifeCycle
function GroupRewardController:KnitInit()
	self.GroupRewardService = knit.GetService("GroupRewardService")
	self.NotificationController = knit.GetController("NotificationController")
end

return GroupRewardController
