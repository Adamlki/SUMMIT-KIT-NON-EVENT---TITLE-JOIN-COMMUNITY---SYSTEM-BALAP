local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Admin Check using JekyConfig
local JekyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyConfig"))
local function isAdmin(plr)
    local adminRoles = {"Owner", "Developer", "HeadAdmin", "Admin"}
    for _, role in ipairs(adminRoles) do
        local rule = JekyConfig.RoleRules[role]
        if rule then
            if table.find(rule.UserIds, plr.UserId) then return true end
            if table.find(rule.Usernames, plr.Name) then return true end
        end
    end
    if RunService:IsStudio() then return true end
    return false
end

-- Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("RaceSystemRemotes")
local RaceAction = remotesFolder:WaitForChild("RaceAction")
local RaceStateUpdate = remotesFolder:WaitForChild("RaceStateUpdate")
local RacePositionsUpdate = remotesFolder:WaitForChild("RacePositionsUpdate")
local RaceAdminNotif = remotesFolder:WaitForChild("RaceAdminNotif")

-- UI Elements
local IsiGui = PlayerGui:WaitForChild("IsiGui", 999999)
local ListGui = PlayerGui:WaitForChild("ListGui", 999999)

if not IsiGui or not ListGui then
    warn("Race System: Could not find IsiGui or ListGui.")
    return
end

local RaceSystemFrame = IsiGui:WaitForChild("RaceSystemFrame", 999999)
local MainFrame = RaceSystemFrame:WaitForChild("MainFrameRaceSystem", 999999)
local RankingFrame = RaceSystemFrame:WaitForChild("RankingFrame", 999999)
local RaceButton = ListGui:FindFirstChild("RaceButton", true) -- It's deep in ListGui maybe?

-- Hide notification templates initially
local summitGui = PlayerGui:WaitForChild("SummitGUI", 999999)
if summitGui then
    local notifRace = summitGui:FindFirstChild("NotifRace")
    if notifRace then
        local t = notifRace:FindFirstChild("MainFrame")
        if t then t.Visible = false end
    end
    local notifAdmin = summitGui:FindFirstChild("NotifAdmin")
    if notifAdmin then
        local t = notifAdmin:FindFirstChild("MainFrame")
        if t then t.Visible = false end
    end
end

local trackEnabled = false
local countdownGui = nil

