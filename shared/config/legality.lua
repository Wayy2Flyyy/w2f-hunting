local Config = DDHunting.Config

Config.Legality = {
    UseLicenses = true,
    UseTags = true,
    UseProtectedSpecies = true,
    UseTimeRestrictions = true,
    UseSeasonRestrictions = true,

    Hours = {
        LegalStart = 5,   -- 05:00
        LegalEnd = 22,    -- 22:00
        NightHuntingAllowed = false,
    },

    Licenses = {
        Basic = {
            Fee = 500,
            DurationDays = 7,
            Species = { 'rabbit', 'deer' },
        },
        Standard = {
            Fee = 2500,
            DurationDays = 14,
            Species = { 'rabbit', 'deer', 'boar', 'coyote' },
        },
        Advanced = {
            Fee = 7500,
            DurationDays = 30,
            Species = { 'rabbit', 'deer', 'boar', 'coyote', 'wolf', 'bear', 'mountain_lion' },
        },
    },

    Tags = {
        deer = 2,
        boar = 2,
        wolf = 1,
        bear = 1,
        mountain_lion = 1,
    },

    ProtectedSpecies = {
        -- example placeholders
        -- ['elk'] = true,
    },

    Fines = {
        NoLicense = 2500,
        NoTag = 1750,
        ProtectedSpecies = 10000,
        IllegalZone = 5000,
        IllegalHours = 1500,
        IllegalBait = 2000,
        BlackMarketSale = 3500,
    },

    Heat = {
        Enabled = true,
        DecayIntervalMinutes = 20,
        DecayAmount = 5,
        Thresholds = {
            Suspicious = 15,
            WantedByRangers = 40,
            MajorOffender = 80,
        }
    },
}
