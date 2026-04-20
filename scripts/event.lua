local config = require("config")
local udp = require("udp")
local event = {}

function event.init()
    local EventsToProccess = config.EventsToProccess
    for i = 1, #EventsToProccess do
        RegisterHook(EventsToProccess[i], function(context, ...)
            local params = {}
            print("[EVENT] CATCHED: " .. ((context:get()):GetFullName()):match("/.+") .. ":" .. (EventsToProccess[i]):match(":(.*)$") .. " with args " .. (#{...}) .. "\n")
            for i = 1, select('#', ...) do
                table.insert(params, i, ({...})[i]:get())
            end
            udp.add({"event", ((context:get()):GetFullName()):match("/.+"), (EventsToProccess[i]):match(":(.*)$"), params})
        end)
    end
end

function event.handle(data)
    local object = StaticFindObject(data[2])
    if object and object:IsValid() then 
        print("[EVENT] RECEIVED: " .. data[2] .. ":" .. data[3] .. " with args " .. #data[4] .. "\n")
        object[data[3]](object, table.unpack(data[4]))
    else
        print("NOT VALID OBJECT: " .. data[2] .. ":" .. data[3] .. " with args " .. #data[4] .. "\n")
    end
end

return event