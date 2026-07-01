-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local CollisionHandler = require(ReplicatedStorage.src.utility.CollisionHandler)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local brainrotHandler = require(ReplicatedStorage.src.utility.brainrotHandler)

-- Constants
local Player = Players.LocalPlayer

-- Helper Functions
local function getBrainrotAsset(brainrotName: string, mutation: string): Model
	assert(typeof(brainrotName) == "string", "brainrotName arg must be a string")
	assert(typeof(mutation) == "string", "mutation arg must be a string")

	return ReplicatedStorage:WaitForChild("Assets")
		:WaitForChild("Brainrots")
		:WaitForChild(mutation)
		:WaitForChild(brainrotName)
		:Clone()
end

local function getMainMeshPart(brainrotAsset: Model): MeshPart?
	return brainrotAsset:FindFirstChildOfClass("MeshPart")
end

local function createAttachments(brainrotAsset: Model): (Attachment?, Attachment?)
	local character = Player.Character
	if not character then
		return nil, nil
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return nil, nil
	end

	local mainMeshPart = getMainMeshPart(brainrotAsset)
	if not mainMeshPart then
		return nil, nil
	end

	local hrpAttachment = InstanceCreator("Attachment", "Attachment", humanoidRootPart, {
		CFrame = CFrame.new(0, 0, -1.25),
	}) :: Attachment

	local extentsSize = brainrotAsset:GetExtentsSize()

	local brainrotAssetAttachment = InstanceCreator("Attachment", "Attachment", mainMeshPart, {
		CFrame = CFrame.new(0, 0, (extentsSize.Z / 2)),
	}) :: Attachment

	return hrpAttachment, brainrotAssetAttachment
end

local function pivotModelSoAttachmentMatches(model: Model, attachment: Attachment, targetCFrame: CFrame)
	assert(typeof(model) == "Instance" and model:IsA("Model"), "model arg must be a Model")
	assert(typeof(attachment) == "Instance" and attachment:IsA("Attachment"), "attachment arg must be an Attachment")
	assert(typeof(targetCFrame) == "CFrame", "targetCFrame arg must be a CFrame")

	local modelPivot = model:GetPivot()
	local attachmentOffsetFromPivot = modelPivot:ToObjectSpace(attachment.WorldCFrame)

	model:PivotTo(targetCFrame * attachmentOffsetFromPivot:Inverse())
end

local function createAlignInstances(
	hrpAttachment: Attachment,
	brainrotAssetAttachment: Attachment,
	parent: Instance
): (AlignPosition, AlignOrientation)
	local alignPosition = InstanceCreator("AlignPosition", "AlignPosition", parent, {
		Attachment0 = brainrotAssetAttachment,
		Attachment1 = hrpAttachment,

		MaxForce = math.huge,
		MaxVelocity = math.huge,
		Responsiveness = 200,
		RigidityEnabled = true,

		Enabled = true,
	}) :: AlignPosition

	local alignOrientation = InstanceCreator("AlignOrientation", "AlignOrientation", parent, {
		Attachment0 = brainrotAssetAttachment,
		Attachment1 = hrpAttachment,

		MaxTorque = math.huge,
		MaxAngularVelocity = math.huge,
		Responsiveness = 200,
		RigidityEnabled = true,

		Enabled = true,
	}) :: AlignOrientation

	return alignPosition, alignOrientation
end

local function clearModelVelocity(model: Model)
	assert(typeof(model) == "Instance" and model:IsA("Model"), "model arg must be a Model")

	for _, descendant in pairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function createTeleportSnapConnection(
	brainrotAsset: Model,
	hrpAttachment: Attachment,
	brainrotAssetAttachment: Attachment
): RBXScriptConnection
	assert(typeof(brainrotAsset) == "Instance" and brainrotAsset:IsA("Model"), "brainrotAsset arg must be a Model")
	assert(
		typeof(hrpAttachment) == "Instance" and hrpAttachment:IsA("Attachment"),
		"hrpAttachment arg must be an Attachment"
	)
	assert(
		typeof(brainrotAssetAttachment) == "Instance" and brainrotAssetAttachment:IsA("Attachment"),
		"brainrotAssetAttachment arg must be an Attachment"
	)

	local snapDistance = 8

	return RunService.RenderStepped:Connect(function()
		if not brainrotAsset.Parent or not hrpAttachment.Parent or not brainrotAssetAttachment.Parent then
			return
		end

		local distance = (brainrotAssetAttachment.WorldPosition - hrpAttachment.WorldPosition).Magnitude
		if distance < snapDistance then
			return
		end

		pivotModelSoAttachmentMatches(brainrotAsset, brainrotAssetAttachment, hrpAttachment.WorldCFrame)
		clearModelVelocity(brainrotAsset)
	end)
