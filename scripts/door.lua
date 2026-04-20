local door = {}
local DoorReady = false
local udp = require("udp")
function door.init()
    print("Init door")
RegisterHook("/Game/objects/door.door_C:doorOpen", function(context, ...)
    local door = context:get()
    
    if door and door:IsValid() then
        print("Door opened: " .. door:GetFullName())
        udp.add({"DOOR", "OPEN", door:GetFullName()})
    end
end)

RegisterHook("/Game/objects/door.door_C:doorClose", function(context, ...)
    local door = context:get()
    
    if door and door:IsValid() then
        print("Door closed: " .. door:GetFullName())
        udp.add({"DOOR", "CLOSE", door:GetFullName()})
    end
end)

    DoorReady = true
end

function door.sync()
    if not DoorReady then
        print("[DOOR] Not ready! Readying...")
        door.init()
    end
end

function door.handle(data)
    local current = StaticFindObject(data[3])
    if data[2] == "OPEN" then
        current:doorOpen
    elseif data[2] == "CLOSE" then
        current:doorClose
    end
end

return door