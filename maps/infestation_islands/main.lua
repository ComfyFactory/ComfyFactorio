--created by Gerkiz
local Public = require 'maps.infestation_islands.core'
local Event = require 'utils.event'
local Func = Public.func
local Task = require 'utils.task_token'
local Scheduler = require 'utils.scheduler'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Server = require 'utils.server'

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
        if not player.character then
            player.set_controller({ type = defines.controllers.god })
            player.create_character()
        end
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
    Task.register(
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
                reset_player(player)
            end
        end
    )

local function create_stage_gui(player)
    if player.gui.top.stage_gui then
        return
    end
    local element = player.gui.top.add({ type = 'frame', name = 'stage_gui', caption = ' ' })
    local style = element.style
    style.minimal_height = 54
    style.maximal_height = 54
    style.minimal_width = 140
    style.maximal_width = 420
    style.top_padding = 12
    style.left_padding = 4
    style.right_padding = 4
    style.bottom_padding = 2
    style.font_color = { r = 155, g = 85, b = 25 }
    style.font = 'default-large-bold'
end

local function update_stage_gui(caption_override)
    local this = Public.get()
    if not this.stages then
        return
    end
    local caption = 'Level: ' .. this.current_level
    caption = caption .. '  |  Stage: '
    local stage = this.current_stage
    if stage > #this.stages - 1 then
        stage = #this.stages - 1
    end
    caption = caption .. stage
    caption = caption .. '/'
    caption = caption .. #this.stages - 1
    if this.alive_enemies == 0 then
        caption = caption .. '  |  Level cleared!'
    else
        caption = caption .. '  |  Bugs remaining: '
        caption = caption .. this.alive_enemies
    end

    for _, player in pairs(game.connected_players) do
        if player.gui.top.stage_gui then
            player.gui.top.stage_gui.caption = caption_override or caption
        end
    end
end

local function bring_players()
    local surface = game.surfaces[1]
    for _, player in pairs(game.connected_players) do
        if player.position.y < -1 then
            if player.character then
                if player.character.valid then
                    local p = surface.find_non_colliding_position('character', { 0, 2 }, 8, 0.5)
                    if not p then
                        player.teleport({ 0, 2 }, surface)
                    else
                        player.teleport(p, surface)
                    end
                end
            end
        end
    end
    local this = Public.get()
    this.gamestate = 2
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

local gamestate_functions =
{
    [1] = bring_players,
    [2] = Func.draw_main_island,
}

local function has_the_game_ended(this)
    if (this.game_lost or this.game_won) and this.game_reset_tick then
        if this.game_reset_tick < 0 then
            return
        end

        game.forces.enemy.set_friend('player', true)
        game.forces.player.set_friend('enemy', true)

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

                for _, market_data in pairs(this.spawned_markets) do
                    if market_data and market_data.market and market_data.market.valid then
                        if market_data.render_protect_text then
                            market_data.render_protect_text.destroy()
                            market_data.render_protect_text = nil
                        end
                        if market_data.render_checkpoint_text then
                            market_data.render_checkpoint_text.destroy()
                            market_data.render_checkpoint_text = nil
                        end
                        market_data.market.destroy()
                    end
                end

                this.game_reset_tick = nil
                this.game_lost = false
                this.game_won = false
                Scheduler.can_run_scheduler(false)
                clear_surface()
                Public.on_init()
                Task.set_timeout_in_ticks(500, reset_players_token)
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
    if game.tick % 25 == 0 and gamestate_functions[this.gamestate] then
        gamestate_functions[this.gamestate]()
    end
    if game.tick % 25 == 0 then
        if this.alive_enemies < 0 then this.alive_enemies = 0 end
        if this.game_lost then
            local message = this.nomed_marked and 'The bugs had a feast on the marked at level ' .. this.nomed_marked .. '!' or 'The bugs had a feast on the marked!'
            update_stage_gui(message)
        else
            update_stage_gui()
        end
        if not this.game_lost then
            if Difficulty.has_votes_ended() and not this.difficulty_vote_ended then
                this.difficulty_vote_ended = true
                game.print('The difficulty vote has ended! You may now progress to the next island!', { color = { r = 0.22, g = 0.88, b = 0.22 } })
                Server.to_discord_embed('** The difficulty vote has ended! You may now progress to the next island! **')
                game.print('The difficulty is ' .. Difficulty.get('name') .. '!', { color = Difficulty.get('print_color') })
                Server.to_discord_embed('** The difficulty is ' .. Difficulty.get('name') .. '! **')
            end
        end
    end

    local infinite_ammo_tick = Public.get('infinite_ammo_tick')
    if game.tick % infinite_ammo_tick == 0 then
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

    if game.tick % 150 == 0 then
        if this.game_lost then return end

        Func.is_rocket_silo_alive()

        local center_position = this.centered_points[this.current_level]
        if not center_position then
            center_position =
            {
                position = { x = 0, y = 0 }
            }
        end
        game.forces.player.chart(game.surfaces[1], { { center_position.position.x - 124, center_position.position.y - 124 }, { center_position.position.x + 124, center_position.position.y + 124 } })

        Func.check_alive_enemies()
        Func.set_multi_command()
        if not this.completed_levels[this.current_level] then
            Func.do_buried_biters()
        end
    end

    if game.tick % 500 == 0 then
        Func.update_evolution_static()
    end

    if this.clear_items_on_ground_state then
        if game.tick % 450 == 0 then
            Func.do_clear_items_on_ground_slowly()
        end

        if game.tick % 4500 == 0 then
            Func.run_clear_items_on_ground()
        end
    end

    has_the_game_ended(this)
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
