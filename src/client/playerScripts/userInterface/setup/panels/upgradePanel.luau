-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local utility = require(ReplicatedStorage.src.UIUtility.utility)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local upgradeConfig = require(ReplicatedStorage.src.GameConfiguration.General.upgradeConfig)

-- Types
type ControllerPayload = {
	UpgradeType: string,
	Level: number,
	Value: number,
	CostToUpgrade: number,
}

--> Private Methods Only
local UpgradePanel = {}

function UpgradePanel:getUpgradeCard(upgradeType: string)
	return self.UpgradeCardsContainer:WaitForChild(upgradeType)
end

function UpgradePanel:upgradePanelDetails(payload: ControllerPayload)
	local card = self:getUpgradeCard(payload.UpgradeType)
	card:WaitForChild("Details"):WaitForChild("Content"):WaitForChild("TextLabel").Text =
		`{NumberShortner(payload.Value)}`

	card:WaitForChild("Buttons"):WaitForChild("CashUpgrade1"):WaitForChild("Cost").Text =
		`${NumberShortner(payload.CostToUpgrade)}`

	if payload.UpgradeType ~= "Carry" then
		card:WaitForChild("Buttons"):WaitForChild("CashUpgrade10"):WaitForChild("Cost").Text =
			`${NumberShortner(payload.CostToUpgrade * 10)}`
	end
end

function UpgradePanel:listenToUpgradeController()
	self.UpgradeController = knit.GetController("UpgradeController")
	self.UpgradeController.UpdateUpgradeDetails:Connect(function(payload: ControllerPayload)
		self:upgradePanelDetails(payload)
	end)
end

function UpgradePanel:listenToDataController()
	self.DataController = knit.GetController("DataController")
	for upgradeType: string, _ in pairs(upgradeConfig.Upgrades) do
		self.DataController
			:GetValueChangedSignal(upgradeType == "Carry" and "MaxHold" or upgradeType)
			:Connect(function(updatedData: { Level: number, Value: number })
				self:upgradePanelDetails({
					UpgradeType = upgradeType,
					Level = updatedData.Level,
					Value = updatedData.Value,
					CostToUpgrade = self.UpgradeController:GetCostToUpgrade(upgradeType),
				})
			end)
	end
end

function UpgradePanel:Init(player: Player)
	self.Panel = utility.getPanel("Upgrades")
	self.UpgradeCardsContainer = self.Panel:WaitForChild("Body")
	self:listenToUpgradeController()
	self:listenToDataController()
end

return UpgradePanel
