local Public = {}

local table_insert = table.insert

local FFATable = require 'modules.scrap_towny_ffa.ffa_table'

local function on_player_dropped_item(event)
	local player = game.players[event.player_index]
	if not player or not player.valid then
		return
	end
	local entity = event.entity
	if entity.name ~= 'item-on-ground' then
		return
	end

	-- only if outlander or rogue
	local force = player.force
	if force.name ~= 'player' and force.name ~= 'rogue' then
		return
	end

	local surface = entity.surface
	local position = entity.position

	-- is there enough fish to make a stink?
	local found = 0
	local required = 20
	local entities = surface.find_entities_filtered({position = position, radius = 3, name = 'item-on-ground'})
	for _, e in pairs(entities) do
		if e.stack.name == 'raw-fish' then
			found = found + 1
		end
	end

	if found >= required then
		-- sufficient fish, remove them
		for _, e in pairs(entities) do
			if e.stack.name == 'raw-fish' and found > 0 then
				e.destroy()
				found = found - 1
			end
		end
		-- set the scent
		local ffatable = FFATable.get_table()
		if not ffatable.fish_mounds then
			ffatable.fish_mounds = {}
		end
		surface.create_decoratives({check_collision = true, decoratives = {
			{name = "enemy-decal", position = position, amount = 2},
			{name = "shroom-decal", position = position, amount = 2},
			{name = "worms-decal", position = position, amount = 1}
		}})
		table_insert(ffatable.fish_mounds, position)
	end

end


local Event = require 'utils.event'
Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)

return Public