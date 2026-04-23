local Client = DDHunting.Client
local State = Client.State

Client.Systems.Wildlife = Client.Systems.Wildlife or {}
local WildlifeClient = Client.Systems.Wildlife

local spawned = {}          -- [wildlifeId] = { ped, model, targetAdded, lastSeenAt }
local streaming = false

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][wildlife:client] %s'):format(msg))
    end
end

local function getRenderDistance()
    return DDHunting.Config.Main
        and DDHunting.Config.Main.Distances
        and DDHunting.Config.Main.Distances.AnimalSyncDistance
        or 180.0
end

local function getPlayerCoords()
    return GetEntityCoords(PlayerPedId())
end

local function ensureModelLoaded(model)
    if not IsModelInCdimage(model) then
        return false
    end

    if not HasModelLoaded(model) then
        RequestModel(model)

        local timeout = GetGameTimer() + 5000
        while not HasModelLoaded(model) do
            Wait(0)

            if GetGameTimer() > timeout then
                return false
            end
        end
    end

    return true
end

local function safeDeleteEntity(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

local function makeAnimalAmbient(ped)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedSeeingRange(ped, 80.0)
    SetPedHearingRange(ped, 80.0)
    SetPedAlertness(ped, 0)
    SetEntityInvincible(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
end

local function spawnLocalAnimal(record)
    if spawned[record.id] then
        return spawned[record.id]
    end

    if not ensureModelLoaded(record.model) then
        debugPrint(('failed to load model for wildlife #%s'):format(record.id))
        return nil
    end

    local ped = CreatePed(28, record.model, record.coords.x, record.coords.y, record.coords.z, record.heading or 0.0, false, false)
    if not ped or ped == 0 then
        debugPrint(('failed to create ped for wildlife #%s'):format(record.id))
        return nil
    end

    makeAnimalAmbient(ped)

    local entry = {
        ped = ped,
        model = record.model,
        wildlifeId = record.id,
        targetAdded = false,
        lastSeenAt = GetGameTimer(),
    }

    Entity(ped).state:set('ddHuntingWildlifeId', record.id, false)
    Entity(ped).state:set('ddHuntingSpecies', record.species, false)

    spawned[record.id] = entry

    if Client.Systems.AnimalTarget and Client.Systems.AnimalTarget.AttachToEntity then
        Client.Systems.AnimalTarget.AttachToEntity(record, ped)
        entry.targetAdded = true
    end

    debugPrint(('spawned local animal #%s [%s]'):format(record.id, record.species))
    return entry
end

local function despawnLocalAnimal(wildlifeId)
    local entry = spawned[wildlifeId]
    if not entry then
        return
    end

    if entry.targetAdded and Client.Systems.AnimalTarget and Client.Systems.AnimalTarget.DetachFromEntity then
        Client.Systems.AnimalTarget.DetachFromEntity(entry.ped)
    end

    safeDeleteEntity(entry.ped)
    spawned[wildlifeId] = nil

    debugPrint(('despawned local animal #%s'):format(wildlifeId))
end

local function shouldRenderRecord(record, playerCoords)
    if not record.alive then
        return false
    end

    local distance = #(playerCoords - record.coords)
    return distance <= getRenderDistance()
end

local function applyAnimalState(record, ped)
    if not DoesEntityExist(ped) then
        return
    end

    SetEntityHeading(ped, record.heading or 0.0)

    if record.state == 'grazing' or record.state == 'idle' then
        TaskWanderStandard(ped, 10.0, 10)
    elseif record.state == 'alert' then
        ClearPedTasks(ped)
        TaskLookAtCoord(ped, record.coords.x, record.coords.y, record.coords.z, 1500, 0, 2)
    elseif record.state == 'fleeing' then
        TaskSmartFleeCoord(ped, record.coords.x, record.coords.y, record.coords.z, 120.0, -1, false, false)
    end
end

function WildlifeClient.GetSpawned()
    return spawned
end

function WildlifeClient.GetPedByWildlifeId(wildlifeId)
    local entry = spawned[wildlifeId]
    return entry and entry.ped or nil
end

function WildlifeClient.GetWildlifeIdFromPed(entity)
    if not entity or entity == 0 then
        return nil
    end

    local stateBag = Entity(entity).state
    return stateBag and stateBag.ddHuntingWildlifeId or nil
end

function WildlifeClient.Refresh()
    local playerCoords = getPlayerCoords()
    local records = State.GetWildlifeAll()

    for wildlifeId, record in pairs(records) do
        if shouldRenderRecord(record, playerCoords) then
            local entry = spawnLocalAnimal(record)
            if entry and DoesEntityExist(entry.ped) then
                entry.lastSeenAt = GetGameTimer()
                applyAnimalState(record, entry.ped)
            end
        else
            despawnLocalAnimal(wildlifeId)
        end
    end

    for wildlifeId in pairs(spawned) do
        if not records[wildlifeId] then
            despawnLocalAnimal(wildlifeId)
        end
    end
end

function WildlifeClient.ClearAll()
    for wildlifeId in pairs(spawned) do
        despawnLocalAnimal(wildlifeId)
    end
end

function WildlifeClient.Start()
    if streaming then
        return
    end

    streaming = true

    CreateThread(function()
        debugPrint('wildlife client streamer started')

        while streaming do
            WildlifeClient.Refresh()
            Wait(1500)
        end
    end)
end

function WildlifeClient.Stop()
    streaming = false
    WildlifeClient.ClearAll()
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    WildlifeClient.ClearAll()
end)
