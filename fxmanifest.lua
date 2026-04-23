fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dd-hunting'
author 'dd-hunting'
description 'ESX + ox hunting framework'
version '0.3.0-progression-depth'

shared_scripts {
    '@ox_lib/init.lua',

    'shared/init.lua',

    'shared/config/main.lua',
    'shared/config/framework.lua',
    'shared/config/ui.lua',
    'shared/config/loot.lua',
    'shared/config/zones.lua',
    'shared/config/seasons.lua',
    'shared/config/progression.lua',
    'shared/config/legality.lua',
    'shared/config/weather.lua',
    'shared/config/equipment.lua',
    'shared/config/Market.lua',
    'shared/config/admin.lua',
    'shared/config/processing.lua',
    'shared/config/contracts.lua',

    'shared/data/animals.lua',
    'shared/data/species/rabbit.lua',
    'shared/data/species/deer.lua',
    'shared/data/species/boar.lua',
    'shared/data/item_tree.lua',
    'shared/data/item_metadata.lua',
    'shared/data/crafting.lua',
}

client_scripts {
    'client/init.lua',
    'client/state.lua',

    'client/systems/wildlife_client.lua',
    'client/systems/harvest.lua',

    'client/ui/processing.lua',
    'client/ui/market.lua',
    'client/ui/progression.lua',

    'client/target/animals.lua',
    'client/target/carcasses.lua',

    'client/zones/processing_zones.lua',
    'client/zones/market_zones.lua',

    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'server/init.lua',
    'server/state.lua',

    'server/bridge/esx.lua',
    'server/bridge/ox_inventory.lua',
    'server/bridge/oxmysql.lua',

    'server/bridge/services/wildlife_service.lua',
    'server/bridge/services/spawn_service.lua',

    'server/services/quality_service.lua',
    'server/services/legality_service.lua',
    'server/services/persistence_service.lua',
    'server/services/reputation_service.lua',
    'server/services/mastery_service.lua',
    'server/services/progression_service.lua',
    'server/services/carcass_service.lua',
    'server/services/processing_service.lua',
    'server/services/market_service.lua',

    'server/events/animals.lua',
    'server/events/harvest.lua',
    'server/events/processing.lua',
    'server/events/Market.lua',
    'server/events/progression.lua',

    'server/main.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'es_extended',
}
