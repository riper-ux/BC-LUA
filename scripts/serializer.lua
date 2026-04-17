-- serializer.lua
local serializer = {}

function serializer.serialize(pos, rot)
    return pos.X .. "," .. pos.Y .. "," .. pos.Z .. "|" .. rot.Pitch .. "," .. rot.Yaw .. "," .. rot.Roll
end

function serializer.deserialize(data)
    if not data then return nil end
    local posPart, rotPart = string.match(data, "([^|]+)|([^|]+)")
    if not posPart or not rotPart then return nil end
    
    local x,y,z = string.match(posPart, "([^,]+),([^,]+),([^,]+)")
    local p,ya,r = string.match(rotPart, "([^,]+),([^,]+),([^,]+)")
    
    if not x or not y or not z or not p or not ya or not r then return nil end
    
    return {
        pos = {X = tonumber(x), Y = tonumber(y), Z = tonumber(z)},
        rot = {Pitch = tonumber(p), Yaw = tonumber(ya), Roll = tonumber(r)}
    }
end

return serializer