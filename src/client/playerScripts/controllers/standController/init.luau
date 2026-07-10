-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local PlayTween = require(ReplicatedStorage.src.utility.PlayTween)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)
local particleEmitter = require(ReplicatedStorage.src.utility.particleEmitter)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Constants
local Player = Players.LocalPlayer
local Particles = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Effects")
local MoneyPickup = Particles:WaitForChild("MoneyPickup")

-- Helper Functions
local function getProximityPrompt(standAsset: any): ProximityPrompt
	return standAsset:WaitForChild("ProximityPrompt"):WaitForChild("ProximityPrompt") :: ProximityPrompt
end

local function updateProximityPromptText(newText: string, standAsset: any)
	getProximityPrompt(standAsset).ActionText = newText
end

local function updateProximityPromptObjectText(newText: string, standAsset: any)
	getProximityPrompt(standAsset).ObjectText = newText
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
	CashCollectCooldowns = {},
	CashCollectCooldownDuration = 0.35,

	ConnectionProfiles = {},
	CashConnectionProfiles = {},
})

-- Private Methods
function StandController:getCashUI(standAsset)
	local cashCollector = standAsset:WaitForChild("CashCollector")
	return cashCollector and cashCollector:WaitForChild("UI")
end

function StandController:toggleStandCashVisibility(standAsset, visible: boolean)
	local ui = self:getCashUI(standAsset)
	if ui then
		if visible then
			ui.Cash.Text = `$0`
		end
		ui.Enabled = visible
	end
end

function StandController:effect(standAsset)
	local brainrot = standAsset.Brainrot:FindFirstChildOfClass("Model")
	if not brainrot then
		return
	end

	local originalCFrame = brainrot:GetAttribute("DefaultCFrame")
	if typeof(originalCFrame) ~= "CFrame" then
		originalCFrame = brainrot.PrimaryPart.CFrame
		brainrot:SetAttribute("DefaultCFrame", originalCFrame)
	end

	PlayTween(
		brainrot.PrimaryPart,
		TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true, 0),
		{
			CFrame = originalCFrame * CFrame.new(0, 3, 0),
		}
	)

	local highlightToDestroy = brainrot.PrimaryPart:FindFirstChildOfClass("Highlight")
	if highlightToDestroy then
		highlightToDestroy:Destroy()
	end

	local highlight = InstanceCreator("Highlight", "Highlight", brainrot.PrimaryPart, {
		FillColor = Color3.fromRGB(157, 255, 0),
		FillTransparency = 0.25,
		OutlineTransparency = 1,
	})

	PlayTween(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0), {
		FillTransparency = 1,
	}).Completed:Once(function()
		highlight:Destroy()
	end)

	local cashCollector = standAsset:WaitForChild("CashCollector")
	PlayTween(cashCollector, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true, 0), {
		Size = Vector3.new(2.05, 0.475, 5.65) - Vector3.new(0, 0.3, 0),
		Color = Color3.fromRGB(51, 90, 0),
	}).Completed:Once(function()
		cashCollector.Size = Vector3.new(2.05, 0.475, 5.65)
		cashCollector.Color = Color3.fromRGB(92, 162, 0)
	end)

	particleEmitter(MoneyPickup, cashCollector)
	self.AudioController:PlayAudio("CashStand", true, cashCollector)
	self.AudioController:PlayAudio("Button", true, cashCollector)
end

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
	self.ConnectionProfiles[standAsset] = standAsset
		:WaitForChild("CashCollector").Touched
		:Connect(function(partThatTouched: BasePart)
			if not validateCashCollectPart(partThatTouched) then
				return
			end

			if self.CashCollectCooldowns[standAsset] == true then
				return
			end

			self.CashCollectCooldowns[standAsset] = true
			task.delay(self.CashCollectCooldownDuration, function()
				self.CashCollectCooldowns[standAsset] = nil
			end)

			self:effect(standAsset)
			self:collectCash(standAsset)
		end)
end

function StandController:connectCashChangedSignal(standAsset)
	local ui = self:getCashUI(standAsset)
	if not ui then
		return
	end

	self.CashConnectionProfiles[standAsset] = standAsset.Cash.Changed:Connect(function()
		if ui then
			ui.Cash.Text = `${NumberShortner(standAsset.Cash.Value)}`
		end
	end)
