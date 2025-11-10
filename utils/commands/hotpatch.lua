local Commands = require 'utils.commands'
local Server = require 'utils.server'
local Task = require 'utils.task_token'
local Global = require 'utils.global'

local hotpatch = '[color=yellow]Hotpatch:[/color] '
local halt_after_timer = 60 * 60 * 1 -- 1 minute

local this = {}

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
                game.print(hotpatch .. 'To abort the hotpatch, use the command /save-hot-patch-abort.')
            end
        end
    )

Commands.new('save-hot-patch', 'Tries to hotpatch the current save from the panel if possible.')
    :require_admin()
    :require_backend()
    :require_validation('Running this will stop the server and hotpatch, only run this if you really want to!')
    :callback(
        function (player)
            if not this.halt_after then
                this.halt_after = game.tick + halt_after_timer
                game.print(hotpatch .. 'Save hot-patching has been initiated by ' .. player.name .. '.')
                game.print(hotpatch .. 'The server will be stopped, hotpatched and resumed in ' .. math.round(halt_after_timer / 60, 0) .. ' seconds.')
                Task.set_duration_task(500, halt_after_timer, save_hot_patch_notify_token, {})
                Task.set_timeout_in_ticks(halt_after_timer, save_hot_patch_token)
            else
                player.print(hotpatch .. 'A hotpatch is already in progress.')
                return false
            end
        end
    )

Commands.new('save-hot-patch-abort', 'Aborts the hotpatch if it is in progress.')
    :require_admin()
    :require_backend()
    :callback(
        function (player)
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
