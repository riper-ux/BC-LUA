-- player.lua
local player = {}

function player.getPos()
    local p = FindFirstOf("mainPlayer_C")
    if not p then 
        return nil 
    end
    
    local ok, pos = pcall(function() return p:K2_GetActorLocation() end)
    if not ok or not pos then
        return nil
    end
    return pos
end

function player.getRot()
    local p = FindFirstOf("mainPlayer_C")
    if not p then 
        return nil 
    end
    
    local ok, rot = pcall(function() return p:K2_GetActorRotation() end)
    if not ok or not rot then
        return nil
    end
    return rot
end

function player.isValid()
    local p = FindFirstOf("mainPlayer_C")
    if not p then return false end
    
    local ok, valid = pcall(function() return p:IsValid() end)
    return ok and valid
end

return player