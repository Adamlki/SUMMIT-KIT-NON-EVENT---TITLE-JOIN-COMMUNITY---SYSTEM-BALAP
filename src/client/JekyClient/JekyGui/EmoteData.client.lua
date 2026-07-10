-- EmoteSystemClient.lua
-- StarterPlayer/StarterPlayerScripts
 
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
 
-- ============================================
-- DEBUG SETTINGS
-- ============================================
local DEBUG_MODE = false  -- Set ke true untuk debug
local function dPrint(...) if DEBUG_MODE then dPrint(...) end end
local function dWarn(...) if DEBUG_MODE then dWarn(...) end end
 
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
 
-- ============================================
-- VARIABLES
-- ============================================
local ListGui
local ListTopBar
local EmoteButton
 
local IsiGui
local EmotePanel
local ScrollingFrame
local TemplateButton
local EmoteListButton
local DanceListButton
local SearchBox
local SearchButton
local CloseButton
local SpeedBar
local SpeedSlider
 
local currentTrack = nil
local currentSpeed = 1.0
local MIN_SPEED = 0.1
local MAX_SPEED = 3.0
local isFrameOpen = false
local currentMode = "dance"  -- "dance" atau "emote"
local currentPlayingButton = nil
 
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
 
-- ============================================
-- COLORS
-- ============================================
local COLORS = {
Cyan = Color3.fromRGB(255, 255, 255),      -- Dance color
Magenta = Color3.fromRGB(255, 255, 255),   -- Emote color
White = Color3.fromRGB(255, 255, 255),
Yellow = Color3.fromRGB(255, 255, 255),    -- Playing color
FeedbackActive = Color3.fromRGB(255, 105, 180)
}
 
-- ============================================
-- ANIMATION DATA
-- ============================================
local dances = {
{name="6 7 Dance", animId=117961236980639},
{name="rings dance", animId=74387250908176},
{name="Accuracy Dance", animId=83600187972870},
{name="Acelerada", animId=103360497719320},
{name="Antifragile", animId=84561978111673},
{name="Apa sto lupa le", animId=85247727536511},
{name="Applaud", animId=10713966026},
{name="Ashi ashi dance", animId=91762541141326},
{name="Aura Farming", animId=80310147207105},
{name="BLACKPINK", animId=79979515443365},
{name="BLACKPINK 2", animId=85478531180450},
{name="Baby Funk Dance", animId=102042722639175},
{name="Bad Romance", animId=109367770639860},
{name="Barcola Dance", animId=83064564490945},
{name="Bboy Hip Hop", animId=106522914573804},
{name="Beggin", animId=72816626774477},
{name="Belly Dance", animId=85312683743028},
{name="Bhangra Dance", animId=78416657618448},
{name="Big G Bounce", animId=115193774522990},
{name="Billy Bounce", animId=133394554631338},
{name="Bones Dance", animId=15689279687},
{name="Boogie Down", animId=99662142344622},
{name="Bouncy Cute", animId=106398383152416},
{name="Boy'S A Liar", animId=131210953953073},
{name="Break", animId=96078519637664},
{name="BreakDancing", animId=107853684946252},
{name="Breakdance", animId=139316100443270},
{name="Bye Bye Bye", animId=134594513356628},
{name="Cabare dance", animId=79245915329984},
{name="Calamity", animId=72298834433396},
{name="Candy Emote", animId=136073073685621},
{name="Cat Car Dance", animId=74363280528801},
{name="Cat Dancing", animId=115465748102845},
{name="Cha Cha Dance", animId=90166098423888},
{name="Chainsaw Man", animId=128611142091245},
{name="Coffin Walkout", animId=126771729094882},
{name="Confess Dance", animId=80332660504444},
{name="Cortis", animId=84411629009577},
{name="Criss-Cross", animId=81733449586987},
{name="Cute Dance", animId=15517864808},
{name="DARE - Gorillaz", animId=94569503223288},
}
 
