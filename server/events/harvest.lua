local Services = DDHunting.Server.Services
local Bridge = DDHunting.Server.Bridge

local function buildWildlifePayload()
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

local function pushSyncToAll()
    TriggerClientEvent('dd-hunting:cl:syncWildlifeSnapshot', -1, buildWildlifePayload())
    TriggerClientEvent('dd-hunting:cl:syncCarcassSnapshot', -1, Services.Carcass.Snapshot())
end

local function joinReasons(reasons)
    if type(reasons) ~= 'table' or #reasons == 0 then
        return 'none'
    end

    return table.concat(reasons, ', ')
end

RegisterNetEvent('dd-hunting:sv:reportAnimalDeath', function(wildlifeId, payload)
    local src = source
    wildlifeId = tonumber(wildlifeId)

    if not wildlifeId then
        return
    end

    local wildlife = Services.Wildlife.Get(wildlifeId)
    if not wildlife then
        return
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return
    end

    local playerCoords = GetEntityCoords(ped)
    local dist = #(playerCoords - wildlife.coords)

    if dist > 250.0 then
        return
    end

    local carcass = Services.Carcass.GetByWildlifeId(wildlifeId)
    if carcass then
        return
    end

    Services.Carcass.CreateFromWildlife(wildlife, {
        killerServerId = src,
        coords = payload and payload.coords or wildlife.coords,
        weapon = payload and payload.weapon or 'unknown',
        shotRegion = payload and payload.shotRegion or 'unknown',
        cleanKill = payload and payload.cleanKill == true,
        dragDamage = payload and payload.dragDamage or 0,
        vehicleDamage = payload and payload.vehicleDamage or 0,
        freshness = 100,
    })

    Services.Wildlife.Remove(wildlifeId, 'reported_dead')
    pushSyncToAll()
end)

RegisterNetEvent('dd-hunting:sv:harvestCarcass', function(carcassId)
    local src = source
    carcassId = tonumber(carcassId)

    if not carcassId then
        return
    end

    local success, result = Services.Carcass.Harvest(src, carcassId)

    if not success then
        Bridge.ESX.ShowNotification(src, ('Harvest failed: %s'):format(result), 'error')
        return
    end

    if result.legality and result.legality.legal then
        Bridge.ESX.ShowNotification(src, 'Carcass harvested legally.', 'success')
    else
        Bridge.ESX.ShowNotification(
            src,
            ('Carcass harvested as contraband. Reasons: %s'):format(joinReasons(result.legality and result.legality.reasons or {})),
            'warning'
        )
    end

    pushSyncToAll()
end)
