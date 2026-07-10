-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Config Modules
local brainrotConfig = require(ReplicatedStorage.src.GameConfiguration.General.brainrotConfig)
local mutationConfig = require(ReplicatedStorage.src.GameConfiguration.General.mutationConfig)
local rarityColors = require(ReplicatedStorage.src.GameConfiguration.General.rarityColors)

-- Constants
local BrainrotUiHeader = ReplicatedStorage.Assets.UI.BrainrotHeader
local BrainrotAssets = ReplicatedStorage.Assets.Brainrots

-- Helper Functions
local function getBrainrotScaleMultiplier(level: number): number
	level = math.max(level, 1)

	local maxLevel = 100
	local maxScale = 2.5
	local firstUpgradeScale = 1.25

	if level >= maxLevel then
		return maxScale
	end

	local progress = (level - 1) / (maxLevel - 1)
	local firstProgress = 1 / (maxLevel - 1)

	local exponent = math.log((firstUpgradeScale - 1) / (maxScale - 1)) / math.log(firstProgress)

	local multiplier = 1 + ((maxScale - 1) * (progress ^ exponent))
	return multiplier
end

local function getBrainrotUi(brainrotAsset: Instance, timeout: number?): BillboardGui?
	timeout = timeout or 3
	local startTime = os.clock()

	repeat
		if typeof(brainrotAsset) ~= "Instance" then
			return nil
		end

		local ui = brainrotAsset:FindFirstChildWhichIsA("BillboardGui", true)
		if ui then
			return ui
		end

		task.wait()
	until os.clock() - startTime >= timeout

	return nil
end

-->
local BrainrotHandler = {}

function BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId: string)
	return brainrotReferenceId:find("_") and brainrotReferenceId:split("_")[1] or brainrotReferenceId
end

function BrainrotHandler.GetBrainrotDisplayName(brainrotReferenceId: string)
	local name = brainrotReferenceId:find("_") and brainrotReferenceId:split("_")[1] or brainrotReferenceId
	return name:gsub("%u", " %0"):gsub("^%s+", "")
end

function BrainrotHandler.GetMutationFromBrainrotReferenceId(brainrotReferenceId: string, player: Player?): string
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")

	local mutation
	if RunService:IsServer() then
		mutation = knit.GetService("DataService"):GetValue(player, "Inventory")[brainrotReferenceId].Mutation
			or "Default"
	elseif RunService:IsClient() then
		mutation = knit.GetController("DataController"):GetValue("Inventory")[brainrotReferenceId].Mutation
	end

	return typeof(mutation) == "string" and mutation or "Default"
end

function BrainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId: string, player: Player?): number
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")

	local level
	if RunService:IsServer() then
		level = knit.GetService("DataService"):GetValue(player, "Inventory")[brainrotReferenceId].Level or 1
	elseif RunService:IsClient() then
		level = knit.GetController("DataController"):GetValue("Inventory")[brainrotReferenceId].Level or 1
	end

	return typeof(level) == "number" and level or 1
end

function BrainrotHandler.GetBrainrotRarity(brainrotReferenceId: string): string
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local brainrotName = BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)
	for rarity, brainrots in pairs(brainrotConfig) do
		if brainrots[brainrotName] then
			return rarity
		end
	end
	return "Common"
end

function BrainrotHandler.GetBrainrotIncomeRate(brainrotReferenceId: string, level: number?, player: Player?)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local _level = level or BrainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId, player)
	local mutation = BrainrotHandler.GetMutationFromBrainrotReferenceId(brainrotReferenceId, player) or "Default"
	local baseIncomeRate = BrainrotHandler.GetBrainrotBaseIncomeRate(brainrotReferenceId)
		* mutationConfig[mutation].Multiplier
	return baseIncomeRate * (1.1 ^ (_level - 1))
end

function BrainrotHandler.GetBrainrotBaseIncomeRate(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local brainrotName = BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)
	local rarity = BrainrotHandler.GetBrainrotRarity(brainrotReferenceId)
	return brainrotConfig[rarity][brainrotName].IncomeRate
end

function BrainrotHandler.GetBrainrotBaseCost(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	return BrainrotHandler.GetBrainrotBaseIncomeRate(brainrotReferenceId) * 10
end

function BrainrotHandler.GetBrainrotCost(brainrotReferenceId: string, level: number?, player: Player?)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local _level = level or BrainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId, player)
	return BrainrotHandler.GetBrainrotBaseCost(brainrotReferenceId) * (_level ^ 1.2)
end

function BrainrotHandler.CalculateLevelCost(brainrotReferenceId: string, level: number)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	assert(typeof(level) == "number", "level arg must be a number")
	local baseCost = BrainrotHandler.GetBrainrotBaseCost(brainrotReferenceId)
	return baseCost * (level ^ 1.2)
end

