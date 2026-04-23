local Server = DDHunting.Server
local State = Server.State

State.StartedAt = os.time()

State.Runtime = {
    booted = false,
    wildlifeTickActive = false,
    lastWildlifeTick = 0,
}

State.World = {
    currentWeather = 'CLEAR',
    currentSeason = (DDHunting.Config.Seasons and DDHunting.Config.Seasons.Current) or 'default',
    marketSeed = math.random(100000, 999999),
}

State.Wildlife = {
    active = {},        -- [entityId] = wildlife data
    byZone = {},        -- [zoneName] = { [entityId] = true }
    bySpecies = {},     -- [speciesKey] = { [entityId] = true }
    pendingDespawn = {},-- [entityId] = true
    nextId = 1,
    total = 0,
}

State.Carcasses = {
    active = {},        -- [carcassId] = carcass metadata
    nextId = 1,
    total = 0,
}

State.Clues = {
    active = {},        -- [clueId] = clue data
    nextId = 1,
    total = 0,
}

State.PlacedBait = {
    active = {},        -- [baitId] = bait instance
    nextId = 1,
    total = 0,
}

State.PlacedCameras = {
    active = {},        -- [cameraId] = trail camera instance
    nextId = 1,
    total = 0,
}

State.Debug = {
    lastSpawnLog = {},
    counters = {
        registeredAnimals = 0,
        removedAnimals = 0,
        deniedSpawns = 0,
    }
}

function State.NextWildlifeId()
    local id = State.Wildlife.nextId
    State.Wildlife.nextId = id + 1
    return id
end

function State.NextCarcassId()
    local id = State.Carcasses.nextId
    State.Carcasses.nextId = id + 1
    return id
end

function State.NextClueId()
    local id = State.Clues.nextId
    State.Clues.nextId = id + 1
    return id
end

function State.NextBaitId()
    local id = State.PlacedBait.nextId
    State.PlacedBait.nextId = id + 1
    return id
end

function State.NextCameraId()
    local id = State.PlacedCameras.nextId
    State.PlacedCameras.nextId = id + 1
    return id
end
