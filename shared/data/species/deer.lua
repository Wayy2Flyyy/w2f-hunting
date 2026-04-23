DDHunting.Data.RegisterSpecies('deer', {
    label = 'Deer',
    model = `a_c_deer`,

    category = 'medium_game',
    tier = 2,

    habitatZones = {
        'DeerCountry',
        'NorthernWilds',
    },

    spawn = {
        chanceWeight = 1.15,
        groupMin = 1,
        groupMax = 4,
        hours = {
            startHour = 5,
            endHour = 21,
        },
        preferredWeather = {
            CLEAR = 1.00,
            EXTRASUNNY = 0.92,
            CLOUDS = 1.05,
            OVERCAST = 1.12,
            RAIN = 0.82,
            THUNDER = 0.55,
            FOG = 1.18,
            SMOG = 0.95,
        },
    },

    tracking = {
        difficulty = 4,
        footprintChance = 0.95,
        droppingChance = 0.60,
        bloodTrailDensity = 1.00,
        clueVisibility = 1.00,
        clueLifetimeMultiplier = 1.00,
    },

    senses = {
        sight = 1.20,
        hearing = 1.10,
        smell = 1.15,
    },

    behavior = {
        aggression = 0.05,
        fleeDistance = 180.0,
        curiosity = 0.08,
        patrolRadius = 45.0,
        canCharge = false,
        herdAnimal = true,
        nocturnal = false,
        skittish = true,
    },

    stats = {
        baseHealth = 110,
        speed = 1.15,
        woundEndurance = 0.95,
        stressGain = 1.00,
    },

    harvest = {
        carryClass = 'medium',
        canSkin = true,
        canGut = true,
        canQuarter = false,
        meatMin = 3,
        meatMax = 6,
        pelt = true,
        antlers = true,
        tusk = false,
        fang = false,
        claw = false,
        trophy = true,
    },

    trophy = {
        enabled = true,
        scoreMin = 95,
        scoreMax = 210,
        weightMin = 65.0,
        weightMax = 160.0,
        maleOnly = true,
    },

    variants = {
        normal = true,
        rare = true,
        albino = true,
        melanistic = true,
    },

    equipment = {
        validWeapons = {
            'weapon_bow',
            'weapon_musket',
            'weapon_heavyrifle',
            'weapon_sniperrifle',
        },
        preferredBaits = {
            'bait_deer',
        },
        preferredCalls = {
            'deer_call',
        },
    },

    economy = {
        baseValue = 180,
        illegalValueMultiplier = 1.30,
    },

    legalityData = {
        requiredLicense = 'Basic',
        requiresTag = true,
        dailyTagLimit = 2,
    },
})
