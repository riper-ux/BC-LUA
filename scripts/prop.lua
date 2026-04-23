local network = require("network")
local spawner = require("spawner")
local config = require("config")
local player = require("player")

local prop = {}
local props = {}
local grid = {}
local force = {}
local sgrid = {}
local tolc = {os.clock(), os.clock()}
local temp = 0
local GRID_SIZE = 1000

function prop.get_grid(pos)
    return math.floor(pos.X / GRID_SIZE), math.floor(pos.Z / GRID_SIZE)
end

function prop.get3x3Grid(centerX, centerZ)
    local grid = {}
    local index = 1
    
    for dx = -1, 1 do
        for dz = -1, 1 do
            grid[index] = {
                x = centerX + dx,
                z = centerZ + dz
            }
            index = index + 1
        end
    end
    
    return grid
end

function prop.cache()
    local count = 1
    print("[PROP] Caching props...\n")
    local Props = FindAllOf("prop_C")
    if not Props then
        print("[PROP] No props found!\n")
        return
    end
    for i=1, #Props do
        if count == 100 then 
            print("[PROP] Cached: " .. i .. "/" .. #Props .. "\n")
            count = 0
        end
        if Props[i]:IsValid() then
            local ok, IDVal = pcall(function() return Props[i]:GetPropertyValue("key") end)
            if IDVal then
                local ok2, id = pcall(function() return IDVal:ToString() end)
                if id and id ~= "None" and type(id) == "string" then
                    props[id] = {Props[i], Props[i]:K2_GetActorLocation(), Props[i]:K2_GetActorRotation(), {X=1, Y=1, Z=1}, os.clock()}
                    if not network.isHost then props[id][1]:SetPropProps(nil, true, nil, nil) end
                    local x, z = prop.get_grid(Props[i]:K2_GetActorLocation())
                    if x and z then
                        if not grid[x] then grid[x] = {} end
                        if not grid[x][z] then grid[x][z] = {} end
                        grid[x][z][id] = 1
                    else
                        print("[PROP] WARNING: Invalid position! " .. Props[i]:GetFullName() .. " \n")
                    end
                    --print("[PROP] Cached: ".. id .. ", " .. Props[i]:GetFullName() .. ", Grid[" .. x .. "][" .. z .. "]" .. "\n")
                elseif not id or id == "None" or type(id) ~= "string" then
                    print("[PROP] WARNING: Invalid ID! " .. Props[i]:GetFullName() .. " \n")
                end
            end
        end
        count = count + 1
    end 
    print("[PROP] Cached: " .. #Props .. "/" .. #Props .. "\n")
    print("[PROP] Done caching\n")
end

function prop.init()
    if not network.isHost then
        local id = nil
        RegisterHook("/Game/main/mainPlayer.mainPlayer_C:pickupObject", function(context, ...)
            local cprop = (context:get())["grabbing_actor"]
            if not cprop or not cprop:GetFullName() then return end
            id = (cprop:GetPropertyValue("key")):ToString()
            print("[PROP] Begin holding: " .. id .. "\n")
            force[id] = 1
            network.add({"prop", id, "Hold"})
        end)
        RegisterHook("/Game/main/mainPlayer.mainPlayer_C:dropGrabObject", function(context, ...)
            print("[PROP] End holding: " .. id .. "\n")
            force[id] = nil
            network.add({"prop", id, "UnHold"})
        end)
    end
    prop.cache()
    return "sync"
end

function prop.sync()
    if network.isHost then
        --print("[PROP] Syncing props...\n")
        local tx, tz = prop.get_grid(player.getPos())
        local targets = prop.get3x3Grid(tx, tz)
        temp = 0
        for i, v in pairs(targets) do
            if grid[v.x] and grid[v.x][v.z] then

                for value, index in pairs(grid[v.x][v.z]) do
                    local id = value
                    local prop = props[id][1]
                    temp = temp + 1
                    if prop:IsValid() then
                        local pos = prop:K2_GetActorLocation()
                        local rot = prop:K2_GetActorRotation()
                        local scale = {X = 1, Y = 1, Z = 1}
                        local correction = ((math.sqrt((pos.X - props[id][2].X)^2 + (pos.Y - props[id][2].Y)^2 + (pos.Z - props[id][2].Z)^2)) * 0.001 + 1) ^ 2
                        if math.abs(pos.X - props[id][2].X) > correction or
                        math.abs(pos.Y - props[id][2].Y) > correction or
                        math.abs(pos.Z - props[id][2].Z) > correction or
                        math.abs(rot.Pitch - props[id][3].Pitch) > correction or
                        math.abs(rot.Yaw - props[id][3].Yaw) > correction or
                        math.abs(rot.Roll - props[id][3].Roll) > correction then
                            if type(id) ~= "userdata" and type(pos) ~= "userdata" and type(rot) ~= "userdata" and type(scale) ~= "userdata" then
                                network.add({"prop", id, pos, rot, scale})
                                --print("[PROP] Sync: " .. prop:GetFullName() .. "\n")
                                props[id][2] = pos
                                props[id][3] = rot
                                props[id][4] = scale
                                props[id][5] = os.clock()
                            end
                        else
                            if props[id][5] + 5 < os.clock() then
                                if not sgrid[v.x] then sgrid[v.x] = {} end
                                if not sgrid[v.x][v.z] then sgrid[v.x][v.z] = {} end
                                sgrid[v.x][v.z][id] = 1
                                grid[v.x][v.z][id] = nil
                            end
                        end
                    end
                end
            end
        end
        if os.clock() - tolc[2] > 1 then
            for i, v in pairs(targets) do
                if sgrid[v.x] and sgrid[v.x][v.z] then
                    for id, _ in pairs(sgrid[v.x][v.z]) do
                        local propObj = props[id][1]
                        if propObj and propObj:IsValid() then
                            local pos = propObj:K2_GetActorLocation()
                            local rot = propObj:K2_GetActorRotation()
                        
                            -- ТА ЖЕ САМАЯ ЛОГИКА КОРРЕКЦИИ
                            local dx = pos.X - props[id][2].X
                            local dy = pos.Y - props[id][2].Y
                            local dz = pos.Z - props[id][2].Z
                            local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
                            local correction = (distance * 0.001 + 1) ^ 2
                        
                            local moved = math.abs(dx) > correction or
                            math.abs(dy) > correction or
                            math.abs(dz) > correction or
                            math.abs(rot.Pitch - props[id][3].Pitch) > correction or
                            math.abs(rot.Yaw - props[id][3].Yaw) > correction or
                            math.abs(rot.Roll - props[id][3].Roll) > correction
                        
                            if moved then
                                -- ПРОСЫПАЕМСЯ (возвращаем в активные)
                                if not grid[v.x] then grid[v.x] = {} end
                                if not grid[v.x][v.z] then grid[v.x][v.z] = {} end
                                grid[v.x][v.z][id] = 1
                                sgrid[v.x][v.z][id] = nil
                                props[id][5] = os.clock()  -- сбрасываем таймер
                            end
                        end
                    end
                end
            end
            print("[PROP] Status: " .. "Grid[" .. tx .. "][" .. tz .. "]" .. " Active Props: " .. temp .. "\n")
            tolc[2] = os.clock()
        end
    else
        for index, value in pairs(force) do
            local propObj = props[index][1]
            if propObj and propObj:IsValid() then
                local pos = propObj:K2_GetActorLocation()
                local rot = propObj:K2_GetActorRotation()
                local scale = {X = 1, Y = 1, Z = 1}
                if type(index) ~= "userdata" and type(pos) ~= "userdata" and type(rot) ~= "userdata" and type(scale) ~= "userdata" then
                    network.add({"prop", index, pos, rot, scale})
                    --print("[PROP] Sync: " .. propObj:GetFullName() .. "\n")
                    props[index][2] = pos
                    props[index][3] = rot
                    props[index][4] = scale
                    props[index][5] = os.clock()
                end
            end
        end
    end
end

function prop.handle(data)
    --print("[PROP] Handle: " .. data[2] .. "\n")
    if type(data[3]) ~= "string" then
        local id = data[2]
        local pos = data[3]
        local rot = data[4]
        local scale = data[5]
        if props[id] then
            if props[id][1]:IsValid() then
                if not network.isHost and not force[id] then props[id][1]:SetPropProps(nil, true, nil, nil) end
                if not force[id] then
                    local success = spawner.move(props[id][1], pos, rot, scale)
                    if success == true then
                        props[id][2] = pos
                        props[id][3] = rot
                        props[id][4] = scale
                    end
                else
                    print("[PROP] Handle ignoring force: " .. id .. "\n")
                end
            end
        end
    else
        if data[3] == "Hold" then
            props[data[2]][1]:SetPropProps(true, nil, nil, nil)
        elseif data[3] == "UnHold" then
            props[data[2]][1]:SetPropProps(false, nil, nil, nil)
        end
    end
end

return prop