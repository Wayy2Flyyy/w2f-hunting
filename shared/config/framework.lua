local Config = DDHunting.Config

Config.Framework = {
    Name = 'esx', -- 'esx'
    SharedObjectExport = 'es_extended:getSharedObject',

    Inventory = {
        Name = 'ox_inventory',
        ImagePath = 'nui://ox_inventory/web/images',
    },

    Target = {
        Name = 'ox_target',
    },

    Notifications = {
        Type = 'ox_lib', -- 'ox_lib' | 'esx'
    },

    Database = {
        Name = 'oxmysql',
    },

    Accounts = {
        LegalPayout = 'money',
        IllegalPayout = 'black_money',
    },

    Jobs = {
        Ranger = { 'ranger', 'gamewarden' },
        Police = { 'police', 'sheriff' },
    },

    Permissions = {
        AdminGroups = { 'admin', 'superadmin' },
    },
}
