local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Setup Suara (Ganti ID dengan ID Audio Roblox yang kamu inginkan)
if playerGui:GetAttribute("SoundEffectsEnabled") == nil then
	playerGui:SetAttribute("SoundEffectsEnabled", true)
end

local hoverSound = Instance.new("Sound")
hoverSound.SoundId = "rbxassetid://117649901456711" 
hoverSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://103282937573040"
clickSound.Parent = SoundService

-- Fungsi untuk memberikan efek suara pada sebuah tombol
local function applySound(element)
	if element:IsA("TextButton") or element:IsA("ImageButton") then
		-- Abaikan GUI bawaan Roblox seperti TouchGui (tombol jump, joystick, dll)
		local screenGui = element:FindFirstAncestorWhichIsA("ScreenGui")
		if screenGui and screenGui.Name == "TouchGui" then
			return
		end
		
		element.MouseEnter:Connect(function()
			if playerGui:GetAttribute("SoundEffectsEnabled") then
				hoverSound:Play()
			end
		end)
		
		element.MouseButton1Click:Connect(function()
			if playerGui:GetAttribute("SoundEffectsEnabled") then
				clickSound:Play()
			end
		end)
	end
end

-- 1. Scan semua tombol yang sudah ada saat player baru masuk
for _, descendant in ipairs(playerGui:GetDescendants()) do
	applySound(descendant)
end

-- 2. Pasang pendeteksi otomatis jika nanti ada UI / Menu baru yang di-load
playerGui.DescendantAdded:Connect(applySound)
