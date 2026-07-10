-- ServerStorage/JekyModules/JekyTitle

local JekyTitle = {}
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PS = require(
ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky")
)

-- ============================================================
-- LOAD CENTRAL CONFIG
-- ============================================================
local JekyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyConfig"))

-- Proxy configs to JekyConfig to maintain backward compatibility for other scripts
JekyTitle.RoleRules = JekyConfig.RoleRules
JekyTitle.RoleOrder = JekyConfig.RoleOrder
JekyTitle.RoleDisplay = JekyConfig.RoleDisplay
JekyTitle.RoleColors = JekyConfig.RoleColors
JekyTitle.RoleUsesGradient = JekyConfig.RoleUsesGradient

JekyTitle.SummitLevels = JekyConfig.SummitLevels
JekyTitle.SummitColors = JekyConfig.SummitColors
JekyTitle.MinusGradient = JekyConfig.MinusGradient
JekyTitle.Gradient1K    = JekyConfig.Gradient1K
JekyTitle.Gradient2K    = JekyConfig.Gradient2K
JekyTitle.Gradient3K    = JekyConfig.Gradient3K
JekyTitle.Gradient5K    = JekyConfig.Gradient5K

-- ============================================================
-- DYNAMIC ROLES
-- ============================================================
function JekyTitle:LoadDynamicRole(userId)
    return PS.Roles.Load(userId)
end

function JekyTitle:SaveDynamicRole(userId, roleData)
    PS.Roles.Save(userId, roleData)
end

-- FIX: Support offline player — pakai GetUserIdFromNameAsync jika player tidak online
function JekyTitle:AddDynamicRole(username, roleName)
    if not username or not roleName then return false, "Invalid parameters" end
    
    local valid = { Owner=true, Developer=true, HeadAdmin=true, Admin=true, Moderator=true, Streamer=true, Community=true }
    if not valid[roleName] then return false, "Invalid role: " .. roleName end
    
    local target = Players:FindFirstChild(username)
    if target then
        -- Player online
        PS.Roles.Save(target.UserId, { role=roleName, username=username, addedAt=os.time() })
        PS.Roles.ForceFlush(target.UserId)
        target:SetAttribute("DynamicRole",      roleName)
        target:SetAttribute("RoleUsesGradient", JekyTitle.RoleUsesGradient[roleName] == true)
        return true, "Role added: " .. username .. " → " .. roleName
    else
        -- FIX: Player offline — cari userId lalu simpan langsung ke DataStore
        local ok, uid = pcall(function()
            return Players:GetUserIdFromNameAsync(username)
        end)
        if ok and uid then
            PS.Roles.Save(uid, { role=roleName, username=username, addedAt=os.time() })
            PS.Roles.ForceFlush(uid)
            return true, "Role added (offline): " .. username .. " → " .. roleName
        end
        return false, "Player not found: " .. username
    end
end

-- FIX: Support offline player
function JekyTitle:RemoveDynamicRole(username)
    if not username then return false, "Invalid username" end
    
    local target = Players:FindFirstChild(username)
    if target then
        -- Player online
        PS.Roles.Save(target.UserId, nil)
        PS.Roles.ForceFlush(target.UserId)
        target:SetAttribute("DynamicRole",      nil)
        target:SetAttribute("RoleUsesGradient", nil)
        return true, "Role removed: " .. username
    else
        -- FIX: Player offline
        local ok, uid = pcall(function()
            return Players:GetUserIdFromNameAsync(username)
        end)
        if ok and uid then
            PS.Roles.Save(uid, nil)
            PS.Roles.ForceFlush(uid)
            return true, "Role removed (offline): " .. username
        end
        return false, "Player not found: " .. username
    end
end

-- ============================================================
-- GETTERS
-- ============================================================
local function contains(t, v)
    for _, x in ipairs(t or {}) do if x == v then return true end end
    return false
end

