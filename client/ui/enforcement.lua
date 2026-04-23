RegisterCommand('huntrisk', function()
    local data = lib.callback.await('dd-hunting:getEnforcementStatus', false)
    if not data then
        lib.notify({ title = 'Enforcement', description = 'No enforcement data.', type = 'error' })
        return
    end

    lib.notify({
        title = 'Wildlife Crime Status',
        description = ('Heat: %s | Legal Rep: %s | Black Market Rep: %s'):format(
            data.rangerHeat or 0,
            data.legalRep or 0,
            data.blackMarketRep or 0
        ),
        type = (data.rangerHeat or 0) >= 40 and 'warning' or 'inform'
    })
end, false)
