local Server = DDHunting.Server
local ContractService = {}
Server.Services.Contracts = ContractService

local Bridge = Server.Bridge
local State = Server.State
local Persistence = Server.Services.Persistence

State.Contracts = State.Contracts or {
    activeByIdentifier = {},
    boardOffers = {},
    boardRefreshedAt = {},
}

local function now()
    return os.time()
end

local function randomFrom(list)
    if type(list) ~= 'table' or #list == 0 then
        return nil
    end
    return list[math.random(1, #list)]
end

local function weightedTier()
    local tiers = DDHunting.Config.Contracts.DifficultyTiers or {}
    local total = 0
    for _, v in pairs(tiers) do
        total = total + (v.weight or 0)
    end

    local roll = math.random() * math.max(1, total)
    local running = 0
    for key, v in pairs(tiers) do
        running = running + (v.weight or 0)
        if roll <= running then
            return key, v
        end
    end

    return 't1', tiers.t1 or { payoutMult = 1.0, xpMult = 1.0, repMult = 1.0 }
end

local function getIdentifier(source)
    return Bridge.ESX.GetIdentifier(source) or ('src:%s'):format(source)
end

local function serializeContract(contract)
    return {
        id = contract.id,
        board = contract.board,
        contractType = contract.contractType,
        label = contract.label,
        tier = contract.tier,
        item = contract.item,
        species = contract.species,
        quantity = contract.quantity,
        requirements = contract.requirements,
        rewards = contract.rewards,
        expiresAt = contract.expiresAt,
        acceptedAt = contract.acceptedAt,
        status = contract.status,
        progress = contract.progress,
    }
end

local function buildRewards(pool, tier)
    local tierCfg = DDHunting.Config.Contracts.DifficultyTiers[tier]
    return {
        payout = math.floor((pool.basePayout or 500) * (tierCfg.payoutMult or 1.0)),
        xp = math.floor((pool.baseXP or 60) * (tierCfg.xpMult or 1.0)),
        repType = pool.repType,
        rep = math.floor((pool.baseRep or 8) * (tierCfg.repMult or 1.0)),
        heatDelta = pool.heatDeltaOnComplete,
    }
end

local function buildRequirements(pool)
    local req = {}
    req.qualityMin = pool.quality and math.random(pool.quality.min, pool.quality.max) or nil
    req.freshnessMin = pool.freshness and math.random(pool.freshness.min, pool.freshness.max) or nil
    req.trophyScoreMin = pool.trophyScore and math.random(pool.trophyScore.min, pool.trophyScore.max) or nil
    req.variant = randomFrom(pool.variant)
    req.partType = randomFrom(pool.partTypePool)
    req.legalRequired = pool.legalRequired
    return req
end

local function buildContract(boardKey)
    local board = DDHunting.Config.Contracts.Boards[boardKey]
    if not board then return nil end

    local contractType = randomFrom(board.contractTypes)
    local pool = DDHunting.Config.Contracts.TypePools[contractType]
    if not pool then return nil end

    local tier, _ = weightedTier()
    local durationRange = pool.timeLimitMinutes or { min = DDHunting.Config.Contracts.DefaultDurationMinutes, max = DDHunting.Config.Contracts.DefaultDurationMinutes }
    local duration = math.random(durationRange.min, durationRange.max)

    local contract = {
        id = ('C%s%s'):format(now(), math.random(1000, 9999)),
        board = boardKey,
        contractType = contractType,
        label = pool.label,
        tier = tier,
        item = randomFrom(pool.itemPool),
        species = randomFrom(pool.speciesPool),
        quantity = math.random(pool.quantity.min, pool.quantity.max),
        requirements = buildRequirements(pool),
        rewards = buildRewards(pool, tier),
        createdAt = now(),
        acceptedAt = 0,
        expiresAt = now() + (duration * 60),
        status = 'offered',
        progress = { delivered = 0 },
    }

    return contract
end

local function refreshBoard(boardKey)
    State.Contracts.boardOffers[boardKey] = {}
    State.Contracts.boardRefreshedAt[boardKey] = now()

    for _ = 1, 6 do
        local generated = buildContract(boardKey)
        if generated then
            State.Contracts.boardOffers[boardKey][#State.Contracts.boardOffers[boardKey] + 1] = generated
        end
    end
end

local function ensureBoard(boardKey)
    local offers = State.Contracts.boardOffers[boardKey]
    local refreshMinutes = DDHunting.Config.Contracts.RefreshIntervalMinutes or 45
    local needRefresh = (not offers)
        or (#offers == 0)
        or (now() - (State.Contracts.boardRefreshedAt[boardKey] or 0) >= refreshMinutes * 60)

    if needRefresh then
        refreshBoard(boardKey)
    end

    return State.Contracts.boardOffers[boardKey]
end

local function saveActiveContract(identifier, contract)
    Persistence.UpsertActiveContract(identifier, contract.id, contract.status, contract.expiresAt, contract)
end

local function contractMatchesItem(contract, item)
    if not item or item.name ~= contract.item then
        return false
    end

    local meta = item.metadata or {}
    if contract.species and meta.species ~= contract.species then
        return false
    end

    local req = contract.requirements or {}

    if req.qualityMin and (tonumber(meta.qualityScore) or 0) < req.qualityMin then
        return false
    end

    if req.freshnessMin and (tonumber(meta.freshness) or 0) < req.freshnessMin then
        return false
    end

    if req.trophyScoreMin and (tonumber(meta.trophyScore) or 0) < req.trophyScoreMin then
        return false
    end

    if req.partType and meta.partType ~= req.partType then
        return false
    end

    if req.variant and req.variant ~= 'normal' and meta.variant ~= req.variant then
        return false
    end

    if req.legalRequired == true and meta.legal == false then
        return false
    end

    return true
end

local function findDeliverableSlots(source, contract)
    local items = Bridge.Inventory.GetInventoryItems(source)
    local needed = contract.quantity
    local slots = {}

    for _, item in pairs(items) do
        if needed <= 0 then break end
        if contractMatchesItem(contract, item) then
            local take = math.min(needed, item.count or 0)
            if take > 0 then
                slots[#slots + 1] = {
                    slot = item.slot,
                    count = take,
                    item = item,
                }
                needed = needed - take
            end
        end
    end

    return slots, needed <= 0
end

local function completeContract(source, profile, contract)
    local payoutAccount = (DDHunting.Config.Contracts.Boards[contract.board] or {}).payoutAccount or 'money'
    Bridge.ESX.AddMoney(source, payoutAccount, contract.rewards.payout, 'dd-hunting contract reward')

    local progressionService = Server.Services.Progression
    progressionService.AddXP(source, contract.rewards.xp, 'contract_complete')
    if contract.rewards.repType then
        progressionService.AddReputation(source, contract.rewards.repType, contract.rewards.rep)
    end

    if contract.rewards.heatDelta and contract.rewards.heatDelta > 0 then
        progressionService.AddReputation(source, 'ranger_heat', contract.rewards.heatDelta, {
            crimeType = 'illegal_contract_complete',
            contractId = contract.id,
        })
    end

    contract.status = 'completed'
    contract.completedAt = now()

    Persistence.ArchiveContract(profile.identifier, contract.id, 'completed', contract)
    Persistence.DeleteActiveContract(profile.identifier, contract.id)

    return {
        payout = contract.rewards.payout,
        xp = contract.rewards.xp,
        repType = contract.rewards.repType,
        rep = contract.rewards.rep,
    }
end

function ContractService.LoadPlayer(source)
    local identifier = getIdentifier(source)
    if not State.Contracts.activeByIdentifier[identifier] then
        State.Contracts.activeByIdentifier[identifier] = {}

        local rows = Persistence.LoadActiveContracts(identifier)
        for i = 1, #rows do
            local ok, contract = pcall(json.decode, rows[i].contract_json or '{}')
            if ok and type(contract) == 'table' then
                contract.status = rows[i].status
                contract.expiresAt = tonumber(rows[i].expires_at) or contract.expiresAt
                State.Contracts.activeByIdentifier[identifier][contract.id] = contract
            end
        end
    end

    return State.Contracts.activeByIdentifier[identifier]
end

function ContractService.GetBoardOffers(source, boardKey)
    local offers = ensureBoard(boardKey)
    local serialized = {}

    for i = 1, #offers do
        serialized[#serialized + 1] = serializeContract(offers[i])
    end

    return serialized
end

function ContractService.GetActiveContracts(source)
    local active = ContractService.LoadPlayer(source)
    local list = {}

    for _, contract in pairs(active) do
        if contract.status == 'active' then
            if contract.expiresAt and contract.expiresAt < now() then
                contract.status = 'failed'
                Persistence.ArchiveContract(getIdentifier(source), contract.id, 'failed', contract)
                Persistence.DeleteActiveContract(getIdentifier(source), contract.id)
                active[contract.id] = nil
            else
                list[#list + 1] = serializeContract(contract)
            end
        end
    end

    return list
end

function ContractService.Accept(source, boardKey, contractId)
    local identifier = getIdentifier(source)
    local active = ContractService.LoadPlayer(source)

    local activeCount = 0
    for _, c in pairs(active) do
        if c.status == 'active' then
            activeCount = activeCount + 1
        end
    end

    if activeCount >= (DDHunting.Config.Contracts.MaxActivePerPlayer or 4) then
        return false, 'active_limit_reached'
    end

    local offers = ensureBoard(boardKey)
    local selected
    for i = 1, #offers do
        if offers[i].id == contractId then
            selected = offers[i]
            table.remove(offers, i)
            break
        end
    end

    if not selected then
        return false, 'contract_not_found'
    end

    selected.status = 'active'
    selected.acceptedAt = now()
    active[selected.id] = selected

    saveActiveContract(identifier, selected)
    return true, serializeContract(selected)
end

function ContractService.Abandon(source, contractId)
    local identifier = getIdentifier(source)
    local active = ContractService.LoadPlayer(source)
    local contract = active[contractId]

    if not contract or contract.status ~= 'active' then
        return false, 'contract_not_active'
    end

    contract.status = 'failed'
    contract.failedAt = now()

    Persistence.ArchiveContract(identifier, contract.id, 'failed', contract)
    Persistence.DeleteActiveContract(identifier, contract.id)
    active[contractId] = nil

    local progressionService = Server.Services.Progression
    progressionService.AddReputation(source, 'legal', -3)
    return true
end

function ContractService.TurnIn(source, contractId)
    local identifier = getIdentifier(source)
    local active = ContractService.LoadPlayer(source)
    local contract = active[contractId]

    if not contract or contract.status ~= 'active' then
        return false, 'contract_not_active'
    end

    if contract.expiresAt and contract.expiresAt < now() then
        contract.status = 'failed'
        Persistence.ArchiveContract(identifier, contract.id, 'failed', contract)
        Persistence.DeleteActiveContract(identifier, contract.id)
        active[contractId] = nil
        return false, 'contract_expired'
    end

    local slots, enough = findDeliverableSlots(source, contract)
    if not enough then
        return false, 'requirements_not_met'
    end

    for i = 1, #slots do
        local slotData = slots[i]
        Bridge.Inventory.RemoveItem(source, contract.item, slotData.count, slotData.item.metadata, slotData.slot)

        if slotData.item.metadata and slotData.item.metadata.legal == false then
            local evidenceService = Server.Services.Evidence
            evidenceService.RecordBySource(source, 'wildlife_evidence', {
                contractId = contract.id,
                board = contract.board,
                item = contract.item,
            })
        end
    end

    local reward = completeContract(source, { identifier = identifier }, contract)
    active[contractId] = nil

    if contract.board == 'black_market' then
        local enforcementService = Server.Services.Enforcement
        local enf = enforcementService.RecordViolation(source, 'black_market', {
            contractId = contract.id,
            contractType = contract.contractType,
        })
        local inspection = enforcementService.ProcessInspection(source, enf)
        reward.inspection = inspection
    end

    return true, reward
end

function ContractService.FailExpiredFor(source)
    local identifier = getIdentifier(source)
    local active = ContractService.LoadPlayer(source)

    for contractId, contract in pairs(active) do
        if contract.status == 'active' and contract.expiresAt and contract.expiresAt < now() then
            contract.status = 'failed'
            Persistence.ArchiveContract(identifier, contract.id, 'failed', contract)
            Persistence.DeleteActiveContract(identifier, contract.id)
            active[contractId] = nil
        end
    end
end


function ContractService.TryRefreshBoard(source, boardKey)
    if not DDHunting.Config.Contracts.Boards[boardKey] then
        return false, 'invalid_board'
    end

    local last = State.Contracts.boardRefreshedAt[boardKey] or 0
    local cooldown = DDHunting.Config.Contracts.BoardRefreshCooldownSeconds or 90
    if (now() - last) < cooldown then
        return false, 'refresh_cooldown'
    end

    refreshBoard(boardKey)
    return true
end
CreateThread(function()
    while true do
        Wait(60000)
        for _, src in ipairs(GetPlayers()) do
            ContractService.FailExpiredFor(tonumber(src))
        end
    end
end)

AddEventHandler('playerDropped', function()
    local identifier = getIdentifier(source)
    State.Contracts.activeByIdentifier[identifier] = nil
end)