end

-->
local BrainrotTool = {
	StandController = knit.GetController("StandController"),
	AnimationController = knit.GetController("AnimationController"),

	TempInstances = {},
	TempConnections = {},
	BrainrotAsset = nil,
}

-- Private Methods
function BrainrotTool:equip(toolName: string)
	assert(typeof(toolName) == "string", "toolName arg must be a string")

	-- Clear any previous carry state just in case Equipped fires weirdly.
	self:unequip()

	local brainrotName = brainrotHandler.GetBrainrotNameFromReferenceId(toolName)
	local mutation = brainrotHandler.GetMutationFromBrainrotReferenceId(toolName)

	self.BrainrotAsset = getBrainrotAsset(brainrotName, mutation)

	CollisionHandler.ToggleCollisionProperties(self.BrainrotAsset, {
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Anchored = false,
		Massless = true,
	}, {})

	self.AnimationController:play("FrontHold")

	local hrpAttachment, brainrotAssetAttachment = createAttachments(self.BrainrotAsset)
	if not hrpAttachment or not brainrotAssetAttachment then
		self:unequip()
		return
	end

	table.insert(self.TempInstances, hrpAttachment)
	table.insert(self.TempInstances, brainrotAssetAttachment)

	local mainMeshPart = getMainMeshPart(self.BrainrotAsset)
	if not mainMeshPart then
		self:unequip()
		return
	end

	-- Important:
	-- Position the model BEFORE parenting it to workspace.
	-- This prevents it from appearing at its default clone position for a frame.
	pivotModelSoAttachmentMatches(self.BrainrotAsset, brainrotAssetAttachment, hrpAttachment.WorldCFrame)

	self.BrainrotAsset.Parent = workspace

	local alignPosition, alignOrientation = createAlignInstances(hrpAttachment, brainrotAssetAttachment, mainMeshPart)

	table.insert(self.TempInstances, alignPosition)
	table.insert(self.TempInstances, alignOrientation)

	local teleportSnapConnection =
		createTeleportSnapConnection(self.BrainrotAsset, hrpAttachment, brainrotAssetAttachment)
	table.insert(self.TempConnections, teleportSnapConnection)
end

function BrainrotTool:unequip()
	for _, connection: RBXScriptConnection in pairs(self.TempConnections) do
		connection:Disconnect()
	end

	table.clear(self.TempConnections)

	for _, instance in pairs(self.TempInstances) do
		if instance and instance.Parent then
			instance:Destroy()
		end
	end

	table.clear(self.TempInstances)

	if self.BrainrotAsset then
		self.BrainrotAsset:Destroy()
		self.BrainrotAsset = nil
	end

	self.AnimationController:stop("FrontHold")
end

-- Public Methods
function BrainrotTool:Bind(tool: Tool)
	local connections = {}

	table.insert(
		connections,
		tool.Equipped:Connect(function()
			self.StandController:ToggleProximityPromptVisibility(true)
			self:equip(tool.Name)
		end)
	)

	table.insert(connections, tool.Activated:Connect(function() end))

	table.insert(
		connections,
		tool.Unequipped:Connect(function()
			self.StandController:ToggleProximityPromptVisibility(false)
			self:unequip()
		end)
	)

	return connections
end

function BrainrotTool:Disconnect(tool: Tool)
	self.StandController:ToggleProximityPromptVisibility(false)
	self:unequip()
end

return BrainrotTool
