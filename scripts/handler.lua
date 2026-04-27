local config = require("config")
local handler = {}
local module = {}

function handler.init()
    for i = 1, #config.Modules do
        if config.Modules[i] ~= "handler" then
            print("[HANDLER] Preparing... " .. config.Modules[i] .. " " .. i .. "/" .. #config.Modules .. "\n")
            module[config.Modules[i]] = require(config.Modules[i])
        end
    end
    return "handle"
end

function handler.handle()
    local queue, ip, port = module.network.receive()
    if not queue then return end
    --print("[HANDLER] Received data with " .. #queue .. "\n")
    for i = 1, #queue do
        --print("[HANDLER] Processing: " .. i .. "/" .. #queue .. "\n")
        queue[i].ip = ip
        queue[i].port = port
        module[queue[i][1]].handle(queue[i])
    end
    queue = nil
end
return handler