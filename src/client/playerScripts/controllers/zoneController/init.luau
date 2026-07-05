-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local ZoneController = knit.CreateController({
	Name = "ZoneController",
	Zone = nil,
	ZoneChanged = Signal.new(),
})

-- Private Methods
function ZoneController:updateZone(newZone: string)
	self.Zone = newZone
	self.ZoneChanged:Fire(newZone)
end

function ZoneController:listenToZoneService()
	self.ZoneService.EnteredZone:Connect(function(payload: { Asset: any, ZoneType: string, LastZoneType: string })
		self:updateZone(payload.ZoneType)
		local controller = knit.GetController(`{payload.ZoneType}Controller`)
		if controller and typeof(controller.Connect) == "function" then
			controller:Connect(payload)
		end
	end)

	self.ZoneService.LeftZone:Connect(function(payload: { Asset: any, ZoneType: string, LastZoneType: string })
		local controller = knit.GetController(`{payload.ZoneType}Controller`)
		if controller and typeof(controller.Disconnect) == "function" then
			controller:Disconnect(payload)
		end
	end)
end

-- LifeCycle
function ZoneController:KnitInit()
	self.ZoneService = knit.GetService("ZoneService")
end

function ZoneController:KnitStart()
	self:listenToZoneService()
end

return ZoneController
