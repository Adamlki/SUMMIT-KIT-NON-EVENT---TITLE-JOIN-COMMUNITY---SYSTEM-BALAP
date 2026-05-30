-- StarterPlayerScripts > JekyClient > JekyGui > DonationBoardClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpdateDonationBoard = ReplicatedStorage:WaitForChild("UpdateDonationBoard")

local MAX_ITEMS = 10
local REFRESH_TIME = 120
local currentTimer = REFRESH_TIME

local lastReceivedData = nil
local lastSyncTimestamp = 0

-- [OPTIMASI] Gunakan FindFirstChild agar tahan terhadap StreamingEnabled (Part telat muncul)
local function getUIElements()
    local allParts = workspace:FindFirstChild("AllPartSummitkitJeky")
    if not allParts then return nil, nil end
    local lbFolder = allParts:FindFirstChild("LeaderBoard")
    if not lbFolder then return nil, nil end
    local boardModel = lbFolder:FindFirstChild("DonationLeaderBoard")
    if not boardModel then return nil, nil end
    
    local board = boardModel:FindFirstChild("Board")
    local detik = boardModel:FindFirstChild("Detik")
    if not board or not detik then return nil, nil end
    
    local sgBoard = board:FindFirstChild("SurfaceGui")
    local sgDetik = detik:FindFirstChild("SurfaceGui")
    if not sgBoard or not sgDetik then return nil, nil end
    
    local uiInit = sgBoard:FindFirstChild("Init")
    local timerLabel = sgDetik:FindFirstChild("DetikLabel")
    
    return uiInit, timerLabel
end

local function updateUI(top10Data)
    local uiInit, _ = getUIElements()
    if not uiInit or not top10Data then return end
    
    local receivedRanks = {}
    for _, data in ipairs(top10Data) do
        receivedRanks[data.Rank] = true
        local frame = uiInit:FindFirstChild("Top" .. tostring(data.Rank))
        if frame then
            frame.Username.Text = data.DisplayName
            frame.Total.Text = "R$ " .. tostring(data.TotalDonated)
            frame.ImageLabel.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(data.UserId) .. "&w=150&h=150"
        end
    end
    
    for rank = 1, MAX_ITEMS do
        if not receivedRanks[rank] then
            local frame = uiInit:FindFirstChild("Top" .. tostring(rank))
            if frame then
                frame.Username.Text = "Belum Ada"
                frame.Total.Text = "R$ 0"
                frame.ImageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            end
        end
    end
end

UpdateDonationBoard.OnClientEvent:Connect(function(top10Data)
    currentTimer = REFRESH_TIME
    lastReceivedData = top10Data
    lastSyncTimestamp = os.time()
    updateUI(top10Data)
end)

-- Loop Countdown Timer & Auto-Recovery StreamingEnabled
task.spawn(function()
    while true do
        task.wait(1)
        if currentTimer > 0 then
            currentTimer -= 1
        end
        
        local uiInit, timerLabel = getUIElements()
        
        -- Update Teks Countdown
        if timerLabel then
            if currentTimer > 0 then
                timerLabel.Text = "Update: " .. tostring(currentTimer) .. "s"
            else
                timerLabel.Text = "Updating..."
            end
        end
        
        -- Auto-Recovery jika Model Leaderboard baru saja ter-load / muncul di depan mata player
        if uiInit and lastReceivedData then
            if uiInit:GetAttribute("LastSync") ~= lastSyncTimestamp then
                updateUI(lastReceivedData)
                uiInit:SetAttribute("LastSync", lastSyncTimestamp)
            end
        end
    end
end)
