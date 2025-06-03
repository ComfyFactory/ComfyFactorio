local Event = require 'utils.event'
local Global = require 'utils.global'
local Util = require 'utils.core'
local Task = require 'utils.task_token'

local this =
{
	death_tags = {}
}

Global.register(
	this,
	function (tbl)
		this = tbl
	end
)

local add_corpse_marker_token =
	Task.register(
		function (event)
			local player_index = event.player_index
			local player = game.get_player(player_index)
			if not player or not player.valid then
				return
			end

			local ents = player.surface.find_entities_filtered
				{
					name = 'character-corpse',
					position = player.position,
					radius = 5,
				}

			if #ents == 0 then
				return
			end
			local entity = ents[1]

			if not entity or not entity.valid then
				return
			end

			player.add_pin
			{
				entity = entity,
			}
		end
	)


Event.add(defines.events.on_pre_player_died, function (event)
	local player = game.get_player(event.player_index)
	if not player and not player.valid then
		return
	end

	if not player.has_items_inside() then
		return
	end

	local surface = player.surface

	Util.iter_players(function (p)
		if p.physical_surface_index == surface.index then
			Task.set_timeout_in_ticks(10, add_corpse_marker_token, { player_index = p.index })
		end
	end)
end)
