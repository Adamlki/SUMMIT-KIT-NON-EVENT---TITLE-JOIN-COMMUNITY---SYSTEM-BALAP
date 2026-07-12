-- StarterPlayerScripts/AvatarChangerClient.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local BundleList = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BundleList"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- AVATAR DATA (USER ID) - MIXED 50 TOTAL
-- ============================================
local AVATAR_LIST = {
    -- ImageLabel1
    8891157967,
    
    -- Cowok (28)
    9101259798, 8912185225, 8935877365, 8352609716,
    9066296823, 5864789650, 9156222022, 9406495776,
    8823452449, 8366141447, 8783760099, 9242309744,
    9063212140, 8731612980, 8549057166, 9064898850,
    8936833167, 8792379592, 7260068521, 9387216928,
    8346379536, 9397013343, 9173293538, 9269235517,
    1125045383, 9619111386, 3060549723, 8653021426,
    7779810863, 8978251546, 8995081216, 8383397608,
    5761318042, 8384430762, 10179011419,3504674222,
    
    -- Cewek (20)
    9181935703, 7843828496, 3226668321, 9201287345,
    8592887007, 9190893909, 9320802325, 9101211561,
    7842783216, 9088019808, 9349422733, 9001659720,
    8919260507, 9200798149, 9473909909, 8985697634,
    8648877923, 9025127598, 9046872011, 8989241684
}

-- ============================================
-- ANIMATION IMAGE DATA
-- ============================================
-- Masukkan ID Image untuk masing-masing kategori di bawah ini:
local CATEGORY_IMAGE_IDS = {
    Bandle = "rbxassetid://85636939460092",
    Climb = "rbxassetid://70618576227992",
    Fall = "rbxassetid://106721127126025",
    Idle = "rbxassetid://132122935420335",
    Jump = "rbxassetid://111609213402233",
    Run = "rbxassetid://134863309474341",
    Swim = "rbxassetid://81938921882443",
    Walk = "rbxassetid://75959277338553",
}

-- ============================================
-- VARIABLES
-- ============================================
local ListGui, AvatarButtonToggle
local IsiGui, AvatarPanel
local SearchTextBox, SearchButton, CloseButton
local AvatarCatalog, AnimationCatalog, ButtonMenuFrame
local MenuAnimationButton, MenuAvatarButton

-- Avatar Variables
local AvatarScrollingFrame, PreviewLabel, ApplyButton, RemoveButton
local selectedUserId = nil
local currentAppliedAvatar = nil

-- Animation Variables
local AnimButtonFrame, AnimScrollingFrame, AnimTamplateButton, AnimTextBox, AnimSearchButton
local ResetAnimationBtn
local currentAnimCategory = "Bandle"
local currentSelectedAnims = {} -- { [category] = id }
local defaultAnimBtnColor = Color3.fromRGB(255, 255, 255)

local isPanelOpen = false

local originalPosition
local hiddenPosition
local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- RemoteEvents
local ChangeAvatarEvent, ResetAvatarEvent, ApplyAnimationEvent

-- ============================================
-- UPDATE BUTTON VISIBILITY & TEXT (AVATAR)
-- ============================================
local function updateButtons()
    if not ApplyButton or not RemoveButton then return end
    
    if currentAppliedAvatar == selectedUserId then
        ApplyButton.Text = "Diterapkan"
    else
        ApplyButton.Text = "Terapkan"
    end
    
    ApplyButton.Visible = true
    RemoveButton.Visible = true
end

-- ============================================
-- UPDATE PREVIEW LABEL (AVATAR)
-- ============================================
local function updatePreview(userId)
    if not PreviewLabel then return end
    
    task.spawn(function()
        local success, thumbnailUrl = pcall(function()
            return Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.AvatarThumbnail,
            Enum.ThumbnailSize.Size420x420
            )
        end)
        
        if success and thumbnailUrl then
            PreviewLabel.Image = thumbnailUrl
            PreviewLabel.ImageRectOffset = Vector2.new(75, 0)
            PreviewLabel.ImageRectSize = Vector2.new(270, 420)
        end
    end)
end

-- ============================================
-- UPDATE BUTTON STATES (AVATAR)
-- ============================================
local function updateButtonStates()
    local AvatarTamplateButton = AvatarScrollingFrame:FindFirstChild("TamplateButton")
    local defaultColor = AvatarTamplateButton and AvatarTamplateButton.BackgroundColor3 or Color3.fromRGB(255, 255, 255)
    
    for _, btn in ipairs(AvatarScrollingFrame:GetChildren()) do
        if btn:IsA("TextButton") and btn.Name == "AvatarItem" then
            local idAttr = btn:GetAttribute("UserId")
            if idAttr == selectedUserId then
                btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            else
                btn.BackgroundColor3 = defaultColor
            end
        end
    end
