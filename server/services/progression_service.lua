local Server = DDHunting.Server
local Bridge = Server.Bridge
local State = Server.State
local Persistence = Server.Services.Persistence
local Reputation = Server.Services.Reputation
local Mastery = Server.Services.Mastery

local ProgressionService = {}
Server.Services.Progression = ProgressionService

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][progression] %s'):format(msg))
    end
end

local function getIdentifier(source)
    return Bridge.ESX.GetIdentifier(source) or ('src:%s'):format(source)
end

local function calcXpRequired(level)
    local curve = DDHunting.Config.Progression and DDHunting.Config.Progression.LevelCurve or {}
    local base = tonumber(curve.BaseXP) or 180
    local growth = tonumber(curve.Growth) or 1.22
    return math.floor(base * (growth ^ math.max(0, (level or 1) - 1)))
end

local function normalizeBranches(rows)
    local branches = {}
    local spent = {}

    for key in pairs((DDHunting.Config.Progression and DDHunting.Config.Progression.Branches) or {}) do
        branches[key] = 0
        spent[key] = 0
    end

    for i = 1, #(rows or {}) do
        local row = rows[i]
        if branches[row.branch_key] ~= nil then
            branches[row.branch_key] = math.max(0, tonumber(row.branch_rank) or 0)
            spent[row.branch_key] = math.max(0, tonumber(row.spent_points) or 0)
        end
    end

    return branches, spent
end

local function normalizeReputation(rows)
    local reps = Reputation.BuildDefaults()

    for i = 1, #(rows or {}) do
        local row = rows[i]
        if reps[row.rep_type] then
            reps[row.rep_type].value = math.floor(tonumber(row.rep_value) or 0)
            reps[row.rep_type].lifetimeGain = math.floor(tonumber(row.lifetime_gain) or 0)
            reps[row.rep_type].lifetimeLoss = math.floor(tonumber(row.lifetime_loss) or 0)
        end
    end

    return reps
end

local function normalizeMastery(rows)
    local out = {}

    for i = 1, #(rows or {}) do
        local row = rows[i]
        local variants = {}
        if row.variants_found_json and row.variants_found_json ~= '' then
            local ok, parsed = pcall(json.decode, row.variants_found_json)
            if ok and type(parsed) == 'table' then
                variants = parsed
            end
        end

        out[row.species_key] = {
            kills = math.max(0, tonumber(row.kills) or 0),
            cleanKills = math.max(0, tonumber(row.clean_kills) or 0),
            bestTrophy = tonumber(row.best_trophy) or 0,
            bestWeight = tonumber(row.best_weight) or 0,
            variantsFound = variants,
            masteryXP = math.max(0, tonumber(row.mastery_xp) or 0),
            masteryRank = math.max(0, tonumber(row.mastery_rank) or 0),
            lastHuntedAt = tonumber(row.last_hunted_at) or 0,
        }
    end

    return out
end

local function buildProfile(identifier)
    local p = Persistence.LoadProfile(identifier)
    local branches, spent = normalizeBranches(Persistence.LoadSkillBranches(identifier))

    local unlocked = {}
    local unlockRows = Persistence.LoadUnlocks(identifier)
    for i = 1, #unlockRows do
        unlocked[unlockRows[i].unlock_key] = true
    end

    return {
        identifier = identifier,
        level = math.max(1, tonumber(p.hunter_level) or 1),
        xp = math.max(0, tonumber(p.hunter_xp) or 0),
        skillPoints = math.max(0, tonumber(p.unspent_skill_points) or 0),
        branchRanks = branches,
        branchSpentPoints = spent,
        reputation = normalizeReputation(Persistence.LoadReputation(identifier)),
        speciesMastery = normalizeMastery(Persistence.LoadSpeciesMastery(identifier)),
        unlocked = unlocked,
        currentTitle = p.current_title or (DDHunting.Config.Progression.Titles.Default),
        totalHunts = math.max(0, tonumber(p.total_hunts) or 0),
        totalCleanKills = math.max(0, tonumber(p.total_clean_kills) or 0),
        totalSales = math.max(0, tonumber(p.total_sales) or 0),
        dirty = false,
    }
end