local function roleMatch(player, rule, roleName)
    if not rule then return false end
    if contains(rule.UserIds,   player.UserId) then return true end
    if contains(rule.Usernames, player.Name)   then return true end
    if roleName == "Community" and JekyConfig.CommunityGroupId and JekyConfig.CommunityGroupId > 0 then
        local success, inGroup = pcall(function() return player:IsInGroup(JekyConfig.CommunityGroupId) end)
        if success and inGroup then return true end
    end
    return false
end

function JekyTitle.GetRoleTitle(player)
    local dyn = player:GetAttribute("DynamicRole")
    if dyn and dyn ~= "" then return dyn end
    local cached = PS.Roles.Load(player.UserId)
    if cached and cached.role then return cached.role end
    for _, name in ipairs(JekyTitle.RoleOrder) do
        if roleMatch(player, JekyTitle.RoleRules[name], name) then
            return name
        end
    end
    if game:GetService("RunService"):IsStudio() then return "Owner" end
    return nil
end

function JekyTitle.GetRoleDisplayText(r)   return r and JekyTitle.RoleDisplay[r] or r or "" end
function JekyTitle.GetRoleColor(r)         return r and JekyTitle.RoleColors[r] or nil end
function JekyTitle.GetRoleUsesGradient(r)  return JekyTitle.RoleUsesGradient[r] == true end

function JekyTitle.GetSummitTitle(total)
    total = tonumber(total) or 0
    local best, bestMin = JekyTitle.SummitLevels[1].Title, -math.huge
    for _, lvl in ipairs(JekyTitle.SummitLevels) do
        if total >= lvl.Min and lvl.Min >= bestMin then
            best, bestMin = lvl.Title, lvl.Min
        end
    end
    return best
end

function JekyTitle.GetSummitColor(title)
    return JekyTitle.SummitColors[title] or Color3.fromRGB(200,200,200)
end

function JekyTitle.GetSpecialSummitGradient(total)
    total = tonumber(total) or 0
    if total < 0         then return JekyTitle.MinusGradient
    elseif total >= 5000 then return JekyTitle.Gradient5K
    elseif total >= 3000 then return JekyTitle.Gradient3K
    elseif total >= 2000 then return JekyTitle.Gradient2K
    elseif total >= 1000 then return JekyTitle.Gradient1K
    end
        return nil
    end
    
    function JekyTitle.ShouldUseSpecialSummitGradient(total)
        return JekyTitle.GetSpecialSummitGradient(total) ~= nil
    end
    
    function JekyTitle.BuildTitles(player, totalSummit)
        totalSummit = tonumber(totalSummit) or 0
        return JekyTitle.GetRoleTitle(player),
        JekyTitle.GetSummitTitle(totalSummit),
        string.format("SUMMIT: %d", totalSummit)
    end
    
    -- ============================================================
    -- INIT PLAYER
    -- ============================================================
    function JekyTitle:InitializePlayer(player)
        task.spawn(function()
            task.wait(1)
            local d = PS.Roles.Load(player.UserId)
            if d and d.role then
                player:SetAttribute("DynamicRole",      d.role)
                player:SetAttribute("RoleUsesGradient", JekyTitle.RoleUsesGradient[d.role] == true)
            end
        end)
    end
    
    Players.PlayerAdded:Connect(function(player)
        JekyTitle:InitializePlayer(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        PS.Roles.FlushOnLeave(player.UserId)
    end)
    
    -- ============================================================
    -- API
    -- ============================================================
    JekyTitle.API = {
    GetAllPlayers = function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            table.insert(list, {
            Name        = p.Name,
            DisplayName = p.DisplayName,
            UserId      = p.UserId,
            Role        = JekyTitle.GetRoleTitle(p) or "None"
            })
        end
        return list
    end,
    AddRole           = function(u, r) return JekyTitle:AddDynamicRole(u, r) end,
        RemoveRole        = function(u)    return JekyTitle:RemoveDynamicRole(u) end,
            GetAvailableRoles = function()     return { "Owner","Developer","HeadAdmin","Admin","Moderator","Streamer","Community" } end,
                }
                
                return JekyTitle

