local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- ==========================================
-- CONFIGURATION
-- ==========================================
-- (Mode is now selected dynamically via the admin panel)
-- ==========================================

local JekyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyConfig"))

local function isAdmin(player)
    local adminRoles = {"Owner", "Developer", "HeadAdmin", "Admin"}
    for _, role in ipairs(adminRoles) do
        local rule = JekyConfig.RoleRules[role]
        if rule then
            if table.find(rule.UserIds, player.UserId) then return true end
            if table.find(rule.Usernames, player.Name) then return true end
        end
    end
    -- Also fallback to true if in Studio for testing
    if RunService:IsStudio() then return true end
    return false
end

local function getAdminRole(player)
    local adminRoles = {"Owner", "Developer", "HeadAdmin", "Admin"}
    for _, role in ipairs(adminRoles) do
        local rule = JekyConfig.RoleRules[role]
        if rule then
            if table.find(rule.UserIds, player.UserId) then return role end
            if table.find(rule.Usernames, player.Name) then return role end
        end
    end
    if RunService:IsStudio() then return "Owner" end
    return "Admin"
end

-- Create Remotes
local remotesFolder = ReplicatedStorage:FindFirstChild("RaceSystemRemotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "RaceSystemRemotes"
    remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name)
    local remote = remotesFolder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote
end

local RaceAction = getOrCreateRemote("RaceAction")
local RaceStateUpdate = getOrCreateRemote("RaceStateUpdate")
local RacePositionsUpdate = getOrCreateRemote("RacePositionsUpdate")
local RaceAdminNotif = getOrCreateRemote("RaceAdminNotif")

-- Race State
local raceState = "NotStarted"
local selectedSummit = nil
local selectedMode = nil -- "Admin" or "Player"
local raceStartTime = 0
local playerFinishTimes = {} -- [UserId] = time (number)

-- Barrier Management
local function getBarrier()
    local barrier = Workspace:FindFirstChild("RaceBarrier", true)
    if not barrier then
        barrier = Instance.new("Part")
        barrier.Name = "RaceBarrier"
        barrier.Size = Vector3.new(20, 10, 2)
        barrier.Position = Vector3.new(0, 5, 0)
        barrier.Anchored = true
        barrier.BrickColor = BrickColor.new("Bright red")
        barrier.Material = Enum.Material.Neon
        barrier.Parent = Workspace
    end
    return barrier
end

