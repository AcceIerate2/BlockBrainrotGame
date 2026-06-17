-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Constants
local Plots = workspace.src.Plots
local PlotAssets = ReplicatedStorage.Assets.PlotAssets
local ExtraFloorAsset = PlotAssets.ExtraFloor
local StandAsset = PlotAssets.StandTemplate

-- Types
type PlotState = {
	Taken: boolean,
	Owner: Player,
	Asset: any,
}

-- Helper Functions
local function isPlayer(player: Player): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local PlotService = knit.CreateService({
	Name = "PlotService",
	PlotStates = {},
	Client = {
		Signals = {},
	},
})

-- Client Exposed Methods
function PlotService.Client:GetPlotAsset(player: Player)
	return self.Server:GetPlotStateFromPlayer(player).Asset
end

-- Private Methods
function PlotService:preloadPlots()
	for _, plotAsset in pairs(Plots:GetChildren()) do
		if plotAsset:HasTag("ExcludedPlot") then
			continue
		end

		self.PlotStates[plotAsset] = {
			Taken = false,
			Owner = nil,
			Asset = plotAsset,
		}
	end
end

function PlotService:getAvailablePlot(): PlotState
	local plotStateToReturn
	for plotAsset, plotState: PlotState in pairs(self.PlotStates) do
		if not plotState.Taken then
			plotStateToReturn = plotState
			break
		end
	end
	return plotStateToReturn
end

function PlotService:syncPlot(player: Player, plotState: PlotState): { () -> () }
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(plotState) == "table", "plotState arg must be a table")

	local plotAsset = plotState.Asset
	local callbackFunctions = {}

	-- Load Overhead UI
	-- plotAsset.OverheadUI.UI.Multiplier.Text = `Multi: 1x`
	--[[plotAsset.OverheadUI.UI:FindFirstChild("Name").Text = `{player.DisplayName}`
	plotAsset.OverheadUI.UI.Avatar.Image = self.DataService:GetValue(player, "AvatarHeadshotAssetId") or "rbxassetid://"
	plotAsset.OverheadUI.UI.Enabled = true

	table.insert(callbackFunctions, function()
		-- plotAsset.OverheadUI.UI.Multiplier.Text = "N/A"
		plotAsset.OverheadUI.UI:FindFirstChild("Name").Text = "Empty"
		plotAsset.OverheadUI.UI.Avatar.Image = ""
		plotAsset.OverheadUI.UI.Enabled = false
	end)]]

	-- Load Floors
	local extraFloorAssets = {}
	local extraPlotFloors = self.DataService:GetValue(player, "ExtraPlotFloors")
	for i = 1, extraPlotFloors do
		table.insert(extraFloorAssets, self:AddFloor(player))
	end

	table.insert(callbackFunctions, function()
		for _, extraFloorAsset in pairs(extraFloorAssets) do
			extraFloorAsset:Destroy()
		end
	end)

	-- Load Stands
	local extraStandAssets = {}
	local extraPlotStands = self.DataService:GetValue(player, "ExtraPlotStands")
	for i = 1, extraPlotStands + 8 do
		table.insert(extraStandAssets, self:AddStand(player))
	end

	table.insert(callbackFunctions, function()
		for _, extraStandAsset in pairs(extraStandAssets) do
			self.StandService
				:DisconnectStand(player, extraStandAsset)
				:andThen(function()
					extraStandAsset:Destroy()
				end)
				:catch(warn)
		end
	end)

	return callbackFunctions
end

