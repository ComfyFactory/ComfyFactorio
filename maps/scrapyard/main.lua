-- modules
require 'maps.scrapyard.player_list'
require 'maps.scrapyard.comfylatron'
require 'maps.scrapyard.commands'
require 'maps.scrapyard.corpse_util'

require 'on_tick_schedule'
require 'modules.dynamic_landfill'
require 'modules.difficulty_vote'
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

local Explosives = require 'modules.explosives'
local Color = require 'utils.color_presets'
local Entities = require 'maps.scrapyard.entities'
local update_gui = require 'maps.scrapyard.gui'
local ICW = require 'maps.scrapyard.icw.main'
local WD = require 'modules.wave_defense.table'
local Map = require 'modules.map_info'
local RPG = require 'maps.scrapyard.rpg'
local Reset = require 'functions.soft_reset'
local Terrain = require 'maps.scrapyard.terrain'
local Event = require 'utils.event'
local Scrap_table = require 'maps.scrapyard.table'
local Locomotive = require 'maps.scrapyard.locomotive'.locomotive_spawn
local render_train_hp = require 'maps.scrapyard.locomotive'.render_train_hp
local Score = require 'comfy_panel.score'
local Poll = require 'comfy_panel.poll'
local Collapse = require 'modules.collapse'
local Balance = require 'maps.scrapyard.balance'

local Public = {}
local math_random = math.random
local math_floor = math.floor

Scrap_table.init({train_reveal = true, energy_shared = true})

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['wood'] = 4, ['rail'] = 16, ['raw-fish'] = 2}
local colors = {
    'green-refined-concrete',
    'red-refined-concrete',
    'blue-refined-concrete'
}
local disabled_tiles = {
    ['water-shallow'] = true,
    ['deepwater-green'] = true,
    ['out-of-map'] = true,
    ['green-refined-concrete'] = true,
    ['red-refined-concrete'] = true,
    ['blue-refined-concrete'] = true
}

local grandmaster = '[color=blue]Grandmaster:[/color]'

local function create_forces_and_disable_tech()
    game.create_force('scrap')
    game.create_force('scrap_defense')
    game.forces.player.set_friend('scrap', true)
    game.forces.enemy.set_friend('scrap', true)
    game.forces.scrap.set_friend('player', true)
    game.forces.scrap.set_friend('enemy', true)
    game.forces.scrap.share_chart = false
    game.forces.player.technologies['landfill'].enabled = false
    game.forces.player.technologies['optics'].researched = true
    game.forces.player.recipes['cargo-wagon'].enabled = false
    game.forces.player.recipes['fluid-wagon'].enabled = false
    game.forces.player.recipes['artillery-wagon'].enabled = false
    game.forces.player.recipes['locomotive'].enabled = false
    game.forces.player.recipes['pistol'].enabled = false
    game.forces.player.technologies['land-mine'].enabled = false
end

local function set_difficulty()
    local wave_defense_table = WD.get_table()
    local player_count = #game.connected_players

    wave_defense_table.max_active_biters = 1024

    -- threat gain / wave
    wave_defense_table.threat_gain_multiplier = 2 + player_count * 0.1

    local amount = player_count * 0.25 + 2
    amount = math.floor(amount)
    if amount > 8 then
        amount = 8
    end
    Collapse.set_amount(amount)

    --20 Players for fastest wave_interval
    wave_defense_table.wave_interval = 3600 - player_count * 90
    if wave_defense_table.wave_interval < 2000 then
        wave_defense_table.wave_interval = 2000
    end
end

