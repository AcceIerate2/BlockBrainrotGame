-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Constants
local Player = Players.LocalPlayer

-- Helper Functions
local function teleport(CFrame: CFrame)
	if Player.Character then
		Player.Character:PivotTo(CFrame)
	end
end

-->
return function(button: GuiButton)
	local tpType = button:GetAttribute("TpType")
	assert(typeof(tpType) == "string", "tpType arg must be a string")

	local cFrame
	if tpType == "CFrame" then
		cFrame = button:GetAttribute("CFrame")
	else
		cFrame = knit.GetController("PlotController"):GetSpawn():GetPivot()
	end

	teleport(cFrame)
end
