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

local function syncWildlife()
    if State.Runtime.syncing then
        return
    end

    State.Runtime.syncing = true

    local startedAt = GetGameTimer()
    local records = lib.callback.await('dd-hunting:getWildlifeState', false)

    if type(records) == 'table' then
        local normalized = {}

        for i = 1, #records do
            normalized[i] = normalizeWildlifeRecord(records[i])
        end

        State.SetWildlife(normalized)
        State.Runtime.lastSyncAt = GetGameTimer()
        State.Debug.lastSyncDuration = GetGameTimer() - startedAt

        if WildlifeClient and WildlifeClient.Refresh then
            WildlifeClient.Refresh()
        end

        debugPrint(('wildlife sync complete (%s records in %sms)'):format(#normalized, State.Debug.lastSyncDuration))
    else
        debugPrint('wildlife sync returned no records')
    end

    State.Runtime.syncing = false
end

CreateThread(function()
    Wait(1000)

    State.Runtime.booted = true
    State.Player.serverId = GetPlayerServerId(PlayerId())

    syncWildlife()

    if WildlifeClient and WildlifeClient.Start then
        WildlifeClient.Start()
    end

    debugPrint('client foundation boot complete')
end)

CreateThread(function()
    while true do
        Wait(State.Runtime.syncIntervalMs)
        syncWildlife()
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
    State.Runtime.lastSyncAt = GetGameTimer()

    if WildlifeClient and WildlifeClient.Refresh then
        WildlifeClient.Refresh()
    end

    debugPrint(('event wildlife sync applied (%s records)'):format(#normalized))
end)

RegisterCommand('huntstate', function()
    local total = State.CountWildlife()

    lib.notify({
        title = 'Hunting',
        description = ('Tracked wildlife records: %s'):format(total),
        type = 'inform'
    })
end, false)
