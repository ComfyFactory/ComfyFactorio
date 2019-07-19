-- too many same entities close together will explode 

local event = require 'utils.event'
local math_random = math.random
require 'utils.table'

local search_radius = 6
local explosions = {"explosion", "explosion", "explosion", "medium-explosion", "uranium-cannon-explosion"}

local default_limit = 2
local entity_limits = {
	["transport-belt"] = 7,
	["inserter"] = 3,
	["underground-belt"] = 3,
	["electric-pole"] = 2,
	["assembling-machine"] = 2
}

local function error_message()
	local errors = {"spaghett", "not found", "cat", "error", "not enough", "pylons", "out of", "limit reached", "void",
	"balance", "operation", "alert", "not responding", "angry", "sad", "not working", "can not compute", "unstable location", "invalid",
	"gearwheel", "malfunction", "unknown", "can not", "wrong", "dog", "ocelot", "failure", "division by", "zero", "bathwater", "faulty", "conveyor", "too many"
	}
	table.shuffle_table(errors)
	local message = table.concat({errors[1], " ", errors[2], " ", errors[3], "!"})
	return message
end

local function count_same_entities(entity)
	local same_entity_count = 0
	for _, e in pairs(entity.surface.find_entities_filtered({name = entity.name, area = {{entity.position.x - search_radius, entity.position.y - search_radius},{entity.position.x + search_radius, entity.position.y + search_radius}}})) do
		if entity.name == e.name and entity.direction == e.direction then
			same_entity_count = same_entity_count + 1
		end
	end
	return same_entity_count
end

local function spaghett(surface, entity, inventory, player)
	local limit = entity_limits[entity.type]
	if not limit then limit = 2 end	
	if count_same_entities(entity) > limit then
		inventory.insert({name = entity.name, count = 1})
		surface.create_entity({name = explosions[math_random(1, #explosions)], position = entity.position})
		entity.die("player")
		if player then
			if not global.last_spaghett_error then global.last_spaghett_error = {} end
			if not global.last_spaghett_error[player.index] then global.last_spaghett_error[player.index] = 0 end
			if game.tick - global.last_spaghett_error[player.index] > 180 then
				game.print(error_message(), {r = math.random(200, 255), g = math.random(150, 200), b = math.random(150, 200)})
				global.last_spaghett_error[player.index] = game.tick
			end
		end
	end
end

local function on_built_entity(event)
	spaghett(event.created_entity.surface, event.created_entity, game.players[event.player_index].get_main_inventory(), game.players[event.player_index])
end

local function on_player_rotated_entity(event)
	spaghett(event.entity.surface, event.entity, game.players[event.player_index].get_main_inventory(), game.players[event.player_index])
end

local function on_robot_built_entity(event)
	spaghett(event.robot.surface, event.created_entity, event.robot.get_inventory(defines.inventory.robot_cargo))
end

event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)