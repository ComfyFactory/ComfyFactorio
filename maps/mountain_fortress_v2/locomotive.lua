function locomotive_spawn(surface, position)
	for y = -6, 6, 2 do
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	global.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -3}, force = "player"})
	global.locomotive.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 100})
	
	global.locomotive_cargo = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 3}, force = "player"})
	global.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 4000})
	
	global.locomotive.color = {0, 255, 0}
	global.locomotive.minable = false
	global.locomotive_cargo.minable = false
	global.locomotive_cargo.operable = false
end

local function accelerate()
	local driver = global.locomotive.get_driver()
	if driver then return	end	
	global.locomotive_driver = global.locomotive.surface.create_entity({name = "character", position = global.locomotive.position, force = "player"})
	global.locomotive_driver.driving = true
	global.locomotive_driver.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight}
end

local function remove_acceleration()
	if global.locomotive_driver then global.locomotive_driver.destroy() end
end

local function set_player_spawn()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	local position = global.locomotive_cargo.surface.find_non_colliding_position("stone-furnace", global.locomotive_cargo.position, 16, 2)
	if not position then return end
	game.forces.player.set_spawn_position({x = position.x, y = position.y}, global.locomotive_cargo.surface)
end

local function set_player_spawn_and_refill_fish()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	global.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 4000})
	local position = global.locomotive_cargo.surface.find_non_colliding_position("stone-furnace", global.locomotive_cargo.position, 16, 2)
	if not position then return end
	game.forces.player.set_spawn_position({x = position.x, y = position.y}, global.locomotive_cargo.surface)
end

local function force_nearby_units_to_attack()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	
	global.locomotive_cargo.surface.set_multi_command({
		command={
			type = defines.command.attack,
			target = global.locomotive_cargo,
			distraction = defines.distraction.none
			},
		unit_count = 4,
		force = "enemy",
		unit_search_distance = 256
	})
end

local function tick()
	if not global.locomotive then return end
	if not global.locomotive.valid then return end
	
	if game.tick % 30 == 0 then
		accelerate()		
		if game.tick % 1800 == 0 then
			--force_nearby_units_to_attack()
			set_player_spawn_and_refill_fish()
		end
	else
		remove_acceleration()
	end
end

local event = require 'utils.event'
event.on_nth_tick(5, tick)