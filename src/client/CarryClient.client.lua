--// =========================================================
--// 2. CARRY SYSTEM SCRIPT (LocalScript)
--// Bertanggung jawab untuk UI, animasi, dan menerima perintah.
--// =========================================================

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Wait for RemoteEvent
local CarryRemote = ReplicatedStorage:WaitForChild("CarryRemote")

-- Config (Angka ID harus sesuai dengan ID Animasi di Roblox)
local SIT_R15_ID = 83370779148836
local SIT_R6_ID = 71467578499689
local CARRY_R15_ID = 114247350686003
local CARRY_R6_ID = 129504764008363

-- Player/UI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- State
local carriedList, carriedIndex = {}, 1
local isCarried = false
local currentCarrierId, currentCarrierName = nil, nil
local lastRequesterId = nil
local keepUiConn = nil
local jumpBlockConn = nil

-- Dynamic UI Fetching (untuk mencegah Infinite Yield & ResetOnSpawn bug)
local function getUIElements()
	local gui = playerGui:FindFirstChild("GendongGUI")
	if not gui then return nil end
	
	local frame2 = gui:FindFirstChild("Frame2")
	local frame3 = gui:FindFirstChild("Frame3")
	if not frame2 or not frame3 then return nil end
	
	return {
		frame2 = frame2,
		btnDown = frame2:FindFirstChild("DownButton"),
		cName = frame2:FindFirstChild("NameLabel"),
		btnRight = frame2:FindFirstChild("RightButton"),
		btnLeft = frame2:FindFirstChild("LeftButton"),
		
		frame3 = frame3,
		promptLabel = frame3:FindFirstChild("TextLabel"),
		btnYes = frame3:FindFirstChild("YesButton"),
		btnNo = frame3:FindFirstChild("NoButton")
	}
end

local function setUIVisible(frameName, visible)
	local ui = getUIElements()
	if ui and ui[frameName] then
		ui[frameName].Visible = visible
	end
end

-- Helpers
local function getHumanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getAnimator(hum)
	return hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
end

local function rigIsR15(hum) 
	return hum and hum.RigType == Enum.HumanoidRigType.R15 
end

-- ==========================================
-- ANIMATION FUNCTIONS
-- ==========================================

-- Variabel Cache
local loadedSitTrack = nil
local loadedCarryTrack = nil

local function playSit()
	local hum = getHumanoid(); if not hum then return end
	hum.Sit = true
	local useId = rigIsR15(hum) and SIT_R15_ID or SIT_R6_ID
	if useId == 0 then return end
	local animator = getAnimator(hum)

	if not loadedSitTrack then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(useId)
		anim.Name = "CarrySystemAnim"
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		if ok and track then
			loadedSitTrack = track
			loadedSitTrack.Priority = Enum.AnimationPriority.Action
			loadedSitTrack.Looped = true
		end
	end

	if loadedSitTrack then
		loadedSitTrack:Play(0.2)
	end
end

local function stopSit() 
	local hum = getHumanoid()
	if loadedSitTrack then loadedSitTrack:Stop(0.2) end 
	if hum then hum.Sit = false end 
end

local function playCarry()
	local hum = getHumanoid(); if not hum then return end
	local useId = rigIsR15(hum) and CARRY_R15_ID or CARRY_R6_ID
	if useId == 0 then return end
	local animator = getAnimator(hum)

	if not loadedCarryTrack then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(useId)
		anim.Name = "CarrySystemAnim"
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		if ok and track then
			loadedCarryTrack = track
			loadedCarryTrack.Priority = Enum.AnimationPriority.Action
			loadedCarryTrack.Looped = true
		end
	end

	if loadedCarryTrack then
		loadedCarryTrack:Play(0.2)
	end
end

local function stopCarry() 
	if loadedCarryTrack then loadedCarryTrack:Stop(0.2) end 
end

