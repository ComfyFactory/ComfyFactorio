require 'maps.mountain_fortress_v3.generate'
require 'maps.mountain_fortress_v3.commands'
require 'maps.mountain_fortress_v3.breached_wall'
require 'maps.mountain_fortress_v3.ic.main'

require 'modules.rpg.main'
require 'modules.dynamic_landfill'
require 'modules.shotgun_buff'
require 'modules.no_deconstruction_of_neutral_entities'
require 'modules.rocks_yield_ore_veins'
require 'modules.spawners_contain_biters'
require 'modules.biters_yield_coins'
require 'modules.wave_defense.main'
require 'modules.mineable_wreckage_yields_scrap'
require 'modules.charging_station'

local IC = require 'maps.mountain_fortress_v3.ic.table'
local Autostash = require 'modules.autostash'
local Group = require 'comfy_panel.group'
local PL = require 'comfy_panel.player_list'
local CS = require 'maps.mountain_fortress_v3.surface'
local Map_score = require 'comfy_panel.map_score'
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
local Difficulty = require 'modules.difficulty_vote'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Alert = require 'utils.alert'
local AntiGrief = require 'antigrief'

local Public = {}
local floor = math.floor
local random = math.random
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

local function get_player_data(player, remove_user_data)
    local this = WPT.get()
    if remove_user_data then
        if this.players[player.index] then
            this.players[player.index] = nil
        end
    end
    if not this.players[player.index] then
        this.players[player.index] = {}
    end
    return this.players[player.index]
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

local set_difficulty = function()
    local Diff = Difficulty.get()
    local wave_defense_table = WD.get_table()
    local collapse_speed = WPT.get('collapse_speed')
    local collapse_amount = WPT.get('collapse_amount')
    local player_count = #game.connected_players
    if not Diff.difficulty_vote_value then
        Diff.difficulty_vote_value = 0.1
    end

    wave_defense_table.max_active_biters = 888 + player_count * (90 * Diff.difficulty_vote_value)

    -- threat gain / wave
    wave_defense_table.threat_gain_multiplier = 1.2 + player_count * Diff.difficulty_vote_value * 0.1

    local amount = player_count * 0.25 + 6
    amount = floor(amount)
    if amount > 10 then
        amount = 10
    end

    local difficulty = Difficulty.get()
    local name = difficulty.difficulties[difficulty.difficulty_vote_index].name

    if wave_defense_table.threat <= 0 then
        wave_defense_table.wave_interval = 1000
        return
    end
    if name == 'Insane' then
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

    if name == 'Insane' then
        Collapse.set_amount(12)
    elseif collapse_amount then
        Collapse.set_amount(collapse_amount)
    else
        Collapse.set_amount(amount)
    end

    if name == 'Insane' then
        Collapse.set_speed(5)
    elseif collapse_speed then
        Collapse.set_speed(collapse_speed)
    else
        if player_count >= 8 and player_count <= 12 then
            Collapse.set_speed(8)
        elseif player_count >= 20 and player_count <= 24 then
            Collapse.set_speed(6)
        elseif player_count >= 35 then
            Collapse.set_speed(5)
        end
    end
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

    Poll.reset()
    ICW.reset()
    IC.reset()
    IC.allowed_surface('mountain_fortress_v3')
    Functions.reset_table()
    game.reset_time_played()
    WPT.reset_table()
    Map_score.reset_score()
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

    Balance.init_enemy_weapon_damage()

    global.custom_highscore.description = 'Wagon distance reached:'
    Entities.set_scores()
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
    game.map_settings.path_finder.max_work_done_per_tick = 4000
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
    WD.remove_entities(false)
    WD.enable_threat_log(true)
    WD.check_collapse_position(true)

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
    local this = WPT.get()
    local player = game.players[event.player_index]
    local map_name = 'mountain_fortress_v3'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local position = player.position
    local surface = game.surfaces[this.active_surface_index]

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
    local this = WPT.get()
    local player = game.players[event.player_index]
    local surface = game.surfaces[this.active_surface_index]

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

    if player.surface.index ~= this.active_surface_index then
        player.teleport(
            surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5),
            surface
        )
    else
        local p = {x = player.position.x, y = player.position.y}
        local get_tile = surface.get_tile(p)
        if get_tile.valid and get_tile.name == 'out-of-map' then
            player.teleport(
                surface.find_non_colliding_position(
                    'character',
                    game.forces.player.get_spawn_position(surface),
                    3,
                    0,
                    5
                ),
                surface
            )
        end
    end

    if not this.locomotive or not this.locomotive.valid then
        return
    end
    if player.position.y > this.locomotive.position.y then
        player.teleport(
            surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5),
            surface
        )
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
    local this = WPT.get()

    research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 50 -- +5 Slots / level
    local mining_speed_bonus = game.forces.player.mining_drill_productivity_bonus * 5 -- +50% speed / level
    if research.force.technologies['steel-axe'].researched then
        mining_speed_bonus = mining_speed_bonus + 0.5
    end -- +50% speed for steel-axe research
    if this.breached_wall <= 2 then
        research.force.manual_mining_speed_modifier = this.force_mining_speed.speed + mining_speed_bonus
    else
        research.force.manual_mining_speed_modifier = mining_speed_bonus
    end

    local force_name = research.force.name
    if not force_name then
        return
    end
    this.flamethrower_damage[force_name] = -0.85
    if research.name == 'military' then
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', this.flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', this.flamethrower_damage[force_name])
    end

    if string.sub(research.name, 0, 18) == 'refined-flammables' then
        this.flamethrower_damage[force_name] = this.flamethrower_damage[force_name] + 0.10
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', this.flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', this.flamethrower_damage[force_name])
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
            local player_data = get_player_data(player)
            if player_data.died then
                return
            end
            player.set_controller {type = defines.controllers.god}
            player.create_character()
        end
    end
