-- ServerScriptService/AvatarChangerServer.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-- ============================================
-- CREATE REMOTEEVENTS
-- ============================================
local ChangeAvatarEvent = Instance.new("RemoteEvent")
ChangeAvatarEvent.Name = "ChangeAvatarEvent"
ChangeAvatarEvent.Parent = ReplicatedStorage
 
local ResetAvatarEvent = Instance.new("RemoteEvent")
ResetAvatarEvent.Name = "ResetAvatarEvent"
ResetAvatarEvent.Parent = ReplicatedStorage

local ApplyAnimationEvent = Instance.new("RemoteEvent")
ApplyAnimationEvent.Name = "ApplyAnimationEvent"
ApplyAnimationEvent.Parent = ReplicatedStorage

local AnimationNotificationEvent = Instance.new("RemoteEvent")
AnimationNotificationEvent.Name = "AnimationNotificationEvent"
AnimationNotificationEvent.Parent = ReplicatedStorage

local RestoreTitleEvent = ReplicatedStorage:FindFirstChild("RestoreTitleEvent") or Instance.new("BindableEvent")
RestoreTitleEvent.Name = "RestoreTitleEvent"
RestoreTitleEvent.Parent = ReplicatedStorage
 
-- ============================================
-- PLAYER DATA STORAGE
-- ============================================
local playerData = {}
local avatarCooldowns = {}
local COOLDOWN_TIME = 3
 
-- ============================================
-- TOOL HANDLER
-- Hanya unequip tool dari karakter ke Backpack sebelum ApplyDescription,
-- lalu equip kembali setelahnya. TIDAK clone/destroy agar script tidak restart.
-- ============================================
local function unequipTools(player)
    local equippedTool = nil
    
    if player.Character then
        for _, item in ipairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then
                equippedTool = item
                local backpack = player:FindFirstChild("Backpack")
                if backpack then
                    item.Parent = backpack -- pindah ke backpack, tidak dihapus
                end
                break -- karakter hanya bisa equip 1 tool sekaligus
            end
        end
    end
    
    return equippedTool -- kembalikan referensi tool aslinya (bukan clone)
end
 
local function reequipTool(player, tool)
    if not tool then return end
    
    task.wait(1.2)
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Pastikan tool masih ada di Backpack (belum dihapus sistem lain)
    local backpack = player:FindFirstChild("Backpack")
    if backpack and tool.Parent == backpack then
        humanoid:EquipTool(tool)
    end
end
 
-- ============================================
-- SAVE ORIGINAL AVATAR
-- ============================================
local function saveOriginalAvatar(player)
    if not playerData[player.UserId] then
        playerData[player.UserId] = {
            currentAvatarId = nil,
            customAnimations = {}
        }
    end
end
 
-- ============================================
-- CHANGE AVATAR
-- ============================================
local function changeAvatar(player, targetUserId)
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    saveOriginalAvatar(player)
    playerData[player.UserId].currentAvatarId = targetUserId
    
    -- Unequip tool yang sedang dipakai (tanpa destroy/clone)
    local equippedTool = unequipTools(player)
    
    -- Apply deskripsi avatar baru
    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(targetUserId)
    end)
    
    if success and description then
        -- apply custom animations
        if playerData[player.UserId] and playerData[player.UserId].customAnimations then
            for prop, val in pairs(playerData[player.UserId].customAnimations) do
                description[prop] = val
            end
        end
        
        humanoid:ApplyDescription(description)
        RestoreTitleEvent:Fire(player)
        -- forceAttachTitle di TitleGiver otomatis restore billboard
        -- Equip kembali tool yang tadi di-unequip
        task.spawn(function()
            reequipTool(player, equippedTool)
        end)
    end
end
 
