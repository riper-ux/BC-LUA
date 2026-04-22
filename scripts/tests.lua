local tests = {}

local function getPropUniqueID(prop)
    local ok, keyVal = pcall(function() return prop:GetPropertyValue("key") end)
    if ok and keyVal then
        local ok2, id = pcall(function() return keyVal:ToString() end)
        if ok2 and id and id ~= "None" then
            return id
        end
    end
    return nil
end

function tests.init()
    RegisterKeyBind(75, function()
    local prop = FindFirstOf("prop_sitBench_C")
    if not prop then
        print("prop_sitBench_C not found")
        return
    end
    
    print("Prop: " .. prop:GetFullName())
    print("ID: " .. getPropUniqueID(prop))
    
    -- Вызываем getData с out-параметром
    local outData = {}
    local ok, result = pcall(function() return prop:getData(outData) end)
    
    outData = 

    print("getData returned: " .. tostring(result))
    print("outData type: " .. type(outData))
    
    -- Анализируем outData
    if type(outData) == "table" then
        print("outData fields:\n")
        for k, v in pairs(outData) do
            print("1  [" .. tostring(k) .. "]")
            print("1    Raw: " .. tostring(v) .. "\n")
            print("1    Type: " .. type(v) .. "\n")
            if type(v) == "table" then
                print("outData fields:\n")
                for l, i in pairs(v) do
                    print("2  [" .. tostring(l) .. "]")
                    print("2    Raw: " .. tostring(i) .. "\n")
                    print("2    Type: " .. type(i) .. "\n")
                    if type(i) == "table" then
                        print("outData fields:\n")
                        for a, s in pairs(i) do
                            print("3  [" .. tostring(a) .. "]")
                            print("3    Raw: " .. tostring(s) .. "\n")
                            print("3    Type: " .. type(s) .. "\n")
                        end
                    end
                end
            end
        end
    end
    end)
end

return tests