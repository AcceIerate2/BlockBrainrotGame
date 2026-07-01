-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local mutationConfig = require(ReplicatedStorage.src.GameConfiguration.General.mutationConfig)
local rarityColors = require(ReplicatedStorage.src.GameConfiguration.General.rarityColors)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Constants
local BrainrotsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Brainrots")
local DefaultBrainrotAssets = BrainrotsFolder:WaitForChild("Default")

-->
local IndexPanel = {
	Cards = (function()
		local _table = {}
		for mutation: string, _ in pairs(mutationConfig) do
			_table[mutation] = {}
		end
		return _table
	end)(),
}

-- Private Methods
function IndexPanel:toggleCardOwnership(card: any, mutation: string)
	local brainrotName = card.Name
	local owned = self.IndexController:Owned(brainrotName, mutation)

	card:WaitForChild("Content"):WaitForChild("Vector").ImageColor3 = owned and Color3.fromRGB(255, 255, 255)
		or Color3.fromRGB(0, 0, 0)

	card:WaitForChild("Content"):WaitForChild("Title").Text = owned
			and brainrotHandler.GetBrainrotDisplayName(brainrotName)
		or "???"
end

function IndexPanel:loadIndexCards(mutation: string, scrollingFrame: ScrollingFrame)
	for _, brainrotAsset in pairs(DefaultBrainrotAssets:GetChildren()) do
		local newCard = self.CardTemplate:Clone()
		newCard:WaitForChild("Content"):WaitForChild("Vector").Image = brainrotHandler.GetBrainrotIcon(
			brainrotAsset.Name
		) or ""

		local rarity = brainrotHandler.GetBrainrotRarity(brainrotAsset.Name)
		newCard:WaitForChild("Content"):WaitForChild("Rarity").Text = rarity
		newCard:WaitForChild("Content"):WaitForChild("Rarity").TextColor3 = rarityColors[rarity]

		newCard:WaitForChild("Content"):WaitForChild("Mutation").Text = mutation
		newCard:WaitForChild("Content"):WaitForChild("Mutation").TextColor3 = mutationConfig[mutation].Color

		newCard.Visible = true
		newCard.Name = `{brainrotAsset.Name}`
		-- newCard.LayoutOrder = brainrotHandler.GetBrainrotBaseIncomeRate(brainrotAsset.Name)
		newCard.Parent = scrollingFrame

		self.Cards[mutation][brainrotAsset.Name] = newCard
		self:toggleCardOwnership(newCard, mutation)
	end
end

function IndexPanel:loadScrollingFrames()
	for mutation: string, _ in pairs(mutationConfig) do
		local newScrollingFrame = self.ScrollingFrameTemplate:Clone()
		newScrollingFrame.Name = `{mutation}ScrollingFrame`
		newScrollingFrame.Visible = mutation == "Default" and true or false
		newScrollingFrame.Parent = self.ScrollingFrameTemplate.Parent
		self:loadIndexCards(mutation, newScrollingFrame)
	end
end

-- LifeCycle
function IndexPanel:Init(player: Player)
	self.IndexController = knit.GetController("IndexController")
	self.Player = player
	self.Panel = self.Player.PlayerGui:WaitForChild("Panels"):WaitForChild("Index")

	self.ScrollingFrameTemplate = self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrameTemplate")
	self.ScrollingFrameTemplate.Visible = false

	self.CardTemplate = self.ScrollingFrameTemplate:WaitForChild("CardTemplate")
	self.CardTemplate.Visible = false

	self:loadScrollingFrames()
	self.IndexController.Signals.Added:Connect(function(brainrotName: string, mutation: string)
		assert(typeof(brainrotName) == "string", "brainrotName arg must be a string")
		assert(typeof(mutation) == "string", "mutation arg must be a string")
		self:toggleCardOwnership(self.Cards[mutation][brainrotName], mutation)
	end)
end

return IndexPanel
