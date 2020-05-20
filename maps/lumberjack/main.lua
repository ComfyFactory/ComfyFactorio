-- modules
require 'maps.lumberjack.player_list'
require 'maps.lumberjack.comfylatron'
require 'maps.lumberjack.commands'
require 'maps.lumberjack.corpse_util'

require 'on_tick_schedule'
require 'modules.dynamic_landfill'
require 'modules.shotgun_buff'
require 'modules.burden'
require 'modules.rocks_heal_over_time'
require 'modules.no_deconstruction_of_neutral_entities'
require 'modules.flamethrower_nerf'
require 'modules.rocks_yield_ore_veins'
require 'modules.spawners_contain_biters'
require 'modules.biters_yield_coins'
require 'modules.biter_noms_you'
require 'modules.wave_defense.main'
require 'modules.admins_operate_biters'
require 'modules.pistol_buffs'

local Difficulty = require 'modules.difficulty_vote'
local Server = require 'utils.server'
local Explosives = require 'modules.explosives'
local Color = require 'utils.color_presets'
local Entities = require 'maps.lumberjack.entities'
local update_gui = require 'maps.lumberjack.gui'
local ICW = require 'maps.lumberjack.icw.main'
local WD = require 'modules.wave_defense.table'
local Map = require 'modules.map_info'
local RPG = require 'maps.lumberjack.rpg'
local Reset = require 'maps.lumberjack.soft_reset'
local Terrain = require 'maps.lumberjack.terrain'
local Event = require 'utils.event'
local WPT = require 'maps.lumberjack.table'
local Locomotive = require 'maps.lumberjack.locomotive'.locomotive_spawn
local render_train_hp = require 'maps.lumberjack.locomotive'.render_train_hp
local Score = require 'comfy_panel.score'
local Poll = require 'comfy_panel.poll'
local Collapse = require 'modules.collapse'
local Balance = require 'maps.lumberjack.balance'
local shape = require 'maps.lumberjack.terrain'.heavy_functions
local Generate = require 'maps.lumberjack.generate'
local Task = require 'utils.task'

local Public = {}
local math_random = math.random

WPT.init({train_reveal = false, energy_shared = true, reveal_normally = true})

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['wood'] = 4, ['rail'] = 16, ['raw-fish'] = 2}

local grandmaster = '[color=blue]Grandmaster:[/color]'

local function create_forces_and_disable_tech()
    if not game.forces.defenders then
        game.create_force('defenders')
    end
    if not game.forces.lumber_defense then
        game.create_force('lumber_defense')
    end
    game.forces.defenders.share_chart = false
    game.forces.player.set_friend('defenders', true)
    game.forces.player.set_friend('lumber_defense', false)
    game.forces.lumber_defense.set_friend('player', false)
    game.forces.lumber_defense.set_friend('enemy', true)
    game.forces.enemy.set_friend('defenders', true)
    game.forces.enemy.set_friend('lumber_defense', true)
    game.forces.defenders.set_friend('player', true)
    game.forces.defenders.set_friend('enemy', true)
    game.forces.defenders.share_chart = false
    game.forces.player.technologies['landfill'].enabled = false
    game.forces.player.technologies['optics'].researched = true
    game.forces.player.technologies['land-mine'].enabled = false
    Balance.init_enemy_weapon_damage()
end

local function set_difficulty()
    local Diff = Difficulty.get()
    local wave_defense_table = WD.get_table()
    local player_count = #game.connected_players
    if not Diff.difficulty_vote_value then
        Diff.difficulty_vote_value = 0.1
    end

    wave_defense_table.max_active_biters = 768 + player_count * (90 * Diff.difficulty_vote_value)

    -- threat gain / wave
    wave_defense_table.threat_gain_multiplier = 1.2 + player_count * Diff.difficulty_vote_value * 0.1

    local amount = player_count * 0.25 + 2
    amount = math.floor(amount)
    if amount > 8 then
        amount = 8
    end
    Collapse.set_amount(amount)

    wave_defense_table.wave_interval = 3600
