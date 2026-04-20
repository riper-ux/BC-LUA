local udp = require("udp")
local serializer = require("serializer")
local player = require("player")
local config = require("config")
local handler = {}

function handler.handle()
    local queue, ip, port = udp.receive()
    for i = 1, #queue do
        print("[HANDLER] Processing: " .. queue[i])
        (queue[i][1]):handle(queue[i])
    end
end
return handler