local function setBarrierEnabled(enabled)
    local barrier = getBarrier()
    local targetTransparency = enabled and 0.5 or 1
    
    barrier.CanCollide = enabled
    barrier.Transparency = targetTransparency
    
    -- Hide/Show any Decals or Textures inside the barrier
    for _, child in ipairs(barrier:GetChildren()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            -- Kembalikan ke 0.4 sesuai setting awal saat muncul, atau 1 untuk disembunyikan
            child.Transparency = enabled and 0.4 or 1
        end
    end
end

-- Ensure barrier starts disabled (hidden when race is off)
setBarrierEnabled(false)

-- Helper for CP parsing
local function getCPSortValue(cpString)
    if not cpString then return -1 end
    local cp = tostring(cpString):lower()
    if cp == "bc" or cp == "basecamp" then
        return 0
    end
    -- Try to parse as number
    local num = tonumber(cp)
    if num then return num end
    
    -- Extract number if it's text like "CP 2" or "Pos 3"
    local match = string.match(cp, "%d+")
    if match then
        return tonumber(match)
    end
    
    return -1
end

-- Format Time (os.clock diff) -> 00.00.00 (min.sec.ms)
local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    local ms3 = math.floor((seconds * 1000) % 1000)
    return string.format("%02d.%02d.%03d", mins, secs, ms3)
end

-- Handle Actions
RaceAction.OnServerEvent:Connect(function(player, actionData)
    if not isAdmin(player) then return end

    local action = actionData.action
    local role = getAdminRole(player)
    local actionText = ""
    
    if action == "SetSummit" then
        selectedSummit = actionData.summit or "Summit"
        actionText = role .. " " .. player.DisplayName .. " set Target: " .. (selectedSummit == "Summit" and "SUMMIT" or "APEX SUMMIT")
        print("Race System: Summit set to " .. selectedSummit)
    
    elseif action == "SetMode" then
        selectedMode = actionData.mode
        actionText = role .. " " .. player.DisplayName .. " set Race Mode: " .. (selectedMode == "Admin" and "ADMIN RACE (All Players)" or "PLAYER RACE (Exclude Admins)")
        print("Race System: Mode set to " .. selectedMode)
        
    elseif action == "Start" then
        if raceState == "Racing" or raceState == "Countdown" then return end
        
        if not selectedMode then
            print("Race System: Cannot start, Mode not selected!")
            RaceAdminNotif:FireClient(player, "⚠️ FAILED: CHOOSE RACE MODE FIRST!")
            return
        end
        
        if not selectedSummit then
            print("Race System: Cannot start, Summit not selected!")
            RaceAdminNotif:FireClient(player, "⚠️ FAILED: CHOOSE TARGET SUMMIT FIRST!")
            return
        end
        
        local countdown = tonumber(actionData.countdown) or 5
        raceState = "Countdown"
        playerFinishTimes = {}
        setBarrierEnabled(true)
        
        actionText = role .. " " .. player.DisplayName .. " set Start (Timer: " .. countdown .. "s)"
        print("Race System: Starting countdown " .. countdown)
        -- Broadcast countdown
        RaceStateUpdate:FireAllClients({
            state = "Countdown",
            countdown = countdown
        })
        
        -- Server side wait
        task.spawn(function()
            for i = countdown, 1, -1 do
                if raceState ~= "Countdown" then return end
                task.wait(1)
            end
            
            if raceState ~= "Countdown" then return end
            
            -- Start race
            raceState = "Racing"
            raceStartTime = os.clock()
            setBarrierEnabled(false)
            
            print("Race System: Race Started!")
            RaceStateUpdate:FireAllClients({
                state = "Racing"
            })
        end)
        
    elseif action == "Reset" then
        -- FULL RESET
        raceState = "NotStarted"
        selectedSummit = nil
        selectedMode = nil
        playerFinishTimes = {}
        setBarrierEnabled(false)
        actionText = role .. " " .. player.DisplayName .. " reset the race!"
        print("Race System: Reset")
        RaceStateUpdate:FireAllClients({
            state = "NotStarted"
        })
        -- Send empty array to clear ranking log on client
        RacePositionsUpdate:FireAllClients({})
        
    elseif action == "SetTrack" then
        actionText = role .. " " .. player.DisplayName .. " set Tracking " .. (actionData.state and "ON" or "OFF")
    end
    
    if actionText ~= "" then
        RaceAdminNotif:FireAllClients(actionText)
    end
end)

-- Ranking Loop
task.spawn(function()
    while true do
        task.wait(1) -- Update twice a second -> changed to once a second
        
        if raceState == "Racing" then
            local playersData = {}
            local currentClock = os.clock()
            
            for _, player in ipairs(Players:GetPlayers()) do
                -- Filter based on mode
                if selectedMode == "Player" and isAdmin(player) then
                    continue
                end
                
                -- Read leaderstats
                local ls = player:FindFirstChild("leaderstats")
                local cp = "BC"
                local sortVal = 0
                
                if ls then
                    local cpVal = ls:FindFirstChild("Checkpoint")
                    if cpVal then
                        cp = tostring(cpVal.Value)
                        sortVal = getCPSortValue(cp)
                    end
                end
                
                -- Check if finished
                local isFinished = (playerFinishTimes[player.UserId] ~= nil)
                local timeTaken = 0
                
                if isFinished then
                    timeTaken = playerFinishTimes[player.UserId]
                else
                    timeTaken = currentClock - raceStartTime
                    -- Check if they just reached the summit
                    local cpLower = cp:lower()
                    local targetLower = selectedSummit:lower()
                    if cpLower == targetLower or (targetLower == "apexsummit" and cpLower == "bigsummit") then
                        playerFinishTimes[player.UserId] = timeTaken
                        isFinished = true
                    end
                end
                
                table.insert(playersData, {
                    player = player,
                    name = player.DisplayName, -- nickname
                    cp = cp,
                    sortVal = sortVal,
                    time = timeTaken,
                    isFinished = isFinished
                })
            end
            
            -- Sort players
            -- Priority: 1. Finished (sorted by time ascending), 2. Not finished (sorted by CP descending)
            table.sort(playersData, function(a, b)
                if a.isFinished and b.isFinished then
                    return a.time < b.time
                elseif a.isFinished then
                    return true
                elseif b.isFinished then
                    return false
                else
                    return a.sortVal > b.sortVal
                end
            end)
            
            -- Assign position numbers and format time
            local finalData = {}
            for i, data in ipairs(playersData) do
                table.insert(finalData, {
                    userId = data.player.UserId,
                    name = data.name,
                    position = i,
                    cp = data.cp,
                    timeFormatted = formatTime(data.time),
                    isFinished = data.isFinished
                })
            end
            
            -- Send to all clients
            RacePositionsUpdate:FireAllClients(finalData)
        end
    end
end)
