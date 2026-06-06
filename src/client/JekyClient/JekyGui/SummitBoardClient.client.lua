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

-- [OPTIMASI] Gunakan fungsi findLBs secara dinamis agar anti-error saat StreamingEnabled
local function getActiveLBs()
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
            Model     = model,
            BSG       = bsg,
            DSG       = dsg,
            IsGlobal  = isG,
            Interval  = isG and CONFIG.GLOBAL_INTERVAL or CONFIG.SERVER_INTERVAL,
        })
    end
    return list
end

local SrvData = {}
local GlbData = {}
local LbTimers = {} -- Menyimpan state timer untuk tiap papan
local lastGlobalSync = 0
local lastServerSync = 0

local function render(lb)
    local init = lb.BSG:FindFirstChild("Init")
    if not init then return end
    
    local data = lb.IsGlobal and GlbData or SrvData
    local currentSync = lb.IsGlobal and lastGlobalSync or lastServerSync
    
    -- Cegah merender ulang jika datanya sama dan model belum dire-render
    if lb.Model:GetAttribute("LastSync") == currentSync then return end
    
    for i = 1, CONFIG.MAX_ENTRIES do
        local tf = init:FindFirstChild("Top"..i)
        if not tf then continue end
        
        local ul = tf:FindFirstChild("Username")
        local tl = tf:FindFirstChild("Total")
        local il = tf:FindFirstChild("ImageLabel")
        if not (ul and tl) then continue end
        
        -- FIX: Paksa teks agar tidak turun ke baris kedua (yang bikin teks jadi hilang/kosong)
        ul.TextWrapped = false
        ul.TextScaled = true
        tl.TextWrapped = false
        tl.TextScaled = true
        
        local e = data[i]
        if e then
            tf.Visible = true -- Tampilkan frame jika ada data
            ul.Text = i..". "..e.Username
            tl.Text = "⛰️ "..fmtNum(e.Summit)
            if il and il:IsA("ImageLabel") then
                il.Image = "rbxthumb://type=AvatarHeadShot&id="..e.UserId.."&w=150&h=150"
            end
        else
            tf.Visible = false -- Sembunyikan frame jika kosong
            ul.Text = i..". ---"
            tl.Text = "⛰️ 0"
            if il and il:IsA("ImageLabel") then il.Image = "" end
        end
    end
    
    lb.Model:SetAttribute("LastSync", currentSync)
end

UpdateSummitBoard.OnClientEvent:Connect(function(payload)
    if payload.Type == "Server" then
        SrvData = payload.Data
        lastServerSync = os.time()
    elseif payload.Type == "Global" then
        GlbData = payload.Data
        lastGlobalSync = os.time()
    elseif payload.Type == "UpdateNames" then
        if payload.ServerData then SrvData = payload.ServerData; lastServerSync = os.time() end
        if payload.GlobalData then GlbData = payload.GlobalData; lastGlobalSync = os.time() end
    end
    
    -- Reset timer berdasarkan event data yang masuk
    for _, lb in ipairs(getActiveLBs()) do
        if payload.Type == "Global" and lb.IsGlobal then
            LbTimers[lb.Model] = lb.Interval
        elseif payload.Type == "Server" and not lb.IsGlobal then
            LbTimers[lb.Model] = lb.Interval
        end
        render(lb)
    end
end)

-- Background Countdown Loop & Streaming Recovery
task.spawn(function()
    while true do
        task.wait(1)
        
        local activeLBs = getActiveLBs()
        for _, lb in ipairs(activeLBs) do
            -- Inisialisasi timer jika belum ada
            if not LbTimers[lb.Model] then
                LbTimers[lb.Model] = lb.Interval
            end
            
            -- Kurangi timer
            LbTimers[lb.Model] = math.max(0, LbTimers[lb.Model] - 1)
            
            local dtlb = lb.DSG:FindFirstChild("DetikLabel")
            if dtlb then
                local t = LbTimers[lb.Model]
                dtlb.Text = t > 0 and ("Update in "..t.." second"..(t ~= 1 and "s" or "")) or "Updating..."
            end
            
            -- Auto-recovery render jika model baru stream in
            render(lb)
        end
    end
end)
