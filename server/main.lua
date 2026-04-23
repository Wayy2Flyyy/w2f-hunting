local Bridge = DDHunting.Server.Bridge
local Services = DDHunting.Server.Services
local State = DDHunting.Server.State

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][main] %s'):format(msg))
    end
end

CreateThread(function()
    Bridge.ESX.Init()
    Bridge.Inventory.Init()
    Bridge.Database.Init()

    State.Runtime.booted = true

    debugPrint('server foundation boot complete')
end)

lib.callback.register('dd-hunting:getWildlifeSnapshot', function(source)
    return Services.Wildlife.Snapshot()
end)
