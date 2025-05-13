local m = {}

m.Values = {
	RetriesOnDataFail = 5,
	RetriesOnUserSearchFail = 2,
	output = if game:GetService("RunService"):IsClient() then false else true, -- Initiates as false on clients, and true on server, can be changed as you please.
	LoadedConfiguration = false,
	RetriesOnBanFail = 5,
}

local function Debug(message, typeOfDebug)
	if m.Values.output then
		if not typeOfDebug then
			print(message)
		else
			warn(message)
		end
	end
end

local function GetGameOwner()
	Debug("[Debug - GetGameOwner] Attempting to retrieve game owner information.")
	local marketplace = game:GetService("MarketplaceService")

	local success, info = pcall(function()
		return marketplace:GetProductInfo(game.PlaceId).Creator
	end)

	if not success or not info then
		if info and string.find(info, "0 is not a valid assetId") then
			Debug("[Debug - GetGameOwner] Game not published on Roblox. Please, upload the game so Dar's Admin can run correctly.", true)
			return nil
		end
		Debug("[Debug - GetGameOwner] Failed to retrieve game owner information. Error: " .. tostring(info), true)
		return nil
	end

	Debug("[Debug - GetGameOwner] Successfully retrieved game owner information.")

	if info.CreatorType == "Group" then
		
		local groupService = game:GetService("GroupService")
		local groupInfo = groupService:GetGroupInfoAsync(info.CreatorTargetId)

		return {
			ownerType = Enum.CreatorType.Group,
			id = groupInfo.Owner.Id,
			name = groupInfo.Owner.Name
		}
	else
		return {
			ownerType = Enum.CreatorType.User,
			id = info.Id,
			name = info.Name
		}
	end
end

m.PlayersWithPermissions = {
	["owner"] = {
		{
			["Name"] = GetGameOwner().name or nil,
			["Id"] = GetGameOwner().id or nil
		},

		{
			["Name"] = "Player1",
			["Id"] = -1
		},
	},
	["admin"] = {

	},
	["mod+"] = {

	},
	["mod"] = {

	},
	["vip"] = {

	},
	["player"] = {

	},
}

function m.StudioAccessDataStore()
	local dataStore = game:GetService("DataStoreService")

	local success, err = pcall(function()
		dataStore:GetDataStore("DataStoreAccess"):GetAsync("keykeykeykey")
	end)

	if success then
		return true
	else
		return false, err
	end
end

local rolePriority = {
	["owner"] = 1,
	["admin"] = 2,
	["mod"] = 3,
	["mod+"] = 4,
	["vip"] = 5,
	["player"] = 6,
}

local essentialRoles = {
	owner = true,
	admin = true,
	mod = true,
	["mod+"] = true,
	vip = true,
	player = true,
}

-- for some reason i struggled a lot to do this
function m:CleanAndConsolidatePermissions()
	local bestEntry = {}
	local duplicates = {}

	for role, entries in pairs(self.PlayersWithPermissions) do
		
		for i = #entries, 1, -1 do
			local entry = entries[i]
			
			if not next(entry) then
				table.remove(entries, i)
			else
				local userKey = entry.Id or entry.Name
				
				if userKey then
					local entryPriority = rolePriority[string.lower(role)] or math.huge
					
					if not bestEntry[userKey] then
						bestEntry[userKey] = { role = role, index = i, priority = entryPriority }
					else
						
						if entryPriority < bestEntry[userKey].priority then
							table.insert(duplicates, { role = bestEntry[userKey].role, index = bestEntry[userKey].index })
							bestEntry[userKey] = { role = role, index = i, priority = entryPriority }
						else
							table.insert(duplicates, { role = role, index = i })
						end
						
					end
				end
			end
		end
	end

	table.sort(duplicates, function(a, b)
		if a.role == b.role then
			return a.index > b.index
		else
			return a.role < b.role
		end
	end)

	for _, info in ipairs(duplicates) do
		local roleEntries = self.PlayersWithPermissions[info.role]
		if roleEntries then
			table.remove(roleEntries, info.index)
		end
	end

	for role, entries in pairs(self.PlayersWithPermissions) do
		if not next(entries) and not essentialRoles[string.lower(role)] then
			self.PlayersWithPermissions[role] = nil
		end
	end

	Debug("[Debug - CleanAndConsolidatePermissions] Finished cleaning permissions.")
end

