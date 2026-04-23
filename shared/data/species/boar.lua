DDHunting.Data.RegisterSpecies('boar', {
    label = 'Boar',
    model = `a_c_boar`,

    category = 'medium_game',
    tier = 3,

    habitatZones = {
        'BoarWoods',
        'NorthernWilds',
    },

    spawn = {
        chanceWeight = 0.95,
        groupMin = 1,
        groupMax = 3,
        hours = {
            startHour = 18,
            endHour = 7,
        },
        preferredWeather = {
            CLEAR = 0.95,
            EXTRASUNNY = 0.85,
            CLOUDS = 1.05,
            OVERCAST = 1.10,
            RAIN = 1.12,
            THUNDER = 0.72,
            FOG = 1.08,
            SMOG = 0.98,
        },
    },

    tracking = {
        difficulty = 5,
        footprintChance = 0.88,
        droppingChance = 0.68,
        bloodTrailDensity = 1.10,
        clueVisibility = 0.95,
        clueLifetimeMultiplier = 1.10,
    },

    senses = {
        sight = 0.95,
        hearing = 1.05,
        smell = 1.30,
    },

    behavior = {
        aggression = 0.35,
        fleeDistance = 110.0,
        curiosity = 0.12,
        patrolRadius = 35.0,
        canCharge = true,
        herdAnimal = true,
        nocturnal = true,
        skittish = false,
    },

    stats = {
        baseHealth = 145,
        speed = 1.00,
        woundEndurance = 1.20,
        stressGain = 0.90,
    },

    harvest = {
        carryClass = 'medium',
        canSkin = true,
        canGut = true,
        canQuarter = true,
        meatMin = 4,
        meatMax = 7,
        pelt = false,
        antlers = false,
        tusk = true,
        fang = false,
        claw = false,
        trophy = true,
    },

    trophy = {
        enabled = true,
        scoreMin = 80,
        scoreMax = 175,
        weightMin = 80.0,
        weightMax = 210.0,
        maleOnly = false,
    },

    variants = {
        normal = true,
        rare = true,
        albino = false,
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
            'bait_predator',
        },
        preferredCalls = {},
    },

    economy = {
        baseValue = 240,
        illegalValueMultiplier = 1.35,
    },

    legalityData = {
        requiredLicense = 'Standard',
        requiresTag = true,
        dailyTagLimit = 2,
    },
})
