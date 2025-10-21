
Config = {}

-- Enable skill system integration
Config.UseSkills = true

-- Mining Types and Locations
Config.MiningSpots = {
    {
        type = 'rock_pickaxe',
        coords = vector3(-593.0, 2040.0, 323.0),
        size = vector3(2.0, 2.0, 2.0),
        rotation = 0,
        requiredItem = 'pickaxe',
        rewards = {
            {item = 'stone', amountMin = 1, amountMax = 5},
            {item = 'iron_ore', amountMin = 0, amountMax = 3},
            {item = 'coal', amountMin = 0, amountMax = 2},
        },
        chanceRare = 0.1,
        rareReward = {item = 'gold_nugget', amount = 1},
        skill = 'mining'
    },
    {
        type = 'rock_dynamite',
        coords = vector3(-1400.0, 1200.0, 220.0),
        size = vector3(3.0, 3.0, 3.0),
        rotation = 0,
        requiredItem = 'dynamite',
        rewards = {
            {item = 'stone', amountMin = 5, amountMax = 15},
            {item = 'iron_ore', amountMin = 2, amountMax = 8},
            {item = 'coal', amountMin = 1, amountMax = 5},
        },
        chanceRare = 0.2,
        rareReward = {item = 'gold_nugget', amount = 2},
        explosionRisk = 0.05,
        skill = 'mining'
    },
    {
        type = 'gold_pan',
        coords = vector3(-1300.0, -1500.0, 50.0),
        size = vector3(5.0, 5.0, 5.0),
        rotation = 0,
        requiredItem = 'goldpan',
        rewards = {
            {item = 'gold_dust', amountMin = 1, amountMax = 3},
            {item = 'small_nugget', amountMin = 0, amountMax = 1},
        },
        chanceRare = 0.05,
        rareReward = {item = 'large_gold_nugget', amount = 1},
        skill = 'mining'
    },
}

-- Smelting Config
Config.SmeltingSpots = {
    {
        coords = vector3(-500.0, 2000.0, 300.0),
        size = vector3(2.0, 2.0, 2.0),
        rotation = 0,
        requiredFuel = 'coal',
        fuelAmount = 1,
        recipes = {
            {
                input = {item = 'iron_ore', amount = 5},
                output = {item = 'iron_ingot', amount = 1},
                time = 15000,
            },
            {
                input = {item = 'gold_dust', amount = 10},
                output = {item = 'gold_bar', amount = 1},
                time = 20000,
            },
        },
        skill = 'smelting'
    },
}

-- Prospecting Config
Config.ProspectingSpots = {
    {
        coords = vector3(-600.0, 2050.0, 320.0),
        size = vector3(2.0, 2.0, 2.0),
        rotation = 0,
        requiredItem = 'prospector_tool',
        rewards = {
            {item = 'mineral_sample', amountMin = 1, amountMax = 3},
            {item = 'rare_mineral', amountMin = 0, amountMax = 1},
        },
        chanceRare = 0.15,
        rareReward = {item = 'diamond', amount = 1},
        skill = 'prospecting'
    },
}

-- Random Events Config
Config.RandomEvents = true
Config.RandomEventChance = 0.15
Config.RandomEventsList = {
    {
        name = 'rare_gem',
        chance = 0.3,
        action = function(playerPed)
            TriggerServerEvent('mining:giveItem', 'rare_gem', 1)
            Config.Notify('You found a rare gem!')
        end
    },
    {
        name = 'cave_in',
        chance = 0.2,
        action = function(playerPed)
            SetEntityHealth(playerPed, GetEntityHealth(playerPed) - 30)
            Config.Notify('Cave-in! You take damage.')
        end
    },
    {
        name = 'animal_attack',
        chance = 0.2,
        action = function(playerPed)
            local animalHash = GetHashKey('a_c_coyote_01')
            local animal = CreatePed(animalHash, GetEntityCoords(playerPed) + vector3(5, 0, 0), 0.0, true, true)
            TaskCombatPed(animal, playerPed, 0, 16)
            Config.Notify('Animal attack!')
        end
    },
    {
        name = 'tool_break',
        chance = 0.15,
        action = function(playerPed)
            TriggerServerEvent('mining:removeItem', 'pickaxe', 1)
            Config.Notify('Your pickaxe broke!')
        end
    },
    {
        name = 'lucky_find',
        chance = 0.15,
        action = function(playerPed)
            TriggerServerEvent('mining:giveItem', 'gold_nugget', 3)
            Config.Notify('Lucky find! Extra gold nuggets discovered!')
        end
    },
    {
        name = 'earthquake',
        chance = 0.1,
        action = function(playerPed)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.5)
            Config.Notify('An earthquake shakes the ground!')
        end
    },
    {
        name = 'treasure_map',
        chance = 0.05,
        action = function(playerPed)
            TriggerServerEvent('mining:giveItem', 'treasure_map', 1)
            Config.Notify('You found a treasure map!')
        end
    },
}

-- Lantern Helmet Config
Config.LanternHelmet = 'lantern_helmet'
Config.FuelItem = 'lamp_oil'
Config.FuelDuration = 300
Config.LightColor = {r = 255, g = 200, b = 100}
Config.LightRange = 10.0
Config.LightIntensity = 2.0
Config.LightOffset = vector3(0.0, 0.2, 0.0)

-- General Settings
Config.ProgressTime = 10000
Config.Notify = function(msg) exports.ox_lib:notify({description = msg, type = 'inform'}) end