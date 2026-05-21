local Bridge = DDHunting.Server.Bridge

Bridge.Qbox = Bridge.Qbox or {}
local QboxBridge = Bridge.Qbox

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][qbox] %s'):format(msg))
    end
end

local function normalizeAccount(account)
    if account == 'money' then
        return 'cash'
    end

    return account
end

function QboxBridge.Init()
    if GetResourceState('qbx_core') ~= 'started' then
        error('[dd-hunting] qbx_core is not started (Config.Framework.Target = qbox)')
    end

    debugPrint('Qbox bridge initialized')
    return true
end

function QboxBridge.GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

function QboxBridge.GetIdentifier(source)
    local player = QboxBridge.GetPlayer(source)
    if not player or not player.PlayerData then
        return nil
    end

    return player.PlayerData.citizenid or player.PlayerData.license
end

function QboxBridge.GetName(source)
    local player = QboxBridge.GetPlayer(source)
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

function QboxBridge.GetJob(source)
    local player = QboxBridge.GetPlayer(source)
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

function QboxBridge.AddMoney(source, account, amount, reason)
    local player = QboxBridge.GetPlayer(source)
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

function QboxBridge.RemoveMoney(source, account, amount, reason)
    local player = QboxBridge.GetPlayer(source)
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

function QboxBridge.ShowNotification(source, message, notifyType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Hunting',
        description = message,
        type = notifyType or 'inform',
    })
end
