local tests = {}

function tests.test()
local actor = FindFirstOf("prop_C")
local class = actor:GetClass()

-- Перебираем все функции класса
class:ForEachFunction(function(func)
    if func:GetName() == "K2_SetActorLocationAndRotation" then
        print("Нашли функцию")
        -- Перебираем параметры
        func:ForEachProperty(function(prop)
            print(prop:GetName())
        end)
    end
end)
end



return tests