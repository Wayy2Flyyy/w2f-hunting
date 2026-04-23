local Bridge = DDHunting.Server.Bridge
local Services = DDHunting.Server.Services
local State = DDHunting.Server.State

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][main] %s'):format(msg))
    end
end

local function sanitizeWildlifeRecord(record)
    return {
        id = record.id,
        species = record.species,
        speciesLabel = record.speciesLabel,
        model = record.model,
        zone = record.zone,
        coords = {
            x = record.coords.x + 0.0,
            y = record.coords.y + 0.0,
            z = record.coords.z + 0.0,
        },
        heading = record.heading,
        sex = record.sex,
        ageClass = record.ageClass,
        variant = record.variant,
        spawnedAt = record.spawnedAt,
        alive = record.alive,
        health = record.health,
        stress = record.stress,
        state = record.state,
        weight = record.weight,
        trophyScore = record.trophyScore,
        flags = record.flags,
    }
end

local function getWildlifeStatePayload()
    local payload = {}
    local all = Services.Wildlife.GetAll()

    for _, record in pairs(all) do
        payload[#payload + 1] = sanitizeWildlifeRecord(record)
    end

    return payload
end

CreateThread(function()
    Bridge.ESX.Init()
    Bridge.Inventory.Init()
    Bridge.Database.Init()

    State.Runtime.booted = true

    Services.Spawn.StartTicking()

    debugPrint('server foundation boot complete')
end)

lib.callback.register('dd-hunting:getWildlifeSnapshot', function(source)
    return Services.Wildlife.Snapshot()
end)

lib.callback.register('dd-hunting:getSpawnDiagnostics', function(source)
    return Services.Spawn.GetDiagnostics()
end)

lib.callback.register('dd-hunting:getWildlifeState', function(source)
    return getWildlifeStatePayload()
end)

lib.callback.register('dd-hunting:getCarcassState', function(source)
    return Services.Carcass.Snapshot()
end)
