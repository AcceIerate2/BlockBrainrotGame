-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
return function(button)
	local brainrotReferenceId = button and button:GetAttribute("BrainrotReferenceId")
	if typeof(brainrotReferenceId) ~= "string" then
		return
	end

	knit.GetController("SellController"):SellBrainrot(brainrotReferenceId)
end
