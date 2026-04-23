local Services = DDHunting.Server.Services
local Bridge = DDHunting.Server.Bridge

lib.callback.register('dd-hunting:getBuyerPreview', function(source, buyerKey)
    return Services.Market.GetBuyerPreview(source, buyerKey)
end)

lib.callback.register('dd-hunting:getVendorCatalog', function(source, vendorKey)
    return Services.Market.GetVendorCatalog(source, vendorKey)
end)

RegisterNetEvent('dd-hunting:sv:sellAllToBuyer', function(buyerKey)
    local src = source
    local success, result = Services.Market.SellAllToBuyer(src, buyerKey)

    if not success then
        Bridge.ESX.ShowNotification(src, ('Sale failed: %s'):format(result), 'error')
        return
    end

    Bridge.ESX.ShowNotification(
        src,
        ('Sold %s units to %s for $%s. Rep: %s | Streak: %s'):format(
            result.units,
            result.buyerLabel,
            result.total,
            result.reputation,
            result.saleStreak
        ),
        result.buyerType == 'illegal' and 'warning' or 'success'
    )

    if result.inspection and result.inspection.inspectionTriggered then
        Bridge.ESX.ShowNotification(
            src,
            ('Ranger inspection: seized %s item stacks, fine $%s'):format(#(result.inspection.seized or {}), result.inspection.fine or 0),
            'warning'
        )
    end
end)

RegisterNetEvent('dd-hunting:sv:purchaseFromVendor', function(vendorKey, itemName, quantity)
    local src = source
    local success, result = Services.Market.PurchaseFromVendor(src, vendorKey, itemName, quantity)

    if not success then
        Bridge.ESX.ShowNotification(src, ('Purchase failed: %s'):format(result), 'error')
        return
    end

    Bridge.ESX.ShowNotification(
        src,
        ('Purchased %sx %s for $%s from %s'):format(
            result.quantity,
            result.item,
            result.totalPrice,
            result.vendorLabel
        ),
        'success'
    )
end)
