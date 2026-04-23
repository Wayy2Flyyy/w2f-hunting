DDHunting.Client.Systems.ProcessingUI = DDHunting.Client.Systems.ProcessingUI or {}
local ProcessingUI = DDHunting.Client.Systems.ProcessingUI

local function money(value)
    return ('$%s'):format(math.floor(tonumber(value) or 0))
end

local function buildInputsText(inputs)
    local parts = {}

    for i = 1, #(inputs or {}) do
        local input = inputs[i]
        parts[#parts + 1] = ('%sx %s'):format(input.count, input.item)
    end

    return table.concat(parts, ' | ')
end

function ProcessingUI.OpenBench(benchKey)
    local data = lib.callback.await('dd-hunting:getBenchCatalog', false, benchKey)
    if not data then
        lib.notify({
            title = 'Processing',
            description = 'Failed to load bench data.',
            type = 'error'
        })
        return
    end

    local options = {}

    for i = 1, #data.catalog do
        local recipe = data.catalog[i]

        options[#options + 1] = {
            title = recipe.label,
            description = ('Inputs: %s | Fee: %s | Craftable: %s'):format(
                buildInputsText(recipe.inputs),
                money(recipe.fee),
                recipe.maxCraftable
            ),
            icon = 'hammer',
            disabled = recipe.maxCraftable <= 0,
            onSelect = function()
                local quantity = 1

                if recipe.maxCraftable > 1 then
                    local input = lib.inputDialog(recipe.label, {
                        {
                            type = 'number',
                            label = 'Quantity',
                            default = 1,
                            min = 1,
                            max = recipe.maxCraftable,
                            required = true,
                        }
                    })

                    if not input or not input[1] then
                        return
                    end

                    quantity = tonumber(input[1]) or 1
                end

                local completed = lib.progressBar({
                    duration = (recipe.timeMs or 3500) * quantity,
                    label = ('Processing %s'):format(recipe.label),
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        move = true,
                        combat = true,
                        car = true,
                    }
                })

                if not completed then
                    return
                end

                TriggerServerEvent('dd-hunting:sv:processRecipe', benchKey, recipe.key, quantity)
            end
        }
    end

    lib.registerContext({
        id = ('dd_hunting_bench_%s'):format(benchKey),
        title = data.benchLabel,
        options = options
    })

    lib.showContext(('dd_hunting_bench_%s'):format(benchKey))
end
