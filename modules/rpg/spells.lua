local Public = {}

function Public.conjure_items()
    local spells = {}

    spells[#spells + 1] = {
        name = {'entity-name.stone-wall'},
        entityName = 'stone-wall',
        level = 10,
        type = 'item',
        mana_cost = 60,
        tick = 100,
        aoe = true,
        enabled = true,
        sprite = 'recipe/stone-wall'
    }
    spells[#spells + 1] = {
        name = {'entity-name.wooden-chest'},
        entityName = 'wooden-chest',
        level = 2,
        type = 'item',
        mana_cost = 50,
        tick = 100,
        aoe = true,
        enabled = true,
        sprite = 'recipe/wooden-chest'
    }
    spells[#spells + 1] = {
        name = {'entity-name.iron-chest'},
        entityName = 'iron-chest',
        level = 10,
        type = 'item',
        mana_cost = 110,
        tick = 200,
        aoe = true,
        enabled = true,
        sprite = 'recipe/iron-chest'
    }
    spells[#spells + 1] = {
        name = {'entity-name.steel-chest'},
        entityName = 'steel-chest',
        level = 15,
        type = 'item',
        mana_cost = 150,
        tick = 300,
        aoe = true,
        enabled = true,
        sprite = 'recipe/steel-chest'
    }
    spells[#spells + 1] = {
        name = {'entity-name.transport-belt'},
        entityName = 'transport-belt',
        level = 3,
        type = 'item',
        mana_cost = 80,
        tick = 100,
        aoe = true,
        enabled = true,
        sprite = 'recipe/transport-belt'
    }
    spells[#spells + 1] = {
        name = {'entity-name.fast-transport-belt'},
        entityName = 'fast-transport-belt',
        level = 20,
        type = 'item',
        mana_cost = 110,
        tick = 200,
        aoe = true,
        enabled = true,
        sprite = 'recipe/fast-transport-belt'
    }
    spells[#spells + 1] = {
        name = {'entity-name.express-transport-belt'},
        entityName = 'express-transport-belt',
        level = 60,
        type = 'item',
        mana_cost = 150,
        tick = 300,
        aoe = true,
        enabled = true,
        sprite = 'recipe/express-transport-belt'
    }
    spells[#spells + 1] = {
        name = {'entity-name.underground-belt'},
        entityName = 'underground-belt',
        level = 3,
        type = 'item',
        mana_cost = 80,
        tick = 100,
        aoe = true,
        enabled = true,
        sprite = 'recipe/underground-belt'
    }
    spells[#spells + 1] = {
        name = {'entity-name.fast-underground-belt'},
        entityName = 'fast-underground-belt',
        level = 20,
        type = 'item',
        mana_cost = 110,
        tick = 200,
        aoe = true,
        enabled = true,
        sprite = 'recipe/fast-underground-belt'
    }
    spells[#spells + 1] = {
        name = {'entity-name.express-underground-belt'},
        entityName = 'express-underground-belt',
        level = 60,
        type = 'item',
        mana_cost = 150,
        tick = 300,
        aoe = true,
        enabled = true,
        sprite = 'recipe/express-underground-belt'
    }
    spells[#spells + 1] = {
        name = {'entity-name.pipe'},
        entityName = 'pipe',
        level = 1,
        type = 'item',
        mana_cost = 50,
        tick = 100,
        aoe = true,
        enabled = true,
        sprite = 'recipe/pipe'
    }
    spells[#spells + 1] = {
        name = {'entity-name.pipe-to-ground'},
        entityName = 'pipe-to-ground',
        level = 1,
        type = 'item',
        mana_cost = 100,
        tick = 100,
        aoe = true,
        enabled = true,
        sprite = 'recipe/pipe-to-ground'
    }
    spells[#spells + 1] = {
        name = {'entity-name.tree'},
        entityName = 'tree-05',
        level = 70,
        type = 'entity',
        mana_cost = 100,
        tick = 350,
        aoe = true,
        enabled = true,
        sprite = 'entity/tree-05'
    }
    spells[#spells + 1] = {
        name = {'entity-name.sand-rock-big'},
        entityName = 'sand-rock-big',
        level = 80,
        type = 'entity',
        mana_cost = 80,
        tick = 350,
        aoe = true,
        enabled = true,
        sprite = 'entity/sand-rock-big'
    }
    spells[#spells + 1] = {
        name = {'entity-name.small-biter'},
        entityName = 'small-biter',
        level = 50,
        biter = true,
        type = 'entity',
        mana_cost = 55,
        tick = 200,
        enabled = true,
        sprite = 'entity/small-biter'
    }
    spells[#spells + 1] = {
        name = {'entity-name.small-spitter'},
        entityName = 'small-spitter',
        level = 50,
        biter = true,
        type = 'entity',
        mana_cost = 55,
        tick = 200,
        enabled = true,
        sprite = 'entity/small-spitter'
    }
    spells[#spells + 1] = {
        name = {'entity-name.medium-biter'},
        entityName = 'medium-biter',
        level = 70,
        biter = true,
        type = 'entity',
        mana_cost = 100,
        tick = 300,
        enabled = true,
        sprite = 'entity/medium-biter'
    }
    spells[#spells + 1] = {
        name = {'entity-name.medium-spitter'},
        entityName = 'medium-spitter',
        level = 70,
        biter = true,
        type = 'entity',
        mana_cost = 100,
        tick = 300,
        enabled = true,
        sprite = 'entity/medium-spitter'
    }
    spells[#spells + 1] = {
        name = {'entity-name.biter-spawner'},
        entityName = 'biter-spawner',
        level = 100,
        biter = true,
        type = 'entity',
        mana_cost = 800,
        tick = 1420,
        enabled = false,
        sprite = 'entity/biter-spawner'
    }
    spells[#spells + 1] = {
        name = {'entity-name.spitter-spawner'},
        entityName = 'spitter-spawner',
        level = 100,
        biter = true,
        type = 'entity',
        mana_cost = 800,
        tick = 1420,
        enabled = false,
        sprite = 'entity/spitter-spawner'
    }
    spells[#spells + 1] = {
        name = {'item-name.grenade'},
        entityName = 'grenade',
        target = true,
        amount = 1,
        damage = true,
        force = 'player',
        level = 30,
        type = 'special',
        mana_cost = 150,
        tick = 150,
        enabled = true,
        sprite = 'recipe/grenade'
    }
    spells[#spells + 1] = {
        name = {'item-name.cluster-grenade'},
        entityName = 'cluster-grenade',
        target = true,
        amount = 2,
        damage = true,
        force = 'player',
        level = 50,
        type = 'special',
        mana_cost = 250,
        tick = 200,
        enabled = true,
        sprite = 'recipe/cluster-grenade'
    }
    spells[#spells + 1] = {
        name = {'item-name.rocket'},
        entityName = 'rocket',
        range = 240,
        target = true,
        amount = 4,
        damage = true,
        force = 'enemy',
        level = 40,
        type = 'special',
        mana_cost = 60,
        tick = 320,
        enabled = true,
        sprite = 'recipe/rocket'
    }
    spells[#spells + 1] = {
        name = {'spells.pointy_explosives'},
        entityName = 'pointy_explosives',
        target = true,
        amount = 1,
        range = 0,
        damage = true,
        force = 'player',
        level = 70,
        type = 'special',
        mana_cost = 100,
        tick = 100,
        enabled = true,
        sprite = 'recipe/explosives'
    }
    spells[#spells + 1] = {
        name = {'spells.repair_aoe'},
        entityName = 'repair_aoe',
        target = true,
        amount = 1,
        range = 50,
        damage = false,
        force = 'player',
        level = 50,
        type = 'special',
        mana_cost = 200,
        tick = 100,
        enabled = true,
        sprite = 'recipe/repair-pack'
    }
    spells[#spells + 1] = {
        name = {'spells.acid_stream'},
        entityName = 'acid-stream-spitter-big',
        target = true,
        amount = 2,
        range = 0,
        damage = true,
        force = 'player',
        level = 70,
        type = 'special',
        mana_cost = 90,
        tick = 100,
        enabled = true,
        sprite = 'virtual-signal/signal-S'
    }
    spells[#spells + 1] = {
        name = {'spells.tank'},
        entityName = 'tank',
        amount = 1,
        capsule = true,
        force = 'player',
        level = 1000,
        type = 'special',
        mana_cost = 10000, -- they who know, will know
        tick = 320,
        enabled = false,
        sprite = 'entity/tank'
    }
    spells[#spells + 1] = {
        name = {'spells.spidertron'},
        entityName = 'spidertron',
        amount = 1,
        capsule = true,
        force = 'player',
        level = 2000,
        type = 'special',
        mana_cost = 19500, -- they who know, will know
        tick = 320,
        enabled = false,
        sprite = 'entity/spidertron'
    }
    spells[#spells + 1] = {
        name = {'spells.raw_fish'},
        entityName = 'raw-fish',
        target = false,
        amount = 4,
        capsule = true,
        damage = false,
        range = 30,
        force = 'player',
        level = 50,
        type = 'special',
        mana_cost = 140,
        tick = 320,
        enabled = true,
        sprite = 'item/raw-fish'
    }
    spells[#spells + 1] = {
        name = {'spells.dynamites'},
        entityName = 'explosives',
        target = false,
        amount = 2,
        capsule = true,
        damage = false,
        range = 30,
        force = 'player',
        level = 25,
        type = 'special',
        mana_cost = 140,
        tick = 320,
        enabled = true,
        sprite = 'item/explosives'
    }
    spells[#spells + 1] = {
        name = {'spells.comfylatron'},
        entityName = 'suicidal_comfylatron',
        target = false,
        amount = 4,
        damage = false,
        range = 30,
        force = 'player',
        level = 60,
        type = 'special',
        mana_cost = 250,
        tick = 320,
        enabled = true,
        sprite = 'entity/compilatron'
    }
    spells[#spells + 1] = {
        name = {'spells.distractor'},
        entityName = 'distractor-capsule',
        target = true,
        amount = 1,
        damage = false,
        range = 30,
        force = 'player',
        level = 50,
        type = 'special',
        mana_cost = 340,
        tick = 320,
        enabled = true,
        sprite = 'recipe/distractor-capsule'
    }
    spells[#spells + 1] = {
        name = {'spells.warp'},
        entityName = 'warp-gate',
        target = true,
        force = 'player',
        level = 60,
        type = 'special',
        mana_cost = 340,
        tick = 2000,
        enabled = true,
        sprite = 'virtual-signal/signal-W'
    }
    return spells
end

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
    ['shotgun-shell'] = {name = 'shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['piercing-shotgun-shell'] = {name = 'piercing-shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['firearm-magazine'] = {name = 'shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['piercing-rounds-magazine'] = {name = 'piercing-shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['uranium-rounds-magazine'] = {name = 'piercing-shotgun-pellet', count = 32, max_range = 24, tick_speed = 1},
    ['cliff-explosives'] = {name = 'cliff-explosives', count = 1, max_range = 48, tick_speed = 2}
}

return Public
