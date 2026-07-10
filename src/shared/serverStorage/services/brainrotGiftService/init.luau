-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)
local luckyBlockHandler = require(ReplicatedStorage.src.utility.luckyBlockHandler)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local BrainrotGiftService = knit.CreateService({
	Name = "BrainrotGiftService",
	Client = {},
})

--[[
	self.BrainrotGiftService
		:Gift({
			Name = playerNameToGiftTo,
			brainrotReferenceId = brainrotReferenceId,
			Mutation = mutation,
		})
		:andThen(function(response)
			warn(response)
		end)
		:catch(warn)
]]

-- Client Exposed Methods
function BrainrotGiftService.Client:RequestToGiftPlayer(
	player: Player,
	data: {
		Name: string,
		BrainrotReferenceId: string,
		Mutation: string,
	}
)
	return self.Server:RequestToGiftPlayer(player, data)
end

-- Public Methods
function BrainrotGiftService:RequestToGiftPlayer(
	player: Player,
	data: { Name: string, BrainrotReferenceId: string, Mutation: string }
)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(data) == "table", "data arg must be a table")
	local isLuckyBlock = data.BrainrotReferenceId:find("LuckyBlock")

	local sendingPlayerOwnsBrainrot = self.DataService:GetValue(player, "Inventory")[data.BrainrotReferenceId]
	if not sendingPlayerOwnsBrainrot or isLuckyBlock and sendingPlayerOwnsBrainrot.Mutation ~= data.Mutation then
		return {
			Accepted = false,
			Reason = `You don't own this {isLuckyBlock and "Lucky Block" or "Brainrot"}!`,
		}
	end

	local otherPlayer = Players:FindFirstChild(data.Name)
	if not otherPlayer then
		return {
			Accepted = false,
			Reason = "Player left the game",
		}
	end

	local response = self.ConfirmationService:Prompt(player, otherPlayer, {
		Title = "Gift Request",
		Message = `{player.Name} wants to give you{isLuckyBlock and "" or data.Mutation ~= "Default" and " " .. data.Mutation or ""} {isLuckyBlock and luckyBlockHandler.GetDisplayNameFromReferenceId(
			data.BrainrotReferenceId
		) or brainrotHandler.GetBrainrotDisplayName(data.BrainrotReferenceId)}`,

		Options = {
			Option1 = "Accept",
			Option2 = "Decline",
		},

		Duration = 10,
	})

	if response.Status == true then
		local ok: boolean, promiseResponse = response.Promise:await()

		if ok and promiseResponse.Status == true and promiseResponse.Response.Option1 == true then
			self:Gift(player, data)
			return {
				Accepted = true,
			}
		else
			return {
				Accepted = false,
				Reason = promiseResponse.Reason,
			}
		end
	end

	return {
		Accepted = false,
		Reason = response.Reason,
	}
end

function BrainrotGiftService:Gift(player: Player, data: { Name: string, BrainrotReferenceId: string, Mutation: string })
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(data) == "table", "data arg must be a table")

	local sendingPlayerOwnsBrainrot = self.DataService:GetValue(player, "Inventory")[data.BrainrotReferenceId]
	if not sendingPlayerOwnsBrainrot then
		return {
			Status = false,
			Reason = `You don't own{data.Mutation ~= "Default" and " " .. data.Mutation or ""} {brainrotHandler.GetBrainrotDisplayName(
				data.BrainrotReferenceId
			)}!`,
		}
	end

	local otherPlayer = Players:FindFirstChild(data.Name)
	if not otherPlayer then
		return {
			Status = false,
			Reason = `{data.Name} left the game`,
		}
	end

	self.InventoryService:Remove(player, data.BrainrotReferenceId)
	self.InventoryService:RemoveTool(player, data.BrainrotReferenceId)

	local isLuckyBlock = data.BrainrotReferenceId:find("LuckyBlock")
	self.InventoryService:Give(otherPlayer, data.BrainrotReferenceId, "BrainrotTool", {
		Mutation = not isLuckyBlock and (data.Mutation or "Default") or nil,
		Level = not isLuckyBlock and 1 or nil,
		Type = isLuckyBlock and "LuckyBlock" or "Brainrot",
	})

	return {
		Status = true,
	}
end

-- LifeCycle
function BrainrotGiftService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.InventoryService = knit.GetService("InventoryService")
	self.ConfirmationService = knit.GetService("ConfirmationService")
end

return BrainrotGiftService
