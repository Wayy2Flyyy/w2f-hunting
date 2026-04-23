local State = DDHunting.Client.State
local WildlifeClient = DDHunting.Client.Systems.Wildlife

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][client] %s'):format(msg))
    end
end

local function normalizeVec3(coords)
    if not coords then
        return vec3(0.0, 0.0, 0.0)
    end

    return vec3(
        (coords.x or 0.0) + 0.0,
        (coords.y or 0.0) + 0.0,
        (coords.z or 0.0) + 0.0
    )
end

local function normalizeWildlifeRecord(record)
    record.coords = normalizeVec3(record.coords)
    return record
end

local function normalizeCarcassRecord(record)
    record.coords = normalizeVec3(record.coords)
    return record
end

local function syncAll()
    if State.Runtime.syncing then
        return
    end

    State.Runtime.syncing = true

    local startedAt = GetGameTimer()
    local wildlife = lib.callback.await('dd-hunting:getWildlifeState', false)
    local carcasses = lib.callback.await('dd-hunting:getCarcassState', false)
    local progression = lib.callback.await('dd-hunting:getProgressionState', false)

    if type(wildlife) == 'table' then
        local normalizedWildlife = {}
        for i = 1, #wildlife do
            normalizedWildlife[i] = normalizeWildlifeRecord(wildlife[i])
        end
        State.SetWildlife(normalizedWildlife)
    end

    if type(carcasses) == 'table' then
        local normalizedCarcasses = {}
        for i = 1, #carcasses do
            normalizedCarcasses[i] = normalizeCarcassRecord(carcasses[i])
        end
        State.SetCarcasses(normalizedCarcasses)
    end

    if type(progression) == 'table' then
        State.SetProgression(progression)
    end

    State.Runtime.lastSyncAt = GetGameTimer()
    State.Debug.lastSyncDuration = GetGameTimer() - startedAt

    if WildlifeClient and WildlifeClient.Refresh then
        WildlifeClient.Refresh()
    end

    State.Runtime.syncing = false
end

CreateThread(function()
    Wait(1000)

    State.Runtime.booted = true
    State.Player.serverId = GetPlayerServerId(PlayerId())

    syncAll()

    if WildlifeClient and WildlifeClient.Start then
        WildlifeClient.Start()
    end

    debugPrint('client foundation boot complete')
end)

CreateThread(function()
    while true do
        Wait(State.Runtime.syncIntervalMs)
        syncAll()
    end
end)

RegisterNetEvent('dd-hunting:cl:syncWildlifeSnapshot', function(records)
    if type(records) ~= 'table' then
        return
    end

    local normalized = {}
    for i = 1, #records do
        normalized[i] = normalizeWildlifeRecord(records[i])
    end

    State.SetWildlife(normalized)

    if WildlifeClient and WildlifeClient.Refresh then
        WildlifeClient.Refresh()
    end
end)

RegisterNetEvent('dd-hunting:cl:syncCarcassSnapshot', function(records)
    if type(records) ~= 'table' then
        return
    end

    local normalized = {}
    for i = 1, #records do
        normalized[i] = normalizeCarcassRecord(records[i])
    end

    State.SetCarcasses(normalized)
end)

RegisterCommand('huntstate', function()
    lib.notify({
        title = 'Hunting',
        description = ('Wildlife: %s | Carcasses: %s'):format(State.CountWildlife(), State.Carcasses.total or 0),
        type = 'inform'
    })
end, false)

RegisterNetEvent('dd-hunting:cl:progressionUpdated', function(payload)
    if State.SetProgression(payload) then
        TriggerEvent('dd-hunting:cl:progressionStateUpdated', payload)
    end
end)

RegisterCommand('huntprogress', function()
    local p = State.Progression
    lib.notify({
        title = 'Hunter Progression',
        description = ('Lv.%s | %s | XP %s/%s | SP %s'):format(p.level, p.currentTitle or 'Rookie Hunter', p.xp, p.xpToNext, p.skillPoints),
        type = 'inform'
    })
end, false)
