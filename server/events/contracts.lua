local Services = DDHunting.Server.Services
local Bridge = DDHunting.Server.Bridge

lib.callback.register('dd-hunting:getContractBoard', function(source, boardKey)
    return Services.Contracts.GetBoardOffers(source, boardKey)
end)

lib.callback.register('dd-hunting:getActiveContracts', function(source)
    return Services.Contracts.GetActiveContracts(source)
end)

RegisterNetEvent('dd-hunting:sv:acceptContract', function(boardKey, contractId)
    local src = source
    local ok, result = Services.Contracts.Accept(src, boardKey, contractId)
    if not ok then
        Bridge.ESX.ShowNotification(src, ('Accept failed: %s'):format(result), 'error')
        return
    end

    Bridge.ESX.ShowNotification(src, ('Contract accepted: %s (%s)'):format(result.label, result.id), 'success')
end)

RegisterNetEvent('dd-hunting:sv:abandonContract', function(contractId)
    local src = source
    local ok, err = Services.Contracts.Abandon(src, contractId)
    if not ok then
        Bridge.ESX.ShowNotification(src, ('Abandon failed: %s'):format(err), 'error')
        return
    end

    Bridge.ESX.ShowNotification(src, 'Contract abandoned.', 'warning')
end)

RegisterNetEvent('dd-hunting:sv:turnInContract', function(contractId)
    local src = source
    local ok, reward = Services.Contracts.TurnIn(src, contractId)
    if not ok then
        Bridge.ESX.ShowNotification(src, ('Turn-in failed: %s'):format(reward), 'error')
        return
    end

    Bridge.ESX.ShowNotification(src, ('Contract complete! +$%s, +%s XP'):format(reward.payout, reward.xp), 'success')

    if reward.inspection and reward.inspection.inspectionTriggered then
        Bridge.ESX.ShowNotification(src, ('Ranger inspection triggered. Fine: $%s | Seized: %s'):format(
            reward.inspection.fine or 0,
            #(reward.inspection.seized or {})
        ), 'warning')
    end
end)

RegisterNetEvent('dd-hunting:sv:refreshContractBoard', function(boardKey)
    local src = source
    local ok, err = Services.Contracts.TryRefreshBoard(src, boardKey)
    if not ok then
        Bridge.ESX.ShowNotification(src, ('Refresh failed: %s'):format(err), 'error')
        return
    end

    Bridge.ESX.ShowNotification(src, 'Contract board refreshed.', 'success')
end)
