local Server = DDHunting.Server
local Bridge = Server.Bridge

local ProcessingService = {}
Server.Services.Processing = ProcessingService

local function floor(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function getBenchConfig(benchKey)
    return DDHunting.Config.Processing
        and DDHunting.Config.Processing.Benches
        and DDHunting.Config.Processing.Benches[benchKey]
end

local function getRecipes(benchKey)
    return DDHunting.Data.Crafting and DDHunting.Data.Crafting[benchKey]
end

local function getRecipe(benchKey, recipeKey)
    local recipes = getRecipes(benchKey)
    return recipes and recipes[recipeKey]
end

local function getItems(source)
    return Bridge.Inventory.GetInventoryItems(source) or {}
end

local function countItem(source, itemName)
    return Bridge.Inventory.GetItemCount(source, itemName) or 0
end

local function getDominantValue(counter)
    local bestKey, bestCount

    for key, value in pairs(counter) do
        if not bestCount or value > bestCount then
            bestKey = key
            bestCount = value
        end
    end

    return bestKey
end

local function collectMetadataForRecipe(source, recipe, craftCount)
    local inventory = getItems(source)
    local needed = {}

    for i = 1, #recipe.inputs do
        local input = recipe.inputs[i]
        needed[input.item] = (needed[input.item] or 0) + (input.count * craftCount)
    end

    local gathered = {}
    local qualityTotal = 0
    local qualityCount = 0
    local freshnessTotal = 0
    local freshnessCount = 0
    local weightTotal = 0
    local weightCount = 0
    local trophyTotal = 0
    local trophyCount = 0

    local speciesCounts = {}
    local variantCounts = {}
    local partTypeCounts = {}
    local legalAll = true

    for _, item in pairs(inventory) do
        if item and item.name and needed[item.name] and needed[item.name] > 0 then
            local take = math.min(needed[item.name], item.count or 0)
            if take > 0 then
                local meta = item.metadata or {}
                gathered[#gathered + 1] = {
                    item = item.name,
                    slot = item.slot,
                    count = take,
                    metadata = meta,
                }

                needed[item.name] = needed[item.name] - take

                if meta.qualityScore then
                    qualityTotal = qualityTotal + (tonumber(meta.qualityScore) or 0)
                    qualityCount = qualityCount + 1
                end

                if meta.freshness then
                    freshnessTotal = freshnessTotal + (tonumber(meta.freshness) or 0)
                    freshnessCount = freshnessCount + 1
                end

                if meta.weight then
                    weightTotal = weightTotal + (tonumber(meta.weight) or 0)
                    weightCount = weightCount + 1
                end

                if meta.trophyScore then
                    trophyTotal = trophyTotal + (tonumber(meta.trophyScore) or 0)
                    trophyCount = trophyCount + 1
                end

                if meta.species then
                    speciesCounts[meta.species] = (speciesCounts[meta.species] or 0) + 1
                end

                if meta.variant then
                    variantCounts[meta.variant] = (variantCounts[meta.variant] or 0) + 1
                end

                if meta.partType then
                    partTypeCounts[meta.partType] = (partTypeCounts[meta.partType] or 0) + 1
                end

                if meta.legal == false then
                    legalAll = false
                end
            end
        end
    end

    for itemName, remaining in pairs(needed) do
        if remaining > 0 then
            return nil, ('missing_%s'):format(itemName)
        end
    end

    return {
        sourceItems = gathered,
        species = getDominantValue(speciesCounts),
        variant = getDominantValue(variantCounts) or 'normal',
        partType = getDominantValue(partTypeCounts),
        qualityScore = qualityCount > 0 and floor(qualityTotal / qualityCount) or 60,
        freshness = freshnessCount > 0 and floor(freshnessTotal / freshnessCount) or 100,
        weight = weightCount > 0 and (weightTotal / weightCount) or 0,
        trophyScore = trophyCount > 0 and (trophyTotal / trophyCount) or 0,
        legal = legalAll,
    }
end

local function buildOutputMetadata(outputItem, aggregate, benchKey, recipeKey)
    local speciesKey = aggregate.species or 'deer'
    local payload = {
        qualityScore = aggregate.qualityScore,
        freshness = aggregate.freshness,
        variant = aggregate.variant,
        weight = aggregate.weight,
        trophyScore = aggregate.trophyScore,
        legal = aggregate.legal,
    }

    if outputItem == 'trimmed_meat' or outputItem == 'premium_cut' or outputItem == 'boxed_game_meat' or outputItem == 'contraband_meat' then
        local metadata = DDHunting.Data.ItemMetadata.CreateMeat(speciesKey, payload)
        metadata.cutType = recipeKey
        metadata.processedAt = os.time()
        metadata.processBench = benchKey
        return metadata
    end

    if outputItem == 'salted_pelt' or outputItem == 'treated_pelt' or outputItem == 'animal_pelt' or outputItem == 'protected_pelt' then
        local metadata = DDHunting.Data.ItemMetadata.CreatePelt(speciesKey, payload)
        if metadata then
            metadata.processStage = recipeKey
            metadata.processedAt = os.time()
            metadata.processBench = benchKey
        end
        return metadata
    end

    if outputItem == 'mounted_trophy' or outputItem == 'animal_trophy' then
        local metadata = DDHunting.Data.ItemMetadata.CreateTrophy(speciesKey, payload)
        if metadata then
            metadata.mounted = outputItem == 'mounted_trophy'
            metadata.processedAt = os.time()
            metadata.processBench = benchKey
        end
        return metadata
    end

    if outputItem == 'falsified_tag' then
        return {
            itemType = 'contraband',
            forged = true,
            forgedAt = os.time(),
            forgedBench = benchKey,
            species = speciesKey,
        }
    end

    return nil
end

function ProcessingService.GetBenchCatalog(source, benchKey)
    local bench = getBenchConfig(benchKey)
    if not bench then
        return nil, 'invalid_bench'
    end

    local recipes = getRecipes(benchKey)
    if not recipes then
        return nil, 'invalid_bench'
    end

    local catalog = {}

    for recipeKey, recipe in pairs(recipes) do
        local maxCraftable = nil

        for i = 1, #recipe.inputs do
            local input = recipe.inputs[i]
            local available = countItem(source, input.item)
            local craftable = math.floor(available / input.count)

            if maxCraftable == nil or craftable < maxCraftable then
                maxCraftable = craftable
            end
        end

        maxCraftable = math.max(0, math.min(maxCraftable or 0, bench.maxBatch or 1))

        local fee = floor((bench.baseFee or 0) * (recipe.feeMultiplier or 1.0))

        catalog[#catalog + 1] = {
            key = recipeKey,
            label = recipe.label or recipeKey,
            outputItem = recipe.output.item,
            outputCount = recipe.output.count,
            inputs = recipe.inputs,
            maxCraftable = maxCraftable,
            fee = fee,
            account = bench.account or 'money',
            timeMs = recipe.timeMs or 3500,
        }
    end

    table.sort(catalog, function(a, b)
        return a.label < b.label
    end)

    return {
        benchKey = benchKey,
        benchLabel = bench.label,
        benchAccount = bench.account or 'money',
        catalog = catalog,
    }
end

function ProcessingService.ProcessRecipe(source, benchKey, recipeKey, craftCount)
    local bench = getBenchConfig(benchKey)
    if not bench then
        return false, 'invalid_bench'
    end

    local recipe = getRecipe(benchKey, recipeKey)
    if not recipe then
        return false, 'invalid_recipe'
    end

    craftCount = math.max(1, math.floor(tonumber(craftCount) or 1))
    craftCount = math.min(craftCount, bench.maxBatch or craftCount)

    for i = 1, #recipe.inputs do
        local input = recipe.inputs[i]
        local required = input.count * craftCount
        local available = countItem(source, input.item)

        if available < required then
            return false, ('missing_%s'):format(input.item)
        end
    end

    local fee = floor((bench.baseFee or 0) * (recipe.feeMultiplier or 1.0) * craftCount)
    local account = bench.account or 'money'

    local removedFunds, fundReason = Bridge.ESX.RemoveMoney(source, account, fee, 'dd-hunting processing fee')
    if not removedFunds then
        return false, fundReason or 'insufficient_funds'
    end

    local aggregate, aggregateErr = collectMetadataForRecipe(source, recipe, craftCount)
    if not aggregate then
        Bridge.ESX.AddMoney(source, account, fee, 'dd-hunting processing refund')
        return false, aggregateErr or 'aggregate_failed'
    end

    local outputMetadata = buildOutputMetadata(recipe.output.item, aggregate, benchKey, recipeKey)

    local outputCount = (recipe.output.count or 1) * craftCount
    if not Bridge.Inventory.CanCarryItem(source, recipe.output.item, outputCount, outputMetadata) then
        Bridge.ESX.AddMoney(source, account, fee, 'dd-hunting processing refund')
        return false, 'inventory_full'
    end

    for i = 1, #recipe.inputs do
        local input = recipe.inputs[i]
        local success = Bridge.Inventory.RemoveItem(source, input.item, input.count * craftCount)

        if not success then
            Bridge.ESX.AddMoney(source, account, fee, 'dd-hunting processing refund')
            return false, 'failed_to_remove_inputs'
        end
    end

    local added = Bridge.Inventory.AddItem(source, recipe.output.item, outputCount, outputMetadata)
    if not added then
        Bridge.ESX.AddMoney(source, account, fee, 'dd-hunting processing refund')
        return false, 'failed_to_add_output'
    end

    return true, {
        benchLabel = bench.label,
        recipeLabel = recipe.label or recipeKey,
        outputItem = recipe.output.item,
        outputCount = outputCount,
        fee = fee,
        account = account,
        species = aggregate.species,
        quality = outputMetadata and outputMetadata.quality,
    }
end
