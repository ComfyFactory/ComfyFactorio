require "modules.satellite_score"
require "modules.dangerous_goods"
require "modules.spawners_contain_biters"
require "modules.splice_double"
require "modules.landfill_reveals_nauvis"
require "modules.biter_evasion_hp_increaser"

local event = require 'utils.event'
local math_random = math.random
local simplex_noise = require 'utils.simplex_noise'.d2

local landfill_drops = {
	["small-biter"] = 1,
	["small-spitter"] = 1,
	["medium-biter"] = 2,
	["medium-spitter"] = 2,
	["big-biter"] = 3,
	["big-spitter"] = 3,
	["behemoth-biter"] = 4,
	["behemoth-spitter"] = 4,
	["biter-spawner"] = 128,
	["spitter-spawner"] = 128,
	["small-worm-turret"] = 16,
	["medium-worm-turret"] = 32,
	["big-worm-turret"] = 48,
	["behemoth-worm-turret"] = 64
}

local tile_coords = {}
for x = 0, 31, 1 do
	for y = 0, 31, 1 do
		tile_coords[#tile_coords + 1] = {x, y}
	end
end

local function north_side(surface, left_top)
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			surface.set_tiles({{name = "water-shallow", position = pos}})			
		end
	end
	
	if left_top.y > -96 then return end
	
	for a = 1, math_random(3,5), 1 do
		local coord_modifier = tile_coords[math_random(1, #tile_coords)]
		local pos = {left_top.x + coord_modifier[1], left_top.y + coord_modifier[2]}
		local name = "biter-spawner"	
		if math_random(1,4) == 1 then name = "spitter-spawner" end
		surface.create_entity({name = name, position = pos, force = "enemy"})		
	end
end

local function south_side(surface, left_top)
	if left_top.y < 32 then
		for x = 0.5, 31.5, 1 do
			for y = 0.5, 31.5, 1 do
				local pos = {x = left_top.x + x, y = left_top.y + y}
				surface.set_tiles({{name = "sand-1", position = pos}})
				if math_random(1, 1024) == 1 then
					local crate = surface.create_entity({name = "wooden-chest", position = pos, force = "neutral"})
					if math_random(1, 12) == 1 then
						crate.insert({name = "grenade", count = math_random(2, 5)})
					else
						crate.insert({name = "firearm-magazine", count = math_random(32, 96)})
					end
				else
					if left_top.x > 160 or left_top.x < -160 then
						if math_random(1, 256) == 1 then
							surface.create_entity({name = "small-worm-turret", position = pos, force = "enemy"})
						end
					end
					if math_random(1, 256) == 1 then
						surface.create_entity({name = "tree-02", position = pos, force = "neutral"})
					end
				end		
			end
		end
		return
	end
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			surface.set_tiles({{name = "water", position = pos}})
			if math_random(1, 256) == 1 then surface.create_entity({name = "fish", position = pos, force = "neutral"}) end
		end
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	
	if surface.index == 1 then
		for _, e in pairs(surface.find_entities_filtered({force = "enemy"})) do
			e.destroy()
		end
		return 
	end
	
	local left_top = event.area.left_top
	
	surface.destroy_decoratives({area = area})
	
	if left_top.y < 0 then north_side(surface, left_top) return end
	south_side(surface, left_top)
end

local function init_surface()
	if game.surfaces["blue_beach"] then return game.surfaces["blue_beach"] end

	local map_gen_settings = {}
	map_gen_settings.water = "0"
	map_gen_settings.starting_area = "0"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 40, cliff_elevation_0 = 40}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "0", size = "0", richness = "0"},
		["stone"] = {frequency = "0", size = "0", richness = "0"},
		["iron-ore"] = {frequency = "0", size = "0", richness = "0"},
		["copper-ore"] = {frequency = "0", size = "0", richness = "0"},
		["uranium-ore"] = {frequency = "0", size = "0", richness = "0"},		
		["crude-oil"] = {frequency = "0", size = "0", richness = "0"},
		["trees"] = {frequency = "0", size = "0", richness = "0"},
		["enemy-base"] = {frequency = "0", size = "0", richness = "0"}
	}
	
	game.map_settings.pollution.enabled = true
	game.map_settings.enemy_expansion.enabled = false				
	game.map_settings.enemy_expansion.max_expansion_distance = 15
	game.map_settings.enemy_expansion.settler_group_min_size = 8
	game.map_settings.enemy_expansion.settler_group_max_size = 16
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.max_expansion_cooldown = 7200
			
	local surface = game.create_surface("blue_beach", map_gen_settings)				
	surface.request_to_generate_chunks({x = 0, y = 0}, 1)
	surface.force_generate_chunk_requests()
	surface.daytime = 0.7
	surface.ticks_per_day = surface.ticks_per_day * 1.5
	surface.min_brightness = 0.1
	
	game.forces["player"].set_spawn_position({0,0},game.surfaces["blue_beach"])
	game.forces["player"].technologies["landfill"].enabled = false
	
	return surface
