local config = require("config")
local event = {}
function event.init()
    local EventsToProccess = config.EventsToProccess
    for i = 1, #EventsToProccess do
        RegisterHook(EventsToProccess[i], function(context, ...)
            print("[EVENT] CATCHED: " .. (context:get()):GetFullName() .. ":" .. (EventsToProccess[i]):match(":(.*)$"))
            udp.add({"event", (context:get()):GetFullName(), (EventsToProccess[i]):match(":(.*)$")})
        end)
    end
end
function event.handle(data)
    local object = StaticFindObject(data[2])
    if object and object:IsValid then 
        print("[EVENT] RECEIVED: " .. data[2] .. ":" .. data[3])
        object:(data[3]) 
    end
end
return event