function Public.reset_map()
    local this = Scrap_table.get_table()
    local wave_defense_table = WD.get_table()
    local get_score = Score.get_table()
    Poll.reset()
    ICW.reset()
    game.reset_time_played()
    Scrap_table.reset_table()
    wave_defense_table.math = 8
    if not this.train_reveal then
        this.revealed_spawn = game.tick + 100
    end

    local map_gen_settings = {
        ['seed'] = math_random(1, 1000000),
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
        this.active_surface_index = game.create_surface('scrapyard', map_gen_settings).index
    else
        game.forces.player.set_spawn_position({0, 25}, game.surfaces[this.active_surface_index])
        this.active_surface_index =
            Reset.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings, starting_items).index
        this.active_surface = game.surfaces[this.active_surface_index]
    end

    local surface = game.surfaces[this.active_surface_index]

    surface.request_to_generate_chunks({0, 0}, 0.5)
    surface.force_generate_chunk_requests()

    local p = surface.find_non_colliding_position('character-corpse', {2, 21}, 2, 2)
    surface.create_entity({name = 'character-corpse', position = p})

    game.forces.player.set_spawn_position({0, 21}, surface)

    global.friendly_fire_history = {}
    global.landfill_history = {}
    global.mining_history = {}
    get_score.score_table = {}
    global.difficulty_poll_closing_timeout = game.tick + 90000
    global.difficulty_player_votes = {}

    game.difficulty_settings.technology_price_multiplier = 0.6

    Collapse.set_kill_entities(false)
    Collapse.set_speed(8)
    Collapse.set_amount(1)
    Collapse.set_max_line_size(Terrain.level_depth)
    Collapse.set_surface(surface)
    Collapse.set_position({0, 290})
    Collapse.set_direction('north')
    Collapse.start_now(false)

    surface.ticks_per_day = surface.ticks_per_day * 2
    surface.daytime = 1
    surface.brightness_visual_weights = {1, 0, 0, 0}
    surface.freeze_daytime = true
    surface.solar_power_multiplier = 1
    this.locomotive_health = 10000
    this.locomotive_max_health = 10000
    this.cargo_health = 10000
    this.cargo_max_health = 10000

    Locomotive(surface, {x = -18, y = 25})
    render_train_hp()

    WD.reset_wave_defense()
    wave_defense_table.surface_index = this.active_surface_index
    wave_defense_table.target = this.locomotive_cargo
    wave_defense_table.nest_building_density = 32
    wave_defense_table.game_lost = false
    wave_defense_table.spawn_position = {x = 0, y = 220}

    surface.create_entity({name = 'electric-beam', position = {-196, 190}, source = {-196, 190}, target = {196, 190}})
    surface.create_entity({name = 'electric-beam', position = {-196, 190}, source = {-196, 190}, target = {196, 190}})

    RPG.rpg_reset_all_players()

    if game.forces.scrap_defense then
        Balance.init_enemy_weapon_damage()
    else
        log('scrap_defense not found')
    end

    set_difficulty()

    rendering.draw_text {
        text = 'Welcome to Scrapyard!',
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
        text = '▼',
        surface = surface,
        target = {-0, 70},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 80},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 90},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 100},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 110},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = 'Biters will attack this area.',
        surface = surface,
        target = {-0, 120},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
end

local function change_tile(surface, pos, steps)
    return surface.set_tiles {{name = colors[math_floor(steps * 0.5) % 3 + 1], position = {x = pos.x, y = pos.y}}}
end

