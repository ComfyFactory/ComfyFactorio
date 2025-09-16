local Discord = require 'utils.discord'
local Server = require 'utils.server'
local Public = {}

local notification = Discord.channel_names.scenario_notifications

--- Send a parsed message to the named discord channel.
--- Requires at least a title and a description
---@param data table
function Public.send_notification(data)
    if not data or not data.title or not data.description then
        return error("Title and description is required.", 2)
    end

    if game.tick < 10 then return end

    data.tick = game.tick

    Server.to_discord_named_parsed_embed(notification, data)
end

--- Send a parsed message to the connected channel.
--- Requires at least a title and a description
---@param data table
function Public.send_notification_connected_channel(data)
    if not data or not data.title or not data.description then
        return error("Title and description is required.", 2)
    end

    if game.tick < 10 then return end

    data.tick = game.tick

    Server.to_discord_embed_parsed(data)
end

--- Send a message to the connected channel.
--- Requires a title and a description
---@param scenario_name string|nil
---@param message string
function Public.send_notification_raw(scenario_name, message)
    if not scenario_name then
        scenario_name = Server.get_server_name() or 'CommandHandler'
    end

    if not message then
        return error('A message is required.', 2)
    end
    local data = table.concat({ '**[', scenario_name, ']**', ' - ', message })
    Server.to_discord_named_embed(notification, data)
end

function Public.send_notification_debug(player, source_debug, debug_data)
    local name = player and player.valid and player.name or 'script'

    local data =
    {
        title = Server.get_server_name(),
        description = source_debug,
        fields =
        {
            {
                title = 'Debug data for: ' .. name,
                description = debug_data
            }
        }
    }
    Public.send_notification(data)
end

return Public
