local Public = {}

-- one table to rule them all!
local Global = require 'utils.global'
local ubitable = {}
Global.register(
		ubitable,
		function(tbl)
			ubitable = tbl
		end
)

function Public.reset_table()
	for k, _ in pairs(ubitable) do
		ubitable[k] = nil
	end
end

function Public.get_table()
	return ubitable
end

function Public.get(key)
	if key then
		return ubitable[key]
	else
		return ubitable
	end
end

function Public.set(key, value)
	if key and (value or value == false) then
		ubitable[key] = value
		return ubitable[key]
	elseif key then
		return ubitable[key]
	else
		return ubitable
	end
end

local on_init = function()
	Public.reset_table()
end

local Event = require 'utils.event'
Event.on_init(on_init)

return Public
