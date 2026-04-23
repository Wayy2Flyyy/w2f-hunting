local Config = DDHunting.Config

Config.Progression = {
    MaxLevel = 50,

    XP = {
        DiscoverTrack = 5,
        IdentifyFreshTrack = 8,
        SpotRareAnimal = 18,
        CleanKill = 40,
        StandardKill = 20,
        PerfectHarvest = 30,
        ContractComplete = 75,
        LegendaryComplete = 300,
    },

    SkillPoints = {
        EveryLevels = 2, -- 1 point every 2 levels
    },

    Branches = {
        tracker = {
            Label = 'Tracker',
            MaxRank = 10,
        },
        marksman = {
            Label = 'Marksman',
            MaxRank = 10,
        },
        butcher = {
            Label = 'Butcher',
            MaxRank = 10,
        },
        survivalist = {
            Label = 'Survivalist',
            MaxRank = 10,
        },
        poacher = {
            Label = 'Poacher',
            MaxRank = 10,
        },
    },

    Unlocks = {
        BinocularsScan = 2,
        BetterTrackReading = 4,
        WeightEstimate = 6,
        TrophyEstimate = 8,
        TrailCameras = 10,
        AdvancedCalls = 14,
        LegendaryContracts = 20,
    },
}