end

-- ============================================================
-- SEARCH USERNAME (AVATAR)
-- ============================================
local function searchUsername()
    local username = SearchTextBox.Text:gsub("%s+", "")
    if username == "" then return end
    
    local success, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    
    if success and userId then
        selectedUserId = userId
        updatePreview(userId)
        updateButtonStates()
        updateButtons()
    else
        SearchTextBox.PlaceholderText = "User not found"
        task.wait(2)
        SearchTextBox.PlaceholderText = "Enter username"
    end
    
    SearchTextBox.Text = ""
end

-- ============================================
-- ANIMATION LOGIC
-- ============================================

local function applyBundle(bundleId, bundleName)
    local char = player.Character
    if not char then return end

    if ApplyAnimationEvent then
        ApplyAnimationEvent:FireServer({type = "Bundle", id = bundleId, name = bundleName})
    end
end

local function applyAnimation(category, animId)
    local char = player.Character
    if not char then return end
    
    if ApplyAnimationEvent then
        ApplyAnimationEvent:FireServer({type = "Single", category = category, id = animId})
    end
end

local currentLoadThread = nil

local function loadAnimationList(category, searchTerm)
    if not AnimScrollingFrame then 
        warn("[AvatarKatalog] AnimScrollingFrame is nil!")
        return 
    end
    if not AnimTamplateButton then 
        warn("[AvatarKatalog] AnimTamplateButton is nil! ScrollingFrame children: ")
        for _, v in ipairs(AnimScrollingFrame:GetChildren()) do
            print(" - " .. v.Name)
        end
        return 
    end
    
    -- Batalkan pemuatan sebelumnya jika ada (biar tidak tumpang tindih)
    if currentLoadThread then
        task.cancel(currentLoadThread)
    end
    
    currentAnimCategory = category
    
    if AnimButtonFrame then
        for _, btn in ipairs(AnimButtonFrame:GetChildren()) do
            if btn:IsA("TextButton") then
                if btn.Name == category .. "Button" then
                    btn.TextColor3 = Color3.fromRGB(0, 255, 0)
                else
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end
    
    if AnimTextBox then
        AnimTextBox.PlaceholderText = "Loading..."
    end
    
    currentLoadThread = task.spawn(function()
        -- Hapus item saat ini
        for _, child in ipairs(AnimScrollingFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name == "AnimItem" then
                child:Destroy()
            end
        end
        
        -- Berikan jeda kecil agar game sempat membersihkan frame sebelum membuat baru
        task.wait()
        
        local imageId = CATEGORY_IMAGE_IDS[category] or ""
        local itemsCreated = 0
        local BATCH_SIZE = 15 -- Jumlah tombol yang dibuat per frame (biar gak patah-patah)
        
        for i, bundleData in ipairs(BundleList) do
            local bundleName = bundleData.Name
            local bundleId = bundleData.Id
            
            if not searchTerm or searchTerm == "" or string.find(string.lower(bundleName), string.lower(searchTerm)) then
                local btn = AnimTamplateButton:Clone()
                btn.Name = "AnimItem"
                btn.Visible = true
                btn.LayoutOrder = i
                
                -- Untuk menu single, ID tidak perlu pakai prefix kategori karena table sudah dipisah
                local uniqueId = tostring(bundleId)
                btn:SetAttribute("AnimId", uniqueId)
                
                if currentSelectedAnims[category] == uniqueId then
                    btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                else
                    btn.BackgroundColor3 = defaultAnimBtnColor
                end
                
                local img = btn:FindFirstChild("ImageLabel")
                local txt = btn:FindFirstChild("TextLabel")
                
                if img then img.Image = imageId end
                if txt then txt.Text = bundleName end
                
                btn.MouseButton1Click:Connect(function()
                    if currentSelectedAnims[category] == uniqueId then
                        -- Unequip (Lepas)
                        if category == "Bandle" then
                            if ApplyAnimationEvent then
                                ApplyAnimationEvent:FireServer({type = "Reset"})
                            end
                        else
                            if ApplyAnimationEvent then
                                ApplyAnimationEvent:FireServer({type = "UnequipSingle", category = category})
                            end
                        end
                    else
                        -- Equip (Pasang)
                        if category == "Bandle" then
                            applyBundle(bundleId, bundleName)
                        else
                            if ApplyAnimationEvent then
                                ApplyAnimationEvent:FireServer({type = "SingleBundle", category = category, id = bundleId, name = bundleName})
                            end
                        end
                    end
                end)
                
                btn.Parent = AnimScrollingFrame
                itemsCreated = itemsCreated + 1
                
                if itemsCreated % BATCH_SIZE == 0 then
                    task.wait()
                end
            end
        end
        
        AnimScrollingFrame.CanvasPosition = Vector2.new(0, 0)
        
        -- Kembalikan teks placeholder
        if AnimTextBox then
            AnimTextBox.PlaceholderText = "Search..."
        end
    end)
end

-- ============================================
-- TOGGLE TABS
-- ============================================
local function switchTab(tabName)
    if not AvatarCatalog or not AnimationCatalog then return end
    
    if tabName == "Avatar" then
        AvatarCatalog.Visible = true
        AnimationCatalog.Visible = false
        if MenuAvatarButton then
            MenuAvatarButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Active color
        end
        if MenuAnimationButton then
            MenuAnimationButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Inactive color
        end
    elseif tabName == "Animation" then
        AvatarCatalog.Visible = false
        AnimationCatalog.Visible = true
        if MenuAnimationButton then
            MenuAnimationButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Active color
        end
        if MenuAvatarButton then
            MenuAvatarButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Inactive color
        end
        -- Load Bandle by default when switching to Animation
        loadAnimationList("Bandle")
    end
end

-- ============================================
-- OPEN/CLOSE PANEL
-- ============================================
function openPanel()
    isPanelOpen = true
    AvatarPanel.Visible = true
    TweenService:Create(AvatarPanel, tweenInfo, {Position = originalPosition}):Play()
    
    if AvatarButtonToggle then
        TweenService:Create(AvatarButtonToggle, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        }):Play()
    end
    
    if currentAppliedAvatar then
        selectedUserId = currentAppliedAvatar
        updatePreview(currentAppliedAvatar)
    else
        selectedUserId = AVATAR_LIST[1]
        updatePreview(AVATAR_LIST[1])
    end
    
    updateButtons()
    
    -- Default open in AvatarCatalog
    switchTab("Avatar")
