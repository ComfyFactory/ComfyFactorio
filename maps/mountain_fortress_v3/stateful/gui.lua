local Event = require 'utils.event'
local SpamProtection = require 'utils.spam_protection'
local Public = require 'maps.mountain_fortress_v3.table'
local Gui = require 'utils.gui'
local WD = require 'modules.wave_defense.table'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Core = require 'utils.core'
local Server = require 'utils.server'

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local boss_frame_name = Gui.uid_name()
local close_button = Gui.uid_name()
local random = math.random
local floor = math.floor

local function create_particles(surface, name, position, amount, cause_position)
    local d1 = (-100 + random(0, 200)) * 0.0004
    local d2 = (-100 + random(0, 200)) * 0.0004

    name = name or 'leaf-particle'

    if cause_position then
        d1 = (cause_position.x - position.x) * 0.025
        d2 = (cause_position.y - position.y) * 0.025
    end

    for _ = 1, amount, 1 do
        local m = random(4, 10)
        local m2 = m * 0.005

        surface.create_particle(
            {
                name = name,
                position = position,
                frame_speed = 1,
                vertical_speed = 0.130,
                height = 0,
                movement = {
                    (m2 - (random(0, m) * 0.01)) + d1,
                    (m2 - (random(0, m) * 0.01)) + d2
                }
            }
        )
    end
end

local spread_particles_token =
    Token.register(
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end
        local particle = event.particle

        create_particles(player.surface, particle, player.position, 128)
    end
)

local warn_player_sound_token =
    Token.register(
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end
        local particle = event.particle

        player.play_sound {path = 'utility/new_objective', volume_modifier = 0.75}

        create_particles(player.surface, particle, player.position, 128)
    end
)

local function create_button(player)
    local b =
        player.gui.top.add(
        {
            type = 'sprite-button',
            name = main_button_name,
            sprite = 'utility/custom_tag_icon',
            tooltip = 'Has information about all objectives that needs to be completed'
        }
    )
    b.style.minimal_height = 38
    b.style.maximal_height = 38
end

local function play_game_won()
    Core.iter_connected_players(
        function(player)
            player.play_sound {path = 'utility/game_won', volume_modifier = 0.75}
            Task.set_timeout_in_ticks(10, spread_particles_token, {player_index = player.index, particle = 'iron-ore-particle'})
            Task.set_timeout_in_ticks(15, spread_particles_token, {player_index = player.index, particle = 'branch-particle'})
            Task.set_timeout_in_ticks(20, spread_particles_token, {player_index = player.index, particle = 'copper-ore-particle'})
            Task.set_timeout_in_ticks(25, spread_particles_token, {player_index = player.index, particle = 'branch-particle'})
            Task.set_timeout_in_ticks(30, spread_particles_token, {player_index = player.index, particle = 'stone-particle'})
            Task.set_timeout_in_ticks(35, spread_particles_token, {player_index = player.index, particle = 'branch-particle'})
            Task.set_timeout_in_ticks(40, spread_particles_token, {player_index = player.index, particle = 'coal-particle'})
            Task.set_timeout_in_ticks(45, spread_particles_token, {player_index = player.index, particle = 'branch-particle'})
        end
    )
end

local function play_achievement_unlocked()
    Core.iter_connected_players(
        function(player)
            player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.75}
            Task.set_timeout_in_ticks(10, spread_particles_token, {player_index = player.index, particle = 'iron-ore-particle'})
            Task.set_timeout_in_ticks(15, spread_particles_token, {player_index = player.index, particle = 'branch-particle'})
            Task.set_timeout_in_ticks(20, spread_particles_token, {player_index = player.index, particle = 'copper-ore-particle'})
            Task.set_timeout_in_ticks(25, spread_particles_token, {player_index = player.index, particle = 'branch-particle'})
            Task.set_timeout_in_ticks(30, spread_particles_token, {player_index = player.index, particle = 'stone-particle'})
            Task.set_timeout_in_ticks(35, spread_particles_token, {player_index = player.index, particle = 'branch-particle'})
            Task.set_timeout_in_ticks(40, spread_particles_token, {player_index = player.index, particle = 'coal-particle'})
            Task.set_timeout_in_ticks(45, spread_particles_token, {player_index = player.index, particle = 'branch-particle'})
        end
    )
