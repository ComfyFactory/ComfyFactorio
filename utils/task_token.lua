-- This file simply exists to reduce the amount of require that is done

local Token = require 'utils.token'
local Task = require 'utils.task'

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

return Public
