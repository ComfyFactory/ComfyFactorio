--Central to add all player modifiers together.

local modifiers = {
	"character_build_distance_bonus",
	"character_crafting_speed_modifier",
	"character_health_bonus",
	"character_inventory_slots_bonus",
	"character_item_drop_distance_bonus",
	"character_item_pickup_distance_bonus",
	"character_loot_pickup_distance_bonus",
	"character_mining_speed_modifier",
	"character_reach_distance_bonus",
	"character_resource_reach_distance_bonus",
	"character_running_speed_modifier",
}

function update_player_modifiers(player)
	for _, modifier in pairs(modifiers) do
		local sum_value = 0
		for _, value in pairs(global.player_modifiers[player.index][modifier]) do
			sum_value = sum_value + value
		end
		if player.character then
			player[modifier] = sum_value
		end
	end
end

local function on_player_joined_game(event)
	if global.player_modifiers[event.player_index] then return end
	global.player_modifiers[event.player_index] = {}
	for _, modifier in pairs(modifiers) do
		global.player_modifiers[event.player_index][modifier] = {}
	end
end

local function on_init(event)
	global.player_modifiers = {}
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_joined_game, on_player_joined_game)