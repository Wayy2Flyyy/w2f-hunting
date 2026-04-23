local Server = DDHunting.Server
local MasteryService = {}
Server.Services.Mastery = MasteryService

local function cfg()
    return DDHunting.Config.Progression and DDHunting.Config.Progression.Mastery or {}
end

local function rankXpRequired(rank)
    local curve = cfg().RankCurve or {}
    local base = tonumber(curve.BaseXP) or 120
    local growth = tonumber(curve.Growth) or 1.27
    rank = math.max(0, tonumber(rank) or 0)
    return math.floor(base * (growth ^ rank))
end

function MasteryService.DefaultSpeciesState()
    return {
        kills = 0,
        cleanKills = 0,
        bestTrophy = 0,
        bestWeight = 0,
        variantsFound = {},
        masteryXP = 0,
        masteryRank = 0,
        lastHuntedAt = 0,
    }
end

function MasteryService.AddHarvest(profile, carcass, legality)
    local speciesKey = carcass and carcass.species
    if not speciesKey then
        return nil
    end

    profile.speciesMastery[speciesKey] = profile.speciesMastery[speciesKey] or MasteryService.DefaultSpeciesState()
    local row = profile.speciesMastery[speciesKey]

    row.kills = row.kills + 1
    row.lastHuntedAt = os.time()

    if carcass.cleanKill then
        row.cleanKills = row.cleanKills + 1
    end

    local trophy = tonumber(carcass.trophyScore) or 0
    local weight = tonumber(carcass.weight) or 0
    row.bestTrophy = math.max(row.bestTrophy or 0, trophy)
    row.bestWeight = math.max(row.bestWeight or 0, weight)

    local variant = carcass.variant or 'normal'
    row.variantsFound[variant] = true

    local xp = tonumber(cfg().BaseXpPerKill) or 18
    if carcass.cleanKill then
        xp = xp + (tonumber(cfg().CleanKillBonus) or 8)
    end

    if variant ~= 'normal' then
        xp = xp + (tonumber(cfg().RareVariantBonus) or 25)
    end

    if trophy > 0 then
        xp = xp + math.floor(trophy / (tonumber(cfg().TrophyBonusDivisor) or 14))
    end

    if legality and legality.legal == false then
        xp = math.floor(xp * 0.85)
    end

    row.masteryXP = row.masteryXP + math.max(0, xp)

    local maxRank = ((cfg().RankCurve or {}).MaxRank) or 20
    while row.masteryRank < maxRank and row.masteryXP >= rankXpRequired(row.masteryRank) do
        row.masteryXP = row.masteryXP - rankXpRequired(row.masteryRank)
        row.masteryRank = row.masteryRank + 1
    end

    return speciesKey, row
end

function MasteryService.ToSummary(profile)
    local list = {}
    for speciesKey, row in pairs(profile.speciesMastery or {}) do
        list[#list + 1] = {
            species = speciesKey,
            kills = row.kills,
            cleanKills = row.cleanKills,
            bestTrophy = row.bestTrophy,
            bestWeight = row.bestWeight,
            masteryRank = row.masteryRank,
            variantsFound = row.variantsFound,
        }
    end

    table.sort(list, function(a, b)
        if a.masteryRank == b.masteryRank then
            return a.kills > b.kills
        end
        return a.masteryRank > b.masteryRank
    end)

    return list
end
