local Services = DDHunting.Server.Services

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][animals:event] %s'):format(msg))
    end
end

local function buildPayload()
    local payload = {}
    local all = Services.Wildlife.GetAll()

    for _, record in pairs(all) do
        payload[#payload + 1] = {
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

    return payload
end

RegisterNetEvent('dd-hunting:sv:requestWildlifeSync', function()
    local src = source
    TriggerClientEvent('dd-hunting:cl:syncWildlifeSnapshot', src, buildPayload())
end)

RegisterNetEvent('dd-hunting:sv:requestWildlifeSyncAll', function()
    local src = source
    if src ~= 0 then
        return
    end

    TriggerClientEvent('dd-hunting:cl:syncWildlifeSnapshot', -1, buildPayload())
end)

RegisterNetEvent('dd-hunting:sv:debugRemoveWildlife', function(wildlifeId)
    local src = source
    local wildlife = Services.Wildlife.Get(tonumber(wildlifeId))
    if not wildlife then
        return
    end

    Services.Wildlife.Remove(wildlife.id, 'debug_remove')
    TriggerClientEvent('dd-hunting:cl:syncWildlifeSnapshot', -1, buildPayload())

    debugPrint(('source %s removed wildlife #%s'):format(src, wildlife.id))
end)
