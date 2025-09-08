local Event = require 'utils.event'
local Server = require 'utils.server'
local Discord = require 'utils.discord_handler'

local commands =
{
    ['editor'] = true,
    ['open'] = true,
    ['cheat'] = true,
    ['permissions'] = true,
    ['banlist'] = true,
    ['config'] = true,
    ['command'] = true,
    ['silent-command'] = true,
    ['sc'] = true,
    ['debug'] = true
}

local title_to_command =
{
    ['editor'] = "Editor",
    ['open'] = "Open",
    ['cheat'] = "Cheat",
    ['permissions'] = "Permissions",
    ['banlist'] = "Banlist",
    ['config'] = "Config",
    ['command'] = "Command",
    ['silent-command'] = "Silent Command",
    ['sc'] = "Silent Command",
    ['debug'] = "Debug"
}


local function on_console_command(event)
    local cmd = event.command
    if not commands[cmd] then
        return
    end

    -- Handle player vs server executor
    local player, executor
    if event.player_index then
        player = game.get_player(event.player_index)
        if not (player and player.admin) then
            return
        end
        executor = player.name
    else
        executor = "Server"
    end

    local param = (event.parameters and event.parameters ~= "" and event.parameters) or "No parameters"
    local server_name = Server.get_server_name() or "CommandHandler"

    Discord.send_notification(
        {
            title = title_to_command[cmd],
            description = "/" .. cmd .. " was used",
            color = "warning",
            fields =
            {
                {
                    title = "Server",
                    description = server_name,
                    inline = "false"
                },
                {
                    title = "By",
                    description = executor,
                    inline = "true"
                },
                {
                    title = "Details",
                    description = param,
                    inline = "true"
                }
            }
        })
end

Event.add(defines.events.on_console_command, on_console_command)

Event.add(
    defines.events.on_player_promoted,
    function (event)
        local admins = Server.get_admins_data()
        local player = game.get_player(event.player_index)
        local server_name = Server.get_server_name() or 'CommandHandler'

        Discord.send_notification(
            {
                title = "Admin promotion",
                description = player.name .. " was promoted.",
                color = "success",
                fields =
                {
                    {
                        title = "Server",
                        description = server_name,
                        inline = "false"
                    }
                }
            })

        if not game.is_multiplayer() then
            return
        end

        if not admins[player.name] then
            player.admin = false
            return
        end
    end
)
Event.add(
    defines.events.on_player_demoted,
    function (event)
        local player = game.get_player(event.player_index)
        local server_name = Server.get_server_name() or 'CommandHandler'

        Discord.send_notification(
            {
                title = "Admin demotion",
                description = player.name .. " was demoted.",
                color = "warning",
                fields =
                {
                    {
                        title = "Server",
                        description = server_name,
                        inline = "false"
                    }
                }
            })
    end
)

Event.add(
    defines.events.on_player_kicked,
    function (event)
        local player = game.get_player(event.player_index)
        local server_name = Server.get_server_name() or 'CommandHandler'

        Discord.send_notification(
            {
                title = "Player kicked",
                description = player.name .. " was kicked.",
                color = "danger",
                fields =
                {
                    {
                        title = "Server",
                        description = server_name,
                        inline = "false"
                    }
                }
            })
    end
)
