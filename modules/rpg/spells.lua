local Public = {}

Public.conjure_items = {
    [1] = {
        name = 'Stone Wall',
        obj_to_create = 'stone-wall',
        level = 10,
        type = 'item',
        mana_cost = 35,
        tick = 160,
        enabled = true
    },
    [2] = {
        name = 'Wooden Chest',
        obj_to_create = 'wooden-chest',
        level = 2,
        type = 'item',
        mana_cost = 30,
        tick = 160,
        enabled = true
    },
    [3] = {
        name = 'Iron Chest',
        obj_to_create = 'iron-chest',
        level = 10,
        type = 'item',
        mana_cost = 40,
        tick = 260,
        enabled = true
    },
    [4] = {
        name = 'Steel Chest',
        obj_to_create = 'steel-chest',
        level = 15,
        type = 'item',
        mana_cost = 50,
        tick = 360,
        enabled = true
    },
    [5] = {
        name = 'Transport Belt',
        obj_to_create = 'transport-belt',
        level = 3,
        type = 'item',
        mana_cost = 40,
        tick = 160,
        enabled = true
    },
    [6] = {
        name = 'Fast Transport Belt',
        obj_to_create = 'fast-transport-belt',
        level = 20,
        type = 'item',
        mana_cost = 50,
        tick = 260,
        enabled = true
    },
    [7] = {
        name = 'Express Transport Belt',
        obj_to_create = 'express-transport-belt',
        level = 60,
        type = 'item',
        mana_cost = 60,
        tick = 360,
        enabled = true
    },
    [8] = {
        name = 'Underground Belt',
        obj_to_create = 'underground-belt',
        level = 3,
        type = 'item',
        mana_cost = 40,
        tick = 160,
        enabled = true
    },
    [9] = {
        name = 'Fast Underground Belt',
        obj_to_create = 'fast-underground-belt',
        level = 20,
        type = 'item',
        mana_cost = 50,
        tick = 260,
        enabled = true
    },
    [10] = {
        name = 'Express Underground Belt',
        obj_to_create = 'express-underground-belt',
        level = 60,
        type = 'item',
        mana_cost = 60,
        tick = 360,
        enabled = true
    },
    [11] = {
        name = 'Sandy Rock',
        obj_to_create = 'sand-rock-big',
        level = 80,
        type = 'entity',
        mana_cost = 80,
        tick = 420,
        enabled = true
    },
    [12] = {
        name = 'Smol Biter',
        obj_to_create = 'small-biter',
        level = 50,
        biter = true,
        type = 'entity',
        mana_cost = 55,
        tick = 100,
        enabled = true
    },
    [13] = {
        name = 'Smol Spitter',
        obj_to_create = 'small-spitter',
        level = 50,
        biter = true,
        type = 'entity',
        mana_cost = 55,
        tick = 100,
        enabled = true
    },
    [14] = {
        name = 'Medium Biter',
        obj_to_create = 'medium-biter',
        level = 70,
        biter = true,
        type = 'entity',
        mana_cost = 100,
        tick = 200,
        enabled = true
    },
    [15] = {
        name = 'Medium Spitter',
        obj_to_create = 'medium-spitter',
        level = 70,
        type = 'entity',
        mana_cost = 100,
        tick = 200,
        enabled = true
    },
    [16] = {
        name = 'Bitter Spawner',
        obj_to_create = 'biter-spawner',
        level = 100,
        biter = true,
        type = 'entity',
        mana_cost = 600,
        tick = 1420,
        enabled = true
    },
    [17] = {
        name = 'Spitter Spawner',
        obj_to_create = 'spitter-spawner',
        level = 100,
        biter = true,
        type = 'entity',
        mana_cost = 600,
        tick = 1420,
        enabled = true
    },
    [18] = {
        name = 'AOE Grenade',
        obj_to_create = 'grenade',
        target = true,
        amount = 1,
        damage = true,
        force = 'player',
        level = 30,
        type = 'special',
        mana_cost = 100,
        tick = 150,
        enabled = true
    },
    [19] = {
        name = 'Big AOE Grenade',
        obj_to_create = 'cluster-grenade',
        target = true,
        amount = 2,
        damage = true,
        force = 'player',
        level = 50,
        type = 'special',
        mana_cost = 150,
        tick = 200,
        enabled = true
    },
    [20] = {
        name = 'Pointy Rocket',
        obj_to_create = 'rocket',
        range = 240,
        target = true,
        amount = 4,
        damage = true,
        force = 'enemy',
        level = 40,
        type = 'special',
        mana_cost = 60,
        tick = 320,
        enabled = true
    },
    [21] = {
        name = 'Bitter Spew',
        obj_to_create = 'acid-stream-spitter-big',
        target = true,
        amount = 2,
        range = 0,
        damage = true,
        force = 'player',
        level = 70,
        type = 'special',
        mana_cost = 90,
        tick = 200,
        enabled = true
    },
    [22] = {
        name = 'Fire my lazors!!',
        obj_to_create = 'railgun-beam',
        target = false,
        amount = 3,
        damage = true,
        range = 240,
        force = 'player',
        level = 50,
        type = 'special',
        mana_cost = 66,
        tick = 320,
        enabled = true
    },
    [23] = {
        name = 'Conjure Raw-fish',
        obj_to_create = 'fish',
        target = false,
        amount = 4,
        damage = false,
        range = 30,
        force = 'player',
        level = 50,
        type = 'special',
        mana_cost = 120,
        tick = 320,
        enabled = true
    },
    [24] = {
        name = 'Suicidal Comfylatron',
        obj_to_create = 'suicidal_comfylatron',
        target = false,
        amount = 4,
        damage = false,
        range = 30,
        force = 'player',
        level = 60,
        type = 'special',
        mana_cost = 250,
        tick = 320,
        enabled = true
    },
    [25] = {
        name = 'Distractor Capsule',
        obj_to_create = 'distractor-capsule',
        target = true,
        amount = 1,
        damage = false,
        range = 30,
        force = 'player',
        level = 60,
        type = 'special',
        mana_cost = 200,
        tick = 320,
        enabled = true
    }
}

