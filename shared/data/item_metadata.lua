function Meta.CreateLicense(tier, payload)
    payload = payload or {}

    local durations = DDHunting.Config.Legality
        and DDHunting.Config.Legality.Licenses
        and DDHunting.Config.Legality.Licenses[tier]

    local durationDays = durations and durations.DurationDays or 7
    local issuedAt = os.time()
    local expiresAt = issuedAt + (durationDays * 86400)

    return {
        serial = payload.serial or serial('LIC'),
        itemType = 'license',
        tier = tier,
        issuedAt = issuedAt,
        expiresAt = expiresAt,
        ownerIdentifier = payload.ownerIdentifier,
        ownerServerId = payload.ownerServerId,
    }
end

function Meta.IsExpired(metadata)
    if type(metadata) ~= 'table' then
        return false
    end

    if not metadata.expiresAt then
        return false
    end

    return os.time() > tonumber(metadata.expiresAt)
end
