local network = require("network")
local spawner = require("spawner")

local prop = {}
local props = {}

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
                    table.insert(props, {id, Props[i], Props[i]:K2_GetActorLocation(), Props[i]:K2_GetActorRotation(), {X=1, Y=1, Z=1}})
                elseif not id or id == "None" then
                    print("[PROP] WARNING: Invalid ID! " .. Props[i]:GetFullName() .. " \n")
                end
            end
        end
        count = count + 1
    end 
    print("[PROP] Done caching\n")
end

function prop.init()
    prop.cache()
    return "sync"
end

function prop.sync()
    --print("[PROP] Syncing props...\n")
    for i=1, #props do
        local id = props[i][1]
        local prop = props[i][2]
        local pos = prop:K2_GetActorLocation()
        local rot = prop:K2_GetActorRotation()
        local scale = {X = 1, Y = 1, Z = 1}
        if math.abs(pos.X - props[i][3].X) > 1 or
        math.abs(pos.Y - props[i][3].Y) > 1 or
        math.abs(pos.Z - props[i][3].Z) > 1 or
        math.abs(rot.Pitch - props[i][4].Pitch) > 1 or
        math.abs(rot.Yaw - props[i][4].Yaw) > 1 or
        math.abs(rot.Roll - props[i][4].Roll) > 1 or
        math.abs(scale.X - props[i][5].X) > 1 or
        math.abs(scale.Y - props[i][5].Y) > 1 or
        math.abs(scale.Z - props[i][5].Z) > 1 then
            if type(id) ~= "userdata" and type(pos) ~= "userdata" and type(rot) ~= "userdata" and type(scale) ~= "userdata" then
                network.add({"prop", id, pos, rot, scale})
                print("[PROP] Sync: " .. prop:GetFullName() .. "\n")
                props[i][3] = pos
                props[i][4] = rot
                props[i][5] = scale
            end
        end
    end
end

function prop.handle(data)
    print("[PROP] Handle: " .. data[2] .. "\n")
    local id = data[2]
    local pos = data[3]
    local rot = data[4]
    local scale = data[5]
    for i=1, #props do
        if props[i][1] == id then
            if props[i][2]:IsValid() then
                local success = spawner.move(props[i][2], pos, rot, scale)
                if success == true then
                    props[i][3] = pos
                    props[i][4] = rot
                    props[i][5] = scale
                end
            end
            break
        end
    end
end

return prop