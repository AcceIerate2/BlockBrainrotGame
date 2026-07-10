-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local IndexService = knit.CreateService({
	Name = "IndexService",
	Client = {
		Added = knit.CreateSignal(),
	},
})

-- Private Methods
function IndexService:brainrotExists(player: Player, brainrotReferenceId: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	return self.DataService:GetValue(player, "Index")[brainrotHandler.GetBrainrotNameFromReferenceId(
		brainrotReferenceId
	)]
end

-- Public Methods
function IndexService:AddBrainrot(player: Player, brainrotReferenceId: string, mutation: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(brainrotReferenceId) == "string", "brainrotReferenceId arg must be a string")
	assert(typeof(mutation) == "string", "mutation arg must be a string")

	local brainrotName = brainrotHandler.GetBrainrotNameFromReferenceId(brainrotReferenceId)
	if self:brainrotExists(player, brainrotReferenceId) then
		return
	end

	local indexValueObject = self.DataService:GetValueObject(player, "Index")
	indexValueObject:Update(function(cached)
		cached[mutation][brainrotName] = true
	end)

	self.Client.Added:Fire(player, brainrotName, mutation)
end

function IndexService:Sync(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local playerInventory = self.DataService:GetValue(player, "Inventory")
	for referenceId: string, data: { Handler: string, Mutation: string, Type: string } in pairs(playerInventory) do
		if data.Handler ~= "BrainrotTool" or data.Type ~= "Brainrot" then
			continue
		end

		if self:brainrotExists(player, referenceId) then
			continue
		end

		local mutation = data.Mutation or "Default"
		self:AddBrainrot(player, referenceId, mutation)
	end
end

-- LifeCycle
function IndexService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

return IndexService
