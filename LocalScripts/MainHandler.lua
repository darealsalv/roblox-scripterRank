print("🛡️ [Dar's Admin] 🛡️ Running admin panel!")

local startTime = tick()

local assetsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Dar's Admin - Assets")
local topBarPlus = require(assetsFolder:WaitForChild("Dependencies"):WaitForChild("TopBarPlus"))
local iconsFolder = assetsFolder:WaitForChild("Dependencies"):WaitForChild("Icons")

local eventsFolder = assetsFolder:WaitForChild("Events")
local panelToggleBindable: BindableEvent = eventsFolder:WaitForChild("OnPanelAppear")

local clientModules = assetsFolder:WaitForChild("Modules"):WaitForChild("Client")
local serverAndClientModules = assetsFolder:WaitForChild("Modules"):WaitForChild("Server&Client")
local panelAnimationsModule = require(clientModules:WaitForChild("PanelAnimations"))
local blindModule = require(serverAndClientModules:WaitForChild("Blind"))

local function OnPanelToggle(toggled: boolean)
	panelToggleBindable:Fire(toggled)
	panelAnimationsModule:TogglePanel(toggled)
	return
end

local darsAdminIcon = topBarPlus.new()
darsAdminIcon:setImage(iconsFolder:WaitForChild("PanelIcon").Image)
darsAdminIcon:setImageScale(0.6)
darsAdminIcon:setCaption("Admin Panel")
darsAdminIcon.toggled:Connect(OnPanelToggle)

local dependenciesFolder = assetsFolder:WaitForChild("Dependencies")
local eventsFolder = assetsFolder:WaitForChild("Events")
local iconsFolder = dependenciesFolder:WaitForChild("Icons")

local panelToggleBindable: BindableEvent = eventsFolder:WaitForChild("OnPanelAppear")

local playersService = game:GetService("Players")
local player = playersService.LocalPlayer
local currentCamera = workspace.CurrentCamera

local adminPanelGui = player.PlayerGui:WaitForChild("AdminGui")
local panelBackground = adminPanelGui:WaitForChild("PanelZone"):WaitForChild("Background")
panelBackground.Position = UDim2.fromScale(0.5, -0.5)

local permsModule = require(clientModules.Parent:WaitForChild("Server&Client"):WaitForChild("Permissions"))
local panelAnimationsModule = require(clientModules:WaitForChild("PanelAnimations"))

---------------------------------------------------------------

local settingsLoad: BindableEvent = eventsFolder:WaitForChild("OnSettingsLoad")

local function OnConfigurationLoad(loadedSuccesfully: boolean)
	if loadedSuccesfully then
		warn("Loaded Admin Panel settings correctly in: "..tick() - startTime)
	else
		warn("Failed to load Admin Panel settings for: "..player.DisplayName.." (@"..player.Name..").")
	end
	
	permsModule.Values.LoadedConfiguration = true
	return
end

settingsLoad.Event:Connect(OnConfigurationLoad)

repeat task.wait() until permsModule.Values.LoadedConfiguration == true

local function DebugOutput(msg: string, typeOfDebug)
	if permsModule.Values.output then
		if not typeOfDebug then
			print(msg)
		else
			warn(msg)
		end
	end
end

local keywordsDebug = {
	ModChat = "[Debug - ModChat] ",
	CommandsPages = "[Debug - CommandsPages] ",
	Terminal = "[Debug - Terminal] ",
	CommandsHandler = "[Debug - ServerCommandsHandler] ",
	Notifications = "[Debug - NotificationsHandler] ",
}

---------------------------------------------------------------

local textChatService = game:GetService("TextChatService")
local players = game:GetService("Players")

local textChatService = game:GetService("TextChatService")
local players = game:GetService("Players")
local getPlayersWithPermissions: RemoteFunction = eventsFolder:WaitForChild("GetPlayersPerms")

local chatTags = {
	owner   = { emoji = "", color = "#FF0000", display = " 👑 Owner " },
	admin   = { emoji = "", color = "#00FF00", display = " 🛡️ Admin " },
	["mod+"] = { emoji = "", color = "#FFA500", display = " ⚡ Mod+ " },
	mod     = { emoji = "", color = "#FFFF00", display = " 🔧 Mod " },
	vip     = { emoji = "", color = "#00FFFF", display = " 💎 Vip " },
}

