local door = {}
local DoorReady = false
local udp = require("udp")
function door.init()
    print("Init door")
RegisterHook("/Game/objects/door.door_C:doorOpen", function(context, ...)
    local door = context:get()
    
    if door and door:IsValid() then
        print("Door opened: " .. door:GetFullName())
        udp.add("OPND: " .. door:GetFullName())
    end
end)

RegisterHook("/Game/objects/door.door_C:doorClose", function(context, ...)
    local door = context:get()
    
    if door and door:IsValid() then
        print("Door closed: " .. door:GetFullName())
        udp.add("CLSD: " .. door:GetFullName())
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

return door