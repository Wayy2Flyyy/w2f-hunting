local Client = DDHunting.Client
local State = Client.State

State.Runtime = {
    booted = false,
    syncing = false,
    lastSyncAt = 0,
    syncIntervalMs = 5000,
}

State.Player = {
    serverId = GetPlayerServerId(PlayerId()),
}

State.Wildlife = {
    active = {},      -- [id] = wildlife record
    byZone = {},      -- [zoneName] = { [id] = true }
    bySpecies = {},   -- [speciesKey] = { [id] = true }
    total = 0,
}

State.Debug = {
    lastSyncCount = 0,
    lastSyncDuration = 0,
}

local function clearIndex(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

local function ensureZoneBucket(zoneName)
    if not State.Wildlife.byZone[zoneName] then
        State.Wildlife.byZone[zoneName] = {}
    end

    return State.Wildlife.byZone[zoneName]
end

local function ensureSpeciesBucket(speciesKey)
    if not State.Wildlife.bySpecies[speciesKey] then
        State.Wildlife.bySpecies[speciesKey] = {}
    end

    return State.Wildlife.bySpecies[speciesKey]
end

function State.ClearWildlife()
    clearIndex(State.Wildlife.active)
    clearIndex(State.Wildlife.byZone)
    clearIndex(State.Wildlife.bySpecies)
    State.Wildlife.total = 0
end

function State.UpsertWildlife(record)
    if not record or not record.id then
        return false
    end

    local existing = State.Wildlife.active[record.id]

    if existing and existing.zone ~= record.zone then
        local oldZone = State.Wildlife.byZone[existing.zone]
        if oldZone then
            oldZone[record.id] = nil
        end
    end

    if existing and existing.species ~= record.species then
        local oldSpecies = State.Wildlife.bySpecies[existing.species]
        if oldSpecies then
            oldSpecies[record.id] = nil
        end
    end

    State.Wildlife.active[record.id] = record
    ensureZoneBucket(record.zone)[record.id] = true
    ensureSpeciesBucket(record.species)[record.id] = true

    return true
end

function State.RemoveWildlife(id)
    local existing = State.Wildlife.active[id]
    if not existing then
        return false
    end

    local zoneBucket = State.Wildlife.byZone[existing.zone]
    if zoneBucket then
        zoneBucket[id] = nil
    end

    local speciesBucket = State.Wildlife.bySpecies[existing.species]
    if speciesBucket then
        speciesBucket[id] = nil
    end

    State.Wildlife.active[id] = nil
    State.Wildlife.total = math.max(0, State.Wildlife.total - 1)

    return true
end

function State.SetWildlife(records)
    State.ClearWildlife()

    for i = 1, #(records or {}) do
        State.UpsertWildlife(records[i])
    end

    local count = 0
    for _ in pairs(State.Wildlife.active) do
        count += 1
    end

    State.Wildlife.total = count
    State.Debug.lastSyncCount = count
end

function State.GetWildlife(id)
    return State.Wildlife.active[id]
end

function State.GetWildlifeAll()
    return State.Wildlife.active
end

function State.CountWildlife()
    return State.Wildlife.total or 0
end

function State.CountWildlifeByZone(zoneName)
    local bucket = State.Wildlife.byZone[zoneName]
    if not bucket then
        return 0
    end

    local count = 0
    for _ in pairs(bucket) do
        count += 1
    end

    return count
end

function State.CountWildlifeBySpecies(speciesKey)
    local bucket = State.Wildlife.bySpecies[speciesKey]
    if not bucket then
        return 0
    end

    local count = 0
    for _ in pairs(bucket) do
        count += 1
    end

    return count
end
