local Data = DDHunting.Data
local Config = DDHunting.Config

Data.ItemMetadata = Data.ItemMetadata or {}
local Meta = Data.ItemMetadata

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function round(value, decimals)
    local power = 10 ^ (decimals or 0)
    return math.floor((value * power) + 0.5) / power
end

local function serial(prefix)
    return ('%s-%d-%06d'):format(prefix or 'HUNT', os.time(), math.random(0, 999999))
end

local function getSpecies(speciesKey)
    local species = Data.GetSpecies and Data.GetSpecies(speciesKey)
    assert(species, ('[dd-hunting] Unknown species "%s" in item metadata builder'):format(tostring(speciesKey)))
    return species
end

function Meta.GetQualityFromScore(score)
    local thresholds = (Config.Loot and Config.Loot.QualityThresholds) or {}

    score = clamp(score or 0, 0, 100)

    if score >= (thresholds.pristine or 90) then
        return 'pristine'
    elseif score >= (thresholds.good or 75) then
        return 'good'
    elseif score >= (thresholds.standard or 55) then
        return 'standard'
    elseif score >= (thresholds.poor or 30) then
        return 'poor'
    end

    return 'ruined'
end

function Meta.GetFreshnessLabel(freshness)
    local thresholds = (Config.Loot and Config.Loot.FreshnessThresholds) or {}

    freshness = clamp(freshness or 100, 0, 100)

    if freshness >= (thresholds.fresh or 85) then
        return 'fresh'
    elseif freshness >= (thresholds.decent or 65) then
        return 'decent'
    elseif freshness >= (thresholds.aging or 35) then
        return 'aging'
    end

    return 'spoiled'
end

function Meta.NormalizeSex(value)
    if value == 'male' or value == 'female' then
        return value
    end

    return 'unknown'
end

function Meta.NormalizeAgeClass(value)
    local valid = {
        juvenile = true,
        adult = true,
        mature = true,
        old = true,
    }

    if valid[value] then
        return value
    end

    return 'adult'
end

function Meta.BuildBaseHarvest(speciesKey, payload)
    payload = payload or {}

    local species = getSpecies(speciesKey)
    local harvestedAt = payload.harvestedAt or os.time()
    local qualityScore = clamp(payload.qualityScore or 60, 0, 100)
    local freshness = clamp(payload.freshness or 100, 0, 100)

    return {
        serial = payload.serial or serial('HV'),
        source = payload.source or 'wildlife',
        species = speciesKey,
        speciesLabel = species.label,

        variant = payload.variant or 'normal',
        sex = Meta.NormalizeSex(payload.sex),
        ageClass = Meta.NormalizeAgeClass(payload.ageClass),

        weight = round(payload.weight or 0, 2),
        trophyScore = round(payload.trophyScore or 0, 2),

        qualityScore = qualityScore,
        quality = payload.quality or Meta.GetQualityFromScore(qualityScore),

        freshness = freshness,
        freshnessLabel = payload.freshnessLabel or Meta.GetFreshnessLabel(freshness),

        zone = payload.zone or 'unknown',
        legal = payload.legal ~= false,
        requiredLicense = payload.requiredLicense or (species.legalityData and species.legalityData.requiredLicense) or 'Basic',
        contractValid = payload.contractValid == true,

        harvestedAt = harvestedAt,
        harvestedDate = os.date('!%Y-%m-%dT%H:%M:%SZ', harvestedAt),

        weapon = payload.weapon or 'unknown',
        shotRegion = payload.shotRegion or 'unknown',
        cleanKill = payload.cleanKill == true,

        killerServerId = payload.killerServerId,
        carcassId = payload.carcassId,
        clueChainId = payload.clueChainId,
    }
end

function Meta.CreateCarcass(speciesKey, payload)
    payload = payload or {}

    local species = getSpecies(speciesKey)
    local base = Meta.BuildBaseHarvest(speciesKey, payload)

    base.itemType = 'carcass'
    base.carcassState = payload.carcassState or 'whole'
    base.carryClass = payload.carryClass or species.harvest.carryClass
    base.canSkin = payload.canSkin ~= false and species.harvest.canSkin == true
    base.canGut = payload.canGut ~= false and species.harvest.canGut == true
    base.canQuarter = payload.canQuarter == true or species.harvest.canQuarter == true
    base.decayAt = payload.decayAt or (os.time() + ((Config.Main and Config.Main.Timers and Config.Main.Timers.CarcassDecaySeconds) or 1800))
    base.deleteAt = payload.deleteAt or (os.time() + ((Config.Main and Config.Main.Timers and Config.Main.Timers.CarcassDeleteSeconds) or 3600))
    base.dragDamage = clamp(payload.dragDamage or 0, 0, 100)
    base.vehicleDamage = clamp(payload.vehicleDamage or 0, 0, 100)

    return base
end

