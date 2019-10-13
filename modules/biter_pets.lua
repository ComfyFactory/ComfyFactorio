local math_random = math.random
local nom_msg = {"munch", "yum"}

local function tame_unit_effects(player, entity)
	local position = {x = entity.position.x - 0.75, y = entity.position.y - 1}
	local b = 1.35
	for a = 1, 7, 1 do
		local p = {(position.x + 0.4) + (b * -1 + math_random(0, b * 20) * 0.1), position.y + (b * -1 + math_random(0, b * 20) * 0.1)}			
		player.surface.create_entity({name = "flying-text", position = p, text = "♥", color = {math_random(150, 255), 0, 255}})						
	end
	
	rendering.draw_text{
		text = "~" .. player.name .. "'s pet~",
		surface = player.surface,
		target = entity,
		target_offset = {0, -2.5},
		color = {
			r = player.color.r * 0.6 + 0.25,
			g = player.color.g * 0.6 + 0.25,
			b = player.color.b * 0.6 + 0.25,
			a = 1
		},
		scale = 1.10,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
end

local function tame_unit(player, entity)
	local units = player.surface.find_entities_filtered({type = "unit", area = {{entity.position.x - 1, entity.position.y - 1},{entity.position.x + 1, entity.position.y + 1}}, limit = 1})
	if not units[1] then return end
	entity.destroy()
	game.print(math.floor(units[1].prototype.max_health * 0.01) + 1)
	if math_random(1, math.floor(units[1].prototype.max_health * 0.01) + 1) ~= 1 then
		player.surface.create_entity({name = "flying-text", position = units[1].position, text = nom_msg[math_random(1, #nom_msg)], color = {math_random(50, 100), 0, 255}})
		return
	end
	if units[1].force.index == player.force.index then return end
	units[1].ai_settings.allow_destroy_when_commands_fail = false
	units[1].ai_settings.allow_try_return_to_spawner = false
	units[1].force = player.force
	units[1].set_command({type = defines.command.wander, distraction = defines.distraction.by_enemy})	
	global.biter_pets[player.index] = {last_command = 0, entity = units[1]}
	tame_unit_effects(player, units[1])
	return true
end

local function command_unit(entity, player)
	if (player.position.x - entity.position.x) ^ 2 + (player.position.y - entity.position.y) ^ 2 < 256 then
		entity.set_command({type = defines.command.wander, distraction = defines.distraction.by_enemy})
	else
		entity.set_command({type = defines.command.go_to_location, destination_entity = player.character, radius = 5, distraction = defines.distraction.by_damage})
	end
end

local function on_player_changed_position(event)
	if math_random(1, 32) ~= 1 then return end
	local player = game.players[event.player_index]
	if not global.biter_pets[player.index] then return end	
	if not global.biter_pets[player.index].entity then global.biter_pets[player.index] = nil return end
	if not global.biter_pets[player.index].entity.valid then global.biter_pets[player.index] = nil return end
	if not player.character then return end
	if global.biter_pets[player.index].last_command + 600 > game.tick then return end
	global.biter_pets[player.index].last_command = game.tick
	command_unit(global.biter_pets[player.index].entity, player)	
end

local function on_player_dropped_item(event)
	local player = game.players[event.player_index]
	if global.biter_pets[player.index] then return end
	if event.entity.stack.name ~= "raw-fish" then return end
	tame_unit(player, event.entity)	
end

local function on_init(event)
	global.biter_pets = {}
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
event.add(defines.events.on_player_changed_position, on_player_changed_position)