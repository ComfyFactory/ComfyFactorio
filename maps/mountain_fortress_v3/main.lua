--[[

Mountain Fortress v3 is maintained by Gerkiz and hosted by Comfy.

Want to host it? Ask Gerkiz#0001 at discord!

]]
local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.core'
local Discord = require 'utils.discord'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local ICMinimap = require 'maps.mountain_fortress_v3.ic.minimap'
local Autostash = require 'modules.autostash'
local Group = require 'utils.gui.group'
local PL = require 'utils.gui.player_list'
local Server = require 'utils.server'
local Explosives = require 'modules.explosives'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WD = require 'modules.wave_defense.table'
local Map = require 'modules.map_info'
local RPG = require 'modules.rpg.main'
local Score = require 'utils.gui.score'
local Poll = require 'utils.gui.poll'
local Collapse = require 'modules.collapse'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Alert = require 'utils.alert'
local BottomFrame = require 'utils.gui.bottom_frame'
local AntiGrief = require 'utils.antigrief'
local Misc = require 'utils.commands.misc'
local Modifiers = require 'utils.player_modifiers'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local JailData = require 'utils.datastore.jail_data'
local RPG_Progression = require 'utils.datastore.rpg_data'
local OfflinePlayers = require 'modules.clear_vacant_players'

require 'modules.shotgun_buff'
require 'modules.no_deconstruction_of_neutral_entities'
require 'modules.spawners_contain_biters'
require 'maps.mountain_fortress_v3.ic.main'
require 'modules.wave_defense.main'
require 'modules.charging_station'

-- Use these settings for live
local send_ping_to_channel = Discord.channel_names.mtn_channel
local role_to_mention = Discord.role_mentions.mtn_fortress
-- Use these settings for testing
-- bot-lounge
-- local send_ping_to_channel = Discord.channel_names.bot_quarters
-- local role_to_mention = Discord.role_mentions.test_role

local floor = math.floor
local remove = table.remove
RPG.disable_cooldowns_on_spells()

