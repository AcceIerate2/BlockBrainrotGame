-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Constants
local Stands = workspace:WaitForChild("src"):WaitForChild("Stands")

-->
local PanelPromptController = knit.CreateController({
	Name = "PanelPromptController",
})

-- LifeCycle
function PanelPromptController:KnitInit()
	self.PanelController = knit.GetController("PanelController")
end

function PanelPromptController:KnitStart()
	for _, standAsset in pairs(Stands:GetChildren()) do
		local proximityPrompt = standAsset:WaitForChild("Prompt"):WaitForChild("ProximityPrompt") :: ProximityPrompt
		proximityPrompt.Triggered:Connect(function(playerWhoTriggered: Player)
			self.PanelController:togglePanel(standAsset.Name)
		end)
	end
end

return PanelPromptController
