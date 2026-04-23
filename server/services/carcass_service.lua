local Server = DDHunting.Server
local State = Server.State
local Bridge = Server.Bridge

local CarcassService = {}
Server.Services.Carcass = CarcassService

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][carcass] %s'):format(msg))
    end
end

local function sanitizeCoords(coords)
    return vec3(
        (coords.x or 0.0) + 0.0,
        (coords.y or 0.0) + 0.0,
        (coords.z or 0.0) + 0.0
    )
end

local function round(value, decimals)
    local power = 10 ^ (decimals or 0)
    return math.floor((value * power) + 0.5) / power
end

local function getSpecies(speciesKey)
    return DDHunting.Data.GetSpecies(speciesKey)
end

local function itemExistsAndCarry(source, itemName, count, metadata)
    count = math.max(1, math.floor(tonumber(count) or 1))
    return Bridge.Inventory.CanCarryItem(source, itemName, count, metadata)
end

function CarcassService.Get(carcassId)
    return State.Carcasses.active[carcassId]
end

function CarcassService.GetAll()
    return State.Carcasses.active
end

function CarcassService.CountAll()
    return State.Carcasses.total or 0
end

function CarcassService.GetByWildlifeId(wildlifeId)
    for _, carcass in pairs(State.Carcasses.active) do
        if carcass.sourceWildlifeId == wildlifeId then
            return carcass
        end
    end

    return nil
end

function CarcassService.BuildRecordFromWildlife(wildlife, payload)
    payload = payload or {}

    local record = DDHunting.Data.ItemMetadata.CreateCarcass(wildlife.species, {
        qualityScore = payload.qualityScore or 72,
        freshness = payload.freshness or 100,
        sex = wildlife.sex,
        ageClass = wildlife.ageClass,
        variant = wildlife.variant,
        weight = wildlife.weight,
        trophyScore = wildlife.trophyScore,
        zone = wildlife.zone,
        legal = payload.legal ~= false,
        weapon = payload.weapon or 'unknown',
        shotRegion = payload.shotRegion or 'unknown',
        cleanKill = payload.cleanKill == true,
        killerServerId = payload.killerServerId,
        harvestedAt = os.time(),
    })

    record.id = State.NextCarcassId()
    record.sourceWildlifeId = wildlife.id
    record.coords = sanitizeCoords(payload.coords or wildlife.coords)
    record.heading = payload.heading or wildlife.heading or 0.0
    record.harvested = false
    record.boundEntityNetId = payload.boundEntityNetId
    record.actionState = {
        inspected = false,
        harvested = false,
    }

    return record
end

function CarcassService.CreateFromWildlife(wildlife, payload)
    if not wildlife then
        return nil, 'invalid_wildlife'
    end

    if CarcassService.GetByWildlifeId(wildlife.id) then
        return nil, 'carcass_already_exists'
    end

    local record = CarcassService.BuildRecordFromWildlife(wildlife, payload)
    State.Carcasses.active[record.id] = record
    State.Carcasses.total += 1

    debugPrint(('created carcass #%s from wildlife #%s'):format(record.id, wildlife.id))
    return record
end

function CarcassService.Remove(carcassId, reason)
    local carcass = CarcassService.Get(carcassId)
    if not carcass then
        return false, 'not_found'
    end

    State.Carcasses.active[carcassId] = nil
    State.Carcasses.total = math.max(0, State.Carcasses.total - 1)

    debugPrint(('removed carcass #%s (%s)'):format(carcassId, reason or 'no_reason'))
    return true
end

