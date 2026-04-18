-- main.lua
print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
print("========================================")
print("=== SYNC CUBE SPAWNER ===")
print("========================================\n")

local config = require("config")
local udp = require("udp")
local player = require("player")
local spawner = require("spawner")
local serializer = require("serializer")

local spawnedCube = nil
local isSyncActive = false
local isHost = false
local isClient = false
local syncRunning = false

-- Данные другого игрока
local otherPlayerPos = {X = 0, Y = 0, Z = 0}
local otherPlayerRot = {Pitch = 0, Yaw = 0, Roll = 0}

-- Инициализация
local function Init()
    print("[INIT] Finding ModActor...\n")
    if spawner.findModActor() then
        print("[INIT] Loading cube class...\n")
        spawner.loadCube(config.cubePath)
    end
end

-- Отправка данных (клиент)
local function SendData()
    local pos = player.getPos()
    local rot = player.getRot()
    if not pos or not rot then 
        return 
    end
    local data = serializer.serialize(pos, rot)
    udp.send(data)
end

-- Получение данных (хост)
local function ReceiveData()
    local data, ip, port = udp.receive()
    if data then
        print("[RECV] From " .. ip .. ":" .. port .. "\n")
        
        if data == "HELLO_FROM_CLIENT" then
            print("[RECV] Handshake\n")
            udp.setPeer(ip, port)
            return
        end
        
        local parsed = serializer.deserialize(data)
        if parsed then
            otherPlayerPos = parsed.pos
            otherPlayerRot = parsed.rot
            print("[RECV] Got position: X=" .. otherPlayerPos.X .. " Y=" .. otherPlayerPos.Y .. " Z=" .. otherPlayerPos.Z .. "\n")
            print("[RECV] spawnedCube=" .. tostring(spawnedCube) .. " isSyncActive=" .. tostring(isSyncActive) .. " ready=" .. tostring(spawner.isReady()) .. "\n")
            
            if not spawnedCube and isSyncActive and spawner.isReady() then
                print("[RECV] Attempting to spawn...\n")
                spawnedCube = spawner.spawn(otherPlayerPos, otherPlayerRot, {X = 1, Y = 1, Z = 1})
                if spawnedCube then
                    print("[RECV] Spawn success!\n")
                else
                    print("[RECV] Spawn failed!\n")
                end
            end
        end
    end
end

-- Отправка от хоста
local function SendHostData()
    local pos = player.getPos()
    local rot = player.getRot()
    if not pos or not rot then 
        return 
    end
    
    local data = serializer.serialize(pos, rot)
    udp.send(data)
end

-- Получение клиентом
local function ReceiveClientData()
    local data = udp.receiveClient()
    if data and data ~= "HELLO_FROM_CLIENT" then
        local parsed = serializer.deserialize(data)
        if parsed then
            otherPlayerPos = parsed.pos
            otherPlayerRot = parsed.rot
            print("[CLIENT] Got position: X=" .. otherPlayerPos.X .. " Y=" .. otherPlayerPos.Y .. " Z=" .. otherPlayerPos.Z .. "\n")
            
            if not spawnedCube and isSyncActive and spawner.isReady() then
                print("[CLIENT] Attempting to spawn...\n")
                spawnedCube = spawner.spawn(otherPlayerPos, otherPlayerRot, {X = 1, Y = 1, Z = 1})
                if spawnedCube then
                    print("[CLIENT] Spawn success!\n")
                else
                    print("[CLIENT] Spawn failed!\n")
                end
            end
        end
    end
end

-- Обновление позиции куба
local function UpdateCubePosition()
    if spawnedCube and spawnedCube:IsValid() then
        print("[MOVE] Moving cube to: X=" .. otherPlayerPos.X .. " Y=" .. otherPlayerPos.Y .. " Z=" .. otherPlayerPos.Z .. "\n")
        local success = spawner.move(spawnedCube, otherPlayerPos, otherPlayerRot)
        if success then
            print("[MOVE] Move success\n")
        else
            print("[MOVE] Move failed\n")
        end
    else
        print("[MOVE] No valid cube to move\n")
    end
end