--[[Saves the permissions table. This function runs automatically whenever the permissions are changed.]]
function m:SavePermissions()
	if not m.StudioAccessDataStore() then
		Debug("[Debug - Permission Save] Attempted to save data but Studio doesn't have access to DataStore! Make sure 'Enable Studio Access to API Services' is checked in your game settings. ", true)
		return false, "Studio doesn't have access to DataStore!"
	end

	m:CleanAndConsolidatePermissions()

	local debugKeyword = "[Debug - Permission Save] "
	Debug(debugKeyword .. "Starting permissions saving.")

	local dataStore = game:GetService("DataStoreService")
	local darsAdminPerms = dataStore:GetDataStore("darsAdminPerms")

	local success, err = pcall(function()
		darsAdminPerms:SetAsync("darsAdminServer", m.PlayersWithPermissions)
	end)

	if success then 
		Debug(debugKeyword .. "Successfully saved permissions.")
		return true
	end

	for i = 1, m.Values.RetriesOnDataFail do
		Debug(debugKeyword .. "Retry attempt " .. i .. " to save permissions.")
		success, err = pcall(function()
			darsAdminPerms:SetAsync("darsAdminServer", m.PlayersWithPermissions)
		end)

		if success then
			Debug(debugKeyword .. "Successfully saved permissions after " .. (i == 1 and "1 retry." or i .. " retries."))
			return true 
		end

		task.wait(1)
	end

	Debug(debugKeyword .. "Failed to save permissions. Error: " .. tostring(err), true)
	return false, err
end

--[[Loads the permissions table. This function runs automatically when the server is started.]]
function m:LoadPermissions()
	if not m.StudioAccessDataStore() then
		Debug("[Debug - Permissions Loading] Attempted to load data but Studio doesn't have access to DataStore! Make sure 'Enable Studio Access to API Services' is checked in your game settings. ", true)
		return false, "Studio doesn't have access to DataStore!"
	end

	local debugKeyword = "[Debug - Permissions Loading] "
	Debug(debugKeyword .. "Starting permissions load.")

	local dataStore = game:GetService("DataStoreService")
	local darsAdminPerms = dataStore:GetDataStore("darsAdminPerms")

	local success, resultOrErr = pcall(function()
		return darsAdminPerms:GetAsync("darsAdminServer")
	end)

	if success and resultOrErr then
		m.PlayersWithPermissions = resultOrErr
		Debug(debugKeyword .. "Successfully loaded permissions.")
		return true
	end

	if resultOrErr == nil then 
		Debug(debugKeyword .. "No data found for permissions. Initializing with default permissions.", true)
		return false, "No data"
	end

	for i = 1, m.Values.RetriesOnDataFail do
		Debug(debugKeyword .. "Retry attempt " .. i .. " to load permissions.")
		success, resultOrErr = pcall(function()
			return darsAdminPerms:GetAsync("darsAdminServer")
		end)

		if success and resultOrErr then
			m.PlayersWithPermissions = resultOrErr
			print(resultOrErr)
			Debug(debugKeyword .. "Successfully loaded permissions after " .. (i == 1 and "1 retry." or i .. " retries."))
			return true
		end

		Debug(debugKeyword .. "Retry attempt " .. i .. " failed. Error: " .. tostring(resultOrErr), true)
		task.wait(1)
	end

	Debug(debugKeyword .. "Failed to load permissions after all retries.", true)
	return false, resultOrErr
end

--[[Removes a player from the permissions table.

<strong>userIdOrName:</strong> The Id or the Username of the player to remove.]]
function m:RemovePermissions(userIdOrName: number?)
	Debug("[Debug - Remove Permissions] Starting removal for user: " .. tostring(userIdOrName))

	if userIdOrName == nil then
		Debug("[Debug - Remove Permissions] Provided user id or name is nil.", true)
		return false, "Provided user id or name is nil"
	end

	local isId = false
	local userId, userName

	if type(userIdOrName) == "number" or tonumber(userIdOrName) then
		isId = true
		userId = tonumber(userIdOrName)
	else
		userName = tostring(userIdOrName)
	end

	local removed = false

	for role, players in pairs(self.PlayersWithPermissions) do
		for i = #players, 1, -1 do
			local entry = players[i]
			if isId and entry.Id == userId then
				table.clear(entry)
				removed = true
			end
		end
	end

	if removed then
		Debug("[Debug - Remove Permissions] Successfully removed permissions for user: " .. tostring(userIdOrName))
	else
		Debug("[Debug - Remove Permissions] No permissions found for user: " .. tostring(userIdOrName), true)
	end

	-- Insert the user into the "player" permission.
	local PlayersService = game:GetService("Players")
	local dataToInsert = {Name = nil, Id = nil}

	if tonumber(userIdOrName) then
		local success, result = pcall(function()
			dataToInsert.Name = PlayersService:GetNameFromUserIdAsync(userIdOrName)
			dataToInsert.Id = userIdOrName
		end)
		if not success then
			Debug("[Debug - Remove Permissions] Failed to get name from user ID: " .. tostring(result), true)
		end
	else
		local success, result = pcall(function()
			dataToInsert.Id = PlayersService:GetUserIdFromNameAsync(userIdOrName)
			dataToInsert.Name = userIdOrName
		end)
		if not success then
			Debug("[Debug - Remove Permissions] Failed to get user ID from name: " .. tostring(result), true)
		end
	end

	table.insert(self.PlayersWithPermissions.player, dataToInsert)
	Debug("[Debug - Remove Permissions] Inserted user into 'player' role with Name: " .. tostring(dataToInsert.Name) .. " and ID: " .. tostring(dataToInsert.Id))
	m:SavePermissions()
	return removed
end

