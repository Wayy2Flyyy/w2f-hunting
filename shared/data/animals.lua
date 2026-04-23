local Data = DDHunting.Data

Data.Species = Data.Species or {}
Data.SpeciesOrder = Data.SpeciesOrder or {}

local function deepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end

    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = deepCopy(v)
    end

    return copy
end

local function deepMerge(base, extra)
    local result = deepCopy(base)

    for k, v in pairs(extra or {}) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            result[k] = deepMerge(result[k], v)
        else
            result[k] = deepCopy(v)
        end
    end

    return result
end

local SpeciesDefaults = {
    label = 'Unknown Species',
    model = nil,

    category = 'game',
    tier = 1,

    legal = true,
    protected = false,
    legendary = false,

    habitatZones = {},
    spawn = {
        enabled = true,
        chanceWeight = 1.0,
        groupMin = 1,
        groupMax = 1,
        minPlayerDistance = 180.0,
        maxPlayerDistance = 260.0,
        preferredWeather = {
            CLEAR = 1.0,
            EXTRASUNNY = 1.0,
            CLOUDS = 1.0,
            OVERCAST = 1.0,
            RAIN = 1.0,
            THUNDER = 0.8,
            FOG = 1.0,
            SMOG = 1.0,
        },
        hours = {
            startHour = 0,
            endHour = 23,
        },
    },

    tracking = {
        difficulty = 1,
        footprintChance = 1.0,
        droppingChance = 0.5,
        bloodTrailDensity = 1.0,
        clueVisibility = 1.0,
        clueLifetimeMultiplier = 1.0,
    },

    senses = {
        sight = 1.0,
        hearing = 1.0,
        smell = 1.0,
    },

    behavior = {
        aggression = 0.0,
        fleeDistance = 100.0,
        curiosity = 0.0,
        patrolRadius = 35.0,
        canCharge = false,
        herdAnimal = false,
        nocturnal = false,
        skittish = true,
    },

    stats = {
        baseHealth = 100,
        speed = 1.0,
        woundEndurance = 1.0,
        stressGain = 1.0,
    },

    harvest = {
        carryClass = 'small', -- small | medium | large
        canSkin = true,
        canGut = true,
        canQuarter = false,
        meatMin = 1,
        meatMax = 1,
        pelt = false,
        antlers = false,
        tusk = false,
        fang = false,
        claw = false,
        trophy = false,
    },

    trophy = {
        enabled = false,
        scoreMin = 0,
        scoreMax = 0,
        weightMin = 1.0,
        weightMax = 5.0,
        maleOnly = false,
    },

    variants = {
        normal = true,
        rare = false,
        albino = false,
        melanistic = false,
    },

    equipment = {
        validWeapons = {},
        overkillImmune = false,
        preferredBaits = {},
        preferredCalls = {},
    },

    economy = {
        baseValue = 50,
        illegalValueMultiplier = 1.0,
    },

    legalityData = {
        requiredLicense = 'Basic',
        requiresTag = false,
        dailyTagLimit = 0,
    },
}

local RequiredKeys = {
    'label',
    'model',
}

function Data.RegisterSpecies(speciesKey, definition)
    assert(type(speciesKey) == 'string' and speciesKey ~= '', 'RegisterSpecies: speciesKey must be a non-empty string')
    assert(type(definition) == 'table', ('RegisterSpecies: definition missing for species "%s"'):format(speciesKey))

    for _, key in ipairs(RequiredKeys) do
        assert(definition[key] ~= nil, ('RegisterSpecies: "%s" missing required field "%s"'):format(speciesKey, key))
    end

    if Data.Species[speciesKey] then
        error(('RegisterSpecies: species "%s" is already registered'):format(speciesKey))
    end

    local merged = deepMerge(SpeciesDefaults, definition)
    merged.key = speciesKey

    Data.Species[speciesKey] = merged
    Data.SpeciesOrder[#Data.SpeciesOrder + 1] = speciesKey

    if Config and Config.Main and Config.Main.DebugMode then
        print(('[dd-hunting] Registered species: %s'):format(speciesKey))
    end

    return merged
end

function Data.GetSpecies(speciesKey)
    return Data.Species[speciesKey]
end

function Data.GetSpeciesKeys()
    return deepCopy(Data.SpeciesOrder)
end

function Data.GetAllSpecies()
    return Data.Species
end

function Data.GetSpeciesLabel(speciesKey)
    local species = Data.GetSpecies(speciesKey)
    return species and species.label or speciesKey
end

function Data.IsSpeciesLegal(speciesKey)
    local species = Data.GetSpecies(speciesKey)
    return species and species.legal == true or false
end

function Data.IsSpeciesProtected(speciesKey)
    local species = Data.GetSpecies(speciesKey)
    return species and species.protected == true or false
end

function Data.GetSpeciesForZone(zoneName)
    local results = {}

    for _, speciesKey in ipairs(Data.SpeciesOrder) do
        local species = Data.Species[speciesKey]
        for _, habitatZone in ipairs(species.habitatZones or {}) do
            if habitatZone == zoneName then
                results[#results + 1] = speciesKey
                break
            end
        end
    end

    return results
end

function Data.CanSpeciesSpawnAtHour(speciesKey, hour)
    local species = Data.GetSpecies(speciesKey)
    if not species then return false end

    local startHour = species.spawn.hours.startHour
    local endHour = species.spawn.hours.endHour

    if startHour <= endHour then
        return hour >= startHour and hour <= endHour
    end

    return hour >= startHour or hour <= endHour
end

function Data.GetSpeciesWeatherMultiplier(speciesKey, weather)
    local species = Data.GetSpecies(speciesKey)
    if not species then return 0.0 end

    return (species.spawn.preferredWeather and species.spawn.preferredWeather[weather]) or 1.0
end
