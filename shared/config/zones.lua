local Config = DDHunting.Config

Config.Zones = {
    Habitats = {
        DeerCountry = {
            label = 'Deer Country',
            type = 'wildlife',
            center = vec3(-679.0, 4187.0, 155.0),
            radius = 650.0,
            species = { 'deer', 'rabbit' },
        },
        BoarWoods = {
            label = 'Boar Woods',
            type = 'wildlife',
            center = vec3(-1118.0, 4898.0, 218.0),
            radius = 500.0,
            species = { 'boar', 'coyote', 'rabbit' },
        },
        PredatorRidge = {
            label = 'Predator Ridge',
            type = 'wildlife',
            center = vec3(1545.0, 4422.0, 44.0),
            radius = 650.0,
            species = { 'wolf', 'mountain_lion', 'coyote' },
        },
        NorthernWilds = {
            label = 'Northern Wilds',
            type = 'wildlife',
            center = vec3(-438.0, 5602.0, 75.0),
            radius = 900.0,
            species = { 'deer', 'boar', 'bear', 'wolf', 'rabbit' },
        },
    },

    Restricted = {
        NatureReserve = {
            label = 'Nature Reserve',
            type = 'restricted',
            center = vec3(2350.0, 4700.0, 34.0),
            radius = 400.0,
            reason = 'Protected wildlife area',
        },
    },

    Buyers = {
        Butcher = {
            label = 'Butcher',
            coords = vec3(-72.82, 6268.73, 31.49),
            type = 'legal',
        },
        Trapper = {
            label = 'Trapper',
            coords = vec3(-769.16, 5595.63, 33.49),
            type = 'legal',
        },
        BlackMarket = {
            label = 'Black Market Buyer',
            coords = vec3(1243.84, -3178.87, 5.53),
            type = 'illegal',
        },
    },

    Lodge = {
        Main = {
            label = 'Hunter Lodge',
            coords = vec3(-679.41, 5838.56, 17.33),
            radius = 40.0,
        },
    },
}
