-- main.lua
print("\n")
print("=== PROTOTYPE? ===\n")
print("\n")

local config = require("config")

local isSyncActive = false
local isHost = false
local Running = false
local ReadyAsync = true
local SyncTPS = 0
local AsyncTPS = 0
local clock = os.clock()
local tclock = os.clock()
local Sync = {}
local Async = {}
local module = {}
local toolkit = nil

for i = 1, #config.Modules do
    print("[MODULAR] Preparing... " .. config.Modules[i] .. " " .. i .. "/" .. #config.Modules .. "\n")
    module[config.Modules[i]] = require(config.Modules[i])
end

local function Tick()
    if ReadyAsync then
        ReadyAsync = false
        ExecuteAsync(function()
            for i = 1, #Async do
                module[Sync[i][1]][Sync[i][2]](module[Sync[i][1]])
            end
            AsyncTPS = AsyncTPS + 1
            ReadyAsync = true
        end)
    end
    for i = 1, #Sync do
        module[Sync[i][1]][Sync[i][2]](module[Sync[i][1]])
    end
    SyncTPS = SyncTPS + 1
end

-- Цикл синхронизации
local function Loop()
    if os.clock() - clock >= 1 then
        clock = os.clock()
        local Scolor = nil
        local Acolor = nil
        if SyncTPS > config.TPS * 0.9 then Scolor = module.cprint.colors.bright_blue elseif SyncTPS > config.TPS * 0.8 then Scolor = module.cprint.colors.bright_green elseif SyncTPS > config.TPS * 0.6 then Scolor = module.cprint.colors.yellow elseif SyncTPS > config.TPS * 0.5 then Scolor = module.cprint.colors.magenta else Scolor = module.cprint.colors.bright_red end
        module.cprint.print("[LOOP] Sync TPS: " .. SyncTPS .. "\n", Scolor)
        if AsyncTPS > config.TPS * 0.9 then Acolor = module.cprint.colors.bright_blue elseif AsyncTPS > config.TPS * 0.8 then Acolor = module.cprint.colors.bright_green elseif AsyncTPS > config.TPS * 0.6 then Acolor = module.cprint.colors.yellow elseif AsyncTPS > config.TPS * 0.5 then Acolor = module.cprint.colors.magenta else Acolor = module.cprint.colors.bright_red end
        module.cprint.print("[LOOP] Async TPS: " .. AsyncTPS .. "\n", Acolor)
        SyncTPS = 0
        AsyncTPS = 0
    end

    if os.clock() - tclock >= 1 / config.TPS then
        tclock = os.clock()
        Tick()
    end
end
print("[MAIN] Loop registered!\n")
RegisterCustomEvent("Tick", function()
    if Running then
        Loop()
    end
end)

-- Запуск цикла
local function StartLoop()
    if Running then return end
    if not toolkit then
        print("[MAIN] Loading toolkit...\n")
        toolkit = FindFirstOf("ModActor_C")
        if not toolkit then
            print("[MAIN] ERROR: Toolkit not found!\n")
            return
        end
        print("[MAIN] Toolkit loaded!\n")
    end
    Running = true
    print("[MAIN] Starting loop\n")
    for i = 1, #config.Modules do
        print("[MODULAR] Initialization... " .. config.Modules[i] .. " " .. i .. "/" .. #config.Modules .. "\n")
        local sync, async = module[config.Modules[i]].init()
        if sync then
            print("[MODULAR] Registration... (Sync) " .. config.Modules[i] .. "\n")
            table.insert(Sync, {config.Modules[i], sync})
        end
        if async then
            print("[MODULAR] Registration... (Async) " .. config.Modules[i] .. "\n")
            table.insert(Async, {config.Modules[i], async})
        end
    end
    clock = os.clock()
    print("[MAIN] Started loop!")
end

-- Запуск хоста
local function StartHost()
    print("[HOST] Starting...\n")
    if module.network.initHost(config.localPort) then
        isHost = true
        StartLoop()
        print("[HOST] === ACTIVE ===\n")
    end
end

-- Запуск клиента
local function StartClient()
    print("[CLIENT] Starting...\n")
    if module.network.initClient() then
        print ("start ccc")
        module.network.connect(config.targetHost, config.targetPort)
        isHost = false
        StartLoop()
        print("[CLIENT] === ACTIVE ===\n")
    end
end

-- Регистрация клавиш
RegisterConsoleCommandHandler("H", function()
    if Running then
        print("[KEY] Sync active, ignoring\n")
        return
    end
    print("\n[KEY] F - HOST\n")
    StartHost()
end)

RegisterConsoleCommandHandler("C", function()
    if Running then
        print("[KEY] Sync active, ignoring\n")
        return
    end
    print("\n[KEY] G - CLIENT\n")
    StartClient()
end)

print("========================================\n")
print("F - Start as HOST\n")
print("G - Start as CLIENT\n")
print("========================================\n")