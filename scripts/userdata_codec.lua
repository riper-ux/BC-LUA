-- userdata_codec.lua
-- Модуль для кодирования/декодирования Unreal userdata в строку и обратно
-- Поддерживает типы: LocalUnrealParam, FNameUserdata, UClass, и другие UE4SS userdata

local codec = {}

-- Таблица для хранения типов userdata
local userdataTypes = {
    bool = "bool",
    int = "int",
    float = "float",
    string = "string",
    name = "name",
    vector = "vector",
    rotator = "rotator",
    transform = "transform",
    class = "class",
    object = "object",
    bytearray = "bytearray"
}

-- Вспомогательная функция для определения типа userdata
local function getUserdataType(ud)
    if type(ud) ~= "userdata" then
        return nil
    end
    
    -- Пытаемся определить тип через tostring
    local udStr = tostring(ud)
    
    if string.find(udStr, "LocalUnrealParam") then
        return "LocalUnrealParam"
    elseif string.find(udStr, "FNameUserdata") then
        return "FNameUserdata"
    elseif string.find(udStr, "UClass") then
        return "UClass"
    elseif string.find(udStr, "UObject") then
        return "UObject"
    elseif string.find(udStr, "FString") then
        return "FString"
    elseif string.find(udStr, "FVector") then
        return "FVector"
    elseif string.find(udStr, "FRotator") then
        return "FRotator"
    elseif string.find(udStr, "FTransform") then
        return "FTransform"
    elseif string.find(udStr, "FGuid") then
        return "FGuid"
    elseif string.find(udStr, " TArray") then
        return "TArray"
    else
        return "unknown"
    end
end

-- Декодирование userdata в строку
-- Возвращает: строка_данных, тип_данных
function codec.encode(ud)
    if ud == nil then
        return "nil", "nil"
    end
    
    if type(ud) ~= "userdata" then
        -- Если не userdata, возвращаем как есть
        return tostring(ud), type(ud)
    end
    
    local udType = getUserdataType(ud)
    
    if not udType then
        return tostring(ud), "unknown"
    end
    
    -- Обработка в зависимости от типа
    if udType == "LocalUnrealParam" then
        -- Попытка получить значение через разные методы
        local ok, value = pcall(function()
            -- Пробуем получить как boolean
            if ud:IsValid() ~= nil then
                return ud:GetValue()
            end
            return ud
        end)
        
        if ok and value ~= ud then
            -- Если удалось получить значение, рекурсивно кодируем
            return codec.encode(value)
        end
        
        -- Если не удалось, пробуем определить тип по контексту или возвращаем адрес
        return tostring(ud), "LocalUnrealParam:" .. tostring(ud)
        
    elseif udType == "FNameUserdata" then
        -- FName можно конвертировать в строку через ToString
        local ok, str = pcall(function()
            return ud:ToString()
        end)
        if ok and str then
            return str, "FName"
        end
        return tostring(ud), "FNameUserdata"
        
    elseif udType == "UClass" then
        -- Получаем имя класса
        local ok, fullName = pcall(function()
            return ud:GetFullName()
        end)
        if ok and fullName then
            return fullName, "UClass"
        end
        local ok, path = pcall(function()
            return ud:GetPathName()
        end)
        if ok and path then
            return path, "UClass"
        end
        return tostring(ud), "UClass"
        
    elseif udType == "UObject" then
        local ok, fullName = pcall(function()
            return ud:GetFullName()
        end)
        if ok and fullName then
            return fullName, "UObject"
        end
        return tostring(ud), "UObject"
        
    elseif udType == "FString" then
        local ok, str = pcall(function()
            return ud:ToString()
        end)
        if ok and str then
            return str, "FString"
        end
        return tostring(ud), "FString"
        
    elseif udType == "FVector" then
        local ok, vec = pcall(function()
            return string.format("%.6f,%.6f,%.6f", ud.X, ud.Y, ud.Z)
        end)
        if ok then
            return vec, "FVector"
        end
        return tostring(ud), "FVector"
        
    elseif udType == "FRotator" then
        local ok, rot = pcall(function()
            return string.format("%.6f,%.6f,%.6f", ud.Pitch, ud.Yaw, ud.Roll)
        end)
        if ok then
            return rot, "FRotator"
        end
        return tostring(ud), "FRotator"
        
    elseif udType == "FTransform" then
        -- Transform содержит Rotation, Translation, Scale3D
        local ok, trans = pcall(function()
            local r = ud.Rotation or {X=0, Y=0, Z=0, W=1}
            local t = ud.Translation or {X=0, Y=0, Z=0}
            local s = ud.Scale3D or {X=1, Y=1, Z=1}
            return string.format("R:%.6f,%.6f,%.6f,%.6f|T:%.6f,%.6f,%.6f|S:%.6f,%.6f,%.6f",
                r.X, r.Y, r.Z, r.W,
                t.X, t.Y, t.Z,
                s.X, s.Y, s.Z)
        end)
        if ok then
            return trans, "FTransform"
        end
        return tostring(ud), "FTransform"
        
    elseif udType == "FGuid" then
        local ok, guid = pcall(function()
            return string.format("%08x-%04x-%04x-%04x-%012x",
                ud.A, ud.B, ud.C, ud.D)
        end)
        if ok then
            return guid, "FGuid"
        end
        return tostring(ud), "FGuid"
        
    elseif udType == "TArray" then
        return tostring(ud), "TArray"
    end
    
    -- По умолчанию возвращаем представление userdata
    return tostring(ud), udType
