-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local CarryController = knit.CreateController({
	Name = "CarryController",
})

-- Private Methods
function CarryController:added(amount: number)
	assert(typeof(amount) == "number", "amount arg must be a number")
	if amount == 1 then
		self.HudController:ToggleDropButtonVisibility(true)
		self.AnimationController:play("Hold", false, {
			Looped = true,
		})
	end
	self.AnimationController:play("Stack")
end

function CarryController:removed(amount: number)
	assert(typeof(amount) == "number", "amount arg must be a number")
	if amount < 1 then
		self.HudController:ToggleDropButtonVisibility(false)
		self.AnimationController:stop("Hold")
	end
	self.AnimationController:play("Throw")
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
end

function CarryController:KnitStart()
	self:listenToService()
end

return CarryController