-- Setup Countdown UI
local function getCountdownGui()
    if not countdownGui then
        countdownGui = Instance.new("ScreenGui")
        countdownGui.Name = "RaceCountdownGui"
        countdownGui.IgnoreGuiInset = true
        countdownGui.Parent = PlayerGui
        
        local topLabel = Instance.new("TextLabel")
        topLabel.Name = "TopLabel"
        topLabel.Size = UDim2.new(0.8, 0, 0.15, 0)
        topLabel.Position = UDim2.new(0.1, 0, 0.2, 0)
        topLabel.BackgroundTransparency = 1
        topLabel.TextScaled = true
        topLabel.TextColor3 = Color3.new(1, 1, 1)
        topLabel.TextStrokeTransparency = 0
        topLabel.Font = Enum.Font.FredokaOne
        topLabel.Text = "GET READY... RACE STARTS NOW!"
        topLabel.Parent = countdownGui
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "NumberLabel"
        textLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
        textLabel.Position = UDim2.new(0.25, 0, 0.35, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = true
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.TextStrokeTransparency = 0
        textLabel.Font = Enum.Font.FredokaOne
        textLabel.Text = ""
        textLabel.Parent = countdownGui
    end
    return countdownGui.NumberLabel
end

local function hideCountdown()
    if countdownGui then
        countdownGui:Destroy()
        countdownGui = nil
    end
    local soundService = game:GetService("SoundService")
    local beep = soundService:FindFirstChild("RaceBeep")
    if beep then beep:Stop() end
end

local function showAdminNotifLocal(text)
    local summitGui = PlayerGui:FindFirstChild("SummitGUI")
    if summitGui then
        local notifAdmin = summitGui:FindFirstChild("NotifAdmin")
        if notifAdmin then
            notifAdmin.Visible = true
            local templateFrame = notifAdmin:FindFirstChild("MainFrame")
            if templateFrame then
                local newNotif = templateFrame:Clone()
                local textLabel = newNotif:FindFirstChild("TextLabel")
                if textLabel then
                    textLabel.Text = text
                end
                newNotif.Visible = true
                newNotif.Parent = notifAdmin
                
                task.delay(3, function()
                    if newNotif then newNotif:Destroy() end
                end)
            end
        end
    end
end

RaceAdminNotif.OnClientEvent:Connect(function(text)
    if not isAdmin(LocalPlayer) then return end
    showAdminNotifLocal(text)
end)

-- Hook Admin Buttons
if MainFrame then
    local StartBtn = MainFrame:FindFirstChild("StartBtn")
    local ResetBtn = MainFrame:FindFirstChild("ResetBtn")
    local SummitBtn = MainFrame:FindFirstChild("SummitBtn")
    local ApexSummitBtn = MainFrame:FindFirstChild("ApexSummitBtn")
    local RankingBtn = MainFrame:FindFirstChild("RankingBtn")
    local CloseBtn = MainFrame:FindFirstChild("CloseBtn")
    local TextBox = MainFrame:FindFirstChild("TextBox")
    local AdminRaceBtn = MainFrame:FindFirstChild("AdminRaceBtn")
    local PlayerRaceBtn = MainFrame:FindFirstChild("PlayerRaceBtn")
    local TrackBtn = MainFrame:FindFirstChild("TrackBtn")
    
    if RaceButton then
        if not isAdmin(LocalPlayer) then
            RaceButton.Visible = false
        else
            RaceButton.Visible = true
        end
        RaceButton.MouseButton1Click:Connect(function()
            RaceSystemFrame.Visible = not RaceSystemFrame.Visible
        end)
    end
    
    if CloseBtn then
        CloseBtn.MouseButton1Click:Connect(function()
            RaceSystemFrame.Visible = false
        end)
    end
    
    if StartBtn then
        StartBtn.MouseButton1Click:Connect(function()
            local countdown = TextBox and tonumber(TextBox.Text)
            if not countdown then
                showAdminNotifLocal("⚠️ FAILED: PLEASE INPUT A NUMBER FOR COUNTDOWN!")
                return
            end
            
            if currentRaceState ~= "NotStarted" then
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Race Started",
                    Text = "Race sudah dimulai! Silakan klik RESET terlebih dahulu sebelum memulai ulang.",
                    Duration = 5
                })
                return
            end
            
            RaceAction:FireServer({ action = "Start", countdown = countdown })
        end)
    end
    
    if ResetBtn then
        ResetBtn.MouseButton1Click:Connect(function()
            RaceAction:FireServer({ action = "Reset" })
        end)
    end
    
    if SummitBtn then
        SummitBtn.MouseButton1Click:Connect(function()
            RaceAction:FireServer({ action = "SetSummit", summit = "Summit" })
            SummitBtn.TextLabel.Text = "> SUMMIT <"
            if ApexSummitBtn then ApexSummitBtn.TextLabel.Text = "APEX SUMMIT" end
        end)
    end
    
    if ApexSummitBtn then
        ApexSummitBtn.MouseButton1Click:Connect(function()
            RaceAction:FireServer({ action = "SetSummit", summit = "ApexSummit" })
            ApexSummitBtn.TextLabel.Text = "> APEX SUMMIT <"
            if SummitBtn then SummitBtn.TextLabel.Text = "SUMMIT" end
        end)
    end
    
    if TrackBtn then
        TrackBtn.MouseButton1Click:Connect(function()
            trackEnabled = not trackEnabled
            local lbl = TrackBtn:FindFirstChild("TextLabel") or TrackBtn
            lbl.Text = trackEnabled and "TRACK: ON" or "TRACK: OFF"
            RaceAction:FireServer({ action = "SetTrack", state = trackEnabled })
            
            if not trackEnabled then
                -- Clear current track UI if disabled
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("Head") then
                        local tag = p.Character.Head:FindFirstChild("TamplateTrack")
                        if tag then tag:Destroy() end
                    end
                end
            end
        end)
    end
    
    if AdminRaceBtn then
        AdminRaceBtn.MouseButton1Click:Connect(function()
            RaceAction:FireServer({ action = "SetMode", mode = "Admin" })
            local lblAdmin = AdminRaceBtn:FindFirstChild("TextLabel") or AdminRaceBtn
            lblAdmin.Text = "> ADMIN RACE <"
            if PlayerRaceBtn then
                local lblPlayer = PlayerRaceBtn:FindFirstChild("TextLabel") or PlayerRaceBtn
                lblPlayer.Text = "PLAYER RACE"
            end
        end)
    end
    
    if PlayerRaceBtn then
        PlayerRaceBtn.MouseButton1Click:Connect(function()
            RaceAction:FireServer({ action = "SetMode", mode = "Player" })
            local lblPlayer = PlayerRaceBtn:FindFirstChild("TextLabel") or PlayerRaceBtn
            lblPlayer.Text = "> PLAYER RACE <"
            if AdminRaceBtn then
                local lblAdmin = AdminRaceBtn:FindFirstChild("TextLabel") or AdminRaceBtn
                lblAdmin.Text = "ADMIN RACE"
            end
        end)
    end
    
    if RankingBtn and RankingFrame then
        RankingBtn.MouseButton1Click:Connect(function()
            RankingFrame.Visible = not RankingFrame.Visible
        end)
        
        local RankClose = RankingFrame:FindFirstChild("CloseBtn")
        if RankClose then
            RankClose.MouseButton1Click:Connect(function()
                RankingFrame.Visible = false
            end)
        end
    end
