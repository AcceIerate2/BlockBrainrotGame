-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-->
return function(button)
	local brainrotReferenceId = button:GetAttribute("BrainrotReferenceId")
	knit.GetService("BrainrotUpgradeService")
		:Upgrade(brainrotReferenceId)
		:andThen(
			function(
				response: { Status: boolean, Reason: string, NewLevel: number, NextLevel: number, CostToUpgrade: number }
			)
				button:WaitForChild("Level").Text = `Lvl {response.NewLevel} > Lvl {response.NextLevel}`
				button:WaitForChild("Cost").Text = `${NumberShortner(response.CostToUpgrade)}`

				local stand = knit.GetController("StandController"):GetStandFromBrainrotReferenceId(brainrotReferenceId)
				if not stand then
					return
				end

				local brainrotAsset = stand.Brainrot:FindFirstChildOfClass("Model")
				brainrotHandler.UpdateLevel(brainrotAsset, brainrotReferenceId, response.NewLevel)
			end
		)
		:catch(warn)
end