local function on_player_changed_position(event)
    local this = Scrap_table.get_table()
    local player = game.players[event.player_index]
    if string.sub(player.surface.name, 0, 9) ~= 'scrapyard' then
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
    if position.y < 5 then
        if not this.players[player.index].tiles_enabled then
            goto continue
        end

        local steps = this.players[player.index].steps
        local tile = surface.get_tile(position).name
        local disabled = disabled_tiles[tile]
        if disabled then
            goto continue
        end
        change_tile(surface, position, steps)
        if this.players[player.index].steps > 5000 then
            this.players[player.index].steps = 0
        end
        this.players[player.index].steps = this.players[player.index].steps + 1
    end
    ::continue::
    if not this.train_reveal or this.players[player.index].reveal - game.tick > 0 then
        if position.y < 5 then
            Terrain.reveal(player)
        end
    end
    if position.y >= 190 then
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
    local this = Scrap_table.get_table()
    local surface = game.surfaces[this.active_surface_index]
    local player = game.players[event.player_index]

    set_difficulty(event)

    if not this.players then
        this.players = {}
    end

    if not this.players[player.index] then
        this.players[player.index] = {
            tiles_enabled = true,
            steps = 0,
            first_join = false,
            reveal = 0,
            data = {}
        }
    end

    if not this.players[player.index].first_join then
        player.print(grandmaster .. ' Greetings, newly joined ' .. player.name .. '!', {r = 1, g = 0.5, b = 0.1})
        player.print(grandmaster .. ' Please read the map info.', {r = 1, g = 0.5, b = 0.1})
        player.print(grandmaster .. ' Guide the choo through the black mist.', {r = 1, g = 0.5, b = 0.1})
        player.print(grandmaster .. ' To disable rainbow mode, type in console: /rainbow_mode', Color.info)
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
    local this = Scrap_table.get_table()
    local player = game.players[event.player_index]
    if player.controller_type == defines.controllers.editor then
        player.toggle_map_editor()
    end
    if player.character then
        this.offline_players[#this.offline_players + 1] = {index = event.player_index, tick = game.tick}
    end
end

local function offline_players()
    local this = Scrap_table.get_table()
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

local function on_research_finished(event)
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
    if rnd(1, 32) == 1 then
        if not this.freeze_daytime then
            return
        end
        game.print(grandmaster .. ' Sunlight, finally!', {r = 1, g = 0.5, b = 0.1})
        surface.min_brightness = 1
        surface.brightness_visual_weights = {1, 0, 0, 0}
        surface.daytime = 1
        surface.freeze_daytime = true
        surface.solar_power_multiplier = 1
        this.freeze_daytime = false
        return
    elseif rnd(1, 64) == 1 then
        if this.freeze_daytime then
            return
        end
        game.print(grandmaster .. ' Darkness has surrounded us!', {r = 1, g = 0.5, b = 0.1})
        game.print(grandmaster .. ' Builds some lamps!', {r = 1, g = 0.5, b = 0.1})
        surface.min_brightness = 0
        surface.brightness_visual_weights = {0.90, 0.90, 0.90}
        surface.daytime = 0.42
        surface.freeze_daytime = true
        surface.solar_power_multiplier = 0
        this.freeze_daytime = true
        return
    end
end

local function scrap_randomness(data)
    local this = data.this
    local rnd = math.random
    if rnd(1, 32) == 1 then
        if this.scrap_enabled then
            return
        end
        this.scrap_enabled = true
        game.print(grandmaster .. ' Scrap is back!', {r = 1, g = 0.5, b = 0.1})
        game.print(grandmaster .. ' Output from scrap is now randomized.', {r = 1, g = 0.5, b = 0.1})
        return
    elseif rnd(1, 64) == 1 then
        if not this.scrap_enabled then
            return
        end
        this.scrap_enabled = false
        game.print(grandmaster .. ' It seems that the scrap is temporarily gone.', {r = 1, g = 0.5, b = 0.1})
        game.print(grandmaster .. ' Output from scrap is now only ores.', {r = 1, g = 0.5, b = 0.1})
        return
    end
end

local function transfer_pollution(data)
    local surface = data.surface
    local this = data.this
    if not surface then
        return
    end
    local pollution = surface.get_total_pollution() * (3 / (4 / 3 + 1)) * global.difficulty_vote_value
    game.surfaces[this.active_surface_index].pollute(this.locomotive.position, pollution)
    surface.clear_pollution()
end

local tick_minute_functions = {
    [300 * 2 + 30 * 2] = scrap_randomness,
    [300 * 3 + 30 * 1] = darkness,
    [300 * 3 + 30 * 0] = transfer_pollution
}

local on_tick = function()
    local this = Scrap_table.get_table()
    local surface = game.surfaces[this.active_surface_index]
    local wave_defense_table = WD.get_table()
    local tick = game.tick
    local status = Collapse.start_now()
    local key = tick % 3600
    local data = {
        this = this,
        surface = surface
    }
    if not this.locomotive.valid then
        Entities.loco_died()
    end
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
            this.game_reset_tick = nil
            Public.reset_map()
        end
        return
    end
end

local on_init = function()
    global.custom_highscore.description = 'Depth reached: '
    create_forces_and_disable_tech()

    game.forces.scrap.share_chart = false
    global.rocks_yield_ore_maximum_amount = 500
    global.rocks_yield_ore_base_amount = 50
    global.rocks_yield_ore_distance_modifier = 0.025
    Public.reset_map()
    local T = Map.Pop_info()
    T.main_caption = 'R a i n b o w   S c r a p y a r d'
    T.sub_caption = '    ---defend the choo---'
    T.text =
        table.concat(
        {
            'The biters have catched the scent of fish in the cargo wagon.\n',
            'Guide the choo through the black mist and protect it for as long as possible!\n',
            'This will not be an easy task however,\n',
            'since their strength and numbers increase over time.\n',
            '\n',
            'Delve deep for greater treasures, but also face increased dangers.\n',
            'Mining productivity research, will overhaul your mining equipment,\n',
            'reinforcing your pickaxe as well as increasing the size of your backpack.\n',
            '\n',
            'Scrap randomness seems to occur frequently, sometimes mining scrap\n',
            'does not output scrap, weird...\n',
            '\n',
            "We've also noticed that solar eclipse occuring, \n",
            'we have yet to solve this mystery\n',
            '\n',
            'Good luck, over and out!',
            '\n',
            '\n',
            '\n'
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
end

Event.on_nth_tick(10, on_tick)
Event.on_init(on_init)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)

return Public
