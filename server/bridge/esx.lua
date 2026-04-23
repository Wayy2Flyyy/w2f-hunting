local Bridge = DDHunting.Server.Bridge

Bridge.ESX = Bridge.ESX or {}
local ESXBridge = Bridge.ESX

local ESX

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][esx] %s'):format(msg))
    end
end

function ESXBridge.Init()
    if ESX then
        return ESX
    end

    if GetResourceState('es_extended') ~= 'started' then
        error('[dd-hunting] es_extended is not started')
    end

    if exports['es_extended'] and exports['es_extended'].getSharedObject then
        ESX = exports['es_extended']:getSharedObject()
    end

    if not ESX then
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
    end

    if not ESX then
        error('[dd-hunting] Failed to get ESX shared object')
    end

    debugPrint('ESX bridge initialized')
    return ESX
end

function ESXBridge.Get()
    return ESX or ESXBridge.Init()
end

function ESXBridge.GetPlayer(source)
    local framework = ESXBridge.Get()
    return framework.GetPlayerFromId(source)
end

function ESXBridge.GetIdentifier(source)
    local xPlayer = ESXBridge.GetPlayer(source)
    if not xPlayer then return nil end

    return xPlayer.identifier or xPlayer.getIdentifier and xPlayer.getIdentifier() or nil
end

function ESXBridge.GetName(source)
    local xPlayer = ESXBridge.GetPlayer(source)
    if not xPlayer then return nil end

    return xPlayer.getName and xPlayer.getName() or xPlayer.name or ('Player %s'):format(source)
end

function ESXBridge.GetJob(source)
    local xPlayer = ESXBridge.GetPlayer(source)
    if not xPlayer then return nil end

    local job = xPlayer.job
    if type(job) ~= 'table' then
        return nil
    end

    return {
        name = job.name,
        label = job.label,
        grade = job.grade,
        grade_name = job.grade_name,
        grade_label = job.grade_label,
    }
end

function ESXBridge.AddMoney(source, account, amount, reason)
    local xPlayer = ESXBridge.GetPlayer(source)
    if not xPlayer then
        return false, 'player_not_found'
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    if account == 'money' or account == 'cash' then
        xPlayer.addMoney(amount, reason or 'dd-hunting')
        return true
    end

    if xPlayer.addAccountMoney then
        xPlayer.addAccountMoney(account, amount, reason or 'dd-hunting')
        return true
    end

    return false, 'unsupported_account'
end

function ESXBridge.RemoveMoney(source, account, amount, reason)
    local xPlayer = ESXBridge.GetPlayer(source)
    if not xPlayer then
        return false, 'player_not_found'
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    if account == 'money' or account == 'cash' then
        local current = xPlayer.getMoney and xPlayer.getMoney() or 0
        if current < amount then
            return false, 'insufficient_funds'
        end

        xPlayer.removeMoney(amount, reason or 'dd-hunting')
        return true
    end

    if xPlayer.getAccount and xPlayer.removeAccountMoney then
        local accountData = xPlayer.getAccount(account)
        if not accountData or (accountData.money or 0) < amount then
            return false, 'insufficient_funds'
        end

        xPlayer.removeAccountMoney(account, amount, reason or 'dd-hunting')
        return true
    end

    return false, 'unsupported_account'
end

function ESXBridge.ShowNotification(source, message, notifyType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Hunting',
        description = message,
        type = notifyType or 'inform'
    })
end
