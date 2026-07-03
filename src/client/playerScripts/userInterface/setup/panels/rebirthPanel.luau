-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-->
local RebirthPanel = {}

function RebirthPanel:updateRewards(payload: {
	CashMultiplier: { Current: number, Next: number },
	BlockMultiplier: { Current: number, Next: number },
})
	assert(typeof(payload) == "table", "payload arg must be a table")

	local cashMultiplier = payload.CashMultiplier
	local blockMultiplier = payload.BlockMultiplier

	assert(typeof(cashMultiplier) == "table", "payload.CashMultiplier must be a table")
	assert(typeof(blockMultiplier) == "table", "payload.BlockMultiplier must be a table")

	local currentRebirths = self.DataController:GetValue("Rebirths") or 0
	local nextRebirths = currentRebirths + 1

	local currentFrame = self.RewardsFrame:WaitForChild("Current")
	local nextFrame = self.RewardsFrame:WaitForChild("Next")

	currentFrame:WaitForChild("CurrentRebirths").Text = `Rebirth {currentRebirths}`
	nextFrame:WaitForChild("NextRebirths").Text = `Rebirth {nextRebirths}`

	currentFrame:WaitForChild("CashMultiplier"):WaitForChild("Label").Text = `x{cashMultiplier.Current}`

	nextFrame:WaitForChild("CashMultiplier"):WaitForChild("Label").Text = `x{cashMultiplier.Next}`

	currentFrame:WaitForChild("BlockMultiplier"):WaitForChild("Label").Text = `x{blockMultiplier.Current}`

	nextFrame:WaitForChild("BlockMultiplier"):WaitForChild("Label").Text = `x{blockMultiplier.Next}`
end

function RebirthPanel:updateRequirement(payload: { Current: number, Requirement: number })
	assert(typeof(payload) == "table", "payload arg must be a table")
	self.RequirementsFrame:WaitForChild("ProgressBar"):WaitForChild("Bar").Size =
		UDim2.fromScale(math.clamp(payload.Current / payload.Requirement, 0, 1), 1)
	self.RequirementsFrame:WaitForChild("ProgressBar"):WaitForChild("TextLabel").Text =
		`{NumberShortner(payload.Current)} / {NumberShortner(payload.Requirement)} Max Blocks Required`
end

function RebirthPanel:Init(player: Player)
	self.RebirthController = knit.GetController("RebirthController")
	self.DataController = knit.GetController("DataController")

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
	self.RebirthController.Signals.UpdateRewards:Connect(function(response: {
		CashMultipler: { Current: number, Next: number },
		BlockMultiplier: { Current: number, Next: number },
	})
		self:updateRewards(response)
	end)
end

return RebirthPanel
