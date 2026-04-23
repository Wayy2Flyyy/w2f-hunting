local Services = DDHunting.Server.Services
local Bridge = DDHunting.Server.Bridge

lib.callback.register('dd-hunting:getBenchCatalog', function(source, benchKey)
    return Services.Processing.GetBenchCatalog(source, benchKey)
end)

RegisterNetEvent('dd-hunting:sv:processRecipe', function(benchKey, recipeKey, craftCount)
    local src = source
    local success, result = Services.Processing.ProcessRecipe(src, benchKey, recipeKey, craftCount)

    if not success then
        Bridge.ESX.ShowNotification(src, ('Processing failed: %s'):format(result), 'error')
        return
    end

    Bridge.ESX.ShowNotification(
        src,
        ('Processed %sx %s at %s for $%s'):format(
            result.outputCount,
            result.outputItem,
            result.benchLabel,
            result.fee
        ),
        'success'
    )
end)
