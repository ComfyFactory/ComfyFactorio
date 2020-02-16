-- chronosphere --

require "functions.soft_reset"
require "player_modifiers"
require "functions.basic_markets"

require "modules.biters_yield_coins"
require "modules.no_deconstruction_of_neutral_entities"
--require "modules.no_solar"
require "modules.shotgun_buff"
require "modules.mineable_wreckage_yields_scrap"
require "maps.chronosphere.comfylatron"
require "maps.chronosphere.chronobubles"
require "maps.chronosphere.ores"
require "on_tick_schedule"
require "modules.biter_noms_you"
local Ai = require "maps.chronosphere.ai"
local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"
local tick_tack_trap = require "functions.tick_tack_trap"
local chronobuble = require "maps.chronosphere.chronobubles"
local level_depth = require "maps.chronosphere.terrain"
local Reset = require "functions.soft_reset"
local Map = require "modules.map_info"
local Locomotive = require "maps.chronosphere.locomotive"
local Modifier = require "player_modifiers"
local update_gui = require "maps.chronosphere.gui"
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt
local chests = {}
local Public = {}
--local acus = {}
global.objective = {}
global.flame_boots = {}

local choppy_entity_yield = {
		["tree-01"] = {"iron-ore"},
		["tree-02-red"] = {"copper-ore"},
		["tree-04"] = {"coal"},
		["tree-08-brown"] = {"stone"}
	}


local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['grenade'] = 1, ['raw-fish'] = 4, ['rail'] = 16, ['wood'] = 16}
local starting_cargo = {['firearm-magazine'] = 16, ['iron-plate'] = 16, ['wood'] = 16, ['burner-mining-drill'] = 8}

function generate_overworld(surface, optplanet)
	local planet = nil
	if not optplanet then
		planet = chronobuble.determine_planet(nil)
		game.print("Planet info: " .. planet[1].name.name .. ", Ore richness: " .. planet[1].ore_richness.name .. ", Speed of day: " .. planet[1].day_speed.name, {r=0.98, g=0.66, b=0.22})
		global.objective.planet = planet
	else
		planet = optplanet
	end
	if planet[1].name.name == "choppy planet" then
		game.print("Comfylatron: OwO what are those strange trees?!? They have ore fruits! WTF!", {r=0.98, g=0.66, b=0.22})
	elseif planet[1].name.name == "lava planet" then
		game.print("Comfylatron: OOF this one is a bit hot. And have seen those biters? They BATHE in fire!", {r=0.98, g=0.66, b=0.22})
	end
	surface.min_brightness = 0
	surface.brightness_visual_weights = {1, 1, 1}
	global.objective.surface = surface
	surface.daytime = planet[1].time
	local timer = planet[1].day_speed.timer
	if timer == 0 then
		surface.freeze_daytime = true
		timer = timer + 1
	else
		surface.freeze_daytime = false
	end
	surface.ticks_per_day = timer * 250

	local moisture = planet[1].name.moisture
	if moisture ~= 0 then
		local mgs = surface.map_gen_settings
		mgs.property_expression_names["control-setting:moisture:bias"] = moisture
		surface.map_gen_settings = mgs
	end
	if planet[1].name.name == "water planet" then
		local mgs = surface.map_gen_settings
		mgs.water = 0.8
		surface.map_gen_settings = mgs
	end
	if planet[1].name.name == "lava planet" then
		local mgs = surface.map_gen_settings
		mgs.water = 0
		surface.map_gen_settings = mgs
	end
	if planet[1].name.name ~= "choppy planet" then
		local mgs = surface.map_gen_settings
		mgs.water = 0.2
		surface.map_gen_settings = mgs
	end
	--log(timer)
	--surface.solar_power_multiplier = 999

	surface.request_to_generate_chunks({0,0}, 3)
	surface.force_generate_chunk_requests()

	-- for x = -352 + 32, 352 - 32, 32 do
	-- 	surface.request_to_generate_chunks({x, 96}, 1)
	-- 	--surface.force_generate_chunk_requests()
	-- end
	--spawn_ores(surface, planet)
	--if planet[1].name.name == "mixed planet" then
	--	ores_are_mixed(surface)
	--end
	--game.forces["player"].chart_all(surface)
end

local function get_map_gen_settings()
	local map_gen_settings = {
		["seed"] = math_random(1, 1000000),
		["width"] = level_depth,
		["height"] = level_depth,
		["water"] = 0.1,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = true,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = true},
			["decorative"] = {treat_missing_as_default = true},
		},
	}
	return map_gen_settings
end

