local Config = DDHunting.Config

Config.Main = {
    DebugMode = false,
    DevCommands = true,
    Locale = 'en',

    TickRates = {
        WildlifeThinkMs = 5000,
        PopulationRefreshMs = 60000,
        ClueCleanupMs = 30000,
        WorldEventThinkMs = 120000,
        RangerThinkMs = 15000,
    },

    Limits = {
        MaxActiveAnimalsGlobal = 120,
        MaxAnimalsPerZone = 18,
        MaxActiveCluesGlobal = 500,
        MaxActiveCluesPerPlayer = 40,
        MaxPlacedBaitPerPlayer = 3,
        MaxTrailCamerasPerPlayer = 5,
        MaxCarcassesPerZone = 20,
    },

    Distances = {
        SpawnFromPlayersMin = 180.0,
        DespawnFromPlayersMin = 260.0,
        ClueRenderDistance = 30.0,
        ClueInteractDistance = 2.0,
        CarcassInteractDistance = 2.0,
        AnimalSyncDistance = 180.0,
        GunshotAlertDistance = 220.0,
    },

    Timers = {
        CarcassDecaySeconds = 1800,      -- 30 min
        CarcassDeleteSeconds = 3600,     -- 60 min
        FootprintLifetimeSeconds = 900,  -- 15 min
        DroppingLifetimeSeconds = 1200,  -- 20 min
        BloodLifetimeSeconds = 600,      -- 10 min
        BaitLifetimeSeconds = 1800,      -- 30 min
        TrailCameraBatterySeconds = 7200,
    },

    Features = {
        UseTarget = true,
        UseOxInventory = true,
        UseDynamicMarket = true,
        UseLicenses = true,
        UsePoaching = true,
        UseEvidence = true,
        UsePopulationPressure = true,
        UseLegendaryHunts = true,
        UseLodgeSystem = true,
        UseTrailCameras = true,
        UseSkillTree = true,
    },
}
