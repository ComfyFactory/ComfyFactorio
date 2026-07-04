require 'modules.infinity_chest'
require 'modules.infinity_power'
require 'modules.infinity_storage'
require 'modules.portable_chest'
require 'utils.gui.warp_system'
require 'utils.commands.bonus'
require 'modules.tree_decon'
require 'modules.launch_fish_to_win'
require 'modules.biters_yield_coins'
require 'modules.dangerous_goods'
require 'modules.autofill'
require 'utils.gui.settings'
require 'modules.autodecon_when_depleted'
require 'modules.biters_double_damage'
require 'modules.custom_death_messages'
require 'modules.spawn_area'
--require 'modules.explosive_biters'
--require 'modules.biter_pets'
--require 'modules.enhancedbiters'
--require 'modules.splice'
--require 'modules.hunger'require 'modules.hidden_dimension.main'

local SpawnersContainBiters = require 'modules.spawners_contain_biters'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Ores = require 'modules.scramble_ores'
local Autostash = require 'modules.autostash'
local Map = require 'modules.map_info'
local Utils = require 'maps.oarc.ms_utils'
local Silo = require 'maps.oarc.frontier_silo'
local R_launch = require 'maps.oarc.rocket_launch'
local Surface = require 'utils.surface'
local SS = require 'maps.oarc.separate_spawns'
local Alert = require 'utils.alert'
local MT = require 'maps.oarc.table'
local ChunkCleaner = require 'utils.chunk_removal'
local HD = require 'modules.hidden_dimension.table'
local Worms = require 'modules.surrounded_by_worms'
local SpawnEnt = require 'modules.spawn_ent.main'
local BottomFrame = require 'utils.gui.bottom_frame'
local Misc = require 'utils.commands.misc'
local SessionData = require 'utils.datastore.session_data'

require 'maps.oarc.evolution'

local random = math.random

local function on_start()
    local this = MT.get()

    if this.hidden_dimension_enabled then
        HD.module_enabled(true)
        HD.multiplayer_enabled(true)
    end

    local caption = '    land of the free    '
    local subtext = 'Biters attack at [color=red]night[/color]'

    if Surface.get('darkness_enabled') then
        caption = '    the horror nights    '
        subtext =
        'Biters attack at [color=red]night[/color] - it gets very dark.\n Surround yourself with light to withstand the nights.'
    end

    Autostash.insert_into_furnace(true)
    Autostash.insert_into_wagon(false)
    Autostash.bottom_button(true)
    Misc.bottom_button(true)
    BottomFrame.activate_custom_buttons(true)

    local surface_name = Surface.get_surface_name()

    Worms.allow_surface(surface_name)

    SpawnEnt.markets_destructible(true)

    SpawnersContainBiters.add_surface(surface_name)

    local T = Map.get_map_information()
    T.main_caption = 'ComfyFactorio!'
    T.sub_caption = caption
    T.text =
        table.concat(
            {
                'Choose between playing solo or joining the main-team.\n',
                "If you don't feel like playing solo, join someones base.\n",
                '\n',
                subtext,
                '\n',
                '\n',
                'Launching a rocket will not be an easy task,\n',
                'since worms are spawned everywhere,\n',
                'their strength and numbers increase over time.\n',
                '\n',
                'Delve deep for greater treasures, but also face increased dangers.\n',
                '\n',
                'Biters drop coin when defeated,\n',
                'Use these coins to purchase loot from markets that spawn around the map.\n',
                '\n',
                'Radars will not reveal new chunks.\n',
                '\n',
                'Unoptimized huge builds will be deleted without any notice.\n',
                "Don't explore too much since it makes the server lag.\n",
                '\n',
                'Good luck, over and out!'
            }
        )
    T.main_caption_color = { r = 150, g = 150, b = 0 }
    T.sub_caption_color = { r = 0, g = 150, b = 0 }

    Map.call_map_info_on_join(false)

    SS.InitSpawnGlobalsAndForces()

    ChunkCleaner.toggle_chunk_removal(true)

    Utils.CreateGameSurface()
    Utils.create_town_in_tbl()

    for _, v in pairs(this.scenario_config.resource_tiles_new) do
        v.amount = 10000
        v.size = 35
    end

    this.scenario_config.pos = { { x = -60, y = -45 }, { x = -20, y = -45 }, { x = 20, y = -45 }, { x = 60, y = -45 } }
    this.scenario_config.resource_patches_new['crude-oil'].x_offset_start = 85
    this.scenario_config.water_new.x_offset = -100

    game.map_settings.enemy_evolution.pollution_factor = 0
    game.map_settings.pollution.ageing = 5

    if this.enable_town_shape then
        this.enable_buddy_spawn = false
    end

    if (this.frontier_rocket_silo_mode) then
        Silo.SpawnSilosAndGenerateSiloAreas()
    end
    this.vanillaSpawns = Utils.shuffle(this.vanillaSpawns)
