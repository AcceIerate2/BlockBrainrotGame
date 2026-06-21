-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

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
			end
		)
		:catch(warn)
end