local collapse_kill = {
    entities = {
        ['laser-turret'] = true,
        ['flamethrower-turret'] = true,
        ['gun-turret'] = true,
        ['artillery-turret'] = true,
        ['land-mine'] = true,
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

local init_bonus_drill_force = function()
    local bonus_drill = game.forces.bonus_drill
    local player = game.forces.player
    if not bonus_drill then
        bonus_drill = game.create_force('bonus_drill')
    end
    bonus_drill.set_friend('player', true)
    player.set_friend('bonus_drill', true)
    bonus_drill.mining_drill_productivity_bonus = 0.5
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

local announce_new_map =
    Token.register(
    function()
        local server_name = Server.check_server_name('Mtn Fortress')
        if server_name then
            Server.to_discord_named_raw(send_ping_to_channel, role_to_mention .. ' ** Mtn Fortress was just reset! **')
        end
    end
)

function Public.reset_map()
    local this = Public.get()
    local wave_defense_table = WD.get_table()
    Misc.set('creative_are_you_sure', false)
    Misc.set('creative_enabled', false)

    Event.raise(WD.events.on_game_reset, {})

    this.active_surface_index = Public.create_surface()
    -- this.soft_reset_counter = Public.get_reset_counter()

    Autostash.insert_into_furnace(true)
    Autostash.insert_into_wagon(true)
    Autostash.bottom_button(true)
    BottomFrame.reset()
    BottomFrame.activate_custom_buttons(true)
    Public.reset_buried_biters()
    Poll.reset()
    ICW.reset()
    IC.reset()
    IC.allowed_surface(game.surfaces[this.active_surface_index].name)
    Public.reset_func_table()
    game.reset_time_played()
    Public.reset_main_table()

    OfflinePlayers.init(this.active_surface_index)
    OfflinePlayers.set_enabled(true)
    -- OfflinePlayers.set_offline_players_surface_removal(true)

    RPG.rpg_reset_all_players()
    RPG.set_surface_name(game.surfaces[this.active_surface_index].name)
    RPG.enable_health_and_mana_bars(true)
    RPG.enable_wave_defense(true)
    RPG.enable_mana(true)
    RPG.personal_tax_rate(0.4)
    RPG.enable_stone_path(true)
    RPG.enable_aoe_punch(true)
    RPG.enable_aoe_punch_globally(false)
    RPG.enable_range_buffs(true)
    RPG.enable_auto_allocate(true)
    RPG.enable_explosive_bullets_globally(true)
    RPG.enable_explosive_bullets(false)
    RPG_Progression.toggle_module(false)
    RPG_Progression.set_dataset('mtn_v3_rpg_prestige')

    if Public.get('prestige_system_enabled') then
        RPG_Progression.restore_xp_on_reset()
    end

    Group.reset_groups()
    Group.alphanumeric_only(false)

    Public.disable_tech()
    init_bonus_drill_force()

    local surface = game.surfaces[this.active_surface_index]

    if this.winter_mode then
        surface.daytime = 0.45
    end

    JailData.set_valid_surface(tostring(surface.name))
    JailData.reset_vote_table()

    Explosives.set_surface_whitelist({[surface.name] = true})
    Explosives.check_growth_below_void(true)

    game.forces.player.set_spawn_position({-27, 25}, surface)
    game.forces.player.manual_mining_speed_modifier = 0
    game.forces.player.set_ammo_damage_modifier('artillery-shell', -0.95)

    BiterHealthBooster.set_active_surface(tostring(surface.name))
    BiterHealthBooster.acid_nova(true)
    BiterHealthBooster.check_on_entity_died(true)
    BiterHealthBooster.boss_spawns_projectiles(true)
    BiterHealthBooster.enable_boss_loot(false)
    BiterHealthBooster.enable_randomize_stun_and_slowdown_sticker(true)

    Public.init_enemy_weapon_damage()

    AntiGrief.whitelist_types('tree', true)
    AntiGrief.enable_capsule_warning(false)
    AntiGrief.enable_capsule_cursor_warning(false)
    AntiGrief.enable_jail(true)
    AntiGrief.damage_entity_threshold(20)
    AntiGrief.explosive_threshold(32)
    AntiGrief.decon_surface_blacklist(surface.name)
    AntiGrief.filtered_types_on_decon({'tree', 'simple-entity', 'fish'})

    PL.show_roles_in_list(true)
    PL.rpg_enabled(true)

    Score.reset_tbl()

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Score.init_player_table(player, true)
        Misc.insert_all_items(player)
        Modifiers.reset_player_modifiers(player)
        if player.gui.left['mvps'] then
            player.gui.left['mvps'].destroy()
        end
        ICMinimap.kill_minimap(player)
        Event.raise(Public.events.reset_map, {player_index = player.index})
    end

    Difficulty.reset_difficulty_poll({closing_timeout = game.tick + 36000})
    Difficulty.set_gui_width(20)

    Collapse.set_kill_entities(false)
    Collapse.set_kill_specific_entities(collapse_kill)
    Collapse.set_speed(8)
    Collapse.set_amount(1)
    -- Collapse.set_max_line_size(zone_settings.zone_width)
    Collapse.set_max_line_size(540)
    Collapse.set_surface_index(surface.index)
    Collapse.set_position({0, 130})
    Collapse.set_direction('north')
    Collapse.start_now(false)

    this.locomotive_health = 10000
    this.locomotive_max_health = 10000

    Public.locomotive_spawn(surface, {x = -18, y = 25})
    Public.render_train_hp()
    Public.render_direction(surface)

    WD.reset_wave_defense()
    wave_defense_table.surface_index = this.active_surface_index
    wave_defense_table.target = this.locomotive
    wave_defense_table.nest_building_density = 32
    wave_defense_table.game_lost = false
    wave_defense_table.spawn_position = {x = 0, y = 84}
    WD.alert_boss_wave(true)
    WD.remove_entities(true)
    WD.enable_threat_log(false) -- creates waaaay to many entries in the global table
    WD.check_collapse_position(true)
    WD.set_disable_threat_below_zero(true)
    WD.increase_boss_health_per_wave(true)
    WD.increase_damage_per_wave(true)
    WD.increase_health_per_wave(true)
    WD.increase_average_unit_group_size(true)
    WD.increase_max_active_unit_groups(true)
    WD.enable_random_spawn_positions(true)

    Public.set_difficulty()
    Public.disable_creative()

    if not surface.is_chunk_generated({-20, 22}) then
        surface.request_to_generate_chunks({-20, 22}, 0.1)
        surface.force_generate_chunk_requests()
    end

    game.forces.player.set_spawn_position({-27, 25}, surface)
    game.speed = 1

    Task.set_queue_speed(16)

    Public.get_scores()

    this.chunk_load_tick = game.tick + 400
    this.force_chunk = true
    this.market_announce = game.tick + 1200
    this.game_lost = false

    Task.set_timeout_in_ticks(25, announce_new_map)
end

local is_locomotive_valid = function()
    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        Public.set('game_lost', true)
        Public.loco_died(true)
    end
end

local is_player_valid = function()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        if player.connected and player.controller_type == 2 then
            player.set_controller {type = defines.controllers.god}
            player.create_character()
        end
    end
end

local has_the_game_ended = function()
    local game_reset_tick = Public.get('game_reset_tick')
    if game_reset_tick then
        if game_reset_tick < 0 then
            return
        end

        local this = Public.get()

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

            local diff_name = Difficulty.get('name')

            if this.soft_reset and this.game_reset_tick == 0 then
                this.game_reset_tick = nil
                Public.set_scores(diff_name)
                Public.reset_map()
                return
            end

            if this.restart and this.game_reset_tick == 0 then
                if not this.announced_message then
                    Public.set_scores(diff_name)
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
                    Public.set_scores(diff_name)
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

local chunk_load = function()
    local chunk_load_tick = Public.get('chunk_load_tick')
    local tick = game.tick
    if chunk_load_tick then
        if chunk_load_tick < tick then
            Public.set('force_chunk', false)
            Public.remove('chunk_load_tick')
            Task.set_queue_speed(8)
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
    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local locomotive_positions = Public.get('locomotive_pos')
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

local compare_collapse_and_train = function()
    local collapse_pos = Collapse.get_position()
    local locomotive = Public.get('locomotive')
    if not (locomotive and locomotive.valid) then
        return
    end

    local c_y = collapse_pos.y
    local t_y = locomotive.position.y

    local gap_between_zones = Public.get('gap_between_zones')

    if c_y - t_y <= gap_between_zones.gap then
        Public.set_difficulty()
    else
        Collapse.set_speed(1)
        Collapse.set_amount(4)
    end
end

local collapse_after_wave_200 = function()
    local collapse_grace = Public.get('collapse_grace')
    if not collapse_grace then
        return
    end
    if Collapse.start_now() then
        return
    end

    local wave_number = WD.get_wave()

    if wave_number >= 200 then
        Collapse.start_now(true)
        local data = {
            position = Collapse.get_position()
        }
        data.message = ({'breached_wall.collapse_start'})
        Task.set_timeout_in_ticks(550, collapse_message, data)
    end
end

local handle_changes = function()
    Public.set('restart', true)
    Public.set('soft_reset', false)
    print('Received new changes from backend.')
end

local on_tick = function()
    local update_gui = Public.update_gui
    local tick = game.tick
    local players = game.connected_players

    if tick % 40 == 0 then
        for i = 1, #players do
            local player = players[i]
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
        Public.set_spawn_position()
        Public.boost_difficulty()
    end

    if tick % 1000 == 0 then
        collapse_after_wave_200()
        Public.set_difficulty()
        Public.is_creativity_mode_on()
    end
end

local on_init = function()
    Public.reset_map()

    game.map_settings.path_finder.general_entity_collision_penalty = 10 -- Recommended value
    game.map_settings.path_finder.general_entity_subsequent_collision_penalty = 3 -- Recommended value

    local tooltip = {
        [1] = ({'main.diff_tooltip', '500', '50%', '15%', '15%', '1', '12', '50', '10000', '100%', '15', '10'}),
        [2] = ({'main.diff_tooltip', '300', '25%', '10%', '10%', '2', '10', '50', '7000', '75%', '8', '8'}),
        [3] = ({'main.diff_tooltip', '50', '0%', '0%', '0%', '4', '3', '10', '5000', '50%', '5', '6'})
    }

    Difficulty.set_tooltip(tooltip)

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
    Explosives.set_whitelist_entity('spidertron')
    Explosives.set_whitelist_entity('car')
    Explosives.set_whitelist_entity('tank')
end

Event.add(Server.events.on_changes_detected, handle_changes)

Event.on_nth_tick(10, on_tick)
Event.on_init(on_init)

return Public
