-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Local Types
type Data = {
	Title: string,
	Message: string,
	Options: { Option1: string, Option2: string },
	Duration: number,
}

-->
local ConfirmationController = knit.CreateController({
	Name = "ConfirmationController",
	Signals = {
		SyncPanel = Signal.new(),
		SyncCountdown = Signal.new(),
	},
	RequestId = nil,
})

-- Public Methods
function ConfirmationController:OptionChosen(option: "Option1" | "Option2")
	local requestId = self.RequestId
	self.RequestId = nil

	if self.PanelController.ActivePanel == "Confirmation" then
		self.PanelController:togglePanel("Confirmation")
	end

	self.ConfirmationService
		:Respond(requestId, { Option1 = option == "Option1", Option2 = option == "Option2" })
		:andThen(function() end)
		:catch(warn)
end

function ConfirmationController:Prompt(requestId: string, otherConfig: Data)
	if self.RequestId then
		return
	end

	self.RequestId = requestId
	self.Signals.SyncPanel:Fire(otherConfig)

	self.PanelController:togglePanel("Confirmation")

	for i = 10, 1, -1 do
		if not self.RequestId or self.RequestId ~= requestId then
			break
		end

		self.Signals.SyncCountdown:Fire(i)
		task.wait(1)
	end

	if self.RequestId == requestId and self.PanelController.ActivePanel == "Confirmation" then
		self.PanelController:togglePanel("Confirmation")
		self.RequestId = nil
	end
end

-- LifeCycle
function ConfirmationController:KnitInit()
	self.ConfirmationService = knit.GetService("ConfirmationService")
	self.PanelController = knit.GetController("PanelController")
end

function ConfirmationController:KnitStart()
	self.ConfirmationService.Prompt:Connect(function(requestId: string, otherConfig: Data)
		self:Prompt(requestId, otherConfig)
	end)
end

return ConfirmationController
