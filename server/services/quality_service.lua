local Server = DDHunting.Server
local QualityService = {}

Server.Services.Quality = QualityService

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

local function normalizeShotRegion(region)
    if type(region) ~= 'string' then
        return 'unknown'
    end

    region = region:lower()

    local aliases = {
        chest = 'lungs',
        lung = 'lungs',
        lungs = 'lungs',
        heart = 'heart',
        stomach = 'stomach',
        gut = 'stomach',
        spine = 'spine',
        leg = 'limb',
        arm = 'limb',
        limb = 'limb',
        head = 'head',
        neck = 'neck',
        shoulder = 'shoulder',
    }

    return aliases[region] or 'unknown'
end

local function normalizeWeapon(rawWeapon)
    if rawWeapon == nil then
        return {
            raw = nil,
            hash = nil,
            name = nil,
        }
    end

    local result = {
        raw = rawWeapon,
        hash = nil,
        name = nil,
    }

    if type(rawWeapon) == 'number' then
        result.hash = rawWeapon
        return result
    end

    if type(rawWeapon) == 'string' then
        local lower = rawWeapon:lower()
        result.name = lower

        local asNumber = tonumber(rawWeapon)
        if asNumber then
            result.hash = asNumber
        elseif lower:find('weapon_') == 1 then
            result.hash = joaat(lower)
        end
    end

    return result
end

local function weaponMatchesEntry(weaponData, entry)
    if type(entry) ~= 'string' then
        return false
    end

    local lower = entry:lower()
    local entryHash = joaat(lower)

    if weaponData.name and weaponData.name == lower then
        return true
    end

    if weaponData.hash and weaponData.hash == entryHash then
        return true
    end

    if tostring(weaponData.raw) == tostring(entryHash) then
        return true
    end

    return false
end

local ShotProfiles = {
    heart = {
        score = 98,
        cleanKillBonus = 8,
    },
    lungs = {
        score = 90,
        cleanKillBonus = 8,
    },
    neck = {
        score = 82,
        cleanKillBonus = 6,
    },
    spine = {
        score = 74,
        cleanKillBonus = 4,
    },
    shoulder = {
        score = 66,
        cleanKillBonus = 2,
    },
    head = {
        score = 58,
        cleanKillBonus = 0,
    },
    stomach = {
        score = 38,
        cleanKillBonus = -6,
    },
    limb = {
        score = 26,
        cleanKillBonus = -10,
    },
    unknown = {
        score = 60,
        cleanKillBonus = 0,
    },
}

function QualityService.IsWeaponValidForSpecies(speciesKey, weapon)
    local species = DDHunting.Data.GetSpecies(speciesKey)
    if not species then
        return false, 'invalid_species'
    end

    local validWeapons = species.equipment and species.equipment.validWeapons or {}
    local weaponData = normalizeWeapon(weapon)

    for i = 1, #validWeapons do
        if weaponMatchesEntry(weaponData, validWeapons[i]) then
            return true
        end
    end

    return false
end

function QualityService.IsOverkillWeapon(weapon)
    local weaponData = normalizeWeapon(weapon)
    local overkillWeapons = DDHunting.Config.Equipment
        and DDHunting.Config.Equipment.Weapons
        and DDHunting.Config.Equipment.Weapons.OverkillWeapons
        or {}

    for entry in pairs(overkillWeapons) do
        if weaponMatchesEntry(weaponData, entry) then
            return true
        end
    end

    return false
end

function QualityService.EvaluateKill(speciesKey, payload)
    payload = payload or {}

    local species = DDHunting.Data.GetSpecies(speciesKey)
    if not species then
        return {
            qualityScore = 0,
            quality = 'ruined',
            shotRegion = 'unknown',
            cleanKill = false,
            validWeapon = false,
            overkill = false,
            notes = { 'invalid_species' },
        }
    end

    local shotRegion = normalizeShotRegion(payload.shotRegion)
    local shotProfile = ShotProfiles[shotRegion] or ShotProfiles.unknown

    local validWeapon = QualityService.IsWeaponValidForSpecies(speciesKey, payload.weapon)
    local overkill = QualityService.IsOverkillWeapon(payload.weapon)

    local score = shotProfile.score
    local notes = {}

    if payload.cleanKill == true then
        score = score + shotProfile.cleanKillBonus
    end

    if validWeapon then
        score = score + 6
    else
        score = score - 22
        notes[#notes + 1] = 'wrong_weapon'
    end

    if overkill then
        score = score - 40
        notes[#notes + 1] = 'overkill_weapon'
    end

    if payload.dragDamage then
        score = score - (clamp(payload.dragDamage, 0, 100) * 0.10)
    end

    if payload.vehicleDamage then
        score = score - (clamp(payload.vehicleDamage, 0, 100) * 0.20)
    end

    score = clamp(math.floor(score + 0.5), 0, 100)

    return {
        qualityScore = score,
        quality = DDHunting.Data.ItemMetadata.GetQualityFromScore(score),
        shotRegion = shotRegion,
        cleanKill = payload.cleanKill == true,
        validWeapon = validWeapon,
        overkill = overkill,
        notes = notes,
    }
end
