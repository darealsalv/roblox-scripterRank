local player = game:GetService("Players").LocalPlayer
local gui = player.PlayerGui:WaitForChild("AdminGui")
local terminalFrame = gui:WaitForChild("Terminal")
local panelZone = gui:WaitForChild("PanelZone")
panelZone.Visible = false
local buttonsZone = panelZone:WaitForChild("Background"):WaitForChild("MainSection"):WaitForChild("ButtonsZone")
local assetsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Dar's Admin - Assets")
local eventsFolder = assetsFolder:WaitForChild("Events")
local clientModules = assetsFolder:WaitForChild("Modules"):WaitForChild("Client")
local panelAnimationsModule = require(clientModules:WaitForChild("PanelAnimations"))
local permsModule = require(clientModules.Parent:WaitForChild("Server&Client"):WaitForChild("Permissions"))

local terminalVisible = false

---------- Decorations ----------

local buttons = {}

for i, inst in buttonsZone:GetChildren() do
	if inst:IsA("TextButton") then
		table.insert(buttons, inst)
		inst:WaitForChild("UIStroke").Transparency = 1
		panelAnimationsModule:SetButtonGradient(inst.UIStroke:WaitForChild("UIGradient"))
	end
end

for i, button: TextButton in buttons do
	local function OnButtonHover()
		local tweenAppearStroke = game:GetService("TweenService"):Create(button:WaitForChild("UIStroke"), TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 0})
		tweenAppearStroke:Play()
		tweenAppearStroke.Completed:Wait()
		tweenAppearStroke:Destroy()
		
		return
	end
	
	local function OnButtonHoverEnd()
		local tweenDisappearStroke = game:GetService("TweenService"):Create(button:WaitForChild("UIStroke"), TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Transparency = 1})
		tweenDisappearStroke:Play()
		tweenDisappearStroke.Completed:Wait()
		tweenDisappearStroke:Destroy()
		
		return
	end
	
	local function OnClick()
		panelAnimationsModule:LightButton(button)
		return
	end
	
	local function ClickEnd()
		panelAnimationsModule:UndoLightButton(button)
		return
	end
	
	button.MouseEnter:Connect(OnButtonHover)
	button.MouseLeave:Connect(OnButtonHoverEnd)
	button.MouseButton1Down:Connect(OnClick)
	button.MouseButton1Up:Connect(ClickEnd)
end

repeat task.wait() until permsModule.Values.LoadedConfiguration == true

local commandsButton = buttonsZone:WaitForChild("CommandsButton")
local informationButton = buttonsZone:WaitForChild("InformationButton")
local modChatButton = buttonsZone:WaitForChild("PrivateChat")
local terminalButton = buttonsZone:WaitForChild("Terminal")
local settingsButton = buttonsZone:WaitForChild("Settings")

local reloadSectionBindable: BindableEvent = assetsFolder:WaitForChild("Events"):WaitForChild("ReloadSection")
local commandsFirstClick = true

local function OnModChatClick()
	panelAnimationsModule:GoToSection(panelZone.Background:WaitForChild("MainSection"), panelZone.Background:WaitForChild("PrivateChat"), "left")
	return
end

local function OnModChatReturn()
	panelAnimationsModule:GoToSection(panelZone.Background:WaitForChild("PrivateChat"), panelZone.Background:WaitForChild("MainSection"), "right")
	return
end

local function OnTerminalToggle()
	if not terminalVisible then
		terminalVisible = true
		terminalFrame.Visible = true
		terminalFrame:WaitForChild("CommandInput"):CaptureFocus()
		task.wait()
		terminalFrame.BackgroundTransparency = 0.4
	else
		terminalVisible = false
		gui:WaitForChild("Terminal").Visible = false
		terminalFrame.BackgroundTransparency = 0.9
		terminalFrame:WaitForChild("CommandInput"):ReleaseFocus()
	end
end

local function OnInformationClick()
	panelAnimationsModule:GoToSection(panelZone.Background:WaitForChild("MainSection"), panelZone.Background:WaitForChild("Information"), "left")
	return
end

local function OnInformationReturn()
	panelAnimationsModule:GoToSection(panelZone.Background:WaitForChild("Information"), panelZone.Background:WaitForChild("MainSection"), "right")
	return
end

local function OnCommandsClick()
	panelAnimationsModule:GoToSection(panelZone.Background:WaitForChild("MainSection"), panelZone.Background:WaitForChild("Commands"), "left")
	
	if commandsFirstClick then
		commandsFirstClick = false
		reloadSectionBindable:Fire()
	end
	
	return
end

local function OnCommandsReturn()
	panelAnimationsModule:GoToSection(panelZone.Background:WaitForChild("Commands"), panelZone.Background:WaitForChild("MainSection"), "right")
	return
end

local function OnSettingsClick()
	panelAnimationsModule:GoToSection(panelZone.Background:WaitForChild("MainSection"), panelZone.Background:WaitForChild("Settings"), "left")
	return
end

local function OnSettingsReturn()
	panelAnimationsModule:GoToSection(panelZone.Background:WaitForChild("Settings"), panelZone.Background:WaitForChild("MainSection"), "right")
	return
end

terminalButton.MouseButton1Click:Connect(OnTerminalToggle)
modChatButton.MouseButton1Click:Connect(OnModChatClick)
informationButton.MouseButton1Click:Connect(OnInformationClick)
commandsButton.MouseButton1Click:Connect(OnCommandsClick)
settingsButton.MouseButton1Click:Connect(OnSettingsClick)

panelZone:WaitForChild("Background"):WaitForChild("PrivateChat"):WaitForChild("ReturnButton").MouseButton1Click:Connect(OnModChatReturn)
panelZone.Background:WaitForChild("Information"):WaitForChild("ReturnButton").MouseButton1Click:Connect(OnInformationReturn)
panelZone.Background:WaitForChild("Commands"):WaitForChild("ReturnButton").MouseButton1Click:Connect(OnCommandsReturn)
panelZone.Background:WaitForChild("Settings"):WaitForChild("ReturnButton").MouseButton1Click:Connect(OnSettingsReturn)
assetsFolder:WaitForChild("Events"):WaitForChild("OpenTerminalViaKeybind").Event:Connect(OnTerminalToggle)

---------- Help Command ----------

local helpCommand = eventsFolder:WaitForChild("HelpCommand")

local function OnHelp()
	task.spawn(OnCommandsClick)
	panelAnimationsModule:TogglePanel(true)
	
	return
end

helpCommand.OnClientEvent:Connect(OnHelp)