local function GetRoleForPlayer(player)
	for role, entries in getPlayersWithPermissions:InvokeServer() do
		
		if role ~= "player" then
			
			for _, entry in ipairs(entries) do
				
				if entry.Id and entry.Id == player.UserId then
					return role
				elseif entry.Name and entry.Name == player.Name then
					return role
				end
				
			end
			
		end
		
	end
	
	return nil
end

local function OnIncommingMessage(message: TextChatMessage)
	if player:WaitForChild("DarAdminChatTag").Value == false then return end
	
	local properties = Instance.new("TextChatMessageProperties")
	properties.Text = message.Text
	
	if message.TextSource then
		local player = players:GetPlayerByUserId(message.TextSource.UserId)
		
		if player then
			
			if not player:WaitForChild("DarAdminChatTag").Value then return end
			
			local role = GetRoleForPlayer(player)
			
			if role then
				local roleInfo = chatTags[role]
				
				if roleInfo then
					properties.PrefixText = string.format("<font color='%s'>%s[%s]</font> ", roleInfo.color, roleInfo.emoji, roleInfo.display) .. (message.PrefixText or "")
				else
					local formattedRole = role:sub(1, 1):upper() .. role:sub(2)
					properties.PrefixText = string.format("[%s] ", formattedRole) .. (message.PrefixText or "")
				end
			end
			
		end
		
	end

	return properties
end

textChatService.OnIncomingMessage = OnIncommingMessage

---------------------------------------------------------------

local modChatModule = require(assetsFolder:WaitForChild("Modules"):WaitForChild("Server&Client"):WaitForChild("Mod Chat Handler"))
local modMessageReceiveEvent: RemoteEvent = eventsFolder:WaitForChild("NewModMessage")

local function OnModMessage(filteredMessage: string, playerThatSentMessage: Player)
	DebugOutput(keywordsDebug.ModChat.."Received new Moderator message from: "..playerThatSentMessage.DisplayName.." (@"..playerThatSentMessage.Name..").")
	
	modChatModule:CreateNewMessage(filteredMessage, playerThatSentMessage)
	return
end

modMessageReceiveEvent.OnClientEvent:Connect(OnModMessage)

---------------------------------------------------------------

local reloadSectionBindable: BindableEvent = eventsFolder:WaitForChild("ReloadSection")

local function OnNextSection()
	local newSection = panelAnimationsModule:NextCommandSection()

	DebugOutput(keywordsDebug.CommandsPages.."Changing command section to: "..newSection)
	return
end

local function OnReturnSection()
	local newSection = panelAnimationsModule:ReturnCommandSection()

	DebugOutput(keywordsDebug.CommandsPages.."Changing command section to: "..newSection)
	return
end

local function OnSectionsReload()
	local newSection = panelAnimationsModule:ReturnCommandSection()
	local newSection = panelAnimationsModule:NextCommandSection()
	
	return
end

reloadSectionBindable.Event:Connect(OnSectionsReload)

panelBackground:WaitForChild("Commands"):WaitForChild("SectionChanger"):WaitForChild("RightArrow").MouseButton1Click:Connect(OnNextSection)
panelBackground:WaitForChild("Commands"):WaitForChild("SectionChanger"):WaitForChild("LeftArrow").MouseButton1Click:Connect(OnReturnSection)

----------------------------------------------------------
panelAnimationsModule:LoadPanelCommands()
----------------------------------------------------------

---------- Terminal Handler ----------

local UIS = game:GetService("UserInputService")
local lastMessages = {}
local currentMessage = nil
local typing = false

local terminalTextBox: TextBox = adminPanelGui:WaitForChild("Terminal"):WaitForChild("CommandInput")
local runCommandEvent: RemoteEvent = eventsFolder:WaitForChild("RunCommand")

local UIS = game:GetService("UserInputService")

local isOnPhone

if UIS.TouchEnabled and UIS.KeyboardEnabled == false then
	isOnPhone = true
	warn("PLAYER IS ON PHONE")
end

