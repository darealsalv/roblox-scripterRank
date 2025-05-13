local m = {}

local assetsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Dar's Admin - Assets")
local gameDescendants = game:GetDescendants()
local modulesFolder = script.Parent.Parent
local dependenciesFolder = modulesFolder.Parent:WaitForChild("Dependencies")
local permissionsModule = require(modulesFolder:WaitForChild("Server&Client"):WaitForChild("Permissions"))

local function DebugOutput(msg: string, typeOfDebug)
	if permissionsModule.Values.output then
		if not typeOfDebug then
			print(msg)
		else
			warn(msg)
		end
	end
end

local function hasPermission(permissionList, plr)
	for i, userData in pairs(permissionList) do
		if userData.Id == plr.UserId or userData.Name == plr.Name then
			return true
		end
	end
	
	return false
end

--[[Checks if a player is a moderator.

<strong>plr:</strong> The player to check.]]
function m.IsPlayerMod(plr: Player)
	local perms = permissionsModule.PlayersWithPermissions
	print()

	if hasPermission(perms.owner, plr) then return true end
	if hasPermission(perms.admin, plr) then return true end
	if hasPermission(perms["mod+"], plr) then return true end
	if hasPermission(perms.mod, plr) then return true end
	
	return false
end

--[[Returns wether a player is or isn't the rank specified.

<strong>plr:</strong> The player to identify.
<strong>rankToSearch:</strong> The rank to search for.]]
function m:IsPlayerSpecificRank(plr: Player, rankToSearch: string)
	local hasRank = false
	
	if string.lower(rankToSearch) == "player" then
		hasRank = hasPermission(permissionsModule.PlayersWithPermissions.player, plr)
	elseif string.lower(rankToSearch) == "vip" then
		hasRank = hasPermission(permissionsModule.PlayersWithPermissions.vip, plr)
	elseif string.lower(rankToSearch) == "mod" then
		hasRank = hasPermission(permissionsModule.PlayersWithPermissions.mod, plr)
	elseif string.lower(rankToSearch) == "mod+" then
		hasRank = hasPermission(permissionsModule.PlayersWithPermissions["mod+"], plr)
	elseif string.lower(rankToSearch) == "admin" then
		hasRank = hasPermission(permissionsModule.PlayersWithPermissions.admin, plr)
	elseif string.lower(rankToSearch) == "owner" then
		hasRank = hasPermission(permissionsModule.PlayersWithPermissions.owner, plr)
	end
	
	return hasRank
end

--[[Sends a message to the moderator chat.

<strong>plr:</strong> The player that sent the message.
<strong>msg:</strong> The message sent.]]
function m:SendMessage(plr: Player, filteredMessage: string)
	local newModMessage: RemoteEvent = assetsFolder:WaitForChild("Events"):WaitForChild("NewModMessage")
	
	for i, player in game:GetService("Players"):GetPlayers() do
		if m.IsPlayerMod(player) then
			newModMessage:FireClient(player, filteredMessage, plr)
		end
	end
end

local totalMessages = 0

--[[Loads a new message in the mod chat.

<strong>msg:</strong> The message sent.
<strong>playerThatSentTheMessage:</strong> The player that sent the message.]]
function m:CreateNewMessage(msg: string, playerThatSentTheMessage: Player)
	if not msg or not playerThatSentTheMessage then return end
	
	-- I was lazy to type this in a way that's easy to understand
	local privateChatMessagesZone = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("AdminGui"):WaitForChild("PanelZone"):WaitForChild("Background"):WaitForChild("PrivateChat"):WaitForChild("ChatZone")
	local sampleMessage = assetsFolder:WaitForChild("Dependencies"):WaitForChild("MessageSample")
	
	local newMessage = sampleMessage:Clone()
	newMessage:WaitForChild("PlayerName").Text = playerThatSentTheMessage.DisplayName.." (@"..playerThatSentTheMessage.Name..")"
	newMessage:WaitForChild("Message").Text = msg
	newMessage:WaitForChild("PlayerAvatar").Image = game.Players:GetUserThumbnailAsync(playerThatSentTheMessage.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) or "rbxassetid://80561752894061"
	newMessage.Parent = privateChatMessagesZone
	newMessage.Name = playerThatSentTheMessage.DisplayName.."'s Message."
	newMessage.LayoutOrder = totalMessages
	totalMessages += 1
end

return m