local function saveAll(profile)
    if not profile then return end

    Persistence.SaveProfile(profile.identifier, {
        level = profile.level,
        xp = profile.xp,
        skillPoints = profile.skillPoints,
        currentTitle = profile.currentTitle,
        totalHunts = profile.totalHunts,
        totalCleanKills = profile.totalCleanKills,
        totalSales = profile.totalSales,
    })

    for branchKey, rank in pairs(profile.branchRanks) do
        Persistence.SaveSkillBranch(profile.identifier, branchKey, rank, profile.branchSpentPoints[branchKey] or rank)
    end

    for repType, rep in pairs(profile.reputation) do
        Persistence.SaveReputation(profile.identifier, repType, rep.value or 0, rep.lifetimeGain or 0, rep.lifetimeLoss or 0)
    end

    for speciesKey, mastery in pairs(profile.speciesMastery) do
        Persistence.SaveSpeciesMastery(profile.identifier, speciesKey, mastery)
    end

    for unlockKey in pairs(profile.unlocked) do
        Persistence.SaveUnlock(profile.identifier, unlockKey, { unlocked = true })
    end

    profile.dirty = false
end

local function ensureProfile(source)
    local identifier = getIdentifier(source)
    if not State.ProgressionPlayers.byIdentifier[identifier] then
        State.ProgressionPlayers.byIdentifier[identifier] = buildProfile(identifier)
    end

    return State.ProgressionPlayers.byIdentifier[identifier]
end

local function resolveUnlocks(profile)
    local unlocks = DDHunting.Config.Progression and DDHunting.Config.Progression.Unlocks or {}

    for unlockKey, def in pairs(unlocks) do
        if not profile.unlocked[unlockKey] then
            if def.type == 'level' and profile.level >= (def.threshold or 0) then
                profile.unlocked[unlockKey] = true
                Persistence.SaveUnlock(profile.identifier, unlockKey, { source = 'level', level = profile.level })
            elseif def.type == 'reputation' and def.repType and profile.reputation[def.repType] then
                if (profile.reputation[def.repType].value or 0) >= (def.threshold or 0) then
                    profile.unlocked[unlockKey] = true
                    Persistence.SaveUnlock(profile.identifier, unlockKey, { source = 'reputation', repType = def.repType })
                end
            end
        end
    end
end

local function setDirty(profile)
    profile.currentTitle = Reputation.ResolveCurrentTitle(profile)
    resolveUnlocks(profile)
    profile.dirty = true
end

function ProgressionService.Init()
    debugPrint('progression services initialized')
end

function ProgressionService.GetProfile(source)
    return ensureProfile(source)
end

function ProgressionService.AddXP(source, amount, reason, opts)
    local profile = ensureProfile(source)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then
        return false, 'invalid_amount'
    end

    local maxLevel = tonumber((DDHunting.Config.Progression and DDHunting.Config.Progression.MaxLevel) or 80)

    if amount > 0 then
        profile.xp = profile.xp + amount
        while profile.level < maxLevel and profile.xp >= calcXpRequired(profile.level) do
            profile.xp = profile.xp - calcXpRequired(profile.level)
            profile.level = profile.level + 1

            local spCfg = DDHunting.Config.Progression and DDHunting.Config.Progression.SkillPoints or {}
            local every = math.max(1, tonumber(spCfg.EveryLevels) or 2)
            if (profile.level % every) == 0 then
                profile.skillPoints = profile.skillPoints + 1
            end

            if spCfg.BonusAt and spCfg.BonusAt[profile.level] then
                profile.skillPoints = profile.skillPoints + math.max(0, tonumber(spCfg.BonusAt[profile.level]) or 0)
            end
        end
    else
        profile.xp = math.max(0, profile.xp + amount)
    end

    setDirty(profile)

    if not (opts and opts.deferSave) then
        saveAll(profile)
    end

    if not (opts and opts.deferSync) then
        ProgressionService.Sync(source)
    end

    return true, { reason = reason or 'generic', level = profile.level, xp = profile.xp }
end

function ProgressionService.AddReputation(source, repType, delta, meta, opts)
    local profile = ensureProfile(source)
    local rep = Reputation.Apply(profile, repType, delta)

    if repType == 'ranger_heat' and delta > 0 then
        Persistence.InsertCrime(profile.identifier, (meta and meta.crimeType) or 'unknown', delta, meta or {})
    end

    setDirty(profile)

    if not (opts and opts.deferSave) then
        saveAll(profile)
    end

    if not (opts and opts.deferSync) then
        ProgressionService.Sync(source)
    end

    return true, rep
end