end

local function render_direction(surface)
    rendering.draw_text {
        text = 'Welcome to Lumberjack!',
        surface = surface,
        target = {-0, 10},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 20},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 30},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 40},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 50},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 60},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = 'Biters will attack this area.',
        surface = surface,
        target = {-0, 70},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    surface.create_entity({name = 'electric-beam', position = {-196, 74}, source = {-196, 74}, target = {196, 74}})
    surface.create_entity({name = 'electric-beam', position = {-196, 74}, source = {-196, 74}, target = {196, 74}})
end

function Public.reset_map()
    local this = WPT.get_table()
    local wave_defense_table = WD.get_table()
    local get_score = Score.get_table()
    local Diff = Difficulty.get()
    local map_gen_settings = {
        ['seed'] = math_random(10000, 99999),
        ['water'] = 0.001,
        ['starting_area'] = 1,
        ['cliff_settings'] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
        ['default_enable_all_autoplace_controls'] = true,
        ['autoplace_settings'] = {
            ['entity'] = {treat_missing_as_default = false},
            ['tile'] = {treat_missing_as_default = true},
            ['decorative'] = {treat_missing_as_default = true}
        }
    }

    if not this.active_surface_index then
        this.active_surface_index = game.create_surface('lumberjack', map_gen_settings).index
        this.active_surface = game.surfaces[this.active_surface_index]
    else
        game.forces.player.set_spawn_position({0, 25}, game.surfaces[this.active_surface_index])
        this.active_surface_index =
            Reset.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings, starting_items).index
        this.active_surface = game.surfaces[this.active_surface_index]
    end

    Poll.reset()
    ICW.reset()
    game.reset_time_played()
    WPT.reset_table()
    wave_defense_table.math = 8
    if not this.train_reveal and not this.reveal_normally then
        this.revealed_spawn = game.tick + 100
    end

    create_forces_and_disable_tech()

    local surface = game.surfaces[this.active_surface_index]

    surface.request_to_generate_chunks({0, 0}, 0.5)
    surface.force_generate_chunk_requests()

    local p = surface.find_non_colliding_position('character-corpse', {2, 21}, 2, 2)
    surface.create_entity({name = 'character-corpse', position = p})

    game.forces.player.set_spawn_position({0, 21}, surface)

    global.bad_fire_history = {}
    global.friendly_fire_history = {}
    global.landfill_history = {}
    global.mining_history = {}
    get_score.score_table = {}
    Diff.difficulty_poll_closing_timeout = game.tick + 90000
    Diff.difficulty_player_votes = {}

    game.difficulty_settings.technology_price_multiplier = 0.6

    Collapse.set_kill_entities(false)
    Collapse.set_speed(8)
    Collapse.set_amount(1)
    Collapse.set_max_line_size(Terrain.level_depth)
    Collapse.set_surface(surface)
    Collapse.set_position({0, 162})
    Collapse.set_direction('north')
    Collapse.start_now(false)

    surface.ticks_per_day = surface.ticks_per_day * 2
    surface.daytime = 0.71
    surface.brightness_visual_weights = {1, 0, 0, 0}
    surface.freeze_daytime = false
    surface.solar_power_multiplier = 1
    this.locomotive_health = 10000
    this.locomotive_max_health = 10000
    this.cargo_health = 10000
    this.cargo_max_health = 10000

    Locomotive(surface, {x = -18, y = 25})
    render_train_hp()
    render_direction(surface)
    RPG.rpg_reset_all_players()

    WD.reset_wave_defense()
    wave_defense_table.surface_index = this.active_surface_index
    wave_defense_table.target = this.locomotive_cargo
    wave_defense_table.nest_building_density = 32
    wave_defense_table.game_lost = false
    wave_defense_table.spawn_position = {x = 0, y = 100}
    wave_defense_table.next_wave = game.tick + 3600 * 25

    set_difficulty()

    local surfaces = {
        [surface.name] = shape
    }
    Generate.init({surfaces = surfaces, regen_decoratives = true, tiles_per_tick = 32})
    Task.reset_queue()
    Task.start_queue()
    Task.set_queue_speed(10)

    this.chunk_load_tick = game.tick + 500
