local Config = DDHunting.Config

Config.Processing = {
    Benches = {
        butcher = {
            label = 'Butcher Bench',
            coords = vec3(-75.44, 6265.19, 31.49),
            radius = 1.5,
            icon = 'fa-solid fa-knife-kitchen',
            account = 'money',
            baseFee = 35,
            maxBatch = 10,
        },

        tannery = {
            label = 'Tannery Bench',
            coords = vec3(-772.18, 5592.45, 33.49),
            radius = 1.5,
            icon = 'fa-solid fa-scroll',
            account = 'money',
            baseFee = 55,
            maxBatch = 10,
        },

        trophy_bench = {
            label = 'Trophy Mount Bench',
            coords = vec3(-681.85, 5835.67, 17.33),
            radius = 1.5,
            icon = 'fa-solid fa-trophy',
            account = 'money',
            baseFee = 120,
            maxBatch = 5,
        },

        illegal = {
            label = 'Forgery Bench',
            coords = vec3(1249.84, -3171.68, 5.53),
            radius = 1.5,
            icon = 'fa-solid fa-user-secret',
            account = 'black_money',
            baseFee = 240,
            maxBatch = 10,
        },
    }
}
