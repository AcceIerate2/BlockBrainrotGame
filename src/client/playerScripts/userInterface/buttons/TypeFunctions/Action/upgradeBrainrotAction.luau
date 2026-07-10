-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local PlayTween = require(ReplicatedStorage.src.utility.PlayTween)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)
local particleEmitter = require(ReplicatedStorage.src.utility.particleEmitter)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Constants
local Particles = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Effects")
local UpgradeParticles = Particles:WaitForChild("CharacterUpgrade")

-->
return function(button)
	local brainrotReferenceId = button:GetAttribute("BrainrotReferenceId")
	knit.GetService("BrainrotUpgradeService")
		:Upgrade(brainrotReferenceId)
		:andThen(
			function(
				response: { Status: boolean, Reason: string, NewLevel: number, NextLevel: number, CostToUpgrade: number }
			)
				if not response.Status then
					knit.GetController("NotificationController"):Push({
						Message = response.Reason,
						Color = Color3.fromRGB(255, 0, 0),
						Sound = "Decline",
					})
					return
				end

				button:WaitForChild("Level").Text = `Lvl {response.NewLevel} > Lvl {response.NextLevel}`
				button:WaitForChild("Cost").Text = `${NumberShortner(response.CostToUpgrade)}`

				local stand = knit.GetController("StandController"):GetStandFromBrainrotReferenceId(brainrotReferenceId)
				if not stand then
					return
				end

				local brainrotAsset = stand.Brainrot:FindFirstChildOfClass("Model")
				brainrotHandler.UpdateLevel(brainrotAsset, brainrotReferenceId, response.NewLevel)
				particleEmitter(UpgradeParticles, brainrotAsset.PrimaryPart)
				knit.GetController("AudioController"):PlayAudio("BrainrotUpgrade", true, brainrotAsset.PrimaryPart)

				local highlightToDestroy = brainrotAsset.PrimaryPart:FindFirstChildOfClass("Highlight")
				if highlightToDestroy then
					highlightToDestroy:Destroy()
				end

				local highlight = InstanceCreator("Highlight", "Highlight", brainrotAsset.PrimaryPart, {
					FillColor = Color3.fromRGB(255, 255, 255),
					FillTransparency = 0.25,
					OutlineTransparency = 1,
				})

				PlayTween(
					highlight,
					TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
					{
						FillTransparency = 1,
					}
				).Completed:Once(function()
					highlight:Destroy()
				end)
			end
		)
		:catch(warn)
end
