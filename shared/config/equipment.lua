local Config = DDHunting.Config

Config.Equipment = {
    Weapons = {
        ValidBySpecies = {
            rabbit = { 'weapon_sniperrifle', 'weapon_musket', 'weapon_compactrifle', 'weapon_bow' },
            deer = { 'weapon_sniperrifle', 'weapon_heavyrifle', 'weapon_musket', 'weapon_bow' },
            boar = { 'weapon_sniperrifle', 'weapon_heavyrifle', 'weapon_musket', 'weapon_bow' },
            coyote = { 'weapon_sniperrifle', 'weapon_heavyrifle', 'weapon_musket', 'weapon_bow' },
            wolf = { 'weapon_sniperrifle', 'weapon_heavyrifle', 'weapon_musket' },
            bear = { 'weapon_heavyrifle', 'weapon_sniperrifle' },
            mountain_lion = { 'weapon_heavyrifle', 'weapon_sniperrifle' },
        },

        OverkillWeapons = {
            weapon_rpg = true,
            weapon_grenadelauncher = true,
            weapon_minigun = true,
        }
    },

    Tools = {
        Knives = {
            basic = { item = 'field_knife', speedMultiplier = 1.00, qualityBonus = 0.00 },
            pro = { item = 'field_knife_pro', speedMultiplier = 1.20, qualityBonus = 0.08 },
        },

        Binoculars = {
            basic = { item = 'binoculars_basic', range = 120.0 },
            rangefinder = { item = 'binoculars_rangefinder', range = 220.0 },
        },

        Calls = {
            deer_call = { item = 'deer_call', species = { 'deer' } },
            predator_call = { item = 'predator_call', species = { 'coyote', 'wolf', 'mountain_lion' } },
        },

        Bait = {
            bait_deer = { item = 'bait_deer', species = { 'deer' }, radius = 40.0 },
            bait_predator = { item = 'bait_predator', species = { 'coyote', 'wolf', 'mountain_lion', 'bear' }, radius = 55.0 },
        },

        Utility = {
            scent_blocker = { item = 'scent_blocker', durationSeconds = 600 },
            trail_camera = { item = 'trail_camera' },
            game_cart = { item = 'game_cart' },
        },
    }
}
