require 'maps.mountain_fortress_v3.generate'
require 'maps.mountain_fortress_v3.commands'
require 'maps.mountain_fortress_v3.breached_wall'
require 'maps.mountain_fortress_v3.ic.main'
require 'maps.mountain_fortress_v3.biters_yield_coins'

require 'modules.rpg.main'
require 'modules.shotgun_buff'
require 'modules.no_deconstruction_of_neutral_entities'
require 'modules.rocks_yield_ore_veins'
require 'modules.spawners_contain_biters'
require 'modules.wave_defense.main'
require 'modules.charging_station'

local BuriedEnemies = require 'maps.mountain_fortress_v3.buried_enemies'
local math2d = require 'math2d'
-- local HS = require 'maps.mountain_fortress_v3.highscore'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local Autostash = require 'modules.autostash'
local Group = require 'comfy_panel.group'
local PL = require 'comfy_panel.player_list'
local CS = require 'maps.mountain_fortress_v3.surface'
local Server = require 'utils.server'
local Explosives = require 'modules.explosives'
local Balance = require 'maps.mountain_fortress_v3.balance'
local Entities = require 'maps.mountain_fortress_v3.entities'
local Gui_mf = require 'maps.mountain_fortress_v3.gui'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local ICW_Func = require 'maps.mountain_fortress_v3.icw.functions'
local WD = require 'modules.wave_defense.table'
local Map = require 'modules.map_info'
local RPG_Settings = require 'modules.rpg.table'
local RPG_Func = require 'modules.rpg.functions'
local Terrain = require 'maps.mountain_fortress_v3.terrain'
local Functions = require 'maps.mountain_fortress_v3.functions'
local Event = require 'utils.event'
local WPT = require 'maps.mountain_fortress_v3.table'
local Locomotive = require 'maps.mountain_fortress_v3.locomotive'
local Score = require 'comfy_panel.score'
local Poll = require 'comfy_panel.poll'
local Collapse = require 'modules.collapse'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Alert = require 'utils.alert'
local AntiGrief = require 'antigrief'

local Public = {}
local floor = math.floor
local random = math.random
local remove = table.remove
local tile_damage = 50

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['rail'] = 16, ['wood'] = 16, ['explosives'] = 32}

local collapse_kill = {
    entities = {
        ['laser-turret'] = true,
        ['flamethrower-turret'] = true,
        ['gun-turret'] = true,
        ['artillery-turret'] = true,
        ['landmine'] = true,
        ['locomotive'] = true,
        ['cargo-wagon'] = true,
        ['character'] = true,
        ['car'] = true,
        ['tank'] = true,
        ['assembling-machine'] = true,
        ['furnace'] = true,
        ['steel-chest'] = true
    },
    enabled = true
}

local function debug_str(msg)
    local debug = WPT.get('debug')
    if not debug then
        return
    end
    print('Mtn: ' .. msg)
end

local function get_player_data(player, remove_user_data)
    local players = WPT.get('players')
    if remove_user_data then
        if players[player.index] then
            players[player.index] = nil
        end
    end
    if not players[player.index] then
        players[player.index] = {}
    end
    return players[player.index]
end

local disable_recipes = function()
    local force = game.forces.player
    force.recipes['cargo-wagon'].enabled = false
    force.recipes['fluid-wagon'].enabled = false
    force.recipes['car'].enabled = false
    force.recipes['tank'].enabled = false
    force.recipes['artillery-wagon'].enabled = false
    force.recipes['locomotive'].enabled = false
    force.recipes['pistol'].enabled = false
end

local show_text = function(msg, pos, color, surface)
    if color == nil then
        surface.create_entity({name = 'flying-text', position = pos, text = msg})
    else
        surface.create_entity({name = 'flying-text', position = pos, text = msg, color = color})
    end
end

local init_new_force = function()
    local new_force = game.forces.protectors
    local enemy = game.forces.enemy
    if not new_force then
        new_force = game.create_force('protectors')
    end
    new_force.set_friend('enemy', true)
    enemy.set_friend('protectors', true)
end

