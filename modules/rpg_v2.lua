local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Color = require 'utils.color_presets'
local Alert = require 'utils.alert'
local Tabs = require 'comfy_panel.main'
local Task = require 'utils.task'
local Token = require 'utils.token'
local P = require 'player_modifiers'
local WD = require 'modules.wave_defense.table'
local Math2D = require 'math2d'
local Session = require 'utils.session_data'

local points_per_level = 5
local nth_tick = 18001
local visuals_delay = 1800
local level_up_floating_text_color = {0, 205, 0}
local xp_floating_text_color = {157, 157, 157}
local experience_levels = {0}
for a = 1, 9999, 1 do
    experience_levels[#experience_levels + 1] = experience_levels[#experience_levels] + a * 8
end
local gain_info_tooltip = 'XP gain from mining, moving, crafting, repairing and combat.'
local reset_tooltip = 'ONE-TIME reset if you picked the wrong path (this will keep your points)'

local teller_global_pool = '[color=blue]Global Pool Reward:[/color] \n'
local teller_level_limit = '[color=blue]Level Limit:[/color] \n'

-- Gui Frames
local draw_main_frame_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local settings_frame_name = Gui.uid_name()
local settings_button_name = Gui.uid_name()
local save_button_name = Gui.uid_name()
local discard_button_name = Gui.uid_name()

--- Tables
local rpg_t = {}
local rpg_extra = {
    debug = false,
    breached_walls = 1,
    reward_new_players = 0,
    level_limit_enabled = false,
    global_pool = 0,
    personal_tax_rate = 0.3,
    leftover_pool = 0,
    turret_kills_to_global_pool = true,
    difficulty = false,
    surface_name = 'nauvis',
    enable_health_and_mana_bars = false,
    enable_mana = false,
    enable_wave_defense = false,
    enable_flame_boots = false,
    mana_per_tick = 0.1,
    force_mana_per_tick = false,
    enable_stone_path = false
}
local rpg_frame_icons = {
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

local rpg_xp_yield = {
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

local projectile_types = {
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

Global.register(
    {rpg_t = rpg_t, rpg_frame_icons = rpg_frame_icons, rpg_extra = rpg_extra, rpg_xp_yield = rpg_xp_yield},
    function(tbl)
        rpg_t = tbl.rpg_t
        rpg_frame_icons = tbl.rpg_frame_icons
        rpg_extra = tbl.rpg_extra
        rpg_xp_yield = tbl.rpg_xp_yield
    end
)

local Public = {}

local classes = {
    ['engineer'] = 'ENGINEER',
    ['strength'] = 'MINER',
    ['magicka'] = 'SCIENTIST',
    ['dexterity'] = 'BEASTMASTER',
    ['vitality'] = 'SOLDIER'
}

local enemy_types = {
    ['unit'] = true,
    ['unit-spawner'] = true,
    ['turret'] = true
}

local die_cause = {
    ['ammo-turret'] = true,
    ['electric-turret'] = true,
    ['fluid-turret'] = true
}

local conjure_items = {
    [1] = {
        name = 'Stone Wall',
        obj_to_create = 'stone-wall',
        level = 10,
        target = true,
        type = 'item',
        mana_cost = 35,
        tick = 160,
        enabled = true
    },
    [2] = {
        name = 'Wooden Chest',
        obj_to_create = 'wooden-chest',
        level = 2,
        target = true,
        type = 'item',
        mana_cost = 30,
        tick = 160,
        enabled = true
    },
    [3] = {
        name = 'Iron Chest',
        obj_to_create = 'iron-chest',
        level = 10,
        target = true,
        type = 'item',
        mana_cost = 40,
        tick = 260,
        enabled = true
    },
    [4] = {
        name = 'Steel Chest',
        obj_to_create = 'steel-chest',
        level = 15,
        target = true,
        type = 'item',
        mana_cost = 50,
        tick = 360,
        enabled = true
    },
    [5] = {
        name = 'Transport Belt',
        obj_to_create = 'transport-belt',
        level = 3,
        target = true,
        type = 'item',
        mana_cost = 40,
        tick = 160,
        enabled = true
    },
    [6] = {
        name = 'Fast Transport Belt',
        obj_to_create = 'fast-transport-belt',
        level = 20,
        target = true,
        type = 'item',
        mana_cost = 50,
        tick = 260,
        enabled = true
    },
    [7] = {
        name = 'Express Transport Belt',
        obj_to_create = 'express-transport-belt',
        level = 60,
        target = true,
        type = 'item',
        mana_cost = 60,
        tick = 360,
        enabled = true
    },
    [8] = {
        name = 'Underground Belt',
        obj_to_create = 'underground-belt',
        level = 3,
        target = true,
        type = 'item',
        mana_cost = 40,
        tick = 160,
        enabled = true
    },
    [9] = {
        name = 'Fast Underground Belt',
        obj_to_create = 'fast-underground-belt',
        level = 20,
        target = true,
        type = 'item',
        mana_cost = 50,
        tick = 260,
        enabled = true
    },
    [10] = {
        name = 'Express Underground Belt',
        obj_to_create = 'express-underground-belt',
        level = 60,
        target = true,
        type = 'item',
        mana_cost = 60,
        tick = 360,
        enabled = true
    },
    [11] = {
        name = 'Sandy Rock',
        obj_to_create = 'sand-rock-big',
        level = 80,
        target = true,
        type = 'entity',
        mana_cost = 80,
        tick = 420,
        enabled = true
    },
    [12] = {
        name = 'Smol Biter',
        obj_to_create = 'small-biter',
        level = 50,
        target = true,
        biter = true,
        type = 'entity',
        mana_cost = 55,
        tick = 220,
        enabled = true
    },
    [13] = {
        name = 'Smol Spitter',
        obj_to_create = 'small-spitter',
        level = 50,
        target = true,
        biter = true,
        type = 'entity',
        mana_cost = 55,
        tick = 220,
        enabled = true
    },
    [14] = {
        name = 'Medium Biter',
        obj_to_create = 'medium-biter',
        level = 70,
        target = true,
        biter = true,
        type = 'entity',
        mana_cost = 77,
        tick = 420,
        enabled = true
    },
    [15] = {
        name = 'Medium Spitter',
        obj_to_create = 'medium-spitter',
        level = 70,
        target = true,
        type = 'entity',
        mana_cost = 77,
        tick = 420,
        enabled = true
    },
    [16] = {
        name = 'Bitter Spawner',
        obj_to_create = 'biter-spawner',
        level = 100,
        target = true,
        biter = true,
        type = 'entity',
        mana_cost = 300,
        tick = 1420,
        enabled = true
    },
    [17] = {
        name = 'Spitter Spawner',
        obj_to_create = 'spitter-spawner',
        level = 100,
        target = true,
        biter = true,
        type = 'entity',
        mana_cost = 300,
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
        mana_cost = 60,
        tick = 420,
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
        mana_cost = 80,
        tick = 620,
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
        tick = 420,
        enabled = true
    },
    [21] = {
        name = 'Bitter Spew',
        obj_to_create = 'acid-stream-spitter-big',
        target = true,
        amount = 1,
        range = 0,
        force = 'player',
        level = 70,
        type = 'special',
        mana_cost = 90,
        tick = 520,
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
        mana_cost = 150,
        tick = 320,
        enabled = true
    }
}

local desync =
    Token.register(
    function(data)
        local entity = data.entity
        if not entity or not entity.valid then
            return
        end
        local surface = data.surface
        local fake_shooter = surface.create_entity({name = 'character', position = entity.position, force = 'enemy'})
        for i = 1, 3 do
            surface.create_entity(
                {
                    name = 'explosive-rocket',
                    position = entity.position,
                    force = 'enemy',
                    speed = 1,
                    max_range = 1,
                    target = entity,
                    source = fake_shooter
                }
            )
        end
        if fake_shooter and fake_shooter.valid then
            fake_shooter.destroy()
        end
    end
)

local travelings = {
    'bzzZZrrt',
    'WEEEeeeeeee',
    'out of my way son',
    'on my way',
    'i need to leave',
    'comfylatron seeking target',
    'gotta go fast',
    'gas gas gas',
    'comfylatron coming through'
}

local function suicidal_comfylatron(pos, surface)
    local str = travelings[math.random(1, #travelings)]
    local symbols = {'', '!', '!', '!!', '..'}
    str = str .. symbols[math.random(1, #symbols)]
    local text = str
    local e =
        surface.create_entity(
        {
            name = 'compilatron',
            position = {x = pos.x, y = pos.y + 2},
            force = 'player'
        }
    )
    surface.create_entity(
        {
            name = 'compi-speech-bubble',
            position = e.position,
            source = e,
            text = text
        }
    )
    local entities =
        surface.find_entities_filtered(
        {
            type = {'unit', 'unit-spawner', 'turret'},
            force = 'enemy',
            area = {{e.position.x - 80, e.position.y - 80}, {e.position.x + 80, e.position.y + 80}},
            limit = 1
        }
    )

    if entities then
        for _, entity in pairs(entities) do
            if entity.name ~= 'compilatron' and entity.active then
                e.set_command(
                    {
                        type = defines.command.attack,
                        target = entity,
                        distraction = defines.distraction.none
                    }
                )
            else
                e.surface.create_entity({name = 'medium-explosion', position = e.position})
                e.surface.create_entity(
                    {name = 'flying-text', position = e.position, text = 'desync', color = {r = 150, g = 0, b = 0}}
                )
                e.die()
            end
        end
        local data = {
            entity = e,
            surface = surface
        }
        Task.set_timeout_in_ticks(300, desync, data)
    else
        e.surface.create_entity({name = 'medium-explosion', position = e.position})
        e.surface.create_entity(
            {name = 'flying-text', position = e.position, text = 'desync', color = {r = 150, g = 0, b = 0}}
        )
        e.die()
    end
end

local function create_healthbar(player, size)
    return rendering.draw_sprite(
        {
            sprite = 'virtual-signal/signal-white',
            tint = Color.green,
            x_scale = size * 8,
            y_scale = size - 0.2,
            render_layer = 'light-effect',
            target = player.character,
            target_offset = {0, -2.5},
            surface = player.surface
        }
    )
end

local function create_manabar(player, size)
    return rendering.draw_sprite(
        {
            sprite = 'virtual-signal/signal-white',
            tint = Color.blue,
            x_scale = size * 8,
            y_scale = size - 0.2,
            render_layer = 'light-effect',
            target = player.character,
            target_offset = {0, -2.0},
            surface = player.surface
        }
    )
end

local function set_bar(min, max, id, mana)
    local m = min / max
    if not rendering.is_valid(id) then
        return
    end
    local x_scale = rendering.get_y_scale(id) * 8
    rendering.set_x_scale(id, x_scale * m)
    if not mana then
        rendering.set_color(id, {math.floor(255 - 255 * m), math.floor(200 * m), 0})
    end
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.index] then
        return false
    end
    return true
end

local function level_limit_exceeded(player, value)
    if not rpg_extra.level_limit_enabled then
        return false
    end

    local limits = {
        [1] = 30,
        [2] = 50,
        [3] = 70,
        [4] = 90,
        [5] = 110,
        [6] = 130,
        [7] = 150,
        [8] = 170,
        [9] = 190,
        [10] = 210
    }

    local level = rpg_t[player.index].level
    local zone = rpg_extra.breached_walls
    if zone >= 11 then
        zone = 10
    end
    if value then
        return limits[zone]
    end

    if level >= limits[zone] then
        return true
    end
    return false
end

local function level_up_effects(player)
    local position = {x = player.position.x - 0.75, y = player.position.y - 1}
    player.surface.create_entity(
        {name = 'flying-text', position = position, text = '+LVL ', color = level_up_floating_text_color}
    )
    local b = 0.75
    for a = 1, 5, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        player.surface.create_entity(
            {name = 'flying-text', position = p, text = '✚', color = {255, math.random(0, 100), 0}}
        )
    end
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.40}
end

local function xp_effects(player)
    local position = {x = player.position.x - 0.75, y = player.position.y - 1}
    player.surface.create_entity(
        {name = 'flying-text', position = position, text = '+XP', color = level_up_floating_text_color}
    )
    local b = 0.75
    for a = 1, 5, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        player.surface.create_entity(
            {name = 'flying-text', position = p, text = '✚', color = {255, math.random(0, 100), 0}}
        )
    end
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.40}
end

local function get_melee_modifier(player)
    return (rpg_t[player.index].strength - 10) * 0.10
end

local function get_heal_modifier(player)
    return (rpg_t[player.index].vitality - 10) * 0.02
end

local function get_mana_modifier(player)
    if rpg_t[player.index].level <= 40 then
        return (rpg_t[player.index].magicka - 10) * 0.02000
    elseif rpg_t[player.index].level <= 80 then
        return (rpg_t[player.index].magicka - 10) * 0.01800
    else
        return (rpg_t[player.index].magicka - 10) * 0.01400
    end
end

local function get_life_on_hit(player)
    return (rpg_t[player.index].vitality - 10) * 0.4
end

local function get_one_punch_chance(player)
    if rpg_t[player.index].strength < 100 then
        return 0
    end
    local chance = math.round(rpg_t[player.index].strength * 0.01, 1)
    if chance > 100 then
        chance = 100
    end
    return chance
end

local function draw_gui_char_button(player)
    if player.gui.top[draw_main_frame_name] then
        return
    end
    local b = player.gui.top.add({type = 'sprite-button', name = draw_main_frame_name, caption = 'CHAR'})
    b.style.font_color = {165, 165, 165}
    b.style.font = 'heading-1'
    b.style.minimal_height = 38
    b.style.minimal_width = 60
    b.style.padding = 0
    b.style.margin = 0
end

local function update_char_button(player)
    if not player.gui.top[draw_main_frame_name] then
        draw_gui_char_button(player)
    end
    if rpg_t[player.index].points_to_distribute > 0 then
        player.gui.top[draw_main_frame_name].style.font_color = {245, 0, 0}
    else
        player.gui.top[draw_main_frame_name].style.font_color = {175, 175, 175}
    end
end

local function update_player_stats(player)
    local player_modifiers = P.get_table()
    local strength = rpg_t[player.index].strength - 10
    player_modifiers[player.index].character_inventory_slots_bonus['rpg'] = math.round(strength * 0.2, 3)
    player_modifiers[player.index].character_mining_speed_modifier['rpg'] = math.round(strength * 0.007, 3)
    player_modifiers[player.index].character_maximum_following_robot_count_bonus['rpg'] = math.round(strength * 0.07, 1)

    local magic = rpg_t[player.index].magicka - 10
    local v = magic * 0.22
    player_modifiers[player.index].character_build_distance_bonus['rpg'] = math.round(v * 0.25, 3)
    player_modifiers[player.index].character_item_drop_distance_bonus['rpg'] = math.round(v * 0.25, 3)
    player_modifiers[player.index].character_reach_distance_bonus['rpg'] = math.round(v * 0.25, 3)
    player_modifiers[player.index].character_loot_pickup_distance_bonus['rpg'] = math.round(v * 0.22, 3)
    player_modifiers[player.index].character_item_pickup_distance_bonus['rpg'] = math.round(v * 0.25, 3)
    player_modifiers[player.index].character_resource_reach_distance_bonus['rpg'] = math.round(v * 0.15, 3)
    rpg_t[player.index].mana_max = math.round(rpg_t[player.index].mana_max + math.round(v * 0.9, 3))

    local dexterity = rpg_t[player.index].dexterity - 10
    player_modifiers[player.index].character_running_speed_modifier['rpg'] = math.round(dexterity * 0.0015, 3)
    player_modifiers[player.index].character_crafting_speed_modifier['rpg'] = math.round(dexterity * 0.015, 3)

    player_modifiers[player.index].character_health_bonus['rpg'] =
        math.round((rpg_t[player.index].vitality - 10) * 6, 3)

    P.update_player_modifiers(player)
end

local function get_class(player)
    local average =
        (rpg_t[player.index].strength + rpg_t[player.index].magicka + rpg_t[player.index].dexterity +
        rpg_t[player.index].vitality) /
        4
    local high_attribute = 0
    local high_attribute_name = ''
    for _, attribute in pairs({'strength', 'magicka', 'dexterity', 'vitality'}) do
        if rpg_t[player.index][attribute] > high_attribute then
            high_attribute = rpg_t[player.index][attribute]
            high_attribute_name = attribute
        end
    end
    if high_attribute < average + average * 0.25 then
        high_attribute_name = 'engineer'
    end
    return classes[high_attribute_name]
end

local function add_gui_description(element, value, width, tooltip)
    local e = element.add({type = 'label', caption = value})
    e.tooltip = tooltip or ''
    e.style.single_line = false
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.maximal_height = 40
    e.style.minimal_height = 38
    e.style.font = 'default-bold'
    e.style.font_color = {175, 175, 200}
    e.style.horizontal_align = 'right'
    e.style.vertical_align = 'center'
    return e
end

local function add_gui_stat(element, value, width, tooltip, name)
    local e = element.add({type = 'sprite-button', name = name or nil, caption = value})
    e.tooltip = tooltip or ''
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.maximal_height = 38
    e.style.minimal_height = 38
    e.style.font = 'default-bold'
    e.style.font_color = {222, 222, 222}
    e.style.horizontal_align = 'center'
    e.style.vertical_align = 'center'
    return e
end

local function add_gui_increase_stat(element, name, player)
    local sprite = 'virtual-signal/signal-red'
    local symbol = '✚'
    if rpg_t[player.index].points_to_distribute <= 0 then
        sprite = 'virtual-signal/signal-black'
    end
    local e = element.add({type = 'sprite-button', name = name, caption = symbol, sprite = sprite})
    e.style.maximal_height = 38
    e.style.minimal_height = 38
    e.style.maximal_width = 38
    e.style.minimal_width = 38
    e.style.font = 'default-large-semibold'
    e.style.font_color = {0, 0, 0}
    e.style.horizontal_align = 'center'
    e.style.vertical_align = 'center'
    e.style.padding = 0
    e.style.margin = 0
    e.tooltip =
        'Right-click to allocate ' .. tostring(points_per_level) .. ' points.\nShift + click to allocate all points.'

    return e
end

local function add_separator(element, width)
    local e = element.add({type = 'line'})
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.minimal_height = 12
    return e
end

local function create_input_element(frame, type, value, items, index)
    if type == 'slider' then
        return frame.add({type = 'slider', value = value, minimum_value = 0, maximum_value = 1})
    end
    if type == 'boolean' then
        return frame.add({type = 'checkbox', state = value})
    end
    if type == 'dropdown' then
        return frame.add({type = 'drop-down', name = 'admin_player_select', items = items, selected_index = index})
    end
    return frame.add({type = 'text-box', text = value})
end

local function extra_settings(player)
    local player_modifiers = P.get_table()
    local trusted = Session.get_trusted_table()
    local main_frame =
        player.gui.screen.add(
        {
            type = 'frame',
            name = settings_frame_name,
            caption = 'RPG Settings',
            direction = 'vertical'
        }
    )
    main_frame.auto_center = true

    local main_frame_style = main_frame.style
    main_frame_style.width = 500

    local info_text =
        main_frame.add({type = 'label', caption = 'Common RPG settings. These settings are per player basis.'})
    local info_text_style = info_text.style
    info_text_style.single_line = false
    info_text_style.bottom_padding = 5
    info_text_style.left_padding = 5
    info_text_style.right_padding = 5
    info_text_style.top_padding = 5
    info_text_style.width = 370

    local scroll_pane = main_frame.add({type = 'scroll-pane'})
    local scroll_style = scroll_pane.style
    scroll_style.vertically_squashable = true
    scroll_style.maximal_height = 800
    scroll_style.bottom_padding = 5
    scroll_style.left_padding = 5
    scroll_style.right_padding = 5
    scroll_style.top_padding = 5

    local setting_grid = scroll_pane.add({type = 'table', column_count = 2})

    local health_bar_gui_input
    if rpg_extra.enable_health_and_mana_bars then
        local health_bar_label =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Show health/mana bar?'
            }
        )

        local style = health_bar_label.style
        style.horizontally_stretchable = true
        style.height = 35
        style.vertical_align = 'center'

        local health_bar_input = setting_grid.add({type = 'flow'})
        local input_style = health_bar_input.style
        input_style.height = 35
        input_style.vertical_align = 'center'
        health_bar_gui_input = create_input_element(health_bar_input, 'boolean', rpg_t[player.index].show_bars)
        health_bar_gui_input.tooltip = 'Checked = true\nUnchecked = false'
        if not rpg_extra.enable_mana then
            health_bar_label.caption = 'Show health bar?'
        end
    end

    local reset_label =
        setting_grid.add(
        {
            type = 'label',
            caption = 'Reset your skillpoints?',
            tooltip = ''
        }
    )

    local reset_label_style = reset_label.style
    reset_label_style.horizontally_stretchable = true
    reset_label_style.height = 35
    reset_label_style.vertical_align = 'center'

    local reset_input = setting_grid.add({type = 'flow'})
    local reset_input_style = reset_input.style
    reset_input_style.height = 35
    reset_input_style.vertical_align = 'center'
    local reset_gui_input = create_input_element(reset_input, 'boolean', false)

    if not rpg_t[player.index].reset then
        if not trusted[player.name] then
            reset_gui_input.enabled = false
            reset_gui_input.tooltip = 'Not trusted.\nChecked = true\nUnchecked = false'
            goto continue
        end
        if rpg_t[player.index].level <= 49 then
            reset_gui_input.enabled = false
            reset_gui_input.tooltip = 'Level requirement: 50\nChecked = true\nUnchecked = false'
            reset_label.tooltip = 'Level requirement: 50\nCan only reset once.'
        else
            reset_gui_input.enabled = true
            reset_gui_input.tooltip = reset_tooltip
            reset_label.tooltip = reset_tooltip
        end
    else
        reset_gui_input.enabled = false
        reset_gui_input.tooltip = 'All used up!'
    end

    ::continue::

    local magic_pickup_label =
        setting_grid.add(
        {
            type = 'label',
            caption = 'Enable item reach distance bonus?',
            tooltip = 'Don´t feeling like picking up others people loot?\nYou can toggle it here.'
        }
    )

    local magic_pickup_label_style = magic_pickup_label.style
    magic_pickup_label_style.horizontally_stretchable = true
    magic_pickup_label_style.height = 35
    magic_pickup_label_style.vertical_align = 'center'

    local magic_pickup_input = setting_grid.add({type = 'flow'})
    local magic_pickup_input_style = magic_pickup_input.style
    magic_pickup_input_style.height = 35
    magic_pickup_input_style.vertical_align = 'center'
    local reach_mod
    if
        player_modifiers.disabled_modifier[player.index] and
            player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus
     then
        reach_mod = not player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus
    else
        reach_mod = true
    end
    local magic_pickup_gui_input = create_input_element(magic_pickup_input, 'boolean', reach_mod)
    magic_pickup_gui_input.tooltip = 'Checked = true\nUnchecked = false'

    local movement_speed_label =
        setting_grid.add(
        {
            type = 'label',
            caption = 'Enable movement speed bonus?',
            tooltip = 'Don´t feeling like running like the flash?\nYou can toggle it here.'
        }
    )

    local movement_speed_label_style = movement_speed_label.style
    movement_speed_label_style.horizontally_stretchable = true
    movement_speed_label_style.height = 35
    movement_speed_label_style.vertical_align = 'center'

    local movement_speed_input = setting_grid.add({type = 'flow'})
    local movement_speed_input_style = movement_speed_input.style
    movement_speed_input_style.height = 35
    movement_speed_input_style.vertical_align = 'center'
    local speed_mod
    if
        player_modifiers.disabled_modifier[player.index] and
            player_modifiers.disabled_modifier[player.index].character_running_speed_modifier
     then
        speed_mod = not player_modifiers.disabled_modifier[player.index].character_running_speed_modifier
    else
        speed_mod = true
    end
    local movement_speed_gui_input = create_input_element(movement_speed_input, 'boolean', speed_mod)
    movement_speed_gui_input.tooltip = 'Checked = true\nUnchecked = false'

    local enable_entity_gui_input
    local conjure_gui_input
    local flame_boots_gui_input
    local stone_path_gui_input

    if rpg_extra.enable_stone_path then
        local stone_path_label =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Enable stone-path when mining?',
                tooltip = 'Enabling this will automatically create stone-path when you mine.'
            }
        )

        local stone_path_label_style = stone_path_label.style
        stone_path_label_style.horizontally_stretchable = true
        stone_path_label_style.height = 35
        stone_path_label_style.vertical_align = 'center'

        local stone_path_input = setting_grid.add({type = 'flow'})
        local stone_path_input_style = stone_path_input.style
        stone_path_input_style.height = 35
        stone_path_input_style.vertical_align = 'center'
        local stone_path
        if rpg_t[player.index].stone_path then
            stone_path = rpg_t[player.index].stone_path
        else
            stone_path = false
        end
        stone_path_gui_input = create_input_element(stone_path_input, 'boolean', stone_path)

        if rpg_t[player.index].level <= 20 then
            stone_path_gui_input.enabled = false
            stone_path_gui_input.tooltip = 'Level requirement: 20\nChecked = true\nUnchecked = false'
            stone_path_label.tooltip = 'Level requirement: 20'
        else
            stone_path_gui_input.enabled = true
            stone_path_gui_input.tooltip = 'Checked = true\nUnchecked = false'
        end
    end

    if rpg_extra.enable_flame_boots then
        local flame_boots_label =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Enable flame boots?',
                tooltip = 'When the bullets simply don´t bite.'
            }
        )

        local flame_boots_label_style = flame_boots_label.style
        flame_boots_label_style.horizontally_stretchable = true
        flame_boots_label_style.height = 35
        flame_boots_label_style.vertical_align = 'center'

        local flame_boots_input = setting_grid.add({type = 'flow'})
        local flame_boots_input_style = flame_boots_input.style
        flame_boots_input_style.height = 35
        flame_boots_input_style.vertical_align = 'center'
        local flame_mod
        if rpg_t[player.index].flame_boots then
            flame_mod = rpg_t[player.index].flame_boots
        else
            flame_mod = false
        end
        flame_boots_gui_input = create_input_element(flame_boots_input, 'boolean', flame_mod)

        if rpg_t[player.index].level <= 100 then
            flame_boots_gui_input.enabled = false
            flame_boots_gui_input.tooltip = 'Level requirement: 100\nChecked = true\nUnchecked = false'
            flame_boots_label.tooltip = 'Level requirement: 100'
        else
            flame_boots_gui_input.enabled = true
            flame_boots_gui_input.tooltip = 'Checked = true\nUnchecked = false'
        end
    end
    if rpg_extra.enable_mana then
        local enable_entity =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Enable spawning with raw-fish?',
                tooltip = 'When simply constructing items is not enough.\nNOTE! Use Raw-fish to cast spells.'
            }
        )

        local enable_entity_style = enable_entity.style
        enable_entity_style.horizontally_stretchable = true
        enable_entity_style.height = 35
        enable_entity_style.vertical_align = 'center'

        local entity_input = setting_grid.add({type = 'flow'})
        local entity_input_style = entity_input.style
        entity_input_style.height = 35
        entity_input_style.vertical_align = 'center'
        local entity_mod
        if rpg_t[player.index].enable_entity_spawn then
            entity_mod = rpg_t[player.index].enable_entity_spawn
        else
            entity_mod = false
        end
        enable_entity_gui_input = create_input_element(entity_input, 'boolean', entity_mod)

        local conjure_label =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Select what entity to spawn',
                tooltip = ''
            }
        )

        local names = {}

        for _, items in pairs(conjure_items) do
            names[#names + 1] = items.name
        end

        local conjure_label_style = conjure_label.style
        conjure_label_style.horizontally_stretchable = true
        conjure_label_style.height = 35
        conjure_label_style.vertical_align = 'center'

        local conjure_input = setting_grid.add({type = 'flow'})
        local conjure_input_style = conjure_input.style
        conjure_input_style.height = 35
        conjure_input_style.vertical_align = 'center'
        conjure_gui_input =
            create_input_element(conjure_input, 'dropdown', false, names, rpg_t[player.index].dropdown_select_index)

        for _, entity in pairs(conjure_items) do
            if entity.type == 'item' then
                conjure_label.tooltip =
                    conjure_label.tooltip ..
                    '[item=' ..
                        entity.obj_to_create ..
                            '] requires ' .. entity.mana_cost .. ' mana to cast. Level: ' .. entity.level .. '\n'
            elseif entity.type == 'entity' then
                conjure_label.tooltip =
                    conjure_label.tooltip ..
                    '[entity=' ..
                        entity.obj_to_create ..
                            '] requires ' .. entity.mana_cost .. ' mana to cast. Level: ' .. entity.level .. '\n'
            elseif entity.type == 'special' then
                conjure_label.tooltip =
                    conjure_label.tooltip ..
                    entity.name .. ' requires ' .. entity.mana_cost .. ' mana to cast. Level: ' .. entity.level .. '\n'
            end
        end
    end

    local data = {
        reset_gui_input = reset_gui_input,
        magic_pickup_gui_input = magic_pickup_gui_input,
        movement_speed_gui_input = movement_speed_gui_input
    }

    if rpg_extra.enable_health_and_mana_bars then
        data.health_bar_gui_input = health_bar_gui_input
    end

    if rpg_extra.enable_mana then
        data.conjure_gui_input = conjure_gui_input
        data.enable_entity_gui_input = enable_entity_gui_input
    end

    if rpg_extra.enable_flame_boots then
        data.flame_boots_gui_input = flame_boots_gui_input
    end

    if rpg_extra.enable_stone_path then
        data.stone_path_gui_input = stone_path_gui_input
    end

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_button_name, caption = 'Discard changes'})
    close_button.style = 'back_button'

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_button_name, caption = 'Save changes'})
    save_button.style = 'confirm_button'

    Gui.set_data(save_button, data)

    player.opened = main_frame
