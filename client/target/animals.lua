local Client = DDHunting.Client

Client.Systems.AnimalTarget = Client.Systems.AnimalTarget or {}
local AnimalTarget = Client.Systems.AnimalTarget

local registered = {} -- [entity] = wildlifeId

local function getInspectDescription(record)
    return ('%s • %s • %s'):format(
        record.speciesLabel or record.species or 'Unknown',
        record.sex or 'unknown',
        record.ageClass or 'adult'
    )
end

function AnimalTarget.AttachToEntity(record, entity)
    if not entity or entity == 0 or registered[entity] then
        return
    end

    exports.ox_target:addLocalEntity(entity, {
        {
            name = ('dd_hunting_animal_inspect_%s'):format(record.id),
            icon = 'fa-solid fa-paw',
            label = 'Inspect Animal',
            distance = 2.5,
            canInteract = function(ent, dist)
                return DoesEntityExist(ent) and dist <= 2.5
            end,
            onSelect = function()
                lib.notify({
                    title = 'Wildlife',
                    description = getInspectDescription(record),
                    type = 'inform'
                })
            end
        },
        {
            name = ('dd_hunting_animal_track_%s'):format(record.id),
            icon = 'fa-solid fa-binoculars',
            label = 'Study Tracks',
            distance = 2.5,
            canInteract = function(ent, dist)
                return DoesEntityExist(ent) and dist <= 2.5
            end,
            onSelect = function()
                lib.notify({
                    title = 'Tracking',
                    description = ('You study the %s for signs and movement.'):format(record.speciesLabel or 'animal'),
                    type = 'inform'
                })
            end
        }
    })

    registered[entity] = record.id
end

function AnimalTarget.DetachFromEntity(entity)
    if not entity or entity == 0 or not registered[entity] then
        return
    end

    exports.ox_target:removeLocalEntity(entity)
    registered[entity] = nil
end
