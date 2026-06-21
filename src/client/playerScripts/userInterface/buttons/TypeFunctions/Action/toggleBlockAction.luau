-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
return function(button)
	local BlockName = button and button:GetAttribute("BlockName")
	if not BlockName then
		return
	end

	knit.GetController("BlockController"):ToggleBlock(BlockName)
end