function ProgressionService.SpendSkillPoint(source, branchKey)
    local profile = ensureProfile(source)
    local branchDef = DDHunting.Config.Progression and DDHunting.Config.Progression.Branches and DDHunting.Config.Progression.Branches[branchKey]
    if not branchDef then
        return false, 'invalid_branch'
    end

    if profile.skillPoints <= 0 then
        return false, 'no_skill_points'
    end

    local current = profile.branchRanks[branchKey] or 0
    if current >= (branchDef.MaxRank or 10) then
        return false, 'branch_maxed'
    end

    profile.skillPoints = profile.skillPoints - 1
    profile.branchRanks[branchKey] = current + 1
    profile.branchSpentPoints[branchKey] = (profile.branchSpentPoints[branchKey] or 0) + 1

    setDirty(profile)
    saveAll(profile)
    ProgressionService.Sync(source)

    return true, profile.branchRanks
end

function ProgressionService.RecordHarvest(source, carcass, legality)
    local profile = ensureProfile(source)
    local xpCfg = DDHunting.Config.Progression.XP.Harvest

    profile.totalHunts = profile.totalHunts + 1
    if carcass.cleanKill then
        profile.totalCleanKills = profile.totalCleanKills + 1
        ProgressionService.AddXP(source, xpCfg.CleanKill, 'harvest_clean', { deferSave = true, deferSync = true })
    else
        ProgressionService.AddXP(source, xpCfg.Standard, 'harvest_standard', { deferSave = true, deferSync = true })
    end

    if carcass.quality == 'perfect' then
        ProgressionService.AddXP(source, xpCfg.PerfectHarvest, 'harvest_perfect', { deferSave = true, deferSync = true })
    end

    if carcass.variant and carcass.variant ~= 'normal' then
        ProgressionService.AddXP(source, xpCfg.RareVariantBonus, 'variant_bonus', { deferSave = true, deferSync = true })
    end

    if (tonumber(carcass.trophyScore) or 0) > 120 then
        ProgressionService.AddXP(source, xpCfg.TrophyBonus, 'trophy_bonus', { deferSave = true, deferSync = true })
    end

    if legality and legality.legal then
        ProgressionService.AddReputation(source, 'legal', 3, nil, { deferSave = true, deferSync = true })
        ProgressionService.AddReputation(source, 'ranger_heat', DDHunting.Config.Progression.Heat.Events.RangerAssist, { crimeType = 'lawful_hunt' }, { deferSave = true, deferSync = true })
    else
        ProgressionService.AddXP(source, xpCfg.IllegalPenalty, 'illegal_penalty', { deferSave = true, deferSync = true })
        ProgressionService.AddReputation(source, 'legal', -6, nil, { deferSave = true, deferSync = true })
        ProgressionService.AddReputation(source, 'ranger_heat', DDHunting.Config.Progression.Heat.Events.IllegalHarvest, {
            crimeType = 'illegal_harvest',
            species = carcass.species,
            protected = legality and legality.protectedSpecies == true,
        }, { deferSave = true, deferSync = true })

        if legality and legality.protectedSpecies then
            ProgressionService.AddReputation(source, 'ranger_heat', DDHunting.Config.Progression.Heat.Events.ProtectedSpecies, {
                crimeType = 'protected_species_harvest',
                species = carcass.species,
            }, { deferSave = true, deferSync = true })
        end
    end

    local speciesKey, masteryState = Mastery.AddHarvest(profile, carcass, legality)
    if speciesKey and masteryState then
        Persistence.SaveSpeciesMastery(profile.identifier, speciesKey, masteryState)
    end

    setDirty(profile)
    saveAll(profile)
    ProgressionService.Sync(source)
end