end
Event.on_init(on_start)

Event.add(
    defines.events.on_rocket_launched,
    function (event)
        local frontier_rocket_silo_mode = MT.get('frontier_rocket_silo_mode')
        if frontier_rocket_silo_mode then
            R_launch.RocketLaunchEvent(event)
        end
    end
)

Event.add(
    defines.events.on_marked_for_deconstruction,
    function (event)
        if not event.entity or not event.entity.valid then
            return
        end
        if event.entity.name == 'fish' then
            event.entity.cancel_deconstruction(game.get_player(event.player_index).force.name)
        end
    end
)

Event.add(
    defines.events.on_chunk_generated,
    function (event)
        if event.surface.name == 'wbtc' then
            local enable_scramble = MT.get('enable_scramble')
            local enable_undecorator = MT.get('enable_undecorator')
            if enable_scramble then
                Ores.scramble(event)
            end

            if enable_undecorator then
                Utils.UndecorateOnChunkGenerate(event)
            end

            Silo.GenerateRocketSiloChunk(event)
            ChunkCleaner.on_chunk_generated(event)
        end
        SS.SeparateSpawnsGenerateChunk(event)
    end
)

Event.add(
    defines.events.on_gui_click,
    function (event)
        SS.WelcomeTextGuiClick(event)
        SS.SpawnOptsGuiClick(event)
        SS.SpawnCtrlGuiClick(event)
        SS.SharedSpwnOptsGuiClick(event)
        SS.BuddySpawnOptsGuiClick(event)
        SS.BuddySpawnWaitMenuClick(event)
        SS.BuddySpawnRequestMenuClick(event)
        SS.SharedSpawnJoinWaitMenuClick(event)
    end
)

Event.add(
    defines.events.on_gui_checked_state_changed,
    function (event)
        SS.SpawnOptsRadioSelect(event)
        SS.SpawnCtrlGuiOptionsSelect(event)
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        Utils.PlayerJoinedMessages(event)
    end
)

Event.add(
    defines.events.on_player_created,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local surface_name = Surface.get_surface_name()

        -- Move the player to the game surface immediately.
        local pos = game.get_surface(surface_name).find_non_colliding_position('character', { x = 0, y = 0 }, 3, 0)
        if not pos then
            return
        end
        player.teleport(pos, surface_name)

        local check_players = MT.get('check_players')
        if check_players[player.name] then
            check_players[player.name] = nil
        end

        local enable_longreach = MT.get('enable_longreach')

        if enable_longreach then
            Utils.GivePlayerLongReach(player)
        end

        SS.SeparateSpawnsPlayerCreated(event.player_index)
    end
)

Event.add(
    defines.events.on_player_respawned,
    function (event)
        local player = game.get_player(event.player_index)

        SS.SeparateSpawnsPlayerRespawned(event)

        local enable_longreach = MT.get('enable_longreach')

        if enable_longreach then
            Utils.GivePlayerLongReach(player)
        end
    end
)

Event.add(
    defines.events.on_player_left_game,
    function (event)
        local player = game.get_player(event.player_index)
        SS.find_unused_spawns(player, true, true)
    end
)

Event.add(
    defines.events.on_built_entity,
    function (event)
        local frontier_rocket_silo_mode = MT.get('frontier_rocket_silo_mode')
        if frontier_rocket_silo_mode then
            Silo.BuildSiloAttempt(event)
        end

        local entity = event.entity
        if not entity.valid then
            return
        end

        local position = entity.position
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        if not SessionData.allowed(player, 'unlimited-radars') then
            if entity.name == 'radar' then
                if entity.surface.count_entities_filtered({ type = 'radar', position = position, radius = 64 }) > 1 then
                    player.create_local_flying_text({
                        position = entity.position,
                        text = 'Another radar is found nearby!',
                        color = { 255, 0, 0 }
                    })

                    player.surface.spill_item_stack({ position = position, stack = { name = entity.name, count = 1 }, enable_looted = true })
                    entity.destroy()
                    return
                end
            end
        end
    end
)

Event.add(
    defines.events.on_tick,
    function ()
        local tick = game.tick
        local surface_name = Surface.get_surface_name()

        if tick % 300 == 0 then
            local clear_old_bases_enabled = MT.get('clear_old_bases_enabled')

            if clear_old_bases_enabled then
                local check_players = MT.get('check_players')
                local cleaner_running = MT.get('cleaner_running')
                if cleaner_running then
                    goto continue
                end
                local players = game.players
                for i = 1, #players do
                    local player = players[i]
                    if player and player.valid and not player.connected then
                        if not check_players[player.name] then
                            check_players[player.name] = true
                            SS.remove_absent_players(player, true)
                        end
                    end
                end
            end
        end

        ::continue::
        SS.DelayedSpawnOnTick()

        local frontier_rocket_silo_mode = MT.get('frontier_rocket_silo_mode')

        if frontier_rocket_silo_mode then
            Silo.DelayedSiloCreationOnTick(game.get_surface(surface_name))
        end
    end
)