end

local function draw_gui(player, forced)
    if not forced then
        if rpg_t[player.index].gui_refresh_delay > game.tick then
            return
        end
    end

    Tabs.comfy_panel_clear_left_gui(player)

    if player.gui.left[main_frame_name] then
        player.gui.left[main_frame_name].destroy()
    end

    if not player.character then
        return
    end

    local value
    local e

    local frame =
        player.gui.left.add(
        {type = 'frame', name = main_frame_name, direction = 'vertical', style = 'changelog_subheader_frame'}
    )

    frame.style.maximal_height = 800
    frame.style.maximal_width = 440
    frame.style.minimal_width = 440
    frame.style.use_header_filler = false
    frame.style.top_padding = 4
    frame.style.bottom_padding = 4
    frame.style.left_padding = 4
    frame.style.right_padding = 10

    local scroll_pane =
        frame.add {
        type = 'scroll-pane',
        direction = 'vertical',
        vertical_scroll_policy = 'always',
        horizontal_scroll_policy = 'never'
    }
    scroll_pane.style.minimal_width = 400
    scroll_pane.style.maximal_width = 450
    scroll_pane.style.minimal_height = 600
    scroll_pane.style.horizontally_squashable = false
    scroll_pane.style.vertically_squashable = false

    local t = scroll_pane.add({type = 'table', column_count = 2})
    e = add_gui_stat(t, player.name, 200, 'Hello ' .. player.name .. '!')
    e.style.font_color = player.chat_color
    e.style.font = 'default-large-bold'
    e = add_gui_stat(t, get_class(player), 200, 'You are an ' .. get_class(player) .. '.')
    e.style.font = 'default-large-bold'

    add_gui_stat(t, 'SETTINGS', 200, 'RPG settings!', settings_button_name)

    add_separator(scroll_pane, 400)

    t = scroll_pane.add({type = 'table', column_count = 4})
    t.style.cell_padding = 1

    add_gui_description(t, 'LEVEL', 80)
    if rpg_extra.level_limit_enabled then
        local level_tooltip =
            'Current max level limit for this zone is: ' ..
            level_limit_exceeded(player, true) .. '\nIncreases by breaching walls/zones.'
        add_gui_stat(t, rpg_t[player.index].level, 80, level_tooltip)
    else
        add_gui_stat(t, rpg_t[player.index].level, 80)
    end

    add_gui_description(t, 'EXPERIENCE', 100)
    e = add_gui_stat(t, math.floor(rpg_t[player.index].xp), 125, gain_info_tooltip)

    add_gui_description(t, ' ', 75)
    add_gui_description(t, ' ', 75)

    add_gui_description(t, 'NEXT LEVEL', 100)
    add_gui_stat(t, experience_levels[rpg_t[player.index].level + 1], 125, gain_info_tooltip)

    add_separator(scroll_pane, 400)

    local t = scroll_pane.add({type = 'table', column_count = 2})
    local tt = t.add({type = 'table', column_count = 3})
    tt.style.cell_padding = 1
    local w1 = 85
    local w2 = 63

    local str_tip = 'Increases inventory slots, mining speed.\nIncreases melee damage and amount of robot followers.'
    add_gui_description(tt, 'STRENGTH', w1, str_tip)
    add_gui_stat(tt, rpg_t[player.index].strength, w2, str_tip)
    add_gui_increase_stat(tt, 'strength', player)

    local mgc_tip = 'Increases reach distance.\nIncreases repair speed.'
    add_gui_description(tt, 'MAGIC', w1, mgc_tip)
    add_gui_stat(tt, rpg_t[player.index].magicka, w2, mgc_tip)
    add_gui_increase_stat(tt, 'magicka', player)

    local dex_tip = 'Increases running and crafting speed.'
    add_gui_description(tt, 'DEXTERITY', w1, dex_tip)
    add_gui_stat(tt, rpg_t[player.index].dexterity, w2, dex_tip)

    add_gui_increase_stat(tt, 'dexterity', player)

    local vit_tip = 'Increases health.\nIncreases melee life on-hit.'
    add_gui_description(tt, 'VITALITY', w1, vit_tip)
    add_gui_stat(tt, rpg_t[player.index].vitality, w2, vit_tip)
    add_gui_increase_stat(tt, 'vitality', player)

    add_gui_description(tt, 'POINTS TO\nDISTRIBUTE', w1)
    e = add_gui_stat(tt, rpg_t[player.index].points_to_distribute, w2)
    e.style.font_color = {200, 0, 0}
    add_gui_description(tt, ' ', w2)

    add_gui_description(tt, ' ', 40)
    add_gui_description(tt, ' ', 40)
    add_gui_description(tt, ' ', 40)

    add_gui_description(tt, 'LIFE', w1, 'Your current life.')
    add_gui_stat(tt, math.floor(player.character.health), w2, 'Current life. Increase it by adding vitality.')
    add_gui_stat(
        tt,
        math.floor(
            player.character.prototype.max_health + player.character_health_bonus + player.force.character_health_bonus
        ),
        w2,
        'This is your maximum life.'
    )

    local shield = 0
    local shield_max = 0
    local shield_desc_tip = 'You don`t have any shield.'
    local shield_tip = 'This is your current shield. You aren`t wearing any armor.'
    local shield_max_tip = shield_tip
    local i = player.character.get_inventory(defines.inventory.character_armor)
    if not i.is_empty() then
        if i[1].grid then
            shield = math.floor(i[1].grid.shield)
            shield_max = math.floor(i[1].grid.max_shield)
            shield_desc_tip = 'Shield protects you and heightens your resistance.'
            shield_tip = 'Current shield value of the equipment.'
            shield_max_tip = 'Maximum shield value.'
        end
    end
    add_gui_description(tt, 'SHIELD', w1, shield_desc_tip)
    add_gui_stat(tt, shield, w2, shield_tip)
    add_gui_stat(tt, shield_max, w2, shield_max_tip)

    if rpg_extra.enable_mana then
        local mana = rpg_t[player.index].mana
        local mana_max = rpg_t[player.index].mana_max

        local mana_tip = 'Mana lets you spawn entities by creating a wooden-chest ghost.'
        add_gui_description(tt, 'MANA', w1, mana_tip)
        local mana_regen_tip = 'This is your current mana. You can increase the regen by increasing your magic skills.'
        local mana_max_regen_tip = 'This is your max mana. You can increase the regen by increasing your magic skills.'
        add_gui_stat(tt, mana, w2, mana_regen_tip)
        add_gui_stat(tt, mana_max, w2, mana_max_regen_tip)
    end

    local tt = t.add({type = 'table', column_count = 3})
    tt.style.cell_padding = 1
    local w0 = 2
    local w1 = 80
    local w2 = 80

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'MINING\nSPEED', w1)
    value =
        math.round((player.force.manual_mining_speed_modifier + player.character_mining_speed_modifier + 1) * 100) ..
        '%'
    add_gui_stat(tt, value, w2)

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'SLOT\nBONUS', w1)
    value = '+ ' .. math.round(player.force.character_inventory_slots_bonus + player.character_inventory_slots_bonus)
    add_gui_stat(tt, value, w2)

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'MELEE\nDAMAGE', w1)
    value = math.round(100 * (1 + get_melee_modifier(player))) .. '%'
    e = add_gui_stat(tt, value, w2)
    e.tooltip =
        'Life on-hit: ' .. get_life_on_hit(player) .. '\nOne punch chance: ' .. get_one_punch_chance(player) .. '%'

    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 5
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 5
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 5

    value = '+ ' .. (player.force.character_reach_distance_bonus + player.character_reach_distance_bonus)
    local tooltip = ''
    tooltip = tooltip .. 'Reach distance bonus: ' .. player.character_reach_distance_bonus
    tooltip = tooltip .. '\nBuild distance bonus: ' .. player.character_build_distance_bonus
    tooltip = tooltip .. '\nItem drop distance bonus: ' .. player.character_item_drop_distance_bonus
    tooltip = tooltip .. '\nLoot pickup distance bonus: ' .. player.character_loot_pickup_distance_bonus
    tooltip = tooltip .. '\nItem pickup distance bonus: ' .. player.character_item_pickup_distance_bonus
    tooltip = tooltip .. '\nResource reach distance bonus: ' .. player.character_resource_reach_distance_bonus
    tooltip = tooltip .. '\nRepair speed: ' .. Public.get_magicka(player)
    add_gui_description(tt, ' ', w0)
    e = add_gui_description(tt, 'REACH\nDISTANCE', w1)
    e.tooltip = tooltip
    e = add_gui_stat(tt, value, w2)
    e.tooltip = tooltip

    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'CRAFTING\nSPEED', w1)
    value =
        math.round((player.force.manual_crafting_speed_modifier + player.character_crafting_speed_modifier + 1) * 100) ..
        '%'
    add_gui_stat(tt, value, w2)

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'RUNNING\nSPEED', w1)
    value =
        math.round((player.force.character_running_speed_modifier + player.character_running_speed_modifier + 1) * 100) ..
        '%'
    add_gui_stat(tt, value, w2)

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'HEALTH\nBONUS', w1)
    value = '+ ' .. math.round((player.force.character_health_bonus + player.character_health_bonus))
    e = add_gui_stat(tt, value, w2)
    e.tooltip = 'Health regen bonus: ' .. get_heal_modifier(player)

    add_gui_description(tt, ' ', w0)

    if rpg_extra.enable_mana then
        add_gui_description(tt, 'MANA\nBONUS', w1)
        local magic = rpg_t[player.index].magicka - 10
        local v = magic * 0.22
        value = '+ ' .. (math.floor(get_mana_modifier(player) * 10) / 10)
        e = add_gui_stat(tt, value, w2)
        e.tooltip = 'Mana regen bonus: ' .. (math.floor(get_mana_modifier(player) * 10) / 10)
    end

    add_separator(scroll_pane, 400)
    local t = scroll_pane.add({type = 'table', column_count = 14})
    for i = 1, 14, 1 do
        e = t.add({type = 'sprite', sprite = rpg_frame_icons[i]})
        e.style.maximal_width = 24
        e.style.maximal_height = 24
        e.style.padding = 0
    end
    add_separator(scroll_pane, 400)

    rpg_t[player.index].gui_refresh_delay = game.tick + 60
    update_char_button(player)
