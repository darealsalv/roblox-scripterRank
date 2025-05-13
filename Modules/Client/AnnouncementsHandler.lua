local m = {}

local ts = game:GetService("TweenService")
local twInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

--[[Displays an announcement around the provided info.

<strong>announcer:</strong> The player that sent the announcement.
<strong>announcement:</strong> The announcement that the player sent.
<strong>announcementDisplayTime:</strong> The amount of time in seconds that the announcement will be displayed on screen.]]
function m:DisplayAnnouncement(announcerDisplay: string, announcer: number, announcement: string, announcementDisplayTime: number)
	local announcementsFrame = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("AdminGui"):WaitForChild("Announcements")
	
	local tweensAppear = {}
	local tweensDisappear = {}
	
	local tweenAppearBg = ts:Create(announcementsFrame:WaitForChild("Background"), twInfo, {BackgroundTransparency = 0.5})
	table.insert(tweensAppear, tweenAppearBg)
	local tweenDisappearBg = ts:Create(announcementsFrame.Background, twInfo, {BackgroundTransparency = 1})	
	table.insert(tweensDisappear, tweenDisappearBg)

	
	for i, inst in announcementsFrame:WaitForChild("NameZone"):GetDescendants() do
		if inst:IsA("TextLabel") then
			table.insert(tweensAppear, ts:Create(inst, twInfo, {TextTransparency = 0}))
			table.insert(tweensDisappear, ts:Create(inst, twInfo, {TextTransparency = 1}))
		elseif inst:IsA("ImageLabel") then
			table.insert(tweensAppear, ts:Create(inst, twInfo, {ImageTransparency = 0}))
			table.insert(tweensDisappear, ts:Create(inst, twInfo, {ImageTransparency = 1}))
			table.insert(tweensAppear, ts:Create(inst, twInfo, {BackgroundTransparency = 0}))
			table.insert(tweensDisappear, ts:Create(inst, twInfo, {BackgroundTransparency = 1}))
		elseif inst:IsA("UIStroke") then
			table.insert(tweensAppear, ts:Create(inst, twInfo, {Transparency = 0}))
			table.insert(tweensDisappear, ts:Create(inst, twInfo, {Transparency = 1}))
		end
	end
	
	announcementsFrame.NameZone:WaitForChild("Announcement").Text = announcement
	announcementsFrame.NameZone:WaitForChild("AnnouncerName").Text = "Announcement from: "..announcerDisplay.." (@"..game:GetService("Players"):GetNameFromUserIdAsync(announcer)..")!"
	announcementsFrame.NameZone:WaitForChild("AnnouncerAvatar").Image = game:GetService("Players"):GetUserThumbnailAsync(announcer, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	
	for i, tween in tweensAppear do
		tween:Play()
	end
	
	for i, tween in tweensAppear do
		tween:Destroy()
	end
	
	task.wait(announcementDisplayTime)
	
	for i, tween in tweensDisappear do
		tween:Play()
	end
	
	for i, tween in tweensDisappear do
		tween:Destroy()
	end
	
	return
end

return m
  
