local m = {}

local player = game:GetService("Players").LocalPlayer
local gui = player.PlayerGui:WaitForChild("AdminGui")
local background = gui:WaitForChild("PanelZone"):WaitForChild("Background")
local permissionsModule = require(script.Parent.Parent:WaitForChild("Server&Client"):WaitForChild("Permissions"))

local animatingText = false
local changingSection = false

local debugKeywords = {
	PanelLoad = "[Debug - PanelCommandsLoader] ",
}

local function DebugOutput(msg: string, typeOfDebug)
	if permissionsModule.Values.output then
		if not typeOfDebug then
			print(msg)
		else
			warn(msg)
		end
	end
end

--[[Plays an animation based if the panel is toggled <code>True</code> or <code>False</code>.

<strong>toggle:</strong> Wether it's <code>True</code> or <code>False</code>.]]
function m:TogglePanel(toggle: boolean)
	local tweenService = game:GetService("TweenService")
	local twInfoPanel = TweenInfo.new(0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	local tweenAppear = tweenService:Create(background, twInfoPanel, {Position = UDim2.fromScale(0.5, 0.5)})
	local tweenDisappear = tweenService:Create(background, twInfoPanel, {Position = UDim2.fromScale(0.5, -0.5)})
	
	if toggle then
		background.Parent.Visible = true
		tweenAppear:Play()
		tweenAppear.Completed:Wait()
	else
		tweenDisappear:Play()
		tweenDisappear.Completed:Wait()
	end
	
	tweenAppear:Destroy()
	tweenDisappear:Destroy()
	
	return
end

--[[Animates the panel title.]]
function m:AnimateTitleText()
	if animatingText then return end
	animatingText = true

	local title = background:WaitForChild("MainSection"):WaitForChild("Title")
	local titleString = "Dar's Admin"
	title.Text = ""
	
	local putBar = false
	
	for i = 1, string.len(titleString) do
		if not animatingText then return end
		
		if putBar then
			putBar = false
		else
			putBar = true
		end
		
		title.Text = string.sub(titleString, 1, i) .. if putBar then "|" else ""
		
		if string.sub(titleString, i, i) == "'" or string.sub(titleString, i, i) == " " then
			task.wait(0.13)
		else
			task.wait(0.07)
		end
	end
	
	title.Text = titleString

	return
end

function m:TerminateTitleAnimation()
	animatingText = false
	local title = background:WaitForChild("MainSection"):WaitForChild("Title")
	local titleString = "Dar's Admin"
	title.Text = titleString
	return
end

function m:SetButtonGradient(gradient: UIGradient)
	local runServ = game:GetService("RunService")

	local function HeartBeat(delt)
		gradient.Rotation += 0.5
		return
	end

	runServ.Heartbeat:Connect(HeartBeat)
	return
end

function m:LightButton(button: TextButton)
	button.BackgroundTransparency = 0.75
end

function m:UndoLightButton(button: TextButton)
	button.BackgroundTransparency = 0.9
end

--[[Plays an animation that slides the current section, replacing it with another one.

<strong>currentSectionFrame:</strong> The current section the player is viewing.
<strong>sectionToGoTo:</strong> The section to swipe to.
<strong>sideToSwipe:</strong> The side that the animation will swipe to.]]
function m:GoToSection(currentSectionFrame: Frame, sectionToGoTo: Frame, sideToSwipe: string)
	local tweenService = game:GetService("TweenService")
	local twInfoSwipe = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut)
	
	if changingSection then changingSection = false end
	task.wait()
	changingSection = true
	
	while changingSection do
		local tweens = {}

		if string.lower(sideToSwipe) == "left" then
			sectionToGoTo.Position = UDim2.fromScale(1.5, 0.5)
			sectionToGoTo.Visible = true
			tweens[1] = tweenService:Create(currentSectionFrame, twInfoSwipe, {Position = UDim2.fromScale(-1.5, 0.5)})
			tweens[2] = tweenService:Create(sectionToGoTo, twInfoSwipe, {Position = UDim2.fromScale(0.5, 0.5)})
		elseif string.lower(sideToSwipe) == "right" then
			sectionToGoTo.Position = UDim2.fromScale(-1.5, 0.5)
			sectionToGoTo.Visible = true
			tweens[1] = tweenService:Create(currentSectionFrame, twInfoSwipe, {Position = UDim2.fromScale(1.5, 0.5)})
			tweens[2] = tweenService:Create(sectionToGoTo, twInfoSwipe, {Position = UDim2.fromScale(0.5, 0.5)})
		else
			error("Invalid input to swipe to side! | " .. sideToSwipe)
			return
		end

		for i, tween in ipairs(tweens) do
			tween:Play()
		end

		tweens[2].Completed:Wait()
		currentSectionFrame.Visible = false

		for i, tween in tweens do
			tween:Destroy()
		end
		
		break
	end
end

local commandsFrame = background:WaitForChild("Commands")

m.CommandSections = {
	[1] = commandsFrame:WaitForChild("Owner"),
	[2] = commandsFrame:WaitForChild("Admin"),
	[3] = commandsFrame:WaitForChild("Mod+"),
	[4] = commandsFrame:WaitForChild("Mod"),
	[5] = commandsFrame:WaitForChild("Vip"),
	[6] = commandsFrame:WaitForChild("Player"),
}

local currentSection = m.CommandSections[1]

local function UpdateSection()
	for i, section in commandsFrame:GetChildren() do
		if table.find(m.CommandSections, section) then
			if section == currentSection then
				commandsFrame:WaitForChild("SectionChanger"):WaitForChild("SectionDisplayer").Text = section.Name.." Commands"
				section.Visible = true
			else
				section.Visible = false
			end
		end
	end
	
	for i, sec in m.CommandSections do
		sec.AutomaticCanvasSize = Enum.AutomaticSize.None
		sec.AutomaticCanvasSize = Enum.AutomaticSize.Y
	end
	
	return
end

function m:NextCommandSection()
	if currentSection == m.CommandSections[#m.CommandSections] then
		currentSection = m.CommandSections[1]
	else
		currentSection = m.CommandSections[table.find(m.CommandSections, currentSection) + 1]
	end
	
	UpdateSection()
	
	return currentSection.Name.." Commands"
end

function m:ReturnCommandSection()
	if currentSection == m.CommandSections[1] then
		currentSection = m.CommandSections[#m.CommandSections]
	else
		currentSection = m.CommandSections[table.find(m.CommandSections, currentSection) - 1]
	end
	
	UpdateSection()
	
	return currentSection.Name.." Commands"
end

function m:LoadPanelCommands()
	local commandsModule = require(script.Parent.Parent:WaitForChild("Server&Client"):WaitForChild("Commands"))
	local dependenciesFolder = script.Parent.Parent.Parent:WaitForChild("Dependencies")
	local sampleCommand = dependenciesFolder:WaitForChild("SampleCommand")
	local sampleMiniCommand = dependenciesFolder:WaitForChild("SampleCommandWithMini")
	DebugOutput(debugKeywords.PanelLoad.."Initiated panel load.")
	
	DebugOutput("----------------------------------")
	for i, commandSection in m.CommandSections do
		DebugOutput(debugKeywords.PanelLoad.."Now loading: "..commandSection.Name)
		local currentlySearchingFor = commandSection.Name
		
		local tableToSearch = commandsModule.CommandsForGui[currentlySearchingFor.."Commands"]
		
		for ii, command in tableToSearch do
			local sampleToUse
			local parametersToDisplay = ""
			
			if command.useDoubleDescription then
				sampleToUse = sampleMiniCommand
				DebugOutput(debugKeywords.PanelLoad.."Command: "..command.Command.." uses use double description.")
			else
				sampleToUse = sampleCommand
				DebugOutput(debugKeywords.PanelLoad.."Command: "..command.Command.." doesn't use double description.")
			end
			
			if command.Parameters then
				parametersToDisplay = command.Parameters
			end
			
			local newCommand = sampleToUse:Clone()
			
			
			newCommand.Name = command.Command
			newCommand.Command.Text = command.Command.." "..parametersToDisplay
			newCommand.CommandExample.CommandExampleText.Text = command.ExampleCommand
			
			if command.useDoubleDescription then
				newCommand.Additional_Information_Mini_1.Text = command.MiniDescription1
				newCommand.Additional_Information_Mini_2.Text = command.MiniDescription2
			else
				newCommand.Additional_Information.Text = command.Description
			end
			
			newCommand.LayoutOrder = ii
			DebugOutput(debugKeywords.PanelLoad.."Layout order for: "..newCommand.Name.." = "..ii)
			newCommand.Parent = commandSection
		end
		
		DebugOutput("----------------------------------")
	end
end

return m
