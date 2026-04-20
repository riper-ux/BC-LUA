local udp = require("udp")
local config = require("config")
local handler = {}
local module = {}

function handler.init()
    for i = 1, #config.Modules do
        print("[HANDLER] Preparing... " .. config.Modules[i] .. " " .. i .. "/" .. #config.Modules .. "\n")
        module[config.Modules[i]] = require(config.Modules[i])
    end
    return "handle"
end

function handler.handle()
    local queue, ip, port = udp.receive()
    if not queue then return end
    for i = 1, #queue do
        --print("[HANDLER] Processing: " .. i .. "/" .. #queue .. "\n")
        module[queue[i][1]].handle(queue[i])
    end
    queue = nil
end
return handler