local function FocusLost(enterPressed)
	typing = false
	if enterPressed or UIS.GamepadEnabled or isOnPhone then
		local message = terminalTextBox.Text
		DebugOutput(keywordsDebug.Terminal.."Attempting to run command: "..string.lower(string.sub(terminalTextBox.Text, 1, (string.find(terminalTextBox.Text, " ") or #terminalTextBox.Text + 1) - 1)))
		runCommandEvent:FireServer(terminalTextBox.Text)
		terminalTextBox.Text = ""
		table.insert(lastMessages, message)
		
		if not UIS.GamepadEnabled and not isOnPhone then
			terminalTextBox:CaptureFocus()
		end
		task.wait()
		terminalTextBox.Text = ""
	end
	
	return
end

local function OnTyping()
	if table.find(lastMessages, terminalTextBox.Text) then
		currentMessage = terminalTextBox.Text
	else
		currentMessage = nil
	end
	
	return
end

local function Focused()
	typing = true
	return
end

local function InputBeganTerminal(input: InputObject)
	if not typing then return end
	
	if input.KeyCode == Enum.KeyCode.Up then
		if #lastMessages == 0 then return end
		
		if not currentMessage then
			currentMessage = lastMessages[#lastMessages]
		else
			local messageToDisplay = table.find(lastMessages, currentMessage)
			if not lastMessages[messageToDisplay - 1] then return end
			
			currentMessage = lastMessages[messageToDisplay - 1]
		end
		
		terminalTextBox.Text = currentMessage
		terminalTextBox.CursorPosition = #terminalTextBox.Text + 1
	elseif input.KeyCode == Enum.KeyCode.Down then
		if #lastMessages == 0 then return end
		
		if not currentMessage then
			currentMessage = lastMessages[#lastMessages]
		else
			local messageToDisplay = table.find(lastMessages, currentMessage)
			if not lastMessages[messageToDisplay + 1] then return end
			
			currentMessage = lastMessages[messageToDisplay + 1]
		end
		
		terminalTextBox.Text = currentMessage
		terminalTextBox.CursorPosition = #terminalTextBox.Text + 1
	end
	
	return
end

terminalTextBox.Focused:Connect(Focused)
terminalTextBox.Changed:Connect(OnTyping)
terminalTextBox.FocusLost:Connect(FocusLost)
UIS.InputBegan:Connect(InputBeganTerminal)

---------- Announcements Handler ----------

local queue = {}

local announcementEvent: RemoteEvent = eventsFolder:WaitForChild("Announcement")
local moduleAnnouncements = require(clientModules:WaitForChild("AnnouncementsHandler"))
local displayingAnnouncement = false

local function OnAnnouncementIncome(announcerDisplay: string, announcer: number, announcement: string, announcementDisplayTime: number)
	if displayingAnnouncement then
		table.insert(queue, {announcerDisplay, announcer, announcement, announcementDisplayTime})
		return
	end
	displayingAnnouncement = true
	
	moduleAnnouncements:DisplayAnnouncement(announcerDisplay, announcer, announcement, announcementDisplayTime)
	
	if #queue > 0 then
		repeat
			local nextAnnouncement = queue[1]
			table.remove(queue, 1)

			if nextAnnouncement then
				moduleAnnouncements:DisplayAnnouncement(nextAnnouncement[1], nextAnnouncement[2], nextAnnouncement[3], nextAnnouncement[4])
			end
		until #queue <= 0
	end
	
	displayingAnnouncement = false
	
	return
end

announcementEvent.OnClientEvent:Connect(OnAnnouncementIncome)

---------- Spectate Handler ----------

local spectateEvent = eventsFolder:WaitForChild("Spectate")

local function OnSpectate(spectate: boolean, playerToSpectate: Player)
	if spectate then
		local char = playerToSpectate.Character or playerToSpectate.CharacterAdded:Wait()
		local humanoid = char:WaitForChild("Humanoid")
		currentCamera.CameraSubject = humanoid
		
		DebugOutput(keywordsDebug.CommandsHandler.."Now spectating player: "..playerToSpectate.DisplayName.." (@"..playerToSpectate.Name..").")
	elseif not spectate then
		local char = player.Character or player.CharacterAdded:Wait()
		local humanoid = char:WaitForChild("Humanoid")
		
		currentCamera.CameraSubject = humanoid
		DebugOutput(keywordsDebug.CommandsHandler.."Cancelling spectating mode.")
	end
end

spectateEvent.OnClientEvent:Connect(OnSpectate)


---------- Command Logs Handler ----------

local commandLogsFrame = adminPanelGui:WaitForChild("CommandLogs")
local sampleLog = dependenciesFolder:WaitForChild("CommandLogSample")
local commandsLogsScrollFrame = commandLogsFrame:WaitForChild("LogsFrame"):WaitForChild("ScrollingFrame")
local errorMessageLogs = commandLogsFrame.LogsFrame:WaitForChild("PermissionError")
local logCommand: RemoteEvent = eventsFolder:WaitForChild("LogCommand")
local toggleCommandLogs: RemoteEvent = eventsFolder:WaitForChild("ToggleCommandLogs")
local closeButton = commandLogsFrame:WaitForChild("CloseButton")

local receivedLogs = 0

local function OnCommandLog(playerThatExecuted: Player, command: string, success: boolean, ranTime: string)
	local newLog = sampleLog:Clone()
	newLog:WaitForChild("ExecutedBy").Text = "Command executed by: "..playerThatExecuted.DisplayName.." (@"..playerThatExecuted.Name..")"
	newLog:WaitForChild("Command").Text = "Command: "..command
	newLog:WaitForChild("Success").Text = "Success: " .. if success then "Yes" else "No"
	newLog:WaitForChild("ExecutionTime").Text = "Executed at: "..ranTime
	
	newLog.LayoutOrder = receivedLogs * -1
	receivedLogs += 1
	
	newLog.Parent = commandsLogsScrollFrame
	return
end

local function ToggleCommandLogs()
	if eventsFolder:WaitForChild("GetPlayerRank"):InvokeServer(player.UserId) ~= "player" then
		errorMessageLogs.Visible = false
		commandsLogsScrollFrame.Visible = true
	end
	
	if commandLogsFrame.Visible then
		commandLogsFrame.Visible = false
	else
		commandLogsFrame.Visible = true
	end
	
	return
end

logCommand.OnClientEvent:Connect(OnCommandLog)
toggleCommandLogs.OnClientEvent:Connect(ToggleCommandLogs)
closeButton.MouseButton1Click:Connect(ToggleCommandLogs)

---------- Notifications Handler ----------

local rankChange: RemoteEvent = eventsFolder:WaitForChild("RankChange")
local errorCommand: RemoteEvent = eventsFolder:WaitForChild("CommandError")
local notification: RemoteEvent = eventsFolder:WaitForChild("Notification")
local notificationsModule = require(clientModules:WaitForChild("Notifications"))
local endNotification: BindableEvent = eventsFolder:WaitForChild("EndNotification")

local function OnRankChange(newRank: string, disableDefaultText: boolean)
	DebugOutput(keywordsDebug.Notifications..if disableDefaultText then newRank else "Your rank has been updated to: "..newRank)
	notificationsModule:NewNotification("Your Rank has been updated!", if disableDefaultText then newRank else "Your rank has been updated to: "..newRank , 15, nil, Color3.fromRGB(255, 225, 135))
	return
end

local function EndNotification(notificationTitle)
	local playerNotificationZone = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("AdminGui"):WaitForChild("NotificationsZone"):WaitForChild("NotificationsList")
	local notification = playerNotificationZone:FindFirstChild(notificationTitle)
	
	if notification then
		notification:Destroy()
	end
	
	return
end

local function OnCommandError(errorMessage: string)
	DebugOutput(keywordsDebug.Notifications.."Received error notification: "..errorMessage, true)
	notificationsModule:NewNotification("Command Error!", errorMessage, 10, dependenciesFolder:WaitForChild("Error"), Color3.fromRGB(255, 116, 118))
end

local function OnNotification(title: string, info: string, duration: number, sound: Sound)
	DebugOutput(keywordsDebug.Notifications.."Received new notification: "..info)
	notificationsModule:NewNotification(title, info, duration, sound)
	return
end

rankChange.OnClientEvent:Connect(OnRankChange)
notification.OnClientEvent:Connect(OnNotification)
errorCommand.OnClientEvent:Connect(OnCommandError)
endNotification.Event:Connect(EndNotification)

---------- Blidness handler ----------

---- Blindness Duration



---- Blindness Main

local blindnessEvent = eventsFolder:WaitForChild("Blind")

local function OnBlind(blindType, duration)
	blindModule:BlindPlayer(string.lower(blindType), duration)
	return
end

blindnessEvent.OnClientEvent:Connect(OnBlind)
