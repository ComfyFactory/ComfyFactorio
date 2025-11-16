local Commands = require 'utils.commands'
local Server = require 'utils.server'
local Task = require 'utils.task_token'
local Global = require 'utils.global'

local hotpatch = '[color=yellow]Hotpatch:[/color] '

local this =
{
    halt_after_timer = 60 * 60 * 1 -- 1 minute
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local save_hot_patch_token = Task.register(
    function ()
        if this.halted then
            this.halted = nil
            return
        end
        this.halt_after = nil
        this.halted = nil

        Server.save_hot_patch()
    end
)

local save_hot_patch_notify_token =
    Task.register(
        function (event)
            if not this.halt_after then
                event.exit = true
                return
            end

            local time_left = math.round((this.halt_after - game.tick) / 60, 0)

            if game.tick % 500 == 0 then
                if time_left < 0 then
                    event.exit = true
                    return
                end

                game.print(hotpatch .. 'The server will be stopped in ' .. time_left .. ' seconds.')
                game.print(hotpatch .. 'To abort the hotpatch, use the command /abort-patch-save.')
            end
        end
    )

Commands.new('patch-save', 'Tries to hotpatch the current save from the panel if possible.')
    :require_admin()
    :add_alias('ps')
    :add_alias('hot-patch')
    :require_backend()
    :add_parameter('halt_after', true, 'number')
    :require_validation('Running this will stop the server and hotpatch, only run this if you really want to!')
    :callback(
        function (player, halt_after)
            if halt_after then
                if halt_after == 0 then
                    this.halt_after_timer = 60
                elseif halt_after < 1 then
                    player.print(hotpatch .. 'Halt after time cannot be less than 1 minute.')
                    return false
                elseif halt_after > 60 then
                    player.print(hotpatch .. 'Halt after time cannot be greater than 60 minutes.')
                    return false
                end

                if not this.halt_after_timer == 60 then
                    this.halt_after_timer = 60 * 60 * halt_after
                end
            end

            if not this.halt_after then
                this.halt_after = game.tick + this.halt_after_timer
                game.print(hotpatch .. 'Save hot-patching has been initiated by ' .. player.name .. '.')
                game.print(hotpatch .. 'The server will be stopped, hotpatched and resumed in ' .. math.round(this.halt_after_timer / 60, 0) .. ' seconds.')
                Task.set_duration_task(500, this.halt_after_timer, save_hot_patch_notify_token, {})
                Task.set_timeout_in_ticks(this.halt_after_timer, save_hot_patch_token)
            else
                player.print(hotpatch .. 'A hotpatch is already in progress.')
                return false
            end
        end
    )

Commands.new('abort-patch-save', 'Aborts the hotpatch if it is in progress.')
    :require_admin()
    :require_backend()
    :add_alias('aps')
    :add_alias('hot-patch-abort')
    :callback(
        function (player)
            this.halt_after_timer = 60 * 60 * 1

            if not this.halted and this.halt_after then
                game.print(hotpatch .. 'Hotpatch has been aborted by ' .. player.name .. '.')
                this.halted = true
                this.halt_after = nil
                return true
            end

            player.print(hotpatch .. 'No hotpatch is in progress.')
            return false
        end
    )