local disable_tech = function()
    game.forces.player.technologies['landfill'].enabled = false
    game.forces.player.technologies['spidertron'].enabled = false
    game.forces.player.technologies['spidertron'].researched = false
    game.forces.player.technologies['optics'].researched = true
    game.forces.player.technologies['railway'].researched = true
    game.forces.player.technologies['land-mine'].enabled = false
    disable_recipes()
end

local is_position_near_tbl = function(position, tbl)
    local status = false
    local function inside(pos)
        return pos.x >= position.x and pos.y >= position.y and pos.x <= position.x and pos.y <= position.y
    end

    for i = 1, #tbl do
        if inside(tbl[i]) then
            status = true
        end
    end

    return status
end

local set_difficulty = function()
    local Diff = Difficulty.get()
    local wave_defense_table = WD.get_table()
    local collapse_amount = WPT.get('collapse_amount')
    local player_count = #game.connected_players
    if not Diff.difficulty_vote_value then
        Diff.difficulty_vote_value = 0.1
    end

    wave_defense_table.max_active_biters = 888 + player_count * (90 * Diff.difficulty_vote_value)

    if wave_defense_table.max_active_biters >= 1600 then
        wave_defense_table.max_active_biters = 1600
    end

    -- threat gain / wave
    wave_defense_table.threat_gain_multiplier = 1.2 + player_count * Diff.difficulty_vote_value * 0.1

    local amount = player_count * 0.05
    amount = floor(amount)
    if amount <= 0 then
        amount = 1
    end
    if amount > 3 then
        amount = 3
    end

    local difficulty = Difficulty.get()
    local name = difficulty.difficulties[difficulty.difficulty_vote_index].name

    if name ~= 'Nightmare' then
        local zone = WPT.get('breached_wall')
        if zone >= 5 then
            WPT.set().coin_amount = random(1, 2)
        elseif zone >= 10 then
            WPT.set().coin_amount = random(1, 3)
        end
    end

    if wave_defense_table.threat <= 0 then
        wave_defense_table.wave_interval = 1000
    end
    if name == 'Nightmare' then
        wave_defense_table.wave_interval = 1800
    else
        wave_defense_table.wave_interval = 3600 - player_count * 60
        if wave_defense_table.wave_interval < 1800 then
            wave_defense_table.wave_interval = 1800
        end
    end

    local gap_between_zones = WPT.get('gap_between_zones')
    if gap_between_zones.set then
        return
    end

    if name == 'Nightmare' then
        Collapse.set_amount(10)
    elseif collapse_amount then
        Collapse.set_amount(collapse_amount)
    else
        Collapse.set_amount(amount)
    end

    Collapse.set_speed(1)
end