--[[Inserts a player in the permissions table.

<strong>perm:</strong> The permission to place the player at.
<strong>userIdOrName:</strong> The Id or the Username of the player to insert.]]
function m:InsertPlayerToPermissions(perm: string, userIdOrName: number?)
	local debugKeyword = "[Debug - Player Inserting in Permissions] "
	Debug(debugKeyword .. "Initializing insertion for permission: " .. perm .. " with user: " .. tostring(userIdOrName))

	local players = game:GetService("Players")

	if not m.PlayersWithPermissions[string.lower(perm)] then
		Debug(debugKeyword .. "Failed to insert player, the requested permission position wasn't found! | " .. perm, true)
		return false
	end

	local dataToInsert = {
		["Name"] = nil,
		["Id"] = nil
	}

	if tonumber(userIdOrName) then
		local id
		local name

		local success, err = pcall(function()
			name = players:GetNameFromUserIdAsync(userIdOrName)
			id = userIdOrName
		end)

		if not success then
			Debug(debugKeyword .. "Initial attempt to retrieve name from user ID failed. Error: " .. tostring(err), true)
			for i = 1, m.Values.RetriesOnUserSearchFail do
				Debug(debugKeyword .. "Retry attempt " .. i .. " for getting name from user ID.")
				success, err = pcall(function()	
					name = players:GetNameFromUserIdAsync(userIdOrName)
					id = userIdOrName
					Debug(debugKeyword .. "Data Retrieved: " .. name .. " - " .. tostring(id))
				end)
				if success then
					break
				end
			end

			if not success then
				Debug(debugKeyword .. "Failed to find player Name after retries. Error: " .. tostring(err), true)
			end
		end

		dataToInsert.Name = name
		dataToInsert.Id = id
	else
		local id
		local name

		local success, err = pcall(function()
			id = players:GetUserIdFromNameAsync(userIdOrName)
			name = userIdOrName
		end)

		if not success then
			Debug(debugKeyword .. "Initial attempt to retrieve user ID from name failed. Error: " .. tostring(err), true)
			for i = 1, m.Values.RetriesOnUserSearchFail do
				Debug(debugKeyword .. "Retry attempt " .. i .. " for getting user ID from name.")
				success, err = pcall(function()
					id = players:GetUserIdFromNameAsync(userIdOrName)
					name = userIdOrName
				end)
				if success then
					break
				end
			end

			if not success then
				Debug(debugKeyword .. "Failed to find player ID after retries. Error: " .. tostring(err), true)
			end
		end

		dataToInsert.Name = name
		dataToInsert.Id = id
	end

	m:RemovePermissions(dataToInsert.Id)

	for i, Table in self.PlayersWithPermissions do
		if Table.Id == dataToInsert.Id then
			table.clear(Table)
		end
	end

	table.insert(m.PlayersWithPermissions[string.lower(perm)], dataToInsert)
	Debug(debugKeyword .. "Player successfully inserted with Name: " .. tostring(dataToInsert.Name) .. " and ID: " .. tostring(dataToInsert.Id))
	return true
end

--[[Returns the rank of a player based on their User Id.]]
function m:GetPlayerRank(plrUserId: number)
	if not plrUserId then 
		return nil 
	end

	local bestRank = "player"
	local bestPriority = rolePriority["player"] or math.huge

	for role, entries in pairs(self.PlayersWithPermissions) do
		for i, entry in ipairs(entries) do
			
			if entry.Id == plrUserId then
				
				local currentPriority = rolePriority[string.lower(role)] or math.huge
				
				if currentPriority < bestPriority then
					bestPriority = currentPriority
					bestRank = role
				end
			end
		end
	end

	return bestRank
end

--[[<strong>This is a dangerous function that can cause multiple issues in the game, it should only be called if absolutely necessary, such as permissions critically bugging.</strong>

Completely wipes all permissions and sets them to a fresh start.]]
function m:ResetPermissions()
	
	local runServ = game:GetService("RunService")
	
	if not runServ:IsServer() then
		error("[Dar's Admin - Reset Permissions] This function can only be ran from the server!", -1)
		return
	end
	
	local debugKeyword = "[Debug - Permissions Reset] "
	
	m.PlayersWithPermissions = {
		["owner"] = {
			{
				["Name"] = GetGameOwner().name or nil,
				["Id"] = GetGameOwner().id or nil
			},

			{
				["Name"] = "Player1",
				["Id"] = -1
			},
		},
		["admin"] = {

		},
		["mod+"] = {

		},
		["mod"] = {

		},
		["vip"] = {

		},
		["player"] = {

		},
	}
	
	m:SavePermissions()
	
	Debug(debugKeyword.."Finished permissions resetting, new permissions:", true)
	Debug(m.PlayersWithPermissions, true)
	
	return
end

--[[Toggles debug mode in the output for bug tracking or bug fixing.]]
function m:ToggleDebugMode(toggle: boolean)
	if type(toggle) ~= "boolean" then error("Insert a valid debug mode!") return end
	m.Values.output = toggle
	Debug("Debug mode is now " .. if toggle then "On." else "Off.")
end

return m