end

local function alert_players_sound()
    Core.iter_connected_players(
        function(player)
            Task.set_timeout_in_ticks(10, warn_player_sound_token, {player_index = player.index, particle = 'iron-ore-particle'})
            Task.set_timeout_in_ticks(20, warn_player_sound_token, {player_index = player.index, particle = 'branch-particle'})
            Task.set_timeout_in_ticks(30, warn_player_sound_token, {player_index = player.index, particle = 'copper-ore-particle'})
            Task.set_timeout_in_ticks(40, warn_player_sound_token, {player_index = player.index, particle = 'branch-particle'})
            Task.set_timeout_in_ticks(50, warn_player_sound_token, {player_index = player.index, particle = 'stone-particle'})
            Task.set_timeout_in_ticks(60, warn_player_sound_token, {player_index = player.index, particle = 'branch-particle'})
            Task.set_timeout_in_ticks(70, warn_player_sound_token, {player_index = player.index, particle = 'coal-particle'})
            Task.set_timeout_in_ticks(80, warn_player_sound_token, {player_index = player.index, particle = 'branch-particle'})
        end
    )
end

local function spacer(frame)
    local flow = frame.add({type = 'flow'})
    flow.style.minimal_height = 2
end

local function objective_frames(stateful, player_frame, objective, data)
    local objective_name = objective[1]
    if objective_name == 'supplies' or objective_name == 'single_item' then
        local supplies = stateful.objectives.supplies
        local tbl = player_frame.add {type = 'table', column_count = 2}
        tbl.style.horizontally_stretchable = true
        local left_flow = tbl.add({type = 'flow'})
        left_flow.style.horizontal_align = 'left'
        left_flow.style.horizontally_stretchable = true

        if objective_name == 'single_item' then
            left_flow.add({type = 'label', caption = {'stateful.production_single'}, tooltip = {'stateful.production_tooltip'}})
        else
            left_flow.add({type = 'label', caption = {'stateful.production'}, tooltip = {'stateful.production_tooltip'}})
        end
        player_frame.add({type = 'line', direction = 'vertical'})
        local right_flow = tbl.add({type = 'flow'})
        right_flow.style.horizontal_align = 'right'
        right_flow.style.horizontally_stretchable = true

        if stateful.objectives_completed.supplies then
            data.supply_completed = right_flow.add({type = 'label', caption = ' [img=utility/check_mark_green]', tooltip = {'stateful.tooltip_completed'}})
        else
            data.supply_completed = right_flow.add({type = 'label', caption = ' [img=utility/not_available]', tooltip = {'stateful.tooltip_not_completed'}})
        end
        -- if objective[1]() then
        --     right_flow.add({type = 'label', caption = '[img=utility/check_mark_green]'})
        -- else
        -- end

        data.supply = {}

        local flow = player_frame.add({type = 'flow'})
        local item_table = flow.add({type = 'table', name = 'item_table', column_count = 3})
        if objective_name ~= 'single_item' then
            data.supply[#data.supply + 1] = item_table.add({type = 'sprite-button', name = supplies[1].name, sprite = 'item/' .. supplies[1].name, enabled = false, number = supplies[1].count})
            data.supply[#data.supply + 1] = item_table.add({type = 'sprite-button', name = supplies[2].name, sprite = 'item/' .. supplies[2].name, enabled = false, number = supplies[2].count})
            data.supply[#data.supply + 1] = item_table.add({type = 'sprite-button', name = supplies[3].name, sprite = 'item/' .. supplies[3].name, enabled = false, number = supplies[3].count})
        else
            local single_item = stateful.objectives.single_item
            data.single_item = item_table.add({type = 'sprite-button', name = single_item.name, sprite = 'item/' .. single_item.name, enabled = false, number = single_item.count})
        end

        return
    end

    if objective_name == 'locomotive_market_selection' then
        local callback_token = stateful.objectives.locomotive_market_selection[1]
        local callback_data = stateful.objectives.locomotive_market_selection[2]
        local callback = Token.get(callback_token)

        local _, locale_left, locale_right, tooltip = callback(callback_data)
        local tbl = player_frame.add {type = 'table', column_count = 2}
        tbl.style.horizontally_stretchable = true
        local left_flow = tbl.add({type = 'flow'})
        left_flow.style.horizontal_align = 'left'
        left_flow.style.horizontally_stretchable = true

        left_flow.add({type = 'label', caption = locale_left, tooltip = {'stateful.locomotive_tooltip'}})
        local right_flow = tbl.add({type = 'flow'})
        right_flow.style.horizontal_align = 'right'
        right_flow.style.horizontally_stretchable = true

        local locomotive_market = right_flow.add({type = 'label', caption = locale_right, tooltip = tooltip})
        data.locomotive_market = locomotive_market
        return
    end

    local callback = Token.get(objective[2])

    local _, objective_locale_left, objective_locale_right, tooltip_left, tooltip_right = callback()

    local tbl = player_frame.add {type = 'table', column_count = 2}
    tbl.style.horizontally_stretchable = true
    local left_flow = tbl.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    data.random_objectives = {}

    left_flow.add({type = 'label', caption = objective_locale_left, tooltip = tooltip_left})
    local right_flow = tbl.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'
    right_flow.style.horizontally_stretchable = true

    local objective_locale_right_label = right_flow.add({type = 'label', caption = objective_locale_right, tooltip = tooltip_right})
    data.random_objectives[#data.random_objectives + 1] = {name = objective_name, frame = objective_locale_right_label}
end

local function boss_frame(player, alert)
    local main_winning_frame = player.gui.screen[main_frame_name]
    if main_winning_frame then
        Gui.remove_data_recursively(main_winning_frame)
        main_winning_frame.destroy()
    end
    local main_player_boss_frame = player.gui.screen[boss_frame_name]
    if main_player_boss_frame then
        Gui.remove_data_recursively(main_player_boss_frame)
        main_player_boss_frame.destroy()
    end

    local data = {}

    local stateful = Public.get_stateful()
    local collection = stateful.collection

    local frame = player.gui.screen.add {type = 'frame', name = boss_frame_name, caption = {'stateful.win_conditions'}, direction = 'vertical'}
    if not alert then
        frame.location = {x = 1, y = 45}
    else
        frame.location = {x = 1, y = 123}
    end
    frame.style.maximal_height = 500
    frame.style.minimal_width = 200
    frame.style.maximal_width = 400
    local rounds_survived_tbl = frame.add {type = 'table', column_count = 2}
    rounds_survived_tbl.style.horizontally_stretchable = true

    local rounds_survived_left_flow = rounds_survived_tbl.add({type = 'flow'})
    rounds_survived_left_flow.style.horizontal_align = 'left'
    rounds_survived_left_flow.style.horizontally_stretchable = true

    rounds_survived_left_flow.add({type = 'label', caption = {'stateful.rounds_survived'}, tooltip = {'stateful.rounds_survived_tooltip'}})
    frame.add({type = 'line', direction = 'vertical'})
    local rounds_survived_right_flow = rounds_survived_tbl.add({type = 'flow'})
    rounds_survived_right_flow.style.horizontal_align = 'right'
    rounds_survived_right_flow.style.horizontally_stretchable = true

    data.rounds_survived_label = rounds_survived_right_flow.add({type = 'label', caption = stateful.rounds_survived})
    spacer(frame)

    frame.add({type = 'line'})

    spacer(frame)

    if not collection.game_won then
        local objective_tbl = frame.add {type = 'table', column_count = 2}
        objective_tbl.style.horizontally_stretchable = true

        local attack_left_flow = objective_tbl.add({type = 'flow'})
        attack_left_flow.style.horizontal_align = 'left'
        attack_left_flow.style.horizontally_stretchable = true

        attack_left_flow.add({type = 'label', caption = {'stateful.time_until_attack'}, tooltip = {'stateful.time_until_attack_tooltip'}})
        frame.add({type = 'line', direction = 'vertical'})
        local attack_right_flow = objective_tbl.add({type = 'flow'})
        attack_right_flow.style.horizontal_align = 'right'
        attack_right_flow.style.horizontally_stretchable = true

        local time_left = floor(collection.time_until_attack / 60 / 60) .. 'm'

        if collection.time_until_attack / 60 / 60 <= 0 then
            time_left = floor(collection.time_until_attack / 60) .. 's'
        end

        if collection.time_until_attack <= 0 then
            data.time_until_attack = attack_right_flow.add({type = 'label', caption = {'stateful.nom'}})
        else
            data.time_until_attack = attack_right_flow.add({type = 'label', caption = time_left})
        end

        if collection.time_until_attack <= 0 then
            local survive_for_left_flow = objective_tbl.add({type = 'flow'})
            survive_for_left_flow.style.horizontal_align = 'left'
            survive_for_left_flow.style.horizontally_stretchable = true

            survive_for_left_flow.add({type = 'label', caption = {'stateful.survive_for'}})
            frame.add({type = 'line', direction = 'vertical'})
            local survive_for_right_flow = objective_tbl.add({type = 'flow'})
            survive_for_right_flow.style.horizontal_align = 'right'
            survive_for_right_flow.style.horizontally_stretchable = true

            local survive_for_timer = floor(collection.survive_for / 60 / 60) .. 'm'

            if collection.survive_for / 60 / 60 <= 0 then
                survive_for_timer = floor(collection.survive_for / 60) .. 's'
            end

            if collection.survive_for <= 0 then
                data.survive_for = survive_for_right_flow.add({type = 'label', caption = {'stateful.won'}})
            else
                data.survive_for = survive_for_right_flow.add({type = 'label', caption = survive_for_timer})
            end
        end
        -- new frame
        local biter_sprites_tbl = objective_tbl.add({type = 'flow'})
        biter_sprites_tbl.style.horizontal_align = 'left'
        biter_sprites_tbl.style.horizontally_stretchable = true

        biter_sprites_tbl.add({type = 'label', caption = {'stateful.biter_sprites'}})
    else
        local objective_tbl = frame.add {type = 'table', column_count = 2}
        objective_tbl.style.horizontally_stretchable = true

        local game_won_left_flow = objective_tbl.add({type = 'flow'})
        game_won_left_flow.style.horizontal_align = 'left'
        game_won_left_flow.style.horizontally_stretchable = true

        game_won_left_flow.add({type = 'label', caption = {'stateful.game_won'}})
    end

    local close = frame.add({type = 'button', name = close_button, caption = 'Close'})
    close.style.horizontally_stretchable = true
    Gui.set_data(frame, data)
end

local function refresh_boss_frame()
    Core.iter_connected_players(
        function(player)
            boss_frame(player)
        end
    )
end

local function main_frame(player)
    local main_player_frame = player.gui.screen[main_frame_name]
    if main_player_frame then
        Gui.remove_data_recursively(main_player_frame)
        main_player_frame.destroy()
    end

    local data = {}

    local stateful = Public.get_stateful()
    local breached_wall = Public.get('breached_wall')
    breached_wall = breached_wall - 1
    local wave_number = WD.get('wave_number')

    local frame = player.gui.screen.add {type = 'frame', name = main_frame_name, caption = {'stateful.win_conditions'}, direction = 'vertical', tooltip = {'stateful.win_conditions_tooltip'}}
    frame.location = {x = 1, y = 45}
    frame.style.maximal_height = 500
    frame.style.minimal_width = 200
    frame.style.maximal_width = 400
    local rounds_survived_tbl = frame.add {type = 'table', column_count = 2}
    rounds_survived_tbl.style.horizontally_stretchable = true

    local rounds_survived_left_flow = rounds_survived_tbl.add({type = 'flow'})
    rounds_survived_left_flow.style.horizontal_align = 'left'
    rounds_survived_left_flow.style.horizontally_stretchable = true

    rounds_survived_left_flow.add({type = 'label', caption = {'stateful.rounds_survived'}, tooltip = {'stateful.rounds_survived_tooltip'}})
    frame.add({type = 'line', direction = 'vertical'})
    local rounds_survived_right_flow = rounds_survived_tbl.add({type = 'flow'})
    rounds_survived_right_flow.style.horizontal_align = 'right'
    rounds_survived_right_flow.style.horizontally_stretchable = true

    data.rounds_survived_label = rounds_survived_right_flow.add({type = 'label', caption = stateful.rounds_survived})
    spacer(frame)

    frame.add({type = 'line'})

    spacer(frame)

    if stateful.objectives_completed.boss_time then
        local objective_tbl = frame.add {type = 'table', column_count = 2}
        objective_tbl.style.horizontally_stretchable = true

        local gather_warning_flow = objective_tbl.add({type = 'flow'})
        gather_warning_flow.style.horizontal_align = 'left'
        gather_warning_flow.style.horizontally_stretchable = true

        gather_warning_flow.add({type = 'label', caption = {'stateful.gather'}})
        frame.add({type = 'line', direction = 'vertical'})

        local warn_timer_flow_left = objective_tbl.add({type = 'flow'})
        warn_timer_flow_left.style.horizontal_align = 'left'
        warn_timer_flow_left.style.horizontally_stretchable = true

        warn_timer_flow_left.add({type = 'label', caption = {'stateful.warp'}, tooltip = {'stateful.warp_tooltip'}})
        frame.add({type = 'line', direction = 'vertical'})

        local warn_timer_flow_right = objective_tbl.add({type = 'flow'})
        warn_timer_flow_right.style.horizontal_align = 'right'
        warn_timer_flow_right.style.horizontally_stretchable = true

        local time_left = floor(stateful.collection.gather_time / 60 / 60) .. 'm'

        if stateful.collection.gather_time / 60 / 60 <= 0 then
            time_left = floor(stateful.collection.gather_time / 60) .. 's'
        end

        data.gather_time_label = warn_timer_flow_right.add({type = 'label', caption = time_left})
    else
        local objective_tbl = frame.add {type = 'table', column_count = 2}
        objective_tbl.style.horizontally_stretchable = true

        local zone_left_flow = objective_tbl.add({type = 'flow'})
        zone_left_flow.style.horizontal_align = 'left'
        zone_left_flow.style.horizontally_stretchable = true

        zone_left_flow.add({type = 'label', caption = {'stateful.zone'}, tooltip = {'stateful.zone_tooltip'}})
        frame.add({type = 'line', direction = 'vertical'})
        local zone_right_flow = objective_tbl.add({type = 'flow'})
        zone_right_flow.style.horizontal_align = 'right'
        zone_right_flow.style.horizontally_stretchable = true

        if breached_wall >= stateful.objectives.randomized_zone then
            data.randomized_zone_label = zone_right_flow.add({type = 'label', caption = breached_wall .. '/' .. stateful.objectives.randomized_zone .. ' [img=utility/check_mark_green]', tooltip = {'stateful.tooltip_completed'}})
        else
            data.randomized_zone_label = zone_right_flow.add({type = 'label', caption = breached_wall .. '/' .. stateful.objectives.randomized_zone .. ' [img=utility/not_available]', tooltip = {'stateful.tooltip_not_completed'}})
        end

        -- new frame
        local wave_left_flow = objective_tbl.add({type = 'flow'})
        wave_left_flow.style.horizontal_align = 'left'
        wave_left_flow.style.horizontally_stretchable = true

        wave_left_flow.add({type = 'label', caption = {'stateful.wave'}, tooltip = {'stateful.wave_tooltip'}})
        frame.add({type = 'line', direction = 'vertical'})
        local wave_right_flow = objective_tbl.add({type = 'flow'})
        wave_right_flow.style.horizontal_align = 'right'
        wave_right_flow.style.horizontally_stretchable = true

        if wave_number >= stateful.objectives.randomized_wave then
            data.randomized_wave_label = wave_right_flow.add({type = 'label', caption = wave_number .. '/' .. stateful.objectives.randomized_wave .. ' [img=utility/check_mark_green]', tooltip = {'stateful.tooltip_completed'}})
        else
            local randomized_wave = wave_right_flow.add({type = 'label', caption = wave_number .. '/' .. stateful.objectives.randomized_wave .. ' [img=utility/not_available]', tooltip = {'stateful.tooltip_not_completed'}})
            data.randomized_wave_label = randomized_wave
        end

        --dynamic conditions

        for index = 1, #stateful.selected_objectives do
            local objective = stateful.selected_objectives[index]
            objective_frames(stateful, frame, objective, data)
        end
    end

    -- warn players
    spacer(frame)
    frame.add({type = 'line'})
    spacer(frame)
    local final_label = frame.add({type = 'label', caption = {'stateful.tooltip_final'}})
    final_label.style.single_line = false
    spacer(frame)
    frame.add({type = 'line'})
    spacer(frame)

    local close = frame.add({type = 'button', name = close_button, caption = 'Close'})
    close.style.horizontally_stretchable = true
    Gui.set_data(frame, data)
end

local function update_data()
    local players = game.connected_players
    local stateful = Public.get_stateful()
    local breached_wall = Public.get('breached_wall')
    local wave_number = WD.get('wave_number')
    local collection = stateful.collection
    local supplies = stateful.objectives.supplies
    local single_item = stateful.objectives.single_item
    local callback_token = stateful.objectives.locomotive_market_selection[1]
    local callback_data = stateful.objectives.locomotive_market_selection[2]
    local callback_locomotive = Token.get(callback_token)
    local locomotive_completed, _, locale_right = callback_locomotive(callback_data)

    for i = 1, #players do
        local player = players[i]
        local f = player.gui.screen[main_frame_name]
        local b = player.gui.screen[boss_frame_name]
        local data = Gui.get_data(f)
        local data_boss = Gui.get_data(b)

        if data then
            if data.rounds_survived and data.rounds_survived.valid then
                data.rounds_survived.caption = stateful.rounds_survived
            end
            if data.randomized_zone_label and data.randomized_zone_label.valid then
                breached_wall = breached_wall - 1
                if breached_wall >= stateful.objectives.randomized_zone then
                    data.randomized_zone_label.caption = breached_wall .. '/' .. stateful.objectives.randomized_zone .. ' [img=utility/check_mark_green]'
                    if not stateful.objectives_completed.randomized_zone_label then
                        stateful.objectives_completed.randomized_zone_label = true
                        play_achievement_unlocked()
                    end
                else
                    data.randomized_zone_label.caption = breached_wall .. '/' .. stateful.objectives.randomized_zone .. ' [img=utility/not_available]'
                end
            end

            if data.randomized_wave_label and data.randomized_wave_label.valid then
                if wave_number >= stateful.objectives.randomized_wave then
                    data.randomized_wave_label.caption = wave_number .. '/' .. stateful.objectives.randomized_wave .. ' [img=utility/check_mark_green]'
                    if not stateful.objectives_completed.randomized_wave_label then
                        stateful.objectives_completed.randomized_wave_label = true
                        play_achievement_unlocked()
                    end
                else
                    data.randomized_wave_label.caption = wave_number .. '/' .. stateful.objectives.randomized_wave .. ' [img=utility/not_available]'
                end
            end

            if data.supply and next(data.supply) then
                local items_done = 0
                for index = 1, #data.supply do
                    local frame = data.supply[index]
                    if frame and frame.valid then
                        local supplies_data = supplies[index]
                        if supplies_data.count == 0 then
                            items_done = items_done + 1
                            frame.number = nil
                            frame.sprite = 'utility/check_mark_green'
                        else
                            frame.number = supplies_data.count
                        end
                        if items_done == 3 then
                            if data.supply_completed and data.supply_completed.valid then
                                data.supply_completed.caption = ' [img=utility/check_mark_green]'
                                if not stateful.objectives_completed.supplies then
                                    stateful.objectives_completed.supplies = true
                                    play_achievement_unlocked()
                                end
                            end
                        end
                    end
                end
            end

            if data.single_item and data.single_item.valid then
                local frame = data.single_item
                if single_item.count == 0 then
                    frame.number = nil
                    frame.sprite = 'utility/check_mark_green'
                    if not stateful.objectives_completed.single_item then
                        stateful.objectives_completed.single_item = true
                        play_achievement_unlocked()
                    end
                else
                    frame.number = single_item.count
                end
            end

            if data.locomotive_market and data.locomotive_market.valid then
                data.locomotive_market.caption = locale_right
                if locomotive_completed and not stateful.objectives_completed.locomotive_market then
                    stateful.objectives_completed.locomotive_market = true
                    play_achievement_unlocked()
                end
            end

            if data.gather_time_label and data.gather_time_label.valid then
                local time_left = floor(stateful.collection.gather_time / 60 / 60) .. 'm'

                if stateful.collection.gather_time / 60 / 60 <= 0 then
                    time_left = floor(stateful.collection.gather_time / 60) .. 's'
                end
                data.gather_time_label.caption = time_left
            end

            if data.random_objectives and next(data.random_objectives) then
                for index = 1, #data.random_objectives do
                    local frame_data = data.random_objectives[index]
                    local name = frame_data.name
                    local frame = frame_data.frame
                    for objective_index = 1, #stateful.selected_objectives do
                        local objective = stateful.selected_objectives[objective_index]
                        local objective_name = objective[1]
                        local callback = Token.get(objective[2])
                        local completed, _, objective_locale_right = callback()
                        if name == objective_name and frame and frame.valid then
                            frame.caption = objective_locale_right
                            if completed and not stateful.objectives_completed[objective_name] then
                                stateful.objectives_completed[objective_name] = true
                                play_achievement_unlocked()
                            end
                        end
                    end
                end
            end
        end
        if data_boss then
            if data_boss.time_until_attack and data_boss.time_until_attack.valid then
                local time_left = floor(collection.time_until_attack / 60 / 60) .. 'm'
                if collection.time_until_attack / 60 / 60 < 1 then
                    time_left = floor(collection.time_until_attack / 60) .. 's'
                end

                if collection.time_until_attack <= 0 then
                    data_boss.time_until_attack.caption = {'stateful.nom'}
                    if not stateful.objectives_completed.warn_players then
                        stateful.objectives_completed.warn_players = true
                        alert_players_sound()
                        refresh_boss_frame()
                    end
                else
                    data_boss.time_until_attack.caption = time_left
                end
            end
            if data_boss.survive_for and data_boss.survive_for.valid then
                local survive_for_timer = floor(collection.survive_for / 60 / 60) .. 'm'

                if collection.survive_for / 60 / 60 <= 1 then
                    survive_for_timer = floor(collection.survive_for / 60) .. 's'
                end

                if collection.survive_for <= 0 then
                    data_boss.survive_for.caption = {'stateful.won'}
                else
                    data_boss.survive_for.caption = survive_for_timer
                end
            end
        end
    end
end

local function update_raw()
    local stateful = Public.get_stateful()
    local breached_wall = Public.get('breached_wall')
    local wave_number = WD.get('wave_number')
    local collection = stateful.collection
    local tick = game.tick
    local supplies = stateful.objectives.supplies
    local single_item = stateful.objectives.single_item
    local callback_token = stateful.objectives.locomotive_market_selection[1]
    local callback_data = stateful.objectives.locomotive_market_selection[2]
    local callback_locomotive = Token.get(callback_token)
    local locomotive_completed, _, _ = callback_locomotive(callback_data)

    breached_wall = breached_wall - 1
    if breached_wall >= stateful.objectives.randomized_zone then
        if not stateful.objectives_completed.randomized_zone_label then
            stateful.objectives_completed.randomized_zone_label = true
            play_achievement_unlocked()
            Server.to_discord_embed('Objective: **breach zone** has been complete!')
            stateful.objectives_completed_count = stateful.objectives_completed_count + 1
        end
    end

    if wave_number >= stateful.objectives.randomized_wave then
        if not stateful.objectives_completed.randomized_wave_label then
            stateful.objectives_completed.randomized_wave_label = true
            play_achievement_unlocked()
            Server.to_discord_embed('Objective: **survive until wave** has been complete!')
            stateful.objectives_completed_count = stateful.objectives_completed_count + 1
        end
    end

    if supplies and next(supplies) then
        local items_done = 0
        for index = 1, #supplies do
            local supplies_data = supplies[index]
            if supplies_data.count == 0 then
                items_done = items_done + 1
            end
            if items_done == 3 then
                if not stateful.objectives_completed.supplies then
                    stateful.objectives_completed.supplies = true
                    Server.to_discord_embed('Objective: **produce 3 items multiple times** has been complete!')
                    play_achievement_unlocked()
                    stateful.objectives_completed_count = stateful.objectives_completed_count + 1
                end
            end
        end
    end

    if single_item and single_item.count == 0 then
        if not stateful.objectives_completed.single_item then
            stateful.objectives_completed.single_item = true
            play_achievement_unlocked()
            Server.to_discord_embed('Objective: **produce an item multiple times** has been completed!')
            stateful.objectives_completed_count = stateful.objectives_completed_count + 1
        end
    end

    if collection.time_until_attack then
        collection.time_until_attack = collection.time_until_attack_timer - tick
        if collection.time_until_attack > 0 then
            collection.time_until_attack = collection.time_until_attack
        elseif collection.time_until_attack and collection.time_until_attack < 0 then
            collection.time_until_attack = 0
            if not collection.nuke_blueprint then
                collection.nuke_blueprint = true
                Public.stateful_blueprints.nuke_blueprint()
                refresh_boss_frame()
            end
        end
    end
    if collection.survive_for and collection.survive_for_timer then
        collection.survive_for = collection.survive_for_timer - tick
        if not collection.survive_for_alerted and collection.time_until_attack == 0 then
            collection.survive_for_alerted = true
            refresh_boss_frame()
        end
        if collection.survive_for > 0 then
            collection.survive_for = collection.survive_for
        elseif collection.survive_for and collection.survive_for < 0 then
            collection.survive_for = 0
            if collection.game_won and not collection.game_won_notified then
                collection.game_won_notified = true
                refresh_boss_frame()
                play_game_won()
                local locomotive = Public.get('locomotive')
                if locomotive and locomotive.valid then
                    locomotive.surface.spill_item_stack(locomotive.position, {name = 'coin', count = 512}, false)
                    Public.set('game_reset_tick', 5400)
                end
            end
        end
    end

    if locomotive_completed then
        if not stateful.objectives_completed.locomotive_market then
            stateful.objectives_completed.locomotive_market = true
            Server.to_discord_embed('Objective: **locomotive purchase** has been completed!')
            play_achievement_unlocked()
            stateful.objectives_completed_count = stateful.objectives_completed_count + 1
        end
    end

    for objective_index = 1, #stateful.selected_objectives do
        local objective = stateful.selected_objectives[objective_index]
        local objective_name = objective[1]
        local callback = Token.get(objective[2])
        local completed, _, _ = callback()
        if completed and completed == true and not stateful.objectives_completed[objective_name] then
            stateful.objectives_completed[objective_name] = true
            Server.to_discord_embed('Objective: **' .. objective_name .. '** has been completed!')
            play_achievement_unlocked()
            stateful.objectives_completed_count = stateful.objectives_completed_count + 1
        end
    end

    if stateful.collection.gather_time and tick >= stateful.collection.gather_time then
        stateful.collection.final_battle = true
        Public.set('final_battle', true)
    end

    if stateful.objectives_completed_count == 5 and not stateful.objectives_completed.boss_time then
        stateful.objectives_completed.boss_time = true
        Server.to_discord_embed('All objectives has been completed!')
        stateful.collection.gather_time = tick + 54000
        play_achievement_unlocked()

        Core.iter_connected_players(
            function(player)
                local frame = player.gui.screen[main_frame_name]
                if frame then
                    Gui.remove_data_recursively(frame)
                    frame.destroy()
                    boss_frame(player)
                end
            end
        )
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not player then
        return
    end

    if not player.gui.top[main_button_name] then
        create_button(player)
    end
end

Gui.on_click(
    main_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Mtn v3 open stateful Button')
        if is_spamming then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        local final_battle = Public.get_stateful('final_battle')

        if final_battle then
            local frame = player.gui.screen[boss_frame_name]
            if frame then
                Gui.remove_data_recursively(frame)
                frame.destroy()
            else
                Gui.clear_all_active_frames(player)
                boss_frame(player)
            end
        else
            local frame = player.gui.screen[main_frame_name]
            if frame then
                Gui.remove_data_recursively(frame)
                frame.destroy()
            else
                Gui.clear_all_active_frames(player)
                main_frame(player)
            end
        end
    end
)

Gui.on_click(
    close_button,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Mtn v3 close stateful Button')
        if is_spamming then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        local frame = player.gui.screen[main_frame_name]

        if frame then
            Gui.remove_data_recursively(frame)
            frame.destroy()
        end

        local frame_boss = player.gui.screen[boss_frame_name]

        if frame_boss then
            Gui.remove_data_recursively(frame_boss)
            frame_boss.destroy()
        end
    end
)

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.on_nth_tick(60, update_data)
Event.on_nth_tick(120, update_raw)

Public.boss_frame = boss_frame

return Public
