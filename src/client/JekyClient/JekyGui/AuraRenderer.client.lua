-- StarterPlayerScripts > JekyClient > AuraRenderer.client.lua
-- Script ini bertugas merender partikel Aura secara lokal tanpa membebani server
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuraPack = ReplicatedStorage:WaitForChild("AuraPack")

local function clearAura(character)
    for _, child in ipairs(character:GetDescendants()) do
        if child:GetAttribute("IsClientAura") then
            child:Destroy()
        end
    end
end

local function applyAura(character, auraName)
    clearAura(character)
    if not auraName or auraName == "" then return end
    
    local auraModel = AuraPack:FindFirstChild(auraName)
    if not auraModel then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local bodyParts = {
        "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperLeg", "RightLowerLeg", "RightFoot",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"
    }
    
    local processedParts = {}
    
    -- Daripada mengkloning Part utuh, kita HANYA mengkloning isi visualnya (Particle, Light, dsb)
    for _, partName in ipairs(bodyParts) do
        local auraPart = auraModel:FindFirstChild(partName)
        local characterPart = character:FindFirstChild(partName)
        
        if auraPart and characterPart and auraPart:IsA("BasePart") then
            -- Ambil semua efek di dalam part tersebut dan pindahkan ke bagian tubuh pemain
            for _, item in ipairs(auraPart:GetChildren()) do
                if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") or item:IsA("Light") or item:IsA("Attachment") then
                    local cloneFx = item:Clone()
                    cloneFx:SetAttribute("IsClientAura", true)
                    
                    if cloneFx:IsA("ParticleEmitter") and cloneFx.Rate > 30 then
                        cloneFx.Rate = 30
                    end
                    
                    cloneFx.Parent = characterPart
                end
            end
            
            processedParts[partName] = true
        end
    end
    
    -- Untuk objek Aura seperti "MeshPart" (contoh: sayap, halo) yang bukan menempel di nama anggota tubuh tertentu
    for _, child in ipairs(auraModel:GetChildren()) do
        if child:IsA("BasePart") and not processedParts[child.Name] then
            -- Jika itu hanya wadah efek, clone efeknya saja
            local hasMesh = child:FindFirstChildOfClass("SpecialMesh") or child:IsA("MeshPart")
            
            if hasMesh or child.Transparency < 1 then
                -- Jika butuh part fisiknya untuk dirender (karena ada mesh/gambar)
                local clone = child:Clone()
                clone:SetAttribute("IsClientAura", true)
                
                -- [SANGAT PENTING] Hapus semua sisa Weld/Motor6D dari Studio sebelum di-weld ke pemain
                for _, obj in ipairs(clone:GetDescendants()) do
                    if obj:IsA("JointInstance") then
                        obj:Destroy()
                    end
                end
                
                clone.CanCollide = false
                clone.CanTouch = false
                clone.Massless = true
                clone.Anchored = false
                clone.CFrame = humanoidRootPart.CFrame
                clone.Parent = humanoidRootPart
                
                for _, fx in ipairs(clone:GetDescendants()) do
                    if fx:IsA("ParticleEmitter") and fx.Rate > 30 then
                        fx.Rate = 30
                    end
                end
                
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = clone
                weld.Part1 = humanoidRootPart
                weld.Parent = clone
                weld:SetAttribute("IsClientAura", true)
            else
                -- Jika hanya part kosong transparan, clone efeknya saja ke HumanoidRootPart
                for _, item in ipairs(child:GetChildren()) do
                    if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") or item:IsA("Light") or item:IsA("Attachment") then
                        local cloneFx = item:Clone()
                        cloneFx:SetAttribute("IsClientAura", true)
                        
                        if cloneFx:IsA("ParticleEmitter") and cloneFx.Rate > 30 then
                            cloneFx.Rate = 30
                        end
                        
                        cloneFx.Parent = humanoidRootPart
                    end
                end
            end
        end
    end
end

local function setupCharacter(character)
    -- Pantau perubahan Attribute dari server
    character:GetAttributeChangedSignal("EquippedAura"):Connect(function()
        applyAura(character, character:GetAttribute("EquippedAura"))
    end)
    
    -- Render awal saat spawn
    task.wait(0.5)
    applyAura(character, character:GetAttribute("EquippedAura"))
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then
        setupCharacter(player.Character)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
