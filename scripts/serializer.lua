-- serializer.lua
-- Расширенный сериализатор с поддержкой UE4SS userdata
local codec = require("userdata_codec")
local serializer = {}

-- Сериализация данных с поддержкой userdata
function serializer.serialize(data)
    if not data then return nil end
    
    -- Если это таблица с pos и rot (старый формат)
    if data.pos and data.rot then
        local pos = data.pos
        local rot = data.rot
        return pos.X .. "," .. pos.Y .. "," .. pos.Z .. "|" .. 
               rot.Pitch .. "," .. rot.Yaw .. "," .. rot.Roll
    end
    
    -- Если это сложная структура с userdata, используем codec
    if type(data) == "table" then
        local encoded = codec.encodeTable(data)
        -- Преобразуем в JSON-подобную строку или используем стандартный encode если есть
        local json = require("lib.json.json")
        return json.encode(encoded)
    end
    
    -- Простые типы
    return tostring(data)
end

-- Десериализация данных с поддержкой userdata
function serializer.deserialize(data, context)
    if not data then return nil end
    
    -- Проверяем старый формат (pos,rot)
    if string.find(data, "|") and string.find(data, ",") then
        local posPart, rotPart = string.match(data, "([^|]+)|([^|]+)")
        if posPart and rotPart then
            local x,y,z = string.match(posPart, "([^,]+),([^,]+),([^,]+)")
            local p,ya,r = string.match(rotPart, "([^,]+),([^,]+),([^,]+)")
            
            if x and y and z and p and ya and r then
                return {
                    pos = {X = tonumber(x), Y = tonumber(y), Z = tonumber(z)},
                    rot = {Pitch = tonumber(p), Yaw = tonumber(ya), Roll = tonumber(r)}
                }
            end
        end
    end
    
    -- Пытаемся декодировать как JSON с userdata
    local json = require("lib.json.json")
    local ok, decoded = pcall(function()
        return json.decode(data)
    end)
    
    if ok and decoded and type(decoded) == "table" then
        -- Декодируем userdata обратно
        return codec.decodeTable(decoded, context)
    end
    
    -- Если не удалось, возвращаем как есть
    return data
end

return serializer