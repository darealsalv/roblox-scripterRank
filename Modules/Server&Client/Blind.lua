local m = {}

m.BlindTypes = {
	["DarkScreen"] = "dark",
	["BlurScreen"] = "blur",
}

if game:GetService("RunService"):IsServer() then
	return m
end

local assetsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Dar's Admin - Assets", 30)
local eventsFolder = assetsFolder:WaitForChild("Events")

local playersService = game:GetService("Players")
local player = playersService.LocalPlayer

local adminPanelGui = player.PlayerGui:WaitForChild("AdminGui")

local frame = adminPanelGui:WaitForChild("BlindnessFrame")

local ts = game:GetService("TweenService")
local twInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
local tweenAppearBlindFrame = ts:Create(frame, twInfo, {BackgroundTransparency = 0})
local tweenDisappearBlindFrame = ts:Create(frame, twInfo, {BackgroundTransparency = 1})

local blinded = false

local function Blur(duration: number)
	if not duration or typeof(duration) ~= "number" then
		duration = 10
	end
	
	local blur
	
	for i, inst in game:GetService("Lighting"):GetDescendants() do
		if inst:IsA("BlurEffect") and inst:HasTag("Dar's Admin") then
			blur = inst
			break
		end
	end
	
	if not blur then
		blur = Instance.new("BlurEffect", game:GetService("Lighting"))
		blur.Size = 0
		blur.Enabled = false
		blur:AddTag("Dar's Admin")
	end
	
	local tweenBlurOn = ts:Create(blur, twInfo, {Size = 56})
	blur.Size = 0
	blur.Enabled = true
	tweenBlurOn:Play()
	task.wait(duration)
	
	if tweenBlurOn.PlaybackState ~= Enum.PlaybackState.Completed then

		if tweenBlurOn.PlaybackState ~= Enum.PlaybackState.Cancelled and tweenBlurOn.PlaybackState ~= Enum.PlaybackState.Paused then
			tweenBlurOn.Completed:Wait()
		end

	end
	
	local tweenBlurOff = ts:Create(blur, twInfo, {Size = 0})
	tweenBlurOff:Play()
	tweenBlurOff.Completed:Wait()
	
	tweenBlurOn:Destroy()
	tweenBlurOff:Destroy()
	
	return
end

local function Dark(duration: number)
	if not duration or typeof(duration) ~= "number" then
		duration = 10
	end
	
	tweenAppearBlindFrame:Play()
	tweenAppearBlindFrame.Completed:Wait()
	task.wait(duration)
	
	if tweenAppearBlindFrame.PlaybackState ~= Enum.PlaybackState.Completed then

		if tweenAppearBlindFrame.PlaybackState ~= Enum.PlaybackState.Cancelled and tweenAppearBlindFrame.PlaybackState ~= Enum.PlaybackState.Paused then
			tweenAppearBlindFrame.Completed:Wait()
		end

	end
	
	tweenDisappearBlindFrame:Play()
	tweenDisappearBlindFrame.Completed:Wait()
	
	return
end

function m:BlindPlayer(blurType: string, blindDuration: number)
	if blinded then
		return false, "Player is already blinded."
	end
	
	blinded = true
	
	if blurType == m.BlindTypes.DarkScreen then
		Dark(blindDuration)
	elseif blurType == m.BlindTypes.BlurScreen then
		Blur(blindDuration)
	end
	
	blinded = false
	
	return
end

return m