-- Цикл синхронизации
local function SyncLoop()
    if not isSyncActive then return end
    
    if isHost then
        ReceiveData()
        if udp.getPeer then
            SendHostData()
        end
    elseif isClient then
        SendData()
        ReceiveClientData()
    end
    
    UpdateCubePosition()
end

-- Запуск цикла
local function StartSyncLoop()
    if syncRunning then return end
    syncRunning = true
    print("[LOOP] Starting sync loop\n")
    
    ExecuteAsync(function()
        while true do
            if isSyncActive then
                SyncLoop()
            end
            ExecuteWithDelay(config.syncInterval, function() end)
        end
    end)
end

-- Запуск хоста
local function StartHost()
    print("[HOST] Starting...\n")
    if isSyncActive then StopSync() end
    
    if not spawner.isReady() then Init() end
    
    if udp.initHost(config.localPort) then
        isHost = true
        isClient = false
        isSyncActive = true
        StartSyncLoop()
        print("[HOST] === ACTIVE ===\n")
    end
end

-- Запуск клиента
local function StartClient()
    print("[CLIENT] Starting...\n")
    if isSyncActive then StopSync() end
    
    if not spawner.isReady() then Init() end
    
    if udp.initClient(config.targetHost, config.targetPort) then
        isClient = true
        isHost = false
        isSyncActive = true
        StartSyncLoop()
        print("[CLIENT] === ACTIVE ===\n")
        ExecuteWithDelay(100, function()
            udp.send("HELLO_FROM_CLIENT")
            print("[CLIENT] Handshake sent\n")
        end)
    end
end

-- Остановка
local function StopSync()
    print("[STOP] Stopping...\n")
    isSyncActive = false
    
    if spawnedCube then
        spawnedCube = spawner.destroy(spawnedCube)
    end
    
    udp.close()
    isHost = false
    isClient = false
    syncRunning = false
end

-- Регистрация клавиш
RegisterKeyBind(70, function()
    if isSyncActive then
        print("[KEY] Sync active, ignoring\n")
        return
    end
    print("\n[KEY] F - HOST\n")
    StartHost()
end)

RegisterKeyBind(71, function()
    if isSyncActive then
        print("[KEY] Sync active, ignoring\n")
        return
    end
    print("\n[KEY] G - CLIENT\n")
    StartClient()
end)

RegisterKeyBind(72, function() -- H
    print("\n================================================================================\n")
    print("[KEY] H pressed - Spawning cube at player position\n")
    
    local pos = player.getPos()
    local rot = player.getRot()
    
    if not pos then
        print("[ERROR] Failed to get player position - pos is nil\n")
        return
    end
    if not rot then
        print("[ERROR] Failed to get player rotation - rot is nil\n")
        return
    end
    
    print("[DEBUG] Player position: X=" .. pos.X .. " Y=" .. pos.Y .. " Z=" .. pos.Z .. "\n")
    print("[DEBUG] Player rotation: Pitch=" .. rot.Pitch .. " Yaw=" .. rot.Yaw .. " Roll=" .. rot.Roll .. "\n")
    
    local spawnPos = {X = pos.X, Y = pos.Y, Z = pos.Z + 100}
    print("[DEBUG] Spawn position: X=" .. spawnPos.X .. " Y=" .. spawnPos.Y .. " Z=" .. spawnPos.Z .. "\n")
    
    if not spawner.isReady() then
        print("[ERROR] Spawner not ready! Press F first to initialize.\n")
        return
    end
    
    local cube = spawner.spawn(spawnPos, rot, {X = 1, Y = 1, Z = 1})
    
    if cube then
        print("[SUCCESS] Cube spawned successfully!\n")
        local cubePos = cube:K2_GetActorLocation()
        if cubePos then
            print("[DEBUG] Cube position: X=" .. cubePos.X .. " Y=" .. cubePos.Y .. " Z=" .. cubePos.Z .. "\n")
        end
    else
        print("[ERROR] Cube spawn failed!\n")
    end
end)

print("========================================")
print("F - Start as HOST")
print("G - Start as CLIENT")
print("H - Spawn test cube")
print("========================================\n")