function Meta.CreateMeat(speciesKey, payload)
    payload = payload or {}

    local species = getSpecies(speciesKey)
    local base = Meta.BuildBaseHarvest(speciesKey, payload)

    base.itemType = 'meat'
    base.cutType = payload.cutType or 'raw'
    base.quantity = math.max(1, math.floor(payload.quantity or 1))
    base.weightKg = round(payload.weightKg or 1.0, 2)
    base.nutrition = payload.nutrition or 'standard'
    base.sellBaseValue = payload.sellBaseValue or species.economy.baseValue
    base.spoilsAt = payload.spoilsAt or (os.time() + ((Config.Main and Config.Main.Timers and Config.Main.Timers.CarcassDecaySeconds) or 1800))

    return base
end

function Meta.CreatePelt(speciesKey, payload)
    payload = payload or {}

    local species = getSpecies(speciesKey)
    if species.harvest.pelt ~= true then
        return nil
    end

    local base = Meta.BuildBaseHarvest(speciesKey, payload)

    base.itemType = 'pelt'
    base.size = payload.size or species.harvest.carryClass
    base.integrity = clamp(payload.integrity or base.qualityScore, 0, 100)
    base.sellBaseValue = payload.sellBaseValue or species.economy.baseValue

    return base
end

function Meta.CreatePart(speciesKey, partType, payload)
    payload = payload or {}

    local species = getSpecies(speciesKey)
    local allowed = {
        antlers = species.harvest.antlers == true,
        tusk = species.harvest.tusk == true,
        fang = species.harvest.fang == true,
        claw = species.harvest.claw == true,
        trophy = species.harvest.trophy == true,
    }

    if not allowed[partType] then
        return nil
    end

    local base = Meta.BuildBaseHarvest(speciesKey, payload)

    base.itemType = 'part'
    base.partType = partType
    base.condition = payload.condition or base.quality
    base.sellBaseValue = payload.sellBaseValue or species.economy.baseValue

    return base
end

function Meta.CreateTrophy(speciesKey, payload)
    payload = payload or {}

    local species = getSpecies(speciesKey)
    if species.trophy.enabled ~= true then
        return nil
    end

    local base = Meta.BuildBaseHarvest(speciesKey, payload)

    base.itemType = 'trophy'
    base.displayName = payload.displayName or (species.label .. ' Trophy')
    base.rank = payload.rank or 'common'
    base.mounted = payload.mounted == true
    base.recordEligible = payload.recordEligible ~= false
    base.sellBaseValue = payload.sellBaseValue or species.economy.baseValue

    return base
end

function Meta.CreateLicenseTag(speciesKey, payload)
    payload = payload or {}

    local species = getSpecies(speciesKey)

    return {
        serial = payload.serial or serial('TAG'),
        itemType = 'tag',
        species = speciesKey,
        speciesLabel = species.label,
        requiredLicense = payload.requiredLicense or (species.legalityData and species.legalityData.requiredLicense) or 'Basic',
        issuedAt = payload.issuedAt or os.time(),
        expiresAt = payload.expiresAt,
        used = payload.used == true,
        usedAt = payload.usedAt,
        ownerIdentifier = payload.ownerIdentifier,
        ownerServerId = payload.ownerServerId,
    }
end

function Meta.CreateEvidence(evidenceType, payload)
    payload = payload or {}

    return {
        serial = payload.serial or serial('EVD'),
        itemType = 'evidence',
        evidenceType = evidenceType or 'unknown',
        zone = payload.zone or 'unknown',
        species = payload.species,
        legal = payload.legal == true,
        createdAt = payload.createdAt or os.time(),
        suspectServerId = payload.suspectServerId,
        suspectIdentifier = payload.suspectIdentifier,
        weapon = payload.weapon,
        notes = payload.notes,
    }
end

function Meta.CreateBaitInstance(baitItem, payload)
    payload = payload or {}

    return {
        serial = payload.serial or serial('BAIT'),
        itemType = 'bait',
        baitItem = baitItem,
        zone = payload.zone or 'unknown',
        placedAt = payload.placedAt or os.time(),
        expiresAt = payload.expiresAt,
        ownerIdentifier = payload.ownerIdentifier,
        ownerServerId = payload.ownerServerId,
        illegal = payload.illegal == true,
    }
end

function Meta.CanUseWeaponForSpecies(speciesKey, weaponName)
    local species = getSpecies(speciesKey)
    local validWeapons = species.equipment.validWeapons or {}

    for i = 1, #validWeapons do
        if validWeapons[i] == weaponName then
            return true
        end
    end

    return false
end

function Meta.IsOverkillWeapon(weaponName)
    local overkill = Config.Equipment
        and Config.Equipment.Weapons
        and Config.Equipment.Weapons.OverkillWeapons

    return overkill and overkill[weaponName] == true or false
end

function Meta.GetDefaultMeatYield(speciesKey)
    local species = getSpecies(speciesKey)
    return species.harvest.meatMin or 1, species.harvest.meatMax or 1
end