local emotes = {
{name="2017X Point", animId=93810591156861},
{name="Chill Guy", animId=107466254930590},
{name="Elegant Picture", animId=113345525010569},
{name="Fashionable Pretty", animId=133076490374907},
{name="For the Pic", animId=117336874204710},
{name="Wall Lean", animId=113694692828125},
{name="Cower", animId=4940563117},
{name="Jumping Wave", animId=10714378156},
{name="Sad", animId=131737004503275},
{name="Sleep Face", animId=10714360343},
{name="Spiderman", animId=123888267685221},
{name="Squat Sit", animId=84129863420846},
{name="Fantano Squat", animId=124972507696792},
{name="Cute Hips", animId=117181705578424},
{name="sit", animId=86898753801433},
{name="Spiderman Hanging", animId=82468904268739},
{name="Shinra Pose", animId=121514889513586},
{name="Fashion", animId=93106139772346},
{name="Sit 2", animId=102544119718369},
{name="Kid tantrum", animId=86339673982616},
{name="Police Vest Rest", animId=83026903211659},
{name="Bang Head", animId=89060597619453},
{name="Sweet Hug V2", animId=118264035209903},
{name="girl idle pose", animId=89439480855309},
{name="FF Push Up", animId=76988349893259},
{name="Bored", animId=10713992055},
{name="Sleeping Soundly", animId=121641415206650},
{name="Swinging", animId=78512680384025},
{name="Fetal Crying", animId=87595043597341},
{name="sitting idle pose", animId=112618514893492},
{name="Adventure Pose", animId=105286298891700},
{name="Sweet Sit V1", animId=75141049180386},
{name="sit and hug", animId=117154715182434},
{name="Pose 1", animId=90198206120117},
{name="Handstand Pose", animId=75102478510616},
{name="doll idle pose", animId=75578209828688},
{name="Nonchalant Sit", animId=124882373076963},
{name="Spider Swing", animId=120676400102543},
{name="Hero Landing", animId=10714360164},
}
 
-- ============================================
-- PLAY ANIMATION
-- ============================================
local function playAnimation(animId, buttonClicked)
    -- Check if clicking the same button that's currently playing
    if currentPlayingButton == buttonClicked and currentTrack and currentTrack.IsPlaying then
        -- Stop the animation
        currentTrack:Stop()
        currentTrack:Destroy()
        currentTrack = nil
        
        -- Return button color to mode color
        local modeColor = currentMode == "dance" and COLORS.Cyan or COLORS.Magenta
        buttonClicked.TextColor3 = modeColor
        currentPlayingButton = nil
        
        if DEBUG_MODE then dPrint("[EmoteSystem] Stopped animation") end
        return
    end
    
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    
    -- Stop current track
    if currentTrack then
        currentTrack:Stop()
        currentTrack:Destroy()
        currentTrack = nil
    end
    
    -- Reset previous button color
    if currentPlayingButton then
        -- Return to mode color (cyan for dance, magenta for emote)
        local modeColor = currentMode == "dance" and COLORS.Cyan or COLORS.Magenta
        currentPlayingButton.TextColor3 = modeColor
    end
    
    -- Create new animation
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://"..animId
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        currentTrack = animator:LoadAnimation(anim)
    else
        currentTrack = humanoid:LoadAnimation(anim)
    end
    
    currentTrack.Priority = Enum.AnimationPriority.Action4
    currentTrack:Play()
    currentTrack:AdjustSpeed(currentSpeed)
    
    -- Set button to yellow (playing)
    if buttonClicked then
        buttonClicked.TextColor3 = COLORS.Yellow
        currentPlayingButton = buttonClicked
    end
    
    if DEBUG_MODE then dPrint("[EmoteSystem] Playing animation: " .. animId) end
end
 
-- ============================================
-- SPEED CONTROL
-- ============================================
local function updateSpeed()
    if currentTrack and currentTrack.IsPlaying then
        currentTrack:AdjustSpeed(currentSpeed)
    end
    
    -- Update slider position
    if SpeedSlider and SpeedBar then
        local percentage = (currentSpeed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
        local barWidth = SpeedBar.AbsoluteSize.X - SpeedSlider.AbsoluteSize.X
        local newX = barWidth * percentage
        
        SpeedSlider.Position = UDim2.new(0, newX, SpeedSlider.Position.Y.Scale, SpeedSlider.Position.Y.Offset)
    end
end
 
local function setSpeedFromSlider(positionX)
    if not SpeedBar then return end
    
    local minX = SpeedBar.AbsolutePosition.X
    local maxX = minX + SpeedBar.AbsoluteSize.X - (SpeedSlider and SpeedSlider.AbsoluteSize.X or 0)
    
    local relativeX = math.clamp(positionX, minX, maxX) - minX
    local barWidth = maxX - minX
    
    currentSpeed = MIN_SPEED + ((relativeX / barWidth) * (MAX_SPEED - MIN_SPEED))
    
    updateSpeed()
end
 
local function initializeSpeedSlider()
    if not SpeedBar or not SpeedSlider then 
        if DEBUG_MODE then dWarn("[EmoteSystem] SpeedBar or SpeedSlider not found!") end
        return 
    end
    
    local isDragging = false
    
    SpeedSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
            input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
            input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
            input.UserInputType == Enum.UserInputType.Touch) then
            setSpeedFromSlider(input.Position.X)
        end
    end)
    
    SpeedBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
            input.UserInputType == Enum.UserInputType.Touch then
            setSpeedFromSlider(input.Position.X)
        end
    end)
    
    -- Initialize to normal speed (1.0)
    currentSpeed = 1.0
    updateSpeed()
