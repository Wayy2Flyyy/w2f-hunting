--- QBCore (qb-core) — secondary compatibility bridge. Do not use directly from services; use Bridge.Framework.

local Bridge = DDHunting.Server.Bridge

Bridge.QBCore = Bridge.QBCore or {}
local QBCoreBridge = Bridge.QBCore

local QBCore

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][qbcore] %s'):format(msg))
    end
end

local function resolveMoneyType(account)
    local a = type(account) == 'string' and account:lower() or 'cash'
    if a == 'money' or a == 'cash' then
        return 'cash'
    end
    if a == 'bank' then
        return 'bank'
    end
    if a == 'black_money' or a == 'dirty' or a == 'markedbills' then
        return 'crypto'
    end
    if a == 'crypto' then
        return 'crypto'
    end
    return 'cash'
end

function QBCoreBridge.Init()
    if GetResourceState('qb-core') ~= 'started' then
        error('[dd-hunting] Config.Framework.Target is "qbcore" but qb-core is not started')
    end
    QBCore = exports['qb-core']:GetCoreObject()
    debugPrint('qb-core bridge initialized')
    return QBCore
end

function QBCoreBridge.GetCore()
    return QBCore or QBCoreBridge.Init()
end

function QBCoreBridge.GetPlayer(source)
    return QBCoreBridge.GetCore().Functions.GetPlayer(source)
end

function QBCoreBridge.GetIdentifier(source)
    local player = QBCoreBridge.GetPlayer(source)
    if not player or not player.PlayerData then
        return nil
    end
    return player.PlayerData.citizenid
end

function QBCoreBridge.GetName(source)
    local player = QBCoreBridge.GetPlayer(source)
    if not player or not player.PlayerData then
        return nil
    end
    local pd = player.PlayerData
    local info = pd.charinfo
    if type(info) == 'table' then
        local first = info.firstname or ''
        local last = info.lastname or ''
        local full = (('%s %s'):format(first, last)):gsub('^%s+', ''):gsub('%s+$', '')
        if full ~= '' then
            return full
        end
    end
    return pd.name or ('Player %s'):format(source)
end

function QBCoreBridge.GetJob(source)
    local player = QBCoreBridge.GetPlayer(source)
    if not player or not player.PlayerData then
        return nil
    end
    local job = player.PlayerData.job
    if type(job) ~= 'table' then
        return nil
    end

    local grade = job.grade
    if type(grade) == 'table' then
        return {
            name = job.name,
            label = job.label,
            grade = grade.level or grade.grade,
            grade_name = grade.name,
            grade_label = grade.name,
        }
    end

    return {
        name = job.name,
        label = job.label,
        grade = tonumber(grade) or 0,
        grade_name = job.grade_name,
        grade_label = job.grade_label,
    }
end

function QBCoreBridge.AddMoney(source, account, amount, reason)
    local player = QBCoreBridge.GetPlayer(source)
    if not player then
        return false, 'player_not_found'
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local moneyType = resolveMoneyType(account)
    if player.Functions.AddMoney then
        player.Functions.AddMoney(moneyType, amount, reason or 'dd-hunting')
        return true
    end

    return false, 'unsupported_account'
end

function QBCoreBridge.RemoveMoney(source, account, amount, reason)
    local player = QBCoreBridge.GetPlayer(source)
    if not player then
        return false, 'player_not_found'
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local moneyType = resolveMoneyType(account)
    if not player.Functions.RemoveMoney then
        return false, 'unsupported_account'
    end

    local ok = player.Functions.RemoveMoney(moneyType, amount, reason or 'dd-hunting')
    if ok == false then
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
