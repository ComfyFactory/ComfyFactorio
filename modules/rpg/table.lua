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
local settings_tooltip_frame = Gui.uid_name()
local close_settings_tooltip_frame = Gui.uid_name()
local settings_tooltip_name = Gui.uid_name()
local save_button_name = Gui.uid_name()
local discard_button_name = Gui.uid_name()
local draw_main_frame_name = Gui.uid_name()
local close_main_frame_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local settings_button_name = Gui.uid_name()
local spell_gui_button_name = Gui.uid_name()
local spell_gui_frame_name = Gui.uid_name()
local enable_spawning_frame_name = Gui.uid_name()
local spell1_button_name = Gui.uid_name()
local spell2_button_name = Gui.uid_name()
local spell3_button_name = Gui.uid_name()

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {}

Public.points_per_level = 5

Public.experience_levels = {0}
for a = 1, 4999, 1 do -- max level
    Public.experience_levels[#Public.experience_levels + 1] = Public.experience_levels[#Public.experience_levels] + a * 8
end

Public.gui_settings_levels = {
    ['reset_text_label'] = 50,
    ['stone_path_label'] = 20,
    ['aoe_punch_label'] = 30,
    ['explosive_bullets_label'] = 50
}

Public.die_cause = {
    ['ammo-turret'] = true,
    ['electric-turret'] = true,
    ['fluid-turret'] = true
}

Public.nth_tick = 18001
Public.visuals_delay = 1800
Public.xp_floating_text_color = {157, 157, 157}

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

Public.auto_allocate_nodes = {
    {'allocations.deactivated'},
    {'allocations.str'},
    {'allocations.mag'},
    {'allocations.dex'},
    {'allocations.vit'}
}

Public.auto_allocate_nodes_func = {
    'Deactivated',
    'Strength',
    'Magicka',
    'Dexterity',
    'Vitality'
}

function Public.reset_table(migrate)
    this.rpg_extra.debug = false
    this.rpg_extra.breached_walls = 1
    this.rpg_extra.reward_new_players = 0
    this.rpg_extra.level_limit_enabled = false
    this.rpg_extra.global_pool = 0
    this.rpg_extra.heal_modifier = 2
    this.rpg_extra.personal_tax_rate = 0.3
    this.rpg_extra.leftover_pool = 0
    this.rpg_extra.turret_kills_to_global_pool = true
    this.rpg_extra.difficulty = false
    this.rpg_extra.surface_name = 'nauvis'
    this.rpg_extra.enable_health_and_mana_bars = false
    this.rpg_extra.enable_mana = false
    this.rpg_extra.mana_limit = 100000
    this.rpg_extra.enable_wave_defense = false
    this.rpg_extra.enable_explosive_bullets = false
    this.rpg_extra.enable_explosive_bullets_globally = false
    this.rpg_extra.enable_range_buffs = false
    this.rpg_extra.mana_per_tick = 0.1
    this.rpg_extra.xp_modifier_when_mining = 0.0045
    this.rpg_extra.force_mana_per_tick = false
    this.rpg_extra.enable_stone_path = false
    this.rpg_extra.enable_auto_allocate = false
    this.rpg_extra.enable_aoe_punch = true
    this.rpg_extra.enable_aoe_punch_globally = false
    this.rpg_extra.disable_get_heal_modifier_from_using_fish = false
    this.rpg_extra.tweaked_crafting_items = {
        ['red-wire'] = true,
        ['green-wire'] = true,
        ['stone-furnace'] = true,
        ['wooden-chest'] = true,
        ['copper-cable'] = true,
        ['iron-stick'] = true,
        ['iron-gear-wheel'] = true,
        ['pipe'] = true
    }
    this.tweaked_crafting_items_enabled = false
    if not migrate then
        this.rpg_t = {}
    end
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
---@param key string
function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

--- Gets value from player rpg_t table
---@param key string|integer
---@param value string|nil
function Public.get_value_from_player(key, value)
    if key and value then
        if (this.rpg_t[key] and this.rpg_t[key][value]) then
            return this.rpg_t[key][value]
        end
        return false
    end
    if key then
        if this.rpg_t[key] then
            return this.rpg_t[key]
        end
        return false
    end
    return false
end

--- Sets value to player rpg_t table
---@param key string
---@param value string|boolean|number|nil
---@param setter string|boolean|number|nil
function Public.set_value_to_player(key, value, setter)
    if key and value then
        if (this.rpg_t[key] and this.rpg_t[key][value]) then
            this.rpg_t[key][value] = setter or false
        elseif (this.rpg_t[key] and not this.rpg_t[key][value]) then
            this.rpg_t[key][value] = setter or false
        end
    end
end

--- Sets a new table to rpg_t table
---@param key string
---@param tbl table
function Public.set_new_player_tbl(key, tbl)
    if key and tbl then
        if type(tbl) ~= 'table' then
            return error('Given parameter is not a table.')
        end

        this.rpg_t[key] = tbl
        return this.rpg_t[key]
    end
end

--- Removes a player from rpg_t table
---@param index number
function Public.remove_player(index)
    if index then
        if this.rpg_t[index] then
            this.rpg_t[index] = nil
        end
    end
end

--- Sets value to table
---@param key string
function Public.set(key)
    if key then
        return this[key]
    else
        return this
    end
end

--- Toggle debug - when you need to troubleshoot.
function Public.toggle_debug(value)
    this.rpg_extra.debug = value or false

    return this.rpg_extra.debug
end

--- Toggle debug - when you need to troubleshoot.
function Public.toggle_debug_aoe_punch()
    if this.rpg_extra.debug_aoe_punch then
        this.rpg_extra.debug_aoe_punch = false
    else
        this.rpg_extra.debug_aoe_punch = true
    end

    return this.rpg_extra.debug_aoe_punch
end

--- Debug only - when you need to troubleshoot.
---@param str string
function Public.debug_log(str)
    if not this.rpg_extra.debug then
        return
    end
    print(str)
end

--- Sets surface name for rpg_v2 to use
---@param name string
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
---@param value boolean
function Public.enable_health_and_mana_bars(value)
    this.rpg_extra.enable_health_and_mana_bars = value or false

    return this.rpg_extra.enable_health_and_mana_bars
end

--- Toggles the mod gui state.
---@param value boolean
---@param read boolean
function Public.enable_mod_gui(value, read)
    if not read then
        Gui.set_mod_gui_top_frame(value or false)
    end

    if Gui.get_mod_gui_top_frame() then
        local players = game.connected_players
        for i = 1, #players do
            local player = players[i]
            local top = player.gui.top
            if top.mod_gui_top_frame and top.mod_gui_top_frame.valid then
                top.mod_gui_top_frame.visible = true
            end
            for _, child in pairs(top.children) do
                if child.caption == '[RPG]' then
                    child.destroy()
                    Public.draw_gui_char_button(player)
                end
            end
        end
    else
        local players = game.connected_players
        local count = 0
        for i = 1, #players do
            local player = players[i]
            local top = Gui.get_button_flow(player)
            for _, child in pairs(top.children) do
                count = count + 1
                if child.caption == '[RPG]' then
                    child.destroy()
                    Public.draw_gui_char_button(player)
                end
            end
            if count == 0 then
                if player.gui.top.mod_gui_top_frame and player.gui.top.mod_gui_top_frame.valid then
                    player.gui.top.mod_gui_top_frame.visible = false
                end
            else
                if player.gui.top.mod_gui_top_frame and player.gui.top.mod_gui_top_frame.valid then
                    player.gui.top.mod_gui_top_frame.visible = true
                end
            end
        end
    end
end

--- Enables the mana feature that allows players to spawn entities.
---@param value boolean
function Public.enable_mana(value)
    this.rpg_extra.enable_mana = value or false

    return this.rpg_extra.enable_mana
end

--- This should only be enabled if wave_defense is enabled.
--- It boosts the amount of xp the players get after x amount of waves.
---@param value boolean
function Public.enable_wave_defense(value)
    this.rpg_extra.enable_wave_defense = value or false

    return this.rpg_extra.enable_wave_defense
end

--- Enables/disabled explosive bullets globally.
---@param value boolean
function Public.enable_explosive_bullets_globally(value)
    this.rpg_extra.enable_explosive_bullets_globally = value or false

    return this.rpg_extra.enable_explosive_bullets_globally
end

--- Fetches if the explosive bullets module is activated globally.
function Public.get_explosive_bullets_globally()
    return this.rpg_extra.enable_explosive_bullets_globally
end

--- Fetches if the explosive bullets module is activated.
function Public.get_explosive_bullets()
    return this.rpg_extra.enable_explosive_bullets
end

--- Enables/disabled explosive bullets.
---@param value boolean
function Public.enable_explosive_bullets(value)
    this.rpg_extra.enable_explosive_bullets = value or false

    return this.rpg_extra.enable_explosive_bullets
end

--- Fetches if the range buffs module is activated.
function Public.get_range_buffs()
    return this.rpg_extra.enable_range_buffs
end

--- Enables/disabled range buffs.
---@param value boolean
function Public.enable_range_buffs(value)
    this.rpg_extra.enable_range_buffs = value or false

    return this.rpg_extra.enable_range_buffs
end

--- Enables/disabled personal tax.
---@param value boolean
function Public.personal_tax_rate(value)
    this.rpg_extra.personal_tax_rate = value or false

    return this.rpg_extra.personal_tax_rate
end

--- Enables/disabled stone-path-tile creation on mined.
---@param value boolean
function Public.enable_stone_path(value)
    this.rpg_extra.enable_stone_path = value or false

    return this.rpg_extra.enable_stone_path
end

--- Enables/disabled auto-allocations of skill-points.
---@param value boolean
function Public.enable_auto_allocate(value)
    this.rpg_extra.enable_auto_allocate = value or false

    return this.rpg_extra.enable_auto_allocate
end

--- Enables/disabled aoe_punch.
---@param value boolean
function Public.enable_aoe_punch(value)
    this.rpg_extra.enable_aoe_punch = value or false

    return this.rpg_extra.enable_aoe_punch
end

--- Enables/disabled aoe_punch.
---@param value boolean
function Public.enable_aoe_punch_globally(value)
    this.rpg_extra.enable_aoe_punch_globally = value or false

    return this.rpg_extra.enable_aoe_punch_globally
end

function Public.tweaked_crafting_items(tbl)
    if not tbl then
        return
    end

    if type(type) ~= 'table' then
        return
    end

    this.tweaked_crafting_items = tbl

    return this.tweaked_crafting_items
end

function Public.migrate_new_rpg_tbl(player)
    local rpg_t = Public.get_value_from_player(player.index, nil)
    if rpg_t then
        rpg_t.flame_boots = nil
        rpg_t.one_punch = nil
        rpg_t.points_left = rpg_t.points_to_distribute or 0
        rpg_t.points_to_distribute = nil

        rpg_t.aoe_punch = false
        rpg_t.auto_toggle_features = {
            aoe_punch = false,
            stone_path = false
        }
    end

    Public.enable_mod_gui(false, true)

    local screen = player.gui.screen
    for _, child in pairs(screen.children) do
        if child.caption and child.caption[1] == 'rpg_settings.spell_name' then
            child.destroy()
        end
    end
end

function Public.migrate_to_new_version()
    Public.reset_table(true)
    if this.rpg_spells then
        this.rpg_spells = nil
    end

    local players = game.players

    for _, player in pairs(players) do
        Public.migrate_new_rpg_tbl(player)
    end
end

Public.settings_frame_name = settings_frame_name
Public.settings_tooltip_frame = settings_tooltip_frame
Public.close_settings_tooltip_frame = close_settings_tooltip_frame
Public.settings_tooltip_name = settings_tooltip_name
Public.save_button_name = save_button_name
Public.discard_button_name = discard_button_name
Public.draw_main_frame_name = draw_main_frame_name
Public.close_main_frame_name = close_main_frame_name
Public.main_frame_name = main_frame_name
Public.settings_button_name = settings_button_name
Public.spell_gui_button_name = spell_gui_button_name
Public.spell_gui_frame_name = spell_gui_frame_name
Public.enable_spawning_frame_name = enable_spawning_frame_name
Public.spell1_button_name = spell1_button_name
Public.spell2_button_name = spell2_button_name
Public.spell3_button_name = spell3_button_name

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)

Event.on_configuration_changed(
    function()
        print('[RPG] Migrating to new version')
        Public.migrate_to_new_version()
    end
)

return Public
