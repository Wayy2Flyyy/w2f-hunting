local Server = DDHunting.Server
local EvidenceService = {}
Server.Services.Evidence = EvidenceService

local Persistence = Server.Services.Persistence

function EvidenceService.Record(identifier, evidenceType, metadata)
    if not identifier or not evidenceType then
        return false, 'invalid_args'
    end

    Persistence.InsertEvidence(identifier, evidenceType, metadata or {})
    return true
end

function EvidenceService.RecordBySource(source, evidenceType, metadata)
    local identifier = Server.Bridge.ESX.GetIdentifier(source) or ('src:%s'):format(source)
    return EvidenceService.Record(identifier, evidenceType, metadata)
end

function EvidenceService.SeizeIllegalItems(source, evidenceTypes)
    evidenceTypes = evidenceTypes or {
        contraband_meat = true,
        protected_pelt = true,
        falsified_tag = true,
        wildlife_evidence = true,
    }

    local removed = {}
    local items = Server.Bridge.Inventory.GetInventoryItems(source)

    for _, item in pairs(items) do
        if item and item.name and evidenceTypes[item.name] and (item.count or 0) > 0 then
            local ok = Server.Bridge.Inventory.RemoveItem(source, item.name, item.count, item.metadata, item.slot)
            if ok then
                removed[#removed + 1] = {
                    item = item.name,
                    count = item.count,
                    metadata = item.metadata,
                }
            end
        end
    end

    return removed
end
