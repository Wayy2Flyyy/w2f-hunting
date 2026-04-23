local Data = DDHunting.Data

Data.ItemTree = {
    documents = {
        hunting_license_basic = {
            label = 'Basic Hunting License',
            category = 'documents',
            stack = false,
            metadataType = 'license',
        },
        hunting_license_standard = {
            label = 'Standard Hunting License',
            category = 'documents',
            stack = false,
            metadataType = 'license',
        },
        hunting_license_advanced = {
            label = 'Advanced Hunting License',
            category = 'documents',
            stack = false,
            metadataType = 'license',
        },
        deer_tag = {
            label = 'Deer Tag',
            category = 'documents',
            stack = true,
            metadataType = 'tag',
        },
        boar_tag = {
            label = 'Boar Tag',
            category = 'documents',
            stack = true,
            metadataType = 'tag',
        },
        predator_tag = {
            label = 'Predator Tag',
            category = 'documents',
            stack = true,
            metadataType = 'tag',
        },
        bear_tag = {
            label = 'Bear Tag',
            category = 'documents',
            stack = true,
            metadataType = 'tag',
        },
    },

    tools = {
        field_knife = {
            label = 'Field Knife',
            category = 'tools',
            stack = false,
            metadataType = 'tool',
        },
        field_knife_pro = {
            label = 'Pro Field Knife',
            category = 'tools',
            stack = false,
            metadataType = 'tool',
        },
        binoculars_basic = {
            label = 'Basic Binoculars',
            category = 'tools',
            stack = false,
            metadataType = 'tool',
        },
        binoculars_rangefinder = {
            label = 'Rangefinder Binoculars',
            category = 'tools',
            stack = false,
            metadataType = 'tool',
        },
        scent_blocker = {
            label = 'Scent Blocker',
            category = 'tools',
            stack = true,
            metadataType = 'consumable',
        },
        game_cart = {
            label = 'Game Cart',
            category = 'tools',
            stack = false,
            metadataType = 'tool',
        },
        trail_camera = {
            label = 'Trail Camera',
            category = 'tools',
            stack = true,
            metadataType = 'device',
        },
        field_dressing_kit = {
            label = 'Field Dressing Kit',
            category = 'tools',
            stack = true,
            metadataType = 'tool',
        },
        hunter_journal = {
            label = 'Hunter Journal',
            category = 'tools',
            stack = false,
            metadataType = 'journal',
        },
    },

    calls_bait = {
        deer_call = {
            label = 'Deer Call',
            category = 'calls_bait',
            stack = false,
            metadataType = 'call',
        },
        predator_call = {
            label = 'Predator Call',
            category = 'calls_bait',
            stack = false,
            metadataType = 'call',
        },
        bait_deer = {
            label = 'Deer Bait',
            category = 'calls_bait',
            stack = true,
            metadataType = 'bait',
        },
        bait_predator = {
            label = 'Predator Bait',
            category = 'calls_bait',
            stack = true,
            metadataType = 'bait',
        },
        illegal_bait = {
            label = 'Illegal Bait',
            category = 'calls_bait',
            stack = true,
            metadataType = 'contraband',
        },
    },

    harvest = {
        raw_meat = {
            label = 'Raw Game Meat',
            category = 'harvest',
            stack = false,
            metadataType = 'meat',
        },
        animal_pelt = {
            label = 'Animal Pelt',
            category = 'harvest',
            stack = false,
            metadataType = 'pelt',
        },
        animal_part = {
            label = 'Animal Part',
            category = 'harvest',
            stack = false,
            metadataType = 'part',
        },
        animal_trophy = {
            label = 'Animal Trophy',
            category = 'harvest',
            stack = false,
            metadataType = 'trophy',
        },
    },

    processed = {
        trimmed_meat = {
            label = 'Trimmed Meat',
            category = 'processed',
            stack = false,
            metadataType = 'meat',
        },
        premium_cut = {
            label = 'Premium Cut',
            category = 'processed',
            stack = false,
            metadataType = 'meat',
        },
        boxed_game_meat = {
            label = 'Boxed Game Meat',
            category = 'processed',
            stack = false,
            metadataType = 'goods',
        },
        salted_pelt = {
            label = 'Salted Pelt',
            category = 'processed',
            stack = false,
            metadataType = 'pelt',
        },
        treated_pelt = {
            label = 'Treated Pelt',
            category = 'processed',
            stack = false,
            metadataType = 'pelt',
        },
        mounted_trophy = {
            label = 'Mounted Trophy',
            category = 'processed',
            stack = false,
            metadataType = 'trophy',
        },
    },

    illegal = {
        protected_pelt = {
            label = 'Protected Pelt',
            category = 'illegal',
            stack = false,
            metadataType = 'contraband',
        },
        contraband_meat = {
            label = 'Contraband Meat',
            category = 'illegal',
            stack = false,
            metadataType = 'contraband',
        },
        falsified_tag = {
            label = 'Falsified Tag',
            category = 'illegal',
            stack = true,
            metadataType = 'contraband',
        },
        poacher_trap = {
            label = 'Poacher Trap',
            category = 'illegal',
            stack = true,
            metadataType = 'contraband',
        },
        wildlife_evidence = {
            label = 'Wildlife Evidence',
            category = 'illegal',
            stack = false,
            metadataType = 'evidence',
        },
    },

    utility = {
        freezer_crate = {
            label = 'Freezer Crate',
            category = 'utility',
            stack = true,
            metadataType = 'storage',
        },
        trophy_plaque = {
            label = 'Trophy Plaque',
            category = 'utility',
            stack = true,
            metadataType = 'display',
        },
        contract_token = {
            label = 'Contract Token',
            category = 'utility',
            stack = true,
            metadataType = 'contract',
        },
    }
}
