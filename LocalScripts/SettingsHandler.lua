local player = game:GetService("Players").LocalPlayer
local scrollFrame = player.PlayerGui:WaitForChild("AdminGui"):WaitForChild("PanelZone"):WaitForChild("Background"):WaitForChild("Settings"):WaitForChild("ScrollingFrame")
local buttons = {
	SaveButton = scrollFrame:WaitForChild("Save Settings"):WaitForChild("SaveButton"),
	DebugModeButton = scrollFrame:WaitForChild("Debug Mode"):WaitForChild("Button"),
	ChatTagButton = scrollFrame:WaitForChild("Chat Tag"):WaitForChild("Button")
}

local repStorage = game:GetService("ReplicatedStorage")
local events = repStorage:WaitForChild("Dar's Admin - Assets"):WaitForChild("Events")
local getSettingsFunction: RemoteFunction = events:WaitForChild("LoadSettings")
local saveSettingsEvent: RemoteEvent = events:WaitForChild("SaveSettings")
local permsModule = require(repStorage["Dar's Admin - Assets"]:WaitForChild("Modules"):WaitForChild("Server&Client"):WaitForChild("Permissions"))
local settingsDataModule = require(repStorage["Dar's Admin - Assets"]:WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("SettingsDataHandler"))

permsModule:ToggleDebugMode(false)

local keywordDebug = "[Debug - SettingsHandler] "

local settingsData = {
	DebugMode = false,
	TerminalKeybind = "F2",
	ChatTag = true,
}

local function DebugOutput(msg: string, typeOfDebug)
	if permsModule.Values.output then
		if not typeOfDebug then
			print(msg)
		else
			warn(msg)
		end
	end
end

local function OnDebugModeToggle()
	if settingsData.DebugMode == false then
		settingsData.DebugMode = true
	else
		settingsData.DebugMode = false
	end
	
	settingsDataModule:ToggleIcon(buttons.DebugModeButton, settingsData.DebugMode)
	permsModule:ToggleDebugMode(settingsData.DebugMode)
	return
end

buttons.DebugModeButton.MouseButton1Click:Connect(OnDebugModeToggle)

------------------ Keybinding Terminal ------------------

local UIS = game:GetService("UserInputService")
local changingKey = false

local function InputBeganTerminal(input: InputObject, isTyping)
	if isTyping or changingKey then return end
	
	if input.KeyCode == Enum.KeyCode[settingsData.TerminalKeybind] then
		DebugOutput(keywordDebug.."Terminal Key detected.")
		events:WaitForChild("OpenTerminalViaKeybind"):Fire()
	end
	
	return
end

UIS.InputBegan:Connect(InputBeganTerminal)

local keybindTerminalButton = scrollFrame:WaitForChild("TerminalKeybind"):WaitForChild("Keybind")

local function OnKeybindChange()
	if changingKey then return end

	changingKey = true
	keybindTerminalButton.Text = "Press any key!"
	local keyToSet = UIS.InputBegan:Wait()

	if keyToSet.UserInputType ~= Enum.UserInputType.Keyboard then
		DebugOutput(keywordDebug.."Something went wrong while changing the custom keybind for the terminal, returning to F2.", true)
		keyToSet = Enum.KeyCode.F2

		keybindTerminalButton.Text = "F2"
		settingsData.TerminalKeybind = "F2"
		task.wait()
		changingKey = false

		return
	end

	keybindTerminalButton.Text = keyToSet.KeyCode.Name
	settingsData.TerminalKeybind = keyToSet.KeyCode.Name
	task.wait()
	changingKey = false

	return
end

keybindTerminalButton.MouseButton1Click:Connect(OnKeybindChange)

------------------ Chat Tag Toggle ------------------

local setChatTag: RemoteEvent = events:WaitForChild("SetChatTag")

local function OnChatTagToggle()
	if settingsData.ChatTag  then
		settingsData.ChatTag = false
	else
		settingsData.ChatTag = true		
	end
	
	setChatTag:FireServer(settingsData.ChatTag)
	settingsDataModule:ToggleIcon(buttons.ChatTagButton, settingsData.ChatTag)
	return
end

buttons.ChatTagButton.MouseButton1Click:Connect(OnChatTagToggle)

------------------ Settings Loading/Saving ------------------

local saveDebounce = false

local function SaveSettings()
	if saveDebounce then 
		buttons.SaveButton.Interactable = false
		DebugOutput(keywordDebug.."Save attempted, but saving method is still in debounce.", true)
		buttons.SaveButton.BackgroundColor3 = Color3.fromRGB(255, 96, 96)
		buttons.SaveButton.Text = "Wait before saving again!"
		task.wait(2)
		buttons.SaveButton.BackgroundColor3 = Color3.fromRGB(189, 255, 195)
		buttons.SaveButton.Text = "Save"
		buttons.SaveButton.Interactable = true
		
		return 
	end
	DebugOutput(keywordDebug.."Entering debounce for data saving.")
	saveDebounce = true
	buttons.SaveButton.Interactable = false
	settingsDataModule:SaveSettings(settingsData)
	
	buttons.SaveButton.BackgroundColor3 = Color3.fromRGB(166, 219, 255)
	buttons.SaveButton.Text = "Saved!"
	task.wait(2)
	buttons.SaveButton.BackgroundColor3 = Color3.fromRGB(189, 255, 195)
	buttons.SaveButton.Text = "Save"
	buttons.SaveButton.Interactable = true
	
	task.wait(7)
	DebugOutput(keywordDebug.."Finished debounce for data saving.")
	saveDebounce = false
	
	return
end

buttons.SaveButton.MouseButton1Click:Connect(SaveSettings)

local settingsLoaded: BindableEvent = events:WaitForChild("OnSettingsLoad")
local success, settingsToSet = getSettingsFunction:InvokeServer()

if success then
	if settingsToSet then
		settingsData.DebugMode = settingsToSet.DebugMode
		---------------------------------------
		permsModule:ToggleDebugMode(settingsData.DebugMode)

		settingsDataModule:ToggleIcon(buttons.DebugModeButton, settingsData.DebugMode)
		---------------------------------------
		settingsData.TerminalKeybind = if settingsToSet.TerminalKeybind ~= "F2" then settingsToSet.TerminalKeybind else "F2"
		keybindTerminalButton.Text = settingsData.TerminalKeybind
		---------------------------------------
		if settingsToSet.ChatTag == false then
			OnChatTagToggle()
		end
		---------------------------------------
	end
	---------------------------------------
	settingsLoaded:Fire(true)
	DebugOutput(keywordDebug.."Saving settings to ensure everything is up-to-date.", true)
	SaveSettings()
else
	settingsLoaded:Fire(false)
	
	if settingsToSet then
		warn(keywordDebug.."Failed to load settings, error:", settingsToSet)
	else
		warn(keywordDebug.."Failed to load settings, unknown error.")
		warn(keywordDebug.."Please report this error to the developer of the game: "..settingsToSet)
	end
end

------------------  ------------------
