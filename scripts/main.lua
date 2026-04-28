-- main.lua
print("\n")
print("=== PROTOTYPE? ===\n")
print("\n")

local config = require("config")

local isSyncActive = false
local isHost = false
local isClient = false
local Running = false
local ReadyAsync = true
local SyncTPS = 0
local AsyncTPS = 0
local clock = os.clock()
local Tclock = os.clock()
local Sync = {}
local Async = {}
local module = {}

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

local function TickAsync()
    for i = 1, #functoexecute do
        module[Async[i][1]][Async[i][2]](module[Async[i][1]])
    end
end

-- Цикл синхронизации
local function Loop()
    if not isSyncActive then return end
    if os.clock() - clock >= 1 then
        clock = os.clock()
        local color = nil
        if ticker > 1000000 then color = module.cprint.colors.bright_blue elseif ticker > 100000 then color = module.cprint.colors.bright_green elseif ticker > 10000 then color = module.cprint.colors.yellow elseif ticker > 1000 then color = module.cprint.colors.magenta else color = module.cprint.colors.bright_red end
        if ticker < config.TPS * 2 then module.cprint.print("!!!OVERLOAD!!!\n", color) end
        module.cprint.print("[LOOP] TICKER: " .. ticker .. "\n", color)
        module.cprint.print("[LOOP] TPS: " .. Tticker .. "\n", color)
        if ticker < config.TPS * 2 then module.cprint.print("!!!OVERLOAD!!!\n", color) end
        ticker = 0
        Tticker = 0
    end
    if os.clock() - Tclock >= (1/config.TPS) then
        Tclock = os.clock()
        Tick()
        Tticker = Tticker + 1
    end
    ticker = ticker + 1
end

local function AsyncLoop()
    if not isSyncActive then return end
    if os.clock() - clock >= 1 then
        clock = os.clock()
        local color = nil
        if ticker > 1000000 then color = module.cprint.colors.bright_blue elseif ticker > 100000 then color = module.cprint.colors.bright_green elseif ticker > 10000 then color = module.cprint.colors.yellow elseif ticker > 1000 then color = module.cprint.colors.magenta else color = module.cprint.colors.bright_red end
        if ticker < config.TPS * 2 then module.cprint.print("!!!OVERLOAD!!!\n", color) end
        module.cprint.print("[ASYNC] TICKER: " .. ticker .. "\n", color)
        module.cprint.print("[ASYNC] TPS: " .. Tticker .. "\n", color)
        if ticker < config.TPS * 2 then module.cprint.print("!!!OVERLOAD!!!\n", color) end
        ticker = 0
        Tticker = 0
    end
    if os.clock() - Tclock >= (1/config.TPS) then
        Tclock = os.clock()
        Tick()
        Tticker = Tticker + 1
    end
    ticker = ticker + 1
end

-- Запуск цикла
local function StartSyncLoop()
    if syncRunning then return end
    for i = 1, #config.Modules do
        print("[MODULAR] Preparing... " .. config.Modules[i] .. " " .. i .. "/" .. #config.Modules .. "\n")
        module[config.Modules[i]] = require(config.Modules[i])
    end
    syncRunning = true
    print("[MAIN] Starting loop\n")
    print("[MODULAR] Started!\n")
    for i = 1, #config.Modules do
        print("[MODULAR] Initialization... " .. config.Modules[i] .. " " .. i .. "/" .. #config.Modules .. "\n")
        local sync, async = module[config.Modules[i]].init()
        if sync then
            print("[MODULAR] Registration... (Sync) " .. config.Modules[i] .. "\n")
            table.insert(Sync, {config.Modules[i], func})
        end
        if async then
            print("[MODULAR] Registration... (Async) " .. config.Modules[i] .. "\n")
            table.insert(Async, {config.Modules[i], func})
        end
    end
    clock = os.clock()
    Tclock = os.clock()
    RegisterCustomEvent("BC_Tick",function()
        if isSyncActive then
            Loop()
        end
    end)
    print("[MAIN] Started loop!")
end

-- Запуск хоста
local function StartHost()
    print("[HOST] Starting...\n")
    if isSyncActive then StopSync() end
    
    if module.network.initHost(config.localPort) then
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
    
    if module.network.initClient() then
        print ("start ccc")
        module.network.connect(config.targetHost, config.targetPort)
        isClient = true
        isHost = false
        isSyncActive = true
        StartSyncLoop()
        print("[CLIENT] === ACTIVE ===\n")
    end
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

print("========================================\n")
print("F - Start as HOST\n")
print("G - Start as CLIENT\n")
print("========================================\n")