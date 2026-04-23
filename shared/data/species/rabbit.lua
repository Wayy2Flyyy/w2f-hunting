DDHunting.Data.RegisterSpecies('rabbit', {
    label = 'Rabbit',
    model = `a_c_rabbit_01`,

    category = 'small_game',
    tier = 1,

    habitatZones = {
        'DeerCountry',
        'BoarWoods',
        'NorthernWilds',
    },

    spawn = {
        chanceWeight = 1.45,
        groupMin = 1,
        groupMax = 3,
        hours = {
            startHour = 0,
            endHour = 23,
        },
        preferredWeather = {
            CLEAR = 1.00,
            EXTRASUNNY = 0.95,
            CLOUDS = 1.05,
            OVERCAST = 1.10,
            RAIN = 0.70,
            THUNDER = 0.45,
            FOG = 1.15,
            SMOG = 0.95,
        },
    },

    tracking = {
        difficulty = 2,
        footprintChance = 0.45,
        droppingChance = 0.25,
        bloodTrailDensity = 0.65,
        clueVisibility = 0.70,
        clueLifetimeMultiplier = 0.70,
    },

    senses = {
        sight = 1.15,
        hearing = 1.25,
        smell = 0.90,
    },

    behavior = {
        aggression = 0.0,
        fleeDistance = 120.0,
        curiosity = 0.05,
        patrolRadius = 20.0,
        canCharge = false,
        herdAnimal = false,
        nocturnal = false,
        skittish = true,
    },

    stats = {
        baseHealth = 35,
        speed = 1.35,
        woundEndurance = 0.45,
        stressGain = 1.35,
    },

    harvest = {
        carryClass = 'small',
        canSkin = true,
        canGut = true,
        canQuarter = false,
        meatMin = 1,
        meatMax = 2,
        pelt = true,
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
        weightMin = 1.2,
        weightMax = 3.6,
        maleOnly = false,
    },

    variants = {
        normal = true,
        rare = true,
        albino = true,
        melanistic = false,
    },

    equipment = {
        validWeapons = {
            'weapon_bow',
            'weapon_musket',
            'weapon_sniperrifle',
            'weapon_compactrifle',
        },
        preferredBaits = {
            'bait_deer',
        },
        preferredCalls = {},
    },

    economy = {
        baseValue = 45,
        illegalValueMultiplier = 1.15,
    },

    legalityData = {
        requiredLicense = 'Basic',
        requiresTag = false,
        dailyTagLimit = 0,
    },
})
