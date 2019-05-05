local biter_waves = require "maps.wave_of_death.biter_waves"
local ai = {}

ai.spawn_wave = function(surface, lane_number, wave_number, amount_modifier)	
	local is_spread_wave = true
	if amount_modifier == 1 then is_spread_wave = false end
	
	if not global.loaders[lane_number].valid then return end
	
	local spawn_position = {x = global.loaders[lane_number].position.x, y = global.loaders[lane_number].position.y - 288}
	
	local unit_group = surface.create_unit_group({position = spawn_position, force = "enemy"})
	
	for _, biter_type in pairs(biter_waves[wave_number]) do
		for count = 1, math.floor(biter_type.amount * amount_modifier), 1 do
			local pos = surface.find_non_colliding_position(biter_type.name, spawn_position, 96, 3)
			local biter = surface.create_entity({name = biter_type.name, position = pos, force = "enemy"})
			global.wod_biters[biter.unit_number] = {entity = biter, lane_number = lane_number, spread_wave = is_spread_wave}
			unit_group.add_member(biter)
			if not is_spread_wave then
				global.wod_lane[lane_number].alive_biters = global.wod_lane[lane_number].alive_biters + 1
			end
		end
	end
	
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = {
			{
				type = defines.command.attack_area,
				destination = global.loaders[lane_number].position,
				radius = 32,
				distraction=defines.distraction.by_enemy
			},									
			{
				type = defines.command.attack,
				target = global.loaders[lane_number],
				distraction = defines.distraction.by_enemy
			}
		}
	})
	
	if is_spread_wave then return end
	global.wod_lane[lane_number].current_wave = global.wod_lane[lane_number].current_wave + 1
	global.biter_evasion_health_increase_factor = global.biter_evasion_health_increase_factor + 0.005
end

--on_entity_died event
ai.spawn_spread_wave = function(event)  
	local entity = event.entity
	if not entity.unit_number then return end
	if not global.wod_biters[entity.unit_number] then return end
	if global.wod_biters[entity.unit_number].spread_wave then global.wod_biters[entity.unit_number] = nil return end

	local trigger_lane_number = global.wod_biters[entity.unit_number].lane_number

	global.wod_lane[trigger_lane_number].alive_biters = global.wod_lane[trigger_lane_number].alive_biters - 1
	if global.wod_lane[trigger_lane_number].alive_biters ~= 0 then return end

	for lane_number = 1, 4, 1 do
		if lane_number ~= trigger_lane_number then
			ai.spawn_wave(entity.surface, lane_number, global.wod_lane[trigger_lane_number].current_wave - 1, global.spread_amount_modifier)	
		end
	end

	game.print("Lane #" .. trigger_lane_number .. " has defeated their wave.")
end

--on_entity_rotated event
ai.trigger_new_wave = function(event)
	local entity = event.entity
	if entity.name ~= "loader" then return end
	local lane_number = tonumber(entity.force.name)
	if not global.wod_lane[lane_number] then return end
	if global.wod_lane[lane_number].alive_biters > 0 then
		entity.force.print("There are " .. global.wod_lane[lane_number].alive_biters .. " spawned biters left.", {r = 180, g = 0, b = 0})
		return 
	end

	local wave_number = global.wod_lane[lane_number].current_wave
	if not biter_waves[wave_number] then wave_number = #biter_waves end
    ai.spawn_wave(entity.surface, lane_number, wave_number, 1)
	
	for _, player in pairs(game.connected_players) do
		player.play_sound{path="utility/new_objective", volume_modifier=0.3} --dont know if a sound would be annoying in a game with 10 lanes playing ^^ maybe a short sound
	end
	game.print("Lane " .. entity.force.name .. " has summoned wave #" .. global.wod_lane[lane_number].current_wave - 1)	
end

return ai