local ensureCarrierAnim = function()
	if (#carriedList > 0) and (not isCarried) then 
		if not (loadedCarryTrack and loadedCarryTrack.IsPlaying) then playCarry() end 
	else 
		stopCarry() 
	end
end

local function startBlockingJump()
	if jumpBlockConn then jumpBlockConn:Disconnect() end
	jumpBlockConn = UserInputService.JumpRequest:Connect(function()
		local h = getHumanoid()
		if h then h.Jump = false end
	end)
end

local function stopBlockingJump()
	if jumpBlockConn then jumpBlockConn:Disconnect(); jumpBlockConn = nil end
end

-- ==========================================
-- UI MANAGEMENT
-- ==========================================

local function stopKeepUi()
	if keepUiConn then 
		keepUiConn:Disconnect()
		keepUiConn = nil 
	end
end

local function refreshCarrierUI()
	local count = #carriedList
	if count <= 0 then 
		setUIVisible("frame2", false)
		stopCarry()
		return 
	end

	if carriedIndex < 1 then carriedIndex = 1 end
	if carriedIndex > count then carriedIndex = count end

	local item = carriedList[carriedIndex]
	if item then
		local ui = getUIElements()
		if ui and ui.cName then
			ui.cName.Text = string.format("Carrying (%d/%d): %s", carriedIndex, count, item.name or "Player")
			ui.frame2.Visible = true
			ui.frame3.Visible = false
		end
		ensureCarrierAnim()
	end
end

local updateCarriedUI
updateCarriedUI = function()
	if isCarried then
		local ui = getUIElements()
		if ui and ui.btnDown and ui.cName then
			ui.btnDown.Visible = true
			ui.btnDown.Text = "Get Down"
			ui.cName.Text = ("Carried by: %s"):format(currentCarrierName or "Player")
			ui.frame2.Visible = true
			ui.frame3.Visible = false
		end
	else
		refreshCarrierUI()
	end
end

local function ensureStatusVisible()
	if not isCarried or not currentCarrierId then return end
	updateCarriedUI()
end

local function startKeepUi()
	stopKeepUi()
	keepUiConn = RunService.Heartbeat:Connect(function()
		if isCarried then
			ensureStatusVisible()
		else
			stopKeepUi()
		end
	end)
end

local function setModeStatusCarried(carrierName, carrierId)
	currentCarrierId = carrierId
	currentCarrierName = carrierName
	isCarried = true
	updateCarriedUI()
	startKeepUi()
	startBlockingJump()
end

local function showPromptRequest(fromId, fromName)
	lastRequesterId = fromId
	local ui = getUIElements()
	if ui and ui.promptLabel then
		ui.promptLabel.Text = ("%s wants to carry you. Allow?"):format(fromName or "Someone")
		ui.frame3.Visible = true
		ui.frame2.Visible = false
	end
end

local function addCarried(id, name)
	for _, it in ipairs(carriedList) do 
		if it.id == id then 
			it.name = name
			refreshCarrierUI()
			return 
		end
	end
	table.insert(carriedList, {id=id, name=name})
	carriedIndex = #carriedList
	refreshCarrierUI()
end

local function removeCarried(id)
	local idx
	for i, it in ipairs(carriedList) do 
		if it.id == id then 
			idx = i 
			break 
		end
	end
	if idx then table.remove(carriedList, idx) end
	if carriedIndex > #carriedList then carriedIndex = #carriedList end
	if #carriedList > 0 then
		refreshCarrierUI()
	else
		setUIVisible("frame2", false)
		stopCarry()
	end
end

local function setCarriedListFromSnapshot(list)
	carriedList = {}
	for _, it in ipairs(list or {}) do 
		table.insert(carriedList, {id = it.id, name = it.name}) 
	end
	if carriedIndex > #carriedList then carriedIndex = #carriedList end
	if carriedIndex < 1 and #carriedList > 0 then carriedIndex = 1 end

	if #carriedList > 0 then
		refreshCarrierUI()
	else
		setUIVisible("frame2", false)
		stopCarry()
	end
end

-- ==========================================
-- REMOTE HANDLERS
-- ==========================================

-- Buttons connection handling (dinamis karena UI bisa ter-reset)
local function bindButtons()
	local ui = getUIElements()
	if not ui then return end
	
	-- Pastikan connection lama dibersihkan jika diperlukan, 
	-- atau kita pakai sistem bind sederhana di sini.
	-- Karena getUIElements mengambil instance baru, kita bind event-nya ke instance tersebut.
end

-- Daripada nge-bind button sekali di awal (yang bisa rusak saat player mati & UI reset),
-- lebih baik kita handle click-nya di StarterGui secara langsung, ATAU
-- kita biarkan saja script ini bind ulang saat character added.
-- Tapi cara teraman untuk script SPS adalah menggunakan UserInputService atau GUI events 
-- di mana script menangkap input, atau kita hubungkan event tiap CharacterAdded.

player.CharacterAdded:Connect(function()
	if loadedSitTrack then loadedSitTrack:Stop(0.1); loadedSitTrack:Destroy(); loadedSitTrack = nil end
	if loadedCarryTrack then loadedCarryTrack:Stop(0.1); loadedCarryTrack:Destroy(); loadedCarryTrack = nil end

	stopKeepUi()
	stopBlockingJump()

	isCarried = false
	currentCarrierId, currentCarrierName = nil, nil
	carriedList = {}
	carriedIndex = 1

	-- Tunggu GUI load untuk bind button secara aman (Anti Lag)
	task.spawn(function()
		local gui = playerGui:WaitForChild("GendongGUI", 999)
		if not gui then return end
		
		local f2 = gui:WaitForChild("Frame2", 60)
		local f3 = gui:WaitForChild("Frame3", 60)
		if not (f2 and f3) then return end
		
		f2.Visible = false
		f3.Visible = false
		
		local btnYes = f3:WaitForChild("YesButton", 60)
		local btnNo = f3:WaitForChild("NoButton", 60)
		local btnDown = f2:WaitForChild("DownButton", 60)
		local btnRight = f2:FindFirstChild("RightButton")
		local btnLeft = f2:FindFirstChild("LeftButton")
		
		if btnYes then
			btnYes.MouseButton1Click:Connect(function()
				if lastRequesterId then
					f3.Visible = false
					CarryRemote:FireServer("Response", {requesterId = lastRequesterId, accept = true})
				end
			end)
		end

		if btnNo then
			btnNo.MouseButton1Click:Connect(function()
				if lastRequesterId then
					f3.Visible = false
					CarryRemote:FireServer("Response", {requesterId = lastRequesterId, accept = false})
				end
			end)
		end

		if btnDown then
			btnDown.MouseButton1Click:Connect(function() 
				if isCarried then
					CarryRemote:FireServer("Stop", {})
				else
					local item = carriedList[carriedIndex]
					if item and item.id then 
						CarryRemote:FireServer("Stop", {targetId = item.id})
					end
				end
			end)
		end

		if btnRight and btnLeft then
			btnRight.MouseButton1Click:Connect(function() 
				if #carriedList == 0 then return end 
				carriedIndex += 1
				if carriedIndex > #carriedList then carriedIndex = 1 end 
				refreshCarrierUI() 
			end)

			btnLeft.MouseButton1Click:Connect(function() 
				if #carriedList == 0 then return end 
				carriedIndex -= 1
				if carriedIndex < 1 then carriedIndex = #carriedList end 
				refreshCarrierUI() 
			end)
		end
	end)

	local hum = getHumanoid()
	if hum then
		hum.Sit = false
		hum.PlatformStand = false
		hum.WalkSpeed = 16
	end
end)


CarryRemote.OnClientEvent:Connect(function(action, data)
	if action == "Prompt" then
		showPromptRequest(data.fromId, data.fromName)

	elseif action == "Start" then
		if data and data.youAreCarrier then
			addCarried(data.targetId, data.targetName)
			if #carriedList > 0 and not isCarried then 
				if not (loadedCarryTrack and loadedCarryTrack.IsPlaying) then playCarry() end 
			end
		else
			if data and data.carrierName and data.carrierId then
				setModeStatusCarried(data.carrierName, data.carrierId)
				playSit()
				stopCarry()
			end
		end

	elseif action == "End" then
		if data and data.youAreCarrier then
			if data.removedId then 
				removeCarried(data.removedId) 
			end

			if #carriedList > 0 and not isCarried then 
				if not (loadedCarryTrack and loadedCarryTrack.IsPlaying) then playCarry() end 
			else 
				stopCarry() 
				setUIVisible("frame2", false)
			end
		else
			isCarried = false
			currentCarrierId, currentCarrierName = nil, nil
			stopKeepUi()
			stopSit()
			stopBlockingJump()
			setUIVisible("frame2", false)
			setUIVisible("frame3", false)
		end

	elseif action == "CarrierList" then
		if data and data.list then
			setCarriedListFromSnapshot(data.list)
		end

	elseif action == "Declined" or action == "TooFar" or action == "Busy" or action == "Failed" or action == "RequestExpired" or action == "Limit" then
		setUIVisible("frame3", false)
	elseif action == "PromptExpire" or action == "PromptClose" then
		setUIVisible("frame3", false)
	end
end)

-- Initialize bind buttons for the first time if character already spawned
if player.Character then
	-- Trigger character added manually once
	task.spawn(function()
		local gui = playerGui:WaitForChild("GendongGUI", 999)
		if not gui then return end
		
		local f2 = gui:WaitForChild("Frame2", 60)
		local f3 = gui:WaitForChild("Frame3", 60)
		if not (f2 and f3) then return end
		
		local btnYes = f3:WaitForChild("YesButton", 60)
		local btnNo = f3:WaitForChild("NoButton", 60)
		local btnDown = f2:WaitForChild("DownButton", 60)
		local btnRight = f2:FindFirstChild("RightButton")
		local btnLeft = f2:FindFirstChild("LeftButton")
		
		if btnYes then
			btnYes.MouseButton1Click:Connect(function()
				if lastRequesterId then
					f3.Visible = false
					CarryRemote:FireServer("Response", {requesterId = lastRequesterId, accept = true})
				end
			end)
		end

		if btnNo then
			btnNo.MouseButton1Click:Connect(function()
				if lastRequesterId then
					f3.Visible = false
					CarryRemote:FireServer("Response", {requesterId = lastRequesterId, accept = false})
				end
			end)
		end

		if btnDown then
			btnDown.MouseButton1Click:Connect(function() 
				if isCarried then
					CarryRemote:FireServer("Stop", {})
				else
					local item = carriedList[carriedIndex]
					if item and item.id then 
						CarryRemote:FireServer("Stop", {targetId = item.id})
					end
				end
			end)
		end

		if btnRight and btnLeft then
			btnRight.MouseButton1Click:Connect(function() 
				if #carriedList == 0 then return end 
				carriedIndex += 1
				if carriedIndex > #carriedList then carriedIndex = 1 end 
				refreshCarrierUI() 
			end)

			btnLeft.MouseButton1Click:Connect(function() 
				if #carriedList == 0 then return end 
				carriedIndex -= 1
				if carriedIndex < 1 then carriedIndex = #carriedList end 
				refreshCarrierUI() 
			end)
		end
	end)
end

