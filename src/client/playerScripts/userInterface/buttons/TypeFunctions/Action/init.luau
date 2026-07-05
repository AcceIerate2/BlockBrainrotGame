-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
local functions = {
	UpgradeBrainrot = require(script.upgradeBrainrotAction),
	DropBrainrot = require(script.dropBrainrotAction),
	Upgrade = require(script.upgradeAction),
	ToggleBlock = require(script.toggleBlockAction),
	SellBrainrot = require(script.sellBrainrotAction),
	SellAllBrainrots = require(script.sellAllBrainrotsAction),
	Teleport = require(script.teleportAction),
	InviteFriends = require(script.inviteFriendsAction),
	Rebirth = require(script.rebirthAction),
	PurchasePrompt = require(script.purchasePromptAction),
	ClaimOfflineCash = require(script.claimOfflineCashAction),
	ToggleIndexMutation = require(script.toggleIndexMutationAction),
	UpgradePlot = require(script.upgradePlotAction),
}

return function(button)
	if not button then
		return
	end

	local actionType = TypeCheck.Instance(button) and button:GetAttribute("Action") or button
	if not TypeCheck.string(actionType) then
		return
	end

	local functionToCall = functions[actionType]
	if typeof(functionToCall) ~= "function" then
		return
	end

	functionToCall(button)
end
