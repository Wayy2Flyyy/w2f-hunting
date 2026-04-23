local Config = DDHunting.Config

Config.Loot = {
    QualityThresholds = {
        pristine = 90,
        good = 75,
        standard = 55,
        poor = 30,
        ruined = 0,
    },

    FreshnessThresholds = {
        fresh = 85,
        decent = 65,
        aging = 35,
        spoiled = 0,
    },

    SpeciesParts = {
        rabbit = {
            meat = { min = 1, max = 2 },
            pelt = true,
            trophy = false,
        },
        deer = {
            meat = { min = 3, max = 6 },
            pelt = true,
            antlers = true,
            trophy = true,
        },
        boar = {
            meat = { min = 4, max = 7 },
            pelt = false,
            tusk = true,
            trophy = true,
        },
        coyote = {
            meat = { min = 2, max = 4 },
            pelt = true,
            fang = true,
            trophy = true,
        },
        wolf = {
            meat = { min = 3, max = 5 },
            pelt = true,
            fang = true,
            trophy = true,
        },
        bear = {
            meat = { min = 6, max = 10 },
            pelt = true,
            claw = true,
            trophy = true,
        },
        mountain_lion = {
            meat = { min = 4, max = 6 },
            pelt = true,
            fang = true,
            trophy = true,
        },
    },

    RareVariants = {
        BaseChance = 0.01, -- 1%
        AlbinoChance = 0.0025,
        MelanisticChance = 0.0015,
    }
}