Public.projectile_types = {
    ['explosives'] = {name = 'grenade', count = 0.5, max_range = 32, tick_speed = 1},
    ['land-mine'] = {name = 'grenade', count = 1, max_range = 32, tick_speed = 1},
    ['grenade'] = {name = 'grenade', count = 1, max_range = 40, tick_speed = 1},
    ['cluster-grenade'] = {name = 'cluster-grenade', count = 1, max_range = 40, tick_speed = 3},
    ['artillery-shell'] = {name = 'artillery-projectile', count = 1, max_range = 60, tick_speed = 3},
    ['cannon-shell'] = {name = 'cannon-projectile', count = 1, max_range = 60, tick_speed = 1},
    ['explosive-cannon-shell'] = {name = 'explosive-cannon-projectile', count = 1, max_range = 60, tick_speed = 1},
    ['explosive-uranium-cannon-shell'] = {
        name = 'explosive-uranium-cannon-projectile',
        count = 1,
        max_range = 60,
        tick_speed = 1
    },
    ['uranium-cannon-shell'] = {name = 'uranium-cannon-projectile', count = 1, max_range = 60, tick_speed = 1},
    ['atomic-bomb'] = {name = 'atomic-rocket', count = 1, max_range = 80, tick_speed = 20},
    ['explosive-rocket'] = {name = 'explosive-rocket', count = 1, max_range = 48, tick_speed = 1},
    ['rocket'] = {name = 'rocket', count = 1, max_range = 48, tick_speed = 1},
    ['flamethrower-ammo'] = {name = 'flamethrower-fire-stream', count = 4, max_range = 28, tick_speed = 1},
    ['crude-oil-barrel'] = {name = 'flamethrower-fire-stream', count = 3, max_range = 24, tick_speed = 1},
    ['petroleum-gas-barrel'] = {name = 'flamethrower-fire-stream', count = 4, max_range = 24, tick_speed = 1},
    ['light-oil-barrel'] = {name = 'flamethrower-fire-stream', count = 4, max_range = 24, tick_speed = 1},
    ['heavy-oil-barrel'] = {name = 'flamethrower-fire-stream', count = 4, max_range = 24, tick_speed = 1},
    ['acid-stream-spitter-big'] = {
        name = 'acid-stream-spitter-big',
        count = 3,
        max_range = 16,
        tick_speed = 1,
        force = 'enemy'
    },
    ['lubricant-barrel'] = {name = 'acid-stream-spitter-big', count = 3, max_range = 16, tick_speed = 1},
    ['railgun-beam'] = {name = 'railgun-beam', count = 5, max_range = 40, tick_speed = 5},
    ['shotgun-shell'] = {name = 'shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['piercing-shotgun-shell'] = {name = 'piercing-shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['firearm-magazine'] = {name = 'shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['piercing-rounds-magazine'] = {name = 'piercing-shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['uranium-rounds-magazine'] = {name = 'piercing-shotgun-pellet', count = 32, max_range = 24, tick_speed = 1},
    ['cliff-explosives'] = {name = 'cliff-explosives', count = 1, max_range = 48, tick_speed = 2}
}

return Public
