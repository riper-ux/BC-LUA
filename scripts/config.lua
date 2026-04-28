-- config.lua
local config = {
    -- main.lua
    TPS = 60,
    Modules = {"player", "handler", "event", "network", "spawner", "prop", "cprint"},
    -- network.lua
    localPort = 12345,
    localPort1 = 12346,
    targetHost = "127.0.0.1",
    targetPort = 12345,
    -- event.lua
    EventsToProccess = {"/Game/objects/door.door_C:doorOpen",
    "/Game/objects/door.door_C:doorClose",
    "/Game/objects/passwordLock.passwordLock_C:inputNumber",
    "/Game/objects/serverBox.serverBox_C:breakServer",
    "/Game/objects/serverBox.serverBox_C:fix"},
    -- spawner.lua
    cubePath = "/Game/Mods/BC-ToolKit/Player.Player_C",
    modActorClass = "ModActor_C",
    -- prop.lua
    correction = 5 -- (units)
}
return config