end

local function on_load()
    local this = WPT.get_table()

    local surfaces = {
        [this.active_surface.name] = shape
    }
    Generate.init({surfaces = surfaces, regen_decoratives = true, tiles_per_tick = 32})
    Generate.register()
    Task.start_queue()
end

local function on_player_changed_position(event)
    local this = WPT.get_table()
    local player = game.players[event.player_index]
    local map_name = 'lumberjack'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local position = player.position
    local surface = game.surfaces[this.active_surface_index]
    if position.x >= Terrain.level_depth * 0.5 then
        return
    end
    if position.x < Terrain.level_depth * -0.5 then
        return
    end

    if
        not this.train_reveal and not this.reveal_normally or
            this.players[player.index].start_tick and game.tick - this.players[player.index].start_tick < 6400
     then
        if position.y < 5 then
            Terrain.reveal_player(player)
        end
    end
    if position.y >= 74 then
        player.teleport({position.x, position.y - 1}, surface)
        player.print(grandmaster .. ' Forcefield does not approve.', {r = 0.98, g = 0.66, b = 0.22})
        if player.character then
            player.character.health = player.character.health - 5
            player.character.surface.create_entity({name = 'water-splash', position = position})
            if player.character.health <= 0 then
                player.character.die('enemy')
            end
        end
    end
end

local function on_player_joined_game(event)
    local this = WPT.get_table()
    local surface = game.surfaces[this.active_surface_index]
    local player = game.players[event.player_index]

    set_difficulty(event)

    if not this.players then
        this.players = {}
    end

    if not this.players[player.index] then
        this.players[player.index] = {
            first_join = false,
            data = {}
        }
    end

    if not this.players[player.index].first_join then
        player.print(grandmaster .. ' Greetings, newly joined ' .. player.name .. '!', {r = 0.98, g = 0.66, b = 0.22})
        player.print(grandmaster .. ' Please read the map info.', {r = 0.98, g = 0.66, b = 0.22})
        this.players[player.index].first_join = true
    end

    if player.surface.index ~= this.active_surface_index then
        player.teleport(
            surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5),
            surface
        )
        for item, amount in pairs(starting_items) do
            player.insert({name = item, count = amount})
        end
    end
end

local function on_player_left_game()
    set_difficulty()
end

