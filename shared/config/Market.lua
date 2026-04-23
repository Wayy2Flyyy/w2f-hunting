local Config = DDHunting.Config

Config.Market = {
    Grind = {
        StreakWindowMinutes = 45,
        StreakBonusPerSale = 0.015,
        MaxStreakBonus = 0.18,

        ReputationTiers = {
            { reputation = 0, multiplier = 1.00, label = 'Unknown' },
            { reputation = 100, multiplier = 1.03, label = 'Recognized' },
            { reputation = 300, multiplier = 1.08, label = 'Reliable' },
            { reputation = 750, multiplier = 1.15, label = 'Trusted' },
            { reputation = 1500, multiplier = 1.25, label = 'Elite' },
            { reputation = 3000, multiplier = 1.40, label = 'Legend' },
        },

        BulkThresholds = {
            { units = 1, multiplier = 1.00 },
            { units = 5, multiplier = 1.03 },
            { units = 10, multiplier = 1.07 },
            { units = 20, multiplier = 1.14 },
            { units = 35, multiplier = 1.24 },
            { units = 50, multiplier = 1.38 },
        },

        ReputationGain = {
            LegalSale = 2,
            IllegalSale = 4,
            TrophySale = 8,
            BulkBonusAtUnits = 20,
            BulkBonusRep = 6,
        }
    },

    Buyers = {
        butcher = {
            label = 'Butcher',
            type = 'legal',
            coords = vec3(-72.82, 6268.73, 31.49),
            radius = 1.5,
            icon = 'fa-solid fa-drumstick-bite',
            payoutAccount = 'money',
            buyerMultiplier = 0.92,
            acceptedItems = {
                raw_meat = true,
                trimmed_meat = true,
                premium_cut = true,
                boxed_game_meat = true,
            },
            acceptsIllegalGeneric = false,
        },

        trapper = {
            label = 'Trapper',
            type = 'legal',
            coords = vec3(-769.16, 5595.63, 33.49),
            radius = 1.5,
            icon = 'fa-solid fa-feather-pointed',
            payoutAccount = 'money',
            buyerMultiplier = 1.06,
            acceptedItems = {
                animal_pelt = true,
                salted_pelt = true,
                treated_pelt = true,
                animal_part = true,
            },
            acceptsIllegalGeneric = false,
        },

        trophy_collector = {
            label = 'Trophy Collector',
            type = 'legal',
            coords = vec3(-679.41, 5838.56, 17.33),
            radius = 1.5,
            icon = 'fa-solid fa-trophy',
            payoutAccount = 'money',
            buyerMultiplier = 1.12,
            acceptedItems = {
                animal_trophy = true,
                mounted_trophy = true,
            },
            acceptsIllegalGeneric = false,
        },

        black_market = {
            label = 'Black Market Buyer',
            type = 'illegal',
            coords = vec3(1243.84, -3178.87, 5.53),
            radius = 1.5,
            icon = 'fa-solid fa-skull',
            payoutAccount = 'black_money',
            buyerMultiplier = 1.55,
            acceptedItems = {
                contraband_meat = true,
                protected_pelt = true,
                falsified_tag = true,
                poacher_trap = true,
                illegal_bait = true,
                wildlife_evidence = true,
            },
            acceptsIllegalGeneric = true,
        },
    },

    Vendors = {
        ranger_supplier = {
            label = 'Ranger Supplier',
            type = 'legal',
            coords = vec3(-675.92, 5834.93, 17.33),
            radius = 1.5,
            icon = 'fa-solid fa-store',
            purchaseAccount = 'money',
            items = {
                hunting_license_basic = {
                    label = 'Basic Hunting License',
                    price = 500,
                    stack = false,
                    maxQuantity = 1,
                },
                hunting_license_standard = {
                    label = 'Standard Hunting License',
                    price = 2500,
                    stack = false,
                    maxQuantity = 1,
                },
                hunting_license_advanced = {
                    label = 'Advanced Hunting License',
                    price = 7500,
                    stack = false,
                    maxQuantity = 1,
                },
                deer_tag = {
                    label = 'Deer Tag',
                    price = 135,
                    stack = true,
                    maxQuantity = 20,
                },
                boar_tag = {
                    label = 'Boar Tag',
                    price = 240,
                    stack = true,
                    maxQuantity = 20,
                },
                predator_tag = {
                    label = 'Predator Tag',
                    price = 520,
                    stack = true,
                    maxQuantity = 20,
                },
                bear_tag = {
                    label = 'Bear Tag',
                    price = 950,
                    stack = true,
                    maxQuantity = 10,
                },
                field_knife = {
                    label = 'Field Knife',
                    price = 900,
                    stack = false,
                    maxQuantity = 1,
                },
                field_knife_pro = {
                    label = 'Pro Field Knife',
                    price = 3250,
                    stack = false,
                    maxQuantity = 1,
                },
                binoculars_basic = {
                    label = 'Basic Binoculars',
                    price = 1450,
                    stack = false,
                    maxQuantity = 1,
                },
                binoculars_rangefinder = {
                    label = 'Rangefinder Binoculars',
                    price = 5200,
                    stack = false,
                    maxQuantity = 1,
                },
                deer_call = {
                    label = 'Deer Call',
                    price = 680,
                    stack = false,
                    maxQuantity = 1,
                },
                predator_call = {
                    label = 'Predator Call',
                    price = 1650,
                    stack = false,
                    maxQuantity = 1,
                },
                bait_deer = {
                    label = 'Deer Bait',
                    price = 260,
                    stack = true,
                    maxQuantity = 25,
                },
                bait_predator = {
                    label = 'Predator Bait',
                    price = 620,
                    stack = true,
                    maxQuantity = 25,
                },
                trail_camera = {
                    label = 'Trail Camera',
                    price = 2850,
                    stack = true,
                    maxQuantity = 5,
                },
                scent_blocker = {
                    label = 'Scent Blocker',
                    price = 400,
                    stack = true,
                    maxQuantity = 20,
                },
            }
        },

        poacher_supplier = {
            label = 'Poacher Supplier',
            type = 'illegal',
            coords = vec3(1248.01, -3174.02, 5.53),
            radius = 1.5,
            icon = 'fa-solid fa-user-secret',
            purchaseAccount = 'black_money',
            items = {
                illegal_bait = {
                    label = 'Illegal Bait',
                    price = 1600,
                    stack = true,
                    maxQuantity = 20,
                },
                poacher_trap = {
                    label = 'Poacher Trap',
                    price = 2600,
                    stack = true,
                    maxQuantity = 10,
                },
                falsified_tag = {
                    label = 'Falsified Tag',
                    price = 3100,
                    stack = true,
                    maxQuantity = 10,
                },
            }
        },
    }
}
