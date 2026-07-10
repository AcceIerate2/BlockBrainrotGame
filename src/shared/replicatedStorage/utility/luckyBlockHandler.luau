-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Utility Modules
local luckyBlocksConfig = require(ReplicatedStorage.src.GameConfiguration.General.luckyBlocksConfig)
local FormatTime = require(script.Parent.FormatTime)
local InstanceCreator = require(script.Parent.InstanceCreator)
local NumberShortner = require(script.Parent.NumberShortner)

-- Constants
local LuckyBlockHeader = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI"):WaitForChild("LuckyBlockHeader")

-- Helper Functions
local function isPlayer(player: Player): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local LuckyBlockHandler = {}

function LuckyBlockHandler.GetDisplayNameFromReferenceId(referenceId: string, player: Player?)
	assert(typeof(referenceId), "referenceId arg must be a string")
	local name = referenceId:find("_") and referenceId:split("_")[1] or referenceId
	return name:gsub("%u", " %0"):gsub("^%s+", "")
end

function LuckyBlockHandler.AddUiHeader(luckyBlockAsset: any, referenceId: string)
	local ui = LuckyBlockHeader:Clone()
	ui:WaitForChild("Labels"):WaitForChild("Content"):WaitForChild("Name").Text =
		LuckyBlockHandler.GetDisplayNameFromReferenceId(referenceId)
	ui.Enabled = true
	ui.Parent = luckyBlockAsset.PrimaryPart
end

function LuckyBlockHandler.ToggleCountdownState(luckyBlockAsset: any, enabled: boolean)
	luckyBlockAsset.PrimaryPart
		:WaitForChild("LuckyBlockHeader")
		:WaitForChild("Labels")
		:WaitForChild("Content")
		:WaitForChild("Countdown").Visible =
		enabled
end

function LuckyBlockHandler.UpdateCountdown(luckyBlockAsset, secondsLeft)
	luckyBlockAsset.PrimaryPart
		:WaitForChild("LuckyBlockHeader")
		:WaitForChild("Labels")
		:WaitForChild("Content")
		:WaitForChild("Countdown")
		:WaitForChild("Label").Text =
		`{secondsLeft > 60 and FormatTime(secondsLeft, secondsLeft <= 3600 and true or false) or secondsLeft}`
end

function LuckyBlockHandler.GetRarityFromName(luckyBlockName)
	return luckyBlockName:split("L")[1]:split(" ")[1]
end

function LuckyBlockHandler.AnimateBlock(luckyBlockAsset)
	local animationController = luckyBlockAsset:WaitForChild("AnimationController", 3)
	local animator = animationController and animationController:WaitForChild("Animator", 3)
	local animation = InstanceCreator("Animation", "Animation", workspace, {
		AnimationId = luckyBlocksConfig.LuckyBlocks[luckyBlockAsset.Name:split("_")[1]].AnimationId,
	})
	local animationTrack = animator and animator:LoadAnimation(animation)
	animation:Destroy()
	if animationTrack then
		animationTrack:Play()
	end
end

return LuckyBlockHandler