local function on_pre_player_left_game(event)
    local this = WPT.get_table()
    local player = game.players[event.player_index]
    if player.controller_type == defines.controllers.editor then
        player.toggle_map_editor()
    end
    if player.character then
        this.offline_players[#this.offline_players + 1] = {index = event.player_index, tick = game.tick}
    end
end

local function offline_players()
    local this = WPT.get_table()
    local players = this.offline_players
    local surface = game.surfaces[this.active_surface_index]
    if #players > 0 then
        local later = {}
        for i = 1, #players, 1 do
            if players[i] and game.players[players[i].index] and game.players[players[i].index].connected then
                players[i] = nil
            else
                if players[i] and players[i].tick < game.tick - 54000 then
                    local player_inv = {}
                    local items = {}
                    player_inv[1] = game.players[players[i].index].get_inventory(defines.inventory.character_main)
                    player_inv[2] = game.players[players[i].index].get_inventory(defines.inventory.character_armor)
                    player_inv[3] = game.players[players[i].index].get_inventory(defines.inventory.character_guns)
                    player_inv[4] = game.players[players[i].index].get_inventory(defines.inventory.character_ammo)
                    player_inv[5] = game.players[players[i].index].get_inventory(defines.inventory.character_trash)
                    local e =
                        surface.create_entity(
                        {
                            name = 'character',
                            position = game.forces.player.get_spawn_position(surface),
                            force = 'neutral'
                        }
                    )
                    local inv = e.get_inventory(defines.inventory.character_main)
                    for ii = 1, 5, 1 do
                        if player_inv[ii].valid then
                            for iii = 1, #player_inv[ii], 1 do
                                if player_inv[ii][iii].valid then
                                    items[#items + 1] = player_inv[ii][iii]
                                end
                            end
                        end
                    end
                    if #items > 0 then
                        for item = 1, #items, 1 do
                            if items[item].valid then
                                inv.insert(items[item])
                            end
                        end
                        game.print({'chronosphere.message_accident'}, {r = 0.98, g = 0.66, b = 0.22})
                        e.die('neutral')
                    else
                        e.destroy()
                    end

                    for ii = 1, 5, 1 do
                        if player_inv[ii].valid then
                            player_inv[ii].clear()
                        end
                    end
                    players[i] = nil
                else
                    later[#later + 1] = players[i]
                end
            end
        end
        players = {}
        if #later > 0 then
            for i = 1, #later, 1 do
                players[#players + 1] = later[i]
            end
        end
    end
end

local function disable_recipes()
    local force = game.forces.player
    force.recipes['cargo-wagon'].enabled = false
    force.recipes['fluid-wagon'].enabled = false
    force.recipes['artillery-wagon'].enabled = false
    force.recipes['locomotive'].enabled = false
    force.recipes['pistol'].enabled = false
end

local function on_research_finished(event)
    disable_recipes()
    event.research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 50 -- +5 Slots / level
    local mining_speed_bonus = game.forces.player.mining_drill_productivity_bonus * 5 -- +50% speed / level
    if event.research.force.technologies['steel-axe'].researched then
        mining_speed_bonus = mining_speed_bonus + 0.5
    end -- +50% speed for steel-axe research
    event.research.force.manual_mining_speed_modifier = mining_speed_bonus
end

local function darkness(data)
    local rnd = math.random
    local this = data.this
    local surface = data.surface
    if rnd(1, 24) == 1 then
        if not this.freeze_daytime then
            return
        end
        game.print(grandmaster .. ' Sunlight, finally!', {r = 0.98, g = 0.66, b = 0.22})
        surface.min_brightness = 1
        surface.brightness_visual_weights = {1, 0, 0, 0}
        surface.daytime = 1
        surface.freeze_daytime = false
        surface.solar_power_multiplier = 1
        this.freeze_daytime = false
        return
    elseif rnd(1, 64) == 1 then
        if this.freeze_daytime then
            return
        end
        game.print(grandmaster .. ' Darkness has surrounded us!', {r = 0.98, g = 0.66, b = 0.22})
        game.print(grandmaster .. ' Builds some lamps!', {r = 0.98, g = 0.66, b = 0.22})
        surface.min_brightness = 0
        surface.brightness_visual_weights = {0.90, 0.90, 0.90}
        surface.daytime = 0.42
        surface.freeze_daytime = true
        surface.solar_power_multiplier = 0
        this.freeze_daytime = true
        return
    end
end

local function transfer_pollution(data)
    local Diff = Difficulty.get()
    local surface = data.loco_surface
    local this = data.this
    if not surface then
        return
    end
    local pollution = surface.get_total_pollution() * (3 / (4 / 3 + 1)) * Diff.difficulty_vote_value
    game.surfaces[this.active_surface_index].pollute(this.locomotive.position, pollution)
    surface.clear_pollution()
end

local tick_minute_functions = {
    [300 * 3 + 30 * 6] = darkness,
    [300 * 3 + 30 * 6] = transfer_pollution
}

local on_tick = function()
    local this = WPT.get_table()
    local surface = game.surfaces[this.active_surface_index]
    local wave_defense_table = WD.get_table()
    local tick = game.tick
    local status = Collapse.start_now()
    local key = tick % 3600
    local unit_surface = this.locomotive.unit_number
    local icw_table = ICW.get_table()
    if not this.locomotive.valid then
        Entities.loco_died()
    end
    local data = {
        this = this,
        surface = surface,
        loco_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]
    }

    if status == true then
        goto continue
    end
    if
        this.left_top.y % Terrain.level_depth == 0 and this.left_top.y < 0 and
            this.left_top.y > Terrain.level_depth * -10
     then
        if not Collapse.start_now() then
            Collapse.start_now(true)
        end
    end
    ::continue::
    if game.tick % 30 == 0 then
        for _, player in pairs(game.connected_players) do
            update_gui(player)
        end

        if game.tick % 1800 == 0 then
            local position = surface.find_non_colliding_position('stone-furnace', Collapse.get_position(), 128, 1)
            if position then
                wave_defense_table.spawn_position = position
            end
            offline_players()
            Entities.set_scores()
        end
    end
    if tick_minute_functions[key] then
        tick_minute_functions[key](data)
    end

    if this.game_reset_tick then
        if this.game_reset_tick < game.tick then
            if not this.disable_reset then
                this.game_reset_tick = nil
                Public.reset_map()
            else
                if not this.reset_the_game then
                    game.print('Auto reset is disabled. Server is shutting down!', {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Auto reset is disabled. Server is shutting down!'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.stop_scenario()
                    this.reset_the_game = true
                end
            end
        end
        return
    end

    if this.chunk_load_tick then
        if this.chunk_load_tick < game.tick then
            this.chunk_load_tick = nil
            Task.set_queue_speed(1)
        end
    end
end

local on_init = function()
    local this = WPT.get_table()
    Public.reset_map()

    local tooltip = {
        [1] = 'something',
        [2] = 'something else',
        [3] = 'something else else',
        [4] = 'something else else else',
        [5] = 'something else else else else',
        [6] = 'something else else else else else',
        [7] = 'something else else else else else else'
    }

    Difficulty:set_tooltip(tooltip)

    global.custom_highscore.description = 'Wagon distance reached:'

    this.rocks_yield_ore_maximum_amount = 500
    this.type_modifier = 1
    this.rocks_yield_ore_base_amount = 50
    this.rocks_yield_ore_distance_modifier = 0.025

    local T = Map.Pop_info()
    T.main_caption = 'L u m b e r  j a c k  '
    T.sub_caption = 'Chop the wood, toss the wood, save the train, die again!'
    T.text =
        table.concat(
        {
            'Welcome lumberlover!\n',
            '\n',
            'The biters have catched the scent of fish in the cargo wagon.\n',
            'Guide the choo and protect it for as long as possible!\n',
            'This will not be an easy task however,\n',
            'since their strength and numbers increase over time.\n',
            '\n',
            'Delve deep for greater treasures, but also face increased dangers.\n',
            'Mining productivity research, will overhaul your mining equipment,\n',
            'reinforcing your pickaxe as well as increasing the size of your backpack.\n',
            '\n',
            "We've also noticed that solar eclipse occuring, \n",
            'we have yet to solve this mystery\n',
            '\n',
            'Good luck, over and out!'
        }
    )
    T.main_caption_color = {r = 150, g = 150, b = 0}
    T.sub_caption_color = {r = 0, g = 150, b = 0}

    local mgs = game.surfaces['nauvis'].map_gen_settings
    mgs.width = 16
    mgs.height = 16
    game.surfaces['nauvis'].map_gen_settings = mgs
    game.surfaces['nauvis'].clear()

    Explosives.set_destructible_tile('out-of-map', 1500)
    Explosives.set_destructible_tile('water', 1000)
    Explosives.set_destructible_tile('water-green', 1000)
    Explosives.set_destructible_tile('deepwater-green', 1000)
    Explosives.set_destructible_tile('deepwater', 1000)
    Explosives.set_destructible_tile('water-shallow', 1000)

    Generate.register()
end

Event.on_nth_tick(10, on_tick)
Event.on_init(on_init)
Event.on_load(on_load)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)

return Public
