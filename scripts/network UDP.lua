-- network.lua
local socket = require("socket")
local json = require("lib.json.json")

local network = {}
local sockets = {}
local clients = {}
network.queue = {}
network.isHost = false

function network.init()
    return "send"
end

function network.addClient(ip, port)
    for i=1, #clients do
        if clients[i].ip == ip and clients[i].port == port then
            return false
        end
    end
    print("[NETWORK] Adding client " .. ip .. ":" .. port)
    table.insert(clients, {ip = ip, port = port})
    return true
end

function network.initHost(port)
    table.insert(sockets, socket.udp())
    sockets[1]:settimeout(0)
    sockets[1]:setoption('reuseaddr', true)
    sockets[1]:setsockname('0.0.0.0', port)
    print("[NETWORK] Socket on port " .. port)
    network.isHost = true
    return true
end

function network.initClient(host, port, port1)
    table.insert(sockets, socket.udp())
    sockets[1]:settimeout(0)
    sockets[1]:setoption('reuseaddr', true)
    sockets[1]:setsockname('0.0.0.0', port1)
    network.addClient(host, port)
    print("[NETWORK] Socket on port " .. port1)
    network.isHost = false
    return true
end

function network.add(data)
    --print("[NETWORK] Adding data to queue")
    table.insert(network.queue, data)
end

function network.send()
    if sockets[1] and (#network.queue > 0) and (#clients > 0) then
        --print("[NETWORK] Sending data...")
        local data = json.encode(network.queue)
        --print(data)
        for i=1, #clients do
            sockets[1]:sendto(data, clients[i].ip, clients[i].port)
            --print("[NETWORK] Data sent")
        end
        network.queue = {}
    elseif (#network.queue > 1000) then
        print("[NETWORK] WARNING: Queue overflow! Resetting queue...\n")
        network.queue = {}
    end
end

function network.receive()
    if sockets[1] then
        local data, ip, port = sockets[1]:receivefrom()
        if not data then return nil end
        --print("[NETWORK] Received data")
        data = json.decode(data)
        if ip and port and network.isHost then
            network.addClient(ip, port)
        end
        return data, ip, port
    end
    return nil
end

function network.close()
    if sockets[1] then
        sockets[1]:close()
        sockets[1] = nil
    end
end

return network