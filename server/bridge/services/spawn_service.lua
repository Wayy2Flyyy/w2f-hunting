local Server = DDHunting.Server
local State = Server.State
local Services = Server.Services

local WildlifeService = Services.Wildlife
local SpawnService = {}

Services.Spawn = SpawnService

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][spawn] %s'):format(msg))
    end
end

local function randomFloat(minValue, maxValue)
    return minValue + (math.random() * (maxValue - minValue))
end

local function getZoneConfig(zoneName)
    local zones = DDHunting.Config.Zones and DDHunting.Config.Zones.Habitats
    if not zones then return nil end
    return zones[zoneName]
end

local function getAllHabitatZones()
    local zones = DDHunting.Config.Zones and DDHunting.Config.Zones.Habitats
    return zones or {}
end

local function getCurrentHour()
    return tonumber(os.date('%H')) or 12
end

local function getCurrentWeather()
    return State.World.currentWeather or 'CLEAR'
end

local function getSpecies(speciesKey)
    return DDHunting.Data.GetSpecies and DDHunting.Data.GetSpecies(speciesKey) or nil
end

local function getMinSpawnDistance()
    return DDHunting.Config.Main
        and DDHunting.Config.Main.Distances
        and DDHunting.Config.Main.Distances.SpawnFromPlayersMin
        or 180.0
end

local function getMaxSpawnDistance()
    return DDHunting.Config.Main
        and DDHunting.Config.Main.Distances
        and DDHunting.Config.Main.Distances.DespawnFromPlayersMin
        or 260.0
end

local function isPlayerNearCoords(coords, minDistance)
    local players = GetPlayers()
    minDistance = minDistance or getMinSpawnDistance()

    for i = 1, #players do
        local src = tonumber(players[i])
        if src then
            local ped = GetPlayerPed(src)
            if ped and ped > 0 then
                local pedCoords = GetEntityCoords(ped)
                local dist = #(pedCoords - coords)

                if dist < minDistance then
                    return true, src, dist
                end
            end
        end
    end

    return false
end

local function isPointInsideRestrictedZone(coords)
    local restricted = DDHunting.Config.Zones and DDHunting.Config.Zones.Restricted
    if not restricted then
        return false
    end

    for zoneName, zone in pairs(restricted) do
        local center = zone.center
        local radius = zone.radius or 0.0

        if center and radius > 0.0 then
            local dist = #(coords - center)
            if dist <= radius then
                return true, zoneName, zone
            end
        end
    end

    return false
end

local function randomPointInZone(zone)
    local angle = randomFloat(0.0, math.pi * 2.0)
    local distance = math.sqrt(math.random()) * (zone.radius or 0.0)

    local x = zone.center.x + math.cos(angle) * distance
    local y = zone.center.y + math.sin(angle) * distance
    local z = zone.center.z

    return vec3(x, y, z)
end

local function resolveGroundZ(coords)
    local found, groundZ = GetGroundZFor_3dCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 150.0, false)
    if found then
        return vec3(coords.x + 0.0, coords.y + 0.0, groundZ + 0.0)
    end

    return coords
end

