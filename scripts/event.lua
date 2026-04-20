local config = require("config")
local udp = require("udp")
local event = {}

function event.init()
    local EventsToProccess = config.EventsToProccess
    for i = 1, #EventsToProccess do
        RegisterHook(EventsToProccess[i], function(context, ...)
            print("[EVENT] CATCHED: " .. ((context:get()):GetFullName()):match("/.+") .. ":" .. (EventsToProccess[i]):match(":(.*)$") .. "\n")
            udp.add({"event", ((context:get()):GetFullName()):match("/.+"), (EventsToProccess[i]):match(":(.*)$")})
        end)
    end
end

function event.handle(data)
    local object = StaticFindObject(data[2])
    print("[EVENT] RECEIVED: " .. data[2] .. ":" .. data[3] .. "\n")
    print("[EVENT] OBJECT: " .. tostring(object) .. "\n")
    if object then 
        print("[EVENT] RECEIVED: " .. data[2] .. ":" .. data[3] .. "\n")
        object[data[3]](object, nil)
    end
end

return event