end

-- Декодирование строки обратно в userdata
-- Требует контекст (Actor или World) для создания объектов
-- encodedData: строка данных
-- targetType: целевой тип userdata
-- context: контекст для создания (Actor, World, Class и т.д.)
function codec.decode(encodedData, targetType, context)
    if encodedData == "nil" or targetType == "nil" then
        return nil
    end
    
    if not targetType or targetType == "number" or targetType == "boolean" then
        -- Простые типы
        if targetType == "number" then
            return tonumber(encodedData)
        elseif targetType == "boolean" then
            return encodedData == "true"
        end
        return encodedData
    end
    
    -- Обработка в зависимости от типа
    if targetType == "FName" then
        -- Создаем FName из строки
        if context and context.MakeFName then
            return context:MakeFName(encodedData)
        end
        -- Глобальная функция UE4SS
        if FName then
            return FName(encodedData)
        end
        return encodedData
        
    elseif targetType == "UClass" then
        -- Находим класс по пути
        if StaticFindObject then
            return StaticFindObject(encodedData)
        end
        if FindObject then
            return FindObject(nil, nil, encodedData, false)
        end
        return encodedData
        
    elseif targetType == "UObject" then
        -- Находим объект по имени
        if FindFirstOf then
            -- Пытаемся извлечь класс из fullName
            local className = string.match(encodedData, "Class ([%w_]+)")
            if className then
                local actors = FindFirstOf(className)
                return actors
            end
        end
        return encodedData
        
    elseif targetType == "FString" then
        -- Возвращаем как строку
        return encodedData
        
    elseif targetType == "FVector" then
        -- Парсим "X,Y,Z"
        local x, y, z = string.match(encodedData, "([^,]+),([^,]+),([^,]+)")
        if x and y and z then
            return {X = tonumber(x), Y = tonumber(y), Z = tonumber(z)}
        end
        return encodedData
        
    elseif targetType == "FRotator" then
        -- Парсим "Pitch,Yaw,Roll"
        local pitch, yaw, roll = string.match(encodedData, "([^,]+),([^,]+),([^,]+)")
        if pitch and yaw and roll then
            return {Pitch = tonumber(pitch), Yaw = tonumber(yaw), Roll = tonumber(roll)}
        end
        return encodedData
        
    elseif targetType == "FTransform" then
        -- Парсим "R:x,y,z,w|T:x,y,z|S:x,y,z"
        local rotPart, transPart, scalePart = string.match(encodedData, "R:([^|]+)|T:([^|]+)|S:(.+)")
        if rotPart and transPart and scalePart then
            local rx, ry, rz, rw = string.match(rotPart, "([^,]+),([^,]+),([^,]+),([^,]+)")
            local tx, ty, tz = string.match(transPart, "([^,]+),([^,]+),([^,]+)")
            local sx, sy, sz = string.match(scalePart, "([^,]+),([^,]+),([^,]+)")
            
            if rx and tx and sx then
                return {
                    Rotation = {X = tonumber(rx), Y = tonumber(ry), Z = tonumber(rz), W = tonumber(rw)},
                    Translation = {X = tonumber(tx), Y = tonumber(ty), Z = tonumber(tz)},
                    Scale3D = {X = tonumber(sx), Y = tonumber(sy), Z = tonumber(sz)}
                }
            end
        end
        return encodedData
        
    elseif targetType == "FGuid" then
        -- Парсим GUID формат
        local a, b, c, d = string.match(encodedData, "([%x]+)-([%x]+)-([%x]+)-([%x]+)-([%x]+)")
        if a then
            return {A = tonumber(a, 16), B = tonumber(b, 16), C = tonumber(c, 16), D = tonumber(d, 16)}
        end
        return encodedData
    end
    
    -- Для LocalUnrealParam и других сложных типов нужна дополнительная информация
    if string.find(targetType, "LocalUnrealParam:") then
        -- Это прокси, нужно знать оригинальный тип
        -- Возвращаем как есть для обработки в другом месте
        return encodedData
    end
    
    return encodedData
end

-- Рекурсивное кодирование всей таблицы данных
function codec.encodeTable(data, depth)
    depth = depth or 0
    local maxDepth = 10  -- Защита от бесконечной рекурсии
    
    if depth > maxDepth then
        return data
    end
    
    if type(data) ~= "table" then
        local encoded, etype = codec.encode(data)
        return {value = encoded, type = etype}
    end
    
    local result = {}
    for key, value in pairs(data) do
        if type(value) == "userdata" then
            local encoded, etype = codec.encode(value)
            result[key] = {value = encoded, type = etype}
        elseif type(value) == "table" then
            result[key] = codec.encodeTable(value, depth + 1)
        else
            result[key] = {value = value, type = type(value)}
        end
    end
    return result
end

-- Рекурсивное декодирование таблицы данных
function codec.decodeTable(encodedTable, context)
    if type(encodedTable) ~= "table" then
        return encodedTable
    end
    
    local result = {}
    for key, valueData in pairs(encodedTable) do
        if type(valueData) == "table" and valueData.value and valueData.type then
            result[key] = codec.decode(valueData.value, valueData.type, context)
        elseif type(valueData) == "table" then
            result[key] = codec.decodeTable(valueData, context)
        else
            result[key] = valueData
        end
    end
    return result
end

return codec
