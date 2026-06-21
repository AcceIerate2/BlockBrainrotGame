-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local utility = require(ReplicatedStorage.src.UIUtility.utility)

-->
local SellPanel = {}

function SellPanel:Init(player: Player)
	self.SellController = knit.GetController("SellController")

	self.Player = player
	self.Panel = utility.getPanel("Sell")
end

return SellPanel
