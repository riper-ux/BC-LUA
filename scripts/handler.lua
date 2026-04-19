local udp = require("udp")
local serializer = require("serializer")
local player = require("player")
local handler = {}
function handler.handle ()
    local queue, ip, port = udp.receive()
    for i = 1, #queue do
        if not queue[i] then
            break
        end
        print("[HANDLER] Processing: " .. queue[i])
        if string.sub(queue[i], 1, 6) == "OPND: " then
            local door = StaticFindObject(string.sub(queue[i], 7))
            if door and door:IsValid() then
                door:openDoor()
            end
        elseif string.sub(queue[i], 1, 6) == "CLSD: " then
            local door = StaticFindObject(string.sub(queue[i], 7))
            if door and door:IsValid() then
                door:CloseDoor()
            end
        else
            local parsed = serializer.deserialize(queue[i])
            if parsed then
                player.handle(parsed.pos, parsed.rot)
            end
        end
    end
end
return handler