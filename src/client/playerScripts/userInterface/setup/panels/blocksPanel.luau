-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local utility = require(ReplicatedStorage.src.UIUtility.utility)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local blocksConfig = require(ReplicatedStorage.src.GameConfiguration.General.blocksConfig)
local viewportHandler = require(ReplicatedStorage.src.utility.viewportHandler)

-- Constants
local BlockAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Blocks")

-->
local BlocksPanel = {
	Cards = {},
}

function BlocksPanel:getBlockAsset(blockName: string)
	assert(typeof(blockName) == "string", "blockName arg must be a string")
	return BlockAssets:WaitForChild(blockName, 1)
end

function BlocksPanel:getCost(blockName: string): number
	return blocksConfig.Blocks[blockName].Cost
end

function BlocksPanel:setIcon(blockName, card)
	local viewportFrame = card:WaitForChild("Details"):WaitForChild("ViewportFrame")
	local vectorImageLabel = viewportFrame:WaitForChild("Vector")

	if typeof(blocksConfig.Blocks[blockName].Icon) == "string" then
		vectorImageLabel.Image = blocksConfig.Blocks[blockName].Icon
	else
		viewportHandler.Setup(
			card:WaitForChild("Details"):WaitForChild("ViewportFrame"),
			self:getBlockAsset(blockName),
			{
				Padding = 1.25,
			}
		)
		vectorImageLabel.Visible = false
	end
end

function BlocksPanel:syncCard(blockName: string, props: { Equipped: boolean, Owned: boolean })
	assert(typeof(blockName) == "string", "blockName arg must be a string")

	local card = self.Cards[blockName]
	assert(typeof(card) ~= nil, `Couldn't find card named: [{blockName}]!`)

	local textToDisplay = props.Equipped and "Equipped"
		or not props.Equipped and props.Owned and "Equip"
		or not props.Owned and `${NumberShortner(self:getCost(blockName))}`

	local backgroundColor = props.Equipped and Color3.fromRGB(0, 183, 255)
		or not props.Equipped and props.Owned and Color3.fromRGB(0, 255, 0)
		or not props.Owned and Color3.fromRGB(0, 255, 0)

	local canAfford = (props.Equipped or props.Owned) and true
		or not props.Owned and self.DataController:GetValue("Cash") >= self:getCost(blockName)

	card:WaitForChild("Buttons"):WaitForChild("Toggle").BackgroundColor3 = backgroundColor
	card:WaitForChild("Buttons"):WaitForChild("Toggle"):WaitForChild("TextLabel").Text = `{textToDisplay}`
	card:WaitForChild("Details"):WaitForChild("Content"):WaitForChild("WalkSpeedMultiplier").Text =
		`x{blocksConfig.Blocks[blockName].WalkSpeedMultiplier} WalkSpeed`
end

function BlocksPanel:createCards()
	for blockName: string, _ in pairs(blocksConfig.Blocks) do
		local newTemplate = self.BlockTemplate:Clone()
		newTemplate.Name = blockName

		newTemplate:WaitForChild("Details"):WaitForChild("Content"):WaitForChild("TextLabel").Text =
			blockName:gsub("%u", " %0"):gsub("^%s+", "")

		newTemplate:WaitForChild("Buttons"):WaitForChild("Toggle"):AddTag("GuiButton")
		newTemplate:WaitForChild("Buttons"):WaitForChild("Toggle"):SetAttribute("Type", "Action")
		newTemplate:WaitForChild("Buttons"):WaitForChild("Toggle"):SetAttribute("Action", "ToggleBlock")
		newTemplate:WaitForChild("Buttons"):WaitForChild("Toggle"):SetAttribute("BlockName", blockName)

		self:setIcon(blockName, newTemplate)
		self.ButtonsController:link(newTemplate:WaitForChild("Buttons"):WaitForChild("Toggle"))

		newTemplate.Visible = true
		newTemplate.Parent = self.Container

		self.Cards[blockName] = newTemplate
		self:syncCard(blockName, self.BlockController:GetState(blockName))
	end
end

function BlocksPanel:Init(player: Player)
	self.ButtonsController = knit.GetController("ButtonsController")
	self.BlockController = knit.GetController("BlockController")
	self.DataController = knit.GetController("DataController")

	self.Player = player
	self.Panel = utility.getPanel("Blocks")
	self.Container = self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrame")

	self.BlockTemplate = self.Container:WaitForChild("BlockTemplate")
	self.BlockTemplate.Visible = false
	self:createCards()

	self.BlockController.UpdateCardState:Connect(
		function(BlockName: string, props: { Equipped: boolean, Owned: boolean })
			self:syncCard(BlockName, props)
		end
	)
end

return BlocksPanel
