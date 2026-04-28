local config = require("config")
local network = require("network")
local event = {}
local ignore = {}

local function addignore(data)
    table.insert(ignore, data[2] .. ":" .. data[3])
end

local function getignore(data1, data2)
    for i = 1, #ignore do
        if ignore[i] == data1 .. ":" .. data2 then
            table.remove(ignore, i)
            return true
        end
    end 
    return false
end

function event.init()
    local EventsToProccess = config.EventsToProccess
    for i = 1, #EventsToProccess do
        RegisterHook(EventsToProccess[i], function(context, ...)
            local FullName = ((context:get()):GetFullName()):match("/.+")
            local Event = (EventsToProccess[i]):match(":(.*)$")
            local params = {}
            if getignore(FullName, Event) then return nil end
            print("[EVENT] CATCHED: " .. FullName .. ":" .. Event .. " with args " .. (#{...}) .. "\n")
            for i = 1, select('#', ...) do
                print("[EVENT] Arg " .. i .. ": " .. type(({...})[i]:get()) .. "\n")
                table.insert(params, i, ({...})[i]:get())
            end
            network.add({"event", FullName, Event, params})
        end)
    end
end

function event.handle(data)
    local object = StaticFindObject(data[2])
    if object and object:IsValid() then 
        print("[EVENT] RECEIVED: " .. data[2] .. ":" .. data[3] .. " with args " .. #data[4] .. "\n")
        addignore(data)
        object[data[3]](object, table.unpack(data[4]))
    else
        print("NOT VALID OBJECT: " .. data[2] .. ":" .. data[3] .. " with args " .. #data[4] .. "\n")
    end
end

return event