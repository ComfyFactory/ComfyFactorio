local Discord = require 'utils.discord'
local Server = require 'utils.server'
local Public = {}

local notification = Discord.channel_names.scenario_notifications

--- Send a parsed message to the connected channel.
--- Requires at least a title and a description
---@param ... table
function Public.send_notification(...)
    local data = ...
    if not data.title or not data.description then
        return error('Title and description is required.', 2)
    end

    local text = {
        title = data.title,
        description = data.description,
        color = data.color or 'success'
    }

    if data.field1 and data.field1.text1 and data.field1.text2 then
        text.field1 = {
            text1 = data.field1.text1,
            text2 = data.field1.text2,
            inline = data.field1.inline or 'true'
        }
    end

    if data.field2 and data.field2.text1 and data.field2.text2 then
        text.field2 = {
            text1 = data.field2.text1,
            text2 = data.field2.text2,
            inline = 'true',
            emptyField = 'true',
            emptyInline = 'true'
        }
    end

    if data.field3 and data.field3.text1 and data.field3.text2 then
        text.field3 = {
            text1 = data.field3.text1,
            text2 = data.field3.text2,
            inline = 'true'
        }
    end

    if data.field4 and data.field4.text1 and data.field4.text2 then
        text.field4 = {
            text1 = data.field4.text1,
            text2 = data.field4.text2,
            inline = 'true',
            emptyField = 'true',
            emptyInline = 'true'
        }
    end

    if data.field5 and data.field5.text1 and data.field5.text2 then
        text.field5 = {
            text1 = data.field5.text1,
            text2 = data.field5.text2,
            inline = 'true'
        }
    end

    if data.field6 and data.field6.text1 and data.field6.text2 then
        text.field6 = {
            text1 = data.field6.text1,
            text2 = data.field6.text2,
            inline = 'true',
            emptyField = 'true',
            emptyInline = 'true'
        }
    end

    if data.field7 and data.field7.text1 and data.field7.text2 then
        text.field7 = {
            text1 = data.field7.text1,
            text2 = data.field7.text2,
            inline = 'true'
        }
    end

    if data.field8 and data.field8.text1 and data.field8.text2 then
        text.field8 = {
            text1 = data.field8.text1,
            text2 = data.field8.text2,
            inline = 'true',
            emptyField = 'true',
            emptyInline = 'true'
        }
    end

    Server.to_discord_named_parsed_embed(notification, text)
end

--- Send a parsed message to the connected channel.
--- Requires at least a title and a description
---@param ... table
function Public.send_notification_obj(...)
    local data = ...
    if not data.title or not data.description then
        return error('Title and description is required.', 2)
    end

    Server.to_discord_named_parsed_embed(notification, data)
end

--- Send a message to the connected channel.
--- Requires a title and a description
---@param scenario_name string
---@param message string
function Public.send_notification_raw(scenario_name, message)
    if not scenario_name then
        return error('A scenario name is required.', 2)
    end

    if not message then
        return error('A message is required.', 2)
    end
    local data = table.concat({'**[', scenario_name, ']**', ' - ', message})
    Server.to_discord_named_embed(notification, data)
end

function Public.send_notification_debug(player, source_debug, debug_data)
    local name = player and player.valid and player.name or 'script'

    local data = {
        title = Server.get_server_name(),
        description = source_debug,
        field1 = {
            text1 = 'Debug data for: ' .. name,
            text2 = debug_data
        }
    }
    Public.send_notification(data)
end

return Public
