-- network.lua
local socket = require("socket")
local json = require("lib.json.json")

local network = {}
local asocket = nil
local clients = {}
network.queue = {}
network.isHost = false

local function concatMultiple(...)
    local result = {}
    local offset = 0
    
    for _, arr in ipairs({...}) do
        if arr and #arr > 0 then
            table.move(arr, 1, #arr, offset + 1, result)
            offset = offset + #arr
        end
    end
    
    return result
end

function network.init()
    return "send"
end

function network.initHost(port)
    asocket = socket.tcp()
    asocket:settimeout(0)
    asocket:setoption('reuseaddr', true)
    asocket:setoption('keepalive', true)
    asocket:bind('0.0.0.0', port)
    asocket:listen(5)
    print("[NETWORK] Socket on port " .. port)
    network.isHost = true
    return true
end

function network.initClient()
    asocket = socket.tcp()
    asocket:settimeout(0)
    asocket:setoption('reuseaddr', true)
    asocket:setoption('keepalive', true)
    print("[NETWORK] Socket on port ")
    network.isHost = false
    return true
end

function network.connect(ip, port)
    print("[NETWORK] Attempting to connect to " .. ip .. ":" .. port)
    if asocket then
        print("[NETWORK] Attempting to connect to " .. ip .. ":" .. port)
        if network.isHost then
            print("[NETWORK] ERROR: Is host")
            return false
        else
            print("[NETWORK] Attempting to connect to " .. ip .. ":" .. port)
            asocket:settimeout(1)
            local ok, err = asocket:connect(ip, port) 
            print("[NETWORK] Attempting to connect to " .. ip .. ":" .. port)
            if ok then
                print("[NETWORK] Connected to " .. ip .. ":" .. port .. "\n")
                asocket:settimeout(0)
                return true
            else
                print("[NETWORK] ERROR: Failed to connect to " .. ip .. ":" .. port .. ":" .. err .. "\n")
                return false
            end
        end
    else
        print("[NETWORK] ERROR: No socket")
        return false
    end
end

function network.add(data)
    --print("[NETWORK] Adding data to queue")
    table.insert(network.queue, data)
end

function network.send()
    if asocket and (#network.queue > 0) then
        if network.isHost then
            for index, value in pairs(clients) do
                local data = json.encode(network.queue)
                value:send(data .. "\n")
            end
            network.queue = {}
        else
            local data = json.encode(network.queue)
            asocket:send(data .. "\n")
            network.queue = {}
        end
    elseif (#network.queue > 1000) then
        print("[NETWORK] WARNING: Queue overflow! Resetting queue...\n")
        network.queue = {}
    end
end

function network.receive()
    if asocket then
        local temp = {}
        if network.isHost then
            local ready = socket.select({asocket}, nil, 0)
            if ready and #ready > 0 then
                local ok, err = asocket:accept()
                if ok then
                    print("[NETWORK] Accepted connection")
                    ok:settimeout(0)
                    table.insert(clients, ok)
                else
                    print("[NETWORK] ERROR: Failed to accept connection: " .. err)
                end
            end
            for index, value in pairs(clients) do
                local data = value:receive('*l')
                if data then
                    --print("[NETWORK] Received data")
                    data = json.decode(data)
                    --print(#data .. "\n")
                    table.insert(temp, data)
                end
            end
        else
            local data = asocket:receive('*l')
            if data then
                --print("[NETWORK] Received data")
                data = json.decode(data)
                --print(#data .. "\n")
                table.insert(temp, data)
            end
        end
        return concatMultiple(table.unpack(temp))
    end
    return nil
end

function network.close()
    if asocket then
        asocket:close()
        asocket = nil
    end

end

return network