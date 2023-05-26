local Public = require 'maps.mountain_fortress_v3.table'
local Functions = require 'maps.mountain_fortress_v3.functions'

local random = math.random
local abs = math.abs

local types = {
    'assembling-machine',
    'furnace'
}

local testing = false

local testing_loot = {
    {
        stack = {
            recipe = 'speed-module-2',
            tech = 'speed-module-2',
            output = {item = 'speed-module-2', min_rate = 1 / 8 / 60 / 2, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 4
    }
}

local science_loot = {
    {
        stack = {
            recipe = 'automation-science-pack',
            output = {item = 'automation-science-pack', min_rate = 3 / 800, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 4
    },
    {
        stack = {
            recipe = 'logistic-science-pack',
            tech = 'logistic-science-pack',
            output = {item = 'logistic-science-pack', min_rate = 2 / 800, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 2
    }
}

local ammo_loot = {
    {
        stack = {
            recipe = 'piercing-rounds-magazine',
            tech = 'military-2',
            output = {item = 'piercing-rounds-magazine', min_rate = 1 / 800, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 1
    },
    {
        stack = {
            recipe = 'firearm-magazine',
            output = {item = 'firearm-magazine', min_rate = 2 / 800, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 4
    },
    {
        stack = {
            recipe = 'shotgun-shell',
            output = {item = 'shotgun-shell', min_rate = 2 / 800, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 4
    },
    {
        stack = {
            recipe = 'uranium-rounds-magazine',
            tech = 'uranium-ammo',
            output = {item = 'uranium-rounds-magazine', min_rate = 2 / 1800, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.25
    }
}

local oil_loot = {
    {
        stack = {
            recipe = 'basic-oil-processing',
            tech = 'oil-processing',
            output = {
                min_rate = 1 / 60,
                distance_factor = 1 / 8 / 60 / 20480,
                item = 'petroleum-gas',
                fluidbox_index = 2
            }
        },
        weight = 1
    },
    {
        stack = {
            recipe = 'advanced-oil-processing',
            tech = 'advanced-oil-processing',
            output = {
                {min_rate = 0.7 / 60, distance_factor = 1 / 8 / 60 / 20480, item = 'heavy-oil', fluidbox_index = 3},
                {min_rate = 0.82 / 60, distance_factor = 1 / 8 / 60 / 20480, item = 'light-oil', fluidbox_index = 4},
                {min_rate = 0.83 / 60, distance_factor = 1 / 8 / 60 / 20480, item = 'petroleum-gas', fluidbox_index = 5}
            }
        },
        weight = 0.1
    }
}

local oil_prod_loot = {
    {
        stack = {
            recipe = 'lubricant',
            tech = 'lubricant',
            output = {
                item = 'lubricant',
                min_rate = 0.7 / 60,
                distance_factor = 1 / 8 / 60 / 20480,
                fluidbox_index = 2
            }
        },
        weight = 1
    },
    {
        stack = {
            recipe = 'solid-fuel-from-light-oil',
            tech = 'oil-processing',
            output = {
                item = 'solid-fuel',
                min_rate = 0.7 / 60,
                distance_factor = 1 / 8 / 60 / 20480
            }
        },
        weight = 4
    },
    {
        stack = {
            recipe = 'sulfuric-acid',
            tech = 'sulfur-processing',
            output = {
                item = 'sulfuric-acid',
                min_rate = 0.8 / 60,
                distance_factor = 1 / 8 / 60 / 20480,
                fluidbox_index = 2
            }
        },
        weight = 1
    },
    {
        stack = {
            recipe = 'battery',
            tech = 'battery',
            output = {
                item = 'battery',
                min_rate = 0.6 / 60,
                distance_factor = 1 / 8 / 60 / 20480
            }
        },
        weight = 0.75
    },
    {
        stack = {
            recipe = 'sulfur',
            tech = 'sulfur-processing',
            output = {
                item = 'sulfur',
                min_rate = 0.8 / 60,
                distance_factor = 1 / 8 / 60 / 20480
            }
        },
        weight = 0.55
    },
    {
        stack = {
            recipe = 'plastic-bar',
            tech = 'plastics',
            output = {
                item = 'plastic-bar',
                min_rate = 0.8 / 60,
                distance_factor = 1 / 8 / 60 / 20480
            }
        },
        weight = 0.25
    },
    {
        stack = {
            recipe = 'explosives',
            tech = 'explosives',
            output = {
                item = 'explosives',
                min_rate = 0.8 / 60,
                distance_factor = 1 / 8 / 60 / 20480
            }
        },
        weight = 0.20
    }
}

local resource_loot = {
    {
        stack = {
            recipe = 'stone-wall',
            tech = 'stone-walls',
            output = {item = 'stone-wall', min_rate = 0.6 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 10
    },
    {
        stack = {
            recipe = 'concrete',
            tech = 'concrete',
            output = {item = 'concrete', min_rate = 1 / 4 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 6
    },
    {
        stack = {
            recipe = 'iron-gear-wheel',
            output = {item = 'iron-gear-wheel', min_rate = 0.6 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 12
    },
    {
        stack = {
            recipe = 'inserter',
            output = {item = 'inserter', min_rate = 0.6 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 12
    },
    {
        stack = {
            recipe = 'fast-inserter',
            tech = 'fast-inserter',
            output = {item = 'fast-inserter', min_rate = 1 / 4 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 4
    },
    {
        stack = {
            recipe = 'electronic-circuit',
            output = {item = 'electronic-circuit', min_rate = 1 / 4 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 2
    },
    {
        stack = {
            recipe = 'advanced-circuit',
            tech = 'advanced-electronics',
            output = {item = 'advanced-circuit', min_rate = 1 / 4 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 1
    },
    {
        stack = {
            recipe = 'processing-unit',
            tech = 'advanced-electronics-2',
            output = {item = 'processing-unit', min_rate = 1 / 10 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 2
    },
    {
        stack = {
            recipe = 'transport-belt',
            output = {item = 'transport-belt', min_rate = 0.6 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 8
    },
    {
        stack = {
            recipe = 'underground-belt',
            output = {item = 'underground-belt', min_rate = 1 / 4 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 8
    },
    {
        stack = {
            recipe = 'small-electric-pole',
            output = {item = 'small-electric-pole', min_rate = 1 / 4 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 8
    },
    {
        stack = {
            recipe = 'fast-transport-belt',
            tech = 'logistics-2',
            output = {item = 'fast-transport-belt', min_rate = 1 / 4 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 5
    },
    {
        stack = {
            recipe = 'fast-underground-belt',
            tech = 'logistics-2',
            output = {item = 'fast-underground-belt', min_rate = 1 / 4 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 5
    },
    {
        stack = {
            recipe = 'solar-panel',
            tech = 'solar-energy',
            output = {item = 'solar-panel', min_rate = 1 / 15 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 3
    },
    {
        stack = {
            recipe = 'productivity-module',
            tech = 'productivity-module',
            output = {item = 'productivity-module', min_rate = 1 / 10 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.9
    },
    {
        stack = {
            recipe = 'effectivity-module',
            tech = 'effectivity-module',
            output = {item = 'effectivity-module', min_rate = 1 / 10 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.9
    },
    {
        stack = {
            recipe = 'speed-module',
            tech = 'speed-module',
            output = {item = 'speed-module', min_rate = 1 / 10 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.8
    },
    {
        stack = {
            recipe = 'productivity-module-2',
            tech = 'productivity-module-2',
            output = {item = 'productivity-module-2', min_rate = 1 / 15 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.5
    },
    {
        stack = {
            recipe = 'effectivity-module-2',
            tech = 'effectivity-module-2',
            output = {item = 'effectivity-module-2', min_rate = 1 / 15 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.5
    },
    {
        stack = {
            recipe = 'speed-module-2',
            tech = 'speed-module-2',
            output = {item = 'speed-module-2', min_rate = 1 / 15 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.5
    },
    {
        stack = {
            recipe = 'productivity-module-3',
            tech = 'productivity-module-3',
            output = {item = 'productivity-module-3', min_rate = 1 / 20 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.25
    },
    {
        stack = {
            recipe = 'effectivity-module-3',
            tech = 'effectivity-module-3',
            output = {item = 'effectivity-module-3', min_rate = 1 / 20 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.25
    },
    {
        stack = {
            recipe = 'speed-module-3',
            tech = 'speed-module-3',
            output = {item = 'speed-module-3', min_rate = 1 / 20 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 0.10
    }
}

local furnace_loot = {
    {
        stack = {
            furance_item = 'iron-plate',
            output = {item = 'iron-plate', min_rate = 2.0 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 4
    },
    {
        stack = {
            furance_item = 'copper-plate',
            output = {item = 'copper-plate', min_rate = 2.0 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 4
    },
    {
        stack = {
            furance_item = 'steel-plate',
            tech = 'steel-processing',
            output = {item = 'steel-plate', min_rate = 1.0 / 60, distance_factor = 1 / 8 / 60 / 20480}
        },
        weight = 1
    }
}

local testing_weights = Functions.prepare_weighted_loot(testing_loot)
local science_weights = Functions.prepare_weighted_loot(science_loot)
local building_weights = Functions.prepare_weighted_loot(ammo_loot)
local oil_weights = Functions.prepare_weighted_loot(oil_loot)
local oil_prod_weights = Functions.prepare_weighted_loot(oil_prod_loot)
local resource_weights = Functions.prepare_weighted_loot(resource_loot)
local furnace_weights = Functions.prepare_weighted_loot(furnace_loot)

local testing_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = testing_loot,
        weights = testing_weights,
        testing = true,
        destructible = false
    }
}

local science_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = science_loot,
        weights = science_weights,
        destructible = false
    }
}

local building_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = ammo_loot,
        weights = building_weights,
        destructible = false
    }
}

local oil_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = oil_loot,
        weights = oil_weights,
        destructible = false
    }
}

local oil_prod_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = oil_prod_loot,
        weights = oil_prod_weights,
        destructible = false
    }
}

local resource_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = resource_loot,
        weights = resource_weights,
        destructible = false
    }
}

local furnace_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = furnace_loot,
        weights = furnace_weights,
        destructible = false
    }
}

local testing_list = {
    [1] = {name = 'assembling-machine-1', callback = testing_callback},
    [2] = {name = 'assembling-machine-2', callback = testing_callback},
    [3] = {name = 'assembling-machine-3', callback = testing_callback}
}

local science_list = {
    [1] = {name = 'assembling-machine-1', callback = science_callback},
    [2] = {name = 'assembling-machine-2', callback = science_callback},
    [3] = {name = 'assembling-machine-3', callback = science_callback}
}

local ammo_list = {
    [1] = {name = 'assembling-machine-1', callback = building_callback},
    [2] = {name = 'assembling-machine-2', callback = building_callback},
    [3] = {name = 'assembling-machine-3', callback = building_callback}
}

local oil_list = {
    [1] = {name = 'oil-refinery', callback = oil_callback}
}

local oil_prod_list = {
    [1] = {name = 'chemical-plant', callback = oil_prod_callback}
}

local resource_list = {
    [1] = {name = 'assembling-machine-1', callback = resource_callback},
    [2] = {name = 'assembling-machine-2', callback = resource_callback},
    [3] = {name = 'assembling-machine-3', callback = resource_callback}
}

local furnace_list = {
    [1] = {name = 'stone-furnace', callback = furnace_callback},
    [2] = {name = 'steel-furnace', callback = furnace_callback},
    [3] = {name = 'electric-furnace', callback = furnace_callback}
}

local function spawn_testing_buildings(entities, p, probability)
    local callback = testing_list[probability].callback

    entities[#entities + 1] = {
        name = testing_list[probability].name,
        position = p,
        force = 'neutral',
        callback = callback,
        collision = true,
        e_type = types
    }
end

local function spawn_science_buildings(entities, p, probability)
    local callback = science_list[probability].callback

    entities[#entities + 1] = {
        name = science_list[probability].name,
        position = p,
        force = 'neutral',
        callback = callback,
        collision = true,
        e_type = types
    }
end

local function spawn_ammo_building(entities, p, probability)
    local callback = ammo_list[probability].callback

    entities[#entities + 1] = {
        name = ammo_list[probability].name,
        position = p,
        force = 'neutral',
        callback = callback,
        collision = true,
        e_type = types
    }
end

local function spawn_oil_buildings(entities, p)
    local callback = oil_list[1].callback

    entities[#entities + 1] = {
        name = oil_list[1].name,
        position = p,
        force = 'neutral',
        callback = callback,
        collision = true,
        e_type = types
    }
end

local function spawn_oil_prod_buildings(entities, p)
    local callback = oil_prod_list[1].callback

    entities[#entities + 1] = {
        name = oil_prod_list[1].name,
        position = p,
        force = 'neutral',
        callback = callback,
        collision = true,
        e_type = types
    }
end

local function spawn_resource_building(entities, p, probability)
    local callback = resource_list[probability].callback

    entities[#entities + 1] = {
        name = resource_list[probability].name,
        position = p,
        force = 'neutral',
        callback = callback,
        collision = true,
        e_type = types
    }
end

local function spawn_furnace_building(entities, p, probability)
    local callback = furnace_list[probability].callback

    entities[#entities + 1] = {
        name = furnace_list[probability].name,
        position = p,
        force = 'neutral',
        callback = callback,
        collision = true,
        e_type = types
    }
end

local buildings = {
    [1] = spawn_ammo_building,
    [2] = spawn_resource_building,
    [3] = spawn_furnace_building,
    [4] = spawn_science_buildings,
    [5] = spawn_oil_buildings,
    [6] = spawn_oil_prod_buildings
}

if testing then
    buildings = {
        [1] = spawn_testing_buildings
    }
end

function Public.spawn_random_buildings(entities, p, depth)
    local randomizer = random(1, #buildings)
    local low = random(1, 2)
    local medium = random(2, 3)
    local high = 3

    if abs(p.y) < depth * 1.5 then
        if random(1, 16) == 1 then
            return buildings[randomizer](entities, p, medium)
        else
            return buildings[randomizer](entities, p, low)
        end
    elseif abs(p.y) < depth * 2.5 then
        if random(1, 8) == 1 then
            return buildings[randomizer](entities, p, medium)
        else
            return buildings[randomizer](entities, p, medium)
        end
    elseif abs(p.y) < depth * 3.5 then
        if random(1, 4) == 1 then
            return buildings[randomizer](entities, p, high)
        else
            return buildings[randomizer](entities, p, medium)
        end
    elseif abs(p.y) < depth * 4.5 then
        if random(1, 4) == 1 then
            return buildings[randomizer](entities, p, high)
        else
            return buildings[randomizer](entities, p, high)
        end
    elseif abs(p.y) < depth * 5.5 then
        if random(1, 4) == 1 then
            return buildings[randomizer](entities, p, high)
        elseif random(1, 2) == 1 then
            return buildings[randomizer](entities, p, high)
        elseif random(1, 8) == 1 then
            return buildings[randomizer](entities, p, high)
        end
    end
    if abs(p.y) > depth * 5.5 then
        if random(1, 32) == 1 then
            return buildings[randomizer](entities, p, medium)
        end
    end
end

return Public
