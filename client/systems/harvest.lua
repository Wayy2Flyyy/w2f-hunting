local Client = DDHunting.Client
local State = Client.State
local WildlifeClient = Client.Systems.Wildlife

Client.Systems.Harvest = Client.Systems.Harvest or {}
local Harvest = Client.Systems.Harvest

local attached = {} -- [carcassId] = entity

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][harvest] %s'):format(msg))
    end
end

local function getWeaponName()
    local weaponHash = GetSelectedPedWeapon(PlayerPedId())
    if not weaponHash or weaponHash == 0 then
        return 'unknown'
    end

    return tostring(weaponHash)
end

local function deleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

local function attachIfNeeded(carcassId, entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return
    end

    if attached[carcassId] == entity then
        return
    end

    if Client.Systems.CarcassTarget and Client.Systems.CarcassTarget.Attach then
        Client.Systems.CarcassTarget.Attach(entity, carcassId)
    end

    attached[carcassId] = entity
end

local function detachIfNeeded(carcassId)
    local entity = attached[carcassId]
    if not entity then
        return
    end

    if Client.Systems.CarcassTarget and Client.Systems.CarcassTarget.Detach then
        Client.Systems.CarcassTarget.Detach(entity)
    end

    attached[carcassId] = nil
end

function Harvest.BeginHarvest(carcass, entity)
    if not carcass or not carcass.id then
        return
    end

    local progressMin = DDHunting.Config.UI
        and DDHunting.Config.UI.Harvest
        and DDHunting.Config.UI.Harvest.ProgressMinMs
        or 4500

    local success = lib.progressBar({
        duration = progressMin,
        label = ('Harvesting %s'):format(carcass.speciesLabel or 'carcass'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true,
            car = true,
        }
    })

    if not success then
        return
    end

    TriggerServerEvent('dd-hunting:sv:harvestCarcass', carcass.id)
end

function Harvest.Refresh()
    local spawned = WildlifeClient and WildlifeClient.GetSpawned and WildlifeClient.GetSpawned() or {}

    for wildlifeId, entry in pairs(spawned) do
        local ped = entry.ped

        if ped and DoesEntityExist(ped) and IsEntityDead(ped) then
            if not entry.deathReported then
                local coords = GetEntityCoords(ped)

                TriggerServerEvent('dd-hunting:sv:reportAnimalDeath', wildlifeId, {
                    coords = {
                        x = coords.x + 0.0,
                        y = coords.y + 0.0,
                        z = coords.z + 0.0,
                    },
                    weapon = getWeaponName(),
                    shotRegion = 'unknown',
                    cleanKill = true,
                    qualityScore = 72,
                })

                entry.deathReported = true
            end

            local carcass = State.GetCarcassByWildlifeId(wildlifeId)
            if carcass then
                attachIfNeeded(carcass.id, ped)
            end
        end
    end

    for carcassId, entity in pairs(attached) do
        local carcass = State.GetCarcass(carcassId)

        if not carcass then
            detachIfNeeded(carcassId)

            if entity and DoesEntityExist(entity) then
                local wildlifeId = WildlifeClient and WildlifeClient.GetWildlifeIdFromPed and WildlifeClient.GetWildlifeIdFromPed(entity)
                deleteEntitySafe(entity)

                if wildlifeId and WildlifeClient and WildlifeClient.RemoveLocalEntity then
                    WildlifeClient.RemoveLocalEntity(wildlifeId)
                end
            end
        end
    end
end

CreateThread(function()
    while true do
        Harvest.Refresh()
        Wait(1000)
    end
end)
