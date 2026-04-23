local Data = DDHunting.Data

Data.Crafting = {
    butcher = {
        trimmed_meat = {
            label = 'Trim Raw Meat',
            feeMultiplier = 1.00,
            timeMs = 3500,
            inputs = {
                { item = 'raw_meat', count = 1 }
            },
            output = {
                item = 'trimmed_meat',
                count = 1,
            }
        },

        premium_cut = {
            label = 'Prepare Premium Cut',
            feeMultiplier = 1.30,
            timeMs = 4500,
            inputs = {
                { item = 'trimmed_meat', count = 1 }
            },
            output = {
                item = 'premium_cut',
                count = 1,
            }
        },

        boxed_game_meat = {
            label = 'Box Premium Meat',
            feeMultiplier = 1.80,
            timeMs = 5500,
            inputs = {
                { item = 'premium_cut', count = 2 }
            },
            output = {
                item = 'boxed_game_meat',
                count = 1,
            }
        },
    },

    tannery = {
        salted_pelt = {
            label = 'Salt Animal Pelt',
            feeMultiplier = 1.10,
            timeMs = 4000,
            inputs = {
                { item = 'animal_pelt', count = 1 }
            },
            output = {
                item = 'salted_pelt',
                count = 1,
            }
        },

        treated_pelt = {
            label = 'Treat Salted Pelt',
            feeMultiplier = 1.45,
            timeMs = 5000,
            inputs = {
                { item = 'salted_pelt', count = 1 }
            },
            output = {
                item = 'treated_pelt',
                count = 1,
            }
        },
    },

    trophy_bench = {
        mounted_trophy = {
            label = 'Mount Trophy',
            feeMultiplier = 1.65,
            timeMs = 6000,
            inputs = {
                { item = 'animal_trophy', count = 1 },
                { item = 'trophy_plaque', count = 1 }
            },
            output = {
                item = 'mounted_trophy',
                count = 1,
            }
        },
    },

    illegal = {
        falsified_tag = {
            label = 'Forge Wildlife Tag',
            feeMultiplier = 2.20,
            timeMs = 5500,
            inputs = {
                { item = 'deer_tag', count = 1 }
            },
            output = {
                item = 'falsified_tag',
                count = 1,
            }
        }
    }
}
