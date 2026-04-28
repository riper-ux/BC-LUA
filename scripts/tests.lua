local tests = {}

function tests.init()
    local obj = StaticFindObject("/Game/objects/passwordLock.passwordLock_C")
    if obj then
        -- Вывести все функции
        for k,v in pairs(obj) do
            print(k, type(v))
        end
    end
end



return tests