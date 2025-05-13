local m = {}

local repStorage = game:GetService("ReplicatedStorage")
local events = repStorage:WaitForChild("Dar's Admin - Assets"):WaitForChild("Events")
local getSettingsFunction: RemoteFunction = events:WaitForChild("LoadSettings")
local saveSettingsEvent: RemoteEvent = events:WaitForChild("SaveSettings")
local permsModule = require(repStorage["Dar's Admin - Assets"]:WaitForChild("Modules"):WaitForChild("Server&Client"):WaitForChild("Permissions"))

local function DebugOutput(msg, typeOfDebug)
	if permsModule.Values.output then
		if not typeOfDebug then
			print(msg)
		else
			warn(msg)
		end
	end
end

local keywordDebug = "[Debug - SettingsData] "

--[[<strong>Client Sided!</strong>
Requests the server to load the player's settings information.]]
function m:LoadSettings()
	local success, data = getSettingsFunction:InvokeServer()
	if success then
		DebugOutput(keywordDebug.."Loaded data succesfully. Data received: "..table.unpack(data) )
		return data
	else
		DebugOutput(keywordDebug.."Failed to load settings data. | "..table.unpack(data), true)
		return nil
	end
end

--[[<strong>Client Sided!</strong>
Requests the server to save the information about a player's settings information.

<strong>settingsData:</strong> The data the server will save. It should be a table containing values.]]
function m:SaveSettings(settingsData)
	saveSettingsEvent:FireServer(settingsData)
	return
end

function m:ToggleIcon(buttonToToggle: ImageButton, toggle: boolean)
	local iconsFolder = buttonToToggle:WaitForChild("Icons")
	
	if toggle then
		buttonToToggle.Image = iconsFolder:WaitForChild("On").Image
		buttonToToggle.BackgroundColor3 = iconsFolder.On.BackgroundColor3
	else
		buttonToToggle.Image = iconsFolder:WaitForChild("Off").Image
		buttonToToggle.BackgroundColor3 = iconsFolder.Off.BackgroundColor3
	end
	
	return
end

return m
