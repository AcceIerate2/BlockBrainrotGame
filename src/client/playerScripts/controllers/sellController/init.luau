-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Constants
local Player = Players.LocalPlayer

-->
local SellController = knit.CreateController({
	Name = "SellController",
	RefreshBrainrots = Signal.new(),
	RemoveCard = Signal.new(),
	ClearCards = Signal.new(),
})

-- Private Methods
function SellController:listenToPanelController()
	self.PanelController.PanelStateChanged:Connect(function(newState: { Visible: boolean, PanelName: string })
		if newState.Visible and newState.PanelName == "Sell" then
			self.RefreshBrainrots:Fire()
		else
			self.ClearCards:Fire()
		end
	end)
end

-- Public Methods
function SellController:GetInactiveBrainrots()
	local inactiveBrainrots = {}
	for _, child in pairs(Player.Backpack:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("Handler") == "BrainrotTool" then
			table.insert(inactiveBrainrots, child.Name)
		end
	end

	local character = Player.Character
	local equippedTool = character and character:FindFirstChildOfClass("Tool")
	if equippedTool and equippedTool:GetAttribute("Handler") == "BrainrotTool" then
		table.insert(inactiveBrainrots, equippedTool.Name)
	end

	return inactiveBrainrots
end

function SellController:SellBrainrot(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	warn(`Selling specific Brainrot: {brainrotReferenceId}`)
	self.BrainrotService
		:SellBrainrot(brainrotReferenceId)
		:andThen(function(response: { Status: boolean, SoldBrainrot: string, Cost: number })
			warn(response)
			self.RemoveCard:Fire(brainrotReferenceId)
		end)
		:catch(warn)
end

function SellController:SellAllBrainrots()
	warn(`Selling all brainrots`)
	self.BrainrotService
		:SellBrainrots(self:GetInactiveBrainrots())
		:andThen(function(response: { Status: boolean })
			warn(response)
			if not response.Status then
				return
			end

			self.ClearCards:Fire()
		end)
		:catch(warn)
end

function SellController:GetBrainrots() end

-- LifeCycle
function SellController:KnitInit()
	self.BrainrotService = knit.GetService("BrainrotService")
	self.PanelController = knit.GetController("PanelController")
end

function SellController:KnitStart()
	self:listenToPanelController()
end

return SellController
