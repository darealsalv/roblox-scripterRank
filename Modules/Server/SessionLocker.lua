local dataStoreService = game:GetService("DataStoreService")
local players = game:GetService("Players")

local sessionStore = dataStoreService:GetDataStore("PlayerSessionLocks")
local sessionTimeout = 300

local m = {}

local function GenerateLockId(player)
	return game.JobId .. "_" .. player.UserId
end

local function IsExpired(lockData)
	if not lockData or not lockData.timestamp then
		return true
	end
	
	return (os.time() - lockData.timestamp) > sessionTimeout
end

function m:Lock(player)
	local lockKey = "lock_" .. player.UserId

	local success, currentLock = pcall(function()
		return sessionStore:GetAsync(lockKey)
	end)

	if not success then
		warn("[SessionLocker] Failed to get lock for", player.Name)
		return false, "DataStore read error"
	end

	if currentLock and not IsExpired(currentLock) then
		return false, "Session already active in another server"
	end

	local newLock = {
		jobId = game.JobId,
		timestamp = os.time(),
	}

	local successSet = pcall(function()
		sessionStore:SetAsync(lockKey, newLock)
	end)

	if not successSet then
		warn("[SessionLocker] Failed to set lock for", player.Name)
		return false, "DataStore write error"
	end

	return true
end

function m:Unlock(player)
	local lockKey = "lock_" .. player.UserId
	local success = pcall(function()
		sessionStore:RemoveAsync(lockKey)
	end)

	if not success then
		warn("[SessionLocker] Failed to remove lock for", player.Name)
	end
end

function m:UnlockAll()
	for i, player in players:GetPlayers() do
		self:Unlock(player)
	end
end

return m
