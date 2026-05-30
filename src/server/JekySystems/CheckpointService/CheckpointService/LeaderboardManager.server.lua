 -- ServerScriptService / LeaderboardManager_Summit
-- v7 — fix stale GlobalLB data saat summit=0

local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local JekyTitle              = require(ServerStorage.JekyModules:WaitForChild("JekyTitle"))
local JekyBoardConfiguration = require(ServerStorage.JekyModules:WaitForChild("JekyBoardConfiguration"))
local PS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky"))

local CONFIG = {
    MAX_ENTRIES          = 10,
    GLOBAL_INTERVAL      = 60,
    SERVER_INTERVAL      = 30,
    TIMEOUT              = 30,
    INIT_DELAY           = 5,
    AUTO_SYNC_INTERVAL   = 300,
    FORCE_INITIAL_SYNC   = true,
    FORCE_SYNC_ON_SUMMIT = true,
}

local JekyEvents = ReplicatedStorage:WaitForChild("JekyEvents", CONFIG.TIMEOUT)
if not JekyEvents then return end

local GetServerLB = JekyEvents:WaitForChild("CP_Internal_GetServerLB", CONFIG.TIMEOUT)
local GetGlobalLB = JekyEvents:WaitForChild("CP_Internal_GetGlobalLB", CONFIG.TIMEOUT)
local ServerLBEvt = JekyEvents:WaitForChild("CP_Internal_ServerLBUpdate", CONFIG.TIMEOUT)
local GlobalLBEvt = JekyEvents:WaitForChild("CP_Internal_GlobalLBUpdate", CONFIG.TIMEOUT)
if not (GetServerLB and GetGlobalLB and ServerLBEvt and GlobalLBEvt) then return end

local UpdateSummitBoardEvt = ReplicatedStorage:FindFirstChild("UpdateSummitBoard")
if not UpdateSummitBoardEvt then
    UpdateSummitBoardEvt = Instance.new("RemoteEvent")
    UpdateSummitBoardEvt.Name = "UpdateSummitBoard"
    UpdateSummitBoardEvt.Parent = ReplicatedStorage
end

-- ============================================================
-- ROLE CACHE
-- ============================================================
local RoleCache = {}
Players.PlayerRemoving:Connect(function(p) RoleCache[p.UserId] = nil end)

local function canShowOnLB(userId)
    if RoleCache[userId] == nil then
        local p = Players:GetPlayerByUserId(userId)
        if p then
            RoleCache[userId] = JekyBoardConfiguration:CanShowOnSummitLeaderboard(JekyTitle.GetRoleTitle(p))
        else
            RoleCache[userId] = true
        end
    end
    return RoleCache[userId]
end

-- ============================================================
-- DATA
-- ============================================================
local SrvData = {}
local GlbData = {}

-- ============================================================
-- getUsername
-- ============================================================
local function getUsername(userId)
    local p = Players:GetPlayerByUserId(userId)
    if p then
        PS.CacheUsername(userId, p.Name)
        return p.Name
    end
    local cached = PS.GetUsernameFromUserId(userId)
    if cached and cached ~= "" then return cached end
    PS.ResolveUsernameBackfill(userId)
    return "Player_"..userId
end

-- ============================================================
-- Re-render loop (Background Data Sync to Clients)
-- ============================================================
local function startRerenderLoop()
    task.spawn(function()
        while true do
            task.wait(3)
            local need = false
            for _, data in ipairs({ GlbData, SrvData }) do
                for _, e in ipairs(data) do
                    if e.Username:find("^Player_") then
                        local name = PS.GetUsernameFromUserId(e.UserId)
                        if name and name ~= "" and not name:find("^Player_") then
                            e.Username = name; need = true
                        end
                    end
                end
            end
            if need then 
                UpdateSummitBoardEvt:FireAllClients({
                    Type = "UpdateNames",
                    ServerData = SrvData,
                    GlobalData = GlbData
                })
            end
        end
    end)
end

