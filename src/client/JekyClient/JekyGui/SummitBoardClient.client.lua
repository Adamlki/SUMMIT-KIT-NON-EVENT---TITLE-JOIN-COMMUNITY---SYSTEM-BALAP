-- StarterPlayerScripts > JekyClient > JekyGui > SummitBoardClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpdateSummitBoard = ReplicatedStorage:WaitForChild("UpdateSummitBoard")

local CONFIG = {
    MAX_ENTRIES          = 10,
    GLOBAL_INTERVAL      = 60,
    SERVER_INTERVAL      = 30,
    LB_PATH              = "AllPartSummitkitJeky/LeaderBoard",
}

local function fmtNum(n)
    n = tonumber(n) or 0
    if n >= 1e6 then return ("%.1fM"):format(n / 1e6)
    elseif n >= 1e3 then return ("%.1fK"):format(n / 1e3)
    else return tostring(math.floor(n)) end
end

local function findLBs()
    local list = {}
    local cur = workspace
    for _, part in ipairs(string.split(CONFIG.LB_PATH, "/")) do
        cur = cur:FindFirstChild(part)
        if not cur then return {} end
    end
    for _, model in ipairs(cur:GetChildren()) do
        if not model:IsA("Model") then continue end
        local nl = model.Name:lower()
        local isG = nl:find("global") ~= nil
        local isS = nl:find("server") ~= nil
        if not (isG or isS) then continue end
        
        local board = model:FindFirstChild("Board")
        local detik = model:FindFirstChild("Detik")
        if not (board and detik) then continue end
        
        local bsg = board:FindFirstChild("SurfaceGui")
        local dsg = detik:FindFirstChild("SurfaceGui")
        if not (bsg and dsg) then continue end
        
        table.insert(list, {
            BSG       = bsg,
            DSG       = dsg,
            IsGlobal  = isG,
            Interval  = isG and CONFIG.GLOBAL_INTERVAL or CONFIG.SERVER_INTERVAL,
            Countdown = isG and CONFIG.GLOBAL_INTERVAL or CONFIG.SERVER_INTERVAL,
        })
    end
    return list
end

-- Tunggu sebentar sampai Map/LeaderBoard termuat
task.wait(2)
local lbs = findLBs()
local SrvData = {}
local GlbData = {}

local function render(lb)
    local init = lb.BSG:FindFirstChild("Init")
    if not init then return end
    
    local data = lb.IsGlobal and GlbData or SrvData
    
    for i = 1, CONFIG.MAX_ENTRIES do
        local tf = init:FindFirstChild("Top"..i)
        if not tf then continue end
        
        local ul = tf:FindFirstChild("Username")
        local tl = tf:FindFirstChild("Total")
        local il = tf:FindFirstChild("ImageLabel")
        if not (ul and tl) then continue end
        
        local e = data[i]
        if e then
            ul.Text = i..". "..e.Username
            tl.Text = "⛰️ "..fmtNum(e.Summit)
            if il and il:IsA("ImageLabel") then
                il.Image = "rbxthumb://type=AvatarHeadShot&id="..e.UserId.."&w=150&h=150"
            end
        else
            ul.Text = i..". ---"
            tl.Text = "⛰️ 0"
            if il and il:IsA("ImageLabel") then il.Image = "" end
        end
    end
end

local function renderAll()
    for _, lb in ipairs(lbs) do render(lb) end
end

UpdateSummitBoard.OnClientEvent:Connect(function(payload)
    if payload.Type == "Server" then
        SrvData = payload.Data
        for _, lb in ipairs(lbs) do
            if not lb.IsGlobal then
                lb.Countdown = lb.Interval
                render(lb)
            end
        end
    elseif payload.Type == "Global" then
        GlbData = payload.Data
        for _, lb in ipairs(lbs) do
            if lb.IsGlobal then
                lb.Countdown = lb.Interval
                render(lb)
            end
        end
    elseif payload.Type == "UpdateNames" then
        if payload.ServerData then SrvData = payload.ServerData end
        if payload.GlobalData then GlbData = payload.GlobalData end
        renderAll()
    end
end)

-- Background Countdown Loop
task.spawn(function()
    while true do
        task.wait(1)
        for _, lb in ipairs(lbs) do
            lb.Countdown = lb.Countdown - 1
            local dtlb = lb.DSG:FindFirstChild("DetikLabel")
            if dtlb then
                local t = math.max(0, math.floor(lb.Countdown))
                dtlb.Text = t > 0 and ("Update in "..t.." second"..(t ~= 1 and "s" or "")) or "Updating..."
            end
        end
    end
end)
