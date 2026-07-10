-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

local AudioController = knit.CreateController({
	Name = "AudioController",
	SoundCache = {},
})

function AudioController:getSound(audioName: string): Sound?
	local cachedSound = self.SoundCache[audioName]
	if cachedSound then
		return cachedSound
	end

	local sound = SoundService:FindFirstChild(audioName, true)
	if sound and sound:IsA("Sound") then
		self.SoundCache[audioName] = sound
		return sound
	end

	return nil
end

function AudioController:PlayAudio(audioName: string, overlay: boolean?, parent: Instance?)
	local templateSound = self:getSound(audioName)
	if not templateSound then
		warn(`Sound "{audioName}" not found`)
		return
	end

	if overlay then
		local sound = templateSound:Clone()
		sound.Parent = parent or SoundService
		sound.TimePosition = 0
		sound:Play()

		sound.Ended:Once(function()
			sound:Destroy()
		end)
	else
		templateSound.TimePosition = 0
		templateSound:Play()
	end
end

function AudioController:KnitStart()
	local sounds = {}

	for _, descendant in ipairs(SoundService:GetDescendants()) do
		if descendant:IsA("Sound") then
			self.SoundCache[descendant.Name] = descendant
			table.insert(sounds, descendant)
		end
	end

	task.spawn(function()
		local success, err = pcall(function()
			ContentProvider:PreloadAsync(sounds)
		end)

		if not success then
			warn("[AudioController] Failed to preload sounds:", err)
		end
	end)
end

return AudioController
