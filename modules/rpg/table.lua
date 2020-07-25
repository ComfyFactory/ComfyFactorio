-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'
local Gui = require 'utils.gui'

local this = {
    rpg_extra = {},
    rpg_t = {}
}

--! Gui Frames
local settings_frame_name = Gui.uid_name()
local save_button_name = Gui.uid_name()
local discard_button_name = Gui.uid_name()
local draw_main_frame_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local settings_button_name = Gui.uid_name()

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {}

Public.rpg_frame_icons = {
    'entity/small-worm-turret',
    'entity/medium-worm-turret',
    'entity/big-worm-turret',
    'entity/behemoth-worm-turret',
    'entity/small-biter',
    'entity/small-biter',
    'entity/small-spitter',
    'entity/medium-biter',
    'entity/medium-biter',
    'entity/medium-spitter',
    'entity/big-biter',
    'entity/big-biter',
    'entity/big-spitter',
    'entity/behemoth-biter',
    'entity/behemoth-biter',
    'entity/behemoth-spitter'
}

Public.points_per_level = 5

Public.experience_levels = {0}
for a = 1, 9999, 1 do
    Public.experience_levels[#Public.experience_levels + 1] =
        Public.experience_levels[#Public.experience_levels] + a * 8
end

Public.die_cause = {
    ['ammo-turret'] = true,
    ['electric-turret'] = true,
    ['fluid-turret'] = true
}

Public.nth_tick = 18001
Public.visuals_delay = 1800
Public.xp_floating_text_color = {157, 157, 157}

Public.teller_global_pool = '[color=blue]Global Pool Reward:[/color] \n'
Public.teller_level_limit = '[color=blue]Level Limit:[/color] \n'

Public.enemy_types = {
    ['unit'] = true,
    ['unit-spawner'] = true,
    ['turret'] = true
}

Public.classes = {
    ['engineer'] = 'ENGINEER',
    ['strength'] = 'MINER',
    ['magicka'] = 'SCIENTIST',
    ['dexterity'] = 'BEASTMASTER',
    ['vitality'] = 'SOLDIER'
}

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

function Public.reset_table()
    this.rpg_extra.debug = false
    this.rpg_extra.breached_walls = 1
    this.rpg_extra.reward_new_players = 0
    this.rpg_extra.level_limit_enabled = false
    this.rpg_extra.global_pool = 0
    this.rpg_extra.personal_tax_rate = 0.3
    this.rpg_extra.leftover_pool = 0
    this.rpg_extra.turret_kills_to_global_pool = true
    this.rpg_extra.difficulty = false
    this.rpg_extra.surface_name = 'nauvis'
    this.rpg_extra.enable_health_and_mana_bars = false
    this.rpg_extra.enable_mana = false
    this.rpg_extra.mana_limit = 1500
    this.rpg_extra.enable_wave_defense = false
    this.rpg_extra.enable_flame_boots = false
    this.rpg_extra.mana_per_tick = 0.1
    this.rpg_extra.force_mana_per_tick = false
    this.rpg_extra.enable_stone_path = false
    this.rpg_extra.enable_one_punch = true
    this.rpg_extra.enable_one_punch_globally = false
    this.rpg_t = {}
    this.rpg_extra.rpg_xp_yield = {
        ['behemoth-biter'] = 16,
        ['behemoth-spitter'] = 16,
        ['behemoth-worm-turret'] = 64,
        ['big-biter'] = 8,
        ['big-spitter'] = 8,
        ['big-worm-turret'] = 48,
        ['biter-spawner'] = 64,
        ['character'] = 16,
        ['gun-turret'] = 8,
        ['laser-turret'] = 16,
        ['medium-biter'] = 4,
        ['medium-spitter'] = 4,
        ['medium-worm-turret'] = 32,
        ['small-biter'] = 1,
        ['small-spitter'] = 1,
        ['small-worm-turret'] = 16,
        ['spitter-spawner'] = 64
    }
end

--- Gets value from table
---@param key <string>
function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

--- Sets value to table
---@param key <string>
function Public.set(key)
    if key then
        return this[key]
    else
        return this
    end
end

--- Toggle debug - when you need to troubleshoot.
function Public.toggle_debug()
    if this.rpg_extra.debug then
        this.rpg_extra.debug = false
    else
        this.rpg_extra.debug = true
    end
end

--- Debug only - when you need to troubleshoot.
---@param str <string>
function Public.debug_log(str)
    if not this.rpg_extra.debug then
        return
    end
    print(str)
end

--- Sets surface name for rpg_v2 to use
---@param name <string>
function Public.set_surface_name(name)
    if name then
        this.rpg_extra.surface_name = name
    else
        return error('No surface name given.', 2)
    end
end

--- Enables the bars that shows above the player character.
--- If you disable mana but enable <enable_health_and_mana_bars> then only health will be shown
---@param value <boolean>
function Public.enable_health_and_mana_bars(value)
    if value then
        this.rpg_extra.enable_health_and_mana_bars = value
    else
        this.rpg_extra.enable_health_and_mana_bars = false
    end
end

--- Enables the mana feature that allows players to spawn entities.
---@param value <boolean>
function Public.enable_mana(value)
    if value then
        this.rpg_extra.enable_mana = value
    else
        this.rpg_extra.enable_mana = false
    end
end

--- This should only be enabled if wave_defense is enabled.
--- It boosts the amount of xp the players get after x amount of waves.
---@param value <boolean>
function Public.enable_wave_defense(value)
    if value then
        this.rpg_extra.enable_wave_defense = value
    else
        this.rpg_extra.enable_wave_defense = false
    end
end

--- Enables/disabled flame boots.
---@param value <boolean>
function Public.enable_flame_boots(value)
    if value then
        this.rpg_extra.enable_flame_boots = value
    else
        this.rpg_extra.enable_flame_boots = false
    end
end

--- Enables/disabled personal tax.
---@param value <boolean>
function Public.personal_tax_rate(value)
    if value then
        this.rpg_extra.personal_tax_rate = value
    else
        this.rpg_extra.personal_tax_rate = nil
    end
end

--- Enables/disabled stone-path-tile creation on mined.
---@param value <boolean>
function Public.enable_stone_path(value)
    if value then
        this.rpg_extra.enable_stone_path = value
    else
        this.rpg_extra.enable_stone_path = nil
    end
end

--- Enables/disabled stone-path-tile creation on mined.
---@param value <boolean>
function Public.enable_one_punch(value)
    if value then
        this.rpg_extra.enable_one_punch = value
    else
        this.rpg_extra.enable_one_punch = nil
    end
end

--- Enables/disabled stone-path-tile creation on mined.
---@param value <boolean>
function Public.enable_one_punch_globally(value)
    if value then
        this.rpg_extra.enable_one_punch_globally = value
    else
        this.rpg_extra.enable_one_punch_globally = nil
    end
end

Public.settings_frame_name = settings_frame_name
Public.save_button_name = save_button_name
Public.discard_button_name = discard_button_name
Public.draw_main_frame_name = draw_main_frame_name
Public.main_frame_name = main_frame_name
Public.settings_button_name = settings_button_name

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
