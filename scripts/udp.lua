-- udp.lua
local socket = require("socket")
local json = require("lib.json.json")

local udp = {}
local udpSocket = nil
local remoteAddress = nil
local remotePort = nil
udp.queue = {}

function udp.initHost(port)
    udpSocket = socket.udp()
    udpSocket:settimeout(0)
    udpSocket:setoption('reuseaddr', true)
    udpSocket:setsockname('0.0.0.0', port)
    print("[UDP] Host on port " .. port)
    return true
end

function udp.initClient(host, port)
    udpSocket = socket.udp()
    udpSocket:settimeout(0)
    udp.setPeer(host, port)
    print("[UDP] Client to " .. host .. ":" .. port)
    return true
end

function udp.add(data)
    --print("[UDP] Adding data to queue")
    table.insert(udp.queue, data)
end

function udp.send()
    if udpSocket and udp.queue and (#udp.queue > 0) and remoteAddress and remotePort then
        --print("[UDP] Sending data...")
        local data = json.encode(udp.queue)
        --print(data)
        udpSocket:send(data)
        --print("[UDP] Data sent")
        udp.queue = {}
    end
end

function udp.receive()
    if udpSocket and not remoteAddress and not remotePort then
        local data, ip, port = udpSocket:receivefrom()
        if not data then return nil end
        data = json.decode(data)
        return data, ip, port
    end
    return nil
end

function udp.setPeer(ip, port)
    remoteAddress = ip
    remotePort = port
    udpSocket:setpeername(remoteAddress, remotePort)
    print("[UDP] Peer set to " .. ip .. ":" .. port)
end

function udp.close()
    if udpSocket then
        udpSocket:close()
        udpSocket = nil
    end
end

return udp