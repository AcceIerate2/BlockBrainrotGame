-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Constants
local Player = Players.LocalPlayer

-- Helper Functions
local function getProximityPrompt(standAsset: any): ProximityPrompt
	return standAsset:WaitForChild("ProximityPrompt"):WaitForChild("ProximityPrompt") :: ProximityPrompt
end

local function updateProximityPromptText(newText: string, standAsset: any)
	getProximityPrompt(standAsset).ActionText = newText
end

local function validateCashCollectPart(partThatTouched: BasePart): boolean
	local character = partOfCharacter(partThatTouched)
	if not character then
		return false
	end

	local playerThatTouched = Players:GetPlayerFromCharacter(character)
	if playerThatTouched ~= Player then
		return false
	end

	return true
end

-->
local StandController = knit.CreateController({
	Name = "StandController",
	CashCollectCooldown = false,
	CashCollectCooldownDuration = 0.35,
	ConnectionProfiles = {},
})

-- Private Methods
function StandController:collectCash(standAsset)
	self.StandService
		:CollectCash(standAsset)
		:andThen(function(response: { Status: boolean })
			if not response.Status then
				return
			end
		end)
		:catch(warn)
end

function StandController:disconnectCashCollect(standAsset)
	if typeof(self.ConnectionProfiles[standAsset]) == "RBXScriptConnection" then
		self.ConnectionProfiles[standAsset]:Disconnect()
		self.ConnectionProfiles[standAsset] = nil
	end
end

function StandController:connectCashCollect(standAsset)
	self:disconnectCashCollect(standAsset)
	self.ConnectionProfiles[standAsset] = standAsset.CashCollector.Touched:Connect(function(partThatTouched: BasePart)
		if not validateCashCollectPart(partThatTouched) then
			return
		end

		if self.CashCollectCooldown == true then
			return
		end

		self.CashCollectCooldown = true
		task.delay(self.CashCollectCooldownDuration, function()
			self.CashCollectCooldown = false
		end)

		self:collectCash(standAsset)
	end)
end

function StandController:syncUpgradeButton(standAsset)
	local surfaceGui = standAsset:WaitForChild("Upgrade"):WaitForChild("SurfaceGui")
	local button = surfaceGui:WaitForChild("Button")

	local brainrotReferenceId = standAsset.Brainrot:FindFirstChildOfClass("Model").Name
	local level = brainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId)
	local nextLevel = level + 1
	local costToUpgrade = brainrotHandler.CalculateLevelCost(brainrotReferenceId, nextLevel)

	button:WaitForChild("Cost").Text = `${NumberShortner(costToUpgrade)}`
	button:WaitForChild("Level").Text = `Lvl {level} > Lvl {nextLevel}`
end

function StandController:connectUpgradeButton(standAsset)
	local surfaceGui = standAsset:WaitForChild("Upgrade"):WaitForChild("SurfaceGui")
	local button = surfaceGui:WaitForChild("Button")

	button:AddTag("GuiButton")
	button:SetAttribute("Type", "Action")
	button:SetAttribute("Action", "UpgradeBrainrot")

	local brainrotReferenceId = standAsset.Brainrot:FindFirstChildOfClass("Model").Name
	button:SetAttribute("BrainrotReferenceId", brainrotReferenceId)

	self:syncUpgradeButton(standAsset, brainrotReferenceId)
	surfaceGui.Enabled = true
	self.ButtonsController:link(button)
end

function StandController:disconnectUpgradeButton(standAsset)
	local surfaceGui = standAsset:WaitForChild("Upgrade"):WaitForChild("SurfaceGui")
	local button = surfaceGui:WaitForChild("Button")

	surfaceGui.Enabled = false
	self.ButtonsController:unlink(button)
end

-- Place/Remove
function StandController:placed(standAsset)
	updateProximityPromptText("Remove", standAsset)
	self:connectCashCollect(standAsset)
	self:connectUpgradeButton(standAsset)
end

function StandController:removed(standAsset)
	updateProximityPromptText("Place", standAsset)
	self:disconnectCashCollect(standAsset)
	self:disconnectUpgradeButton(standAsset)
end

function StandController:listenToService()
	self.StandService.BrainrotPlaced:Connect(function(standAsset)
		self:placed(standAsset)
	end)

	self.StandService.BrainrotRemoved:Connect(function(standAsset)
		self:removed(standAsset)
	end)
end

-- LifeCycle
function StandController:KnitInit()
	self.StandService = knit.GetService("StandService")
	self.DataController = knit.GetController("DataController")
	self.ButtonsController = knit.GetController("ButtonsController")
end

function StandController:KnitStart()
	self:listenToService()
end

return StandController