end

local function on_player_joined_game(event)	
	local surface = init_surface()	
	local player = game.players[event.player_index]
	
	if player.online_time == 0 then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "blue_beach")
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "iron-plate", count = 128})
		player.insert({name = "iron-gear-wheel", count = 64})
		player.insert({name = "copper-plate", count = 128})
		player.insert({name = "copper-cable", count = 64})
		player.insert({name = "pistol", count = 1})
		player.insert({name = "firearm-magazine", count = 32})
		player.insert({name = "shotgun", count = 1})
		player.insert({name = "shotgun-shell", count = 16})
		player.insert({name = "light-armor", count = 1})
	end
end

local function make_sand(surface, position)
	if math_random(1,5) ~= 1 then return end
	local water_tiles = {}
	for x = -1, 1, 1 do
		for y = -1, 1, 1 do
			local pos = {position.x + x, position.y + y}
			if surface.get_tile(pos).name == "water" then
				water_tiles[#water_tiles + 1] = pos
			end
		end
	end
	if not water_tiles[2] then return end
	surface.set_tiles({{name = "sand-1", position = water_tiles[math_random(1, #water_tiles)]}})
end

local function on_entity_died(event)	
	if not event.entity.valid then return end
	if landfill_drops[event.entity.name] then 
		event.entity.surface.spill_item_stack(event.entity.position,{name = "landfill", count = landfill_drops[event.entity.name] * 2}, true)
	end
	if event.entity.type ~= "unit" then return end
	make_sand(event.entity.surface, event.entity.position)
end

local function draw_evolution_gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.top.evolution_gui then player.gui.top.evolution_gui.destroy() end
		local element = player.gui.top.add({type = "sprite-button", name = "evolution_gui", caption = "Evolution: " .. global.evolution_factor .. "%", tooltip = "Can go above 100%"})
		local style = element.style
		style.minimal_height = 38
		style.maximal_height = 38
		style.minimal_width = 176
		style.top_padding = 2
		style.left_padding = 4
		style.right_padding = 4
		style.bottom_padding = 2
		style.font_color = {r = 50, g = 130, b = 255}
		style.font = "default-large-bold"
	end
end

local function get_random_close_spawner(surface)
	local spawners = surface.find_entities_filtered({type = "unit-spawner", force = "enemy"})	
	if not spawners[1] then return false end
	
	local spawner = spawners[math_random(1,#spawners)]
	for i = 1, 4, 1 do
		local spawner_2 = spawners[math_random(1,#spawners)]
		if spawner_2.position.x ^ 2 + spawner_2.position.y ^ 2 < spawner.position.x ^ 2 + spawner.position.y ^ 2 then spawner = spawner_2 end	
	end	
	
	return spawner
end

local function send_wave()
	local surface = game.surfaces.blue_beach
	local spawner = get_random_close_spawner(surface)
	local biters = spawner.surface.find_enemy_units(spawner.position, 96, "player")
	if not biters[1] then return end
	local amount = math.floor(game.tick * 0.001)
	if amount > 128 then amount = 128 end
	local group_position = surface.find_non_colliding_position("rocket-silo", spawner.position, 128, 1)
	if not group_position then return end
	local nearest_player_unit = surface.find_nearest_enemy({position = spawner.position, max_distance = 2048, force = "enemy"})
	if not nearest_player_unit then return end
	local unit_group = surface.create_unit_group({position = group_position, force = "enemy"})
	for _, biter in pairs(biters) do
		unit_group.add_member(biter)
		amount = amount - 1
		if amount < 0 then break end
	end	
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = {
			{
				type = defines.command.attack_area,
				destination = nearest_player_unit.position,
				radius = 32,
				distraction=defines.distraction.by_enemy
			},									
			{
				type = defines.command.attack,
				target = game.connected_players[math_random(1, #game.connected_players)].character,
				distraction = defines.distraction.by_enemy
			}
		}
	})	
end

local function set_evolution()
	local evo = game.tick * 0.000001
	global.evolution_factor = math.round(evo, 4)
	if evo > 1 then	evo = 1	end
	game.forces.enemy.evolution_factor = evo
	
	if global.evolution_factor < 1 then return end
	game.forces.enemy.set_ammo_damage_modifier("melee", (global.evolution_factor - 1) * 1.5)
	game.forces.enemy.set_ammo_damage_modifier("biological", (global.evolution_factor - 1) * 1.5)
	global.biter_evasion_health_increase_factor = global.evolution_factor * 3
end

local function on_tick(event)	
	if game.tick % 900 ~= 450 then return end
	send_wave()
	set_evolution()	
	draw_evolution_gui()
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)