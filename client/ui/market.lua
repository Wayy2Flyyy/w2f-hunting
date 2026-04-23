DDHunting.Client.Systems.MarketUI = DDHunting.Client.Systems.MarketUI or {}
local MarketUI = DDHunting.Client.Systems.MarketUI

local function money(value)
    return ('$%s'):format(math.floor(tonumber(value) or 0))
end

function MarketUI.OpenBuyerMenu(buyerKey)
    local preview = lib.callback.await('dd-hunting:getBuyerPreview', false, buyerKey)
    if not preview then
        lib.notify({
            title = 'Market',
            description = 'Failed to load buyer preview.',
            type = 'error'
        })
        return
    end

    local options = {
        {
            title = preview.buyerLabel,
            description = ('Units: %s | Subtotal: %s | Final: %s'):format(
                preview.units,
                money(preview.subtotal),
                money(preview.finalTotal)
            ),
            icon = 'sack-dollar',
            disabled = true,
        },
        {
            title = 'Multipliers',
            description = ('Rep x%.2f | Streak x%.2f | Bulk x%.2f | Buyer x%.2f'):format(
                preview.repMultiplier,
                preview.streakMultiplier,
                preview.bulkMultiplier,
                preview.buyerMultiplier
            ),
            icon = 'chart-line',
            disabled = true,
        }
    }

    if not preview.lines or #preview.lines == 0 then
        options[#options + 1] = {
            title = 'Nothing to sell',
            description = 'You have no valid items for this buyer.',
            icon = 'ban',
            disabled = true,
        }
    else
        options[#options + 1] = {
            title = ('Sell Everything (%s units)'):format(preview.units),
            description = ('Cashout for %s'):format(money(preview.finalTotal)),
            icon = 'cash-register',
            onSelect = function()
                TriggerServerEvent('dd-hunting:sv:sellAllToBuyer', buyerKey)
            end
        }

        for i = 1, math.min(#preview.lines, 10) do
            local line = preview.lines[i]
            options[#options + 1] = {
                title = line.label,
                description = ('x%s • %s'):format(line.count, money(line.totalPrice)),
                icon = 'box-open',
                disabled = true,
            }
        end

        if #preview.lines > 10 then
            options[#options + 1] = {
                title = ('+ %s more items'):format(#preview.lines - 10),
                description = 'Additional sellable inventory not shown.',
                icon = 'ellipsis',
                disabled = true,
            }
        end
    end

    lib.registerContext({
        id = ('dd_hunting_buyer_%s'):format(buyerKey),
        title = preview.buyerLabel,
        options = options
    })

    lib.showContext(('dd_hunting_buyer_%s'):format(buyerKey))
end

function MarketUI.OpenVendorMenu(vendorKey)
    local catalog = lib.callback.await('dd-hunting:getVendorCatalog', false, vendorKey)
    if not catalog then
        lib.notify({
            title = 'Market',
            description = 'Failed to load vendor catalog.',
            type = 'error'
        })
        return
    end

    local options = {}

    for i = 1, #catalog.catalog do
        local entry = catalog.catalog[i]
        options[#options + 1] = {
            title = entry.label,
            description = ('%s | Max %s'):format(money(entry.price), entry.maxQuantity),
            icon = 'cart-shopping',
            onSelect = function()
                local quantity = 1

                if entry.stack and entry.maxQuantity > 1 then
                    local input = lib.inputDialog(entry.label, {
                        {
                            type = 'number',
                            label = 'Quantity',
                            default = 1,
                            min = 1,
                            max = entry.maxQuantity,
                            required = true,
                        }
                    })

                    if not input or not input[1] then
                        return
                    end

                    quantity = tonumber(input[1]) or 1
                end

                TriggerServerEvent('dd-hunting:sv:purchaseFromVendor', vendorKey, entry.item, quantity)
            end
        }
    end

    lib.registerContext({
        id = ('dd_hunting_vendor_%s'):format(vendorKey),
        title = catalog.vendorLabel,
        options = options
    })

    lib.showContext(('dd_hunting_vendor_%s'):format(vendorKey))
end
