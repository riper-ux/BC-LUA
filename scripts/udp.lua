-- udp.lua
local socket = require("lib.luasocket.socket")
local json = require("lib.json.json")

local udp = {}
udp.queue = {}
local udpSocket = nil
local remoteAddress = nil
local remotePort = nil

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
    udpSocket:setpeername(host, port)
    print("[UDP] Client to " .. host .. ":" .. port)
    return true
end

function udp.add(data)
    table.insert(udp.queue, data)
end

function udp.send()
    if udpSocket and #udp.queue > 0 then
        udpSocket:send(json.encode(udp.queue))
    end
end

function udp.receive()
    if udpSocket then
        local data, ip, port = udpSocket:receivefrom()
        data = json.decode(data)
        return data, ip, port
    end
    return nil
end

function udp.receiveClient()
    if udpSocket then
        return udpSocket:receive()
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