end

function closePanel()
    isPanelOpen = false
    TweenService:Create(AvatarPanel, tweenInfo, {Position = hiddenPosition}):Play()
    
    if AvatarButtonToggle then
        TweenService:Create(AvatarButtonToggle, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        }):Play()
    end
    
    task.wait(0.35)
    AvatarPanel.Visible = false
end

-- ============================================
-- APPLY AVATAR
-- ============================================
local function applyAvatar()
    if not selectedUserId then return end
    
    if currentAppliedAvatar == selectedUserId then
        closePanel()
        return
    end
    
    -- Server handles tools backup/restore
    ChangeAvatarEvent:FireServer(selectedUserId)
    currentAppliedAvatar = selectedUserId
    updateButtons()
    
    task.wait(0.5)
    closePanel()
end

-- ============================================
-- REMOVE AVATAR (RESET TO ORIGINAL)
-- ============================================
local function removeAvatar()
    if currentAppliedAvatar == nil then
        closePanel()
        return
    end
    
    -- Server handles tools backup/restore
    ResetAvatarEvent:FireServer()
    currentAppliedAvatar = nil
    updateButtons()
    
    task.wait(0.5)
    closePanel()
end

-- ============================================
-- SETUP IMAGE LABELS (AVATAR)
-- ============================================
local function setupImageLabels()
    if not AvatarScrollingFrame then return end
    
    local AvatarTamplateButton = AvatarScrollingFrame:FindFirstChild("TamplateButton")
    if not AvatarTamplateButton then return end
    AvatarTamplateButton.Visible = false
    
    -- Bersihkan sisa-sisa UI lama (seperti ImageLabel1-50) jika user lupa menghapusnya di Studio
    for _, child in ipairs(AvatarScrollingFrame:GetChildren()) do
        if child ~= AvatarTamplateButton and not child:IsA("UIGridLayout") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UICorner") then
            child:Destroy()
        end
    end
    
    local defaultColor = AvatarTamplateButton.BackgroundColor3
    
    for i, userId in ipairs(AVATAR_LIST) do
        local btn = AvatarTamplateButton:Clone()
        btn.Name = "AvatarItem"
        btn.Visible = true
        btn.LayoutOrder = i
        
        local img = btn:FindFirstChild("ImageLabel")
        if img then
            img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
        end
        
        if selectedUserId == userId then
            btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        else
            btn.BackgroundColor3 = defaultColor
        end
        
        btn.MouseButton1Click:Connect(function()
            selectedUserId = userId
            updatePreview(userId)
            updateButtonStates()
            updateButtons()
        end)
        
        btn:SetAttribute("UserId", userId)
        btn.Parent = AvatarScrollingFrame
    end
