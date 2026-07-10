local GroupRewardPanel = {}

function GroupRewardPanel:Init(player: Player)
	self.Player = player
	self.Panel = self.Player.PlayerGui:WaitForChild("Panels"):WaitForChild("GroupReward")
	self.Container = self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrame")

	self.RewardsFrame = self.Container:WaitForChild("Rewards"):WaitForChild("Content")
	self.ClaimButton = self.Container:WaitForChild("Buttons"):WaitForChild("ClaimGroupReward")
end

return GroupRewardPanel
