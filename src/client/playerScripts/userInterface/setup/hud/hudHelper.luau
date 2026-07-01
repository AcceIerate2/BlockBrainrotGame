-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Constants
local Player = Players.LocalPlayer

-->
local Hud = {}

function Hud:ToggleDropButtonVisibility(toggle: boolean)
	Player.PlayerGui:WaitForChild("Hud"):WaitForChild("Drop").Visible = toggle
end

function Hud:Init(player: Player)
	self.HudController = knit.GetController("HudController")
	self.HudController.Signals.ToggleDropButtonVisibility:Connect(function(toggle: boolean)
		self:ToggleDropButtonVisibility(toggle)
	end)

	self:ToggleDropButtonVisibility(false)
end

return Hud