-- ============================================
-- RESET AVATAR
-- ============================================
local function resetAvatar(player)
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if not playerData[player.UserId] then
        saveOriginalAvatar(player)
    end
    
    playerData[player.UserId].currentAvatarId = nil
    
    -- Unequip tool yang sedang dipakai (tanpa destroy/clone)
    local equippedTool = unequipTools(player)
    
    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(player.UserId)
    end)
    
    if success and description then
        if playerData[player.UserId] and playerData[player.UserId].customAnimations then
            for prop, val in pairs(playerData[player.UserId].customAnimations) do
                description[prop] = val
            end
        end
        
        humanoid:ApplyDescription(description)
        RestoreTitleEvent:Fire(player)
        -- forceAttachTitle di TitleGiver otomatis restore billboard
        task.spawn(function()
            reequipTool(player, equippedTool)
        end)
    end
end
 
-- ============================================
-- CHANGE ANIMATION (HUMANOID DESCRIPTION)
-- ============================================
local function changeAnimation(player, data)
    if not player.Character then return end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local currentDesc = humanoid:GetAppliedDescription()
    if not currentDesc then return end

    local changed = false

    if not playerData[player.UserId] then saveOriginalAvatar(player) end

    if (data.type == "Bundle" or data.type == "SingleBundle") and data.id then
        local bundleId = tonumber(data.id)
        local AssetService = game:GetService("AssetService")
        local success, bundleDetails = pcall(function()
            return AssetService:GetBundleDetailsAsync(bundleId)
        end)
        
        if success and bundleDetails and bundleDetails.Items then
            local outfitId
            for _, item in ipairs(bundleDetails.Items) do
                if item.Type == "UserOutfit" then
                    outfitId = item.Id
                    break
                end
            end
            
            if outfitId then
                local successOutfit, outfitDesc = pcall(function()
                    return Players:GetHumanoidDescriptionFromOutfitId(outfitId)
                end)
                if successOutfit and outfitDesc then
                    if data.type == "Bundle" then
                        currentDesc.ClimbAnimation = outfitDesc.ClimbAnimation
                        currentDesc.FallAnimation = outfitDesc.FallAnimation
                        currentDesc.IdleAnimation = outfitDesc.IdleAnimation
                        currentDesc.JumpAnimation = outfitDesc.JumpAnimation
                        currentDesc.RunAnimation = outfitDesc.RunAnimation
                        currentDesc.SwimAnimation = outfitDesc.SwimAnimation
                        currentDesc.WalkAnimation = outfitDesc.WalkAnimation
                        
                        playerData[player.UserId].customAnimations = {
                            ClimbAnimation = outfitDesc.ClimbAnimation,
                            FallAnimation = outfitDesc.FallAnimation,
                            IdleAnimation = outfitDesc.IdleAnimation,
                            JumpAnimation = outfitDesc.JumpAnimation,
                            RunAnimation = outfitDesc.RunAnimation,
                            SwimAnimation = outfitDesc.SwimAnimation,
                            WalkAnimation = outfitDesc.WalkAnimation
                        }
                        changed = true
                    elseif data.type == "SingleBundle" and data.category then
                        local propName = data.category .. "Animation"
                        currentDesc[propName] = outfitDesc[propName]
                        
                        if not playerData[player.UserId].customAnimations then
                            playerData[player.UserId].customAnimations = {}
                        end
                        playerData[player.UserId].customAnimations[propName] = outfitDesc[propName]
                        changed = true
                    end
                end
            end
        end
    elseif data.type == "Single" and data.category and data.id then
        local idStr = string.match(data.id, "%d+")
        if idStr then
            local animId = tonumber(idStr)
            local propName = data.category .. "Animation"
            currentDesc[propName] = animId
            
            if not playerData[player.UserId].customAnimations then
                playerData[player.UserId].customAnimations = {}
            end
            playerData[player.UserId].customAnimations[propName] = animId
            changed = true
        end
    elseif data.type == "UnequipSingle" and data.category then
        local propName = data.category .. "Animation"
        
        local baseId = (playerData[player.UserId] and playerData[player.UserId].currentAvatarId) or player.UserId
        local success, baseDesc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(baseId)
        end)
        
        if success and baseDesc then
            currentDesc[propName] = baseDesc[propName]
            
            if playerData[player.UserId].customAnimations then
                playerData[player.UserId].customAnimations[propName] = nil
            end
            changed = true
        end
    elseif data.type == "Reset" then
        playerData[player.UserId].customAnimations = {}
        
        local baseId = (playerData[player.UserId] and playerData[player.UserId].currentAvatarId) or player.UserId
        local success, baseDesc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(baseId)
        end)
        
        if success and baseDesc then
            currentDesc.ClimbAnimation = baseDesc.ClimbAnimation
            currentDesc.FallAnimation = baseDesc.FallAnimation
            currentDesc.IdleAnimation = baseDesc.IdleAnimation
            currentDesc.JumpAnimation = baseDesc.JumpAnimation
            currentDesc.RunAnimation = baseDesc.RunAnimation
            currentDesc.SwimAnimation = baseDesc.SwimAnimation
            currentDesc.WalkAnimation = baseDesc.WalkAnimation
            changed = true
        end
    end

    if changed then
        local equippedTool = unequipTools(player)
        
        local success, err = pcall(function()
            humanoid:ApplyDescription(currentDesc)
        end)
        
        if success then
            RestoreTitleEvent:Fire(player)
            task.spawn(function()
                reequipTool(player, equippedTool)
            end)
            AnimationNotificationEvent:FireClient(player, true, "Berhasil " .. (data.type == "Reset" and "mereset" or "memasang") .. " animasi!", data)
        else
            warn("Failed to apply animation description: " .. tostring(err))
            task.spawn(function()
                reequipTool(player, equippedTool)
            end)
            AnimationNotificationEvent:FireClient(player, false, "Gagal memasang animasi.", data)
        end
    else
        AnimationNotificationEvent:FireClient(player, false, "Gagal mendapatkan data animasi.", data)
    end
