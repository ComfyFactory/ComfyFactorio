--created by Gerkiz
local Public = require 'maps.infestation_islands.core'
local Event = require 'utils.event'
local Func = Public.functions
local Scheduler = require 'utils.scheduler'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Server = require 'utils.server'
local Gui = require 'utils.gui'

local stage_gui_name = Gui.uid()
local random = math.random

if not script.active_mods.quality then
    error('Quality mod is not enabled!')
end

if not script.active_mods['space-age'] then
    error('Space Age mod is not enabled!')
end

local function reset_player(player)
    if player.character and player.character.valid then
        player.character.destroy()
    end
    player.clear_items_inside()
    if player.connected then
        player.set_controller({ type = defines.controllers.god })
        player.create_character()
        if player.character ~= nil then
            player.character.destructible = true
        end
        player.insert({ name = 'raw-fish', count = 3 })
        player.insert({ name = 'grenade', count = 1 })
        player.insert({ name = 'iron-plate', count = 16 })
        player.insert({ name = 'iron-gear-wheel', count = 8 })
        player.insert({ name = 'stone', count = 5 })
        player.insert({ name = 'pistol', count = 1 })
        player.insert({ name = 'firearm-magazine', count = 16 })
    else
        if player.character then
            player.character.destructible = true
        end
        if player.character ~= nil then
            player.character.destroy()
        end
        game.remove_offline_players({ player.index })
    end
end

local reset_players_token =
    Scheduler.register_function(
        'reset_players_token',
        function ()
            local surface = game.get_surface(1)

            for _, f in pairs(game.forces) do
                f.reset()
                f.clear_chart(surface)
                f.reset_evolution()
            end
            for _, tech in pairs(game.forces.player.technologies) do
                tech.researched = false
                tech.saved_progress = 0
            end

            local players = game.players
            for i = 1, #players do
                local player = players[i]
                if player and player.valid then
                    reset_player(player)
                end
            end
        end
    )

local function get_top_frame(player, id)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player)[id]
    else
        return player.gui.top[id]
    end
end

local function create_stage_gui(player)
    local button = get_top_frame(player, stage_gui_name)
    if button and button.valid then button.destroy() end

    if Gui.get_mod_gui_top_frame() then
        local element =
            Gui.add_mod_button(
                player,
                {
                    type = 'frame',
                    name = stage_gui_name,
                }
            )
        if element and element.valid then
            local style = element.style

            style.minimal_height = 36
            style.maximal_height = 36
            style.padding = 0
            local label = element.add({ type = 'label', caption = ' ', name = 'label' })
            label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
            label.style.font = 'heading-1'
        end
    else
        local element = player.gui.top.add({ type = 'frame', name = stage_gui_name, caption = ' ' })
        if element and element.valid then
            local style = element.style
            style.padding = 0

            local label = element.add({ type = 'label', caption = ' ', name = 'label' })
            label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
            label.style.font = 'heading-1'
        end
    end
end

