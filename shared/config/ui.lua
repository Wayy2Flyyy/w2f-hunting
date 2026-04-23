local Config = DDHunting.Config

Config.UI = {
    UseOxLibContext = true,
    UseOxLibNotify = true,
    UseOxLibProgress = true,

    Tracking = {
        ShowFreshnessText = true,
        ShowSpeciesHint = true,
        ShowDirectionHint = true,
    },

    Binoculars = {
        ShowRange = true,
        ShowSpecies = true,
        ShowWeightEstimate = true,
        ShowTrophyEstimate = true,
    },

    Harvest = {
        UseSkillCheck = true,
        ProgressMinMs = 4500,
        ProgressMaxMs = 12000,
    },

    Notifications = {
        Position = 'top',
        Duration = 5000,
    }
}
