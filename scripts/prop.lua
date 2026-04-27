local network = require("network")
local spawner = require("spawner")
local config = require("config")

local prop = {}
local props = {}
local active = {}
local sleep = {}
local force = {}
local tolc = {os.clock(), os.clock()}
local temp = 0
local correction = config.correction

function prop.getCount(table)
    local count = 0
    for _,_ in pairs(table) do
        count = count + 1
    end
    return count
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
                    sleep[id] = 1
                    if not network.isHost then props[id][1]:SetPropProps(nil, true, nil, nil) end
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

        for id, _ in pairs(active) do
            local prop = props[id][1]
            temp = temp + 1
            if prop:IsValid() then
                local pos = prop:K2_GetActorLocation()
                local rot = prop:K2_GetActorRotation()
                local scale = {X = 1, Y = 1, Z = 1}
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
                        sleep[id] = 1
                        active[id] = nil
                    end
                end
            end
        end
        if os.clock() - tolc[2] > 1 then
            for id, _ in pairs(sleep) do
                local propObj = props[id][1]
                if propObj and propObj:IsValid() then
                    local pos = propObj:K2_GetActorLocation()
                    local rot = propObj:K2_GetActorRotation()
                        
                    -- ТА ЖЕ САМАЯ ЛОГИКА КОРРЕКЦИИ
                    local dx = pos.X - props[id][2].X
                    local dy = pos.Y - props[id][2].Y
                    local dz = pos.Z - props[id][2].Z
                        
                    local moved = math.abs(dx) > correction or
                    math.abs(dy) > correction or
                    math.abs(dz) > correction or
                    math.abs(rot.Pitch - props[id][3].Pitch) > correction or
                    math.abs(rot.Yaw - props[id][3].Yaw) > correction or
                    math.abs(rot.Roll - props[id][3].Roll) > correction
                        
                    if moved then
                        -- ПРОСЫПАЕМСЯ (возвращаем в активные)
                        active[id] = 1
                        sleep[id] = nil
                        props[id][5] = os.clock()  -- сбрасываем таймер
                    end
                end
            end
            print("[PROP] Active: " .. prop.getCount(active) .. " Sleep: " .. prop.getCount(sleep) .. " Total: " .. prop.getCount(props) .. "\n")
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
    print("[PROP] Handle: " .. data[2] .. "\n")
    if type(data[3]) ~= "string" then
        local id = data[2]
        local pos = data[3]
        local rot = data[4]
        local scale = data[5]
        if props[id] then
            print("g\n")
            if props[id][1]:IsValid() then
                print("h\n")
                if not network.isHost and not force[id] then props[id][1]:SetPropProps(nil, true, nil, nil) end
                if not force[id] then
                    print("[PROP] Handle moving: " .. id .. "\n")
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