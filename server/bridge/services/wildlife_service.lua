local Server = DDHunting.Server
local State = Server.State
local WildlifeService = {}

Server.Services.Wildlife = WildlifeService

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][wildlife] %s'):format(msg))
    end
end

local function now()
    return os.time()
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

local function removeFromBuckets(entityId, wildlife)
    if not wildlife then return end

    local zoneBucket = State.Wildlife.byZone[wildlife.zone]
    if zoneBucket then
        zoneBucket[entityId] = nil
    end

    local speciesBucket = State.Wildlife.bySpecies[wildlife.species]
    if speciesBucket then
        speciesBucket[entityId] = nil
    end
end

function WildlifeService.CountAll()
    return State.Wildlife.total or 0
end

function WildlifeService.CountByZone(zoneName)
    local bucket = State.Wildlife.byZone[zoneName]
    local count = 0

    if not bucket then
        return 0
    end

    for _ in pairs(bucket) do
        count += 1
    end

    return count
end

function WildlifeService.CountBySpecies(speciesKey)
    local bucket = State.Wildlife.bySpecies[speciesKey]
    local count = 0

    if not bucket then
        return 0
    end

    for _ in pairs(bucket) do
        count += 1
    end

    return count
end

function WildlifeService.Get(entityId)
    return State.Wildlife.active[entityId]
end

function WildlifeService.GetAll()
    return State.Wildlife.active
end

function WildlifeService.Exists(entityId)
    return State.Wildlife.active[entityId] ~= nil
end

function WildlifeService.BuildRecord(speciesKey, zoneName, coords, extra)
    local species = DDHunting.Data.GetSpecies(speciesKey)
    if not species then
        return nil, 'invalid_species'
    end

    local x, y, z = coords.x + 0.0, coords.y + 0.0, coords.z + 0.0

    local record = {
        id = State.NextWildlifeId(),
        species = speciesKey,
        speciesLabel = species.label,
        model = species.model,

        zone = zoneName,
        coords = vec3(x, y, z),
        heading = extra and extra.heading or 0.0,

        sex = extra and extra.sex or 'unknown',
        ageClass = extra and extra.ageClass or 'adult',
        variant = extra and extra.variant or 'normal',

        spawnedAt = now(),
        lastSeenAt = now(),
        lastThinkAt = 0,

        alive = true,
        health = extra and extra.health or species.stats.baseHealth,
        stress = extra and extra.stress or 0,
        state = extra and extra.state or 'idle',
        networkId = extra and extra.networkId or nil,
        entityNetId = extra and extra.entityNetId or nil,

        source = extra and extra.source or 'system',
        qualitySeed = extra and extra.qualitySeed or math.random(1, 1000000),
        weight = extra and extra.weight or 0.0,
        trophyScore = extra and extra.trophyScore or 0.0,

        flags = {
            despawnRequested = false,
            harvested = false,
            legendary = species.legendary == true,
            protected = species.protected == true,
        }
    }

    return record
end

function WildlifeService.CanRegister(speciesKey, zoneName)
    local limits = DDHunting.Config.Main and DDHunting.Config.Main.Limits or {}
    local maxGlobal = limits.MaxActiveAnimalsGlobal or 120
    local maxZone = limits.MaxAnimalsPerZone or 18

    if WildlifeService.CountAll() >= maxGlobal then
        State.Debug.counters.deniedSpawns += 1
        return false, 'global_cap_reached'
    end

    if WildlifeService.CountByZone(zoneName) >= maxZone then
        State.Debug.counters.deniedSpawns += 1
        return false, 'zone_cap_reached'
    end

    if not DDHunting.Data.GetSpecies(speciesKey) then
        return false, 'invalid_species'
    end

    return true
end

function WildlifeService.Register(speciesKey, zoneName, coords, extra)
    local allowed, reason = WildlifeService.CanRegister(speciesKey, zoneName)
    if not allowed then
        return nil, reason
    end

    local record, buildReason = WildlifeService.BuildRecord(speciesKey, zoneName, coords, extra)
    if not record then
        return nil, buildReason
    end

    State.Wildlife.active[record.id] = record
    ensureZoneBucket(zoneName)[record.id] = true
    ensureSpeciesBucket(speciesKey)[record.id] = true
    State.Wildlife.total += 1
    State.Debug.counters.registeredAnimals += 1

    debugPrint(('registered wildlife #%s [%s] in zone %s'):format(record.id, speciesKey, zoneName))
    return record
