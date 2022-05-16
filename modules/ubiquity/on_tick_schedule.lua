local Table = require 'modules.ubiquity.table'

local function on_tick()
	local ubitable = Table.get_table()
	if not ubitable.on_tick_schedule[game.tick] then
		return
	end
	for _, schedule in pairs(ubitable.on_tick_schedule[game.tick]) do
		schedule.func(unpack(schedule.args))
	end
	ubitable.on_tick_schedule[game.tick] = nil
end

local on_init = function()
	local ffatable = Table.get_table()
	ffatable.on_tick_schedule = {}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
