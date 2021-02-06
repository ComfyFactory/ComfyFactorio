local Public = {}

function Public.reset()
	for index = 1, #game.forces, 1 do
		local force = game.forces[index]
		force.clear_chart("nauvis")
	end
end

--local Event = require 'utils.event'
--Event.add(defines.events.on_chunk_charted, on_chunk_charted)

return Public