-- ============================================================
-- PROCESS DATA
-- ============================================================
local function processServer(raw)
    local out  = {}
    local seen = {}
    for _, e in ipairs(raw or {}) do
        if not (e and e.UserId) then continue end
        if seen[e.UserId] then continue end
        local sum = tonumber(e.Summit) or 0
        if sum <= 0 then continue end
        if not canShowOnLB(e.UserId) then continue end
        seen[e.UserId] = true
        table.insert(out, { UserId = e.UserId, Username = getUsername(e.UserId), Summit = sum })
    end
    table.sort(out, function(a, b)
        if a.Summit ~= b.Summit then return a.Summit > b.Summit end
        return (a.Username or "") < (b.Username or "")
    end)
    SrvData = out
    UpdateSummitBoardEvt:FireAllClients({Type = "Server", Data = SrvData})
end

local function processGlobal(raw)
    local out  = {}
    local seen = {}
    
    -- Online players SELALU masuk seen (termasuk yg summit=0)
    -- Ini mencegah data lama DS muncul saat player sudah di-reset
    for _, p in ipairs(Players:GetPlayers()) do
        -- Tandai seen dulu SEBELUM cek sum, supaya DS lama tidak bisa override
        seen[p.UserId] = true
        
        local ls  = p:FindFirstChild("leaderstats")
        local sv  = ls and ls:FindFirstChild("Summit")
        local sum = sv and (tonumber(sv.Value) or 0) or 0
        
        -- Hanya masuk LB kalau summit > 0 dan boleh tampil
        if sum > 0 and canShowOnLB(p.UserId) then
            PS.CacheUsername(p.UserId, p.Name)
            table.insert(out, { UserId = p.UserId, Username = p.Name, Summit = sum })
        end
    end
    
    -- Offline dari DataStore — skip kalau sudah ada di seen (online player)
    for _, e in ipairs(raw or {}) do
        if not (e and e.UserId) then continue end
        if seen[e.UserId] then continue end  -- skip: online player sudah handle di atas
        local sum = tonumber(e.Summit) or 0
        if sum <= 0 then continue end
        if not canShowOnLB(e.UserId) then continue end
        seen[e.UserId] = true
        table.insert(out, { UserId = e.UserId, Username = getUsername(e.UserId), Summit = sum })
    end
    
    table.sort(out, function(a, b)
        if a.Summit ~= b.Summit then return a.Summit > b.Summit end
        return (a.Username or "") < (b.Username or "")
    end)
    for i, e in ipairs(out) do e.Rank = i end
    GlbData = out
    UpdateSummitBoardEvt:FireAllClients({Type = "Global", Data = GlbData})
end

-- ============================================================
-- FETCH
-- ============================================================
local function fetchServer()
    local ok, d = pcall(function() return GetServerLB:Invoke() end)
    if ok and d then processServer(d) end
end

local function fetchGlobal()
    local ok, d = pcall(function() return GetGlobalLB:Invoke() end)
    if ok and d then processGlobal(d) end
end

-- ============================================================
-- SETUP
-- ============================================================
local function setupListeners()
    ServerLBEvt.Event:Connect(function(raw) processServer(raw) end)
    GlobalLBEvt.Event:Connect(function(raw) processGlobal(raw) end)
end

local function startLoop()
    task.spawn(function()
        task.wait(CONFIG.INIT_DELAY)
        if CONFIG.FORCE_INITIAL_SYNC then
            PS.GlobalLB.ForceSyncOnline()
            task.wait(2)
        end
        PS.PreloadOnlineUsernames()
        task.wait(0.5)
        fetchServer()
        fetchGlobal()
    end)
    
    -- Simple background loop to periodically fetch
    task.spawn(function()
        local serverTimer = CONFIG.SERVER_INTERVAL
        local globalTimer = CONFIG.GLOBAL_INTERVAL
        while true do
            task.wait(1)
            serverTimer -= 1
            globalTimer -= 1
            
            if serverTimer <= 0 then
                serverTimer = CONFIG.SERVER_INTERVAL
                task.spawn(fetchServer)
            end
            
            if globalTimer <= 0 then
                globalTimer = CONFIG.GLOBAL_INTERVAL
                task.spawn(fetchGlobal)
            end
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(CONFIG.AUTO_SYNC_INTERVAL)
            PS.PreloadOnlineUsernames()
            PS.GlobalLB.ForceSyncOnline()
        end
    end)
    
    startRerenderLoop()
end

-- ============================================================
-- ENTRY
-- ============================================================
if RunService:IsServer() then
    task.wait(5)
    task.spawn(function()
        setupListeners()
        startLoop()
    end)
end