local function render_train_hp()
	local surface = game.surfaces[global.active_surface_index]
	local objective = global.objective
	objective.health_text = rendering.draw_text{
		text = "HP: " .. objective.health .. " / " .. objective.max_health,
		surface = surface,
		target = global.locomotive,
		target_offset = {0, -2.5},
		color = global.locomotive.color,
		scale = 1.40,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	objective.caption = rendering.draw_text{
		text = "Comfylatron's ChronoTrain",
		surface = surface,
		target = global.locomotive,
		target_offset = {0, -4.25},
		color = global.locomotive.color,
		scale = 1.80,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
end


function Public.reset_map()
	global.chunk_queue = {}
	if game.surfaces["chronosphere"] then game.delete_surface(game.surfaces["chronosphere"]) end
	if game.surfaces["cargo_wagon"] then game.delete_surface(game.surfaces["cargo_wagon"]) end
	chests = {}
	local map_gen_settings = get_map_gen_settings()
	local planet = nil
	if not global.active_surface_index then
		global.active_surface_index = game.create_surface("chronosphere", map_gen_settings).index
	else
		planet = chronobuble.determine_planet(nil)

		global.objective.planet = planet
		game.forces.player.set_spawn_position({12, 10}, game.surfaces[global.active_surface_index])
		global.active_surface_index = Reset.soft_reset_map(game.surfaces[global.active_surface_index], map_gen_settings, starting_items).index
		game.print("Planet info: " .. planet[1].name.name .. ", Ore richness: " .. planet[1].ore_richness.name .. ", Speed of day: " .. planet[1].day_speed.name, {r=0.98, g=0.66, b=0.22})
	end

	local surface = game.surfaces[global.active_surface_index]
	generate_overworld(surface, planet)

	local objective = global.objective
	objective.max_health = 10000
	objective.health = 10000
	objective.hpupgradetier = 0
	objective.acuupgradetier = 0
	objective.filterupgradetier = 0
	objective.pickupupgradetier = 0
	objective.invupgradetier = 0
	objective.toolsupgradetier = 0
	objective.waterupgradetier = 0
	objective.outupgradetier = 0
	objective.boxupgradetier = 0
	objective.chronojumps = 0
	objective.chronotimer = 0
	objective.chrononeeds = 2000
	objective.active_biters = {}
	objective.unit_groups = {}
	objective.biter_raffle = {}
	global.outchests = {}




	game.difficulty_settings.technology_price_multiplier = 0.5
	game.map_settings.enemy_evolution.destroy_factor = 0.001
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 4e-05
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.settler_group_max_size = 8
	game.map_settings.enemy_expansion.settler_group_min_size = 16
	game.map_settings.pollution.enabled = true

	game.forces.player.technologies["land-mine"].enabled = false
	game.forces.player.technologies["landfill"].enabled = false
	game.forces.player.technologies["railway"].researched = true
	game.forces.player.set_spawn_position({12, 10}, surface)

	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, starting_cargo, starting_cargo)
	render_train_hp()
	game.reset_time_played()
	objective.game_lost = false




	--set_difficulty()
end

local function on_player_joined_game(event)
	local player_modifiers = Modifier.get_table()
	local player = game.players[event.player_index]
	global.flame_boots[event.player_index] = {fuel = 1}
	if not global.flame_boots[event.player_index].steps then global.flame_boots[event.player_index].steps = {} end
	--log(chronobuble.determine_planet())

	--set_difficulty()

	local surface = game.surfaces[global.active_surface_index]

	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end

	if player.surface.index ~= global.active_surface_index and player.surface.name ~= "cargo_wagon" then
		player.character = nil
		player.set_controller({type=defines.controllers.god})
		player.create_character()
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end

	player_modifiers[player.index].character_mining_speed_modifier["chronosphere"] = 0.5
	Modifier.update_player_modifiers(player)
	local tile = surface.get_tile(player.position)
	if tile.valid then
		if tile.name == "out-of-map" then
			player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
		end
	end
end

local function repair_train()
	local objective = global.objective
	if not game.surfaces["cargo_wagon"] then return end
	if objective.game_lost == true then return end
	if objective.health < objective.max_health then
		local inv = global.repairchest.get_inventory(defines.inventory.chest)
		local count = inv.get_item_count("repair-pack")
		if count >= 5 and objective.toolsupgradetier == 4 and objective.health + 750 <= objective.max_health then
			inv.remove({name = "repair-pack", count = 5})
			set_objective_health(-750)
		elseif count >= 4 and objective.toolsupgradetier == 3 and objective.health + 600 <= objective.max_health then
			inv.remove({name = "repair-pack", count = 4})
			set_objective_health(-600)
		elseif count >= 3 and objective.toolsupgradetier == 2 and objective.health + 450 <= objective.max_health then
			inv.remove({name = "repair-pack", count = 3})
			set_objective_health(-450)
		elseif count >= 2 and objective.toolsupgradetier == 1 and objective.health + 300 <= objective.max_health then
			inv.remove({name = "repair-pack", count = 2})
			set_objective_health(-300)
		elseif count >= 1 then
			inv.remove({name = "repair-pack", count = 1})
			set_objective_health(-150)
		end
	end
end

local function check_upgrades()
	local objective = global.objective
	if not game.surfaces["cargo_wagon"] then return end
	if objective.game_lost == true then return end
	if global.hpchest and global.hpchest.valid then
		local inv = global.hpchest.get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("copper-plate")
		if countcoins >= 2500 and count2 >= 3000 and objective.hpupgradetier < 18 then
			inv.remove({name = "coin", count = 2500})
			inv.remove({name = "copper-plate", count = 3000})
			game.print("Comfylatron: Train's max HP was upgraded.", {r=0.98, g=0.66, b=0.22})
			objective.hpupgradetier = objective.hpupgradetier + 1
			objective.max_health = 10000 + 5000 * objective.hpupgradetier
			rendering.set_text(global.objective.health_text, "HP: " .. global.objective.health .. " / " .. global.objective.max_health)
		end
	end
	if global.filterchest and global.filterchest.valid then
		local inv = global.filterchest.get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("electronic-circuit")
		if countcoins >= 4000 and count2 >= 1000 and objective.filterupgradetier < 9 then
			inv.remove({name = "coin", count = 4000})
			inv.remove({name = "electronic-circuit", count = 1000})
			game.print("Comfylatron: Train's pollution filter was upgraded.", {r=0.98, g=0.66, b=0.22})
			objective.filterupgradetier = objective.filterupgradetier + 1
		end
	end
	if global.acuchest and global.acuchest.valid then
		local inv = global.acuchest.get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("battery")
		if countcoins >= 2500 and count2 >= 200 and objective.acuupgradetier < 24 then
			inv.remove({name = "coin", count = 2500})
			inv.remove({name = "battery", count = 200})
			game.print("Comfylatron: Train's acumulator capacity was upgraded.", {r=0.98, g=0.66, b=0.22})
			objective.acuupgradetier = objective.acuupgradetier + 1
			spawn_acumulators()
		end
	end
	if global.playerchest and global.playerchest.valid then
		local inv = global.playerchest.get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("long-handed-inserter")
		if countcoins >= 1000 and count2 >= 400 and objective.pickupupgradetier < 4 then
			inv.remove({name = "coin", count = 1000})
			inv.remove({name = "long-handed-inserter", count = 400})
			game.print("Comfylatron: Players now have additional red inserter installed on shoulders, increasing their item pickup range.", {r=0.98, g=0.66, b=0.22})
			objective.pickupupgradetier = objective.pickupupgradetier + 1
			game.forces.player.character_item_pickup_distance_bonus = game.forces.player.character_item_pickup_distance_bonus + 1
		end
	end
	if global.invchest and global.invchest.valid then
		local inv = global.invchest.get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local item = "computer"
		if objective.invupgradetier == 0 then
			item = "wooden-chest"
		elseif objective.invupgradetier == 1 then
			item = "iron-chest"
		elseif objective.invupgradetier == 2 then
			item = "steel-chest"
		elseif objective.invupgradetier == 3 then
			item = "logistic-chest-storage"
		end
		local count2 = inv.get_item_count(item)
		if countcoins >= 2000 and count2 >= 250 and objective.invupgradetier < 4 and objective.chronojumps >= (objective.invupgradetier + 1) * 5 then
			inv.remove({name = "coin", count = 2000})
			inv.remove({name = item, count = 250})
			game.print("Comfylatron: Players now can carry more trash in their unsorted inventories.", {r=0.98, g=0.66, b=0.22})
			objective.invupgradetier = objective.invupgradetier + 1
			game.forces.player.character_inventory_slots_bonus = game.forces.player.character_inventory_slots_bonus + 10
		end
	end

	if global.toolschest and global.toolschest.valid then
		local inv = global.toolschest.get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("repair-pack")
		if countcoins >= 1000 and count2 >= 200 and objective.toolsupgradetier < 4 then
			inv.remove({name = "coin", count = 1000})
			inv.remove({name = "repair-pack", count = 200})
			game.print("Comfylatron: Train now gets repaired with additional repair kit at once.", {r=0.98, g=0.66, b=0.22})
			objective.toolsupgradetier = objective.toolsupgradetier + 1
		end
	end
	if global.waterchest and global.waterchest.valid and game.surfaces["cargo_wagon"].valid then
		local inv = global.waterchest.get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("pipe")
		if countcoins >= 2000 and count2 >= 500 and objective.waterupgradetier < 1 then
			inv.remove({name = "coin", count = 2000})
			inv.remove({name = "pipe", count = 500})
			game.print("Comfylatron: Train now has piping system for additional water sources.", {r=0.98, g=0.66, b=0.22})
			objective.waterupgradetier = objective.waterupgradetier + 1
			local e1 = game.surfaces["cargo_wagon"].create_entity({name = "offshore-pump", position = {28,66}, force="player"})
			local e2 = game.surfaces["cargo_wagon"].create_entity({name = "offshore-pump", position = {28,-62}, force = "player"})
			local e3 = game.surfaces["cargo_wagon"].create_entity({name = "offshore-pump", position = {-29,66}, force = "player"})
			local e4 = game.surfaces["cargo_wagon"].create_entity({name = "offshore-pump", position = {-29,-62}, force = "player"})
			e1.destructible = false
			e1.minable = false
			e2.destructible = false
			e2.minable = false
			e3.destructible = false
			e3.minable = false
			e4.destructible = false
			e4.minable = false
		end
	end
	if global.outchest and global.outchest.valid and game.surfaces["cargo_wagon"].valid then
		local inv = global.outchest.get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("fast-inserter")
		if countcoins >= 2000 and count2 >= 100 and objective.outupgradetier < 1 then
			inv.remove({name = "coin", count = 2000})
			inv.remove({name = "fast-inserter", count = 100})
			game.print("Comfylatron: Train now has output chests.", {r=0.98, g=0.66, b=0.22})
			objective.outupgradetier = objective.outupgradetier + 1
			local e = {}
			e[1] = game.surfaces["cargo_wagon"].create_entity({name="compilatron-chest", position= {-16,-62}, force = "player"})
			e[2] = game.surfaces["cargo_wagon"].create_entity({name="compilatron-chest", position= {15,-62}, force = "player"})
			e[3] = game.surfaces["cargo_wagon"].create_entity({name="compilatron-chest", position= {-16,66}, force = "player"})
			e[4] = game.surfaces["cargo_wagon"].create_entity({name="compilatron-chest", position= {15,66}, force = "player"})

			local out = {}
			for i = 1, 4, 1 do
				e[i].destructible = false
				e[i].minable = false
				global.outchests[i] = e[i]
				out[i] = rendering.draw_text{
					text = "Output",
					surface = e[i].surface,
					target = e[i],
					target_offset = {0, -1.5},
					color = global.locomotive.color,
					scale = 0.80,
					font = "default-game",
					alignment = "center",
					scale_with_zoom = false
				}
			end
		end
	end
	if global.boxchest and global.boxchest.valid and game.surfaces["cargo_wagon"].valid then
		local inv = global.boxchest.get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local item = "computer"
		if objective.boxupgradetier == 0 then
			item = "wooden-chest"
		elseif objective.boxupgradetier == 1 then
			item = "iron-chest"
		elseif objective.boxupgradetier == 2 then
			item = "steel-chest"
		elseif objective.boxupgradetier == 3 then
			item = "logistic-chest-storage"
		end
		local count2 = inv.get_item_count(item)
		if countcoins >= 5000 and count2 >= 250 and objective.boxupgradetier < 4 and objective.chronojumps >= (objective.boxupgradetier + 1) * 5 then
			inv.remove({name = "coin", count = 5000})
			inv.remove({name = item, count = 250})
			game.print("Comfylatron: Cargo wagons now have enlargened storage.", {r=0.98, g=0.66, b=0.22})
			objective.boxupgradetier = objective.boxupgradetier + 1
			local chests = {}
			for i = 1, 58, 1 do
				if objective.boxupgradetier == 1 then
					chests[#chests + 1] = {name="wooden-chest", position= {-33 ,-189 + i}, force = "player"}
					chests[#chests + 1] = {name="wooden-chest", position= {32 ,-189 + i}, force = "player"}
				elseif objective.boxupgradetier == 2 then
					chests[#chests + 1] = {name="iron-chest", position= {-33 ,-189 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="iron-chest", position= {32 ,-189 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 3 then
					chests[#chests + 1] = {name="steel-chest", position= {-33 ,-189 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="steel-chest", position= {32 ,-189 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 4 then
					chests[#chests + 1] = {name="logistic-chest-storage", position= {-33 ,-189 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="logistic-chest-storage", position= {32 ,-189 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				end
			end
			for i = 1, 58, 1 do
				if objective.boxupgradetier == 1 then
					chests[#chests + 1] = {name="wooden-chest", position= {-33 ,-127 + i}, force = "player"}
					chests[#chests + 1] = {name="wooden-chest", position= {32 ,-127 + i}, force = "player"}
				elseif objective.boxupgradetier == 2 then
					chests[#chests + 1] = {name="iron-chest", position= {-33 ,-127 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="iron-chest", position= {32 ,-127 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 3 then
					chests[#chests + 1] = {name="steel-chest", position= {-33 ,-127 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="steel-chest", position= {32 ,-127 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 4 then
					chests[#chests + 1] ={name="logistic-chest-storage", position= {-33 ,-127 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] ={name="logistic-chest-storage", position= {32 ,-127 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				end
			end
			for i = 1, 58, 1 do
				if objective.boxupgradetier == 1 then
					chests[#chests + 1] = {name="wooden-chest", position= {-33 ,-61 + i}, force = "player"}
					chests[#chests + 1] = {name="wooden-chest", position= {32 ,-61 + i}, force = "player"}
				elseif objective.boxupgradetier == 2 then
					chests[#chests + 1] = {name="iron-chest", position= {-33 ,-61 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="iron-chest", position= {32 ,-61 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 3 then
					chests[#chests + 1] = {name="steel-chest", position= {-33 ,-61 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="steel-chest", position= {32 ,-61 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 4 then
					chests[#chests + 1] = {name="logistic-chest-storage", position= {-33 ,-61 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="logistic-chest-storage", position= {32 ,-61 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				end
			end
			for i = 1, 58, 1 do
				if objective.boxupgradetier == 1 then
					chests[#chests + 1] = {name="wooden-chest", position= {-33 ,1 + i}, force = "player"}
					chests[#chests + 1] = {name="wooden-chest", position= {32 ,1 + i}, force = "player"}
				elseif objective.boxupgradetier == 2 then
					chests[#chests + 1] = {name="iron-chest", position= {-33 ,1 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="iron-chest", position= {32 ,1 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 3 then
					chests[#chests + 1] = {name="steel-chest", position= {-33 ,1 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="steel-chest", position= {32 ,1 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 4 then
					chests[#chests + 1] = {name="logistic-chest-storage", position= {-33 ,1 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="logistic-chest-storage", position= {32 ,1 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				end
			end
			for i = 1, 58, 1 do
				if objective.boxupgradetier == 1 then
					chests[#chests + 1] = {name="wooden-chest", position= {-33 ,67 + i}, force = "player"}
					chests[#chests + 1] = {name="wooden-chest", position= {32 ,67 + i}, force = "player"}
				elseif objective.boxupgradetier == 2 then
					chests[#chests + 1] = {name="iron-chest", position= {-33 ,67 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="iron-chest", position= {32 ,67 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 3 then
					chests[#chests + 1] = {name="steel-chest", position= {-33 ,67 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="steel-chest", position= {32 ,67 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 4 then
					chests[#chests + 1] = {name="logistic-chest-storage", position= {-33 ,67 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="logistic-chest-storage", position= {32 ,67 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				end
			end
			for i = 1, 58, 1 do
				if objective.boxupgradetier == 1 then
					chests[#chests + 1] = {name="wooden-chest", position= {-33 ,129 + i}, force = "player"}
					chests[#chests + 1] = {name="wooden-chest", position= {32 ,129 + i}, force = "player"}
				elseif objective.boxupgradetier == 2 then
					chests[#chests + 1] = {name="iron-chest", position= {-33 ,129 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="iron-chest", position= {32 ,129 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 3 then
					chests[#chests + 1] = {name="steel-chest", position= {-33 ,129 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="steel-chest", position= {32 ,129 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				elseif objective.boxupgradetier == 4 then
					chests[#chests + 1] = {name="logistic-chest-storage", position= {-33 ,129 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
					chests[#chests + 1] = {name="logistic-chest-storage", position= {32 ,129 + i}, force = "player", fast_replace = true, player = "Hanakocz"}
				end
			end
			local surface = game.surfaces["cargo_wagon"]
			for i = 1, #chests, 1 do
				surface.set_tiles({{name = "tutorial-grid", position = chests[i].position}})
				local e = surface.create_entity(chests[i])
				local old = nil
				if e.name == "iron-chest" then old = surface.find_entity("wooden-chest", e.position)
				elseif e.name == "steel-chest" then old = surface.find_entity("iron-chest", e.position)
				elseif e.name == "logistic-chest-storage" then old = surface.find_entity("steel-chest", e.position)
				end
				if old then
					local items = old.get_inventory(defines.inventory.chest).get_contents()
					for item, count in pairs(items) do
						e.insert({name = item, count = count})
					end
					old.destroy()
				end
				e.destructible = false
				e.minable = false
			end
		end
	end
end



local function move_items()
	if not global.comfychests then return end
	if not global.comfychests2 then return end
	if global.objective.game_lost == true then return end
  local input = global.comfychests
  local output = global.comfychests2
	for i = 1, 24, 1 do
		if not input[i].valid then
			log("no input chest " .. i)
			return
		end
		if not output[i].valid then
			log("no output chest " .. i)
			return
		end

		local input_inventory = input[i].get_inventory(defines.inventory.chest)
		local output_inventory = output[i].get_inventory(defines.inventory.chest)
		input_inventory.sort_and_merge()
		local items = input_inventory.get_contents()

		for item, count in pairs(items) do
			local inserted = output_inventory.insert({name = item, count = count})
			if inserted > 0 then
				local removed = input_inventory.remove({name = item, count = inserted})
			end
		end
	end
end

local function output_items()
	if global.objective.game_lost == true then return end
	if not global.outchests then return end
	if not global.locomotive_cargo2 then return end
	if not global.locomotive_cargo3 then return end
	if global.objective.outupgradetier ~= 1 then return end
	for i = 1, 4, 1 do
		if not global.outchests[i].valid then return end
		local inv = global.outchests[i].get_inventory(defines.inventory.chest)
		inv.sort_and_merge()
		local items = inv.get_contents()
		for item, count in pairs(items) do
			local inserted = nil
			if i <= 2 then
				inserted = global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count})
			else
				inserted = global.locomotive_cargo3.get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count})
			end
			if inserted > 0 then
				local removed = inv.remove({name = item, count = inserted})
			end
		end
	end
end

function chronojump(choice)
	local objective = global.objective
	if objective.game_lost then return end
	objective.chronojumps = objective.chronojumps + 1
	objective.chrononeeds = 2000 + 800 * objective.chronojumps
	objective.chronotimer = 0
	game.print("Comfylatron: Wheeee! Time Jump Active! This is Jump number " .. global.objective.chronojumps, {r=0.98, g=0.66, b=0.22})
	local oldsurface = game.surfaces[global.active_surface_index]

	for _,player in pairs(game.players) do
		if player.surface == oldsurface then
			if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
			Locomotive.enter_cargo_wagon(player, global.locomotive_cargo)
		end
	end
	local map_gen_settings = get_map_gen_settings()

	global.active_surface_index = game.create_surface("chronosphere" .. objective.chronojumps, map_gen_settings).index
	local surface = game.surfaces[global.active_surface_index]
	local planet = nil
	if choice then
		planet = chronobuble.determine_planet(choice)
		game.print("Planet info: " .. planet[1].name.name .. ", Ore richness: " .. planet[1].ore_richness.name .. ", Speed of day: " .. planet[1].day_speed.name, {r=0.98, g=0.66, b=0.22})
		global.objective.planet = planet
	end
	generate_overworld(surface, planet)
	game.forces.player.set_spawn_position({12, 10}, surface)
	local items = global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon).get_contents()
	local items2 = global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon).get_contents()
	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, items, items2)
	render_train_hp()
	game.delete_surface(oldsurface)
	if objective.chronojumps <= 40 then
		game.forces["enemy"].evolution_factor = 0 + 0.025 * objective.chronojumps
	else
		game.forces["enemy"].evolution_factor = 1
	end
	game.map_settings.enemy_evolution.time_factor = 4e-05 + 2e-06 * objective.chronojumps
end

local function check_chronoprogress()
	local objective = global.objective
	--game.print(objective.chronotimer)
	if objective.chronotimer >= objective.chrononeeds - 60 and objective.chronotimer < objective.chrononeeds - 59 then
		game.print("Comfylatron: ChronoTrain nearly charged! Grab what you can, we leaving in 60 seconds!", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer == objective.chrononeeds - 30 then
		game.print("Comfylatron: You better hurry up! 30 seconds remaining!", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer >= objective.chrononeeds - 10 and objective.chrononeeds - objective.chronotimer > 0 then
		game.print("Comfylatron: Jump in " .. objective.chrononeeds - objective.chronotimer .. " seconds!", {r=0.98, g=0.66, b=0.22})
	end
	if objective.chronotimer >= objective.chrononeeds then
		chronojump(nil)

	end
end

local function charge_chronosphere()
	if not global.acumulators then return end
	local objective = global.objective
	if not objective.chronotimer then return end
	if objective.chronotimer < 20 then return end
	local acus = global.acumulators
	if #acus < 1 then return end
	for i = 1, #acus, 1 do
		if not acus[i].valid then return end
		local energy = acus[i].energy
		if energy > 3000000 and objective.chronotimer < objective.chrononeeds - 62 and objective.chronotimer > 130 then
			acus[i].energy = acus[i].energy - 3000000
			objective.chronotimer = objective.chronotimer + 1
			game.surfaces[global.active_surface_index].pollute(global.locomotive.position, 100 * (4 / (objective.filterupgradetier / 2 + 1)))
			--log("energy charged from acu")
		end
	end
end

local function transfer_pollution()
	local surface = game.surfaces["cargo_wagon"]
	if not surface then return end
	local pollution = surface.get_total_pollution() * (3 / (global.objective.filterupgradetier / 3 + 1))
	game.surfaces[global.active_surface_index].pollute(global.locomotive.position, pollution)
	surface.clear_pollution()
end

local tick_minute_functions = {

	[300 * 2] = Ai.destroy_inactive_biters,
	[300 * 3 + 30 * 0] = Ai.pre_main_attack,		-- setup for main_attack
	[300 * 3 + 30 * 1] = Ai.perform_main_attack,
	[300 * 3 + 30 * 2] = Ai.perform_main_attack,
	[300 * 3 + 30 * 3] = Ai.perform_main_attack,
	[300 * 3 + 30 * 4] = Ai.perform_main_attack,
	[300 * 3 + 30 * 5] = Ai.perform_main_attack,	-- call perform_main_attack 7 times on different ticks
	[300 * 4] = Ai.send_near_biters_to_objective,
	[300 * 5] = Ai.wake_up_sleepy_groups

}

local function tick()
	local tick = game.tick
	if tick % 60 == 30 and global.objective.chronotimer < 64 then
		local surface = game.surfaces[global.active_surface_index]
		surface.request_to_generate_chunks({0,0}, 3 + math_floor(global.objective.chronotimer / 5))
		--surface.force_generate_chunk_requests()


	end
	if tick % 30 == 0 then
		if tick % 600 == 0 then
			charge_chronosphere()
			transfer_pollution()
		end
		if tick % 1800 == 0 then
			Locomotive.set_player_spawn_and_refill_fish()
			repair_train()
			check_upgrades()
		end
		local key = tick % 3600
		if tick_minute_functions[key] then tick_minute_functions[key]() end
		if tick % 60 == 0 then
			global.objective.chronotimer = global.objective.chronotimer + 1
			check_chronoprogress()
		end
		if tick % 120 == 0 then
			move_items()
			output_items()
		end
		if global.game_reset_tick then
			if global.game_reset_tick < tick then
				global.game_reset_tick = nil
				require "maps.chronosphere.main".reset_map()
			end
			return
		end
		Locomotive.fish_tag()
	end
	for _, player in pairs(game.connected_players) do update_gui(player) end
	--if not collapse_enabled then return end
	--Collapse.process()
end

local function on_init()
	local T = Map.Pop_info()
	T.localised_category = "chronosphere"
	T.main_caption_color = {r = 150, g = 150, b = 0}
	T.sub_caption_color = {r = 0, g = 150, b = 0}
	global.objective.game_lost = true

	--global.rocks_yield_ore_maximum_amount = 999
	--global.rocks_yield_ore_base_amount = 50
	--global.rocks_yield_ore_distance_modifier = 0.025
	--if game.surfaces["nauvis"] then game.delete_surface(game.surfaces["nauvis"]) end
	Public.reset_map()
end

function set_objective_health(final_damage_amount)
	local objective = global.objective
	objective.health = math_floor(objective.health - final_damage_amount)
	if objective.health > objective.max_health then objective.health = objective.max_health end

	if objective.health <= 0 then
		if objective.game_lost == true then return end
		objective.health = 0
		local surface = objective.surface
		game.print("The chronotrain was destroyed!")
		game.print("Comfylatron is going to kill you for that...he has time machine after all!")
		surface.create_entity({name = "big-artillery-explosion", position = global.locomotive_cargo.position})
		global.locomotive_cargo.destroy()
		surface.create_entity({name = "big-artillery-explosion", position = global.locomotive_cargo2.position})
		global.locomotive_cargo2.destroy()
		surface.create_entity({name = "big-artillery-explosion", position = global.locomotive_cargo3.position})
		global.locomotive_cargo3.destroy()
		for i = 1, #global.comfychests,1 do
			--surface.create_entity({name = "big-artillery-explosion", position = global.comfychests[i].position})
			global.comfychests[i].destroy()

			if global.comfychests2 then global.comfychests2[i].destroy() end

			--global.comfychests = {}
		end
		global.ores_queue = {}
		global.entities_queue = {}
		global.acumulators = {}
		objective.game_lost = true
		global.game_reset_tick = game.tick + 1800
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_lost", volume_modifier=0.75}
		end
	end
	rendering.set_text(objective.health_text, "HP: " .. objective.health .. " / " .. objective.max_health)
end

local function isprotected(entity)
	local protected = {global.locomotive, global.locomotive_cargo, global.locomotive_cargo2, global.locomotive_cargo3}
	if entity.surface.name == "cargo_wagon" then return true end
	for i = 1, #global.comfychests,1 do
		table.insert(protected, global.comfychests[i])
	end
	for index = 1, #protected do
    if protected[index] == entity then
      return true
    end
  end
end

local function protect_entity(event)
	if event.entity.force.index ~= 1 then return end --Player Force
	if isprotected(event.entity) then
		if event.cause then
			if event.cause.force.index == 2 then
				set_objective_health(event.final_damage_amount)
			end
		end
		if not event.entity.valid then return end
		event.entity.health = event.entity.health + event.final_damage_amount
	end
end

local function biters_chew_rocks_faster(event)
	if event.entity.force.index ~= 3 then return end --Neutral Force
	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.force.index ~= 2 then return end --Enemy Force
	event.entity.health = event.entity.health - event.final_damage_amount * 5
end

local function on_entity_damaged(event)
	if not event.entity.valid then	return end
	protect_entity(event)
	if not event.entity.valid then	return end
	if not event.entity.health then return end
	biters_chew_rocks_faster(event)
	if global.objective.planet[1].name.name == "lava planet" and event.entity.force.name == "enemy" then
		if event.damage_type.name == "fire" then
			event.entity.health = event.entity.health + event.final_damage_amount
			local fire = event.entity.stickers
			if fire and #fire > 0 then
				for i = 1, #fire, 1 do
					if fire[i].sticked_to == event.entity and fire[i].name == "fire-sticker" then fire[i].destroy() break end
				end
			end
		end
	end

end

local function trap(entity)
	if math_random(1,256) == 1 then tick_tack_trap(entity.surface, entity.position) return end
	if math_random(1,128) == 1 then unearthing_worm(entity.surface, entity.surface.find_non_colliding_position("big-worm-turret",entity.position,5,1)) end
	if math_random(1,64) == 1 then unearthing_biters(entity.surface, entity.position, math_random(4,8)) end
end

local function get_choppy_amount(entity)
	local distance_to_center = 20 * global.objective.chronojumps
	local amount = (40 + distance_to_center ) * (1 + game.forces.player.mining_drill_productivity_bonus)
	if amount > 1000 then amount = 1000 end
	amount = math_random(math_floor(amount * 0.5), math_floor(amount * 1.5))
	return amount
end

local function pre_player_mined_item(event)
	local surface = game.surfaces[global.active_surface_index]
	local player = game.players[event.player_index]
	local objective = global.objective
	if objective.planet[1].name.name == "rocky planet" then
		if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
			trap(event.entity)
			local rock_position = {x = event.entity.position.x, y = event.entity.position.y}
			event.entity.destroy()
			local tile_distance_to_center = 40 + 40 * objective.chronojumps * (1 + game.forces.player.mining_drill_productivity_bonus)
			if tile_distance_to_center > 1450 then tile_distance_to_center = 1450 end
			surface.spill_item_stack(player.position,{name = "raw-fish", count = math_random(1,3)},true)
			local bonus_amount = math_floor((tile_distance_to_center) + 1)
			if bonus_amount < 0 then bonus_amount = 0 end
			local amount = math_random(25,45) + bonus_amount
			if amount > 500 then amount = 500 end
			amount = math_floor(amount * (1+game.forces.player.mining_drill_productivity_bonus))
			local rock_mining = {"iron-ore", "iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "copper-ore", "stone", "stone", "coal", "coal"}
			local mined_loot = rock_mining[math_random(1,#rock_mining)]
			surface.create_entity({
				name = "flying-text",
				position = rock_position,
				text = "+" .. amount .. " [img=item/" .. mined_loot .. "]",
				color = {r=0.98, g=0.66, b=0.22}
			})
			local i = player.insert {name = mined_loot, count = amount}
			amount = amount - i
			if amount > 0 then
				surface.spill_item_stack(rock_position,{name = mined_loot, count = amount},true)
			end
		end
	end
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "tree" and global.objective.planet[1].name.name == "choppy planet" then
		trap(entity)
		if choppy_entity_yield[entity.name] then
			if event.buffer then event.buffer.clear() end
			if not event.player_index then return end
			local amount = get_choppy_amount(entity)
			local second_item_amount = math_random(2,5)
			local second_item = "wood"
			local main_item = choppy_entity_yield[entity.name][math_random(1,#choppy_entity_yield[entity.name])]

			entity.surface.create_entity({
				name = "flying-text",
				position = entity.position,
				text = "+" .. amount .. " [item=" .. main_item .. "] +" .. second_item_amount .. " [item=" .. second_item .. "]",
				color = {r=0.8,g=0.8,b=0.8}
			})

			local player = game.players[event.player_index]

			local inserted_count = player.insert({name = main_item, count = amount})
			amount = amount - inserted_count
			if amount > 0 then
				entity.surface.spill_item_stack(entity.position,{name = main_item, count = amount}, true)
			end

			local inserted_count = player.insert({name = second_item, count = second_item_amount})
			second_item_amount = second_item_amount - inserted_count
			if second_item_amount > 0 then
				entity.surface.spill_item_stack(entity.position,{name = second_item, count = second_item_amount}, true)
			end
		end
	end
	if entity.name == "rock-huge" or entity.name == "rock-big" or entity.name == "sand-rock-big" then
		if global.objective.planet[1].name.name ~= "rocky planet" then
			prospect_ores(entity)
		elseif
			global.objective.planet[1].name.name == "rocky planet" then event.buffer.clear()
		end
	end
end

local function shred_simple_entities(entity)
	--game.print(entity.name)
	if game.forces["enemy"].evolution_factor < 0.25 then return end
	local simple_entities = entity.surface.find_entities_filtered({type = {"simple-entity", "tree"}, area = {{entity.position.x - 3, entity.position.y - 3},{entity.position.x + 3, entity.position.y + 3}}})
	if #simple_entities == 0 then return end
	for i = 1, #simple_entities, 1 do
		if not simple_entities[i] then break end
		if simple_entities[i].valid then
			simple_entities[i].die("enemy", simple_entities[i])
		end
	end
end

local function on_entity_died(event)

	if event.entity.type == "tree" and global.objective.planet[1].name.name == "choppy planet" then
		if event.cause then
			if event.cause.valid then
				if event.cause.force.index ~= 2 then
					trap(event.entity)
				end
			end
		end
		-- if not event.entity.valid then return end
		-- for _, entity in pairs (event.entity.surface.find_entities_filtered({area = {{event.entity.position.x - 4, event.entity.position.y - 4},{event.entity.position.x + 4, event.entity.position.y + 4}}, name = "fire-flame-on-tree"})) do
		-- 	if entity.valid then entity.destroy() end
		-- end
		--return
	end
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "unit" and entity.force == "enemy" then
		global.objective.active_biters[entity.unit_number] = nil
	end
	if entity.force.index == 3 then
		if event.cause then
			if event.cause.valid then
				if event.cause.force.index == 2 then
					shred_simple_entities(entity)
				end
			end
		end
	end

	--on_player_mined_entity(event)
	--if not event.entity.valid then return end
end

local function on_research_finished(event)
	event.research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 100 + global.objective.invupgradetier * 5
	if not event.research.force.technologies["steel-axe"].researched then return end
	event.research.force.manual_mining_speed_modifier = 1 + game.forces.player.mining_drill_productivity_bonus * 4
end

local function on_player_driving_changed_state(event)
	local player = game.players[event.player_index]
	local vehicle = event.entity
	Locomotive.enter_cargo_wagon(player, vehicle)
end

-- function deny_building(event)
-- 	local entity = event.created_entity
-- 	if not entity.valid then return end
-- 	local surface = event.created_entity.surface
--
-- 	if event.player_index then
-- 		game.players[event.player_index].insert({name = entity.name, count = 1})
-- 	else
-- 		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
-- 		inventory.insert({name = entity.name, count = 1})
-- 	end
--
-- 	surface.create_entity({
-- 		name = "flying-text",
-- 		position = entity.position,
-- 		text = "Private Comfylatron's area!",
-- 		color = {r=0.98, g=0.66, b=0.22}
-- 	})
--
-- 	entity.destroy()
-- end

-- local function on_built_entity(event)
-- 	if event.surface.name == "cargo_wagon" and event.position.y < -190 then
-- 		deny_building(event)
-- 	end
-- end
--
-- local function on_robot_built_entity(event)
-- 	if event.surface.name == "cargo_wagon" and event.position.y < -190 then
-- 		deny_building(event)
-- 	end
-- 	Terrain.deny_construction_bots(event)
-- end
-- local function on_market_item_purchased(event)
-- 	Locomotive.offer_purchased(event)
-- end

local function on_player_changed_position(event)
	if global.objective.planet[1].name.name ~= "lava planet" then return end
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving then return end
	if player.surface.name == "cargo_wagon" then return end
	if not global.flame_boots[player.index].steps then global.flame_boots[player.index].steps = {} end
	local steps = global.flame_boots[player.index].steps

	local elements = #steps

	steps[elements + 1] = {x = player.position.x, y = player.position.y}

	if elements > 10 then
		player.surface.create_entity({name = "fire-flame", position = steps[elements - 1], })
		for i = 1, elements, 1 do
			steps[i] = steps[i+1]
		end
		steps[elements + 1] = nil
	end
end

local event = require 'utils.event'
event.on_init(on_init)
event.on_nth_tick(2, tick)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
--event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_pre_player_mined_item, pre_player_mined_item)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_research_finished, on_research_finished)
--event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
event.add(defines.events.on_player_changed_position, on_player_changed_position)

return Public
