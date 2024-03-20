-- This file simply exists to reduce the amount of require that is done

local Token = require 'utils.token'
local Task = require 'utils.task'
local Alert = require 'utils.alert'

local Public = {}

Public.register = Token.register
Public.get = Token.get

Public.set_timeout_in_ticks = Task.set_timeout_in_ticks
Public.set_timeout_in_ticks_text = Task.set_timeout_in_ticks_text
Public.set_timeout = Task.set_timeout
Public.queue_task = Task.queue_task
Public.get_queue_speed = Task.get_queue_speed
Public.set_queue_speed = Task.set_queue_speed

Public.delay = Task.queue_task
Public.priority_delay = Task.set_timeout_in_ticks

local delay_print_alert_token =
    Token.register(
    function(event)
        local text = event.text
        if not text then
            return
        end

        local ttl = event.ttl
        if not ttl then
            ttl = 60
        end

        local sprite = event.sprite
        local color = event.color

        Alert.alert_all_players(ttl, text, color, sprite, 1)
    end
)

Public.set_timeout_in_ticks_alert = function(delay, data)
    if not data then
        return error('Data was not provided', 2)
    end
    if type(data) ~= 'table' then
        return error("Data must be of type 'table'", 2)
    end

    if not delay then
        return error('No delay was provided', 2)
    end

    Task.set_timeout_in_ticks(delay, delay_print_alert_token, data)
end

return Public
