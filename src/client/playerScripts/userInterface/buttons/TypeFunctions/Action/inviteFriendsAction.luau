-- Roblox Services
local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

-- Constants
local player = Players.LocalPlayer

-- Function to check whether the player can send an invite
local function canSendGameInvite(sendingPlayer)
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(sendingPlayer)
	end)
	return success and canSend
end

-->
return function()
	local canInvite = canSendGameInvite(player)
	if canInvite then
		SocialService:PromptGameInvite(player)
	end
end
