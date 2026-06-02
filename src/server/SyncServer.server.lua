local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Fungsi aman mengambil folder Syncing agar tidak tertukar dengan Event bernama "Syncing"
local function getSyncFolder()
	for _, child in ipairs(ReplicatedStorage:GetChildren()) do
		if child.Name == "Syncing" and child:IsA("Folder") then
			return child
		end
	end
	
	-- Kalau foldernya hilang, buat otomatis
	local folder = Instance.new("Folder")
	folder.Name = "Syncing"
	folder.Parent = ReplicatedStorage
	return folder
end

local SyncFolder = getSyncFolder()

-- Ambil atau buat RemoteEvent
local SyncEvent = SyncFolder:FindFirstChild("Sync") or Instance.new("RemoteEvent", SyncFolder)
SyncEvent.Name = "Sync"
local UnSyncEvent = SyncFolder:FindFirstChild("UnSync") or Instance.new("RemoteEvent", SyncFolder)
UnSyncEvent.Name = "UnSync"

-- Sistem Anti-Spam
local rateLimit = {}
local COOLDOWN_TIME = 1

SyncEvent.OnServerEvent:Connect(function(player, targetPlayer)
	local lastTime = rateLimit[player.UserId] or 0
	local currentTime = os.clock()
	if currentTime - lastTime < COOLDOWN_TIME then return end
	rateLimit[player.UserId] = currentTime

	if targetPlayer and typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") and targetPlayer ~= player then
		SyncEvent:FireAllClients(player, targetPlayer, "START")
	end
end)

UnSyncEvent.OnServerEvent:Connect(function(player)
	local lastTime = rateLimit[player.UserId .. "_unsync"] or 0
	local currentTime = os.clock()
	if currentTime - lastTime < COOLDOWN_TIME then return end
	rateLimit[player.UserId .. "_unsync"] = currentTime

	SyncEvent:FireAllClients(player, nil, "STOP")
end)

Players.PlayerRemoving:Connect(function(player)
	rateLimit[player.UserId] = nil
	rateLimit[player.UserId .. "_unsync"] = nil
end)