end

function StandController:disconnectCashChangedSignal(standAsset)
	if typeof(self.CashConnectionProfiles[standAsset]) == "RBXScriptConnection" then
		self.CashConnectionProfiles[standAsset]:Disconnect()
		self.CashConnectionProfiles[standAsset] = nil
	end
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
function StandController:placed(standAsset, brainrotReferenceId: string)
	local isLuckyBlock = brainrotReferenceId:find("LuckyBlock")

	self:toggleStandProximityPromptVisibility(standAsset, true)
	updateProximityPromptText("Remove", standAsset)

	local brainrotDisplayName = brainrotHandler.GetBrainrotDisplayName(brainrotReferenceId)
	updateProximityPromptObjectText(brainrotDisplayName, standAsset)

	if not isLuckyBlock then
		self:connectCashChangedSignal(standAsset)
		self:toggleStandCashVisibility(standAsset, true)
		self:connectCashCollect(standAsset)
		self:connectUpgradeButton(standAsset)
	end

	local brainrotAsset = standAsset.Brainrot:FindFirstChildOfClass("Model")
	if brainrotAsset and not isLuckyBlock then
		brainrotHandler.UpdateLevel(brainrotAsset, brainrotReferenceId)
	end

	self.SellController.RefreshBrainrots:Fire()
	self.AudioController:PlayAudio("Place", true, brainrotAsset.PrimaryPart)
end

function StandController:removed(standAsset)
	updateProximityPromptText("Place", standAsset)
	updateProximityPromptObjectText("Empty", standAsset)

	self:toggleStandProximityPromptVisibility(standAsset, false)

	self:disconnectCashChangedSignal(standAsset)
	self:toggleStandCashVisibility(standAsset, false)
	self:disconnectCashCollect(standAsset)
	self:disconnectUpgradeButton(standAsset)

	self.SellController.RefreshBrainrots:Fire()
	self.AudioController:PlayAudio("Equip", true, standAsset.ProximityPrompt)
end

function StandController:listenToService()
	self.StandService.BrainrotPlaced:Connect(function(standAsset, brainrotReferenceId: string)
		self:placed(standAsset, brainrotReferenceId)
	end)

	self.StandService.BrainrotRemoved:Connect(function(standAsset)
		self:removed(standAsset)
	end)
end

function StandController:toggleStandProximityPromptVisibility(standAsset, toggle: boolean)
	local proximityPrompt =
		standAsset:WaitForChild("ProximityPrompt"):WaitForChild("ProximityPrompt") :: ProximityPrompt
	local equippedTool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
	if equippedTool and proximityPrompt.ActionText == "Remove" then
		proximityPrompt.ActionText = "Replace"
	elseif not equippedTool and proximityPrompt.ActionText == "Replace" then
		proximityPrompt.ActionText = "Remove"
	end

	if toggle == false and (proximityPrompt.ActionText == "Remove" or proximityPrompt.ActionText == "Replace") then
		proximityPrompt.Enabled = true
	else
		proximityPrompt.Enabled = toggle
	end
end

-- Public Methods
function StandController:ToggleProximityPromptVisibility(toggle: boolean)
	assert(typeof(toggle) == "boolean", "toggle arg must be a boolean")
	local plotAsset = self.PlotController:GetPlotAsset()
	for _, stand in pairs(plotAsset:WaitForChild("Stands"):GetChildren()) do
		self:toggleStandProximityPromptVisibility(stand, toggle)
	end
end

function StandController:GetStandFromBrainrotReferenceId(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	for standAsset, _ in pairs(self.ConnectionProfiles) do
		local brainrot = standAsset.Brainrot:FindFirstChildOfClass("Model")
		if brainrot and brainrot.Name == brainrotReferenceId then
			return standAsset
		end
	end
	return
end

-- LifeCycle
function StandController:KnitInit()
	self.StandService = knit.GetService("StandService")
	self.DataController = knit.GetController("DataController")
	self.ButtonsController = knit.GetController("ButtonsController")
	self.PlotController = knit.GetController("PlotController")
	self.SellController = knit.GetController("SellController")
	self.AudioController = knit.GetController("AudioController")
end

function StandController:KnitStart()
	self:listenToService()
end

return StandController