end



local notifiedPlayers = {}

local currentRaceState = "NotStarted"
local globalTrackEnabled = false

-- Listen to State
RaceStateUpdate.OnClientEvent:Connect(function(data)
    if data.type == "TrackUpdate" then
        globalTrackEnabled = data.trackEnabled
        
        if not globalTrackEnabled then
            -- Clear current track UI if disabled
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Head") then
                    local tag = p.Character.Head:FindFirstChild("TamplateTrack")
                    if tag then tag:Destroy() end
                end
            end
        end
        return
    end

    local state = data.state
    currentRaceState = state
    
    if state == "Countdown" or state == "NotStarted" or state == "Stopped" then
        notifiedPlayers = {}
    end
    
    -- Update Reset Button text (No longer changes to STOP)
    if MainFrame then
        local btn = MainFrame:FindFirstChild("ResetBtn")
        if btn then
            local textObj = btn:FindFirstChild("TextLabel") or btn
            textObj.Text = "RESET"
        end
        
        if state == "NotStarted" then
            local adminBtn = MainFrame:FindFirstChild("AdminRaceBtn")
            if adminBtn then
                local lbl = adminBtn:FindFirstChild("TextLabel") or adminBtn
                lbl.Text = "ADMIN RACE"
            end
            local playerBtn = MainFrame:FindFirstChild("PlayerRaceBtn")
            if playerBtn then
                local lbl = playerBtn:FindFirstChild("TextLabel") or playerBtn
                lbl.Text = "PLAYER RACE"
            end
            local summitBtn = MainFrame:FindFirstChild("SummitBtn")
            if summitBtn then
                local lbl = summitBtn:FindFirstChild("TextLabel") or summitBtn
                lbl.Text = "SUMMIT"
            end
            local apexBtn = MainFrame:FindFirstChild("ApexSummitBtn")
            if apexBtn then
                local lbl = apexBtn:FindFirstChild("TextLabel") or apexBtn
                lbl.Text = "APEX SUMMIT"
            end
        end
    end
    
    if state == "Countdown" then
        local label = getCountdownGui()
        local cd = data.countdown
        
        -- Create/Get Sound
        local soundService = game:GetService("SoundService")
        local beep = soundService:FindFirstChild("RaceBeep")
        if not beep then
            beep = Instance.new("Sound")
            beep.Name = "RaceBeep"
            beep.SoundId = "rbxassetid://133349677064026"
            beep.Volume = 2
            beep.Parent = soundService
        end
        
        task.spawn(function()
            for i = cd, 1, -1 do
                if not countdownGui or not countdownGui.Parent then break end
                label.Text = tostring(i)
                beep.PlaybackSpeed = 1
                beep.TimePosition = 0 -- Mulai dari awal (suara tit)
                beep:Play()
                task.wait(1)
            end
        end)
    elseif state == "Racing" then
        local label = getCountdownGui()
        if countdownGui and countdownGui.Parent then
            if countdownGui:FindFirstChild("TopLabel") then
                countdownGui.TopLabel.Visible = false
            end
            label.Text = "GO!"
            
            local soundService = game:GetService("SoundService")
            local beep = soundService:FindFirstChild("RaceBeep")
            if beep then
                beep.PlaybackSpeed = 1
                beep.TimePosition = 3 -- Loncat ke detik ke-3 (suara teng)
                beep:Play()
            end

            task.wait(1)
            hideCountdown()
        end
    elseif state == "NotStarted" or state == "Stopped" then
        hideCountdown()
    end
end)

