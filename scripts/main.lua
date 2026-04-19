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
local door = require("door")
local handler = require("handler")

local spawnedCube = nil
local isSyncActive = false
local isHost = false
local isClient = false
local syncRunning = false
local ticker = 0
local Tticker = 0
local clock = os.clock()
local Tclock = os.clock()

-- Данные другого игрока
local otherPlayerPos = {X = 0, Y = 0, Z = 0}
local otherPlayerRot = {Pitch = 0, Yaw = 0, Roll = 0}
local SendPlayerPos = {X = 0, Y = 0, Z = 0}
local SendPlayerRot = {Pitch = 0, Yaw = 0, Roll = 0}
local ActivePlayerPos = {X = 0, Y = 0, Z = 0}
local ActivePlayerRot = {Pitch = 0, Yaw = 0, Roll = 0}

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
    if pos.X ~= SendPlayerPos.X or pos.Y ~= SendPlayerPos.Y or pos.Z ~= SendPlayerPos.Z or rot.Pitch ~= SendPlayerRot.Pitch or rot.Yaw ~= SendPlayerRot.Yaw or rot.Roll ~= SendPlayerRot.Roll then
        local data = serializer.serialize(pos, rot)
        udp.add(data)
        SendPlayerPos = pos
        SendPlayerRot = rot
    end
end

-- Цикл синхронизации
local function SyncLoop()
    if not isSyncActive then return end
    
    if os.clock() - clock >= 1 then
        clock = os.clock()
        print("[LOOP] TICKER: " .. ticker .. "\n")
        print("[LOOP] TPS: " .. Tticker .. "\n")
        ticker = 0
        Tticker = 0
    end
    if os.clock() - Tclock >= (1/config.TPS) then
        Tclock = os.clock()
        if isHost then
            handler.handle()
        elseif isClient then
            SendData()
        end
        Tticker = Tticker + 1
    end
    ticker = ticker + 1
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
            ExecuteWithDelay(1, function() end)
        end
    end)
end

-- Запуск хоста
local function StartHost()
    print("[HOST] Starting...\n")
    if isSyncActive then StopSync() end
    
    if not spawner.isReady() then Init() end

    player.cache()

    door.init()
    
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

    player.cache()
    
    if udp.initClient(config.targetHost, config.targetPort) then
        isClient = true
        isHost = false
        isSyncActive = true
        StartSyncLoop()
        print("[CLIENT] === ACTIVE ===\n")
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