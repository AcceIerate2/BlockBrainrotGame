-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
return function(button: GuiButton)
	local upgradeType = button:GetAttribute("UpgradeType")
	local upgradeAmount = button:GetAttribute("Amount")
	knit.GetController("UpgradeController"):Upgrade(upgradeType, upgradeAmount)
end
