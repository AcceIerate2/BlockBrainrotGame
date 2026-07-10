-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Constants
local Player = Players.LocalPlayer
local CarryGui = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI"):WaitForChild("CarryGui")

-->
local CarryController = knit.CreateController({
	Name = "CarryController",
	Connections = {},
	CarryGui = nil,
	Amount = 0,
})

-- Private Methods
function CarryController:connectHoldLabel()
	if not Player.Character then
		return
	end

	local hrp = Player.Character:WaitForChild("HumanoidRootPart", 3)
	if not hrp then
		return
	end

	self:disconnectHoldLabel()
	self.CarryGui = CarryGui:Clone()
	self.CarryGui:WaitForChild("TextLabel").Text = `{self.Amount}/{self.DataController:GetValue("MaxHold").Value}`
	self.CarryGui.Enabled = true
	self.CarryGui.Parent = hrp

	table.insert(
		self.Connections,
		self.DataController:GetValueChangedSignal("MaxHold"):Connect(function(newData)
			self.CarryGui:WaitForChild("TextLabel").Text = `{self.Amount}/{newData.Value}`
		end)
	)
end

function CarryController:syncHoldLabel()
	if not self.CarryGui then
		return
	end
	self.CarryGui:WaitForChild("TextLabel").Text = `{self.Amount}/{self.DataController:GetValue("MaxHold").Value}`
end

function CarryController:disconnectHoldLabel()
	-- Disconnect Connections
	for _, connection: RBXScriptConnection in pairs(self.Connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	table.clear(self.Connections)

	-- Destroy CarryGui
	if typeof(self.CarryGui) == "Instance" then
		self.CarryGui:Destroy()
		self.CarryGui = nil
	end
end

function CarryController:added(amount: number)
	assert(typeof(amount) == "number", "amount arg must be a number")
	self.Amount = amount

	if amount == 1 then
		self.HudController:ToggleDropButtonVisibility(true)
		self.AnimationController:play("Hold", false, {
			Looped = true,
		})
		self:connectHoldLabel()
	end

	self:syncHoldLabel()
	self.AnimationController:play("Stack")
	self.AudioController:PlayAudio("Stack", true, SoundService)
end

function CarryController:removed(amount: number)
	assert(typeof(amount) == "number", "amount arg must be a number")
	self.Amount = amount
	self:syncHoldLabel()

	if amount < 1 then
		self.HudController:ToggleDropButtonVisibility(false)
		self.AnimationController:stop("Hold")
		self:disconnectHoldLabel()
	end

	self.AnimationController:play("Throw")
	self.AudioController:PlayAudio("Drop", true, SoundService)
end

function CarryController:listenToService()
	self.CarryService.BrainrotAdded:Connect(function(payload: { Amount: number })
		self:added(payload.Amount)
	end)

	self.CarryService.BrainrotRemoved:Connect(function(payload: { Amount: number })
		self:removed(payload.Amount)
	end)
end

-- Public Methods
function CarryController:RequestToDrop()
	self.CarryService
		:Drop(true)
		:andThen(function(response)
			warn(response)
		end)
		:catch(warn)
end

-- LifeCycle
function CarryController:KnitInit()
	self.CarryService = knit.GetService("CarryService")
	self.HudController = knit.GetController("HudController")
	self.AnimationController = knit.GetController("AnimationController")
	self.DataController = knit.GetController("DataController")
	self.AudioController = knit.GetController("AudioController")
end

function CarryController:KnitStart()
	self:listenToService()
end

return CarryController
