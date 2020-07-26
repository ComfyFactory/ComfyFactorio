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

    return this.rpg_extra.debug
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

    return this.rpg_extra.surface_name
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

    return this.rpg_extra.enable_health_and_mana_bars
end

--- Enables the mana feature that allows players to spawn entities.
---@param value <boolean>
function Public.enable_mana(value)
    if value then
        this.rpg_extra.enable_mana = value
    else
        this.rpg_extra.enable_mana = false
    end

    return this.rpg_extra.enable_mana
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

    return this.rpg_extra.enable_wave_defense
end

--- Enables/disabled flame boots.
---@param value <boolean>
function Public.enable_flame_boots(value)
    if value then
        this.rpg_extra.enable_flame_boots = value
    else
        this.rpg_extra.enable_flame_boots = false
    end

    return this.rpg_extra.enable_flame_boots
end

--- Enables/disabled personal tax.
---@param value <boolean>
function Public.personal_tax_rate(value)
    if value then
        this.rpg_extra.personal_tax_rate = value
    else
        this.rpg_extra.personal_tax_rate = false
    end

    return this.rpg_extra.personal_tax_rate
end

--- Enables/disabled stone-path-tile creation on mined.
---@param value <boolean>
function Public.enable_stone_path(value)
    if value then
        this.rpg_extra.enable_stone_path = value
    else
        this.rpg_extra.enable_stone_path = false
    end

    return this.rpg_extra.enable_stone_path
end

--- Enables/disabled stone-path-tile creation on mined.
---@param value <boolean>
function Public.enable_one_punch(value)
    if value then
        this.rpg_extra.enable_one_punch = value
    else
        this.rpg_extra.enable_one_punch = false
    end

    return this.rpg_extra.enable_one_punch
end

--- Enables/disabled stone-path-tile creation on mined.
---@param value <boolean>
function Public.enable_one_punch_globally(value)
    if value then
        this.rpg_extra.enable_one_punch_globally = value
    else
        this.rpg_extra.enable_one_punch_globally = false
    end

    return this.rpg_extra.enable_one_punch_globally
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
