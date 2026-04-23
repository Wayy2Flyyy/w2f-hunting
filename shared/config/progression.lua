local Config = DDHunting.Config

Config.Progression = {
    MaxLevel = 80,

    LevelCurve = {
        BaseXP = 180,
        Growth = 1.22,
    },

    SkillPoints = {
        EveryLevels = 2,
        BonusAt = {
            [10] = 1,
            [20] = 2,
            [40] = 2,
            [60] = 3,
        }
    },

    XP = {
        Harvest = {
            Standard = 25,
            CleanKill = 45,
            PerfectHarvest = 40,
            IllegalPenalty = -5,
            RareVariantBonus = 35,
            TrophyBonus = 20,
        },
        Market = {
            LegalUnit = 2,
            IllegalUnit = 3,
            BulkThreshold = 20,
            BulkBonus = 40,
            TrophyLineBonus = 22,
        },
        Processing = {
            CraftAction = 12,
            TrophyBenchBonus = 20,
            IllegalBenchBonus = 18,
        },
        Contracts = {
            StandardComplete = 140,
            LegendaryComplete = 550,
        }
    },

    Branches = {
        tracker = { Label = 'Tracker', MaxRank = 12 },
        marksman = { Label = 'Marksman', MaxRank = 12 },
        butcher = { Label = 'Butcher', MaxRank = 12 },
        survivalist = { Label = 'Survivalist', MaxRank = 12 },
        trophy_hunter = { Label = 'Trophy Hunter', MaxRank = 12 },
        poacher = { Label = 'Poacher', MaxRank = 12 },
    },

    Reputation = {
        Min = -2000,
        Max = 6000,
        Types = {
            legal = { label = 'Legal Hunter Rep', default = 0 },
            trapper = { label = 'Trapper Rep', default = 0 },
            trophy = { label = 'Trophy Rep', default = 0 },
            black_market = { label = 'Black Market Rep', default = 0 },
            ranger_heat = { label = 'Ranger Heat', default = 0, isHeat = true },
        },
        Thresholds = {
            legal = {
                { value = -600, title = 'Known Poacher' },
                { value = 0, title = 'Unproven Hunter' },
                { value = 450, title = 'Licensed Regular' },
                { value = 1200, title = 'Respected Warden Ally' },
                { value = 2600, title = 'Conservation Pillar' },
            },
            trapper = {
                { value = 0, title = 'Fur Runner' },
                { value = 500, title = 'Hide Supplier' },
                { value = 1400, title = 'Tannery Favorite' },
            },
            trophy = {
                { value = 0, title = 'Aspiring Collector' },
                { value = 550, title = 'Hall Entrant' },
                { value = 1500, title = 'Trophy Specialist' },
            },
            black_market = {
                { value = 0, title = 'Street Unknown' },
                { value = 700, title = 'Smuggler Contact' },
                { value = 1800, title = 'Shadow Broker' },
            },
        },
    },

    Heat = {
        Min = 0,
        Max = 100,
        Events = {
            IllegalHarvest = 10,
            ProtectedSpecies = 22,
            BlackMarketSale = 8,
            IllegalProcessing = 6,
            RangerAssist = -7,
        }
    },

    Mastery = {
        BaseXpPerKill = 18,
        CleanKillBonus = 8,
        RareVariantBonus = 25,
        TrophyBonusDivisor = 14,
        RankCurve = {
            BaseXP = 120,
            Growth = 1.27,
            MaxRank = 20,
        },
    },

    Unlocks = {
        contract_board_t2 = { type = 'level', threshold = 12, label = 'Advanced Contracts' },
        contract_board_t3 = { type = 'level', threshold = 24, label = 'Elite Contracts' },
        contract_legendary = { type = 'level', threshold = 40, label = 'Legendary Hunt Contracts' },
        legal_commission_bonus = { type = 'reputation', repType = 'legal', threshold = 1200, label = 'Legal Commission Bonus Flag' },
        trapper_preferred_rates = { type = 'reputation', repType = 'trapper', threshold = 900, label = 'Trapper Preferred Rates Flag' },
        trophy_showcase = { type = 'reputation', repType = 'trophy', threshold = 1200, label = 'Trophy Showcase Access Flag' },
        black_market_inner_circle = { type = 'reputation', repType = 'black_market', threshold = 1500, label = 'Black Market Inner Circle Flag' },
    },

    Titles = {
        Default = 'Rookie Hunter',
        Rules = {
            { key = 'warden_ally', label = 'Warden Ally', repType = 'legal', threshold = 1700 },
            { key = 'master_trapper', label = 'Master Trapper', repType = 'trapper', threshold = 1400 },
            { key = 'trophy_master', label = 'Trophy Master', repType = 'trophy', threshold = 1500 },
            { key = 'silent_smuggler', label = 'Silent Smuggler', repType = 'black_market', threshold = 1600 },
            { key = 'high_risk_poacher', label = 'High-Risk Poacher', repType = 'ranger_heat', threshold = 75 },
        }
    },
}
