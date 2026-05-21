local Config = DDHunting.Config

--- Framework selection: qbox (default), qbcore, or esx.
--- Hard manifest dependencies stay on ox_* only; start the matching framework resource in server.cfg.
Config.Framework = {
    Target = 'qbox', -- 'qbox' | 'qbcore' | 'esx'
    Primary = 'qbox',
    UseOxInventory = true,

    Inventory = {
        Name = 'ox_inventory',
        ImagePath = 'nui://ox_inventory/web/images',
    },

    --- ox_target / third-party interaction layer (not the framework target string above).
    Targeting = {
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

--- Keep legacy feature flag aligned with framework inventory setting.
if DDHunting.Config.Main and DDHunting.Config.Main.Features then
    DDHunting.Config.Main.Features.UseOxInventory = DDHunting.Config.Framework.UseOxInventory ~= false
end
