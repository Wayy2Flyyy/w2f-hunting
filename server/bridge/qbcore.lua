-- QBCore compatibility bridge (secondary target; not mixed into Qbox path)
local Bridge = DDHunting.Server.Bridge

Bridge.QBCore = Bridge.QBCore or {}
local QBCoreBridge = Bridge.QBCore

local QBCore

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][qbcore] %s'):format(msg))
    end
end

local function normalizeAccount(account)
    if account == 'money' then
        return 'cash'
    end

    return account
end

function QBCoreBridge.Init()
    if GetResourceState('qb-core') ~= 'started' then
        error('[dd-hunting] qb-core is not started (Config.Framework.Target = qbcore)')
    end

    QBCore = exports['qb-core']:GetCoreObject()

    if not QBCore then
        error('[dd-hunting] Failed to get QBCore object')
    end

    debugPrint('QBCore bridge initialized')
    return QBCore
end

function QBCoreBridge.Get()
    return QBCore or QBCoreBridge.Init()
end

function QBCoreBridge.GetPlayer(source)
    local framework = QBCoreBridge.Get()
    return framework.Functions.GetPlayer(source)
end

function QBCoreBridge.GetIdentifier(source)
    local player = QBCoreBridge.GetPlayer(source)
    if not player or not player.PlayerData then
        return nil
    end

    return player.PlayerData.citizenid or player.PlayerData.license
end

function QBCoreBridge.GetName(source)
    local player = QBCoreBridge.GetPlayer(source)
    if not player or not player.PlayerData then
        return ('Player %s'):format(source)
    end

    local charinfo = player.PlayerData.charinfo
    if not charinfo then
        return ('Player %s'):format(source)
    end

    local first = charinfo.firstname or ''
    local last = charinfo.lastname or ''
    local fullName = ('%s %s'):format(first, last):gsub('^%s+', ''):gsub('%s+$', '')

    if fullName == '' then
        return ('Player %s'):format(source)
    end

    return fullName
end

function QBCoreBridge.GetJob(source)
    local player = QBCoreBridge.GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.job then
        return nil
    end

    local job = player.PlayerData.job
    local grade = job.grade

    if type(grade) == 'table' then
        grade = grade.level or grade.grade
    end

    return {
        name = job.name,
        label = job.label,
        grade = grade,
        grade_name = type(job.grade) == 'table' and job.grade.name or nil,
        grade_label = type(job.grade) == 'table' and job.grade.label or nil,
        onduty = job.onduty,
    }
end

function QBCoreBridge.AddMoney(source, account, amount, reason)
    local player = QBCoreBridge.GetPlayer(source)
    if not player or not player.Functions or not player.Functions.AddMoney then
        return false, 'player_not_found'
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local moneyType = normalizeAccount(account)
    local success = player.Functions.AddMoney(moneyType, amount, reason or 'dd-hunting')

    if success == false then
        return false, 'add_money_failed'
    end

    return true
end

function QBCoreBridge.RemoveMoney(source, account, amount, reason)
    local player = QBCoreBridge.GetPlayer(source)
    if not player or not player.Functions or not player.Functions.RemoveMoney then
        return false, 'player_not_found'
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local moneyType = normalizeAccount(account)
    local success = player.Functions.RemoveMoney(moneyType, amount, reason or 'dd-hunting')

    if success == false then
        return false, 'insufficient_funds'
    end

    return true
end

function QBCoreBridge.ShowNotification(source, message, notifyType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Hunting',
        description = message,
        type = notifyType or 'inform',
    })
end
