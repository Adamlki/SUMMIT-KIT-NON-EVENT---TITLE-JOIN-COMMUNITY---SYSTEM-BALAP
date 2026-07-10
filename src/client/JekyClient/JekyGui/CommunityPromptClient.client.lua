local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")

local player = Players.LocalPlayer

-- Tunggu 60 detik sebelum mengeksekusi
task.delay(60, function()
    local JekyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyConfig"))
    local GROUP_ID = JekyConfig.CommunityGroupId
    
    if not GROUP_ID or GROUP_ID == 0 then
        warn("CommunityGroupId belum di-set di JekyConfig!")
        return
    end

    local success, isInGroup = pcall(function()
        return player:IsInGroup(GROUP_ID)
    end)
    if success and isInGroup then return end

    -- Prompt untuk favorite game
    task.delay(3, function()
        local AvatarEditorService = game:GetService("AvatarEditorService")
        pcall(function()
            AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
        end)
    end)

    -- Prompt untuk join group
    local successJoin, result = pcall(function()
        return GroupService:PromptJoinAsync(GROUP_ID)
    end)

    if successJoin then
        if result == Enum.GroupMembershipStatus.Joined then
        elseif result == Enum.GroupMembershipStatus.AlreadyMember then
        else
        end
    else
        warn("Prompt failed:", result)
    end
end)
