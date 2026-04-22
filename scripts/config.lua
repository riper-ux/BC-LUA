-- config.lua
local config = {
    localPort = 12345,
    localPort1 = 12346,
    targetHost = "127.0.0.1",
    targetPort = 12345,
    TPS = 10,
    EventsToProccess = {"/Game/objects/door.door_C:doorOpen", "/Game/objects/door.door_C:doorClose"},
    Modules = {"player", "event", "handler", "network", "spawner", "tests", "prop"},
    cubePath = "/Game/Mods/BC-ToolKit/Player.Player_C",
    modActorClass = "ModActor_C",
    playerClass = "mainPlayer_C",
}
return config