function ProgressionService.RecordSale(source, buyerKey, preview)
    local profile = ensureProfile(source)
    local xpCfg = DDHunting.Config.Progression.XP.Market

    profile.totalSales = profile.totalSales + 1

    if preview.buyerType == 'illegal' then
        ProgressionService.AddXP(source, (xpCfg.IllegalUnit or 3) * math.max(1, preview.units), 'illegal_sale', { deferSave = true, deferSync = true })
        ProgressionService.AddReputation(source, 'black_market', 6, nil, { deferSave = true, deferSync = true })
        ProgressionService.AddReputation(source, 'ranger_heat', DDHunting.Config.Progression.Heat.Events.BlackMarketSale, {
            crimeType = 'black_market_sale',
            buyer = buyerKey,
            units = preview.units,
        }, { deferSave = true, deferSync = true })
    else
        ProgressionService.AddXP(source, (xpCfg.LegalUnit or 2) * math.max(1, preview.units), 'legal_sale', { deferSave = true, deferSync = true })
        ProgressionService.AddReputation(source, 'legal', 2, nil, { deferSave = true, deferSync = true })

        if buyerKey == 'trapper' then
            ProgressionService.AddReputation(source, 'trapper', 3, nil, { deferSave = true, deferSync = true })
        elseif buyerKey == 'trophy_collector' then
            ProgressionService.AddReputation(source, 'trophy', 4, nil, { deferSave = true, deferSync = true })
        end
    end

    if preview.units >= (xpCfg.BulkThreshold or 20) then
        ProgressionService.AddXP(source, xpCfg.BulkBonus or 40, 'bulk_bonus', { deferSave = true, deferSync = true })
    end

    for i = 1, #(preview.lines or {}) do
        local line = preview.lines[i]
        if line.item == 'animal_trophy' or line.item == 'mounted_trophy' then
            ProgressionService.AddXP(source, xpCfg.TrophyLineBonus or 22, 'trophy_sale_bonus', { deferSave = true, deferSync = true })
        end
    end

    setDirty(profile)
    saveAll(profile)
    ProgressionService.Sync(source)
end

function ProgressionService.RecordProcessing(source, benchKey, recipeKey, craftCount)
    local xpCfg = DDHunting.Config.Progression.XP.Processing
    ProgressionService.AddXP(source, (xpCfg.CraftAction or 12) * math.max(1, craftCount or 1), 'processing', { deferSave = true, deferSync = true })

    if benchKey == 'trophy_bench' then
        ProgressionService.AddReputation(source, 'trophy', 2, nil, { deferSave = true, deferSync = true })
        ProgressionService.AddXP(source, xpCfg.TrophyBenchBonus or 20, 'trophy_bench', { deferSave = true, deferSync = true })
    elseif benchKey == 'illegal' then
        ProgressionService.AddReputation(source, 'black_market', 2, nil, { deferSave = true, deferSync = true })
        ProgressionService.AddReputation(source, 'ranger_heat', DDHunting.Config.Progression.Heat.Events.IllegalProcessing, {
            crimeType = 'illegal_processing',
            recipe = recipeKey,
        }, { deferSave = true, deferSync = true })
        ProgressionService.AddXP(source, xpCfg.IllegalBenchBonus or 18, 'illegal_bench', { deferSave = true, deferSync = true })
    elseif benchKey == 'tannery' then
        ProgressionService.AddReputation(source, 'trapper', 2, nil, { deferSave = true, deferSync = true })
    end

    local profile = ensureProfile(source)
    setDirty(profile)
    saveAll(profile)
    ProgressionService.Sync(source)
end

function ProgressionService.GetSummary(source)
    local profile = ensureProfile(source)

    local reps = {}
    for repType, rep in pairs(profile.reputation) do
        reps[repType] = {
            value = rep.value,
            label = Reputation.GetThresholdTitle(repType, rep.value),
            lifetimeGain = rep.lifetimeGain,
            lifetimeLoss = rep.lifetimeLoss,
        }
    end

    return {
        level = profile.level,
        xp = profile.xp,
        xpToNext = calcXpRequired(profile.level),
        skillPoints = profile.skillPoints,
        branches = profile.branchRanks,
        currentTitle = profile.currentTitle,
        reputation = reps,
        unlocks = profile.unlocked,
        totals = {
            hunts = profile.totalHunts,
            cleanKills = profile.totalCleanKills,
            sales = profile.totalSales,
        },
        mastery = Mastery.ToSummary(profile),
    }
end

function ProgressionService.Sync(source)
    local payload = ProgressionService.GetSummary(source)
    TriggerClientEvent('dd-hunting:cl:progressionUpdated', source, payload)
    return payload
end

function ProgressionService.FlushBySource(source)
    local identifier = getIdentifier(source)
    local profile = State.ProgressionPlayers.byIdentifier[identifier]
    if profile then
        saveAll(profile)
        State.ProgressionPlayers.byIdentifier[identifier] = nil
    end
end

AddEventHandler('playerDropped', function()
    ProgressionService.FlushBySource(source)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    for _, profile in pairs(State.ProgressionPlayers.byIdentifier) do
        saveAll(profile)
    end
end)
