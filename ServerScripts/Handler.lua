local mainFolder = workspace:WaitForChild("Dar's Admin")

for i, script in mainFolder["Dar's Admin - Local Scripts"]:GetChildren() do
	script.Parent = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
end

local DarAssetsFolder = Instance.new("Folder", game.ReplicatedStorage)
DarAssetsFolder.Name = "Dar's Admin - Assets"

mainFolder.Events.Parent = DarAssetsFolder
mainFolder.Dependencies.Parent = DarAssetsFolder
mainFolder.Modules.Parent = DarAssetsFolder
if mainFolder:FindFirstChild("Dar's Admin - Gui"):WaitForChild("AdminGui") then mainFolder["Dar's Admin - Gui"].AdminGui.Parent = game:GetService("StarterGui") end

--DarAssetsFolder:WaitForChild("Modules"):WaitForChild("Server&Client"):WaitForChild("Permissions")
--workspace["Dar's Admin"].Modules["Server&Client"].Permissions
local permsModule = require(DarAssetsFolder:WaitForChild("Modules"):WaitForChild("Server&Client"):WaitForChild("Permissions"))

local keywordsDebug = {
	ModChat = "[Debug - ServerModChatHandler] ",
	SettingsLoader = "[Debug - ServerSettingsLoader] ",
	CommandsHandler = "[Debug - ServerCommandsHandler] "
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

local success, err = permsModule:LoadPermissions()

if not success then
	if err == "No data" then
		DebugOutput("[Debug - Permissions Loader] No permissions found, initializing with default permissions.")
	else
		if err then
			DebugOutput("[Debug - Permissions Loader] Failed to load. Reason: "..err, true)
		else
			DebugOutput("[Debug - Permissions Loader] Failed to load. Reason is Unknown.", true)
		end
	end
end

----------------------------------------------------------------------------------------------

local eventsFolder = DarAssetsFolder:WaitForChild("Events")

local commadErrorEvent: RemoteEvent = eventsFolder:WaitForChild("CommandError")
local commandEvent: RemoteEvent = eventsFolder:WaitForChild("RunCommand")
local rankChangeEvent: RemoteEvent = eventsFolder:WaitForChild("RankChange")
local notificationEvent: RemoteEvent = eventsFolder:WaitForChild("Notification")
local setChatTag: RemoteEvent = eventsFolder:WaitForChild("SetChatTag")

local serverAndClientModules = DarAssetsFolder:WaitForChild("Modules"):WaitForChild("Server&Client")
local serverModules = DarAssetsFolder:WaitForChild("Modules"):WaitForChild("Server")
local blindModule = require(serverAndClientModules:WaitForChild("Blind"))

print(serverAndClientModules:WaitForChild("Blind"))
print(blindModule.BlindTypes)

----------------------------------------------------------------------------------------------

---------- Mod Chat Handler ----------

local modChatModule = require(DarAssetsFolder.Modules["Server&Client"]["Mod Chat Handler"])
local messageReceiveEvent: RemoteEvent = DarAssetsFolder.Events.OnModMessageReceive

local function GetFilteredMessage(filterResult: TextFilterResult)
	local textService = game:GetService("TextService")
	local result

	local success, err = pcall(function()
		result = filterResult:GetNonChatStringForBroadcastAsync()
	end)

	if success then
		return true, result
	end

	return false
end

local function FilterMessage(msg: string, user: Player)
	local textService = game:GetService("TextService")
	local result
	
	local success, err = pcall(function()
		result = textService:FilterStringAsync(msg, user.UserId)
	end)
	
	if success then
		local success, filteredMessage = GetFilteredMessage(result)
		
		if success then
			return true, filteredMessage
		end
		
	end
	
	return false
end

messageReceiveEvent.OnServerEvent:Connect(function(plr, msg)
	DebugOutput(keywordsDebug.ModChat.."Received message from: "..plr.DisplayName.." (@"..plr.Name..").")
	if modChatModule.IsPlayerMod(plr) then
		DebugOutput(keywordsDebug.ModChat.."Sending message from "..plr.DisplayName.." (@"..plr.Name..") to other moderators.")
		local succes, filteredMessage = FilterMessage(msg, plr)
		modChatModule:SendMessage(plr, filteredMessage)
	end
end)

---------- Settings Loader ----------

local getSettingsFunction: RemoteFunction = DarAssetsFolder.Events.LoadSettings
local saveSettingsEvent: RemoteEvent = DarAssetsFolder.Events.SaveSettings

getSettingsFunction.OnServerInvoke = function(plr)
	DebugOutput(keywordsDebug.SettingsLoader.."Attempting to get settings data for "..plr.DisplayName.." (@"..plr.Name..").")
	DebugOutput(keywordsDebug.SettingsLoader.."Access to DataStore: "..tostring( permsModule.StudioAccessDataStore() ) )
	
	if not permsModule.StudioAccessDataStore() then
		DebugOutput(keywordsDebug.SettingsLoader.."Attempted to save data but Studio doesn't have access to DataStore! Make sure 'Enable Studio Access to API Services' is checked in your game settings. ")
		return false, "Studio doesn't have access to DataStore services! Activate the 'Enable Studio Access to API Services' in your game settings in order to proceed."
	end

	local dataStore = game:GetService("DataStoreService")
	local settingsData = dataStore:GetDataStore("SettingsDarsAdminPanel")

	local dataToReturn 

	local success, err = pcall(function()
		dataToReturn = settingsData:GetAsync(plr.UserId)
	end)

	if success then
		DebugOutput(keywordsDebug.SettingsLoader.."Successfully retrieved settings data for "..plr.DisplayName.." (@"..plr.Name..").")
	else
		DebugOutput(keywordsDebug.SettingsLoader.."Initial get settings data failed for "..plr.DisplayName.." (@"..plr.Name.."). Retrying...", true)

		for i = 1, permsModule.Values.RetriesOnDataFail do
			success, err = pcall(function()
				dataToReturn = settingsData:GetAsync(plr.UserId)
			end)

			task.wait(1)

			if success then 
				DebugOutput(keywordsDebug.SettingsLoader.."Successfully retrieved settings data on retry "..i.." for "..plr.DisplayName.." (@"..plr.Name..").")
				break 
			else
				DebugOutput(keywordsDebug.SettingsLoader.."Retry "..i.." failed for "..plr.DisplayName.." (@"..plr.Name..").", true)
			end
		end

		if not success then 
			DebugOutput(keywordsDebug.SettingsLoader.."Failed to get settings data for "..plr.DisplayName.." (@"..plr.Name.."). Error: "..err, true)
			error("Failed to get settings data. | "..err) 
			return false, nil 
		end
	end
	
	if dataToReturn == nil then
		DebugOutput(keywordsDebug.SettingsLoader.."The player: "..plr.DisplayName.."(@"..plr.Name..") has no settings data, player will be initialized with default data.")
	else
		warn(keywordsDebug.SettingsLoader.."Settings for player: "..plr.DisplayName.."(@"..plr.Name.."):", dataToReturn)
	end
	
	return if success then true else false, dataToReturn
end

saveSettingsEvent.OnServerEvent:Connect(function(plr, dataToSave)
	DebugOutput(keywordsDebug.SettingsLoader.."Attempting to save settings data for "..plr.DisplayName.." (@"..plr.Name..").")

	local dataStore = game:GetService("DataStoreService")
	local settingsData = dataStore:GetDataStore("SettingsDarsAdminPanel")

	local success, err = pcall(function()
		settingsData:SetAsync(plr.UserId, dataToSave)
	end)

	if success then
		DebugOutput(keywordsDebug.SettingsLoader.."Successfully saved settings data for "..plr.DisplayName.." (@"..plr.Name..").")
	else
		DebugOutput(keywordsDebug.SettingsLoader.."Initial save settings data failed for "..plr.DisplayName.." (@"..plr.Name.."). Retrying...", true)

		for i = 1, permsModule.Values.RetriesOnDataFail do
			success, err = pcall(function()
				settingsData:SetAsync(plr.UserId, dataToSave)
			end)

			task.wait(1)

			if success then 
				DebugOutput(keywordsDebug.SettingsLoader.."Successfully saved settings data on retry "..i.." for "..plr.DisplayName.." (@"..plr.Name..").")
				break 
			else
				DebugOutput(keywordsDebug.SettingsLoader.."Retry "..i.." failed for saving settings data for "..plr.DisplayName.." (@"..plr.Name..").", true)
			end
		end

		if not success then 
			DebugOutput(keywordsDebug.SettingsLoader.."Failed to save settings data for "..plr.DisplayName.." (@"..plr.Name.."). Error: "..err, true)
			error("Failed to save settings data. | "..err) 
			return 
		end
	end

	return
end)

-------- Chat Tag Value Handle --------

game:GetService("Players").PlayerAdded:Connect(function(plr)
	local chatTagValue = Instance.new("BoolValue", plr)
	chatTagValue.Name = "DarAdminChatTag"
	chatTagValue.Value = true
end)

for i, player in game.Players:GetPlayers() do
	local chatTagValue = Instance.new("BoolValue", player)
	chatTagValue.Name = "DarAdminChatTag"
	chatTagValue.Value = true
end

setChatTag.OnServerEvent:Connect(function(plr, toggle)
	plr.DarAdminChatTag.Value = toggle
end)

---------- Rank Alert On Join Handler ----------

local function NotifyPlayerRank(plr)
	local found = false
	local rank
	
	local rankOrder = {
		owner = "Owner",
		admin = "Admin",
		["mod+"] = "Mod+",
		mod = "Mod",
		vip = "VIP",
		player = "Player"
	}

	for groupKey, entries in pairs(permsModule.PlayersWithPermissions) do
		for i, entry in ipairs(entries) do
			if entry.Id == plr.UserId then
				found = true
				break
			end
		end

		rank = rankOrder[groupKey]

		if found then break end
	end
	
	if found then
		rankChangeEvent:FireClient(plr, "Welcome! Your rank is: "..rank, true)
	else
		table.insert(permsModule.PlayersWithPermissions.player, {
			["Name"] = plr.Name,
			["Id"] = plr.UserId
		})
		
		rankChangeEvent:FireClient(plr, "Welcome! Your rank is: Player", true)
		permsModule:SavePermissions()
	end
end

for i, player in game:GetService("Players"):GetPlayers() do
	NotifyPlayerRank(player)
end

game:GetService("Players").PlayerAdded:Connect(NotifyPlayerRank)

---------- Rank Request ----------

local getPlayerRankFunction: RemoteFunction = eventsFolder:WaitForChild("GetPlayerRank")

getPlayerRankFunction.OnServerInvoke = function(plr: Player, plrToGetRankUserId: number)
	return permsModule:GetPlayerRank(plrToGetRankUserId)
end

---------- Commands Handler ----------

local commandsModule

pcall(function()
	commandsModule = require(workspace["Dar's Admin"].Modules["Server&Client"].Commands)
end)

if not commandsModule then commandsModule = require(DarAssetsFolder:WaitForChild("Modules"):WaitForChild("Server&Client"):WaitForChild("Commands")) end

local function CommandExists(commandList, command)
	for i, cmd in commandList do
		if cmd == command then
			return true
		end
	end
	
	return false
end
	
local function GetCommandRank(plrRunningCommand, command)
	if CommandExists(commandsModule.Comandos.OwnerCommands, command) then
		DebugOutput(keywordsDebug.CommandsHandler .. "Command rank: Owner.")
		return "owner"
	elseif CommandExists(commandsModule.Comandos.AdminCommands, command) then
		DebugOutput(keywordsDebug.CommandsHandler .. "Command rank: Admin.")
		return "admin"
	elseif CommandExists(commandsModule.Comandos["Mod+Commands"], command) then
		DebugOutput(keywordsDebug.CommandsHandler .. "Command rank: Mod+.")
		return "mod+"
	elseif CommandExists(commandsModule.Comandos.ModCommands, command) then
		DebugOutput(keywordsDebug.CommandsHandler .. "Command rank: Mod.")
		return "mod"
	elseif CommandExists(commandsModule.Comandos.VipCommands, command) then
		DebugOutput(keywordsDebug.CommandsHandler .. "Command rank: Vip.")
		return "vip"
	elseif CommandExists(commandsModule.Comandos.PlayerCommands, command) then
		DebugOutput(keywordsDebug.CommandsHandler .. "Command rank: Player.")
		return "player"
	else
		commadErrorEvent:FireClient(plrRunningCommand, "No valid command passed.")
		DebugOutput(keywordsDebug.CommandsHandler.."No valid command passed.", true)
		return nil, false
	end
end


local rankHierarchy = {
	player = 1,
	vip = 2,
	mod = 3,
	["mod+"] = 4,
	admin = 5,
	owner = 6,
}

local function PlayerHasPermission(plr, rank)
	local perms = permsModule.PlayersWithPermissions[rank]
	if perms then
		
		for i, entry in ipairs(perms) do
			
			if entry.Id == plr.UserId then
				return true
			end
			
		end
		
	end
	
	return false
end

local function GetPlayerHighestRank(plr)
	local orderedRanks = {"owner", "admin", "mod+", "mod", "vip", "player"}
	
	for i, rank in ipairs(orderedRanks) do
		
		if PlayerHasPermission(plr, rank) then
			return rank
		end
		
	end
		
	return nil
end

local function IsRankHigherThan(rankToCheck, rankToSurpass)
	if not rankToCheck or not rankToSurpass then
		return false
	end
	
	local rankToCheckValue = rankHierarchy[rankToCheck]
	local rankToSurpassValue = rankHierarchy[rankToSurpass]
	
	if not rankToCheckValue or not rankToSurpassValue then
		return false
	end
	
	return rankToCheckValue > rankToSurpassValue
end

local function CanPlayerRunCommand(plr, command)
	if not plr or not command then 
		return false
	end

	local requiredRank, found = GetCommandRank(plr, command)
	
	if found == false then 
		return false, "No"
	end
	
	if not requiredRank then 
		return false
	end

	local playerRank = GetPlayerHighestRank(plr)
	
	if not playerRank then 
		return false 
	end

	local playerRankValue = rankHierarchy[playerRank]
	
	local requiredRankValue = rankHierarchy[requiredRank]
	
	if not playerRankValue or not requiredRankValue then
		warn("Invalid rank value detected.")
		return false
	end

	return playerRankValue >= requiredRankValue
end

local partsToIgnoreOnInvisible = {}

--[[Searches a player in the same server as you based of their name. Returns a table containing the players found. Usually will only return one value inside the table unless, the <code>allowAllPlayers</code> is set to <code>true</code>, if so, the table will contain all players in the server.

<strong>plrMakingTheSearch:</strong> The player that is searching for another player.
<strong>playerToSearchName:</strong> The player name to search.
<strong>allowOwnSelf:</strong> Wether to allow the parameter 'me' as a valid search.
<strong>allowAllPlayers:</strong> Wether to allow the parameter 'all' as a valid search.]]
local function SearchPlayerByName(plrMakingTheSearch: Player, playerToSearchName: string, allowOwnSelf: boolean, allowAllPlayers: boolean)
	local nameLength = #playerToSearchName
	local matches = {}
	
	if nameLength < 1 then
		nameLength = -1
	end

	if allowOwnSelf then
		if string.lower(playerToSearchName) == "me" then
			table.insert(matches, plrMakingTheSearch)
			return true, matches
		end
	end

	if allowAllPlayers then
		if string.lower(playerToSearchName) == "all" then
			matches = game:GetService("Players"):GetPlayers()
			return true, matches
		end
	end

	for i, player in game:GetService("Players"):GetPlayers() do
		local nameToMatch = string.sub(player.Name, 1, nameLength)

		if playerToSearchName == nameToMatch then
			table.insert(matches, player)
		end
	end

	if #matches > 1 then
		DebugOutput(keywordsDebug.CommandsHandler.."More than 1 player was found while searching for players!", true)
		return false, nil
	elseif #matches < 1 then
		DebugOutput(keywordsDebug.CommandsHandler.."Player not found!", true)
		return false, nil
	end
	
	return true, matches
end

-- value: the numerical time value
-- unit: a string indicating the unit ("seconds", "minutes", "hours", "days", "months", "years")
local function convertToSeconds(value, unit)
	local conversionTable = {
		["s"]  = 1,
		["seconds"] = 1,
		["min"]  = 60,
		["minutes"] = 60,
		["hour"]    = 3600,
		["h"]   = 3600,
		["day"]     = 86400,
		["d"]    = 86400,
		
		-- Approximate conversions:
		["month"]   = 2592000,  -- 30 days * 86400 seconds/day
		["m"]  = 2592000,
		["year"]    = 31536000, -- 365 days * 86400 seconds/day
		["y"]   = 31536000,
	}

	local factor = conversionTable[unit:lower()]
	
	if not factor then
		error("Invalid time unit: " .. tostring(unit))
	end

	return value * factor
end

local function DoesInstanceHasTransparencyValue(instance)
	local success, err = pcall(function()
		return instance.Transparency
	end)

	return if success then true else false
end

local logCommandEvent: RemoteEvent = eventsFolder:WaitForChild("LogCommand")

local function LogCommand(plr: Player, command: string, success: boolean)
	local timestamp = os.date("!%H:%M:%S") .. " - UTC"

	for i, player in ipairs(game.Players:GetPlayers()) do
		if permsModule:GetPlayerRank(player.UserId) ~= "player" then
			logCommandEvent:FireClient(player, plr, command, success, timestamp)
			continue
		end
	end
end

local function CheckRigType(character: Model)
	if character:FindFirstChild("Torso") then
		return "R6"
	else
		return "R15"
	end
end

local function AreVipCommandsEnabled(errorToPlayer: boolean, plrToError: Player, command: string, errorMessage: string)
	if not commandsModule.CommandSettings.VIPCommandsEnabled then
		if errorToPlayer then
			commadErrorEvent:FireClient(plrToError, errorMessage)
			DebugOutput(keywordsDebug.CommandsHandler..errorMessage, true)
			local Success = false
			LogCommand(plrToError, command, Success)
			return false
		else
			return false
		end
	else
		return true
	end
end

local vipCommandsError = "VIP Commands are not enabled in this server!"
local healDebounces = {}
local vipToggleDb = false

local function RunCommand(plrRunningTheCommand, commandReceived)
	local Success = false
	local logCommand = true
	
	local stopCommandSearchAt = string.find(commandReceived, " ")
	local command = string.lower(string.sub(commandReceived, 1, (stopCommandSearchAt or (#commandReceived + 1)) - 1))

	local canRunCommand, nonExistingCommand = CanPlayerRunCommand(plrRunningTheCommand, command)

	if not canRunCommand then
		
		if nonExistingCommand then
			Success = false
			return
		end
		
		DebugOutput(keywordsDebug.CommandsHandler.."Attempted to run command: "..command.." but player: @"..plrRunningTheCommand.Name.." ("..plrRunningTheCommand.UserId..") can't run this command or the command doesn't exist!", true)
		commadErrorEvent:FireClient(plrRunningTheCommand, "You don't have enough permissions to run this command!")
		Success = false
		LogCommand(plrRunningTheCommand, commandReceived, Success)
		return
	end
	
	DebugOutput(keywordsDebug.CommandsHandler.."Running command: "..command, true)

	if command == commandsModule.Comandos.OwnerCommands.Shutdown then
		local messagingService = game:GetService("MessagingService")
		messagingService:PublishAsync("MegaShutdown")
		Success = true

	elseif command == commandsModule.Comandos.OwnerCommands.MegaAnnounce then
		local messagingService = game:GetService("MessagingService")
		local success, filteredMessage = FilterMessage(string.sub(commandReceived, (stopCommandSearchAt or #command) + 1), plrRunningTheCommand)
		if not success then
			commadErrorEvent:FireClient(plrRunningTheCommand, "An error ocurred while filtering the message.")
			DebugOutput(keywordsDebug.CommandsHandler.."An error ocurred while filtering the message.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		local dataToTransfer = {
			plrRunningTheCommand.DisplayName,
			plrRunningTheCommand.UserId,
			filteredMessage,
			10
		}
		messagingService:PublishAsync("MegaAnnouncement", dataToTransfer)
		Success = true

	elseif command == commandsModule.Comandos.AdminCommands.Ban then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local stopPlayerSearchAt = string.find(commandReceived, " ", stopCommandSearchAt + 1) or #commandReceived + 1	
		local stopTimeSearchAt = string.find(commandReceived, " ", stopPlayerSearchAt + 1) or #commandReceived + 1

		local success, playersTable = SearchPlayerByName(plrRunningTheCommand, string.sub(commandReceived, stopCommandSearchAt + 1, stopPlayerSearchAt - 1), false, false)
		if not success then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to ban player because the player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		local timeToBanString = string.sub(commandReceived, stopPlayerSearchAt + 1, stopTimeSearchAt - 1)
		local timeToBan
		local unit = string.find(timeToBanString, "s") or string.find(timeToBanString, "min") or string.find(timeToBanString, "h") or string.find(timeToBanString, "d") or string.find(timeToBanString, "m") or string.find(timeToBanString, "y")

		if not timeToBanString then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You didn't provide a valid time to ban for!")
			DebugOutput(keywordsDebug.CommandsHandler.."You didn't provide a valid time to ban for!", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		if not unit then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You didn't provide a valid time to ban for!")
			DebugOutput(keywordsDebug.CommandsHandler.."You didn't provide a valid time to ban for!", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		DebugOutput(keywordsDebug.CommandsHandler.."TimeToBanString: "..timeToBanString)
		DebugOutput(keywordsDebug.CommandsHandler.."Unit received for ban time: "..string.sub(timeToBanString, unit))

		if timeToBanString == "-1" then
			timeToBan = -1
		else
			timeToBan = convertToSeconds(tonumber(string.sub(timeToBanString, 1, unit - 1)), string.sub(timeToBanString, unit)) 
		end

		for i, playerToBan in ipairs(playersTable) do
			if playerToBan.UserId == permsModule.PlayersWithPermissions.owner.Id then
				commadErrorEvent:FireClient(plrRunningTheCommand, "You can't ban the owner!")
				DebugOutput(keywordsDebug.CommandsHandler.."Can't ban the owner.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			elseif playerToBan.UserId == plrRunningTheCommand.UserId then
				commadErrorEvent:FireClient(plrRunningTheCommand, "You can't ban your own self!")
				DebugOutput(keywordsDebug.CommandsHandler.."Can't ban yourself.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
			
			local rankFromPlayerDoingBan = GetPlayerHighestRank(plrRunningTheCommand)
			local rankFromPlayerToBan
			
			for rank, entry in pairs(permsModule.PlayersWithPermissions) do

				for i, plrPerm in entry do
					if plrPerm.Id == playerToBan.UserId then
						rankFromPlayerToBan = entry
						break
					end
				end

			end


			if not rankFromPlayerToBan then rankFromPlayerToBan = "player" end

			if not IsRankHigherThan(rankFromPlayerDoingBan, rankFromPlayerToBan) then
				commadErrorEvent:FireClient(plrRunningTheCommand, "You don't have permission to ban this person!")
				DebugOutput(
					keywordsDebug.CommandsHandler ..
						"Player " .. plrRunningTheCommand.DisplayName .. 
						" (@" .. plrRunningTheCommand.Name .. 
						") attempted to ban: " .. playerToBan.DisplayName .. 
						" (@" .. playerToBan.Name .. 
						"), but he doesn't have enough permission to ban this user!",
					true
				)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end

			local configBan = {
				UserIds = { playerToBan.UserId },
				ApplyToUniverse = true,
				Duration = timeToBan,
				DisplayReason = string.sub(commandReceived, stopTimeSearchAt + 1),
				PrivateReason = "",
				ExcludeAltAccounts = false
			}

			local successBan, err = pcall(function()
				game:GetService("Players"):BanAsync(configBan)
			end)

			if not successBan then
				for i = 1, permsModule.Values.RetriesOnBanFail do
					successBan, err = pcall(function()
						game:GetService("Players"):BanAsync(configBan)
					end)
					if successBan then break end
					task.wait(0.65)
				end

				if not successBan then
					commadErrorEvent:FireClient(plrRunningTheCommand, "Failed to Ban because of an unknown error.")
					warn("Failed to ban because:", err)
					Success = false
					LogCommand(plrRunningTheCommand, commandReceived, Success)
					error(table.unpack(playersTable))
				end
			end
		end
		notificationEvent:FireClient(plrRunningTheCommand, "Banned succesfully!", "Succesfully banned the player: "..playersTable[1].DisplayName.." (@"..playersTable[1].Name..").")
		Success = true

	elseif command == commandsModule.Comandos.AdminCommands.BanAsync then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local stopPlayerSearchAt = string.find(commandReceived, " ", stopCommandSearchAt + 1) or #commandReceived + 1	
		local stopTimeSearchAt = string.find(commandReceived, " ", stopPlayerSearchAt + 1) or #commandReceived + 1

		local userId = tonumber(string.sub(commandReceived, stopCommandSearchAt + 1, stopPlayerSearchAt - 1))
		if not userId then
			commadErrorEvent:FireClient(plrRunningTheCommand, "No UserId has been passed!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to ban because passed UserId was nil.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		else
			userId = tonumber(userId)
			if not userId then
				commadErrorEvent:FireClient(plrRunningTheCommand, "Passed UserId wasn't a number!")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to ban because passed UserId wasn't a number.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
			if not game:GetService("Players"):GetNameFromUserIdAsync(userId) then
				commadErrorEvent:FireClient(plrRunningTheCommand, "The passed UserId wasn't found in Roblox!")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to ban because passed UserId wasn't found in the Roblox Website.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
		end

		local nameOfPlayerToBan = game:GetService("Players"):GetNameFromUserIdAsync(userId)
		local timeToBanString = string.sub(commandReceived, stopPlayerSearchAt + 1, stopTimeSearchAt - 1)
		local timeToBan
		local unit = string.find(timeToBanString, "s") or string.find(timeToBanString, "min") or string.find(timeToBanString, "h") or string.find(timeToBanString, "d") or string.find(timeToBanString, "m") or string.find(timeToBanString, "y")
		DebugOutput(keywordsDebug.CommandsHandler.."Banning: "..nameOfPlayerToBan.." - "..userId, true)
		DebugOutput(keywordsDebug.CommandsHandler.."TimeToBanString: "..timeToBanString)
		DebugOutput(keywordsDebug.CommandsHandler.."Unit received for ban time: "..string.sub(timeToBanString, unit))
		if timeToBanString == "-1" then
			timeToBan = -1
		else
			local subbedTimeToBan = string.sub(timeToBanString, 1, unit - 1)
						
			timeToBan = convertToSeconds(tonumber(subbedTimeToBan), string.sub(timeToBanString, unit)) 
		end

		if userId == permsModule.PlayersWithPermissions.owner.Id then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You can't ban the owner!")
			DebugOutput(keywordsDebug.CommandsHandler.."Can't ban the owner.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif userId == plrRunningTheCommand.UserId then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You can't ban your own self!")
			DebugOutput(keywordsDebug.CommandsHandler.."Can't ban yourself.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		
		local rankFromPlayerDoingBan = GetPlayerHighestRank(plrRunningTheCommand)
		local rankFromPlayerToBan
		
		for rank, entry in pairs(permsModule.PlayersWithPermissions) do

			for i, plrPerm in entry do
				if plrPerm.Id == userId then
					rankFromPlayerToBan = entry
					break
				end
			end
		end

		if not rankFromPlayerToBan then rankFromPlayerToBan = "player" end
		
		if not IsRankHigherThan(rankFromPlayerDoingBan, rankFromPlayerToBan) then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You don't have permission to ban this person!")
			DebugOutput(
				keywordsDebug.CommandsHandler ..
					"Player " .. plrRunningTheCommand.DisplayName .. 
					" (@" .. plrRunningTheCommand.Name .. 
					") attempted to ban: " .. userId ..
					", but he doesn't have enough permission to ban this user!",
				true
			)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		local configBan = {
			UserIds = { userId },
			ApplyToUniverse = true,
			Duration = timeToBan,
			DisplayReason = string.sub(commandReceived, stopTimeSearchAt + 1),
			PrivateReason = "",
			ExcludeAltAccounts = false
		}

		local successBan, err = pcall(function()
			game:GetService("Players"):BanAsync(configBan)
		end)
		if not successBan then
			for i = 1, permsModule.Values.RetriesOnBanFail do
				successBan, err = pcall(function()
					game:GetService("Players"):BanAsync(configBan)
				end)
				if successBan then break end
				task.wait(0.65)
			end
			commadErrorEvent:FireClient(plrRunningTheCommand, "Failed to Ban because of an Unknown error!")
			warn("Failed to ban because:", err)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		notificationEvent:FireClient(plrRunningTheCommand, "Banned succesfully!", "Succesfully banned the player: "..game:GetService("Players"):GetNameFromUserIdAsync(userId).." ("..userId..")")
		Success = true

	elseif command == commandsModule.Comandos.AdminCommands.Unban then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToUnBanIdOrName = string.sub(commandReceived, stopCommandSearchAt + 1)
		local typeOfUnBanMethod = nil

		if not playerToUnBanIdOrName then
			commadErrorEvent:FireClient(plrRunningTheCommand, "No Name or ID was passed to UnBan!")
			DebugOutput(keywordsDebug.CommandsHandler.."No Name or ID was passed to UnBan: "..commandReceived)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		if tonumber(playerToUnBanIdOrName) then
			typeOfUnBanMethod = "id"
			playerToUnBanIdOrName = tonumber(playerToUnBanIdOrName)
		else
			typeOfUnBanMethod = "name"
		end

		local userIdToUnBan

		if typeOfUnBanMethod == "id" then
			if not game:GetService("Players"):GetNameFromUserIdAsync(playerToUnBanIdOrName) then
				commadErrorEvent:FireClient(plrRunningTheCommand, "The passed UserId wasn't found in Roblox!")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to unban because passed UserId wasn't found in the Roblox Website.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
			userIdToUnBan = playerToUnBanIdOrName
		else
			if not game:GetService("Players"):GetUserIdFromNameAsync(playerToUnBanIdOrName) then
				commadErrorEvent:FireClient(plrRunningTheCommand, "The passed UserId wasn't found in Roblox!")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to unban because passed UserId wasn't found in the Roblox Website.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
			userIdToUnBan = game:GetService("Players"):GetUserIdFromNameAsync(playerToUnBanIdOrName)
		end

		local configBan = {
			UserIds = { userIdToUnBan },
			ApplyToUniverse = true
		}

		local successUnban, err = pcall(function()
			game:GetService("Players"):UnbanAsync(configBan)
		end)
		if not successUnban then
			for i = 1, permsModule.Values.RetriesOnBanFail do
				successUnban, err = pcall(function()
					game:GetService("Players"):UnbanAsync(configBan)
				end)
				if successUnban then break end
				task.wait(0.65)
			end
			if not successUnban then
				commadErrorEvent:FireClient(plrRunningTheCommand, "Failed to UnBan because of an Unknown error!")
				warn("Failed to UnBan because:", err)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
		end
		notificationEvent:FireClient(plrRunningTheCommand, "Unbanned succesfully!","Succesfully unbanned the player: "..game:GetService("Players"):GetNameFromUserIdAsync(userIdToUnBan).." ("..userIdToUnBan..")")
		Success = true

	elseif command == commandsModule.Comandos.AdminCommands.SetRank then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local stoPlayerSearchAt = string.find(commandReceived, " ", stopCommandSearchAt + 1) or #commandReceived + 1

		local playerToSetRank = string.sub(commandReceived, stopCommandSearchAt + 1, stoPlayerSearchAt - 1)
		local rankToUse = string.lower(string.sub(commandReceived, stoPlayerSearchAt + 1)) or nil
		local typeOfSearchMethod = nil

		if not rankToUse then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the rank you want to use! Valid ranks are: 'player', 'vip', 'mod', 'mod+' and 'admin'.")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to find rank to set.")
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		local validRanks = {
			"player",
			"vip",
			"mod",
			"mod+",
			"admin"
		}

		if not table.find(validRanks, rankToUse) then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Invalid rank! Valid ranks are: 'player', 'vip', 'mod', 'mod+' and 'admin'.")
			DebugOutput(keywordsDebug.CommandsHandler.."Invalid rank received.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		if tonumber(playerToSetRank) then
			typeOfSearchMethod = "id"
			playerToSetRank = tonumber(playerToSetRank)
		else
			typeOfSearchMethod = "name"
			local foundPlayer, matchesTable = SearchPlayerByName(plrRunningTheCommand, playerToSetRank, false, false)
			if foundPlayer then
				playerToSetRank = matchesTable[1]
			else
				commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to set rank because player name was spelt wrong or they're not in the same server.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
		end

		local userIdToSetRank
		if typeOfSearchMethod == "id" then
			if not game:GetService("Players"):GetNameFromUserIdAsync(playerToSetRank) then
				commadErrorEvent:FireClient(plrRunningTheCommand, "The passed UserId wasn't found in Roblox!")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to set rank because passed UserId wasn't found in the Roblox Website.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
			userIdToSetRank = playerToSetRank
		elseif typeOfSearchMethod == "name" then
			if not game:GetService("Players"):GetUserIdFromNameAsync(playerToSetRank.Name) then
				commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly.")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to set rank because player name was spelt wrong.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
			userIdToSetRank = game:GetService("Players"):GetUserIdFromNameAsync(playerToSetRank.Name)
		end

		if userIdToSetRank == permsModule.PlayersWithPermissions.owner.Id then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You can't set the rank of the owner!")
			DebugOutput(keywordsDebug.CommandsHandler.."Can't set rank of owner.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif userIdToSetRank == plrRunningTheCommand.UserId then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You can't set your own rank!")
			DebugOutput(keywordsDebug.CommandsHandler.."Can't set rank of yourself.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		
		local plrRunningCommandRank = GetPlayerHighestRank(plrRunningTheCommand)
		local plrToSetRank_Rank

		for rank, entry in pairs(permsModule.PlayersWithPermissions) do

			for i, plrPerm in entry do
				if plrPerm.Id == userIdToSetRank then
					plrToSetRank_Rank = rank
					break
				end
			end

		end

		if not plrToSetRank_Rank then plrToSetRank_Rank = "player" end

		if not IsRankHigherThan(plrRunningCommandRank, plrToSetRank_Rank) then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You don't have permission to set the rank from this person!")
			DebugOutput(
				keywordsDebug.CommandsHandler ..
					"Player " .. plrRunningTheCommand.DisplayName .. 
					" (@" .. plrRunningTheCommand.Name .. 
					") attempted to set rank from: " .. playerToSetRank.Name .. 
					" (" .. userIdToSetRank .. 
					"), but he doesn't have enough permission to set the rank from this user!",
				true
			)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		permsModule:InsertPlayerToPermissions(rankToUse, userIdToSetRank)
		permsModule:SavePermissions()

		if typeOfSearchMethod == "name" then
			DebugOutput(keywordsDebug.CommandsHandler.."Sent notification to: "..playerToSetRank.DisplayName.." (@"..playerToSetRank.Name..").", true)
			rankChangeEvent:FireClient(playerToSetRank, rankToUse)
		end

		local firstLetter = string.upper(string.sub(rankToUse, 1, 1))
		rankToUse = firstLetter .. string.sub(rankToUse, 2)
		notificationEvent:FireClient(plrRunningTheCommand, "Rank Set succesfully!", "The rank: "..rankToUse..", was set succesfully to the player: "..playerToSetRank.DisplayName.." (@"..playerToSetRank.Name..").")
		Success = true

	elseif command == commandsModule.Comandos.AdminCommands.RemoveRank then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToRemoveRank = string.sub(commandReceived, stopCommandSearchAt + 1)
		local typeOfSearchMethod = nil

		if tonumber(playerToRemoveRank) then
			typeOfSearchMethod = "id"
			playerToRemoveRank = tonumber(playerToRemoveRank)
		else
			typeOfSearchMethod = "name"
			local foundPlayer, matchesTable = SearchPlayerByName(plrRunningTheCommand, playerToRemoveRank, false, false)
			if foundPlayer then
				playerToRemoveRank = matchesTable[1]
			else
				commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to set rank because player name was spelt wrong or they're not in the same server.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
		end

		local userIdToRemoveRank
		if typeOfSearchMethod == "id" then
			if not game:GetService("Players"):GetNameFromUserIdAsync(playerToRemoveRank) then
				commadErrorEvent:FireClient(plrRunningTheCommand, "The passed UserId wasn't found in Roblox!")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to remove rank because passed UserId wasn't found in the Roblox Website.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
			userIdToRemoveRank = playerToRemoveRank
		elseif typeOfSearchMethod == "name" then
			if not game:GetService("Players"):GetUserIdFromNameAsync(playerToRemoveRank.Name) then
				commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly.")
				DebugOutput(keywordsDebug.CommandsHandler.."Failed to remove rank because player name was spelt wrong.", true)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
			userIdToRemoveRank = game:GetService("Players"):GetUserIdFromNameAsync(playerToRemoveRank.Name)
		end

		if userIdToRemoveRank == permsModule.PlayersWithPermissions.owner.Id then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You can't remove the rank of the owner!")
			DebugOutput(keywordsDebug.CommandsHandler.."Can't remove rank of owner.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif userIdToRemoveRank == plrRunningTheCommand.UserId then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You can't remove your own rank!")
			DebugOutput(keywordsDebug.CommandsHandler.."Can't remove rank of yourself.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		
		local plrRunningCommandRank = GetPlayerHighestRank(plrRunningTheCommand)
		local plrToRemoveRank_Rank

		for rank, entry in pairs(permsModule.PlayersWithPermissions) do

			for i, plrPerm in entry do
				if plrPerm.Id == userIdToRemoveRank then
					plrToRemoveRank_Rank = rank
					break
				end
			end

		end

		if not plrToRemoveRank_Rank then plrToRemoveRank_Rank = "player" end

		if not IsRankHigherThan(plrRunningCommandRank, plrToRemoveRank_Rank) then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You don't have permission to remove the rank from this person!")
			DebugOutput(
				keywordsDebug.CommandsHandler ..
					"Player " .. plrRunningTheCommand.DisplayName .. 
					" (@" .. plrRunningTheCommand.Name .. 
					") attempted to remove rank from: " .. playerToRemoveRank.Name .. 
					" (" .. userIdToRemoveRank .. 
					"), but he doesn't have enough permission to remove the rank from this user!",
				true
			)	
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		permsModule:RemovePermissions(userIdToRemoveRank)

		if typeOfSearchMethod == "name" then
			DebugOutput(keywordsDebug.CommandsHandler.."Sent notification to: "..playerToRemoveRank.DisplayName.." (@"..playerToRemoveRank.Name..").", true)
			rankChangeEvent:FireClient(playerToRemoveRank, "Player")
		end

		notificationEvent:FireClient(plrRunningTheCommand, "Rank Removed succesfully!", "Rank was succesfully removed from the player: "..playerToRemoveRank.DisplayName.." (@"..playerToRemoveRank.Name..").")
		Success = true

	elseif command == commandsModule.Comandos.AdminCommands.ServerAnnounce then
		local success, filteredMessage = FilterMessage(string.sub(commandReceived, (stopCommandSearchAt or #command) + 1), plrRunningTheCommand)
		if not success then
			commadErrorEvent:FireClient(plrRunningTheCommand, "An error in Roblox's backend ocurred while filtering the message.")
			DebugOutput(keywordsDebug.CommandsHandler.."An error in Roblox's backend ocurred while filtering the message.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		local data = {
			plrRunningTheCommand.DisplayName,
			plrRunningTheCommand.UserId,
			filteredMessage, 
			10
		}
		DarAssetsFolder:WaitForChild("Events"):WaitForChild("Announcement"):FireAllClients(data[1], data[2], data[3], data[4])
		Success = true

	elseif command == commandsModule.Comandos["Mod+Commands"].Freeze then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToFreeze = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToFreeze, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to freeze the player because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			if not player.Character then continue end
			task.spawn(function()
				for i, part in ipairs(player.Character:GetChildren()) do
					if not part:IsA("MeshPart") or not part:IsA("Part") then continue end
					part.Anchored = true
				end
				DebugOutput(keywordsDebug.CommandsHandler.."Froze player: "..player.DisplayName.." (@"..player.Name..").")
			end)
		end
		Success = true

	elseif command == commandsModule.Comandos["Mod+Commands"].Unfreeze then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToFreeze = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToFreeze, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to unfreeze the player because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			if not player.Character then continue end
			task.spawn(function()
				for i, part in ipairs(player.Character:GetChildren()) do
					if not part:IsA("MeshPart") or not part:IsA("Part") then continue end
					part.Anchored = false
				end
				DebugOutput(keywordsDebug.CommandsHandler.."Unfroze player: "..player.DisplayName.." (@"..player.Name..").")
			end)
		end
		Success = true

	elseif command == commandsModule.Comandos["Mod+Commands"].Refresh then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToRefresh = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToRefresh, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to refresh the player because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			if not player.Character then continue end
			task.spawn(function()
				local positionToSpawnAt = player.Character.PrimaryPart.CFrame
				player.Character:WaitForChild("Humanoid").Health = 0
				player.CharacterAdded:Wait()
				player.Character.PrimaryPart.CFrame = positionToSpawnAt
			end)
			DebugOutput(keywordsDebug.CommandsHandler.."Refreshed player: "..player.DisplayName.." (@"..player.Name..").")
		end
		Success = true

	elseif command == commandsModule.Comandos["Mod+Commands"].Invisible then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToInvisible = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToInvisible, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to make the player invisible because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			if not player.Character then continue end
			task.spawn(function()
				for i, part in ipairs(player.Character:GetDescendants()) do
					if DoesInstanceHasTransparencyValue(part) then
						if part.Transparency == 1 then
							table.insert(partsToIgnoreOnInvisible, part)
							continue
						end
						part.Transparency = 1
					end
				end
			end)
			DebugOutput(keywordsDebug.CommandsHandler.."player: "..player.DisplayName.." (@"..player.Name..") was made invisible.")
		end
		Success = true

	elseif command == commandsModule.Comandos["Mod+Commands"].Visible then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToInvisible = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToInvisible, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to make the player visible because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			
			if not player.Character then continue end
			
			task.spawn(function()
				for i, part in ipairs(player.Character:GetDescendants()) do
					if table.find(partsToIgnoreOnInvisible, part) then continue end
					if DoesInstanceHasTransparencyValue(part) then
						part.Transparency = 0
					end
				end
			end)
			
			DebugOutput(keywordsDebug.CommandsHandler.."player: "..player.DisplayName.." (@"..player.Name..") was made visible.")
		end
		Success = true

	elseif command == commandsModule.Comandos.ModCommands.Spectate then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToSpectate = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToSpectate, false, false)
		
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to spectate the player because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		
		for i, player in ipairs(playersTable) do
			DarAssetsFolder:WaitForChild("Events"):WaitForChild("Spectate"):FireClient(plrRunningTheCommand, true, player)
		end
		
		DebugOutput(keywordsDebug.CommandsHandler.."Player: "..plrRunningTheCommand.DisplayName.." (@"..plrRunningTheCommand.Name..") is spectating: "..playersTable[1].DisplayName.." (@"..playersTable[1].Name..").")
		Success = true

	elseif command == commandsModule.Comandos.ModCommands.Unspectate then
		DarAssetsFolder:WaitForChild("Events"):WaitForChild("Spectate"):FireClient(plrRunningTheCommand, false)
		DebugOutput(keywordsDebug.CommandsHandler.."Player: "..plrRunningTheCommand.DisplayName.." (@"..plrRunningTheCommand.Name..") stopped spectating other players.")
		Success = true

	elseif command == commandsModule.Comandos.ModCommands.Kill then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToKill = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToKill, true, true)
		
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to kill the player because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			local char = player.Character
			if not char then continue end
			local hum = char["Humanoid"]
			if not hum then continue end
			hum.Health = 0
		end
		DebugOutput(keywordsDebug.CommandsHandler.."Killed player: "..playersTable[1].DisplayName.." (@"..playersTable[1].Name..").")
		Success = true

	elseif command == commandsModule.Comandos.ModCommands.Explode then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToExplode = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToExplode, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to explode the player because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			local char = player.Character
			if not char then continue end
			local rootPart = char:WaitForChild("HumanoidRootPart") or char:WaitForChild("Torso")
			if not rootPart then continue end
			local newExplosion = Instance.new("Explosion")
			newExplosion.Parent = rootPart
			newExplosion.Position = rootPart.Position
			DebugOutput(keywordsDebug.CommandsHandler.."Exploded player: "..playersTable[1].DisplayName.." (@"..playersTable[1].Name..").")
		end
		Success = true

	elseif command == commandsModule.Comandos.ModCommands.FF then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToFF = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToFF, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to make the player unable to receive to damage because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			local char = player.Character
			if not char then continue end
			for i, descendant in ipairs(char:GetDescendants()) do
				if descendant:IsA("ForceField") then return end
			end
			local newForcefield = Instance.new("ForceField")
			newForcefield.Parent = char
			DebugOutput(keywordsDebug.CommandsHandler.."Made player: "..player.DisplayName.." (@"..player.Name..") unable to receive damage.")
		end
		Success = true

	elseif command == commandsModule.Comandos.ModCommands.UnFF then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local playerToUnFF = string.sub(commandReceived, stopCommandSearchAt + 1)
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToUnFF, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to make the player able to receive to damage because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			local char = player.Character
			if not char then continue end
			for i, descendant in ipairs(char:GetDescendants()) do
				if descendant:IsA("ForceField") then
					descendant:Destroy()
					DebugOutput(keywordsDebug.CommandsHandler.."Made player: "..player.DisplayName.." (@"..player.Name..") able to receive damage.")
				end
			end
		end
		Success = true

	elseif command == commandsModule.Comandos.ModCommands.Speed then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local stopPlayerSearchAt = string.find(commandReceived, " ", stopCommandSearchAt + 1) or #commandReceived + 1
		local playerToChangeSpeed = string.sub(commandReceived, stopCommandSearchAt + 1, stopPlayerSearchAt - 1)
		local speedToSet = string.lower(string.sub(commandReceived, stopPlayerSearchAt + 1)) or 16
		if speedToSet == "" then
			speedToSet = 16
		end
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToChangeSpeed, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to change the player's speed because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		if not tonumber(speedToSet) then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You didn't enter a number!")
			DebugOutput(keywordsDebug.CommandsHandler.."Player entered a non-number value.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			local char = player.Character
			if not char then continue end
			local hum = char:WaitForChild("Humanoid")
			hum.WalkSpeed = tonumber(speedToSet)
			DebugOutput(keywordsDebug.CommandsHandler.."Set player: "..player.DisplayName.." (@"..player.Name..") speed to: "..speedToSet)
		end
		Success = true
		
	elseif command == commandsModule.Comandos.ModCommands.Jump then

		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local stopPlayerSearchAt = string.find(commandReceived, " ", stopCommandSearchAt + 1) or #commandReceived + 1
		local playerToChangeJump = string.sub(commandReceived, stopCommandSearchAt + 1, stopPlayerSearchAt - 1)
		local jumpToSet = string.lower(string.sub(commandReceived, stopPlayerSearchAt + 1)) or 16

		if jumpToSet == "" then
			jumpToSet = 50
		end

		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToChangeJump, true, true)
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to change the player's speed because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		if not tonumber(jumpToSet) then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You didn't enter a number!")
			DebugOutput(keywordsDebug.CommandsHandler.."Player entered a non-number value.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		for i, player in ipairs(playersTable) do
			local char = player.Character
			if not char then continue end
			local hum: Humanoid = char:WaitForChild("Humanoid")

			if hum.UseJumpPower then
				hum.JumpPower = jumpToSet
			else
				hum.JumpHeight = (jumpToSet ^ 2) / (2 * workspace.Gravity)
			end

			DebugOutput(keywordsDebug.CommandsHandler.."Set player: "..player.DisplayName.." (@"..player.Name..") jump to: "..if hum.UseJumpPower then jumpToSet else ((jumpToSet ^ 2) / (2 * workspace.Gravity)))
		end
		Success = true

	elseif command == commandsModule.Comandos.ModCommands.Kick then
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local stopPlayerSearchAt = string.find(commandReceived, " ", stopCommandSearchAt + 1) or #commandReceived + 1

		local playerToKick = string.sub(commandReceived, stopCommandSearchAt + 1, stopPlayerSearchAt - 1)
		local reasonForKick = string.sub(commandReceived, stopPlayerSearchAt + 1)

		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToKick, false, false)

		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to kick because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif playersTable[1].UserId == permsModule.PlayersWithPermissions.owner.Id then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You can't kick the owner!")
			DebugOutput(keywordsDebug.CommandsHandler.."Can't kick the owner.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif playersTable[1].UserId == plrRunningTheCommand.UserId then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You can't kick your own self!")
			DebugOutput(keywordsDebug.CommandsHandler.."Can't kick yourself.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		
		for i, plrBeingKicked in playersTable do
			
			local rankFromPlayerDoingKick = GetPlayerHighestRank(plrRunningTheCommand)
			local rankFromPlayerToKick

			for rank, entry in pairs(permsModule.PlayersWithPermissions) do

				for i, plrPerm in pairs(entry) do

					if plrPerm.Id == plrBeingKicked.UserId then
						rankFromPlayerToKick = rank
						break
					end

				end

			end

			if not rankFromPlayerToKick then rankFromPlayerToKick = "player" end
			
			print("rank from player 1: "..rankFromPlayerDoingKick)
			print("rank from player 2: "..rankFromPlayerToKick)

			if not IsRankHigherThan(rankFromPlayerDoingKick, rankFromPlayerToKick) then
				commadErrorEvent:FireClient(plrRunningTheCommand, "You don't have permission to kick this person!")
				DebugOutput(
					keywordsDebug.CommandsHandler ..
						"Player " .. plrRunningTheCommand.DisplayName .. 
						" (@" .. plrRunningTheCommand.Name .. 
						") attempted to kick: " .. plrBeingKicked.DisplayName .. 
						" (@" .. plrBeingKicked.Name .. 
						"), but he doesn't have enough permission to kick this user!",
					true
				)
				Success = false
				LogCommand(plrRunningTheCommand, commandReceived, Success)
				return
			end
			
			plrBeingKicked:Kick("You were kicked from the game by a "..rankFromPlayerDoingKick..". Kick reason: "..reasonForKick)
		end
		Success = true
		
	elseif command == commandsModule.Comandos.ModCommands.Goto then
		
		local playerToGoToName = string.sub(commandReceived, stopCommandSearchAt + 1)

		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToGoToName, false, false)

		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to kick because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif playersTable[1].UserId == plrRunningTheCommand.UserId then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You can't teleport to your own self!")
			DebugOutput(keywordsDebug.CommandsHandler.."Can't teleport to yourself.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		
		for i, plr in playersTable do
			local plrChar = plrRunningTheCommand.Character or plrRunningTheCommand.CharacterAdded:Wait()
			local tpChar = plr.Character or plr.CharacterAdded:Wait()

			local plrRoot
			local tpRoot

			if CheckRigType(plrChar) == "R6" then
				plrRoot = plrChar:FindFirstChild("Torso")
			else
				plrRoot = plrChar:FindFirstChild("HumanoidRootPart")
			end

			if CheckRigType(tpChar) == "R6" then
				tpRoot = tpChar:FindFirstChild("Torso")
			else
				tpRoot = tpChar:FindFirstChild("HumanoidRootPart")
			end

			plrRoot.CFrame = tpRoot.CFrame
		end
		
		Success = true
		
	elseif command == commandsModule.Comandos.ModCommands.Bring then
		
		local playerToBringName = string.sub(commandReceived, stopCommandSearchAt + 1)

		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToBringName, false, true)

		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to kick because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		for i, plr in playersTable do
			
			if plr == plrRunningTheCommand.UserId then
				if #playersTable < 2 then
					commadErrorEvent:FireClient(plrRunningTheCommand, "You can't bring your own self!")
					DebugOutput(keywordsDebug.CommandsHandler.."Can't bring yourself.", true)
					Success = false
					LogCommand(plrRunningTheCommand, commandReceived, Success)
					return
				else
					continue
				end
			end
			
			local plrChar = plrRunningTheCommand.Character or plrRunningTheCommand.CharacterAdded:Wait()
			local tpChar = plr.Character or plr.CharacterAdded:Wait()

			local plrRoot
			local tpRoot

			if CheckRigType(plrChar) == "R6" then
				plrRoot = plrChar:FindFirstChild("Torso")
			else
				plrRoot = plrChar:FindFirstChild("HumanoidRootPart")
			end

			if CheckRigType(tpChar) == "R6" then
				tpRoot = tpChar:FindFirstChild("Torso")
			else
				tpRoot = tpChar:FindFirstChild("HumanoidRootPart")
			end

			tpRoot.CFrame = plrRoot.CFrame
		end
		
		Success = true
		
	elseif command == commandsModule.Comandos.ModCommands.Mark then
		
		local playerToMark = string.sub(commandReceived, stopCommandSearchAt + 1)

		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToMark, true, true)

		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to kick because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		for i, plr in playersTable do
			local char = plr.Character or plr.CharacterAdded:Wait()
			local newHighlight = Instance.new("Highlight", char)
			newHighlight:AddTag("Dar's Admin Highlight")
			newHighlight.FillTransparency = 1
			newHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
			newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		end
		
		Success = true
		
	elseif command == commandsModule.Comandos.ModCommands.UnMark then
		
		local playerToUnMark = string.sub(commandReceived, stopCommandSearchAt + 1)

		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToUnMark, true, true)

		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to kick because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		for i, plr in playersTable do
			local char = plr.Character or plr.CharacterAdded:Wait()
			
			for i, part: Instance in char:GetDescendants() do
				if part:HasTag("Dar's Admin Highlight") then
					part:Destroy()
				end
			end
		end
		Success = true
		
	elseif command == commandsModule.Comandos.ModCommands.BlindnessDuration then
		
		local newDuration = string.sub(commandReceived, stopCommandSearchAt + 1)

		if not tonumber(newDuration) then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You didn't provide a number!")
			DebugOutput(keywordsDebug.CommandsHandler.."You didn't provide a number!", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif tonumber(newDuration) > 100 then
			commadErrorEvent:FireClient(plrRunningTheCommand, "The maximum duration is 100 seconds!")
			DebugOutput(keywordsDebug.CommandsHandler.."The maximum duration is 100 seconds!", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif tonumber(newDuration) < 5 then
			commadErrorEvent:FireClient(plrRunningTheCommand, "The minimum duration is 5 seconds!")
			DebugOutput(keywordsDebug.CommandsHandler.."The minimum duration is 5 seconds!", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		Success = true
		commandsModule.CommandSettings.BlindnessDuration = tonumber(newDuration)
		notificationEvent:FireClient(plrRunningTheCommand, "Information", "Succesfully set the blidness duration to: "..newDuration..".", 10)

	elseif command == commandsModule.Comandos.ModCommands.HealCooldown then
		
		local newDuration = string.sub(commandReceived, stopCommandSearchAt + 1)

		if not tonumber(newDuration) then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You didn't provide a number!")
			DebugOutput(keywordsDebug.CommandsHandler.."You didn't provide a number!", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif tonumber(newDuration) > 100 then
			commadErrorEvent:FireClient(plrRunningTheCommand, "The maximum duration is 100 seconds!")
			DebugOutput(keywordsDebug.CommandsHandler.."The maximum duration is 100 seconds!", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif tonumber(newDuration) < 5 then
			commadErrorEvent:FireClient(plrRunningTheCommand, "The minimum duration is 5 seconds!")
			DebugOutput(keywordsDebug.CommandsHandler.."The minimum duration is 5 seconds!", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end

		Success = true
		commandsModule.CommandSettings.HealCooldown = tonumber(newDuration)
		notificationEvent:FireClient(plrRunningTheCommand, "Information", "Succesfully set the heal cooldown to: "..newDuration..".", 10)

	elseif command == commandsModule.Comandos.ModCommands.ToggleVipCommands then
		
		if vipToggleDb then
			commadErrorEvent:FireClient(plrRunningTheCommand, "This command is on cooldown! Try again later.")
			DebugOutput(keywordsDebug.CommandsHandler.."This command is on cooldown. Try again later.")
			Success = false
			return
		end
		
		vipToggleDb = true
		
		commandsModule.CommandSettings.VIPCommandsEnabled = not commandsModule.CommandSettings.VIPCommandsEnabled
		notificationEvent:FireClient(plrRunningTheCommand, "Information", "Succesfully changed VIP Commands to be: ".. if commandsModule.CommandSettings.VIPCommandsEnabled then "enabled." else "disabled.", 10)
		Success = true
		
		task.spawn(function()
			task.wait(3)
			vipToggleDb = false
			return
		end)
		
	elseif command == commandsModule.Comandos.VipCommands.Blindness then
		
		if not AreVipCommandsEnabled(true, plrRunningTheCommand, commandReceived, vipCommandsError) then
			logCommand = false
			return
		end
				
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local stopPlayerSearchAt = string.find(commandReceived, " ", stopCommandSearchAt + 1) or #commandReceived + 1
		
		local plrToBlind = string.sub(commandReceived, stopCommandSearchAt + 1, stopPlayerSearchAt - 1)
		local blindType = string.sub(commandReceived, stopPlayerSearchAt + 1)
				
		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, plrToBlind, true, true)
		
		if not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to kick because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		
		local validType = false
		
		for i, types in blindModule.BlindTypes do
			if string.lower(blindType) == types then
				validType = true
				break
			end
		end
		
		if not validType then
			
			local typeList = {}
			
			for i, typeValue in pairs(blindModule.BlindTypes) do
				table.insert(typeList, typeValue)
			end
						
			commadErrorEvent:FireClient(plrRunningTheCommand, "Invalid blind type! These are the valid types: "..table.concat(typeList, ", "))
			DebugOutput(keywordsDebug.CommandsHandler.."Invalid blind type.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		
		for i, plr in playersTable do
			eventsFolder:WaitForChild("Blind"):FireClient(plr, blindType, commandsModule.CommandSettings.BlindnessDuration)
		end
		
		Success = true
		
	elseif command == commandsModule.Comandos.VipCommands.Heal then
		
		if not AreVipCommandsEnabled(true, plrRunningTheCommand, commandReceived, vipCommandsError) then
			logCommand = false
			return
		end
		
		local stopCommandSearchAt = string.find(commandReceived, " ") or #commandReceived + 1
		local stopPlayerSearchAt = string.find(commandReceived, " ", stopCommandSearchAt + 1) or #commandReceived + 1

		local playerToHeal = string.sub(commandReceived, stopCommandSearchAt + 1, stopPlayerSearchAt - 1)
		local healAmount = string.sub(commandReceived, stopPlayerSearchAt + 1)
		healAmount = tonumber(healAmount) or healAmount

		local foundPlayer, playersTable = SearchPlayerByName(plrRunningTheCommand, playerToHeal, true, false)
		
		if playerToHeal == "all" then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You are not allowed to use heal on all players at the same time!")
			DebugOutput(keywordsDebug.CommandsHandler.."Heal can not be used on all players at the same time.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif not foundPlayer then
			commadErrorEvent:FireClient(plrRunningTheCommand, "Couldn't find the player! Make sure you've spelt the name correctly and that you're in the same server!")
			DebugOutput(keywordsDebug.CommandsHandler.."Failed to kick because player name was spelt wrong or they're not in the same server.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif table.find(healDebounces, plrRunningTheCommand.UserId) then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You are on cooldown!")
			DebugOutput(keywordsDebug.CommandsHandler.."You are on cooldown!", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif typeof(healAmount) ~= "number" then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You didn't enter a valid number!")
			DebugOutput(keywordsDebug.CommandsHandler.."Not a valid number.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		elseif healAmount > commandsModule.CommandSettings.HealLimit then
			commadErrorEvent:FireClient(plrRunningTheCommand, "You tried to heal the player to more than the limit!")
			DebugOutput(keywordsDebug.CommandsHandler.."Tried to heal the player to more than the limit.", true)
			Success = false
			LogCommand(plrRunningTheCommand, commandReceived, Success)
			return
		end
		
		task.spawn(function()
			table.insert(healDebounces, plrRunningTheCommand.UserId)
			task.wait(commandsModule.CommandSettings.HealCooldown)
			table.remove(healDebounces, table.find(healDebounces, plrRunningTheCommand.UserId))
		end)
		
		for i, plr in playersTable do
			local char = plr.Character
			if not char then return end
			
			local hum: Humanoid = char:WaitForChild("Humanoid")
			if not hum then return end
			
			notificationEvent:FireClient(plrRunningTheCommand, "Information", "Succesfully healed the player: "..playersTable[1].DisplayName.." (@"..playersTable[1].Name..") with "..healAmount.." of life.", 10)
			hum.Health += healAmount
		end
		
		Success = true
		
	elseif command == commandsModule.Comandos.PlayerCommands.Logs then
		
		Success = true
		logCommand = false
		eventsFolder:WaitForChild("ToggleCommandLogs"):FireClient(plrRunningTheCommand)
		
	elseif command == commandsModule.Comandos.PlayerCommands.Help then
		
		Success = true
		logCommand = false
		eventsFolder:WaitForChild("HelpCommand"):FireClient(plrRunningTheCommand)
		
	end
	
	if nonExistingCommand == nil and logCommand then
		LogCommand(plrRunningTheCommand, commandReceived, Success)
	end
end


commandEvent.OnServerEvent:Connect(RunCommand)

---------- Mega Announcements Handler ----------

local messagingService = game:GetService("MessagingService")

messagingService:SubscribeAsync("MegaAnnouncement", function(data)
	DarAssetsFolder:WaitForChild("Events"):WaitForChild("Announcement"):FireAllClients(data.Data[1], data.Data[2], data.Data[3], data.Data[4])
end)

messagingService:SubscribeAsync("MegaShutdown", function()
	while task.wait(0.1) do
		
		for i, player in game:GetService("Players"):GetPlayers() do
			local success, err = pcall(function()
				player:Kick("Game shutdown by owner.")
			end)
		end
				
	end
end)

---------- Players Perms Requests ----------

eventsFolder:WaitForChild("GetPlayersPerms").OnServerInvoke = function()
	return permsModule.PlayersWithPermissions
end