end

-- ============================================
-- WAIT FOR GUI ELEMENTS
-- ============================================
local function waitForElements()
    local attempts = 0
    while attempts < 100 do
        ListGui = playerGui:FindFirstChild("ListGui")
        if ListGui then
            local listTopBar = ListGui:FindFirstChild("ListTopBar")
            if listTopBar then
                AvatarButtonToggle = listTopBar:FindFirstChild("AvatarButton")
            end
        end
        
        IsiGui = playerGui:FindFirstChild("IsiGui")
        if IsiGui then
            AvatarPanel = IsiGui:FindFirstChild("AvatarPanel")
            
            if AvatarPanel then
                AvatarCatalog = AvatarPanel:FindFirstChild("AvatarCatalog")
                AnimationCatalog = AvatarPanel:FindFirstChild("AnimationCatalog")
                ButtonMenuFrame = AvatarPanel:FindFirstChild("ButtonMenuFrame")
                CloseButton = AvatarPanel:FindFirstChild("CloseButton")
                
                if AvatarCatalog and AnimationCatalog and ButtonMenuFrame then
                    -- Avatar Elements
                    SearchTextBox = AvatarCatalog:FindFirstChild("TextBox")
                    if SearchTextBox then
                        SearchButton = SearchTextBox:FindFirstChild("Button")
                    end
                    AvatarScrollingFrame = AvatarCatalog:FindFirstChild("ScrollingFrame")
                    PreviewLabel = AvatarCatalog:FindFirstChild("PreviewLabel")
                    
                    if PreviewLabel then
                        ApplyButton = PreviewLabel:FindFirstChild("ApplyButton")
                        RemoveButton = PreviewLabel:FindFirstChild("RemoveButton")
                    end
                    
                    -- Animation Elements
                    AnimButtonFrame = AnimationCatalog:FindFirstChild("ButtonFrame")
                    AnimScrollingFrame = AnimationCatalog:FindFirstChild("ScrollingFrame")
                    AnimTextBox = AnimationCatalog:FindFirstChild("TextBox")
                    ResetAnimationBtn = AnimationCatalog:FindFirstChild("ResetAnimationBtn")
                    if AnimTextBox then
                        AnimSearchButton = AnimTextBox:FindFirstChild("Button")
                    end
                    
                    if AnimScrollingFrame then
                        AnimTamplateButton = AnimScrollingFrame:FindFirstChild("TamplateButton")
                        if AnimTamplateButton then 
                            AnimTamplateButton.Visible = false 
                            defaultAnimBtnColor = AnimTamplateButton.BackgroundColor3
                        end
                    end
                    
                    -- Menu Buttons
                    MenuAnimationButton = ButtonMenuFrame:FindFirstChild("AnimationButton")
                    MenuAvatarButton = ButtonMenuFrame:FindFirstChild("AvatarButton")
                    
                    if AvatarButtonToggle and CloseButton and AvatarScrollingFrame and PreviewLabel and ApplyButton and RemoveButton and AnimTamplateButton then
                        return true
                    end
                end
            end
        end
        
        attempts = attempts + 1
        task.wait(0.1)
    end
    
    return false
end

