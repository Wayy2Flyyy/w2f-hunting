local ProcessingUI = DDHunting.Client.Systems.ProcessingUI

CreateThread(function()
    local benches = DDHunting.Config.Processing and DDHunting.Config.Processing.Benches or {}

    for benchKey, bench in pairs(benches) do
        exports.ox_target:addSphereZone({
            coords = bench.coords,
            radius = bench.radius or 1.5,
            debug = false,
            options = {
                {
                    name = ('dd_hunting_processing_%s'):format(benchKey),
                    icon = bench.icon or 'fa-solid fa-hammer',
                    label = ('Use %s'):format(bench.label),
                    onSelect = function()
                        ProcessingUI.OpenBench(benchKey)
                    end,
                }
            }
        })
    end
end)
