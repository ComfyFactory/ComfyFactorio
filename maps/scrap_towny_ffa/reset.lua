local Event = require 'utils.event'
local Server = require 'utils.server'
local Alert = require 'utils.alert'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Nauvis = require 'maps.scrap_towny_ffa.nauvis'
local Team = require 'maps.scrap_towny_ffa.team'
local Player = require 'maps.scrap_towny_ffa.player'
local Color = require 'utils.color_presets'
local table_insert = table.insert

-- game duration in ticks
-- 7d * 24h * 60m * 60s * 60t
-- local game_duration = 36288000
local game_duration = 36288000
local armageddon_duration = 3600
local warning_duration = 600
local mapkeeper = '[color=blue]Mapkeeper:[/color]'

local function on_rocket_launched(event)
    local this = ScenarioTable.get()
    local rocket = event.rocket
    local tick = event.tick
    local force_index = rocket.force.index
    table_insert(this.rocket_launches, {force_index = force_index, tick = tick})
end

local function get_victorious_force()
    local this = ScenarioTable.get_table()
    if this.rocket_launches then
        for _, launch in pairs(this.rocket_launches) do
            local force = game.forces[launch.force_index]
            if force.valid then
                return force.name
            end
        end
    end
    return nil
end

local function warning()
    Alert.alert_all_players(5, 'The world is ending!', Color.white, 'warning-white', 1.0)
end

local function armageddon()
    if not get_victorious_force() then
        Nauvis.armageddon()
    end
end

local function do_soft_reset()
    local this = ScenarioTable.get_table()
    for _, player in pairs(game.players) do
        local frame = this.score_gui_frame[player.index]
        if frame and frame.valid then
            frame.destroy()
        end
    end
    this.game_reset_tick = nil
    this.game_won = false
    ScenarioTable.reset_table()
    local surface = game.surfaces['nauvis']
    if get_victorious_force() then
        surface.play_sound({path = 'utility/game_won', volume_modifier = 1})
    else
        surface.play_sound({path = 'utility/game_lost', volume_modifier = 1})
    end
    game.reset_time_played()
    game.reset_game_state()
    for _, player in pairs(game.players) do
        player.teleport({0, 0}, game.surfaces['limbo'])
    end
    Nauvis.initialize()
    Team.initialize()
    if game.forces['rogue'] == nil then
        log('rogue force is missing!')
    end
    for _, player in pairs(game.players) do
        Player.increment()
        Player.initialize(player)
        Team.set_player_color(player)
        Player.spawn(player)
        Player.load_buffs(player)
        Player.requests(player)
    end

    Alert.alert_all_players(5, 'The world has been reset!', Color.white, 'restart_required', 1.0)
    game.print('The world has been reset!', {r = 0.22, g = 0.88, b = 0.22})

    Server.to_discord_embed('*** The world has been reset! ***')
end

local function has_the_game_ended()
    local game_reset_tick = ScenarioTable.get('game_reset_tick')
    if game_reset_tick then
        if game_reset_tick < 0 then
            return
        end

        local this = ScenarioTable.get_table()

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
                do_soft_reset()
                return
            end

            if this.restart and this.game_reset_tick == 0 then
                if not this.announced_message then
                    game.print(({'entity.notify_restart'}), {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Soft-reset is disabled! Server will restart from scenario to load new changes.'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.start_scenario('Towny')
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

local function on_tick()
    local tick = game.tick
    if tick > 0 then
        if tick % 40 == 0 then
            local game_won = ScenarioTable.get('game_won')
            if game_won then
                has_the_game_ended()
            end
        end

        if (tick + armageddon_duration + warning_duration) % game_duration == 0 then
            warning()
        end
        if (tick + armageddon_duration) % game_duration == 0 then
            armageddon()
        end
        if (tick + 1) % game_duration == 0 then
            Nauvis.clear_nuke_schedule()
            Team.reset_all_forces()
        end
        if tick % game_duration == 0 then
            has_the_game_ended()
        end
    end
end

commands.add_command(
    'scenario',
    'Usable only for admins - controls the scenario!',
    function(cmd)
        local p
        local player = game.player

        if not player or not player.valid then
            p = log
        else
            p = player.print
            if not player.admin then
                return
            end
        end

        local this = ScenarioTable.get_table()
        local param = cmd.parameter

        if param == 'restart' or param == 'shutdown' or param == 'reset' or param == 'restartscenario' then
            goto continue
        else
            p('[ERROR] Arguments are:\nrestart\nshutdown\nreset\nrestartscenario')
            return
        end

        ::continue::

        if not this.reset_are_you_sure then
            this.reset_are_you_sure = true
            p('[WARNING] This command will disable the soft-reset feature, run this command again if you really want to do this!')
            return
        end

        if param == 'restart' then
            if this.restart then
                this.reset_are_you_sure = nil
                this.restart = false
                this.soft_reset = true
                p('[SUCCESS] Soft-reset is enabled.')
                return
            else
                this.reset_are_you_sure = nil
                this.restart = true
                this.soft_reset = false
                if this.shutdown then
                    this.shutdown = false
                end
                p('[WARNING] Soft-reset is disabled! Server will restart from scenario to load new changes.')
                return
            end
        elseif param == 'restartscenario' then
            this.reset_are_you_sure = nil
            Server.start_scenario('Towny')
            return
        elseif param == 'shutdown' then
            if this.shutdown then
                this.reset_are_you_sure = nil
                this.shutdown = false
                this.soft_reset = true
                p('[SUCCESS] Soft-reset is enabled.')
                return
            else
                this.reset_are_you_sure = nil
                this.shutdown = true
                this.soft_reset = false
                if this.restart then
                    this.restart = false
                end
                p('[WARNING] Soft-reset is disabled! Server will shutdown. Most likely because of updates.')
                return
            end
        elseif param == 'reset' then
            this.reset_are_you_sure = nil
            if player and player.valid then
                game.print(mapkeeper .. ' ' .. player.name .. ', has reset the game!', {r = 0.98, g = 0.66, b = 0.22})
            else
                game.print(mapkeeper .. ' server, has reset the game!', {r = 0.98, g = 0.66, b = 0.22})
            end
            do_soft_reset()
            p('[WARNING] Game has been reset!')
            return
        end
    end
)

Event.on_nth_tick(10, on_tick)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)