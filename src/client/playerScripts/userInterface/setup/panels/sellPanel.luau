-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local utility = require(ReplicatedStorage.src.UIUtility.utility)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-->
local SellPanel = {
	Cards = {},
}

function SellPanel:removeCard(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	for card, _ in pairs(self.Cards) do
		if card and card.Name == brainrotReferenceId then
			self.Cards[card] = nil
			self.ButtonsController:unlink(card:WaitForChild("Buttons"):WaitForChild("Toggle"))
			card:Destroy()
		end
	end
end

function SellPanel:clearCards()
	for card, _ in pairs(self.Cards) do
		local buttons = card:FindFirstChild("Buttons")
		local toggle = buttons and buttons:FindFirstChild("Toggle")
		if toggle then
			self.ButtonsController:unlink(toggle)
		end
		card:Destroy()
	end
	table.clear(self.Cards)
end

function SellPanel:newCard(brainrotReferenceId: string)
	local newCard = self.CardTemplate:Clone()
	local detailsFrame = newCard:WaitForChild("Details")
	local detailsContentFrame = detailsFrame:WaitForChild("Content")
	local buttonDetailsFrame = newCard:WaitForChild("Buttons"):WaitForChild("Details")

	detailsFrame:WaitForChild("ViewportFrame"):WaitForChild("Vector").Image =
		brainrotHandler.GetBrainrotIcon(brainrotReferenceId)
	detailsContentFrame:WaitForChild("Name").Text = brainrotHandler.GetBrainrotDisplayName(brainrotReferenceId)
	detailsContentFrame:WaitForChild("Rarity").Text = brainrotHandler.GetBrainrotRarity(brainrotReferenceId)
	detailsContentFrame:WaitForChild("Mutation").Text =
		brainrotHandler.GetMutationFromBrainrotReferenceId(brainrotReferenceId)

	buttonDetailsFrame:WaitForChild("Level").Text =
		`Lvl {brainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId)}`

	local cost = brainrotHandler.GetBrainrotCost(
		brainrotReferenceId,
		brainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId)
	)
	buttonDetailsFrame:WaitForChild("Cost").Text = `${NumberShortner(cost)}`

	local toggleBtn = newCard:WaitForChild("Buttons"):WaitForChild("Toggle")
	toggleBtn:AddTag("GuiButton")
	toggleBtn:SetAttribute("Type", "Action")
	toggleBtn:SetAttribute("Action", "SellBrainrot")
	toggleBtn:SetAttribute("BrainrotReferenceId", brainrotReferenceId)
	self.ButtonsController:link(toggleBtn)

	newCard.LayoutOrder = -cost
	newCard.Name = brainrotReferenceId
	newCard.Visible = true
	newCard.Parent = self.Container

	self.Cards[newCard] = true
end

function SellPanel:refreshBrainrots()
	self:clearCards()
	for _, brainrotReferenceId: string in pairs(self.SellController:GetInactiveBrainrots()) do
		local isLuckyBlock = brainrotReferenceId:find("Lucky")
		if isLuckyBlock then
			continue
		end
		self:newCard(brainrotReferenceId)
	end
end

function SellPanel:Init(player: Player)
	self.SellController = knit.GetController("SellController")
	self.ButtonsController = knit.GetController("ButtonsController")

	self.Player = player

	self.Panel = utility.getPanel("Sell")
	self.Container = self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrame")
	self.CardTemplate = self.Container:WaitForChild("CardTemplate")
	self.CardTemplate.Visible = false

	self.SellController.RefreshBrainrots:Connect(function()
		self:refreshBrainrots()
	end)

	self.SellController.RemoveCard:Connect(function(brainrotReferenceId: string)
		self:removeCard(brainrotReferenceId)
	end)

	self.SellController.ClearCards:Connect(function()
		self:clearCards()
	end)
end

return SellPanel