-- ============================================
-- INITIALIZE SYSTEM
-- ============================================
local function initializeSystem()
    if not waitForElements() then return end
    
    local RepStorage = game:GetService("ReplicatedStorage")
    ChangeAvatarEvent = RepStorage:FindFirstChild("ChangeAvatarEvent")
    ResetAvatarEvent = RepStorage:FindFirstChild("ResetAvatarEvent")
    ApplyAnimationEvent = RepStorage:FindFirstChild("ApplyAnimationEvent")
    
    if not ChangeAvatarEvent or not ResetAvatarEvent then return end
    
    -- Setup PreviewLabel properties
    PreviewLabel.BackgroundTransparency = 1
    PreviewLabel.ScaleType = Enum.ScaleType.Fit
    PreviewLabel.SizeConstraint = Enum.SizeConstraint.RelativeXY
    PreviewLabel.ResampleMode = Enum.ResamplerMode.Default
    
    local aspect = PreviewLabel:FindFirstChildOfClass("UIAspectRatioConstraint")
    if not aspect then
        aspect = Instance.new("UIAspectRatioConstraint")
        aspect.Parent = PreviewLabel
    end
    aspect.AspectRatio = 110 / 200
    aspect.DominantAxis = Enum.DominantAxis.Height
    
    -- Setup positions
    originalPosition = AvatarPanel.Position
    hiddenPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1.2, 0)
    
    -- Initial state
    AvatarPanel.Visible = false
    AvatarPanel.Position = hiddenPosition
    
    -- Setup Notifications
    local AnimationNotificationEvent = RepStorage:WaitForChild("AnimationNotificationEvent")
    AnimationNotificationEvent.OnClientEvent:Connect(function(success, message, data)
        game.StarterGui:SetCore("SendNotification", {
            Title = success and "Sukses" or "Gagal",
            Text = message,
            Duration = 3
        })
        
        if success and data then
            if data.type == "Reset" then
                currentSelectedAnims = {}
            elseif data.type == "Bundle" then
                currentSelectedAnims = { ["Bandle"] = tostring(data.id) }
            elseif data.type == "SingleBundle" then
                currentSelectedAnims[data.category] = tostring(data.id)
            elseif data.type == "UnequipSingle" then
                currentSelectedAnims[data.category] = nil
            end
            
            if AnimScrollingFrame then
                for _, btn in ipairs(AnimScrollingFrame:GetChildren()) do
                    if btn:IsA("TextButton") and btn.Name == "AnimItem" then
                        local attr = btn:GetAttribute("AnimId")
                        if attr and tostring(attr) == currentSelectedAnims[currentAnimCategory] then
                            btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        else
                            btn.BackgroundColor3 = defaultAnimBtnColor
                        end
                    end
                end
            end
        end
    end)
    
    -- Setup ImageLabels
    setupImageLabels()
    
    -- Connect AvatarButton (toggle in topbar)
    AvatarButtonToggle.MouseButton1Click:Connect(function()
        if isPanelOpen then
            closePanel()
        else
            openPanel()
        end
    end)
    
    -- Connect Tab Buttons
    if MenuAvatarButton then
        MenuAvatarButton.MouseButton1Click:Connect(function()
            switchTab("Avatar")
        end)
    end
    if MenuAnimationButton then
        MenuAnimationButton.MouseButton1Click:Connect(function()
            switchTab("Animation")
        end)
    end
    
    -- Connect Animation Category Buttons
    if AnimButtonFrame then
        local categories = {"Bandle", "Climb", "Fall", "Idle", "Jump", "Run", "Swim", "Walk"}
        for _, cat in ipairs(categories) do
            local btn = AnimButtonFrame:FindFirstChild(cat .. "Button")
            if btn then
                btn.MouseButton1Click:Connect(function()
                    loadAnimationList(cat)
                end)
            end
        end
    end
    
    -- Connect SearchButtons
    if SearchButton then
        SearchButton.MouseButton1Click:Connect(searchUsername)
    end
    if SearchTextBox then
        SearchTextBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                searchUsername()
            end
        end)
    end
    
    if ResetAnimationBtn then
        ResetAnimationBtn.MouseButton1Click:Connect(function()
            if ApplyAnimationEvent then
                ApplyAnimationEvent:FireServer({type = "Reset"})
            end
        end)
    end
    
    if AnimSearchButton then
        AnimSearchButton.MouseButton1Click:Connect(function()
            loadAnimationList(currentAnimCategory, AnimTextBox.Text)
        end)
    end
    if AnimTextBox then
        AnimTextBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                loadAnimationList(currentAnimCategory, AnimTextBox.Text)
            end
        end)
    end
    
    -- Connect CloseButton
    CloseButton.MouseButton1Click:Connect(closePanel)
    
    -- Connect ApplyButton
    ApplyButton.MouseButton1Click:Connect(applyAvatar)
    
    -- Connect RemoveButton
    RemoveButton.MouseButton1Click:Connect(removeAvatar)
    
    -- Auto close when other TextButtons in ListGui clicked
    if ListGui then
        for _, gui in ipairs(ListGui:GetDescendants()) do
            if gui:IsA("TextButton") and gui ~= AvatarButtonToggle then
                gui.MouseButton1Click:Connect(function()
                    if isPanelOpen then
                        closePanel()
                    end
                end)
            end
        end
    end
end

-- ============================================
-- MAIN EXECUTION
-- ============================================
task.spawn(function()
    task.wait(2)
    initializeSystem()
    
    player.CharacterAdded:Connect(function()
        task.wait(2)
        waitForElements()
    end)
end)