-- Public Methods
function PlotService:AddStand(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")

	local playerFloors = self.DataService:GetValue(player, "ExtraPlotFloors") + 1
	local extraPlotStandsVO = self.DataService:GetValueObject(player, "ExtraPlotStands")

	local plotState = self:GetPlotStateFromPlayer(player) :: PlotState
	local standFolder = plotState.Asset.Stands

	local highestStandNumber = 0
	for _, standAsset in ipairs(standFolder:GetChildren()) do
		local standNumber = tonumber(standAsset.Name:match("^Stand_(%d+)$"))
		if standNumber and standNumber > highestStandNumber then
			highestStandNumber = standNumber
		end
	end

	local newStandIndex = highestStandNumber + 1
	local floorIndex = math.ceil(newStandIndex / 8)

	if floorIndex > playerFloors then
		warn("Could not place new stand - not enough floors")
		return
	end

	local floorAsset = plotState.Asset.Floors:FindFirstChild(`Floor_{floorIndex}`)
	if not floorAsset then
		warn(`Floor asset number [{floorIndex}] does not exist?`)
		return
	end

	local standPositions = floorAsset:FindFirstChild("StandPositions")
	if not standPositions then
		warn(`Floor_{floorIndex} has no StandPositions folder`)
		return
	end

	local standPositionOnFloor = ((newStandIndex - 1) % 8) + 1
	local spawnPoint = standPositions:FindFirstChild(tostring(standPositionOnFloor))

	if not spawnPoint then
		warn(`Could not get spawnPoint named: {standPositionOnFloor}`)
		return
	end

	local newStand = StandAsset:Clone()
	newStand.Name = `Stand_{newStandIndex}`
	newStand:PivotTo(spawnPoint:GetPivot())
	newStand.Parent = standFolder

	extraPlotStandsVO:Set(extraPlotStandsVO:Get() + 1)
	self.StandService:ConnectStand(player, newStand)

	return newStand
end

function PlotService:AddFloor(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local extraPlotFloorsVO = self.DataService:GetValueObject(player, "ExtraPlotFloors")
	local playerFloors = extraPlotFloorsVO:Get()

	local plotState = self:GetPlotStateFromPlayer(player) :: PlotState
	local lastFloorAsset, highestFloorNumber = (function(): (Model?, number)
		local floorsFolder = plotState.Asset.Floors

		local highestFloorNumber = 0
		local lastFloorAsset: Model? = nil

		for _, floorAsset in ipairs(floorsFolder:GetChildren()) do
			local floorNumber = tonumber(floorAsset.Name:match("^Floor_(%d+)$"))
			if floorNumber and floorNumber > highestFloorNumber then
				highestFloorNumber = floorNumber
				lastFloorAsset = floorAsset :: Model
			end
		end

		return lastFloorAsset, highestFloorNumber
	end)()

	local newFloorAsset = ExtraFloorAsset:Clone()
	newFloorAsset.Name = `Floor_{highestFloorNumber + 1}`

	local pivot
	if highestFloorNumber == 1 then
		pivot = lastFloorAsset:GetPivot() + Vector3.new(0, newFloorAsset:GetExtentsSize().Y / 2 - 0.625, 0)
		newFloorAsset.Windows.Front.Transparency = 1
		newFloorAsset.Windows.Front.CanCollide = false
		newFloorAsset.Windows.Front.CanQuery = false
	else
		pivot = lastFloorAsset:GetPivot() + Vector3.new(0, newFloorAsset:GetExtentsSize().Y - 0.8, 0)
	end

	newFloorAsset:PivotTo(pivot)
	newFloorAsset.Parent = plotState.Asset.Floors

	extraPlotFloorsVO:Set(playerFloors + 1)
	return newFloorAsset
end

function PlotService:GetPlotStateFromPlayer(player: Player): PlotState
	assert(isPlayer(player), "player arg must be a Player Instance")
	local plotStateToReturn
	for plotAsset, plotState: PlotState in pairs(self.PlotStates) do
		if plotState.Owner == player then
			plotStateToReturn = plotState
			break
		end
	end
	return plotStateToReturn
end

function PlotService:ConnectPlot(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local plotState = self:getAvailablePlot() :: PlotState
	if not plotState then
		player:Kick("Couldn't find an available Plot - Pls rejoin to fix it")
		warn(`Couldn't find an available Plot`)
		return
	end

	plotState.Taken = true
	plotState.Owner = player
	plotState.Asset.Owner.Value = player

	return {
		Function = self.DisconnectPlot,
		Args = {
			self,
			player,
			self:syncPlot(player, plotState),
		},
	}
end

function PlotService:DisconnectPlot(player: Player, resetFunctions: { () -> () })
	assert(isPlayer(player), "player arg must be a Player Instance")
	local plotState = self:GetPlotStateFromPlayer(player) :: PlotState
	if not plotState then
		warn("Leaving Player Did not have a Plot assigned on leave?")
		return
	end

	if typeof(resetFunctions) == "table" then
		for _, functionToRun in pairs(resetFunctions) do
			if typeof(functionToRun) == "function" then
				functionToRun()
			end
		end
	end

	plotState.Taken = false
	plotState.Owner = nil
	plotState.Asset.Owner.Value = nil
end

-- LifeCycle
function PlotService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.StandService = knit.GetService("StandService")
end

function PlotService:KnitStart()
	self:preloadPlots()
end

return PlotService