end

local has_the_game_ended = function()
    local this = WPT.get()
    if this.game_reset_tick then
        if this.game_reset_tick < 0 then
            return
        end

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
    local force_mining_speed = WPT.get('force_mining_speed')
    if difficulty_set then
        return
    end

    local difficulty = Difficulty.get()
    local name = difficulty.difficulties[difficulty.difficulty_vote_index].name

    if game.tick < difficulty.difficulty_poll_closing_timeout then
        return
    end

    local rpg_extra = RPG_Settings.get('rpg_extra')
    Difficulty.get().name = name

    Difficulty.get().button_tooltip = difficulty.tooltip[difficulty.difficulty_vote_index]
    Difficulty.difficulty_gui()

    local message = ({'main.diff_set', name})
    local data = {
        position = WPT.get('locomotive').position
    }
    Alert.alert_all_players_location(data, message)

    if name == 'Easy' then
        rpg_extra.difficulty = 1
        game.forces.player.manual_mining_speed_modifier = 1
        force_mining_speed.speed = game.forces.player.manual_mining_speed_modifier
        game.forces.player.character_running_speed_modifier = 0.2
        game.forces.player.manual_crafting_speed_modifier = 0.3
        WPT.set().coin_amount = 2
        WPT.set('upgrades').flame_turret.limit = 25
        WPT.set('upgrades').landmine.limit = 100
        WPT.set().locomotive_health = 15000
        WPT.set().locomotive_max_health = 15000
        WPT.set().bonus_xp_on_join = 700
        WD.set().next_wave = game.tick + 3600 * 20
        WPT.set().spidertron_unlocked_at_wave = 11
        WPT.set().difficulty_set = true
    elseif name == 'Normal' then
        rpg_extra.difficulty = 0.5
        game.forces.player.manual_mining_speed_modifier = 0.5
        force_mining_speed.speed = game.forces.player.manual_mining_speed_modifier
        game.forces.player.character_running_speed_modifier = 0.1
        game.forces.player.manual_crafting_speed_modifier = 0.1
        WPT.set().coin_amount = 1
        WPT.set('upgrades').flame_turret.limit = 10
        WPT.set('upgrades').landmine.limit = 50
        WPT.set().locomotive_health = 10000
        WPT.set().locomotive_max_health = 10000
        WPT.set().bonus_xp_on_join = 300
        WD.set().next_wave = game.tick + 3600 * 15
        WPT.set().spidertron_unlocked_at_wave = 16
        WPT.set().difficulty_set = true
    elseif name == 'Hard' then
        rpg_extra.difficulty = 0
        game.forces.player.manual_mining_speed_modifier = 0
        force_mining_speed.speed = game.forces.player.manual_mining_speed_modifier
        game.forces.player.character_running_speed_modifier = 0
        game.forces.player.manual_crafting_speed_modifier = 0
        WPT.set().coin_amount = 1
        WPT.set('upgrades').flame_turret.limit = 3
        WPT.set('upgrades').landmine.limit = 10
        WPT.set().locomotive_health = 5000
        WPT.set().locomotive_max_health = 5000
        WPT.set().bonus_xp_on_join = 50
        WD.set().next_wave = game.tick + 3600 * 10
        WPT.set().spidertron_unlocked_at_wave = 21
        WPT.set().difficulty_set = true
    elseif name == 'Insane' then
        rpg_extra.difficulty = 0
        game.forces.player.manual_mining_speed_modifier = 0
        force_mining_speed.speed = game.forces.player.manual_mining_speed_modifier
        game.forces.player.character_running_speed_modifier = 0
        game.forces.player.manual_crafting_speed_modifier = 0
        WPT.set().coin_amount = 1
        WPT.set('upgrades').flame_turret.limit = 0
        WPT.set('upgrades').landmine.limit = 0
        WPT.set().locomotive_health = 1000
        WPT.set().locomotive_max_health = 1000
        WPT.set().bonus_xp_on_join = 0
        WD.set().next_wave = game.tick + 3600 * 5
        WPT.set().spidertron_unlocked_at_wave = 26
        WPT.set().difficulty_set = true
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
    if not difficulty_set and name == 'Insane' then
        return
    end

    local wave_number = WD.get_wave()

    if wave_number >= 100 or name == 'Insane' then
        Collapse.start_now(true)
        local data = {
            position = Collapse.get_position()
        }
        data.message = ({'breached_wall.collapse_start'})
        Task.set_timeout_in_ticks(550, collapse_message, data)
    end
