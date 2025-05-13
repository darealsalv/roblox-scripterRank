local m = {}

local ts = game:GetService("TweenService")
local twInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local dependenciesFolder = game:GetService("ReplicatedStorage"):WaitForChild("Dar's Admin - Assets"):WaitForChild("Dependencies")
local notificationSound = dependenciesFolder:WaitForChild("Notification")
local notificationSample = dependenciesFolder:WaitForChild("NotificationSample")
local invisibleNotification = dependenciesFolder:WaitForChild("InvisibleNotification")
local playerNotificationZone = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("AdminGui"):WaitForChild("NotificationsZone")

local function CreateNotificationTweens(notificationBox: Frame)
	local tweens = {}
	
	local tweenAppear = ts:Create(notificationBox, twInfo, {Position = playerNotificationZone:WaitForChild("NotificationAppearPosition").Position})
	table.insert(tweens, tweenAppear)
	
	return tweens
end

local function AdjustNotification(notificationBox: Frame, soundToPlay: Sound)
	local newEmptyBox = invisibleNotification:Clone()
	newEmptyBox.Parent = playerNotificationZone:WaitForChild("NotificationsList")
	newEmptyBox.LayoutOrder = notificationBox.LayoutOrder
	
	local tweensTable = CreateNotificationTweens(notificationBox)
	tweensTable[1]:Play()
	soundToPlay:Play()
	tweensTable[1].Completed:Wait()
	
	newEmptyBox:Destroy()
	
	if notificationBox.Parent then
		notificationBox.Parent = playerNotificationZone:WaitForChild("NotificationsList")
	end
	
	return
end

function m:NewNotification(title: string, info: string, duration: number, customSound: Sound, color: Color3)
	if not customSound then
		customSound = notificationSound
	end
	
	if not duration then
		duration = 15
	end
	
	local newNotification = notificationSample:Clone()
	
	if color then
		for i, sideColor in newNotification:GetChildren() do
			
			if sideColor.Name == "SideColor" then
				sideColor.BackgroundColor3 = color
			end
			
		end
	end
	
	newNotification.LayoutOrder = #playerNotificationZone:WaitForChild("NotificationsList"):GetChildren()
	newNotification.Position = playerNotificationZone:WaitForChild("NotificationInvisiblePosition").Position
	newNotification.Name = title
	newNotification:WaitForChild("Title").Text = title
	newNotification:WaitForChild("Information").Text = info
	newNotification.Parent = playerNotificationZone
	
	task.spawn(AdjustNotification, newNotification, customSound)
	
	local durationDisplay = newNotification:WaitForChild("DurationDisplay")
	
	for i = 1, duration do
		if newNotification then
			durationDisplay.Text = "("..duration - i..")"
			task.wait(1)
		end
	end
	
	if newNotification then
		newNotification:Destroy()
	end
	
	return
end

return m
