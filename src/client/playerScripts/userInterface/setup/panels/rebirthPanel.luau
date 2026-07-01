-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-->
local RebirthPanel = {}

function RebirthPanel:updateRewards(payload) end

function RebirthPanel:updateRequirement(payload: { Current: number, Requirement: number })
	assert(typeof(payload) == "table", "payload arg must be a table")
	self.RequirementsFrame:WaitForChild("ProgressBar"):WaitForChild("Bar").Size =
		UDim2.fromScale(math.clamp(payload.Current / payload.Requirement, 0, 1), 1)
	self.RequirementsFrame:WaitForChild("ProgressBar"):WaitForChild("TextLabel").Text =
		`{NumberShortner(payload.Current)} / {NumberShortner(payload.Requirement)} Max Blocks Required`
end

function RebirthPanel:Init(player: Player)
	self.RebirthController = knit.GetController("RebirthController")

	self.Player = player
	self.Panel = self.Player.PlayerGui:WaitForChild("Panels"):WaitForChild("Rebirths")

	self.RequirementsFrame = self.Panel:WaitForChild("Body"):WaitForChild("Requirement")
	self.RewardsFrame = self.Panel:WaitForChild("Body"):WaitForChild("Rewards")
	self.RebirthButtons = self.Panel:WaitForChild("Body"):WaitForChild("RebirthButtons")

	self:updateRequirement(self.RebirthController:GetRequirement())
	self.RebirthController.Signals.UpdateRequirement:Connect(
		function(response: { Current: number, Requirement: number })
			self:updateRequirement(response)
		end
	)

	self:updateRewards(self.RebirthController:GetRewards())
	self.RebirthController.Signals.UpdateRewards:Connect(function(value)
		self:updateRewards()
	end)
end

return RebirthPanel
