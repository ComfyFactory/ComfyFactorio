function locomotive_spawn(surface, position)
	for y = -6, 6, 2 do
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	global.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -3}, force = "player"})
	global.locomotive.get_inventory(defines.inventory.fuel).insert({name = "coal", count = 50})
	
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
	global.locomotive_driver = game.surfaces["cave_defender"].create_entity({name = "character", position = global.locomotive.position, force = "player"})
	global.locomotive_driver.driving = true
	global.locomotive_driver.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight}
end

local function remove_acceleration()
	if global.locomotive_driver then global.locomotive_driver.destroy() end
end

local function tick()
	if game.tick % 30 == 0 then
		accelerate()
	else
		remove_acceleration()
	end
end

local event = require 'utils.event'
event.on_nth_tick(5, tick)