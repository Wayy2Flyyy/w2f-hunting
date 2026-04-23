local Config = DDHunting.Config

Config.Weather = {
    ActivityMultipliers = {
        CLEAR = 1.00,
        EXTRASUNNY = 0.95,
        CLOUDS = 1.05,
        OVERCAST = 1.10,
        RAIN = 0.80,
        THUNDER = 0.60,
        FOG = 1.15,
        SMOG = 0.90,
    },

    Wind = {
        MinChangeSeconds = 180,
        MaxChangeSeconds = 420,
        MinStrength = 0.1,
        MaxStrength = 1.0,
    }
}
