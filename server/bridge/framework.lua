--- Config-driven framework facade. Services must call Bridge.Framework, not qbx/qb/esx directly.

local Bridge = DDHunting.Server.Bridge

Bridge.Framework = Bridge.Framework or {}
local FW = Bridge.Framework

local impl

local function targetKey()
    return (DDHunting.Config.Framework.Target or 'qbox'):lower():gsub('%s+', '')
end

local function resolveImpl(key)
    if key == 'qbox' then
        return Bridge.Qbox
    end
    if key == 'qbcore' then
        return Bridge.QBCore
    end
    if key == 'esx' then
        return Bridge.ESX
    end
    return nil
end

function FW.GetTarget()
    return targetKey()
end

function FW.Init()
    local key = targetKey()
    impl = resolveImpl(key)
    if not impl then
        error(('[dd-hunting] Invalid Config.Framework.Target %q (use qbox, qbcore, or esx)'):format(key))
    end
    impl.Init()
end

function FW.GetPlayer(source)
    return impl.GetPlayer(source)
end

function FW.GetIdentifier(source)
    return impl.GetIdentifier(source)
end

function FW.GetName(source)
    return impl.GetName(source)
end

function FW.GetJob(source)
    return impl.GetJob(source)
end

function FW.AddMoney(source, account, amount, reason)
    return impl.AddMoney(source, account, amount, reason)
end

function FW.RemoveMoney(source, account, amount, reason)
    return impl.RemoveMoney(source, account, amount, reason)
end

function FW.ShowNotification(source, message, notifyType)
    return impl.ShowNotification(source, message, notifyType)
end