local function getColorForRank(pos)
    if pos == 1 then
        return Color3.fromRGB(255, 215, 0) -- Emas (Gold)
    elseif pos == 2 then
        return Color3.fromRGB(192, 192, 192) -- Perak (Silver)
    elseif pos == 3 then
        return Color3.fromRGB(205, 127, 50) -- Perunggu (Bronze)
    else
        return Color3.fromRGB(255, 255, 255) -- Putih
    end
end

-- Listen to Positions Update
RacePositionsUpdate.OnClientEvent:Connect(function(payload)
    -- Parse payload
    local positionsData = payload.positions or {}
    globalTrackEnabled = payload.trackEnabled or false
    
    if payload.positions == nil and typeof(payload) == "table" and #payload == 0 then
        -- This is a reset packet (empty array) sent directly
        positionsData = {}
        globalTrackEnabled = false
    end
    
    -- Update RankingFrame UI
    if RankingFrame then
        local scrollFrame = RankingFrame:FindFirstChild("ScrollingFrame")
        if scrollFrame then
            -- Pastikan ScrollingFrame bisa melar otomatis ke bawah sebanyak apapun playernya
            scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            
            local template = scrollFrame:FindFirstChild("TamplateFrame")
            if template then
                -- Mark all existing UI as unused
                local unusedFrames = {}
                for _, child in ipairs(scrollFrame:GetChildren()) do
                    if child:IsA("Frame") and child.Name ~= "TamplateFrame" then
                        unusedFrames[child.Name] = child
                        child.Visible = false
                    end
                end
                
                -- Populate new entries
                for _, data in ipairs(positionsData) do
                    local playerIdStr = data.userId and tostring(data.userId) or (data.player and tostring(data.player.UserId) or data.name)
                    local frameName = "Player_" .. playerIdStr
                    
                    local frame = unusedFrames[frameName]
                    if not frame then
                        frame = template:Clone()
                        frame.Name = frameName
                        frame.Parent = scrollFrame
                    else
                        -- Frame reused, remove from unused pool
                        unusedFrames[frameName] = nil
                    end
                    
                    frame.Visible = true
                    frame.LayoutOrder = data.position -- Otomatis mengurutkan posisi UI dari atas ke bawah
                    
                    local nameLbl = frame:FindFirstChild("NameLabel")
                    local numLbl = frame:FindFirstChild("NumberLabel")
                    local posLbl = frame:FindFirstChild("PositonLabel")
                    local timeLbl = frame:FindFirstChild("TimeLabel")
                    
                    local rankColor = getColorForRank(data.position)
                    
                    if nameLbl then nameLbl.Text = data.name; nameLbl.TextColor3 = rankColor end
                    if numLbl then numLbl.Text = "#" .. data.position; numLbl.TextColor3 = rankColor end
                    if posLbl then posLbl.Text = data.cp; posLbl.TextColor3 = rankColor end
                    if timeLbl then timeLbl.Text = data.timeFormatted; timeLbl.TextColor3 = rankColor end
                    
                    -- Check for new finishes to trigger notification
                    local playerIdentifier = data.userId or (data.player and data.player.UserId)
                    if data.isFinished and playerIdentifier and not notifiedPlayers[playerIdentifier] then
                        notifiedPlayers[playerIdentifier] = true
                        
                        -- Create Notification UI
                        local summitGui = PlayerGui:FindFirstChild("SummitGUI")
                        if summitGui then
                            local notifRace = summitGui:FindFirstChild("NotifRace")
                            if notifRace then
                                notifRace.Visible = true
                                local templateFrame = notifRace:FindFirstChild("MainFrame")
                                if templateFrame then
                                    local newNotif = templateFrame:Clone()
                                    local textLabel = newNotif:FindFirstChild("TextLabel")
                                    if textLabel then
                                        textLabel.Text = "#" .. data.position .. " " .. data.name .. " " .. data.timeFormatted
                                    end
                                    newNotif.Visible = true
                                    newNotif.Parent = notifRace
                                    
                                    -- Play Finish Sound
                                    local soundService = game:GetService("SoundService")
                                    local finishSound = soundService:FindFirstChild("RaceFinishSound")
                                    if not finishSound then
                                        finishSound = Instance.new("Sound")
                                        finishSound.Name = "RaceFinishSound"
                                        finishSound.SoundId = "rbxassetid://86296105231494"
                                        finishSound.Volume = 2
                                        finishSound.Parent = soundService
                                    end
                                    finishSound:Play()
                                    
                                    -- Auto remove after 5 seconds
                                    task.delay(5, function()
                                        if newNotif then newNotif:Destroy() end
                                    end)
                                end
                            end
                        end
                    end
                end
                
                -- Bersihkan frame pemain yang sudah keluar atau tidak ada di data
                for _, child in pairs(unusedFrames) do
                    child:Destroy()
                end
            end
        end
    end
    
    -- Update Overhead Tags
    if globalTrackEnabled then
        if #positionsData == 0 then
            -- Clear all tags if we get empty data (reset)
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Head") then
                    local tag = p.Character.Head:FindFirstChild("TamplateTrack")
                    if tag then tag:Destroy() end
                end
            end
        end
        
        local templateTrack = ReplicatedStorage:FindFirstChild("TamplateTrack")
        if templateTrack then
            for _, data in ipairs(positionsData) do
                local player = data.player or (data.userId and Players:GetPlayerByUserId(data.userId))
                if not player then
                    continue
                end
                
                if player and player.Character then
                    -- Don't show tags on admins/developers as requested (Commented out so developers can see it too)
                    -- if isAdmin(player) then continue end
                    
                    local head = player.Character:FindFirstChild("Head")
                    if head then
                        local tag = head:FindFirstChild("TamplateTrack")
                        if not tag then
                            tag = templateTrack:Clone()
                            tag.Adornee = head
                            tag.Parent = head
                        end
                        
                        -- Hide if user disabled overhead tags
                        if _G.isHideTitle then
                            tag.Enabled = false
                        else
                            tag.Enabled = true
                        end
                        
                        local nameLabel = tag:FindFirstChild("Name")
                        if nameLabel then
                            nameLabel.Text = "#" .. data.position .. " " .. data.name
                            nameLabel.TextColor3 = getColorForRank(data.position)
                        end
                    end
                end
            end
        end
    end
end)
