-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local BlocksLabel = {}

function BlocksLabel:update(blocksValue, maxBlocksValue)
	self.Label.Text = `{blocksValue}/{maxBlocksValue}`
end

function BlocksLabel:Init(player: Player)
	self.DataController = knit.GetController("DataController")

	self.Player = player
	self.Label = self.Player.PlayerGui:WaitForChild("Hud"):WaitForChild("Blocks")

	self:update(self.DataController:GetValue("Blocks").Value, self.DataController:GetValue("MaxBlocks").Value)
	self.DataController:GetValueChangedSignal("Blocks"):Connect(function(newValue)
		self:update(newValue.Value, self.DataController:GetValue("MaxBlocks").Value)
	end)

	self.DataController:GetValueChangedSignal("MaxBlocks"):Connect(function(newValue)
		self:update(self.DataController:GetValue("Blocks").Value, newValue.Value)
	end)
end

return BlocksLabel
