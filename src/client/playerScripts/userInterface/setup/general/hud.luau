-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Constants
local Player = Players.LocalPlayer

-->
local Hud = {}

function Hud:ToggleRemoveLastBlockButtonVisibility(toggle: boolean)
	Player.PlayerGui:WaitForChild("Hud"):WaitForChild("RemoveLastBlock").Visible = toggle
end

function Hud:Init(player: Player)
	self.HudController = knit.GetController("HudController")
	self.HudController.Signals.ToggleRemoveLastBlockButtonVisibility:Connect(function(toggle: boolean)
		self:ToggleRemoveLastBlockButtonVisibility(toggle)
	end)
end

return Hud