end
 
-- ============================================
-- UPDATE LIST
-- ============================================
local function updateList(searchTerm)
    if not ScrollingFrame or not TemplateButton then 
        if DEBUG_MODE then dWarn("[EmoteSystem] ScrollingFrame or TemplateButton not found!") end
        return 
    end
    
    -- Clear existing buttons
    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name == "AnimButton" then
            child:Destroy()
        end
    end
    
    local list = currentMode == "dance" and dances or emotes
    local displayList = {}
    
    -- Filter by search term
    if searchTerm and searchTerm ~= "" then
        for _, item in ipairs(list) do
            if string.find(string.lower(item.name), string.lower(searchTerm)) then
                table.insert(displayList, item)
            end
        end
    else
        displayList = list
    end
    
    -- Get color based on mode
    local modeColor = currentMode == "dance" and COLORS.Cyan or COLORS.Magenta
    
    -- Create buttons
    for i, item in ipairs(displayList) do
        local newButton = TemplateButton:Clone()
        newButton.Name = "AnimButton"
        newButton.LayoutOrder = i
        newButton.Visible = true
        newButton.Text = item.name
        
        -- Fix scrolling on mobile: set Active to false so button doesn't block swipe
        newButton.Active = false
        
        -- Set color based on mode (cyan for dance, magenta for emote)
        newButton.TextColor3 = modeColor
        
        newButton.MouseButton1Click:Connect(function()
            playAnimation(item.animId, newButton)
        end)
        
        newButton.Parent = ScrollingFrame
    end
    
    -- Update canvas size
    ScrollingFrame.Active = true
    ScrollingFrame.ScrollingEnabled = true
    ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    -- Dihapus agar tidak menimpa settingan CanvasSize {0, 0}, {3, 0} dari Studio:
    -- ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    if DEBUG_MODE then dPrint("[EmoteSystem] Updated list with " .. #displayList .. " items") end
end
 
-- ============================================
-- SWITCH MODE (DANCE/EMOTE)
-- ============================================
local function switchMode(mode)
    currentMode = mode
    
    -- Get original colors
    local danceOriginalColor = DanceListButton and DanceListButton.BackgroundColor3 or COLORS.White
    local emoteOriginalColor = EmoteListButton and EmoteListButton.BackgroundColor3 or COLORS.White
    
    -- Update button with feedback animation
    if DanceListButton then
        if mode == "dance" then
            -- Feedback animation then return to white
            TweenService:Create(DanceListButton, TweenInfo.new(0.1), {
            BackgroundColor3 = COLORS.FeedbackActive
            }):Play()
            task.wait(0.1)
            TweenService:Create(DanceListButton, TweenInfo.new(0.2), {
            BackgroundColor3 = COLORS.White
            }):Play()
        else
            -- Keep original color when not active
            DanceListButton.BackgroundColor3 = COLORS.White
        end
    end
    
    if EmoteListButton then
        if mode == "emote" then
            -- Feedback animation then return to white
            TweenService:Create(EmoteListButton, TweenInfo.new(0.1), {
            BackgroundColor3 = COLORS.FeedbackActive
            }):Play()
            task.wait(0.1)
            TweenService:Create(EmoteListButton, TweenInfo.new(0.2), {
            BackgroundColor3 = COLORS.White
            }):Play()
        else
            -- Keep original color when not active
            EmoteListButton.BackgroundColor3 = COLORS.White
        end
    end
    
    -- Update list
    updateList()
end
 
-- ============================================
-- OPEN/CLOSE FRAME
-- ============================================
local function openFrame()
    if not EmotePanel then return end
    
    isFrameOpen = true
    EmotePanel.Visible = true
    
    if DEBUG_MODE then dPrint("[EmoteSystem] Frame opened") end
end
 
local function closeFrame()
    if not EmotePanel then return end
    
    isFrameOpen = false
    EmotePanel.Visible = false
    
    if DEBUG_MODE then dPrint("[EmoteSystem] Frame closed") end
end
 
-- ============================================
-- AUTO CLOSE WHEN OTHER GUI CLICKED
-- ============================================
local function setupAutoClose()
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextButton") then
            -- Skip buttons that should NOT close the panel
            local skipButtons = {
            "EmoteButton", "EmoteListButton", "DanceListButton", 
            "CloseButton", "SearchButton", "SpeedSlider"
            }
            
            local shouldSkip = false
            for _, skipName in ipairs(skipButtons) do
                if gui.Name == skipName then
                    shouldSkip = true
                    break
                end
            end
            
            -- Skip buttons inside EmotePanel
            if not shouldSkip then
                local parent = gui.Parent
                local isInPanel = false
                while parent do
                    if parent == EmotePanel then
                        isInPanel = true
                        break
                    end
                    parent = parent.Parent
                end
                
                if isInPanel then
                    shouldSkip = true
                end
            end
            
            if not shouldSkip then
                gui.MouseButton1Click:Connect(function()
                    if isFrameOpen then
                        closeFrame()
                    end
                end)
            end
        end
    end
end
 
-- ============================================
-- WAIT FOR GUI ELEMENTS
-- ============================================
local function waitForElements()
    if DEBUG_MODE then dPrint("[EmoteSystem] Looking for GUI elements...") end
    
    ListGui = playerGui:WaitForChild("ListGui", 999)
    if not ListGui then return false end
    
    ListTopBar = ListGui:WaitForChild("ListTopBar", 999)
    EmoteButton = ListTopBar:WaitForChild("EmoteButton", 999)
    
    IsiGui = playerGui:WaitForChild("IsiGui", 999)
    EmotePanel = IsiGui:WaitForChild("EmotePanel", 999)
    
    ScrollingFrame = EmotePanel:WaitForChild("ScrollingFrame", 999)
    EmoteListButton = EmotePanel:WaitForChild("EmoteButton", 999)
    DanceListButton = EmotePanel:WaitForChild("DanceButton", 999)
    SearchBox = EmotePanel:WaitForChild("TextBox", 999)
    CloseButton = EmotePanel:WaitForChild("CloseButton", 999)
    SpeedBar = EmotePanel:WaitForChild("SpeedBar", 999)
    
    TemplateButton = ScrollingFrame:WaitForChild("Button", 999)
    TemplateButton.Visible = false
    
    SpeedSlider = SpeedBar:WaitForChild("SpeedSlider", 999)
    SearchButton = SearchBox:WaitForChild("Button", 999)
    
    return true
end
 
-- ============================================
-- INITIALIZE SYSTEM
-- ============================================
local function initializeSystem()
    if DEBUG_MODE then dPrint("[EmoteSystem] Initializing...") end
    
    if not waitForElements() then 
        if DEBUG_MODE then dWarn("[EmoteSystem] Failed to find GUI elements!") end
        return 
    end
    
    -- Set initial state
    if EmotePanel then
        EmotePanel.Visible = false
    end
    
    -- Initialize speed slider
    if SpeedBar and SpeedSlider then
        initializeSpeedSlider()
    end
    
    -- Update initial list
    switchMode("dance")
    
    -- Connect toggle button
    if EmoteButton then
        EmoteButton.MouseButton1Click:Connect(function()
            if isFrameOpen then
                closeFrame()
            else
                openFrame()
            end
        end)
    end
    
    -- Connect close button
    if CloseButton then
        CloseButton.MouseButton1Click:Connect(closeFrame)
    end
    
    -- Connect mode switch buttons
    if DanceListButton then
        DanceListButton.MouseButton1Click:Connect(function()
            switchMode("dance")
        end)
    end
    
    if EmoteListButton then
        EmoteListButton.MouseButton1Click:Connect(function()
            switchMode("emote")
        end)
    end
    
    -- Connect search
    if SearchButton and SearchBox then
        SearchButton.MouseButton1Click:Connect(function()
            local searchTerm = SearchBox.Text
            updateList(searchTerm)
        end)
        
        SearchBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local searchTerm = SearchBox.Text
                updateList(searchTerm)
            end
        end)
    end
    
    -- Setup auto close
    setupAutoClose()
    
    if DEBUG_MODE then dPrint("[EmoteSystem] Initialization complete!") end
end
 
-- ============================================
-- MAIN EXECUTION
-- ============================================
task.spawn(function()
    task.wait(1)
    
    local success, err = pcall(initializeSystem)
    if not success then
        dWarn("[EmoteSystem ERROR]: " .. err)
    end
end)

