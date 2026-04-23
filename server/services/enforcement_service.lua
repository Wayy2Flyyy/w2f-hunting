local Server = DDHunting.Server
local EnforcementService = {}
Server.Services.Enforcement = EnforcementService

local Persistence = Server.Services.Persistence
local Evidence = Server.Services.Evidence
local Bridge = Server.Bridge

local function getIdentifier(source)
    return Bridge.ESX.GetIdentifier(source) or ('src:%s'):format(source)
end

local lastAlertByIdentifier = {}

local AlertWeights = {
    protected_species = 32,
    no_license = 20,
    no_tag = 15,
    restricted_zone = 18,
    illegal_hours = 12,
    black_market = 16,
    illegal_bait = 11,
    forged_tag = 14,
}

function EnforcementService.RecordViolation(source, violationType, metadata)
    local identifier = getIdentifier(source)
    local weight = AlertWeights[violationType] or 8
    local now = os.time()

    local alertState = lastAlertByIdentifier[identifier] or { score = 0, lastAt = 0 }
    if (now - alertState.lastAt) < 20 then
        weight = math.floor(weight * 0.5)
    end

    alertState.lastAt = now
    alertState.score = math.min(100, (alertState.score or 0) + weight)
    lastAlertByIdentifier[identifier] = alertState

    local progressionService = Server.Services.Progression
    if progressionService and progressionService.AddReputation then
        progressionService.AddReputation(source, 'ranger_heat', weight, {
            crimeType = violationType,
            metadata = metadata,
            alertScore = alertState.score,
        })
    end

    Persistence.InsertEnforcementLog(identifier, violationType, weight, alertState.score, metadata or {})

    if violationType == 'black_market' or violationType == 'forged_tag' then
        Evidence.Record(identifier, 'wildlife_evidence', {
            violationType = violationType,
            alertScore = alertState.score,
            metadata = metadata,
        })
    end

    local inspectionChance = math.min(0.85, 0.08 + (alertState.score / 130.0))
    local rolledInspection = math.random() <= inspectionChance

    return {
        identifier = identifier,
        alertScore = alertState.score,
        addedWeight = weight,
        inspectionChance = inspectionChance,
        inspectionTriggered = rolledInspection,
    }
end

function EnforcementService.ProcessInspection(source, context)
    local result = {
        seized = {},
        fine = 0,
        inspectionTriggered = false,
    }

    if not context or context.inspectionTriggered ~= true then
        return result
    end

    result.inspectionTriggered = true
    result.seized = Evidence.SeizeIllegalItems(source)

    local fines = DDHunting.Config.Legality and DDHunting.Config.Legality.Fines or {}
    local totalFine = 0

    if #result.seized > 0 then
        totalFine = totalFine + (fines.BlackMarketSale or 3500)
    end

    if context.alertScore and context.alertScore >= 60 then
        totalFine = totalFine + (fines.NoLicense or 2500)
    end

    if totalFine > 0 then
        Bridge.ESX.RemoveMoney(source, 'money', totalFine, 'dd-hunting ranger fine')
    end

    result.fine = totalFine

    return result
end
