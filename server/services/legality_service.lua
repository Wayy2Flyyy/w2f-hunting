local Server = DDHunting.Server
local Bridge = Server.Bridge
local LegalityService = {}

Server.Services.Legality = LegalityService

local LicenseOrder = {
    Basic = 1,
    Standard = 2,
    Advanced = 3,
}

local LicenseItems = {
    Basic = 'hunting_license_basic',
    Standard = 'hunting_license_standard',
    Advanced = 'hunting_license_advanced',
}

local SpeciesTags = {
    deer = 'deer_tag',
    boar = 'boar_tag',
    coyote = 'predator_tag',
    wolf = 'predator_tag',
    mountain_lion = 'predator_tag',
    bear = 'bear_tag',
}

local function isInsideRestrictedZone(coords)
    local restricted = DDHunting.Config.Zones and DDHunting.Config.Zones.Restricted
    if not restricted then
        return false, nil
    end

    for zoneName, zone in pairs(restricted) do
        if zone.center and zone.radius then
            local dist = #(coords - zone.center)
            if dist <= zone.radius then
                return true, zoneName
            end
        end
    end

    return false, nil
end

local function currentHour()
    return tonumber(os.date('%H')) or 12
end

function LegalityService.GetRequiredLicense(speciesKey)
    local species = DDHunting.Data.GetSpecies(speciesKey)
    if not species then
        return nil
    end

    return species.legalityData and species.legalityData.requiredLicense or 'Basic'
end

function LegalityService.GetRequiredTagItem(speciesKey)
    return SpeciesTags[speciesKey]
end

function LegalityService.HasLicense(source, requiredTier)
    requiredTier = requiredTier or 'Basic'
    local requiredRank = LicenseOrder[requiredTier] or 1

    for tierName, rank in pairs(LicenseOrder) do
        if rank >= requiredRank then
            local itemName = LicenseItems[tierName]
            if itemName and Bridge.Inventory.GetItemCount(source, itemName) > 0 then
                return true, tierName
            end
        end
    end

    return false, nil
end

function LegalityService.HasTag(source, speciesKey)
    local itemName = LegalityService.GetRequiredTagItem(speciesKey)
    if not itemName then
        return true, nil
    end

    return Bridge.Inventory.GetItemCount(source, itemName) > 0, itemName
end

function LegalityService.ConsumeTag(source, speciesKey)
    local itemName = LegalityService.GetRequiredTagItem(speciesKey)
    if not itemName then
        return true, nil
    end

    local success = Bridge.Inventory.RemoveItem(source, itemName, 1)
    return success == true, itemName
end

function LegalityService.ResolveHarvest(source, carcass)
    local species = DDHunting.Data.GetSpecies(carcass.species)
    local result = {
        legal = true,
        reasons = {},
        requiredLicense = nil,
        licenseSatisfied = true,
        licenseTierUsed = nil,
        requiresTag = false,
        tagItem = nil,
        tagSatisfied = true,
        tagConsumed = false,
        protectedSpecies = false,
        restrictedZone = false,
        restrictedZoneName = nil,
        legalHours = true,
    }

    if not species then
        result.legal = false
        result.reasons[#result.reasons + 1] = 'invalid_species'
        return result
    end

    result.requiredLicense = LegalityService.GetRequiredLicense(carcass.species)
    result.requiresTag = species.legalityData and species.legalityData.requiresTag == true or false
    result.protectedSpecies = species.protected == true

    if result.protectedSpecies then
        result.legal = false
        result.reasons[#result.reasons + 1] = 'protected_species'
    end

    local insideRestricted, restrictedZoneName = isInsideRestrictedZone(carcass.coords)
    result.restrictedZone = insideRestricted
    result.restrictedZoneName = restrictedZoneName

    if insideRestricted then
        result.legal = false
        result.reasons[#result.reasons + 1] = 'restricted_zone'
    end

    local legalityCfg = DDHunting.Config.Legality or {}
    local hoursCfg = legalityCfg.Hours or {}

    if legalityCfg.UseTimeRestrictions ~= false and hoursCfg.NightHuntingAllowed == false then
        local hour = currentHour()
        local legalStart = hoursCfg.LegalStart or 5
        local legalEnd = hoursCfg.LegalEnd or 22

        if hour < legalStart or hour > legalEnd then
            result.legal = false
            result.legalHours = false
            result.reasons[#result.reasons + 1] = 'illegal_hours'
        end
    end

    local hasLicense, tierUsed = LegalityService.HasLicense(source, result.requiredLicense)
    result.licenseSatisfied = hasLicense
    result.licenseTierUsed = tierUsed

    if not hasLicense then
        result.legal = false
        result.reasons[#result.reasons + 1] = 'no_license'
    end

    if result.requiresTag then
        local hasTag, tagItem = LegalityService.HasTag(source, carcass.species)
        result.tagItem = tagItem
        result.tagSatisfied = hasTag

        if not hasTag then
            result.legal = false
            result.reasons[#result.reasons + 1] = 'no_tag'
        end
    end

    if result.legal and result.requiresTag then
        local consumed = LegalityService.ConsumeTag(source, carcass.species)
        result.tagConsumed = consumed == true

        if not result.tagConsumed then
            result.legal = false
            result.reasons[#result.reasons + 1] = 'tag_consume_failed'
        end
    end

    return result
end
