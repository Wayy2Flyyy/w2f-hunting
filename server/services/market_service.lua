local Server = DDHunting.Server
local State = Server.State
local Bridge = Server.Bridge

local MarketService = {}
Server.Services.Market = MarketService

local function floor(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function getSpeciesBaseValue(speciesKey)
    local base = DDHunting.Config.Economy
        and DDHunting.Config.Economy.BasePayouts
        and DDHunting.Config.Economy.BasePayouts[speciesKey]

    return tonumber(base) or 50
end

local function getQualityMultiplier(metadata)
    local quality = metadata and metadata.quality or 'standard'
    local mult = DDHunting.Config.Economy
        and DDHunting.Config.Economy.QualityMultipliers
        and DDHunting.Config.Economy.QualityMultipliers[quality]

    return tonumber(mult) or 1.0
end

local function getFreshnessMultiplier(metadata)
    local label = metadata and metadata.freshnessLabel or 'fresh'
    local mult = DDHunting.Config.Economy
        and DDHunting.Config.Economy.FreshnessMultipliers
        and DDHunting.Config.Economy.FreshnessMultipliers[label]

    return tonumber(mult) or 1.0
end

local function getVariantMultiplier(metadata)
    local variant = metadata and metadata.variant or 'normal'
    local mult = DDHunting.Config.Economy
        and DDHunting.Config.Economy.VariantMultipliers
        and DDHunting.Config.Economy.VariantMultipliers[variant]

    return tonumber(mult) or 1.0
end

local function getPartMultiplier(partType)
    local mult = DDHunting.Config.Economy
        and DDHunting.Config.Economy.PartMultipliers
        and DDHunting.Config.Economy.PartMultipliers[partType]

    return tonumber(mult) or 1.0
end

local function getIdentifier(source)
    return Bridge.ESX.GetIdentifier(source) or ('src:%s'):format(source)
end

local function getBuyerConfig(buyerKey)
    return DDHunting.Config.Market and DDHunting.Config.Market.Buyers and DDHunting.Config.Market.Buyers[buyerKey]
end

local function getVendorConfig(vendorKey)
    return DDHunting.Config.Market and DDHunting.Config.Market.Vendors and DDHunting.Config.Market.Vendors[vendorKey]
end

local function ensurePlayerState(source)
    local identifier = getIdentifier(source)

    if not State.MarketPlayers.byIdentifier[identifier] then
        State.MarketPlayers.byIdentifier[identifier] = {
            identifier = identifier,
            reputation = 0,
            totalSales = 0,
            totalEarned = 0,
            saleStreak = 0,
            lastSaleAt = 0,
        }
    end

    return State.MarketPlayers.byIdentifier[identifier]
end

local function getReputationTierData(reputation)
    local tiers = DDHunting.Config.Market and DDHunting.Config.Market.Grind and DDHunting.Config.Market.Grind.ReputationTiers or {}
    local result = { reputation = 0, multiplier = 1.0, label = 'Unknown' }

    for i = 1, #tiers do
        if reputation >= tiers[i].reputation then
            result = tiers[i]
        end
    end

    return result
end

local function getBulkMultiplier(units)
    local thresholds = DDHunting.Config.Market and DDHunting.Config.Market.Grind and DDHunting.Config.Market.Grind.BulkThresholds or {}
    local result = 1.0

    for i = 1, #thresholds do
        if units >= thresholds[i].units then
            result = thresholds[i].multiplier
        end
    end

    return result
end

local function getStreakMultiplier(playerState)
    local grind = DDHunting.Config.Market and DDHunting.Config.Market.Grind or {}
    local windowMinutes = grind.StreakWindowMinutes or 45
    local perSale = grind.StreakBonusPerSale or 0.015
    local maxBonus = grind.MaxStreakBonus or 0.18

    if not playerState.lastSaleAt or playerState.lastSaleAt <= 0 then
        return 1.0
    end

    if (os.time() - playerState.lastSaleAt) > (windowMinutes * 60) then
        playerState.saleStreak = 0
        return 1.0
    end

    local bonus = math.min(maxBonus, (playerState.saleStreak or 0) * perSale)
    return 1.0 + bonus
end

local function isIllegalMetadata(metadata)
    return metadata and metadata.legal == false
end

local function isAcceptedByBuyer(buyer, itemName, metadata)
    if not buyer or not buyer.acceptedItems then
        return false
    end

    if buyer.acceptedItems[itemName] then
        if buyer.type == 'legal' and isIllegalMetadata(metadata) then
            return false
        end

        return true
    end

    if buyer.type == 'illegal' and buyer.acceptsIllegalGeneric then
        if isIllegalMetadata(metadata) and (
            itemName == 'raw_meat' or
            itemName == 'animal_pelt' or
            itemName == 'animal_part' or
            itemName == 'animal_trophy'
        ) then
            return true
        end
    end

    return false
end

function MarketService.GetPlayerState(source)
    return ensurePlayerState(source)
end

function MarketService.GetBuyerPreview(source, buyerKey)
    local buyer = getBuyerConfig(buyerKey)
    if not buyer then
        return nil, 'invalid_buyer'
    end

    local items = Bridge.Inventory.GetInventoryItems(source)
    local playerState = ensurePlayerState(source)

    local lines = {}
    local subtotal = 0
    local units = 0

    for _, item in pairs(items) do
        if item and item.name and item.count and item.count > 0 then
            local metadata = item.metadata or {}

            if isAcceptedByBuyer(buyer, item.name, metadata) then
                local baseSpeciesValue = getSpeciesBaseValue(metadata.species)
                local price = 0

                if item.name == 'raw_meat' or item.name == 'contraband_meat' then
                    local quantity = tonumber(metadata.quantity) or 1
                    price = baseSpeciesValue * 0.18 * quantity
                    price = price * getQualityMultiplier(metadata) * getFreshnessMultiplier(metadata) * getVariantMultiplier(metadata)
                elseif item.name == 'animal_pelt' or item.name == 'protected_pelt' then
                    price = baseSpeciesValue * 0.82
                    price = price * getQualityMultiplier(metadata) * getVariantMultiplier(metadata)
                elseif item.name == 'animal_part' then
                    price = baseSpeciesValue * 0.55 * getPartMultiplier(metadata.partType)
                    price = price * getQualityMultiplier(metadata) * getVariantMultiplier(metadata)
                elseif item.name == 'animal_trophy' then
                    local trophyScale = 1.0 + math.min(1.25, (tonumber(metadata.trophyScore) or 0) / 220.0)
                    price = baseSpeciesValue * 1.15 * trophyScale
                    price = price * getQualityMultiplier(metadata) * getVariantMultiplier(metadata)
                elseif item.name == 'trimmed_meat' then
                    price = baseSpeciesValue * 0.24
                elseif item.name == 'premium_cut' then
                    price = baseSpeciesValue * 0.42
                elseif item.name == 'boxed_game_meat' then
                    price = baseSpeciesValue * 0.96
                elseif item.name == 'salted_pelt' then
                    price = baseSpeciesValue * 0.98
                elseif item.name == 'treated_pelt' then
                    price = baseSpeciesValue * 1.24
                elseif item.name == 'mounted_trophy' then
                    price = baseSpeciesValue * 2.10
                elseif item.name == 'falsified_tag' then
                    price = 950
                elseif item.name == 'poacher_trap' then
                    price = 1100
                elseif item.name == 'illegal_bait' then
                    price = 450
                elseif item.name == 'wildlife_evidence' then
                    price = 1350
                else
                    price = 0
                end

                price = floor(price)
                if price > 0 then
                    lines[#lines + 1] = {
                        slot = item.slot,
                        item = item.name,
                        count = item.count,
                        metadata = metadata,
                        label = item.label or item.name,
                        unitPrice = price,
                        totalPrice = price * item.count,
                    }

                    subtotal = subtotal + (price * item.count)
                    units = units + item.count
                end
            end
        end
    end

    local repTier = getReputationTierData(playerState.reputation)
    local repMult = repTier.multiplier
    local streakMult = getStreakMultiplier(playerState)
    local bulkMult = getBulkMultiplier(units)
    local buyerMult = buyer.buyerMultiplier or 1.0

    local finalTotal = floor(subtotal * repMult * streakMult * bulkMult * buyerMult)

    return {
        buyerKey = buyerKey,
        buyerLabel = buyer.label,
        buyerType = buyer.type,
        payoutAccount = buyer.payoutAccount,
        lines = lines,
        units = units,
        subtotal = subtotal,
        repMultiplier = repMult,
        streakMultiplier = streakMult,
        bulkMultiplier = bulkMult,
        buyerMultiplier = buyerMult,
        finalTotal = finalTotal,
        reputation = playerState.reputation,
        repLabel = repTier.label,
        saleStreak = playerState.saleStreak,
    }
end

function MarketService.SellAllToBuyer(source, buyerKey)
    local preview, err = MarketService.GetBuyerPreview(source, buyerKey)
    if not preview then
        return false, err
    end

    if #preview.lines == 0 then
        return false, 'nothing_to_sell'
    end

    for i = 1, #preview.lines do
        local line = preview.lines[i]
        local removed = Bridge.Inventory.RemoveItem(source, line.item, line.count, line.metadata, line.slot)
        if not removed then
            return false, 'failed_to_remove_item'
        end
    end

    local payoutAccount = preview.payoutAccount or 'money'
    local paid = Bridge.ESX.AddMoney(source, payoutAccount, preview.finalTotal, 'dd-hunting market sale')
    if not paid then
        return false, 'failed_to_pay_player'
    end

    local playerState = ensurePlayerState(source)
    local grind = DDHunting.Config.Market and DDHunting.Config.Market.Grind or {}

    playerState.totalSales = playerState.totalSales + 1
    playerState.totalEarned = playerState.totalEarned + preview.finalTotal

    if playerState.lastSaleAt > 0 and (os.time() - playerState.lastSaleAt) <= ((grind.StreakWindowMinutes or 45) * 60) then
        playerState.saleStreak = playerState.saleStreak + 1
    else
        playerState.saleStreak = 1
    end

    playerState.lastSaleAt = os.time()

    local repGain = preview.buyerType == 'illegal'
        and (grind.ReputationGain and grind.ReputationGain.IllegalSale or 4)
        or (grind.ReputationGain and grind.ReputationGain.LegalSale or 2)

    for i = 1, #preview.lines do
        if preview.lines[i].item == 'animal_trophy' or preview.lines[i].item == 'mounted_trophy' then
            repGain = repGain + (grind.ReputationGain and grind.ReputationGain.TrophySale or 8)
        end
    end

    if preview.units >= (grind.ReputationGain and grind.ReputationGain.BulkBonusAtUnits or 20) then
        repGain = repGain + (grind.ReputationGain and grind.ReputationGain.BulkBonusRep or 6)
    end

    playerState.reputation = playerState.reputation + repGain

    local resultInspection = nil

    local progressionService = Server.Services.Progression
    if progressionService and progressionService.RecordSale then
        progressionService.RecordSale(source, buyerKey, preview)
    end

    if preview.buyerType == 'illegal' then
        local evidenceService = Server.Services.Evidence
        if evidenceService then
            evidenceService.RecordBySource(source, 'wildlife_evidence', { buyerKey = buyerKey, units = preview.units, total = preview.finalTotal })
        end

        local enforcementService = Server.Services.Enforcement
        if enforcementService then
            local context = enforcementService.RecordViolation(source, 'black_market', { buyerKey = buyerKey, units = preview.units })
            local inspect = enforcementService.ProcessInspection(source, context)
            if inspect and inspect.inspectionTriggered then
                resultInspection = inspect
            end
        end
    end

    return true, {
        total = preview.finalTotal,
        payoutAccount = payoutAccount,
        units = preview.units,
        soldCount = #preview.lines,
        reputation = playerState.reputation,
        saleStreak = playerState.saleStreak,
        buyerLabel = preview.buyerLabel,
        buyerType = preview.buyerType,
        inspection = resultInspection,
    }
end

function MarketService.GetVendorCatalog(source, vendorKey)
    local vendor = getVendorConfig(vendorKey)
    if not vendor then
        return nil, 'invalid_vendor'
    end

    local catalog = {}
    for itemName, entry in pairs(vendor.items or {}) do
        catalog[#catalog + 1] = {
            item = itemName,
            label = entry.label or itemName,
            price = entry.price or 0,
            stack = entry.stack == true,
            maxQuantity = entry.maxQuantity or 1,
        }
    end

    table.sort(catalog, function(a, b)
        return a.price < b.price
    end)

    return {
        vendorKey = vendorKey,
        vendorLabel = vendor.label,
        vendorType = vendor.type,
        purchaseAccount = vendor.purchaseAccount or 'money',
        catalog = catalog,
    }
end

function MarketService.PurchaseFromVendor(source, vendorKey, itemName, quantity)
    local vendor = getVendorConfig(vendorKey)
    if not vendor then
        return false, 'invalid_vendor'
    end

    local entry = vendor.items and vendor.items[itemName]
    if not entry then
        return false, 'invalid_item'
    end

    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    quantity = math.min(quantity, entry.maxQuantity or quantity)

    if entry.stack ~= true then
        quantity = 1
    end

    local totalPrice = floor((entry.price or 0) * quantity)
    if totalPrice <= 0 then
        return false, 'invalid_price'
    end

    local account = vendor.purchaseAccount or 'money'
    local removedFunds, reason = Bridge.ESX.RemoveMoney(source, account, totalPrice, 'dd-hunting market purchase')
    if not removedFunds then
        return false, reason or 'insufficient_funds'
    end

    local metadata

    if itemName == 'hunting_license_basic' then
        metadata = DDHunting.Data.ItemMetadata.CreateLicense('Basic', {
            ownerIdentifier = getIdentifier(source),
            ownerServerId = source,
        })
    elseif itemName == 'hunting_license_standard' then
        metadata = DDHunting.Data.ItemMetadata.CreateLicense('Standard', {
            ownerIdentifier = getIdentifier(source),
            ownerServerId = source,
        })
    elseif itemName == 'hunting_license_advanced' then
        metadata = DDHunting.Data.ItemMetadata.CreateLicense('Advanced', {
            ownerIdentifier = getIdentifier(source),
            ownerServerId = source,
        })
    elseif itemName == 'deer_tag' then
        metadata = DDHunting.Data.ItemMetadata.CreateLicenseTag('deer', {
            ownerIdentifier = getIdentifier(source),
            ownerServerId = source,
        })
    elseif itemName == 'boar_tag' then
        metadata = DDHunting.Data.ItemMetadata.CreateLicenseTag('boar', {
            ownerIdentifier = getIdentifier(source),
            ownerServerId = source,
        })
    elseif itemName == 'predator_tag' then
        metadata = DDHunting.Data.ItemMetadata.CreateLicenseTag('wolf', {
            ownerIdentifier = getIdentifier(source),
            ownerServerId = source,
        })
    elseif itemName == 'bear_tag' then
        metadata = DDHunting.Data.ItemMetadata.CreateLicenseTag('bear', {
            ownerIdentifier = getIdentifier(source),
            ownerServerId = source,
        })
    end

    if not Bridge.Inventory.CanCarryItem(source, itemName, quantity, metadata) then
        Bridge.ESX.AddMoney(source, account, totalPrice, 'dd-hunting refund')
        return false, 'inventory_full'
    end

    local added = Bridge.Inventory.AddItem(source, itemName, quantity, metadata)
    if not added then
        Bridge.ESX.AddMoney(source, account, totalPrice, 'dd-hunting refund')
        return false, 'failed_to_add_item'
    end

    return true, {
        item = itemName,
        quantity = quantity,
        totalPrice = totalPrice,
        vendorLabel = vendor.label,
        account = account,
    }
end
