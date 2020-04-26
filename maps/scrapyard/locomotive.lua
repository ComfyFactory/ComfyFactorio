local Event = require 'utils.event'
local Power = require "maps.scrapyard.power"
local ICW = require "modules.immersive_cargo_wagons.main"
local Scrap_table = require "maps.scrapyard.table"

local Public = {}

function Public.render_train_hp()
	local this = Scrap_table.get_table()
	local surface = game.surfaces[this.active_surface_index]
	this.health_text = rendering.draw_text{
		text = "HP: " .. this.locomotive_health .. " / " .. this.locomotive_max_health,
		surface = surface,
		target = this.locomotive,
		target_offset = {0, -2.5},
		color = this.locomotive.color,
		scale = 1.40,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	this.caption = rendering.draw_text{
		text = "Scrapyard Train",
		surface = surface,
		target = this.locomotive,
		target_offset = {0, -4.25},
		color = this.locomotive.color,
		scale = 1.80,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
end

function Public.locomotive_spawn(surface, position)
	local this = Scrap_table.get_table()
	for y = -6, 6, 2 do
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	this.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -3}, force = "player"})
	this.locomotive.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 100})

	--this.power_source = surface.create_entity {name = 'hidden-electric-energy-interface', position = {position.x, position.y + -3, force = "player"}}
    --this.ow_energy.electric_buffer_size = 2400000
	--this.ow_energy.power_production = 40000

	this.locomotive_cargo = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 3}, force = "player"})
	this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 8})

	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = this.locomotive,
		surface = surface, visible = true, only_in_alt_mode = false,
	})

	this.locomotive.color = {0, 255, 0}
	this.locomotive.minable = false
	this.locomotive_cargo.minable = false
	this.locomotive_cargo.operable = true

	ICW.register_wagon(this.locomotive)
	ICW.register_wagon(this.locomotive_cargo)
end

function Public.power_source()
	local this = Scrap_table.get_table()
	local surface = game.surfaces[this.active_surface_index]
	if not this.locomotive then return end
	if not this.locomotive.valid then return end
	if not this.locomotive.surface then return end
	if not this.locomotive.surface.valid then return end
	if this.ow_energy then
		if this.ow_energy.valid then
			if this.ow_energy.position.x == this.locomotive.position.x and this.ow_energy.position.y == this.locomotive.position.y+2 then return end
			this.old_ow_energy = this.ow_energy.energy
			this.ow_energy.destroy() 
			this.energy["scrapyard"] = nil
		end
	end
	this.ow_energy = surface.create_entity{ 
		name = "electric-energy-interface", 
		position = {
			x=this.locomotive.position.x,
			y=this.locomotive.position.y+2
		},
		create_build_effect_smoke = false, 
		force = game.forces.neutral
	}

	rendering.draw_text{
	  text = "Power",
	  surface = surface,
	  target = this.ow_energy,
	  target_offset = {0, -1.5},
	  color = { r = 0, g = 1, b = 0},
	  alignment = "center"
	}

	this.ow_energy.minable = false
	this.ow_energy.destructible = false
	this.ow_energy.operable = false
	this.ow_energy.power_production = 0
	this.ow_energy.electric_buffer_size = 10000000
	if this.old_ow_energy then
		this.ow_energy.energy = this.old_ow_energy
	end
end

function Public.on_teleported_player()
	local this = Scrap_table.get_table()
	local unit_surface = this.locomotive.unit_number
	local loco_surface = game.surfaces[tostring(unit_surface)]
	local pos = {x=-9, y=3}
	if not this.lo_energy then
		this.lo_energy = loco_surface.create_entity{ 
			name = "electric-energy-interface", 
			position = pos,
			create_build_effect_smoke = false, 
			force = game.forces.neutral
		}
	
		rendering.draw_text{
		  text = "Power",
		  surface = loco_surface,
		  target = this.lo_energy,
		  target_offset = {0, -1.5},
		  color = { r = 0, g = 1, b = 0},
		  alignment = "center"
		}

		this.lo_energy.minable = false
		this.lo_energy.destructible = false
		this.lo_energy.operable = false
		this.lo_energy.power_production = 0
		this.lo_energy.electric_buffer_size = 10000000
	end
end

local function fish_tag()
	local this = Scrap_table.get_table()
	if not this.locomotive_cargo then return end
	if not this.locomotive_cargo.valid then return end
	if not this.locomotive_cargo.surface then return end
	if not this.locomotive_cargo.surface.valid then return end
	if this.locomotive_tag then
		if this.locomotive_tag.valid then
			if this.locomotive_tag.position.x == this.locomotive_cargo.position.x and this.locomotive_tag.position.y == this.locomotive_cargo.position.y then return end
			this.locomotive_tag.destroy() 
		end
	end
	this.locomotive_tag = this.locomotive_cargo.force.add_chart_tag(
		this.locomotive_cargo.surface,
		{icon = {type = 'item', name = 'raw-fish'},
		position = this.locomotive_cargo.position,
		text = " "
	})
end
--[[
local function accelerate()
	local this = Scrap_table.get_table()
	if not this.locomotive then return end
	if not this.locomotive.valid then return end
	if this.locomotive.get_driver() then return end
	this.locomotive_driver = this.locomotive.surface.create_entity({name = "character", position = this.locomotive.position, force = "player"})
	this.locomotive_driver.driving = true
	this.locomotive_driver.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight}
end

local function remove_acceleration()
	if not this.locomotive then return end
	if not this.locomotive.valid then return end
	if this.locomotive_driver then this.locomotive_driver.destroy() end
	this.locomotive_driver = nil
end
]]
local function set_player_spawn_and_refill_fish()
	local this = Scrap_table.get_table()
	if not this.locomotive_cargo then return end
	if not this.locomotive_cargo.valid then return end
	this.locomotive_cargo.health = this.locomotive_cargo.health + 6
	this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = math.random(2, 5)})
	local position = this.locomotive_cargo.surface.find_non_colliding_position("stone-furnace", this.locomotive_cargo.position, 16, 2)
	if not position then return end
	game.forces.player.set_spawn_position({x = position.x, y = position.y}, this.locomotive_cargo.surface)
end

local function tick()
	local this = Scrap_table.get_table()
	if game.tick % 30 == 0 then
		if game.tick % 1800 == 0 then
			set_player_spawn_and_refill_fish()
		end
		if this.game_reset_tick then
			if this.game_reset_tick < game.tick then
				this.game_reset_tick = nil
				require "maps.scrapyard.main".reset_map()
			end
			return
		end
		fish_tag()
		Public.power_source()
		--accelerate()
	else
		--remove_acceleration()
	end
end

Event.on_nth_tick(5, tick)
Event.add(defines.events.on_player_driving_changed_state, Public.on_teleported_player)


return Public