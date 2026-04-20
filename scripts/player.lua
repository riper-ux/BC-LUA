-- player.lua
local spawner = require("spawner")
local udp = require("udp")
local serializer = require("serializer")
local player = {}
local cachedPlayer = nil
local cachedPlayerAddress = nil
local spawned = nil

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

function player.handle(data)
    local parsed = serializer.deserialize
    if not parsed then
        return nil
    end
    if not spawned then
        print("[PLAYER] Attempting to spawn...\n")
        spawned = spawner.spawn(parsed.pos, parsed.rot)
        if spawned then
            print("[PLAYER] Spawn success!\n")
        else
            print("[PLAYER] Spawn failed!\n")
        end
    else
        local success = spawner.move(spawned, pos, rot, scl)
        if not success then
            print("[PLAYER] Move failed!\n")
        end
    end
end

function player.send()
    local pos = player.getPos()
    local rot = player.getRot()
    if not pos or not rot then return end
    local data = serializer.serialize(pos, rot)
    udp.add(data)
end

return player