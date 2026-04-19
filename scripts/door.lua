local door = {}
local DoorReady = false
local udp = require("udp")
function door.init()
    print("Init door")
RegisterHook("/Game/objects/door.door_C:doorOpen", function(context, ...)
    local door = context:get()
    
    if door and door:IsValid() then
        print("Door opened: " .. door:GetFullName())
        table.insert(udp.queue, "OPND: " .. door:GetFullName())
    end
end)

RegisterHook("/Game/objects/door.door_C:doorClose", function(context, ...)
    local door = context:get()
    
    if door and door:IsValid() then
        print("Door closed: " .. door:GetFullName())
        table.insert(udp.queue, "CLSD: " .. door:GetFullName())
    end
end)

    DoorReady = true
end

function door.sync()
    if not DoorReady then
        print("Door not ready! Readying...")
        door.init()
    end
end

return door