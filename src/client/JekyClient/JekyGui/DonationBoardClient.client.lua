-- StarterPlayerScripts > JekyClient > JekyGui > DonationBoardClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpdateDonationBoard = ReplicatedStorage:WaitForChild("UpdateDonationBoard")

local allPartsFolder = workspace:WaitForChild("AllPartSummitkitJeky")
local leaderboardFolder = allPartsFolder:WaitForChild("LeaderBoard")
local boardModel = leaderboardFolder:WaitForChild("DonationLeaderBoard")

local uiInit = boardModel:WaitForChild("Board"):WaitForChild("SurfaceGui"):WaitForChild("Init")
local timerLabel = boardModel:WaitForChild("Detik"):WaitForChild("SurfaceGui"):WaitForChild("DetikLabel")

local MAX_ITEMS = 10
local REFRESH_TIME = 120
local currentTimer = REFRESH_TIME

UpdateDonationBoard.OnClientEvent:Connect(function(top10Data)
    currentTimer = REFRESH_TIME
    
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
    
    -- Bersihkan frame yang tidak masuk Top 10 / kosong
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
end)

-- Loop Countdown Timer
task.spawn(function()
    while true do
        task.wait(1)
        if currentTimer > 0 then
            currentTimer -= 1
            timerLabel.Text = "Update: " .. tostring(currentTimer) .. "s"
        else
            timerLabel.Text = "Updating..."
        end
    end
end)