local render_direction = function(surface)
    local counter = WPT.get('soft_reset_counter')
    if counter then
        rendering.draw_text {
            text = 'Welcome to Mountain Fortress v3!\nRun: ' .. counter,
            surface = surface,
            target = {-0, 10},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    else
        rendering.draw_text {
            text = 'Welcome to Mountain Fortress v3!',
            surface = surface,
            target = {-0, 10},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    end

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

    local x_min = -Terrain.level_width / 2
    local x_max = Terrain.level_width / 2

    surface.create_entity({name = 'electric-beam', position = {x_min, 74}, source = {x_min, 74}, target = {x_max, 74}})
    surface.create_entity({name = 'electric-beam', position = {x_min, 74}, source = {x_min, 74}, target = {x_max, 74}})
end

function Public.reset_map()
    local Diff = Difficulty.get()
    local this = WPT.get()
    local wave_defense_table = WD.get_table()

    this.active_surface_index = CS.create_surface()

    Autostash.insert_into_furnace(true)
    Autostash.insert_into_wagon(true)
    BuriedEnemies.reset()

    Poll.reset()
    ICW.reset()
    IC.reset()
    IC.allowed_surface('mountain_fortress_v3')
    Functions.reset_table()
    game.reset_time_played()
    WPT.reset_table()

    RPG_Func.rpg_reset_all_players()
    RPG_Settings.set_surface_name('mountain_fortress_v3')
    RPG_Settings.enable_health_and_mana_bars(true)
    RPG_Settings.enable_wave_defense(true)
    RPG_Settings.enable_mana(true)
    RPG_Settings.enable_flame_boots(true)
    RPG_Settings.personal_tax_rate(0.3)
    RPG_Settings.enable_stone_path(true)
    RPG_Settings.enable_one_punch(true)
    RPG_Settings.enable_one_punch_globally(false)
    RPG_Settings.enable_auto_allocate(true)
    RPG_Settings.disable_cooldowns_on_spells()

    Group.reset_groups()
    Group.alphanumeric_only(false)

    disable_tech()
    init_new_force()

    local surface = game.surfaces[this.active_surface_index]

    Explosives.set_surface_whitelist({[surface.name] = true})

    game.forces.player.set_spawn_position({-27, 25}, surface)
    game.forces.player.manual_mining_speed_modifier = 0

    Balance.init_enemy_weapon_damage()

    AntiGrief.log_tree_harvest(true)
    AntiGrief.whitelist_types('tree', true)
    AntiGrief.enable_capsule_warning(false)
    AntiGrief.enable_capsule_cursor_warning(false)
    AntiGrief.enable_jail(true)
    AntiGrief.damage_entity_threshold(20)
    AntiGrief.explosive_threshold(32)

    PL.show_roles_in_list(true)

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Score.init_player_table(player)
    end

    Difficulty.reset_difficulty_poll({difficulty_poll_closing_timeout = game.tick + 36000})
    Diff.gui_width = 20

    Collapse.set_kill_entities(false)
    Collapse.set_kill_specific_entities(collapse_kill)
    Collapse.set_speed(8)
    Collapse.set_amount(1)
    Collapse.set_max_line_size(Terrain.level_width)
    Collapse.set_surface(surface)
    Collapse.set_position({0, 130})
    Collapse.set_direction('north')
    Collapse.start_now(false)

    this.locomotive_health = 10000
    this.locomotive_max_health = 10000

    Locomotive.locomotive_spawn(surface, {x = -18, y = 25})
    Locomotive.render_train_hp()
    render_direction(surface)

    WD.reset_wave_defense()
    wave_defense_table.surface_index = this.active_surface_index
    wave_defense_table.target = this.locomotive
    wave_defense_table.nest_building_density = 32
    wave_defense_table.game_lost = false
    wave_defense_table.spawn_position = {x = 0, y = 100}
    WD.alert_boss_wave(true)
    WD.clear_corpses(false)
    WD.remove_entities(true)
    WD.enable_threat_log(true)
    WD.check_collapse_position(true)
    WD.set_disable_threat_below_zero(true)

    set_difficulty()

    if not surface.is_chunk_generated({-20, 22}) then
        surface.request_to_generate_chunks({-20, 22}, 0.1)
        surface.force_generate_chunk_requests()
    end

    game.forces.player.set_spawn_position({-27, 25}, surface)

    Task.start_queue()
    Task.set_queue_speed(16)

    this.chunk_load_tick = game.tick + 1200
    this.game_lost = false
end

local on_player_changed_position = function(event)
    local active_surface_index = WPT.get('active_surface_index')
    if not active_surface_index then
        return
    end
    local player = game.players[event.player_index]
    local map_name = 'mountain_fortress_v3'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local position = player.position
    local surface = game.surfaces[active_surface_index]

    local p = {x = player.position.x, y = player.position.y}
    local get_tile = surface.get_tile(p)
    local config_tile = WPT.get('void_or_tile')
    if config_tile == 'lab-dark-2' then
        if get_tile.valid and get_tile.name == 'lab-dark-2' then
            if random(1, 2) == 1 then
                if random(1, 2) == 1 then
                    show_text('This path is not for players!', p, {r = 0.98, g = 0.66, b = 0.22}, surface)
                end
                player.surface.create_entity({name = 'fire-flame', position = player.position})
                player.character.health = player.character.health - tile_damage
                if player.character.health == 0 then
                    player.character.die()
                    local message = ({'main.death_message_' .. random(1, 7), player.name})
                    game.print(message, {r = 0.98, g = 0.66, b = 0.22})
                end
            end
        end
    end

    if position.y >= 74 then
        player.teleport({position.x, position.y - 1}, surface)
        player.print(({'main.forcefield'}), {r = 0.98, g = 0.66, b = 0.22})
        if player.character then
            player.character.health = player.character.health - 5
            player.character.surface.create_entity({name = 'water-splash', position = position})
            if player.character.health <= 0 then
                player.character.die('enemy')
            end
        end
    end
end

local on_player_joined_game = function(event)
    local active_surface_index = WPT.get('active_surface_index')
    local player = game.players[event.player_index]
    local surface = game.surfaces[active_surface_index]

    set_difficulty()

    ICW_Func.is_minimap_valid(player, surface)

    local player_data = get_player_data(player)

    if not player_data.first_join then
        local message = ({'main.greeting', player.name})
        Alert.alert_player(player, 15, message)
        for item, amount in pairs(starting_items) do
            player.insert({name = item, count = amount})
        end
        player_data.first_join = true
    end

    if player.surface.index ~= active_surface_index then
        player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5), surface)
    else
        local p = {x = player.position.x, y = player.position.y}
        local get_tile = surface.get_tile(p)
        if get_tile.valid and get_tile.name == 'out-of-map' then
            player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5), surface)
        end
    end

    local locomotive = WPT.get('locomotive')

    if not locomotive or not locomotive.valid then
        return
    end
    if player.position.y > locomotive.position.y then
        player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5), surface)
    end
