local Bridge = DDHunting.Server.Bridge

Bridge.Framework = Bridge.Framework or {}

local FrameworkBridge = Bridge.Framework
local ActiveBridge
local activeTarget

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][framework:%s] %s'):format(activeTarget or 'unknown', msg))
    end
end

local function normalizeTarget(target)
    target = (target or 'qbox'):lower()

    if target == 'qbx' then
        return 'qbox'
    end

    if target == 'qb' or target == 'qb-core' then
        return 'qbcore'
    end

    return target
end

local function resolveTarget()
    local frameworkConfig = DDHunting.Config.Framework or {}
    return normalizeTarget(frameworkConfig.Target or frameworkConfig.Primary or 'qbox')
end

local function selectBridge(target)
    if target == 'qbox' then
        return Bridge.Qbox
    end

    if target == 'qbcore' then
        return Bridge.QBCore
    end

    if target == 'esx' then
        return Bridge.ESX
    end

    error(('[dd-hunting] Unsupported Config.Framework.Target "%s" (expected qbox, qbcore, or esx)'):format(target))
end

function FrameworkBridge.GetTarget()
    return activeTarget or resolveTarget()
end

function FrameworkBridge.Init()
    activeTarget = resolveTarget()
    ActiveBridge = selectBridge(activeTarget)

    if not ActiveBridge or not ActiveBridge.Init then
        error(('[dd-hunting] Framework bridge missing for target "%s"'):format(activeTarget))
    end

    ActiveBridge.Init()
    debugPrint('framework bridge initialized')
    return ActiveBridge
end

function FrameworkBridge.GetActive()
    if not ActiveBridge then
        FrameworkBridge.Init()
    end

    return ActiveBridge
end

function FrameworkBridge.GetPlayer(source)
    return FrameworkBridge.GetActive().GetPlayer(source)
end

function FrameworkBridge.GetIdentifier(source)
    return FrameworkBridge.GetActive().GetIdentifier(source)
end

function FrameworkBridge.GetName(source)
    return FrameworkBridge.GetActive().GetName(source)
end

function FrameworkBridge.GetJob(source)
    return FrameworkBridge.GetActive().GetJob(source)
end

function FrameworkBridge.AddMoney(source, account, amount, reason)
    return FrameworkBridge.GetActive().AddMoney(source, account, amount, reason)
end

function FrameworkBridge.RemoveMoney(source, account, amount, reason)
    return FrameworkBridge.GetActive().RemoveMoney(source, account, amount, reason)
end

function FrameworkBridge.ShowNotification(source, message, notifyType)
    return FrameworkBridge.GetActive().ShowNotification(source, message, notifyType)
end

function FrameworkBridge.RegisterPlayerLoaded(handler)
    local target = FrameworkBridge.GetTarget()

    if target == 'esx' then
        AddEventHandler('esx:playerLoaded', function(playerId)
            handler(tonumber(playerId) or playerId)
        end)
        return
    end

    AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
        local src = type(player) == 'table' and player.PlayerData and player.PlayerData.source or player
        handler(tonumber(src) or src)
    end)

    AddEventHandler('QBCore:Server:OnPlayerLoaded', function(player)
        local src = type(player) == 'table' and player.PlayerData and player.PlayerData.source or player
        handler(tonumber(src) or src)
    end)
end