end

function WildlifeService.Update(entityId, patch)
    local wildlife = WildlifeService.Get(entityId)
    if not wildlife then
        return false, 'not_found'
    end

    patch = patch or {}

    if patch.zone and patch.zone ~= wildlife.zone then
        local oldZone = wildlife.zone
        wildlife.zone = patch.zone

        local oldBucket = State.Wildlife.byZone[oldZone]
        if oldBucket then
            oldBucket[entityId] = nil
        end

        ensureZoneBucket(wildlife.zone)[entityId] = true
    end

    if patch.coords then
        wildlife.coords = vec3(patch.coords.x + 0.0, patch.coords.y + 0.0, patch.coords.z + 0.0)
    end

    if patch.heading ~= nil then wildlife.heading = patch.heading end
    if patch.health ~= nil then wildlife.health = patch.health end
    if patch.stress ~= nil then wildlife.stress = patch.stress end
    if patch.state ~= nil then wildlife.state = patch.state end
    if patch.alive ~= nil then wildlife.alive = patch.alive end
    if patch.networkId ~= nil then wildlife.networkId = patch.networkId end
    if patch.entityNetId ~= nil then wildlife.entityNetId = patch.entityNetId end
    if patch.lastSeenAt ~= nil then wildlife.lastSeenAt = patch.lastSeenAt end
    if patch.lastThinkAt ~= nil then wildlife.lastThinkAt = patch.lastThinkAt end
    if patch.weight ~= nil then wildlife.weight = patch.weight end
    if patch.trophyScore ~= nil then wildlife.trophyScore = patch.trophyScore end

    return true, wildlife
end

function WildlifeService.MarkForDespawn(entityId)
    local wildlife = WildlifeService.Get(entityId)
    if not wildlife then
        return false, 'not_found'
    end

    wildlife.flags.despawnRequested = true
    State.Wildlife.pendingDespawn[entityId] = true

    return true
end

function WildlifeService.Remove(entityId, reason)
    local wildlife = WildlifeService.Get(entityId)
    if not wildlife then
        return false, 'not_found'
    end

    removeFromBuckets(entityId, wildlife)

    State.Wildlife.active[entityId] = nil
    State.Wildlife.pendingDespawn[entityId] = nil
    State.Wildlife.total = math.max(0, State.Wildlife.total - 1)
    State.Debug.counters.removedAnimals += 1

    debugPrint(('removed wildlife #%s (%s)'):format(entityId, reason or 'no_reason'))
    return true
end

function WildlifeService.FindNearest(zoneName, coords, radius, speciesFilter)
    local bucket = State.Wildlife.byZone[zoneName]
    if not bucket then
        return nil
    end

    local bestRecord, bestDist
    radius = radius or 50.0

    for entityId in pairs(bucket) do
        local wildlife = State.Wildlife.active[entityId]
        if wildlife and wildlife.alive then
            if not speciesFilter or wildlife.species == speciesFilter then
                local dist = #(wildlife.coords - coords)
                if dist <= radius and (not bestDist or dist < bestDist) then
                    bestDist = dist
                    bestRecord = wildlife
                end
            end
        end
    end

    return bestRecord, bestDist
end

function WildlifeService.ListZone(zoneName)
    local result = {}
    local bucket = State.Wildlife.byZone[zoneName]

    if not bucket then
        return result
    end

    for entityId in pairs(bucket) do
        local wildlife = State.Wildlife.active[entityId]
        if wildlife then
            result[#result + 1] = wildlife
        end
    end

    return result
end

function WildlifeService.Snapshot()
    local zones = {}
    for zoneName, bucket in pairs(State.Wildlife.byZone) do
        local count = 0
        for _ in pairs(bucket) do
            count += 1
        end
        zones[zoneName] = count
    end

    return {
        total = WildlifeService.CountAll(),
        byZone = zones,
        counters = State.Debug.counters,
        startedAt = State.StartedAt,
    }
end
