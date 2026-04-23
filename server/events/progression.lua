local Services = DDHunting.Server.Services
local Bridge = DDHunting.Server.Bridge

lib.callback.register('dd-hunting:getProgressionState', function(source)
    return Services.Progression.GetSummary(source)
end)

lib.callback.register('dd-hunting:getMasterySummary', function(source)
    local payload = Services.Progression.GetSummary(source)
    return payload and payload.mastery or {}
end)

RegisterNetEvent('dd-hunting:sv:requestProgressionSync', function()
    Services.Progression.Sync(source)
end)

RegisterNetEvent('dd-hunting:sv:spendSkillPoint', function(branchKey)
    local src = source
    local success, result = Services.Progression.SpendSkillPoint(src, branchKey)

    if not success then
        Bridge.ESX.ShowNotification(src, ('Skill upgrade failed: %s'):format(result), 'error')
        return
    end

    Bridge.ESX.ShowNotification(src, ('Upgraded %s to rank %s'):format(branchKey, result[branchKey] or 0), 'success')
end)