local tick_actions =
{
    [60 * 15] = Utils.recreate_fishes -- each minute, at 15 seconds
    -- [60 * 25] = Biters.unit_groups_start_moving,
    -- [60 * 45] = Biters.validate_swarms,
    -- [60 * 50] = Biters.swarm
}

Event.on_nth_tick(
    60,
    function (event)
        local tick = event.tick
        local seconds = tick % 3600 -- tick will recycle minute
        if not tick_actions[seconds] then
            return
        end
        tick_actions[seconds]()
    end
)

Event.add(
    defines.events.on_player_mined_entity,
    function (event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        local e = event.entity
        if e.type ~= 'tree' then
            return
        end

        if e and e.valid and random(1, 4) == 1 then
            player.insert({ name = 'coin', count = random(1, 3) })
        end
    end
)

Event.add(
    defines.events.on_robot_built_entity,
    function (event)
        local frontier_rocket_silo_mode = MT.get('frontier_rocket_silo_mode')
        if frontier_rocket_silo_mode then
            local e = event.entity
            if e and e.valid then
                Silo.BuildSiloAttempt(event)
            end
        end
    end
)

Event.add(
    defines.events.on_console_chat,
    function (event)
        local team_chat = MT.get('team_chat')
        if (team_chat) then
            if (event.player_index ~= nil) then
                Utils.ShareChatBetweenForces(game.get_player(event.player_index), event.message)
            end
        end
    end
)

Event.add(
    defines.events.on_research_finished,
    function (event)
        local research = event.research
        local force_name = research.force.name
        if research.name == 'rocket-silo' then
            local message =
            'Note! Rocket-silos can only be built on designated areas! You can find these on the mini-map.'
            Alert.alert_force(force_name, 10, message)

            game.forces[force_name].play_sound { path = 'utility/new_objective', volume_modifier = 0.75 }
        end

        local frontier_rocket_silo_mode = MT.get('frontier_rocket_silo_mode')
        local enable_silo_player_build = MT.get('enable_silo_player_build')
        local enable_loaders = MT.get('enable_loaders')
        local disable_nukes = MT.get('disable_nukes')

        if frontier_rocket_silo_mode and not enable_silo_player_build then
            Utils.RemoveRecipe(event.research.force, 'rocket-silo')
        end

        if enable_loaders then
            Utils.EnableLoaders(event)
        end

        if disable_nukes then
            Utils.DisableTech(research.force, 'atomic-bomb')
        end
        -- Utils.DisableTech(research.force, 'nuclear-power')
    end
)

Event.add(
    defines.events.on_entity_spawned,
    function (event)
        local modded_enemy = MT.get('modded_enemy')
        if (modded_enemy) then
            SS.ModifyEnemySpawnsNearPlayerStartingAreas(event)
        end
    end
)
Event.add(
    defines.events.on_biter_base_built,
    function (event)
        local modded_enemy = MT.get('modded_enemy')
        if (modded_enemy) then
            SS.ModifyEnemySpawnsNearPlayerStartingAreas(event)
        end
    end
)

Event.add(
    defines.events.on_character_corpse_expired,
    function (event)
        Utils.DropGravestoneChestFromCorpse(event.corpse)
    end
)

Event.add(
    defines.events.on_sector_scanned,
    function (event)
        local radar = event.radar
        if not radar or not radar.valid then
            return
        end

        local pos = event.chunk_position

        radar.force.cancel_charting(radar.surface.index)
        radar.force.unchart_chunk(pos, radar.surface.index)
    end
)

Event.on_nth_tick(
    60,
    function ()
        local players = game.connected_players
        local tick = game.tick
        local respawn_cooldown = MT.get('respawn_cooldown')
        local ticks_per_minute = MT.get('ticks_per_minute')
        local playerCooldowns = MT.get('playerCooldowns')
        for _, player in pairs(players) do
            SS.DisplayPleaseWaitForSpawnDialog(player)

            local frame = Gui.get_player_active_frame(player)
            if frame and frame.valid then
                local spwn_ctrl_panel = frame.spwn_ctrl_panel
                if spwn_ctrl_panel and spwn_ctrl_panel.valid then
                    local respawn_cooldown_note1 = spwn_ctrl_panel.respawn_cooldown_note1
                    if respawn_cooldown_note1 and respawn_cooldown_note1.valid then
                        respawn_cooldown_note1.caption =
                        {
                            'ms-set-respawn-loc-cooldown',
                            Utils.formattime((respawn_cooldown * ticks_per_minute) -
                                (tick - playerCooldowns[player.name].setRespawn))
                        }
                    end
                end
            end
        end
    end
)
