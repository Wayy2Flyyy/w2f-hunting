local Config = DDHunting.Config

Config.Seasons = {
    Enabled = false, -- flip on when season rotation system is ready

    Current = 'default',

    Types = {
        default = {
            DeerMultiplier = 1.00,
            BoarMultiplier = 1.00,
            PredatorMultiplier = 1.00,
        },
        rut = {
            DeerMultiplier = 1.20,
            BoarMultiplier = 0.95,
            PredatorMultiplier = 1.05,
        },
        winter = {
            DeerMultiplier = 0.85,
            BoarMultiplier = 1.10,
            PredatorMultiplier = 1.15,
        },
    }
}
