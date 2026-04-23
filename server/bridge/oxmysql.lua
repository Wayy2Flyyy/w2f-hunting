local Bridge = DDHunting.Server.Bridge

Bridge.Database = Bridge.Database or {}
local DB = Bridge.Database

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][db] %s'):format(msg))
    end
end

function DB.Init()
    if GetResourceState('oxmysql') ~= 'started' then
        error('[dd-hunting] oxmysql is not started')
    end

    debugPrint('oxmysql bridge initialized')
    return true
end

function DB.Scalar(query, params)
    return MySQL.scalar.await(query, params or {})
end

function DB.Single(query, params)
    return MySQL.single.await(query, params or {})
end

function DB.Query(query, params)
    return MySQL.query.await(query, params or {})
end

function DB.Insert(query, params)
    return MySQL.insert.await(query, params or {})
end

function DB.Update(query, params)
    return MySQL.update.await(query, params or {})
end

function DB.Transaction(statements)
    return MySQL.transaction.await(statements)
end

function DB.Ready(callback)
    MySQL.ready(callback)
end