function CarcassService.BuildRewardItems(carcass)
    local species = getSpecies(carcass.species)
    if not species then
        return {}, 'invalid_species'
    end

    local rewards = {}
    local meatMin = species.harvest.meatMin or 1
    local meatMax = species.harvest.meatMax or meatMin
    local meatCount = math.random(meatMin, meatMax)

    rewards[#rewards + 1] = {
        item = 'raw_meat',
        count = 1,
        metadata = DDHunting.Data.ItemMetadata.CreateMeat(carcass.species, {
            qualityScore = carcass.qualityScore,
            freshness = carcass.freshness,
            sex = carcass.sex,
            ageClass = carcass.ageClass,
            variant = carcass.variant,
            weight = carcass.weight,
            trophyScore = carcass.trophyScore,
            zone = carcass.zone,
            legal = carcass.legal,
            weapon = carcass.weapon,
            shotRegion = carcass.shotRegion,
            cleanKill = carcass.cleanKill,
            killerServerId = carcass.killerServerId,
            quantity = meatCount,
            weightKg = round(math.max(1.0, carcass.weight * 0.18), 2),
        })
    }

    if species.harvest.pelt then
        rewards[#rewards + 1] = {
            item = 'animal_pelt',
            count = 1,
            metadata = DDHunting.Data.ItemMetadata.CreatePelt(carcass.species, carcass)
        }
    end

    local partType
    if species.harvest.antlers then
        partType = 'antlers'
    elseif species.harvest.tusk then
        partType = 'tusk'
    elseif species.harvest.fang then
        partType = 'fang'
    elseif species.harvest.claw then
        partType = 'claw'
    end

    if partType then
        local partMeta = DDHunting.Data.ItemMetadata.CreatePart(carcass.species, partType, carcass)
        if partMeta then
            rewards[#rewards + 1] = {
                item = 'animal_part',
                count = 1,
                metadata = partMeta
            }
        end
    end

    if species.harvest.trophy and carcass.trophyScore and carcass.trophyScore > 0 then
        local trophyMeta = DDHunting.Data.ItemMetadata.CreateTrophy(carcass.species, carcass)
        if trophyMeta then
            rewards[#rewards + 1] = {
                item = 'animal_trophy',
                count = 1,
                metadata = trophyMeta
            }
        end
    end

    return rewards
end

function CarcassService.CanHarvest(source, carcassId)
    local carcass = CarcassService.Get(carcassId)
    if not carcass then
        return false, 'not_found'
    end

    if carcass.harvested then
        return false, 'already_harvested'
    end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return false, 'invalid_player'
    end

    local playerCoords = GetEntityCoords(ped)
    local dist = #(playerCoords - carcass.coords)

    if dist > 4.0 then
        return false, 'too_far'
    end

    return true, carcass
end

function CarcassService.Harvest(source, carcassId)
    local allowed, carcassOrReason = CarcassService.CanHarvest(source, carcassId)
    if not allowed then
        return false, carcassOrReason
    end

    local carcass = carcassOrReason
    local rewards, rewardErr = CarcassService.BuildRewardItems(carcass)

    if not rewards then
        return false, rewardErr or 'reward_build_failed'
    end

    for i = 1, #rewards do
        local reward = rewards[i]
        if not itemExistsAndCarry(source, reward.item, reward.count, reward.metadata) then
            return false, 'inventory_full'
        end
    end

    for i = 1, #rewards do
        local reward = rewards[i]
        local success = Bridge.Inventory.AddItem(source, reward.item, reward.count, reward.metadata)
        if not success then
            return false, 'failed_to_add_reward'
        end
    end

    carcass.harvested = true
    carcass.actionState.harvested = true

    CarcassService.Remove(carcassId, 'harvest_complete')
    return true, rewards
end

function CarcassService.Snapshot()
    local payload = {}

    for _, record in pairs(State.Carcasses.active) do
        payload[#payload + 1] = {
            id = record.id,
            sourceWildlifeId = record.sourceWildlifeId,
            species = record.species,
            speciesLabel = record.speciesLabel,
            coords = {
                x = record.coords.x + 0.0,
                y = record.coords.y + 0.0,
                z = record.coords.z + 0.0,
            },
            zone = record.zone,
            sex = record.sex,
            ageClass = record.ageClass,
            variant = record.variant,
            weight = record.weight,
            trophyScore = record.trophyScore,
            quality = record.quality,
            qualityScore = record.qualityScore,
            freshness = record.freshness,
            freshnessLabel = record.freshnessLabel,
            legal = record.legal,
            harvested = record.harvested,
            actionState = record.actionState,
        }
    end

    return payload
end
