require 'modules.custom_death_messages'
require 'modules.flashlight_toggle_button'
require 'modules.global_chat_toggle'
require 'modules.worms_create_oil_patches'
require 'modules.biters_yield_coins'
require 'modules.scrap_towny_ffa.reset'
require 'modules.scrap_towny_ffa.mining'
require 'modules.scrap_towny_ffa.on_tick_schedule'
require 'modules.scrap_towny_ffa.building'
require 'modules.scrap_towny_ffa.spaceship'
require 'modules.scrap_towny_ffa.town_center'
require 'modules.scrap_towny_ffa.market'
require 'modules.scrap_towny_ffa.slots'
require 'modules.scrap_towny_ffa.wreckage_yields_scrap'
require 'modules.scrap_towny_ffa.rocks_yield_ore_veins'
require 'modules.scrap_towny_ffa.spawners_contain_biters'
require 'modules.scrap_towny_ffa.explosives_are_explosive'
require 'modules.scrap_towny_ffa.fluids_are_explosive'
require 'modules.scrap_towny_ffa.trap'
require 'modules.scrap_towny_ffa.turrets_drop_ammo'
require 'modules.scrap_towny_ffa.combat_balance'
require 'modules.scrap_towny_ffa.vehicles'

local Autostash = require 'modules.autostash'
local BottomFrame = require 'utils.gui.bottom_frame'
local MapDefaults = require 'modules.scrap_towny_ffa.map_defaults'
local Limbo = require 'modules.scrap_towny_ffa.limbo'
local Nauvis = require 'modules.scrap_towny_ffa.nauvis'
local Biters = require 'modules.scrap_towny_ffa.biters'
local Pollution = require 'modules.scrap_towny_ffa.pollution'
local Fish = require 'modules.scrap_towny_ffa.fish_reproduction'
local Team = require 'modules.scrap_towny_ffa.team'
local Radar = require 'modules.scrap_towny_ffa.limited_radar'

local function on_init()
    Autostash.insert_into_furnace(true)
    Autostash.insert_into_wagon(true)
    Autostash.bottom_button(true)
    BottomFrame.reset()
    BottomFrame.activate_custom_buttons(true)

    --log("on_init")
    game.enemy_has_vision_on_land_mines = false
    game.draw_resource_selection = true
    game.disable_tutorial_triggers()

    MapDefaults.initialize()
    Limbo.initialize()
    Nauvis.initialize()
    Team.initialize()
end

local tick_actions = {
    [60 * 0] = Radar.reset, -- each minute, at 00 seconds
    [60 * 5] = Team.update_town_chart_tags, -- each minute, at 05 seconds
    [60 * 10] = Team.set_all_player_colors, -- each minute, at 10 seconds
    [60 * 15] = Fish.reproduce, -- each minute, at 15 seconds
    [60 * 25] = Biters.unit_groups_start_moving, -- each minute, at 25 seconds
    [60 * 30] = Radar.reset, -- each minute, at 30 seconds
    [60 * 45] = Biters.validate_swarms, -- each minute, at 45 seconds
    [60 * 50] = Biters.swarm, -- each minute, at 50 seconds
    [60 * 55] = Pollution.market_scent -- each minute, at 55 seconds
}

local function on_nth_tick(event)
    -- run each second
    local tick = event.tick
    local seconds = tick % 3600 -- tick will recycle minute
    if not tick_actions[seconds] then
        return
    end
    --game.surfaces['nauvis'].play_sound({path = 'utility/alert_destroyed', volume_modifier = 1})
    --log('seconds = ' .. seconds)
    tick_actions[seconds]()
end

local Event = require 'utils.event'

Event.on_init(on_init)
Event.on_nth_tick(60, on_nth_tick) -- once every second