local function chooseWeightedSpecies(zoneName)
    local speciesKeys = DDHunting.Data.GetSpeciesForZone and DDHunting.Data.GetSpeciesForZone(zoneName) or {}
    if #speciesKeys == 0 then
        return nil, 'no_species_for_zone'
    end

    local totalWeight = 0.0
    local currentHour = getCurrentHour()
    local weather = getCurrentWeather()

    local weighted = {}

    for i = 1, #speciesKeys do
        local speciesKey = speciesKeys[i]
        local species = getSpecies(speciesKey)

        if species and species.spawn and species.spawn.enabled ~= false then
            local allowedHour = DDHunting.Data.CanSpeciesSpawnAtHour(speciesKey, currentHour)
            local weatherMult = DDHunting.Data.GetSpeciesWeatherMultiplier(speciesKey, weather) or 1.0

            if allowedHour and weatherMult > 0.0 then
                local weight = (species.spawn.chanceWeight or 1.0) * weatherMult

                if weight > 0.0 then
                    totalWeight = totalWeight + weight
                    weighted[#weighted + 1] = {
                        speciesKey = speciesKey,
                        weight = weight,
                    }
                end
            end
        end
    end

    if totalWeight <= 0.0 then
        return nil, 'no_weighted_species_available'
    end

    local roll = randomFloat(0.0, totalWeight)
    local running = 0.0

    for i = 1, #weighted do
        running = running + weighted[i].weight
        if roll <= running then
            return weighted[i].speciesKey
        end
    end

    return weighted[#weighted].speciesKey
end

local function pickSex()
    return math.random(1, 100) <= 50 and 'male' or 'female'
end

local function pickAgeClass()
    local roll = math.random(1, 100)

    if roll <= 10 then
        return 'juvenile'
    elseif roll <= 55 then
        return 'adult'
    elseif roll <= 90 then
        return 'mature'
    end

    return 'old'
end

local function pickVariant(species)
    local variants = species.variants or {}
    local rareConfig = DDHunting.Config.Loot and DDHunting.Config.Loot.RareVariants or {}

    if variants.albino and math.random() <= (rareConfig.AlbinoChance or 0.0025) then
        return 'albino'
    end

    if variants.melanistic and math.random() <= (rareConfig.MelanisticChance or 0.0015) then
        return 'melanistic'
    end

    if variants.rare and math.random() <= (rareConfig.BaseChance or 0.01) then
        return 'rare'
    end

    return 'normal'
end

local function rollWeight(species, sex, ageClass)
    local trophy = species.trophy or {}
    local minWeight = trophy.weightMin or 10.0
    local maxWeight = trophy.weightMax or 20.0

    local value = randomFloat(minWeight, maxWeight)

    if sex == 'male' then
        value = value * 1.05
    end

    if ageClass == 'juvenile' then
        value = value * 0.55
    elseif ageClass == 'mature' then
        value = value * 1.10
    elseif ageClass == 'old' then
        value = value * 0.95
    end

    return math.floor((value * 100) + 0.5) / 100
end

local function rollTrophyScore(species, sex, ageClass)
    local trophy = species.trophy or {}

    if trophy.enabled ~= true then
        return 0.0
    end

    if trophy.maleOnly and sex ~= 'male' then
        return 0.0
    end

    local value = randomFloat(trophy.scoreMin or 0, trophy.scoreMax or 0)

    if ageClass == 'juvenile' then
        value = value * 0.50
    elseif ageClass == 'adult' then
        value = value * 0.85
    elseif ageClass == 'mature' then
        value = value * 1.10
    elseif ageClass == 'old' then
        value = value * 0.92
    end

    return math.floor((value * 100) + 0.5) / 100
end

function SpawnService.CanZoneSpawn(zoneName)
    local zone = getZoneConfig(zoneName)
    if not zone then
        return false, 'invalid_zone'
    end

    local limits = DDHunting.Config.Main and DDHunting.Config.Main.Limits or {}
    local maxZone = limits.MaxAnimalsPerZone or 18

    if WildlifeService.CountByZone(zoneName) >= maxZone then
        return false, 'zone_cap_reached'
    end

    return true
end

function SpawnService.CanSpeciesSpawnInZone(speciesKey, zoneName)
    local species = getSpecies(speciesKey)
    if not species then
        return false, 'invalid_species'
    end

    local foundZone = false
    for i = 1, #(species.habitatZones or {}) do
        if species.habitatZones[i] == zoneName then
            foundZone = true
            break
        end
    end

    if not foundZone then
        return false, 'species_not_in_zone'
    end

    if not DDHunting.Data.CanSpeciesSpawnAtHour(speciesKey, getCurrentHour()) then
        return false, 'hour_restricted'
    end

    local weatherMult = DDHunting.Data.GetSpeciesWeatherMultiplier(speciesKey, getCurrentWeather()) or 1.0
    if weatherMult <= 0.0 then
        return false, 'weather_restricted'
    end

    return true
end

function SpawnService.FindSpawnPoint(zoneName, speciesKey, attempts)
    local zone = getZoneConfig(zoneName)
    if not zone then
        return nil, 'invalid_zone'
    end

    attempts = attempts or 12

    for _ = 1, attempts do
        local rawCoords = randomPointInZone(zone)
        local coords = resolveGroundZ(rawCoords)

        local blocked, restrictedName = isPointInsideRestrictedZone(coords)
        if not blocked then
            local nearPlayer = isPlayerNearCoords(coords, getMinSpawnDistance())
            if not nearPlayer then
                return coords
            end
        else
            debugPrint(('spawn point blocked by restricted zone: %s'):format(restrictedName))
        end
    end

    return nil, 'no_valid_spawn_point'
end

function SpawnService.RollGroupSize(speciesKey)
    local species = getSpecies(speciesKey)
    if not species then
        return 0
    end

    local minCount = species.spawn.groupMin or 1
    local maxCount = species.spawn.groupMax or minCount

    if maxCount < minCount then
        maxCount = minCount
    end

    return math.random(minCount, maxCount)
end

function SpawnService.BuildSpawnExtra(speciesKey)
    local species = getSpecies(speciesKey)
    if not species then
        return nil
    end

    local sex = pickSex()
    local ageClass = pickAgeClass()

    return {
        sex = sex,
        ageClass = ageClass,
        variant = pickVariant(species),
        state = species.behavior and (species.behavior.herdAnimal and 'grazing' or 'idle') or 'idle',
        health = species.stats and species.stats.baseHealth or 100,
        stress = 0,
        weight = rollWeight(species, sex, ageClass),
        trophyScore = rollTrophyScore(species, sex, ageClass),
        heading = randomFloat(0.0, 359.0),
        source = 'spawn_service',
    }
end

function SpawnService.SpawnOne(zoneName, speciesKey)
    local zoneAllowed, zoneReason = SpawnService.CanZoneSpawn(zoneName)
    if not zoneAllowed then
        return nil, zoneReason
    end

    local speciesAllowed, speciesReason = SpawnService.CanSpeciesSpawnInZone(speciesKey, zoneName)
    if not speciesAllowed then
        return nil, speciesReason
    end

    local coords, pointReason = SpawnService.FindSpawnPoint(zoneName, speciesKey)
    if not coords then
        return nil, pointReason
    end

    local extra = SpawnService.BuildSpawnExtra(speciesKey)
    local record, registerReason = WildlifeService.Register(speciesKey, zoneName, coords, extra)

    if not record then
        return nil, registerReason
    end

    return record
end

function SpawnService.SpawnBatch(zoneName, speciesKey, count)
    local spawned = {}
    local failures = {}

    count = math.max(1, math.floor(tonumber(count) or 1))

    for _ = 1, count do
        local record, reason = SpawnService.SpawnOne(zoneName, speciesKey)
        if record then
            spawned[#spawned + 1] = record
        else
            failures[#failures + 1] = reason or 'unknown'
        end
    end

    return spawned, failures
end

function SpawnService.AutoPopulateZone(zoneName)
    local zoneAllowed, zoneReason = SpawnService.CanZoneSpawn(zoneName)
    if not zoneAllowed then
        return {}, { zoneReason }
    end

    local speciesKey, speciesReason = chooseWeightedSpecies(zoneName)
    if not speciesKey then
        return {}, { speciesReason }
    end

    local groupSize = SpawnService.RollGroupSize(speciesKey)
    return SpawnService.SpawnBatch(zoneName, speciesKey, groupSize)
end

function SpawnService.AutoPopulateAllZones()
    local results = {}
    local zones = getAllHabitatZones()

    for zoneName in pairs(zones) do
        local spawned, failures = SpawnService.AutoPopulateZone(zoneName)

        results[zoneName] = {
            spawned = spawned,
            failures = failures,
        }
    end

    return results
end

function SpawnService.RunTick()
    local tickMs = GetGameTimer()
    State.Runtime.lastWildlifeTick = tickMs

    local zones = getAllHabitatZones()
    local limits = DDHunting.Config.Main and DDHunting.Config.Main.Limits or {}
    local perZoneCap = limits.MaxAnimalsPerZone or 18

    for zoneName in pairs(zones) do
        local currentCount = WildlifeService.CountByZone(zoneName)

        if currentCount < perZoneCap then
            local spawned, failures = SpawnService.AutoPopulateZone(zoneName)

            if #spawned > 0 then
                debugPrint(('tick spawned %s wildlife in %s'):format(#spawned, zoneName))
            elseif failures[1] and DDHunting.Config.Main.DebugMode then
                debugPrint(('tick skipped zone %s (%s)'):format(zoneName, failures[1]))
            end
        end
    end
end

function SpawnService.StartTicking()
    if State.Runtime.wildlifeTickActive then
        return
    end

    State.Runtime.wildlifeTickActive = true

    local interval = DDHunting.Config.Main
        and DDHunting.Config.Main.TickRates
        and DDHunting.Config.Main.TickRates.WildlifeThinkMs
        or 5000

    CreateThread(function()
        debugPrint(('wildlife tick started (%sms)'):format(interval))

        while State.Runtime.wildlifeTickActive do
            SpawnService.RunTick()
            Wait(interval)
        end
    end)
end

function SpawnService.StopTicking()
    State.Runtime.wildlifeTickActive = false
    debugPrint('wildlife tick stopped')
end

function SpawnService.SetWeather(weatherName)
    if type(weatherName) ~= 'string' or weatherName == '' then
        return false, 'invalid_weather'
    end

    State.World.currentWeather = weatherName
    return true
end

function SpawnService.GetDiagnostics()
    local zones = {}
    local habitatZones = getAllHabitatZones()

    for zoneName in pairs(habitatZones) do
        zones[zoneName] = {
            count = WildlifeService.CountByZone(zoneName),
            species = DDHunting.Data.GetSpeciesForZone(zoneName),
        }
    end

    return {
        currentHour = getCurrentHour(),
        currentWeather = getCurrentWeather(),
        totalWildlife = WildlifeService.CountAll(),
        zones = zones,
    }
end