end

local function draw_level_text(player)
    if not player.character then
        return
    end

    if rpg_t[player.index].text then
        rendering.destroy(rpg_t[player.index].text)
        rpg_t[player.index].text = nil
    end

    local players = {}
    for _, p in pairs(game.players) do
        if p.index ~= player.index then
            players[#players + 1] = p.index
        end
    end
    if #players == 0 then
        return
    end

    rpg_t[player.index].text =
        rendering.draw_text {
        text = 'lvl ' .. rpg_t[player.index].level,
        surface = player.surface,
        target = player.character,
        target_offset = {0, -3.25},
        color = {
            r = player.color.r * 0.6 + 0.25,
            g = player.color.g * 0.6 + 0.25,
            b = player.color.b * 0.6 + 0.25,
            a = 1
        },
        players = players,
        scale = 1.00,
        font = 'default-large-semibold',
        alignment = 'center',
        scale_with_zoom = false
    }
end

local function level_up(player)
    local distribute_points_gain = 0
    for i = rpg_t[player.index].level + 1, #experience_levels, 1 do
        if rpg_t[player.index].xp > experience_levels[i] then
            rpg_t[player.index].level = i
            distribute_points_gain = distribute_points_gain + points_per_level
        else
            break
        end
    end
    if distribute_points_gain == 0 then
        return
    end
    draw_level_text(player)
    rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute + distribute_points_gain
    update_char_button(player)
    table.shuffle_table(rpg_frame_icons)
    if player.gui.left[main_frame_name] then
        draw_gui(player, true)
    end
    level_up_effects(player)
end

local function add_to_global_pool(amount, personal_tax)
    if not rpg_extra.global_pool then
        return
    end
    local fee
    if personal_tax then
        fee = amount * rpg_extra.personal_tax_rate
    else
        fee = amount * 0.3
    end

    rpg_extra.global_pool = rpg_extra.global_pool + fee
    return amount - fee
end

local function global_pool(players, count)
    if not rpg_extra.global_pool then
        return
    end

    local pool = math.floor(rpg_extra.global_pool)

    local random_amount = math.random(5000, 10000)

    if pool <= random_amount then
        return
    end

    if pool >= 20000 then
        pool = 20000
    end

    local share = pool / count

    Public.debug_log('RPG - Share per player:' .. share)

    for i = 1, #players do
        local p = players[i]
        if p.afk_time < 5000 then
            if not level_limit_exceeded(p) then
                Public.gain_xp(p, share, false, true)
                xp_effects(p)
            else
                share = share / 10
                rpg_extra.leftover_pool = rpg_extra.leftover_pool + share
                Public.debug_log('RPG - player capped: ' .. p.name .. '. Amount to pool:' .. share)
            end
        else
            local message = teller_global_pool .. p.name .. ' received nothing. Reason: AFK'
            Alert.alert_player_warning(p, 10, message)
            share = share / 10
            rpg_extra.leftover_pool = rpg_extra.leftover_pool + share
            Public.debug_log('RPG - player AFK: ' .. p.name .. '. Amount to pool:' .. share)
        end
    end

    rpg_extra.global_pool = rpg_extra.leftover_pool or 0

    return
end

local function on_gui_click(event)
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local element = event.element
    local player = game.players[event.player_index]

    if element.type ~= 'sprite-button' then
        return
    end

    local shift = event.shift

    if element.caption ~= '✚' then
        return
    end
    if element.sprite ~= 'virtual-signal/signal-red' then
        return
    end

    local index = element.name
    if not rpg_t[player.index][index] then
        return
    end
    if not player.character then
        return
    end

    if shift then
        local count = rpg_t[player.index].points_to_distribute
        if not count then
            return
        end
        rpg_t[player.index].points_to_distribute = 0
        rpg_t[player.index][index] = rpg_t[player.index][index] + count
        if not rpg_t[player.index].reset then
            rpg_t[player.index].total = rpg_t[player.index].total + count
        end
        update_player_stats(player)
        draw_gui(player, true)
    elseif event.button == defines.mouse_button_type.right then
        for _ = 1, points_per_level, 1 do
            if rpg_t[player.index].points_to_distribute <= 0 then
                draw_gui(player, true)
                return
            end
            rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute - 1
            rpg_t[player.index][index] = rpg_t[player.index][index] + 1
            if not rpg_t[player.index].reset then
                rpg_t[player.index].total = rpg_t[player.index].total + 1
            end
            update_player_stats(player)
        end
        draw_gui(player, true)
        return
    end

    if rpg_t[player.index].points_to_distribute <= 0 then
        draw_gui(player, true)
        return
    end
    rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute - 1
    rpg_t[player.index][index] = rpg_t[player.index][index] + 1
    if not rpg_t[player.index].reset then
        rpg_t[player.index].total = rpg_t[player.index].total + 1
    end
    update_player_stats(player)
    draw_gui(player, true)
end

local function train_type_cause(cause)
    local players = {}
    if cause.train.passengers then
        for _, player in pairs(cause.train.passengers) do
            players[#players + 1] = player
        end
    end
    return players
end

local get_cause_player = {
    ['character'] = function(cause)
        if not cause.player then
            return
        end
        return {cause.player}
    end,
    ['combat-robot'] = function(cause)
        if not cause.last_user then
            return
        end
        if not game.players[cause.last_user.index] then
            return
        end
        return {game.players[cause.last_user.index]}
    end,
    ['car'] = function(cause)
        local players = {}
        local driver = cause.get_driver()
        if driver then
            if driver.player then
                players[#players + 1] = driver.player
            end
        end
        local passenger = cause.get_passenger()
        if passenger then
            if passenger.player then
                players[#players + 1] = passenger.player
            end
        end
        return players
    end,
    ['locomotive'] = train_type_cause,
    ['cargo-wagon'] = train_type_cause,
    ['artillery-wagon'] = train_type_cause,
    ['fluid-wagon'] = train_type_cause
}

local function on_entity_died(event)
    if not event.entity.valid then
        return
    end

    --Grant XP for hand placed land mines
    if event.entity.last_user then
        if event.entity.type == 'land-mine' then
            if event.cause then
                if event.cause.valid then
                    if event.cause.force.index == event.entity.force.index then
                        return
                    end
                end
            end
            Public.gain_xp(event.entity.last_user, 1)
            return
        end
    end

    if rpg_extra.enable_wave_defense then
        if rpg_xp_yield['big-biter'] <= 16 then
            local wave_number = WD.get_wave()
            if wave_number >= 1000 then
                rpg_xp_yield['big-biter'] = 16
                rpg_xp_yield['behemoth-biter'] = 64
            end
        end
    end

    if not event.cause then
        return
    end

    if not event.cause.valid then
        return
    end

    local type = event.cause.type
    if not type then
        goto continue
    end

    if event.cause.force.index == 1 then
        if die_cause[type] then
            if rpg_xp_yield[event.entity.name] then
                local amount = rpg_xp_yield[event.entity.name]
                amount = amount / 5
                if global.biter_health_boost then
                    local health_pool = global.biter_health_boost_units[event.entity.unit_number]
                    if health_pool then
                        amount = amount * (1 / health_pool[2])
                    end
                end

                if rpg_extra.turret_kills_to_global_pool then
                    add_to_global_pool(amount, false)
                end
            else
                add_to_global_pool(0.5, false)
            end
            return
        end
    end

    ::continue::

    if event.cause.force.index == event.entity.force.index then
        return
    end

    if not get_cause_player[event.cause.type] then
        return
    end

    local players = get_cause_player[event.cause.type](event.cause)
    if not players then
        return
    end
    if not players[1] then
        return
    end

    --Grant modified XP for health boosted units
    if global.biter_health_boost then
        if enemy_types[event.entity.type] then
            local health_pool = global.biter_health_boost_units[event.entity.unit_number]
            if health_pool then
                for _, player in pairs(players) do
                    if rpg_xp_yield[event.entity.name] then
                        local amount = rpg_xp_yield[event.entity.name] * (1 / health_pool[2])
                        if rpg_extra.turret_kills_to_global_pool then
                            local inserted = add_to_global_pool(amount, true)
                            Public.gain_xp(player, inserted, true)
                        else
                            Public.gain_xp(player, amount)
                        end
                    else
                        Public.gain_xp(player, 0.5 * (1 / health_pool[2]))
                    end
                end
                return
            end
        end
    end

    --Grant normal XP
    for _, player in pairs(players) do
        if rpg_xp_yield[event.entity.name] then
            local amount = rpg_xp_yield[event.entity.name]
            if rpg_extra.turret_kills_to_global_pool then
                local inserted = add_to_global_pool(amount, true)
                Public.gain_xp(player, inserted, true)
            else
                Public.gain_xp(player, amount)
            end
        else
            Public.gain_xp(player, 0.5)
        end
    end
end

local function regen_health_player(players)
    for i = 1, #players do
        local player = players[i]
        local heal_per_tick = get_heal_modifier(player)
        if heal_per_tick <= 0 then
            goto continue
        end
        heal_per_tick = math.round(heal_per_tick)
        if player and player.valid then
            if player.character and player.character.valid then
                player.character.health = player.character.health + heal_per_tick
            end
        end
        if player.gui.left[main_frame_name] then
            draw_gui(player)
        end

        ::continue::

        if rpg_extra.enable_health_and_mana_bars then
            if rpg_t[player.index].show_bars then
                if player and player.valid then
                    if player.character and player.character.valid then
                        local max_life =
                            math.floor(
                            player.character.prototype.max_health + player.character_health_bonus +
                                player.force.character_health_bonus
                        )
                        if not rpg_t[player.index].health_bar then
                            rpg_t[player.index].health_bar = create_healthbar(player, 0.5)
                        elseif not rendering.is_valid(rpg_t[player.index].health_bar) then
                            rpg_t[player.index].health_bar = create_healthbar(player, 0.5)
                        end
                        set_bar(player.character.health, max_life, rpg_t[player.index].health_bar)
                    end
                end
            end
        end
    end
end

local function regen_mana_player(players)
    for i = 1, #players do
        local player = players[i]
        local mana_per_tick = get_mana_modifier(player)
        if mana_per_tick <= 0.1 then
            mana_per_tick = rpg_extra.mana_per_tick
        end

        if rpg_extra.force_mana_per_tick then
            mana_per_tick = 1
        end

        if player and player.valid then
            if player.character and player.character.valid then
                if rpg_t[player.index].mana >= rpg_t[player.index].mana_max then
                    goto continue
                end
                rpg_t[player.index].mana = rpg_t[player.index].mana + mana_per_tick

                if rpg_t[player.index].mana >= rpg_t[player.index].mana_max then
                    rpg_t[player.index].mana = rpg_t[player.index].mana_max
                end
                rpg_t[player.index].mana = (math.round(rpg_t[player.index].mana * 10) / 10)
            end
        end

        ::continue::

        if rpg_extra.enable_health_and_mana_bars then
            if rpg_t[player.index].show_bars then
                if player.character and player.character.valid then
                    if not rpg_t[player.index].mana_bar then
                        rpg_t[player.index].mana_bar = create_manabar(player, 0.5)
                    elseif not rendering.is_valid(rpg_t[player.index].mana_bar) then
                        rpg_t[player.index].mana_bar = create_manabar(player, 0.5)
                    end
                    set_bar(rpg_t[player.index].mana, rpg_t[player.index].mana_max, rpg_t[player.index].mana_bar, true)
                end
            end
        end
        if player.gui.left[main_frame_name] then
            draw_gui(player)
        end
    end
end

local function give_player_flameboots(event)
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if player.character.driving then
        return
    end

    if not rpg_t[player.index].mana then
        return
    end

    if not rpg_t[player.index].flame_boots then
        return
    end

    if rpg_t[player.index].mana <= 0 then
        player.print('Your flame boots have worn out.', {r = 0.22, g = 0.77, b = 0.44})
        rpg_t[player.index].flame_boots = false
        return
    end

    if rpg_t[player.index].mana % 500 == 0 then
        player.print('Mana remaining: ' .. rpg_t[player.index].mana, {r = 0.22, g = 0.77, b = 0.44})
    end

    local p = player.position

    player.surface.create_entity({name = 'fire-flame', position = p})

    rpg_t[player.index].mana = rpg_t[player.index].mana - 5
    if rpg_t[player.index].mana <= 0 then
        rpg_t[player.index].mana = 0
    end
    if player.gui.left[main_frame_name] then
        draw_gui(player)
    end
end

--Melee damage modifier
local function one_punch(character, target, damage)
    local base_vector = {target.position.x - character.position.x, target.position.y - character.position.y}

    local vector = {base_vector[1], base_vector[2]}
    vector[1] = vector[1] * 1000
    vector[2] = vector[2] * 1000

    character.surface.create_entity(
        {
            name = 'flying-text',
            position = {character.position.x + base_vector[1] * 0.5, character.position.y + base_vector[2] * 0.5},
            text = 'ONE PUNCH',
            color = {255, 0, 0}
        }
    )
    character.surface.create_entity({name = 'blood-explosion-huge', position = target.position})
    character.surface.create_entity(
        {
            name = 'big-artillery-explosion',
            position = {target.position.x + vector[1] * 0.5, target.position.y + vector[2] * 0.5}
        }
    )

    if math.abs(vector[1]) > math.abs(vector[2]) then
        local d = math.abs(vector[1])
        if math.abs(vector[1]) > 0 then
            vector[1] = vector[1] / d
        end
        if math.abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
    else
        local d = math.abs(vector[2])
        if math.abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
        if math.abs(vector[1]) > 0 and d > 0 then
            vector[1] = vector[1] / d
        end
    end

    vector[1] = vector[1] * 1.5
    vector[2] = vector[2] * 1.5

    local a = 0.25

    for i = 1, 16, 1 do
        for x = i * -1 * a, i * a, 1 do
            for y = i * -1 * a, i * a, 1 do
                local p = {character.position.x + x + vector[1] * i, character.position.y + y + vector[2] * i}
                character.surface.create_trivial_smoke({name = 'train-smoke', position = p})
                for _, e in pairs(character.surface.find_entities({{p[1] - a, p[2] - a}, {p[1] + a, p[2] + a}})) do
                    if e.valid then
                        if e.health then
                            if e.destructible and e.minable and e.force.index ~= 3 then
                                if e.force.index ~= character.force.index then
                                    e.health = e.health - damage * 0.05
                                    if e.health <= 0 then
                                        e.die(e.force.name, character)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function on_entity_damaged(event)
    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if event.cause.force.index == 2 then
        return
    end
    if event.cause.name ~= 'character' then
        return
    end
    if event.damage_type.name ~= 'physical' then
        return
    end
    if not event.entity.valid then
        return
    end
    if
        event.cause.get_inventory(defines.inventory.character_ammo)[event.cause.selected_gun_index].valid_for_read and
            event.cause.get_inventory(defines.inventory.character_guns)[event.cause.selected_gun_index].valid_for_read
     then
        return
    end
    if not event.cause.player then
        return
    end

    --Grant the player life-on-hit.
    event.cause.health = event.cause.health + get_life_on_hit(event.cause.player)

    --Calculate modified damage.
    local damage = event.original_damage_amount + event.original_damage_amount * get_melee_modifier(event.cause.player)
    if event.entity.prototype.resistances then
        if event.entity.prototype.resistances.physical then
            damage = damage - event.entity.prototype.resistances.physical.decrease
            damage = damage - damage * event.entity.prototype.resistances.physical.percent
        end
    end
    damage = math.round(damage, 3)
    if damage < 1 then
        damage = 1
    end

    --Cause a one punch.
    if math.random(0, 999) < get_one_punch_chance(event.cause.player) * 10 then
        one_punch(event.cause, event.entity, damage)
        if event.entity.valid then
            event.entity.die(event.entity.force.name, event.cause)
        end
        return
    end

    --Floating messages and particle effects.
    if math.random(1, 7) == 1 then
        damage = damage * math.random(250, 350) * 0.01
        event.cause.surface.create_entity(
            {
                name = 'flying-text',
                position = event.entity.position,
                text = '‼' .. math.floor(damage),
                color = {255, 0, 0}
            }
        )
        event.cause.surface.create_entity({name = 'blood-explosion-huge', position = event.entity.position})
    else
        damage = damage * math.random(100, 125) * 0.01
        event.cause.player.create_local_flying_text(
            {
                text = math.floor(damage),
                position = event.entity.position,
                color = {150, 150, 150},
                time_to_live = 90,
                speed = 2
            }
        )
    end

    --Handle the custom health pool of the biter health booster, if it is used in the map.
    if global.biter_health_boost then
        local health_pool = global.biter_health_boost_units[event.entity.unit_number]
        if health_pool then
            health_pool[1] = health_pool[1] + event.final_damage_amount
            health_pool[1] = health_pool[1] - damage

            --Set entity health relative to health pool
            event.entity.health = health_pool[1] * health_pool[2]

            if health_pool[1] <= 0 then
                global.biter_health_boost_units[event.entity.unit_number] = nil
                event.entity.die(event.entity.force.name, event.cause)
            end
            return
        end
    end

    --Handle vanilla damage.
    event.entity.health = event.entity.health + event.final_damage_amount
    event.entity.health = event.entity.health - damage
    if event.entity.health <= 0 then
        event.entity.die(event.entity.force.name, event.cause)
    end
end

local function on_player_repaired_entity(event)
    if math.random(1, 4) ~= 1 then
        return
    end

    local entity = event.entity

    if not entity then
        return
    end

    if not entity.valid then
        return
    end

    if not entity.health then
        return
    end

    local player = game.players[event.player_index]

    if not player.character then
        return
    end
    Public.gain_xp(player, 0.05)

    local repair_speed = Public.get_magicka(player)
    if repair_speed <= 0 then
        return
    end
    entity.health = entity.health + repair_speed
end

local function on_player_rotated_entity(event)
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if rpg_t[player.index].rotated_entity_delay > game.tick then
        return
    end
    rpg_t[player.index].rotated_entity_delay = game.tick + 20
    Public.gain_xp(player, 0.20)
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]

    if string.sub(player.surface.name, 0, #rpg_extra.surface_name) ~= rpg_extra.surface_name then
        return
    end

    if rpg_extra.enable_flame_boots then
        give_player_flameboots(event)
    end

    if math.random(1, 64) ~= 1 then
        return
    end
    if not player.character then
        return
    end
    if player.character.driving then
        return
    end
    Public.gain_xp(player, 1.0)
end

local building_and_mining_blacklist = {
    ['tile-ghost'] = true,
    ['entity-ghost'] = true,
    ['item-entity'] = true
}

local function on_pre_player_mined_item(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if building_and_mining_blacklist[entity.type] then
        return
    end
    if entity.force.index ~= 3 then
        return
    end
    local player = game.players[event.player_index]

    if
        rpg_t[player.index].last_mined_entity_position.x == event.entity.position.x and
            rpg_t[player.index].last_mined_entity_position.y == event.entity.position.y
     then
        return
    end
    rpg_t[player.index].last_mined_entity_position.x = entity.position.x
    rpg_t[player.index].last_mined_entity_position.y = entity.position.y

    local distance_multiplier = math.floor(math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2)) * 0.0005 + 1

    local xp_amount
    if entity.type == 'resource' then
        xp_amount = 0.5 * distance_multiplier
    else
        xp_amount = (1.5 + event.entity.prototype.max_health * 0.0035) * distance_multiplier
    end

    Public.gain_xp(player, xp_amount)
end

local function on_player_crafted_item(event)
    if not event.recipe.energy then
        return
    end
    local player = game.players[event.player_index]
    if not player.valid then
        return
    end

    if player.cheat_mode then
        return
    end

    local amount = 0.30 * math.random(1, 2)

    Public.gain_xp(player, event.recipe.energy * amount)
end

local function on_player_respawned(event)
    local player = game.players[event.player_index]
    if not rpg_t[player.index] then
        Public.rpg_reset_player(player)
        return
    end
    update_player_stats(player)
    draw_level_text(player)
    if rpg_extra.enable_health_and_mana_bars then
        rpg_t[player.index].health_bar = create_healthbar(player, 0.5)
        if player.character and player.character.valid then
            local max_life =
                math.floor(
                player.character.prototype.max_health + player.character_health_bonus +
                    player.force.character_health_bonus
            )
            set_bar(player.character.health, max_life, rpg_t[player.index].health_bar)
        end
        if rpg_extra.enable_mana then
            rpg_t[player.index].mana_bar = create_manabar(player, 0.5)
            set_bar(rpg_t[player.index].mana, rpg_t[player.index].mana_max, rpg_t[player.index].mana_bar, true)
        end
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not rpg_t[player.index] then
        Public.rpg_reset_player(player)
        if rpg_extra.reward_new_players > 10 then
            Public.gain_xp(player, rpg_extra.reward_new_players)
        end
    end
    for _, p in pairs(game.connected_players) do
        draw_level_text(p)
    end
    draw_gui_char_button(player)
    if not player.character then
        return
    end
    update_player_stats(player)
end

local function splash_damage(surface, position, final_damage_amount)
    local radius = 3
    local damage = math.random(math.floor(final_damage_amount * 3), math.floor(final_damage_amount * 4))
    for _, e in pairs(
        surface.find_entities_filtered(
            {area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}}
        )
    ) do
        if e.valid and e.health then
            local distance_from_center = math.sqrt((e.position.x - position.x) ^ 2 + (e.position.y - position.y) ^ 2)
            if distance_from_center <= radius then
                local damage_distance_modifier = 1 - distance_from_center / radius
                if damage > 0 then
                    if math.random(1, 3) == 1 then
                        surface.create_entity({name = 'explosion', position = e.position})
                    end
                    e.damage(damage * damage_distance_modifier, 'player', 'explosion')
                end
            end
        end
    end
end

local function create_projectile(surface, name, position, force, target, max_range)
    if max_range then
        surface.create_entity(
            {
                name = name,
                position = position,
                force = force,
                source = position,
                target = target,
                max_range = max_range,
                speed = 0.4
            }
        )
    else
        surface.create_entity(
            {
                name = name,
                position = position,
                force = force,
                source = position,
                target = target,
                speed = 0.4
            }
        )
    end
end

local function get_near_coord_modifier(range)
    local coord = {x = (range * -1) + math.random(0, range * 2), y = (range * -1) + math.random(0, range * 2)}
    for i = 1, 5, 1 do
        local new_coord = {x = (range * -1) + math.random(0, range * 2), y = (range * -1) + math.random(0, range * 2)}
        if new_coord.x ^ 2 + new_coord.y ^ 2 < coord.x ^ 2 + coord.y ^ 2 then
            coord = new_coord
        end
    end
    return coord
end

local function damage_entity(e)
    if not e.health then
        return
    end

    if e.force.name == 'player' then
        return
    end

    e.surface.create_entity({name = 'water-splash', position = e.position})

    if e.type == 'entity-ghost' then
        e.destroy()
        return
    end

    e.health = e.health - math.random(30, 90)
    if e.health <= 0 then
        e.die('enemy')
    end
end

local function floaty_hearts(entity, c)
    local position = {x = entity.position.x - 0.75, y = entity.position.y - 1}
    local b = 1.35
    for a = 1, c, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        entity.surface.create_entity(
            {name = 'flying-text', position = p, text = '♥', color = {math.random(150, 255), 0, 255}}
        )
    end
end

local function tame_unit_effects(player, entity)
    floaty_hearts(entity, 7)

    rendering.draw_text {
        text = '~' .. player.name .. "'s pet~",
        surface = player.surface,
        target = entity,
        target_offset = {0, -2.6},
        color = {
            r = player.color.r * 0.6 + 0.25,
            g = player.color.g * 0.6 + 0.25,
            b = player.color.b * 0.6 + 0.25,
            a = 1
        },
        scale = 1.05,
        font = 'default-large-semibold',
        alignment = 'center',
        scale_with_zoom = false
    }
end

local function on_player_used_capsule(event)
    if not rpg_extra.enable_mana then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if string.sub(player.surface.name, 0, #rpg_extra.surface_name) ~= rpg_extra.surface_name then
        return
    end

    local item = event.item

    if not item then
        return
    end

    local name = item.name

    if name ~= 'raw-fish' then
        return
    end

    if not rpg_t[player.index].enable_entity_spawn then
        return
    end

    local p = player.print

    if rpg_t[player.index].last_spawned >= game.tick then
        return p(
            'There was a lot more to magic, as ' ..
                player.name .. ' quickly found out, than waving their wand and saying a few funny words.',
            Color.warning
        )
    end

    local mana = rpg_t[player.index].mana
    local surface = player.surface

    local object = conjure_items[rpg_t[player.index].dropdown_select_index]
    if not object then
        return
    end

    if rpg_t[player.index].level <= object.level then
        return p('You lack the level to cast this spell.', Color.fail)
    end

    local object_name = object.name
    local obj_name = object.obj_to_create

    local position = event.position
    if not position then
        return
    end

    local radius = 15
    local area = {
        left_top = {x = position.x - radius, y = position.y - radius},
        right_bottom = {x = position.x + radius, y = position.y + radius}
    }

    if not Math2D.bounding_box.contains_point(area, player.position) then
        player.print('You wave your wand but realize that it´s out of reach.', Color.fail)
        return
    end

    if mana <= object.mana_cost then
        return p('You don´t have enough mana to cast this spell.', Color.fail)
    else
        rpg_t[player.index].mana = rpg_t[player.index].mana - object.mana_cost
    end

    local target_pos
    if object.target then
        target_pos = {position.x, position.y}
    elseif projectile_types[obj_name] then
        local coord_modifier = get_near_coord_modifier(projectile_types[obj_name].max_range)
        local proj_pos = {position.x + coord_modifier.x, position.y + coord_modifier.y}
        target_pos = proj_pos
    end

    local range
    if object.range then
        range = object.range
    else
        range = 0
    end

    local force
    if object.force then
        force = object.force
    else
        force = 'player'
    end
    if object.obj_to_create == 'suicidal_comfylatron' then
        suicidal_comfylatron(position, surface)
    elseif projectile_types[obj_name] then
        for i = 1, object.amount do
            local damage_area = {
                left_top = {x = position.x - 2, y = position.y - 2},
                right_bottom = {x = position.x + 2, y = position.y + 2}
            }
            create_projectile(surface, obj_name, position, force, target_pos, range)
            if object.damage then
                for _, e in pairs(surface.find_entities_filtered({area = damage_area})) do
                    damage_entity(e)
                end
            end
        end
    else
        if object.obj_to_create == 'fish' then
            player.insert({name = 'raw-fish', count = object.amount})
        elseif object.biter then
            local e = surface.create_entity({name = obj_name, position = position, force = force})
            tame_unit_effects(player, e)
        else
            surface.create_entity({name = obj_name, position = position, force = force})
        end
    end

    rpg_t[player.index].last_spawned = game.tick + object.tick
    if player.gui.left[main_frame_name] then
        draw_gui(player)
    end
    if rpg_extra.enable_health_and_mana_bars then
        if rpg_t[player.index].show_bars then
            set_bar(rpg_t[player.index].mana, rpg_t[player.index].mana_max, rpg_t[player.index].mana_bar, true)
        end
    end

    return p('You wave your wand and ' .. object_name .. ' appears.', Color.success)
end

local function tick()
    local ticker = game.tick
    local count = #game.connected_players
    local players = game.connected_players

    if ticker % nth_tick == 0 then
        global_pool(players, count)
    end

    if ticker % 30 == 0 then
        regen_health_player(players)
        if rpg_extra.enable_mana then
            regen_mana_player(players)
        end
        if rpg_extra.enable_flameboots then
            give_player_flameboots(players)
        end
    end
end

--- Gives connected player some bonus xp if the map was preemptively shut down.
-- amount (integer) -- 10 levels
-- local Public = require 'modules.rpg_v2' Public.give_xp(512)
function Public.give_xp(amount)
    for _, player in pairs(game.connected_players) do
        if not validate_player(player) then
            return
        end
        Public.gain_xp(player, amount)
    end
end

function Public.rpg_reset_player(player, one_time_reset)
    if player.gui.left[main_frame_name] then
        player.gui.left[main_frame_name].destroy()
    end
    if not player.character then
        player.set_controller({type = defines.controllers.god})
        player.create_character()
    end
    if one_time_reset then
        local total = rpg_t[player.index].total
        if not total then
            total = 0
        end
        local old_level = rpg_t[player.index].level
        local old_points_to_distribute = rpg_t[player.index].points_to_distribute
        local old_xp = rpg_t[player.index].xp
        rpg_t[player.index] = {
            level = 1,
            xp = 0,
            strength = 10,
            magicka = 10,
            dexterity = 10,
            vitality = 10,
            mana = 0,
            mana_max = 100,
            last_spawned = 0,
            dropdown_select_index = 1,
            flame_boots = false,
            enable_entity_spawn = false,
            health_bar = rpg_t[player.index].health_bar,
            mana_bar = rpg_t[player.index].mana_bar,
            points_to_distribute = 0,
            last_floaty_text = visuals_delay,
            xp_since_last_floaty_text = 0,
            reset = true,
            capped = false,
            bonus = rpg_extra.breached_walls or 1,
            rotated_entity_delay = 0,
            gui_refresh_delay = 0,
            last_mined_entity_position = {x = 0, y = 0},
            show_bars = false,
            stone_path = false
        }
        rpg_t[player.index].points_to_distribute = old_points_to_distribute + total
        rpg_t[player.index].xp = old_xp
        rpg_t[player.index].level = old_level
    else
        rpg_t[player.index] = {
            level = 1,
            xp = 0,
            strength = 10,
            magicka = 10,
            dexterity = 10,
            vitality = 10,
            mana = 0,
            mana_max = 100,
            last_spawned = 0,
            dropdown_select_index = 1,
            flame_boots = false,
            enable_entity_spawn = false,
            points_to_distribute = 0,
            last_floaty_text = visuals_delay,
            xp_since_last_floaty_text = 0,
            reset = false,
            capped = false,
            total = 0,
            bonus = 1,
            rotated_entity_delay = 0,
            gui_refresh_delay = 0,
            last_mined_entity_position = {x = 0, y = 0},
            show_bars = false,
            stone_path = false
        }
    end
    draw_gui_char_button(player)
    draw_level_text(player)
    update_char_button(player)
    update_player_stats(player)
end

function Public.rpg_reset_all_players()
    for k, _ in pairs(rpg_t) do
        rpg_t[k] = nil
    end
    for _, p in pairs(game.connected_players) do
        Public.rpg_reset_player(p)
    end
    rpg_extra.breached_walls = 1
    rpg_extra.reward_new_players = 0
    rpg_extra.global_pool = 0
end

function Public.get_magicka(player)
    return (rpg_t[player.index].magicka - 10) * 0.10
end

function Public.gain_xp(player, amount, added_to_pool, text)
    if not validate_player(player) then
        return
    end

    if level_limit_exceeded(player) then
        add_to_global_pool(amount, false)
        if not rpg_t[player.index].capped then
            rpg_t[player.index].capped = true
            local message = teller_level_limit .. 'You have hit the max level for the current zone.'
            Alert.alert_player_warning(player, 10, message)
        end
        return
    end

    local text_to_draw

    if rpg_t[player.index].capped then
        rpg_t[player.index].capped = false
    end

    if not added_to_pool then
        Public.debug_log('RPG - ' .. player.name .. ' got org xp: ' .. amount)
        local fee = add_to_global_pool(amount, true)
        Public.debug_log('RPG - ' .. player.name .. ' got fee: ' .. fee)
        amount = math.round(amount, 3) - fee
        if rpg_extra.difficulty then
            amount = amount + rpg_extra.difficulty
        end
        Public.debug_log('RPG - ' .. player.name .. ' got after fee: ' .. amount)
    else
        Public.debug_log('RPG - ' .. player.name .. ' got org xp: ' .. amount)
    end

    rpg_t[player.index].xp = rpg_t[player.index].xp + amount
    rpg_t[player.index].xp_since_last_floaty_text = rpg_t[player.index].xp_since_last_floaty_text + amount

    if player.gui.left[main_frame_name] then
        draw_gui(player, false)
    end

    if not experience_levels[rpg_t[player.index].level + 1] then
        return
    end

    if rpg_t[player.index].xp >= experience_levels[rpg_t[player.index].level + 1] then
        level_up(player)
    end

    if rpg_t[player.index].last_floaty_text > game.tick then
        if not text then
            return
        end
    end

    if text then
        text_to_draw = '+' .. math.floor(amount) .. ' xp'
    else
        text_to_draw = '+' .. math.floor(rpg_t[player.index].xp_since_last_floaty_text) .. ' xp'
    end

    player.create_local_flying_text {
        text = text_to_draw,
        position = player.position,
        color = xp_floating_text_color,
        time_to_live = 340,
        speed = 2
    }

    rpg_t[player.index].xp_since_last_floaty_text = 0
    rpg_t[player.index].last_floaty_text = game.tick + visuals_delay
end

--- Returns the rpg_t table.
---@param key <string>
function Public.get_table(key)
    if key then
        return rpg_t[key]
    else
        return rpg_t
    end
end

--- Returns the rpg_extra table.
---@param key <string>
function Public.get_extra_table(key)
    if key then
        return rpg_extra[key]
    else
        return rpg_extra
    end
end

--- Toggle debug - when you need to troubleshoot.
function Public.toggle_debug()
    if rpg_extra.debug then
        rpg_extra.debug = false
    else
        rpg_extra.debug = true
    end
end

--- Distributes the global xp pool to every connected player.
function Public.distribute_pool()
    local count = #game.connected_players
    local players = game.connected_players
    global_pool(players, count)
    print('Distributed the global XP pool')
end

--- Debug only - when you need to troubleshoot.
---@param str <string>
function Public.debug_log(str)
    if not rpg_extra.debug then
        return
    end
    print(str)
end

--- Sets surface name for rpg_v2 to use
---@param name <string>
function Public.set_surface_name(name)
    if name then
        rpg_extra.surface_name = name
    else
        return error('No surface name given.', 2)
    end
end

--- Enables the bars that shows above the player character.
--- If you disable mana but enable <enable_health_and_mana_bars> then only health will be shown
---@param value <boolean>
function Public.enable_health_and_mana_bars(value)
    if value then
        rpg_extra.enable_health_and_mana_bars = value
    else
        rpg_extra.enable_health_and_mana_bars = false
    end
end

--- Enables the mana feature that allows players to spawn entities.
---@param value <boolean>
function Public.enable_mana(value)
    if value then
        rpg_extra.enable_mana = value
    else
        rpg_extra.enable_mana = false
    end
end

--- This should only be enabled if wave_defense is enabled.
--- It boosts the amount of xp the players get after x amount of waves.
---@param value <boolean>
function Public.enable_wave_defense(value)
    if value then
        rpg_extra.enable_wave_defense = value
    else
        rpg_extra.enable_wave_defense = false
    end
end

--- Enables/disabled flame boots.
---@param value <boolean>
function Public.enable_flame_boots(value)
    if value then
        rpg_extra.enable_flame_boots = value
    else
        rpg_extra.enable_flame_boots = false
    end
end

--- Enables/disabled personal tax.
---@param value <boolean>
function Public.personal_tax_rate(value)
    if value then
        rpg_extra.personal_tax_rate = value
    else
        rpg_extra.personal_tax_rate = nil
    end
end

--- Enables/disabled stone-path-tile creation on mined.
---@param value <boolean>
function Public.enable_stone_path(value)
    if value then
        rpg_extra.enable_stone_path = value
    else
        rpg_extra.enable_stone_path = nil
    end
end

--- Pass along the main_button and main_frame
Public.main_frame_name = main_frame_name
Public.draw_main_frame_name = draw_main_frame_name
Public.settings_frame_name = settings_frame_name

Gui.on_click(
    draw_main_frame_name,
    function(event)
        local player = event.player
        if not player.character then
            return
        end
        if player.gui.left[main_frame_name] then
            player.gui.left[main_frame_name].destroy()
            return
        else
            draw_gui(player, true)
        end
    end
)

Gui.on_click(
    save_button_name,
    function(event)
        local player = event.player
        if not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[settings_frame_name]
        local player_modifiers = P.get_table()
        local data = Gui.get_data(event.element)
        local health_bar_gui_input = data.health_bar_gui_input
        local reset_gui_input = data.reset_gui_input
        local conjure_gui_input = data.conjure_gui_input
        local magic_pickup_gui_input = data.magic_pickup_gui_input
        local movement_speed_gui_input = data.movement_speed_gui_input
        local flame_boots_gui_input = data.flame_boots_gui_input
        local enable_entity_gui_input = data.enable_entity_gui_input
        local stone_path_gui_input = data.stone_path_gui_input

        if frame and frame.valid then
            if stone_path_gui_input and stone_path_gui_input.valid then
                if not stone_path_gui_input.state then
                    rpg_t[player.index].stone_path = false
                elseif stone_path_gui_input.state then
                    rpg_t[player.index].stone_path = true
                end
            end

            if enable_entity_gui_input and enable_entity_gui_input.valid then
                if not enable_entity_gui_input.state then
                    rpg_t[player.index].enable_entity_spawn = false
                elseif enable_entity_gui_input.state then
                    rpg_t[player.index].enable_entity_spawn = true
                end
            end

            if flame_boots_gui_input and flame_boots_gui_input.valid then
                if not flame_boots_gui_input.state then
                    rpg_t[player.index].flame_boots = false
                elseif flame_boots_gui_input.state then
                    rpg_t[player.index].flame_boots = true
                end
            end

            if movement_speed_gui_input and movement_speed_gui_input.valid then
                if not player_modifiers.disabled_modifier[player.index] then
                    player_modifiers.disabled_modifier[player.index] = {}
                end
                if not movement_speed_gui_input.state then
                    player_modifiers.disabled_modifier[player.index].character_running_speed_modifier = true
                    P.update_player_modifiers(player)
                elseif movement_speed_gui_input.state then
                    player_modifiers.disabled_modifier[player.index].character_running_speed_modifier = false
                    P.update_player_modifiers(player)
                end
            end

            if magic_pickup_gui_input and magic_pickup_gui_input.valid then
                if not player_modifiers.disabled_modifier[player.index] then
                    player_modifiers.disabled_modifier[player.index] = {}
                end
                if not magic_pickup_gui_input.state then
                    player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus = true
                    P.update_player_modifiers(player)
                elseif magic_pickup_gui_input.state then
                    player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus = false
                    P.update_player_modifiers(player)
                end
            end
            if conjure_gui_input and conjure_gui_input.valid and conjure_gui_input.selected_index then
                rpg_t[player.index].dropdown_select_index = conjure_gui_input.selected_index
            end

            if reset_gui_input and reset_gui_input.valid and reset_gui_input.state then
                if not rpg_t[player.index].reset then
                    if rpg_t[player.index].level >= 50 then
                        rpg_t[player.index].reset = true
                        Public.rpg_reset_player(player, true)
                    end
                end
            end
            if health_bar_gui_input and health_bar_gui_input.valid then
                if not health_bar_gui_input.state then
                    rpg_t[player.index].show_bars = false
                    if rpg_t[player.index].health_bar then
                        if rendering.is_valid(rpg_t[player.index].health_bar) then
                            rendering.destroy(rpg_t[player.index].health_bar)
                        end
                    end
                    if rpg_extra.enable_mana then
                        if rpg_t[player.index].mana_bar then
                            if rendering.is_valid(rpg_t[player.index].mana_bar) then
                                rendering.destroy(rpg_t[player.index].mana_bar)
                            end
                        end
                    end
                elseif health_bar_gui_input.state then
                    rpg_t[player.index].show_bars = true
                    if not rpg_t[player.index].health_bar then
                        rpg_t[player.index].health_bar = create_healthbar(player, 0.5)
                    elseif not rendering.is_valid(rpg_t[player.index].health_bar) then
                        rpg_t[player.index].health_bar = create_healthbar(player, 0.5)
                    end
                    local max_life =
                        math.floor(
                        player.character.prototype.max_health + player.character_health_bonus +
                            player.force.character_health_bonus
                    )
                    set_bar(player.character.health, max_life, rpg_t[player.index].health_bar)
                    if rpg_extra.enable_mana then
                        if not rpg_t[player.index].mana_bar then
                            rpg_t[player.index].mana_bar = create_manabar(player, 0.5)
                        elseif not rendering.is_valid(rpg_t[player.index].mana_bar) then
                            rpg_t[player.index].mana_bar = create_manabar(player, 0.5)
                        end
                        set_bar(
                            rpg_t[player.index].mana,
                            rpg_t[player.index].mana_max,
                            rpg_t[player.index].mana_bar,
                            true
                        )
                    end
                end
            end

            if player.gui.left[main_frame_name] then
                draw_gui(player, false)
            end
            frame.destroy()
        end
    end
)

Gui.on_click(
    discard_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[settings_frame_name]
        if not player.character then
            return
        end
        if frame and frame.valid then
            frame.destroy()
        end
    end
)

Gui.on_click(
    settings_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[settings_frame_name]
        if not player.character then
            return
        end
        if frame and frame.valid then
            frame.destroy()
        else
            extra_settings(player)
        end
    end
)

if _DEBUG then
    commands.add_command(
        'give_xp',
        'DEBUG ONLY - if you are seeing this then this map is running on debug-mode.',
        function(cmd)
            local p
            local player = game.player
            local param = tonumber(cmd.parameter)

            if player then
                if player ~= nil then
                    p = player.print
                    if not player.admin then
                        p("[ERROR] You're not admin!", Color.fail)
                        return
                    end
                    if not param then
                        return
                    end
                    p('Distributed ' .. param .. ' of xp.')
                    Public.give_xp(param)
                end
            end
        end
    )
end

Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_crafted_item, on_player_crafted_item)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.on_nth_tick(10, tick)

return Public
