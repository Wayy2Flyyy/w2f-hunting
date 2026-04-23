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
    active = {},
    byZone = {},
    bySpecies = {},
    total = 0,
}

State.Carcasses = {
    active = {},
    byWildlifeId = {},
    total = 0,
}

State.Debug = {
    lastSyncCount = 0,
    lastCarcassSyncCount = 0,
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

function State.ClearCarcasses()
    clearIndex(State.Carcasses.active)
    clearIndex(State.Carcasses.byWildlifeId)
    State.Carcasses.total = 0
end

function State.UpsertCarcass(record)
    if not record or not record.id then
        return false
    end

    State.Carcasses.active[record.id] = record

    if record.sourceWildlifeId then
        State.Carcasses.byWildlifeId[record.sourceWildlifeId] = record.id
    end

    return true
end

function State.SetCarcasses(records)
    State.ClearCarcasses()

    for i = 1, #(records or {}) do
        State.UpsertCarcass(records[i])
    end

    local count = 0
    for _ in pairs(State.Carcasses.active) do
        count += 1
    end

    State.Carcasses.total = count
    State.Debug.lastCarcassSyncCount = count
end

function State.GetCarcass(carcassId)
    return State.Carcasses.active[carcassId]
end

function State.GetCarcassByWildlifeId(wildlifeId)
    local carcassId = State.Carcasses.byWildlifeId[wildlifeId]
    if not carcassId then
        return nil
    end

    return State.Carcasses.active[carcassId]
end

function State.GetAllCarcasses()
    return State.Carcasses.active
end
