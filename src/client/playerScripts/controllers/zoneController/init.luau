-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local ZoneController = knit.CreateController({
	Name = "ZoneController",
})

-- Private Methods
function ZoneController:listenToZoneService()
	self.ZoneService.EnteredZone:Connect(function(payload: { Asset: any, ZoneType: string, LastZoneType: string })
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
