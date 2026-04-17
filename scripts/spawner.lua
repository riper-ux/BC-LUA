-- spawner.lua
local spawner = {}
local modActor = nil
local cubeClass = nil
local cubePath = nil

-- Поиск ModActor в мире
function spawner.findModActor()
    print("[SPAWNER] Finding ModActor...")
    
    local actors = FindAllOf("ModActor_C")
    if not actors then
        print("[SPAWNER] FindAllOf returned nil")
        return false
    end
    
    for _, actor in pairs(actors) do
        if actor then
            local ok, fullName = pcall(function() return actor:GetFullName() end)
            if ok and fullName and string.find(fullName, "Class ") then
                goto continue
            end
            
            print("[SPAWNER] Found ModActor")
            modActor = actor
            return true
        end
        ::continue::
    end
    
    print("[SPAWNER] No ModActor found")
    return false
end

-- Загрузка класса куба
function spawner.loadCube(path)
    cubePath = path
    print("[SPAWNER] Loading cube class from: " .. path)
    
    local class = FindObject(nil, nil, path, false)
    if not class then
        class = StaticFindObject(path)  
    end
    
    if class then
        cubeClass = class
        print("[SPAWNER] Cube class loaded")
        return true
    else
        print("[SPAWNER] Failed to load cube class")
        return false
    end
end

-- Проверка готовности (без IsValid для cubeClass)
function spawner.isReady()
    if not modActor then
        print("[SPAWNER] Not ready: modActor is nil")
        return false
    end
    
    if not cubeClass then
        print("[SPAWNER] Not ready: cubeClass is nil")
        return false
    end
    
    print("[SPAWNER] Ready!")
    return true
end

-- Спавн куба
function spawner.spawn(location, rotation, scale)
    print("[SPAWNER] ========== SPAWN START ==========")
    
    if not location then
        print("[SPAWNER] ERROR: location is nil")
        return nil
    end
    print("[SPAWNER] location X=" .. location.X .. " Y=" .. location.Y .. " Z=" .. location.Z)
    
    local rot = rotation or {Pitch = 0, Yaw = 0, Roll = 0}
    print("[SPAWNER] rotation Pitch=" .. tostring(rot.Pitch) .. " Yaw=" .. tostring(rot.Yaw) .. " Roll=" .. tostring(rot.Roll))
    
    local sc = scale or {X = 1, Y = 1, Z = 1}
    print("[SPAWNER] scale X=" .. sc.X .. " Y=" .. sc.Y .. " Z=" .. sc.Z)
    
    if not modActor then
        print("[SPAWNER] ERROR: modActor is nil")
        return nil
    end
    
    if not cubeClass then
        print("[SPAWNER] ERROR: cubeClass is nil")
        return nil
    end
    
    print("[SPAWNER] Calling SpawnActor with separate params...")
    
    pcall(function()
        modActor:SpawnActor(cubeClass, location, rot, sc, 1, nil, nil)
    end)
    
    local errorMsg = modActor["LastError"]
    if errorMsg then
        local errorText = errorMsg:ToString()
        print("[SPAWNER] BP LastError: " .. errorText)
        if errorText ~= "OK" then
            print("[SPAWNER] Spawn failed with error: " .. errorText)
            return nil
        end
    end
    
    local result = modActor["Return-SpawnActor"]
    
    if result then
        print("[SPAWNER] Spawn success!")
        return result
    else
        print("[SPAWNER] Spawn failed, Return-SpawnActor is nil")
        return nil
    end
end

-- Перемещение куба
function spawner.move(actor, location)
    if not actor then
        print("[MOVE] actor is nil")
        return false
    end
    
    if not location then
        print("[MOVE] location is nil")
        return false
    end
    
    print("[MOVE] Moving to X=" .. location.X .. " Y=" .. location.Y .. " Z=" .. location.Z)
    
    local ok, err = pcall(function()
        actor:K2_SetActorLocation(location, false, nil, false)
    end)
    
    if not ok then
        print("[MOVE] Error: " .. tostring(err))
        return false
    end
    
    print("[MOVE] Success")
    return true
end

-- Удаление куба
function spawner.destroy(actor)
    if not actor then
        return nil
    end
    
    pcall(function()
        actor:K2_DestroyActor()
    end)
    
    print("[SPAWNER] Destroyed")
    return nil
end

-- Получить ModActor
function spawner.getModActor()
    return modActor
end

return spawner