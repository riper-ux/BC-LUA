-- spawn_and_move_cube.lua
-- Упрощенная версия с использованием готового Blueprint куба

local spawnedCube = nil
local isCubeSpawned = false
local spawnDistance = 500.0
local cubeClass = nil
local assetsLoaded = false

-- Функция для получения позиции игрока
local function GetPlayerPos()
    local p = FindFirstOf("mainPlayer_C")
    if not p then return nil end
    return p:K2_GetActorLocation()
end

-- Функция для получения поворота игрока
local function GetPlayerRot()
    local p = FindFirstOf("mainPlayer_C")
    if not p then return nil end
    return p:K2_GetActorRotation()
end

-- Функция для получения forward вектора из Rotator
function GetForwardVector(rot)
    local pitch = rot.Pitch * math.pi / 180
    local yaw = rot.Yaw * math.pi / 180
    
    local x = math.cos(yaw) * math.cos(pitch)
    local y = math.sin(yaw) * math.cos(pitch)
    local z = math.sin(pitch)
    
    return {X = x, Y = y, Z = z}
end

-- Функция для получения позиции перед игроком
function GetPositionInFrontOfPlayer(distance)
    local playerPos = GetPlayerPos()
    local playerRot = GetPlayerRot()
    
    if not playerPos or not playerRot then
        return nil
    end
    
    local forwardVector = GetForwardVector(playerRot)
    
    local targetLocation = {
        X = playerPos.X + (forwardVector.X * distance),
        Y = playerPos.Y + (forwardVector.Y * distance),
        Z = playerPos.Z + (forwardVector.Z * distance)
    }
    
    return targetLocation
end

-- Загрузка класса куба
function LoadCubeClass(callback)
    ExecuteInGameThread(function()
        print("Loading cube class...")
        cubeClass = LoadAsset("/Game/Mods/SynsMod/CUBE.CUBE_C")
        
        if cubeClass then
            assetsLoaded = true
            print("Cube class loaded successfully!")
        else
            print("Failed to load cube class at: /Game/Mods/SynsMod/CUBE.CUBE_C")
        end
        
        if callback then
            callback()
        end
    end)
end

-- Функция для спавна куба
function SpawnCubeAtLocation(location)
    if not assetsLoaded or not cubeClass then
        print("Cube class not loaded yet")
        return nil
    end
    
    local world = FindFirstOf("World")
    if not world then
        print("No World found")
        return nil
    end
    
    local spawnParams = {
        SpawnCollisionHandlingOverride = 1 -- AlwaysSpawn
    }
    
    -- Спавним куб из вашего Blueprint
    local spawned = world:SpawnActor(cubeClass, location, {Pitch=0, Yaw=0, Roll=0}, spawnParams)
    
    if spawned and spawned:IsValid() then
        print("Cube spawned successfully!")
        return spawned
    else
        print("Failed to spawn cube")
        return nil
    end
end

-- Функция для обновления позиции куба
function UpdateCubePosition()
    if not spawnedCube or not spawnedCube:IsValid() then
        return
    end
    
    local newLocation = GetPositionInFrontOfPlayer(spawnDistance)
    if newLocation then
        spawnedCube:K2_SetActorLocation(newLocation, false, nil, false)
    end
end

-- Переключение спавна куба
function ToggleCube()
    local currentPlayer = FindFirstOf("mainPlayer_C")
    if not currentPlayer or not currentPlayer:IsValid() then
        print("Player not found! Make sure you're in game.")
        return
    end
    
    if not isCubeSpawned then
        if not assetsLoaded then
            print("Loading cube class first time... Please wait and press F again")
            LoadCubeClass(function()
                print("Cube class ready! Press F again to spawn")
            end)
            return
        end
        
        print("Spawning cube...")
        local spawnLocation = GetPositionInFrontOfPlayer(spawnDistance)
        if spawnLocation then
            spawnedCube = SpawnCubeAtLocation(spawnLocation)
            if spawnedCube and spawnedCube:IsValid() then
                isCubeSpawned = true
                print("=== Cube Activated - Following player ===")
            end
        else
            print("Failed to get spawn location")
        end
    else
        print("Destroying cube...")
        if spawnedCube and spawnedCube:IsValid() then
            spawnedCube:K2_DestroyActor()
        end
        spawnedCube = nil
        isCubeSpawned = false
        print("=== Cube Deactivated ===")
    end
end

-- Асинхронный цикл обновления
local updateRunning = false

function StartUpdateLoop()
    if updateRunning then
        return
    end
    updateRunning = true
    
    ExecuteAsync(function()
        while true do
            if isCubeSpawned and spawnedCube and spawnedCube:IsValid() then
                UpdateCubePosition()
            end
            ExecuteWithDelay(16, function() end)
        end
    end)
end

-- Регистрируем консольную команду
RegisterConsoleCommandHandler("spawncube", function(cmd, parts, ar)
    ToggleCube()
    return true
end)

-- Регистрируем клавишу F
RegisterKeyBind(70, function()
    ToggleCube()
end)

-- Запускаем цикл обновления
StartUpdateLoop()

print("========================================")
print("Cube Spawner Loaded for VotV!")
print("========================================")
print("Using: /Game/Mods/SynsMod/CUBE.CUBE_C")
print("Press F to spawn cube")
print("(First press loads the cube class)")
print("Cube follows player movement")
print("Press F again to destroy")
print("========================================")