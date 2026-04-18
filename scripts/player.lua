-- player.lua
local player = {}
local cachedPlayer = nil
local cachedPlayerAddress = nil

function player.cache()
    cachedPlayer = FindFirstOf("mainPlayer_C")
    if cachedPlayer then
        cachedPlayerAddress = cachedPlayer:GetAddress()
        print("[PLAYER] Cached at address: " .. tostring(cachedPlayerAddress))
        return true
    end
    return false
end

function player.getPos()
    if not cachedPlayer then
        if not player.cache() then return nil end
    end
    
    -- Быстрая проверка валидности без поиска
    local ok, isValid = pcall(function() return cachedPlayer:IsValid() end)
    if not ok or not isValid then
        player.cache() -- перезагружаем
        if not cachedPlayer then return nil end
    end
    
    return cachedPlayer:K2_GetActorLocation()
end

function player.getRot()
    if not cachedPlayer then
        if not player.cache() then return nil end
    end
    
    local ok, isValid = pcall(function() return cachedPlayer:IsValid() end)
    if not ok or not isValid then
        player.cache()
        if not cachedPlayer then return nil end
    end
    
    return cachedPlayer:K2_GetActorRotation()
end

function player.isValid()
    local ok, valid = pcall(function() return cachedPlayer:IsValid() end)
    return ok and valid
end

return player