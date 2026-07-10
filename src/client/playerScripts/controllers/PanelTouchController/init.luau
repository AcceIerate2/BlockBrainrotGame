-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Constants
local Panels = {
	"Upgrades",
	"Blocks",
	"Sell",
}
local PanelTouchTogglersFolder = workspace:WaitForChild("src"):WaitForChild("PanelTouchTogglers")
local PanelTouchTogglers = {}
for _, panelName: string in pairs(Panels) do
	table.insert(PanelTouchTogglers, PanelTouchTogglersFolder:WaitForChild(panelName))
end

-->
local PanelTouchController = knit.CreateController({
	Name = "PanelTouchController",
	Cooldown = false,
})

local function isCharacterStillTouchingPart(character: Model, basePart: BasePart)
	for _, touchingPart: BasePart in pairs(basePart:GetTouchingParts()) do
		local touchingCharacter = partOfCharacter(touchingPart)
		if touchingCharacter == character then
			return true
		end
	end

	return false
end

-- LifeCycle
function PanelTouchController:KnitInit()
	self.PanelController = knit.GetController("PanelController")
end

function PanelTouchController:KnitStart()
	for _, basePart: BasePart in pairs(PanelTouchTogglers) do
		basePart.Touched:Connect(function(partThatTouched: BasePart)
			local character = partOfCharacter(partThatTouched)
			if character then
				local player = Players:GetPlayerFromCharacter(character)
				if player == Players.LocalPlayer then
					if self.PanelController.ActivePanel ~= basePart.Name then
						self.PanelController:togglePanel(basePart.Name)
					end
				end
			end
		end)

		basePart.TouchEnded:Connect(function(partThatTouched)
			local character = partOfCharacter(partThatTouched)
			if character then
				local player = Players:GetPlayerFromCharacter(character)
				if player == Players.LocalPlayer then
					if isCharacterStillTouchingPart(character, basePart) then
						return
					end

					if self.PanelController.ActivePanel == basePart.Name then
						self.PanelController:togglePanel(basePart.Name)
					elseif
						typeof(self.PanelController.ActivePanel) == "string"
						and self.PanelController.ActivePanel:len() > 0
					then
						self.PanelController:togglePanel(self.PanelController.ActivePanel)
					end
				end
			end
		end)
	end

	for _, standAsset in pairs(workspace:WaitForChild("src"):WaitForChild("Stands"):GetChildren()) do
		local brainrot
		for _, v in pairs(standAsset:GetChildren()) do
			if v:IsA("Model") and v:FindFirstChildOfClass("AnimationController") then
				brainrot = v
				break
			end
		end

		brainrotHandler.AnimateBrainrot(brainrot)
	end
end

return PanelTouchController