function BrainrotHandler.GetBrainrotIcon(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local brainrotName = BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)
	local rarity = BrainrotHandler.GetBrainrotRarity(brainrotReferenceId)
	return brainrotConfig[rarity][brainrotName] and brainrotConfig[rarity][brainrotName].Icon
end

function BrainrotHandler.GetBrainrotAnimations(brainrotReferenceId: string)
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	local brainrotName = BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)
	local rarity = BrainrotHandler.GetBrainrotRarity(brainrotReferenceId)
	return brainrotConfig[rarity][brainrotName].AnimationIds
end

function BrainrotHandler.ToggleCountdownState(brainrotAsset: any, enabled: boolean)
	local ui = getBrainrotUi(brainrotAsset)
	if not ui then
		return
	end

	ui.Labels.Content.Countdown.Visible = enabled
	ui.Labels.Content.Level.Visible = not enabled
end

function BrainrotHandler.UpdateLevel(
	brainrotAsset: any,
	brainrotReferenceId: string,
	newLevel: number?,
	player: Player?
)
	local ui = getBrainrotUi(brainrotAsset)
	if not ui then
		return
	end

	local level = newLevel or BrainrotHandler.GetLevelFromBrainrotReferenceId(brainrotReferenceId, player)
	ui.Labels.Content.Level.Text = `Level {level}`
	ui.Labels.Content.Income.Text =
		`${NumberShortner(BrainrotHandler.GetBrainrotIncomeRate(brainrotReferenceId, level, player))}/s`

	local defaultScale = brainrotAsset:GetAttribute("DefaultScale")
	local scaleMultiplier = getBrainrotScaleMultiplier(level)
	brainrotAsset:ScaleTo(defaultScale * scaleMultiplier)
end

function BrainrotHandler.AddUiHeader(brainrotAsset: any, mutation: string)
	local ui = BrainrotUiHeader:Clone()
	ui.Labels.Content.Income.Text = `${NumberShortner(BrainrotHandler.GetBrainrotBaseIncomeRate(brainrotAsset.Name))}/s`
	ui.Labels.Content.Level.Text = `Level 1`

	local rarity = BrainrotHandler.GetBrainrotRarity(brainrotAsset.Name)
	ui.Labels.Content.Rarity.Text = rarity
	ui.Labels.Content.Rarity.TextColor3 = rarityColors[rarity]

	ui.Labels.Content:FindFirstChild("Name").Text = BrainrotHandler.GetBrainrotDisplayName(brainrotAsset.Name)

	ui.Labels.Content.Mutation.Visible = typeof(mutation) == "string" and mutation ~= "Default"
	ui.Labels.Content.Mutation.Text = mutation
	ui.Labels.Content.Mutation.TextColor3 = mutationConfig[mutation].Color

	ui.StudsOffset = Vector3.new(0, brainrotAsset:GetExtentsSize().Y + 1, 0)
	ui.Parent = brainrotAsset:FindFirstChildOfClass("MeshPart")

	ui.Enabled = true
end

function BrainrotHandler.AnimateBrainrot(brainrotAsset: any)
	local animationController = brainrotAsset and brainrotAsset:FindFirstChildOfClass("AnimationController")
	local animator = animationController and animationController:FindFirstChildOfClass("Animator")
	if not animator then
		animator = InstanceCreator("Animator", "Animator", animationController)
	end

	local animationId = BrainrotHandler.GetBrainrotAnimations(brainrotAsset.Name).Idle
	local animationInstance = InstanceCreator("Animation", "IdleAnimation", brainrotAsset, {
		AnimationId = animationId,
	})

	local loadedAnimationTrack = animator:LoadAnimation(animationInstance)
	animationInstance:Destroy()

	loadedAnimationTrack:Play()
end

function BrainrotHandler.GetBrainrotAsset(
	brainrotName: string,
	mutation: string,
	shouldClone: boolean,
	skipUICreation: boolean?
)
	assert(typeof(brainrotName) == "string", "brainrotName arg must be a string")
	assert(typeof(mutation) == "string", "mutation arg must be a string")

	brainrotName = BrainrotHandler.GetBrainrotNameFromReferenceId(brainrotName)
	mutation = typeof(mutation) == "string" and mutation or "Default"

	local brainrotAsset = BrainrotAssets:FindFirstChild(mutation):FindFirstChild(brainrotName)
	if shouldClone then
		brainrotAsset = brainrotAsset:Clone()
		brainrotAsset:SetAttribute("DefaultScale", brainrotAsset:GetScale())
		if not skipUICreation then
			BrainrotHandler.AnimateBrainrot(brainrotAsset)
			BrainrotHandler.AddUiHeader(brainrotAsset, mutation)
		end
	end

	return brainrotAsset
end

function BrainrotHandler.UpdateCountdown(brainrotAsset: any, newText: string)
	local ui = getBrainrotUi(brainrotAsset)
	if not ui then
		return
	end

	ui.Labels.Content.Countdown.Label.Text = `{newText}`
end

return BrainrotHandler
