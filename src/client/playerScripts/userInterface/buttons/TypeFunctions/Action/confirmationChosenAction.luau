-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
return function(button: GuiButton)
	local option = button.Name
	knit.GetController("ConfirmationController"):OptionChosen(option)
end
