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
    active = {},
    byZone = {},
    bySpecies = {},
    pendingDespawn = {},
    nextId = 1,
    total = 0,
}

State.Carcasses = {
    active = {},
    nextId = 1,
    total = 0,
}

State.Clues = {
    active = {},
    nextId = 1,
    total = 0,
}

State.PlacedBait = {
    active = {},
    nextId = 1,
    total = 0,
}

State.PlacedCameras = {
    active = {},
    nextId = 1,
    total = 0,
}

State.MarketPlayers = {
    byIdentifier = {},
}

State.ProgressionPlayers = {
    byIdentifier = {},
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
