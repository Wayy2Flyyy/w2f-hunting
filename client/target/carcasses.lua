local Client = DDHunting.Client
local State = Client.State

Client.Systems.CarcassTarget = Client.Systems.CarcassTarget or {}
local CarcassTarget = Client.Systems.CarcassTarget

local registered = {} -- [entity] = carcassId

local function inspectText(record)
    return ('%s • %s quality • %s'):format(
        record.speciesLabel or record.species or 'Unknown',
        record.quality or 'standard',
        record.freshnessLabel or 'fresh'
    )
end

function CarcassTarget.Attach(entity, carcassId)
    if not entity or entity == 0 or registered[entity] then
        return
    end

    local record = State.GetCarcass(carcassId)
    if not record then
        return
    end

    exports.ox_target:addLocalEntity(entity, {
        {
            name = ('dd_hunting_carcass_inspect_%s'):format(carcassId),
            icon = 'fa-solid fa-drumstick-bite',
            label = 'Inspect Carcass',
            distance = 2.5,
            onSelect = function()
                local current = State.GetCarcass(carcassId)
                if not current then
                    return
                end

                lib.notify({
                    title = 'Carcass',
                    description = inspectText(current),
                    type = 'inform'
                })
            end
        },
        {
            name = ('dd_hunting_carcass_harvest_%s'):format(carcassId),
            icon = 'fa-solid fa-knife',
            label = 'Harvest Carcass',
            distance = 2.0,
            onSelect = function()
                local current = State.GetCarcass(carcassId)
                if not current then
                    return
                end

                if Client.Systems.Harvest and Client.Systems.Harvest.BeginHarvest then
                    Client.Systems.Harvest.BeginHarvest(current, entity)
                end
            end
        }
    })

    registered[entity] = carcassId
end

function CarcassTarget.Detach(entity)
    if not entity or entity == 0 or not registered[entity] then
        return
    end

    exports.ox_target:removeLocalEntity(entity)
    registered[entity] = nil
end