end

local on_tick = function()
    local active_surface_index = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    local update_gui = Gui_mf.update_gui
    local tick = game.tick

    if tick % 40 == 0 then
        for _, player in pairs(game.connected_players) do
            update_gui(player)
        end

        is_player_valid()
        is_locomotive_valid()
        has_the_game_ended()
        chunk_load()

        if tick % 1200 == 0 then
            boost_difficulty()
            collapse_after_wave_100()
            Entities.set_scores()
            set_difficulty()
            local spawn_near_collapse = WPT.get('spawn_near_collapse')
            if spawn_near_collapse then
                local collapse_pos = Collapse.get_position()
                local position = surface.find_non_colliding_position('rocket-silo', collapse_pos, 128, 1)
                if position then
                    WD.set_spawn_position(position)
                end
            end
        end
    end
end

local on_init = function()
    local this = WPT.get()
    Public.reset_map()

    local difficulties = {
        [1] = {
            name = 'Easy',
            value = 0.75,
            color = {r = 0.00, g = 0.25, b = 0.00},
            print_color = {r = 0.00, g = 0.4, b = 0.00}
        },
        [2] = {
            name = 'Normal',
            value = 1,
            color = {r = 0.00, g = 0.00, b = 0.25},
            print_color = {r = 0.0, g = 0.0, b = 0.5}
        },
        [3] = {
            name = 'Hard',
            value = 1.5,
            color = {r = 0.25, g = 0.25, b = 0.00},
            print_color = {r = 0.4, g = 0.0, b = 0.00}
        },
        [4] = {
            name = 'Insane',
            value = 3,
            color = {r = 0.25, g = 0.00, b = 0.00},
            print_color = {r = 0.4, g = 0.0, b = 0.00}
        }
    }

    local tooltip = {
        [1] = ({'main.diff_tooltip', '1', '1.5', '0.2', '0.4', '2', '25', '100', '15000', '100%', '20', '10'}),
        [2] = ({'main.diff_tooltip', '0.5', '1', '0.1', '0.2', '1', '10', '50', '10000', '75%', '15', '15'}),
        [3] = ({'main.diff_tooltip', '0', '0', '0', '0', '1', '3', '10', '5000', '50%', '10', '20'}),
        [4] = ({'main.diff_tooltip', '0', '0', '0', '0', '1', '0', '0', '1000', '25%', '5', '25'})
    }

    Difficulty.set_difficulties(difficulties)
    Difficulty.set_tooltip(tooltip)

    this.rocks_yield_ore_maximum_amount = 500
    this.type_modifier = 1
    this.rocks_yield_ore_base_amount = 100
    this.rocks_yield_ore_distance_modifier = 0.025

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
