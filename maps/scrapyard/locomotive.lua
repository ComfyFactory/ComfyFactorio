local Public = {}

function Public.locomotive_spawn(surface, position)
	for y = -6, 6, 2 do
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	global.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -3}, force = "player"})
	global.locomotive.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 100})

	global.locomotive_cargo = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 3}, force = "player"})
	global.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 8})

	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = global.locomotive,
		surface = surface, visible = true, only_in_alt_mode = false,
	})

	global.locomotive.color = {0, 255, 0}
	global.locomotive.minable = false
	global.locomotive_cargo.minable = false
	global.locomotive_cargo.operable = false
end


local function fish_tag()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	if not global.locomotive_cargo.surface then return end
	if not global.locomotive_cargo.surface.valid then return end
	if global.locomotive_tag then
		if global.locomotive_tag.valid then
			if global.locomotive_tag.position.x == global.locomotive_cargo.position.x and global.locomotive_tag.position.y == global.locomotive_cargo.position.y then return end
			global.locomotive_tag.destroy() 
		end
	end
	global.locomotive_tag = global.locomotive_cargo.force.add_chart_tag(
		global.locomotive_cargo.surface,
		{icon = {type = 'item', name = 'raw-fish'},
		position = global.locomotive_cargo.position,
		text = " "
	})
end
--[[
local function accelerate()
	if not global.locomotive then return end
	if not global.locomotive.valid then return end
	if global.locomotive.get_driver() then return end
	global.locomotive_driver = global.locomotive.surface.create_entity({name = "character", position = global.locomotive.position, force = "player"})
	global.locomotive_driver.driving = true
	global.locomotive_driver.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight}
end

local function remove_acceleration()
	if not global.locomotive then return end
	if not global.locomotive.valid then return end
	if global.locomotive_driver then global.locomotive_driver.destroy() end
	global.locomotive_driver = nil
end
]]
local function set_player_spawn_and_refill_fish()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	global.locomotive_cargo.health = global.locomotive_cargo.health + 6
	global.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = math.random(2, 5)})
	local position = global.locomotive_cargo.surface.find_non_colliding_position("stone-furnace", global.locomotive_cargo.position, 16, 2)
	if not position then return end
	game.forces.player.set_spawn_position({x = position.x, y = position.y}, global.locomotive_cargo.surface)
end

local function tick()
	if game.tick % 30 == 0 then
		if game.tick % 1800 == 0 then
			set_player_spawn_and_refill_fish()
		end
		if global.game_reset_tick then
			if global.game_reset_tick < game.tick then
				global.game_reset_tick = nil
				require "maps.scrapyard.main".reset_map()
			end
			return
		end
		fish_tag()
		--accelerate()
	else
		--remove_acceleration()
	end
end

local event = require 'utils.event'
event.on_nth_tick(5, tick)

return Public