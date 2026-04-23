local Data = DDHunting.Data

Data.Crafting = {
    butcher = {
        trimmed_meat = {
            inputs = {
                { item = 'raw_meat', count = 1 }
            },
            output = {
                item = 'trimmed_meat',
                count = 1,
            }
        },

        premium_cut = {
            inputs = {
                { item = 'trimmed_meat', count = 1 }
            },
            output = {
                item = 'premium_cut',
                count = 1,
            }
        },

        boxed_game_meat = {
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
            inputs = {
                { item = 'animal_pelt', count = 1 }
            },
            output = {
                item = 'salted_pelt',
                count = 1,
            }
        },

        treated_pelt = {
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