end

local on_player_left_game = function()
    set_difficulty()
end

local on_player_respawned = function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    local player_data = get_player_data(player)
    if player_data.died then
        player_data.died = nil
    end
end

local on_player_died = function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    local player_data = get_player_data(player)
    player_data.died = true
end

local on_research_finished = function(event)
    disable_tech()
    local research = event.research

    research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 50 -- +5 Slots /

    if research.name == 'steel-axe' then
        local msg = 'Steel-axe technology has been researched, 100% has been applied.\nBuy Pickaxe-upgrades in the market to boost it even more!'
        Alert.alert_all_players(30, msg, nil, 'achievement/tech-maniac', 0.6)
    end -- +50% speed for steel-axe research

    local force_name = research.force.name
    if not force_name then
        return
    end
    local flamethrower_damage = WPT.get('flamethrower_damage')
    flamethrower_damage[force_name] = -0.85
    if research.name == 'military' then
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', flamethrower_damage[force_name])
    end

    if string.sub(research.name, 0, 18) == 'refined-flammables' then
        flamethrower_damage[force_name] = flamethrower_damage[force_name] + 0.10
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', flamethrower_damage[force_name])
    end
end

local is_locomotive_valid = function()
    local locomotive = WPT.get('locomotive')
    if not locomotive.valid then
        Entities.loco_died()
    end
end

local is_player_valid = function()
    local players = game.connected_players
    for _, player in pairs(players) do
        if player.connected and not player.character or not player.character.valid then
            if not player.admin then
                local player_data = get_player_data(player)
                if player_data.died then
                    return
                end
                player.set_controller {type = defines.controllers.god}
                player.create_character()
            end
        end
    end
end

