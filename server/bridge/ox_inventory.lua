local Bridge = DDHunting.Server.Bridge

Bridge.Inventory = Bridge.Inventory or {}
local InventoryBridge = Bridge.Inventory

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][inventory] %s'):format(msg))
    end
end

function InventoryBridge.Init()
    if GetResourceState('ox_inventory') ~= 'started' then
        error('[dd-hunting] ox_inventory is not started')
    end

    debugPrint('ox_inventory bridge initialized')
    return true
end

function InventoryBridge.CanCarryItem(source, itemName, count, metadata)
    count = math.max(1, math.floor(tonumber(count) or 1))
    return exports.ox_inventory:CanCarryItem(source, itemName, count, metadata)
end

function InventoryBridge.AddItem(source, itemName, count, metadata, slot)
    count = math.max(1, math.floor(tonumber(count) or 1))

    local success, response = exports.ox_inventory:AddItem(source, itemName, count, metadata, slot)
    return success == true, response
end

function InventoryBridge.RemoveItem(source, itemName, count, metadata, slot)
    count = math.max(1, math.floor(tonumber(count) or 1))

    local success, response = exports.ox_inventory:RemoveItem(source, itemName, count, metadata, slot)
    return success == true, response
end

function InventoryBridge.Search(source, searchType, itemName)
    return exports.ox_inventory:Search(source, searchType, itemName)
end

function InventoryBridge.GetItemCount(source, itemName, metadata)
    local result = exports.ox_inventory:Search(source, 'count', itemName, metadata)
    return tonumber(result) or 0
end

function InventoryBridge.GetSlotsWithItem(source, itemName, metadata)
    local result = exports.ox_inventory:Search(source, 'slots', itemName, metadata)
    return result or {}
end

function InventoryBridge.HasItem(source, itemName, count, metadata)
    return InventoryBridge.GetItemCount(source, itemName, metadata) >= (count or 1)
end

function InventoryBridge.RegisterStash(stashId, label, slots, maxWeight, owner, groups, coords)
    exports.ox_inventory:RegisterStash(stashId, label, slots, maxWeight, owner, groups, coords)
end
