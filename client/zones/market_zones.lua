local MarketUI = DDHunting.Client.Systems.MarketUI

CreateThread(function()
    local market = DDHunting.Config.Market or {}

    for buyerKey, buyer in pairs(market.Buyers or {}) do
        exports.ox_target:addSphereZone({
            coords = buyer.coords,
            radius = buyer.radius or 1.5,
            debug = false,
            options = {
                {
                    name = ('dd_hunting_buyer_%s'):format(buyerKey),
                    icon = buyer.icon or 'fa-solid fa-coins',
                    label = ('Open %s'):format(buyer.label),
                    onSelect = function()
                        MarketUI.OpenBuyerMenu(buyerKey)
                    end,
                }
            }
        })
    end

    for vendorKey, vendor in pairs(market.Vendors or {}) do
        exports.ox_target:addSphereZone({
            coords = vendor.coords,
            radius = vendor.radius or 1.5,
            debug = false,
            options = {
                {
                    name = ('dd_hunting_vendor_%s'):format(vendorKey),
                    icon = vendor.icon or 'fa-solid fa-store',
                    label = ('Browse %s'):format(vendor.label),
                    onSelect = function()
                        MarketUI.OpenVendorMenu(vendorKey)
                    end,
                }
            }
        })
    end
end)
