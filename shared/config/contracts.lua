local Config = DDHunting.Config

Config.Contracts = {
    MaxActivePerPlayer = 3,
    RefreshIntervalMinutes = 45,

    Types = {
        standard = {
            payoutMultiplier = 1.00,
            xpReward = 50,
        },
        premium = {
            payoutMultiplier = 1.35,
            xpReward = 85,
        },
        legendary = {
            payoutMultiplier = 2.50,
            xpReward = 200,
        },
    },

    Requirements = {
        MinFreshness = 60,
        AllowIllegalForLegalBoard = false,
    }
}
