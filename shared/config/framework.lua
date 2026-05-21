local Config = DDHunting.Config

Config.Framework = {
    -- Active framework: qbox | qbcore | esx
    Target = 'qbox',
    Primary = 'qbox',
    UseOxInventory = true,

    Inventory = {
        Name = 'ox_inventory',
        ImagePath = 'nui://ox_inventory/web/images',
    },

    InteractionTarget = {
        Name = 'ox_target',
    },

    Notifications = {
        Type = 'ox_lib', -- 'ox_lib' | 'esx'
    },

    Database = {
        Name = 'oxmysql',
    },

    Accounts = {
        -- Qbox/QBCore: cash | bank | black_money (server-dependent)
        -- ESX: money | black_money
        LegalPayout = 'cash',
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