end
 
-- ============================================
-- PLAYER JOINED
-- ============================================
Players.PlayerAdded:Connect(function(player)
    saveOriginalAvatar(player)
    
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            task.wait(1)
            
            local currentAvatarId = playerData[player.UserId] and playerData[player.UserId].currentAvatarId
            local hasCustomAnims = playerData[player.UserId] and playerData[player.UserId].customAnimations and next(playerData[player.UserId].customAnimations)
            
            if currentAvatarId or hasCustomAnims then
                local baseId = currentAvatarId or player.UserId
                local success, desc = pcall(function()
                    return Players:GetHumanoidDescriptionFromUserId(baseId)
                end)
                
                if success and desc then
                    if hasCustomAnims then
                        for prop, val in pairs(playerData[player.UserId].customAnimations) do
                            desc[prop] = val
                        end
                    end
                    
                    local equippedTool = unequipTools(player)
                    pcall(function()
                        humanoid:ApplyDescription(desc)
                    end)
                    RestoreTitleEvent:Fire(player)
                    task.spawn(function()
                        reequipTool(player, equippedTool)
                    end)
                end
            end
        end
    end)
end)
 
-- ============================================
-- EVENT HANDLERS
-- ============================================
ChangeAvatarEvent.OnServerEvent:Connect(function(player, targetUserId)
    local now = os.clock()
    if avatarCooldowns[player.UserId] and (now - avatarCooldowns[player.UserId]) < COOLDOWN_TIME then
        return -- Abaikan jika belum lewat 3 detik
    end
    avatarCooldowns[player.UserId] = now

    if typeof(targetUserId) == "number" then
        changeAvatar(player, targetUserId)
    end
end)
 
ResetAvatarEvent.OnServerEvent:Connect(function(player)
    local now = os.clock()
    if avatarCooldowns[player.UserId] and (now - avatarCooldowns[player.UserId]) < COOLDOWN_TIME then
        return
    end
    avatarCooldowns[player.UserId] = now

    resetAvatar(player)
end)

ApplyAnimationEvent.OnServerEvent:Connect(function(player, data)
    local now = os.clock()
    if avatarCooldowns[player.UserId] and (now - avatarCooldowns[player.UserId]) < COOLDOWN_TIME then
        return
    end
    avatarCooldowns[player.UserId] = now

    if typeof(data) == "table" then
        changeAnimation(player, data)
    end
end)
 
-- ============================================
-- CLEANUP
-- ============================================
Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
    avatarCooldowns[player.UserId] = nil
end)