local function update_stage_gui()
    local this = Public.get()
    if not this.stages then
        return
    end

    local stages = this.stages
    local stage = math.min(this.current_level, #stages - 1)
    local time, _, half = Public.normalize_time_until_next_island_is_created()
    local islands_data = Public.get('islands_data')
    local island_data = islands_data[stage]
    local caption_parts =
    {
        ('Level: %d/%d'):format(stage, #stages - 1)
    }

    local tooltip
    local random_quality = Public.qualities[random(1, #Public.qualities)]
    local has_biters = island_data and island_data.ready
    local island_complete = has_biters and island_data.completed
    local can_auto_generate = (
        this.auto_generate_upon_idle and
        has_biters and
        island_complete and
        this.time_until_next_island_is_created and
        this.time_until_next_island_is_created > game.tick and
        Difficulty.has_votes_ended()
    )

    local attack_grace_period = Public.get('attack_grace_period')
    if attack_grace_period then
        attack_grace_period = math.round((attack_grace_period - game.tick) / 60, 0)
        if attack_grace_period < 0 then
            attack_grace_period = '\n\n[color=yellow]The biters are marching towards the market![/color]'
        else
            attack_grace_period = '\n\nThe biters will attack in ' .. attack_grace_period .. ' seconds'
        end
    else
        attack_grace_period = ''
    end

    local waves_sent = ''
    if island_data.wave_count then
        waves_sent = '\n[color=yellow]They have sent ' .. island_data.wave_count .. ' wave(s) so far.[/color]'
        if island_data.wave_level_evolution and island_data.wave_level_evolution > this.current_level then
            waves_sent = waves_sent .. '\n[color=yellow]They are getting stronger.[/color]'
        end
    end

    if island_data.pause_waves then
        local time_until_ancestors = math.round((island_data.pause_waves - game.tick) / 60 / 60, 0)
        if time_until_ancestors > 0 then
            time_until_ancestors = time_until_ancestors .. ' minutes'
        else
            time_until_ancestors = math.round((island_data.pause_waves - game.tick) / 60, 0)
            if time_until_ancestors < 0 then
                time_until_ancestors = 'imminent'
            else
                time_until_ancestors = time_until_ancestors .. ' seconds'
            end
        end
        table.insert(caption_parts, (' | [entity=behemoth-biter,quality=%s] Ancestors in: %s'):format(random_quality, time_until_ancestors))
        tooltip = ('The biters ancestors are rising to finish what they started. Quickly kill the remaining %d biters before they rise!'):format(this.alive_enemies)
    elseif not has_biters then
        table.insert(caption_parts, ' | Generating...')
        tooltip = 'The biters are still generating on the island. Please wait for them to finish.'
    elseif can_auto_generate then
        table.insert(caption_parts, ' | Level cleared!')
        table.insert(caption_parts, (' | [entity=small-biter,quality=%s]: %s'):format(random_quality, time))
        tooltip = ('The next island will be generated in %s.\nThe bridge for next island will be generated in %s.\n\n' ..
            'Unless you progress to the next island, it will be generated automatically.\n\n' ..
            'If you do not progress to the next island, you will not be able to reroll the next island market if the bridge also generates.\n\n' ..
            'Market rerolls are unlocked when you manually progress to the next island.'):format(half, time)
    elseif island_complete then
        table.insert(caption_parts, ' | Level cleared!')
        tooltip = ('Defenses would sure be helpful right now.\nVotes close in %d seconds.'):format(Difficulty.get_closing_timeout())
    elseif this.auto_generate_upon_idle and island_data and island_data.auto_generated_bridge == false then
        table.insert(caption_parts, (' | Bugs remaining: %d | [entity=small-biter,quality=%s]: %s'):format(
            this.alive_enemies, random_quality, time))
        tooltip = ('The bridge to the next island will be generated in %s.\nUnless you progress to the next island, it will be generated automatically.\n' ..
            'Market rerolls will be removed for the next island if the bridge is auto-generated.\nMarket rerolls are unlocked when you manually progress to the next island.'):format(time)
    else
        table.insert(caption_parts, (' | Bugs remaining: %d'):format(this.alive_enemies))
        tooltip = ('Vanquish the biters to capture the island. %d biters remaining.%s%s'):format(this.alive_enemies, attack_grace_period, waves_sent)
    end

    local caption = this.top_label_caption_override or table.concat(caption_parts)

    for _, player in pairs(game.connected_players) do
        local frame = get_top_frame(player, stage_gui_name)
        if frame and frame.valid and frame.label and frame.label.valid then
            frame.label.caption = caption
            frame.label.tooltip = tooltip
        end
    end
end


local function drift_corpses_toward_beach()
    if not Public.get('drift_corpses_toward_beach_enabled') then
        return
    end
    local surface = game.surfaces[1]
    for _, corpse in pairs(surface.find_entities_filtered({ name = 'character-corpse' })) do
        if corpse.position.y < 0 then
            if surface.get_tile(corpse.position.x, corpse.position.y).collides_with('resource') then
                corpse.clone
                {
                    position = { corpse.position.x, corpse.position.y + (math.random(50, 250) * 0.01) },
                    surface = surface,
                    force = corpse.force.name
                }
                corpse.destroy()
            end
        end
    end
end

local function clear_surface()
    local surface = game.get_surface(1)
    surface.clear()

    local planet = game.planets['nauvis']
    local platforms = planet.get_space_platforms('player')
    if platforms then
        for _, platform in pairs(platforms) do
            if platform and platform.valid then
                platform.destroy()
            end
        end
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    create_stage_gui(player)

    update_stage_gui()

    if player.online_time == 0 then
        reset_player(player)
        return
    end

    Difficulty.difficulty_gui()
end

local function has_the_game_ended(this)
    if (this.game_lost or this.game_won) and this.game_reset_tick then
        if this.game_reset_tick < 0 then
            return
        end

        game.forces.enemy.set_friend('player', true)
        game.forces.enemy.set_cease_fire('player', true)
        game.forces.player.set_friend('enemy', true)
        game.forces.player.set_cease_fire('enemy', true)

        this.game_reset_tick = this.game_reset_tick - 1
        if this.game_reset_tick % 600 == 0 then
            if this.game_reset_tick > 0 then
                local cause_msg
                if this.restart then
                    cause_msg = 'restart'
                elseif this.shutdown then
                    cause_msg = 'shutdown'
                elseif this.soft_reset then
                    cause_msg = 'soft-reset'
                end

                local message = 'Game will ' .. cause_msg .. ' in ' .. this.game_reset_tick / 60 .. ' seconds!'

                game.print(message, { color = { r = 0.22, g = 0.88, b = 0.22 } })
            end

            if this.soft_reset and this.game_reset_tick == 0 then
                if this.render_ammo_text then
                    this.render_ammo_text.destroy()
                    this.render_ammo_text = nil
                end
                if this.ammo_chest and this.ammo_chest.valid then
                    this.ammo_chest.destroy()
                    this.ammo_chest = nil
                end

                for _, market_data in pairs(this.islands_data) do
                    if market_data and market_data.market and market_data.market.valid then
                        if market_data.render_protect_text then
                            market_data.render_protect_text.destroy()
                            market_data.render_protect_text = nil
                        end
                        if market_data.render_checkpoint_text then
                            market_data.render_checkpoint_text.destroy()
                            market_data.render_checkpoint_text = nil
                        end
                        if market_data.chart_tag then
                            market_data.chart_tag.destroy()
                            market_data.chart_tag = nil
                        end
                        market_data.market.destroy()
                        market_data.market = nil
                    end
                end

                this.game_reset_tick = nil
                this.game_lost = false
                this.game_won = false
                Scheduler.clear_tasks()
                clear_surface()
                Public.on_init()
                Scheduler.new(500, reset_players_token)
                return
            end

            if this.restart and this.game_reset_tick == 0 then
                if not this.announced_message then
                    local message = 'Soft-reset is disabled! Server will restart from scenario to load new changes.'
                    game.print(message, { color = { r = 0.22, g = 0.88, b = 0.22 } })
                    Server.to_discord_bold(table.concat { '*** ', message, ' ***' })
                    Server.start_scenario('Infestation_Islands')
                    this.announced_message = true
                    return
                end
            end
            if this.shutdown and this.game_reset_tick == 0 then
                if not this.announced_message then
                    local message = 'Soft-reset is disabled! Server will shutdown. Most likely because of updates.'
                    game.print(message, { color = { r = 0.22, g = 0.88, b = 0.22 } })
                    Server.to_discord_bold(message)
                    Server.stop_scenario()
                    this.announced_message = true
                    return
                end
            end
        end
    end
end

local function on_tick()
    local this = Public.get()
    local island_data = this.islands_data and this.islands_data[this.current_level]
    local tick = game.tick

    if this.delayed_messages[tick] then
        game.print(this.delayed_messages[tick])
        this.delayed_messages[tick] = nil
    end

    if tick % 25 == 0 then
        Func.check_alive_enemies()
    end

    has_the_game_ended(this)

    if tick % 40 == 0 and this.auto_generate_upon_idle then
        if island_data and Difficulty.has_votes_ended() then
            local _, time = Public.normalize_time_until_next_island_is_created()

            if island_data.completed then
                if not this.time_until_next_island_is_created then
                    local difficulty_index = Difficulty.get('index')
                    local hour
                    if difficulty_index == 1 then
                        hour = random(60, 120)
                    elseif difficulty_index == 2 then
                        hour = random(30, 60)
                    elseif difficulty_index == 3 then
                        hour = random(15, 30)
                    end

                    this.time_until_next_island_is_created = tick + (60 * 60 * hour * this.current_level)
                    this.time_until_next_island_is_created_static = math.round((this.time_until_next_island_is_created - tick) / 60 / 60, 0)

                    if _DEBUG then
                        this.time_until_next_island_is_created = tick + (60 * 60 * 10)
                        this.time_until_next_island_is_created_static = math.round((this.time_until_next_island_is_created - tick) / 60 / 60, 0)
                    end
                    return
                end

                local time_limit = this.time_until_next_island_is_created_static / 2

                -- spawn the island before the time limit is reached
                if time <= time_limit then
                    if not island_data.auto_generated_island then
                        island_data.auto_generated_island = true
                        game.print(Public.island_keeper .. 'The biters are getting hungry!!!', { color = { r = 0.88, g = 0.22, b = 0.22 } })
                        Scheduler.new(1, Public.init_next_island_without_bridge_token):set_data({ surface = game.surfaces[1] })
                    end
                end
            else
                -- spawn the island after the time limit is reached
                if time <= 0 then
                    if not (island_data and island_data.auto_generated_bridge) then
                        island_data.auto_generated_bridge = true
                        island_data.parent_level = nil
                        game.print(Public.island_keeper .. 'The biters are forming a bridge to our island! They are coming!!!', { color = { r = 0.88, g = 0.22, b = 0.22 } })
                        Scheduler.new(1, Public.do_generate_bridge_token):set_data({ surface = game.surfaces[1], reroll_enabled = false })
                        this.time_until_next_island_is_created = nil
                    end
                end
            end
        end
    end

    if tick % 50 == 0 then
        update_stage_gui()
        if this.game_lost then return end

        local position = island_data and island_data.position or { x = 0, y = 0 }
        local radius = island_data and island_data.radius or 0

        game.forces.player.chart(game.surfaces[1], { { position.x - radius, position.y - radius }, { position.x + radius, position.y + radius } })

        Func.is_rocket_silo_alive()

        Func.check_vote_status()
    end

    if tick % this.infinite_ammo_tick == 0 then
        drift_corpses_toward_beach()
        if this.ammo_chest and this.ammo_chest.valid then
            local magazine_name = 'firearm-magazine'
            if this.piercing_ammo_grants then
                magazine_name = 'piercing-rounds-magazine'
            end
            if this.uranium_ammo_grants then
                magazine_name = 'uranium-rounds-magazine'
            end

            this.ammo_chest.insert({ name = magazine_name, count = this.infinite_ammo_grants or 1 })
        end
    end

    if tick % 100 == 0 then
        if not this.game_lost then
            Func.check_afk_players()
            if Difficulty.has_votes_ended() and not this.difficulty_vote_ended then
                this.difficulty_vote_ended = true
                game.print(Public.island_keeper .. 'The difficulty vote has ended! You may now progress to the next island!', { color = { r = 0.22, g = 0.88, b = 0.22 } })
                Server.to_discord_embed('** The difficulty vote has ended! You may now progress to the next island! **')
                game.print(Public.island_keeper .. 'The difficulty is ' .. Difficulty.get('name') .. '!', { color = Difficulty.get('print_color') })
                Server.to_discord_embed('** The difficulty is ' .. Difficulty.get('name') .. '! **')
            end
        end
    end

    if tick % 200 == 0 then
        if not (this.game_lost and island_data.completed and this.disable_multi_command_attack) and island_data.bridge_generated then
            Func.do_buried_biters()
        end
    end

    if tick % 500 == 0 then
        Func.update_evolution_static()
    end

    if tick % 800 == 0 then
        Func.send_biters_to_market()
    end

    if this.clear_items_on_ground_state then
        if tick % 450 == 0 then
            Func.do_clear_items_on_ground_slowly()
        end

        if tick % 4500 == 0 then
            Func.run_clear_items_on_ground()
        end
    end

    if tick % 1000 == 0 then
        Func.check_chart_tags()
        Func.check_spawners_without_units()
    end
    if tick % 1500 == 0 then
        Func.slowly_kill_spawners_without_units()
    end

    if tick % 10000 == 0 then
        Func.set_multi_command()
    end
end

local handle_changes = function ()
    Public.set('restart', true)
    Public.set('soft_reset', false)
    Server.output_script_data('Received new changes from backend.')
end

Server.on_scenario_changed(
    'Infestation_Islands',
    function (data)
        local scenario = data.scenario
        if scenario == 'Infestation_Islands' then
            handle_changes()
        end
    end
)

Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
