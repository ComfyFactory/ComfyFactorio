require 'modules.custom_death_messages'
require 'modules.flashlight_toggle_button'
require 'modules.global_chat_toggle'
require 'modules.worms_create_oil_patches'
require 'modules.biters_yield_coins'
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

local Autostash = require 'modules.autostash'
local BottomFrame = require 'utils.gui.bottom_frame'
local Table = require 'modules.scrap_towny_ffa.table'
local Nauvis = require 'modules.scrap_towny_ffa.nauvis'
local Biters = require 'modules.scrap_towny_ffa.biters'
local Pollution = require 'modules.scrap_towny_ffa.pollution'
local Fish = require 'modules.scrap_towny_ffa.fish_reproduction'
local Info = require 'modules.scrap_towny_ffa.info'
local Team = require 'modules.scrap_towny_ffa.team'
local Spawn = require 'modules.scrap_towny_ffa.spawn'
local Radar = require 'modules.scrap_towny_ffa.limited_radar'

-- for testing purposes only!!!
local testing_mode = false

-- how long in ticks between spawn and death will be considered spawn kill (10 seconds)
local max_ticks_between_spawns = 60 * 10
-- how many players must login before teams are teams_enabled
local min_players_for_enabling_towns = 0

local function load_buffs(player)
    if player.force.name ~= 'player' and player.force.name ~= 'rogue' then
        return
    end
    local ffatable = Table.get_table()
    local player_index = player.index
    if player.character == nil then
        return
    end
    if ffatable.buffs[player_index] == nil then
        ffatable.buffs[player_index] = {}
    end
    if ffatable.buffs[player_index].character_inventory_slots_bonus ~= nil then
        player.character.character_inventory_slots_bonus = ffatable.buffs[player_index].character_inventory_slots_bonus
    end
    if ffatable.buffs[player_index].character_mining_speed_modifier ~= nil then
        player.character.character_mining_speed_modifier = ffatable.buffs[player_index].character_mining_speed_modifier
    end
    if ffatable.buffs[player_index].character_crafting_speed_modifier ~= nil then
        player.character.character_crafting_speed_modifier = ffatable.buffs[player_index].character_crafting_speed_modifier
    end
end

local function on_player_joined_game(event)
    local ffatable = Table.get_table()
    local player = game.players[event.player_index]
    local surface = game.surfaces['nauvis']

    player.game_view_settings.show_minimap = false
    player.game_view_settings.show_map_view_options = false
    player.game_view_settings.show_entity_info = true
    player.map_view_settings = {
        ['show-logistic-network'] = false,
        ['show-electric-network'] = false,
        ['show-turret-range'] = false,
        ['show-pollution'] = false,
        ['show-train-station-names'] = false,
        ['show-player-names'] = false,
        ['show-networkless-logistic-members'] = false,
        ['show-non-standard-map-info'] = false
    }
    player.show_on_map = false
    --player.game_view_settings.show_side_menu = false

    Info.toggle_button(player)
    Team.set_player_color(player)
    if player.force ~= game.forces.player then
        return
    end

    if player.online_time == 0 then
        Info.show(player)
        if testing_mode then
            ffatable.towns_enabled = true
        else
            ffatable.players = ffatable.players + 1
            if ffatable.players >= min_players_for_enabling_towns then
                ffatable.towns_enabled = true
            end
        end

        player.teleport({0, 0}, game.surfaces['limbo'])
        Team.set_player_to_outlander(player)
        Team.give_player_items(player)
        player.insert {name = 'coin', count = '100'}
        player.insert {name = 'stone-furnace', count = '1'}
        Team.give_key(player.index)
        if (testing_mode == true) then
            player.cheat_mode = true
            player.force.research_all_technologies()
            player.insert {name = 'coin', count = '9900'}
        end
        -- first time spawn point
        local spawn_point = Spawn.get_new_spawn_point(player, surface)
        ffatable.strikes[player.name] = 0
        Spawn.clear_spawn_point(spawn_point, surface)
        -- reset cooldown
        ffatable.cooldowns_town_placement[player.index] = 0
        ffatable.last_respawn[player.name] = 0
        player.teleport(spawn_point, surface)
        return
    end
    load_buffs(player)

    if not ffatable.requests[player.index] or ffatable.requests[player.index] ~= 'kill-character' then
        return
    end
    if player.character then
        if player.character.valid then
            player.character.die()
        end
    end
    ffatable.requests[player.index] = nil
end

local function on_player_respawned(event)
    local ffatable = Table.get_table()
    local player = game.players[event.player_index]
    local surface = player.surface
    Team.give_player_items(player)
    if player.force == game.forces['rogue'] then
        Team.set_player_to_outlander(player)
    end
    if player.force == game.forces['player'] then
        Team.give_key(player.index)
    end

    -- get_spawn_point will always return a valid spawn
    local spawn_point = Spawn.get_spawn_point(player, surface)

    -- reset cooldown
    ffatable.last_respawn[player.name] = game.tick
    player.teleport(spawn_point, surface)
    load_buffs(player)
end

local function on_player_died(event)
    local ffatable = Table.get_table()
    local player = game.players[event.player_index]
    if ffatable.strikes[player.name] == nil then
        ffatable.strikes[player.name] = 0
    end

    local ticks_elapsed = game.tick - ffatable.last_respawn[player.name]
    if ticks_elapsed < max_ticks_between_spawns then
        ffatable.strikes[player.name] = ffatable.strikes[player.name] + 1
    else
        ffatable.strikes[player.name] = 0
    end
end

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

    local ffatable = Table.get_table()
    ffatable.last_respawn = {}
    ffatable.last_death = {}
    ffatable.strikes = {}
    ffatable.testing_mode = testing_mode
    ffatable.spawn_point = {}
    ffatable.buffs = {}
    ffatable.players = 0
    ffatable.towns_enabled = true

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
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_died, on_player_died)