local has_the_game_ended = function()
    local game_reset_tick = WPT.get('game_reset_tick')
    if game_reset_tick then
        if game_reset_tick < 0 then
            return
        end

        local this = WPT.get()

        this.game_reset_tick = this.game_reset_tick - 30
        if this.game_reset_tick % 1800 == 0 then
            if this.game_reset_tick > 0 then
                local cause_msg
                if this.restart then
                    cause_msg = 'restart'
                elseif this.shutdown then
                    cause_msg = 'shutdown'
                elseif this.soft_reset then
                    cause_msg = 'soft-reset'
                end

                game.print(({'main.reset_in', cause_msg, this.game_reset_tick / 60}), {r = 0.22, g = 0.88, b = 0.22})
            end
            if this.soft_reset and this.game_reset_tick == 0 then
                this.game_reset_tick = nil
                Public.reset_map()
                return
            end
            if this.restart and this.game_reset_tick == 0 then
                if not this.announced_message then
                    game.print(({'entity.notify_restart'}), {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Soft-reset is disabled! Server will restart from scenario to load new changes.'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.start_scenario('Mountain_Fortress_v3')
                    this.announced_message = true
                    return
                end
            end
            if this.shutdown and this.game_reset_tick == 0 then
                if not this.announced_message then
                    game.print(({'entity.notify_shutdown'}), {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Soft-reset is disabled! Server will shutdown. Most likely because of updates.'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.stop_scenario()
                    this.announced_message = true
                    return
                end
            end
        end
    end
end

local boost_difficulty = function()
    local difficulty_set = WPT.get('difficulty_set')
    if difficulty_set then
        return
    end

    local breached_wall = WPT.get('breached_wall')

    local difficulty = Difficulty.get()
    local name = difficulty.difficulties[difficulty.difficulty_vote_index].name

    if game.tick < difficulty.difficulty_poll_closing_timeout and breached_wall <= 1 then
        return
    end

    Difficulty.get().name = name
    Difficulty.get().difficulty_poll_closing_timeout = game.tick

    Difficulty.get().button_tooltip = difficulty.tooltip[difficulty.difficulty_vote_index]
    Difficulty.difficulty_gui()

    local message = ({'main.diff_set', name})
    local data = {
        position = WPT.get('locomotive').position
    }
    Alert.alert_all_players_location(data, message)

    local force = game.forces.player

    if name == "I'm too young to die" then
        -- rpg_extra.difficulty = 1
        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 0.5
        force.character_running_speed_modifier = 0.15
        force.manual_crafting_speed_modifier = 0.15
        WPT.set().coin_amount = 1
        WPT.set('upgrades').flame_turret.limit = 12
        WPT.set('upgrades').landmine.limit = 50
        WPT.set().locomotive_health = 10000
        WPT.set().locomotive_max_health = 10000
        WPT.set().bonus_xp_on_join = 500
        WD.set().next_wave = game.tick + 3600 * 15
        WPT.set().spidertron_unlocked_at_wave = 14
        WPT.set().difficulty_set = true
        WD.set_biter_health_boost(1.50)
    elseif name == 'Hurt me plenty' then
        -- rpg_extra.difficulty = 0.5
        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 0.25
        force.character_running_speed_modifier = 0.1
        force.manual_crafting_speed_modifier = 0.1
        WPT.set().coin_amount = 1
        WPT.set('upgrades').flame_turret.limit = 10
        WPT.set('upgrades').landmine.limit = 50
        WPT.set().locomotive_health = 7000
        WPT.set().locomotive_max_health = 7000
        WPT.set().bonus_xp_on_join = 300
        WD.set().next_wave = game.tick + 3600 * 10
        WPT.set().spidertron_unlocked_at_wave = 16
        WPT.set().difficulty_set = true
        WD.set_biter_health_boost(2)
    elseif name == 'Ultra-violence' then
        -- rpg_extra.difficulty = 0
        force.character_running_speed_modifier = 0
        force.manual_crafting_speed_modifier = 0
        WPT.set().coin_amount = 1
        WPT.set('upgrades').flame_turret.limit = 3
        WPT.set('upgrades').landmine.limit = 10
        WPT.set().locomotive_health = 5000
        WPT.set().locomotive_max_health = 5000
        WPT.set().bonus_xp_on_join = 50
        WD.set().next_wave = game.tick + 3600 * 5
        WPT.set().spidertron_unlocked_at_wave = 18
        WPT.set().difficulty_set = true
        WD.set_biter_health_boost(3)
    elseif name == 'Nightmare' then
        -- rpg_extra.difficulty = 0
        force.character_running_speed_modifier = 0
        force.manual_crafting_speed_modifier = 0
        WPT.set().coin_amount = 1
        WPT.set('upgrades').flame_turret.limit = 0
        WPT.set('upgrades').landmine.limit = 0
        WPT.set().locomotive_health = 1000
        WPT.set().locomotive_max_health = 1000
        WPT.set().bonus_xp_on_join = 0
        WD.set().next_wave = game.tick + 3600 * 2
        WPT.set().spidertron_unlocked_at_wave = 22
        WPT.set().difficulty_set = true
        WD.set_biter_health_boost(4)
    end
end

local chunk_load = function()
    local chunk_load_tick = WPT.get('chunk_load_tick')
    if chunk_load_tick then
        if chunk_load_tick < game.tick then
            WPT.get().chunk_load_tick = nil
            Task.set_queue_speed(3)
        end
    end
end

local collapse_message =
    Token.register(
    function(data)
        local pos = data.position
        local message = data.message
        local collapse_position = {
            position = pos
        }
        Alert.alert_all_players_location(collapse_position, message)
    end
)

local lock_locomotive_positions = function()
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local locomotive_positions = WPT.get('locomotive_pos')
    local success = is_position_near_tbl(locomotive.position, locomotive_positions.tbl)
    local p = locomotive.position
    if not success then
        locomotive_positions.tbl[#locomotive_positions.tbl + 1] = {x = floor(p.x), y = floor(p.y)}
    end

    local total_pos = #locomotive_positions.tbl
    if total_pos > 50 then
        remove(locomotive_positions.tbl, total_pos - total_pos + 1)
    end
end

local set_spawn_position = function()
    local collapse_pos = Collapse.get_position()
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end
    local l = locomotive.position

    local retries = 0

    local function check_tile(surface, tile, tbl, inc)
        if not (surface and surface.valid) then
            return false
        end
        if not tile then
            return false
        end
        local get_tile = surface.get_tile(tile)
        if get_tile.valid and get_tile.name == 'out-of-map' then
            remove(tbl.tbl, inc - inc + 1)
            return true
        else
            return false
        end
    end

    ::retry::

    local locomotive_positions = WPT.get('locomotive_pos')
    local total_pos = #locomotive_positions.tbl

    local active_surface_index = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not (surface and surface.valid) then
        return
    end

    local spawn_near_collapse = WPT.get('spawn_near_collapse')

    if spawn_near_collapse.active then
        local collapse_position = surface.find_non_colliding_position('small-biter', collapse_pos, 32, 2)
        local sizeof = locomotive_positions.tbl[total_pos - total_pos + 1]
        if check_tile(surface, sizeof, locomotive_positions.tbl, total_pos) then
            retries = retries + 1
            if retries == 2 then
                goto continue
            end
            goto retry
        end

        local locomotive_position = surface.find_non_colliding_position('small-biter', sizeof, 128, 1)
        local distance_from = floor(math2d.position.distance(locomotive_position, locomotive.position))
        local l_y = l.y
        local t_y = locomotive_position.y
        local c_y = collapse_pos.y
        if total_pos > spawn_near_collapse.total_pos then
            if l_y - t_y <= spawn_near_collapse.compare then
                if locomotive_position then
                    if check_tile(surface, sizeof, locomotive_positions.tbl, total_pos) then
                        debug_str('total_pos was higher - found oom')
                        retries = retries + 1
                        if retries == 2 then
                            goto continue
                        end
                        goto retry
                    end
                    debug_str('total_pos was higher - spawning at locomotive_position')
                    WD.set_spawn_position(locomotive_position)
                end
            elseif c_y - t_y <= spawn_near_collapse.compare_next then
                if distance_from >= spawn_near_collapse.distance_from then
                    local success = check_tile(surface, locomotive_position, locomotive_positions.tbl, total_pos)
                    if success then
                        debug_str('distance_from was higher - found oom')
                        return
                    end
                    debug_str('distance_from was higher - spawning at locomotive_position')
                    WD.set_spawn_position({x = locomotive_position.x, y = collapse_pos.y - 20})
                else
                    debug_str('distance_from was lower - spawning at locomotive_position')
                    WD.set_spawn_position({x = locomotive_position.x, y = collapse_pos.y - 20})
                end
            else
                if collapse_position then
                    debug_str('total_pos was higher - spawning at collapse_position')
                    WD.set_spawn_position(collapse_position)
                end
            end
        else
            if collapse_position then
                debug_str('total_pos was lower - spawning at collapse_position')
                WD.set_spawn_position(collapse_position)
            end
        end
    end

    ::continue::
end

local compare_collapse_and_train = function()
    local collapse_pos = Collapse.get_position()
    local locomotive = WPT.get('locomotive')
    local carriages = WPT.get('carriages')
    if not locomotive or not locomotive.valid then
        return
    end

    if not carriages then
        WPT.set().carriages = locomotive.train.carriages
    end

    local c_y = collapse_pos.y
    local t_y = locomotive.position.y

    local gap_between_zones = WPT.get('gap_between_zones')

    if c_y - t_y <= gap_between_zones.gap then
        if gap_between_zones.set then
            set_difficulty()
            gap_between_zones.set = false
        end
        return
    end

    Collapse.set_speed(1)
    Collapse.set_amount(4)
    gap_between_zones.set = true
end

local collapse_after_wave_100 = function()
    local collapse_grace = WPT.get('collapse_grace')
    if not collapse_grace then
        return
    end
    if Collapse.start_now() then
        return
    end
    local difficulty = Difficulty.get()
    local name = difficulty.difficulties[difficulty.difficulty_vote_index].name

    local difficulty_set = WPT.get('difficulty_set')
    if not difficulty_set and name == 'Nightmare' then
        return
    end

    local wave_number = WD.get_wave()

    if wave_number >= 100 or name == 'Nightmare' then
        Collapse.start_now(true)
        local data = {
            position = Collapse.get_position()
        }
        data.message = ({'breached_wall.collapse_start'})
        Task.set_timeout_in_ticks(550, collapse_message, data)
    end
end

local on_tick = function()
    local update_gui = Gui_mf.update_gui
    local tick = game.tick

    if tick % 40 == 0 then
        for _, player in pairs(game.connected_players) do
            update_gui(player)
        end
        lock_locomotive_positions()
        is_player_valid()
        is_locomotive_valid()
        has_the_game_ended()
        chunk_load()
    end

    if tick % 250 == 0 then
        compare_collapse_and_train()
        set_spawn_position()
        boost_difficulty()
    end

    if tick % 1000 == 0 then
        collapse_after_wave_100()
        set_difficulty()
    end
end

local on_init = function()
    local this = WPT.get()
    Public.reset_map()

    local tooltip = {
        [1] = ({'main.diff_tooltip', '0', '0.5', '0.2', '0.4', '1', '12', '50', '10000', '100%', '15', '14'}),
        [2] = ({'main.diff_tooltip', '0', '0.25', '0.1', '0.1', '1', '10', '50', '7000', '75%', '10', '16'}),
        [3] = ({'main.diff_tooltip', '0', '0', '0', '0', '1', '3', '10', '5000', '50%', '10', '18'}),
        [4] = ({'main.diff_tooltip', '0', '0', '0', '0', '1', '0', '0', '1000', '25%', '5', '22'})
    }

    Difficulty.set_tooltip(tooltip)

    this.rocks_yield_ore_maximum_amount = 500
    this.type_modifier = 1
    this.rocks_yield_ore_base_amount = 40
    this.rocks_yield_ore_distance_modifier = 0.020

    local T = Map.Pop_info()
    T.localised_category = 'mountain_fortress_v3'
    T.main_caption_color = {r = 150, g = 150, b = 0}
    T.sub_caption_color = {r = 0, g = 150, b = 0}

    Explosives.set_destructible_tile('out-of-map', 1500)
    Explosives.set_destructible_tile('water', 1000)
    Explosives.set_destructible_tile('water-green', 1000)
    Explosives.set_destructible_tile('deepwater-green', 1000)
    Explosives.set_destructible_tile('deepwater', 1000)
    Explosives.set_destructible_tile('water-shallow', 1000)
    Explosives.set_destructible_tile('water-mud', 1000)
    Explosives.set_destructible_tile('lab-dark-2', 1000)
    Explosives.set_whitelist_entity('straight-rail')
    Explosives.set_whitelist_entity('curved-rail')
    Explosives.set_whitelist_entity('character')
end

Event.on_nth_tick(10, on_tick)
Event.on_init(on_init)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_research_finished, on_research_finished)

return Public
