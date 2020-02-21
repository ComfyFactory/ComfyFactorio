-- chronosphere --

require "functions.soft_reset"
require "player_modifiers"
require "functions.basic_markets"
require "modules.difficulty_vote"

require "modules.biters_yield_coins"
require "modules.no_deconstruction_of_neutral_entities"
--require "modules.no_solar"
require "modules.shotgun_buff"
require "modules.mineable_wreckage_yields_scrap"
require "maps.chronosphere.comfylatron"
require "maps.chronosphere.terrain"
require "on_tick_schedule"
require "modules.biter_noms_you"
local Server = require 'utils.server'
local Ai = require "maps.chronosphere.ai"
local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"
local tick_tack_trap = require "functions.tick_tack_trap"
local Planets = require "maps.chronosphere.chronobubles"
local Ores =require "maps.chronosphere.ores"
local Reset = require "functions.soft_reset"
local Map = require "modules.map_info"
local Upgrades = require "maps.chronosphere.upgrades"
local Locomotive = require "maps.chronosphere.locomotive"
local Modifier = require "player_modifiers"
local update_gui = require "maps.chronosphere.gui"
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt
--local chests = {}
--local acus = {}
global.objective = {}
global.flame_boots = {}
global.comfylatron = nil
global.lab_cells = {}


local choppy_entity_yield = {
		["tree-01"] = {"iron-ore"},
		["tree-02-red"] = {"copper-ore"},
		["tree-04"] = {"coal"},
		["tree-08-brown"] = {"stone"}
	}

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 32, ['grenade'] = 4, ['raw-fish'] = 4, ['rail'] = 16, ['wood'] = 16}
local starting_cargo = {['firearm-magazine'] = 16, ['iron-plate'] = 16, ['wood'] = 16, ['burner-mining-drill'] = 8}

local function generate_overworld(surface, optplanet)
	Planets.determine_planet(optplanet)
	local planet = global.objective.planet
	local message = "Planet info: " .. planet[1].name.name .. ", Ore richness: " .. planet[1].ore_richness.name .. ", Speed of day: " .. planet[1].day_speed.name
	game.print(message, {r=0.98, g=0.66, b=0.22})
	Server.to_discord_embed(message)
	if planet[1].name.id == 12 then
		game.print("Comfylatron: OwO what are those strange trees?!? They have ore fruits! WTF!", {r=0.98, g=0.66, b=0.22})
	elseif planet[1].name.id == 14 then
		game.print("Comfylatron: OOF this one is a bit hot. And have seen those biters? They BATHE in fire! Maybe try some bricks to protect from lava?", {r=0.98, g=0.66, b=0.22})
	elseif planet[1].name.id == 17 then
		game.print("Comfylatron: So here we are. Fish Market. When they ordered the fish, they said this location is perfectly safe. Looks like we will have to do it for them. I hope you have enough nukes.", {r=0.98, g=0.66, b=0.22})
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
	if planet[1].name.id == 8 then --water planet
		local mgs = surface.map_gen_settings
		mgs.water = 0.8
		surface.map_gen_settings = mgs
	end
	if planet[1].name.id == 14 then --lava planet
		local mgs = surface.map_gen_settings
		mgs.water = 0
		surface.map_gen_settings = mgs
	end
	if planet[1].name.id ~= 12 then --choppy planet
		local mgs = surface.map_gen_settings
		mgs.water = 0.2
		surface.map_gen_settings = mgs
	end
	if planet[1].name.id == 17 then --fish market
		local mgs = surface.map_gen_settings
		mgs.width = 2176
		surface.map_gen_settings = mgs
		surface.request_to_generate_chunks({-960,-64}, 3)
		--surface.request_to_generate_chunks({0,0}, 3)
		surface.force_generate_chunk_requests()
	else
		surface.request_to_generate_chunks({0,0}, 3)
		surface.force_generate_chunk_requests()
	end
	--log(timer)
	--surface.solar_power_multiplier = 999



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
		["width"] = 960,
		["height"] = 960,
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


local function reset_map()

	global.chunk_queue = {}
	if game.surfaces["chronosphere"] then game.delete_surface(game.surfaces["chronosphere"]) end
	if game.surfaces["cargo_wagon"] then game.delete_surface(game.surfaces["cargo_wagon"]) end
	--chests = {}
	local objective = global.objective
	objective.computerupgrade = 0
	objective.computerparts = 0
	local map_gen_settings = get_map_gen_settings()
	Planets.determine_planet(nil)
	local planet = global.objective.planet
	if not global.active_surface_index then
		global.active_surface_index = game.create_surface("chronosphere", map_gen_settings).index
	else
		game.forces.player.set_spawn_position({12, 10}, game.surfaces[global.active_surface_index])
		global.active_surface_index = Reset.soft_reset_map(game.surfaces[global.active_surface_index], map_gen_settings, starting_items).index
	end

	local surface = game.surfaces[global.active_surface_index]
	generate_overworld(surface, planet)


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
	objective.poisondefense = 2
	objective.poisontimeout = 0
	objective.chronojumps = 0
	objective.chronotimer = 0
	objective.passivetimer = 0
	objective.passivejumps = 0
	objective.chrononeeds = 2000
	objective.mainscore = 0
	objective.active_biters = {}
	objective.unit_groups = {}
	objective.biter_raffle = {}
	global.outchests = {}
	global.upgradechest = {}
	global.fishchest = {}




	game.difficulty_settings.technology_price_multiplier = 0.6
	game.map_settings.enemy_evolution.destroy_factor = 0.005
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 7e-05
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.settler_group_max_size = 8
	game.map_settings.enemy_expansion.settler_group_min_size = 16
	game.map_settings.pollution.enabled = true
	game.map_settings.pollution.pollution_restored_per_tree_damage = 0.02
	game.map_settings.pollution.min_pollution_to_damage_trees = 1
	game.map_settings.pollution.max_pollution_to_restore_trees = 0
	game.map_settings.pollution.pollution_with_max_forest_damage = 10
	game.map_settings.pollution.pollution_per_tree_damage = 0.1
	game.map_settings.pollution.ageing = 0.1
	game.map_settings.pollution.diffusion_ratio = 0.1
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 5
	game.forces["enemy"].evolution_factor = 0.0001

	game.forces.player.technologies["land-mine"].enabled = false
	game.forces.player.technologies["landfill"].enabled = false
	game.forces.player.technologies["railway"].researched = true
	game.forces.player.set_spawn_position({12, 10}, surface)
	local wagons = {}
	wagons[1] = {inventory = starting_cargo, bar = 0, filters = {}}
	wagons[2] = {inventory = starting_cargo, bar = 0, filters = {}}
	for i = 1, 40, 1 do
		wagons[1].filters[i] = nil
		wagons[2].filters[i] = nil
	end
	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, wagons)
	render_train_hp()
	game.reset_time_played()
	global.difficulty_poll_closing_timeout = game.tick + 54000
	global.difficulty_player_votes = {}
	if objective.game_won then
		game.print("Comfylatron: WAIT whaat? Looks like we did not fixed the train properly and it teleported us back in time...sigh...so let's do this again, and now properly.", {r=0.98, g=0.66, b=0.22})
	end
	objective.game_lost = false
	objective.game_won = false

	--set_difficulty()
end

local function on_player_joined_game(event)
	local player_modifiers = Modifier.get_table()
	local player = game.players[event.player_index]
	global.flame_boots[event.player_index] = {fuel = 1}
	if not global.flame_boots[event.player_index].steps then global.flame_boots[event.player_index].steps = {} end
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
		local inv = global.upgradechest[1].get_inventory(defines.inventory.chest)
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

local function chronojump(choice)
	local objective = global.objective
	if objective.game_lost then return end
	local overstayed = false
	if objective.passivetimer > objective.chrononeeds * 0.75 and objective.chronojumps > 5 then
		overstayed = true
		objective.passivejumps = objective.passivejumps + 1
	end
	objective.chronojumps = objective.chronojumps + 1
	objective.chrononeeds = 2000 + 500 * objective.chronojumps
	objective.passivetimer = 0
	objective.chronotimer = 0
	local message = "Comfylatron: Wheeee! Time Jump Active! This is Jump number " .. global.objective.chronojumps
	game.print(message, {r=0.98, g=0.66, b=0.22})
	Server.to_discord_embed(message)
	local oldsurface = game.surfaces[global.active_surface_index]

	for _,player in pairs(game.players) do
		if player.surface == oldsurface then
			if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
			local wagons = {global.locomotive_cargo, global.locomotive_cargo2, global.locomotive_cargo3}
			Locomotive.enter_cargo_wagon(player, wagons[math_random(1,3)])
		end
	end
	local map_gen_settings = get_map_gen_settings()
	global.lab_cells = {}
	global.active_surface_index = game.create_surface("chronosphere" .. objective.chronojumps, map_gen_settings).index
	local surface = game.surfaces[global.active_surface_index]
	local planet = nil
	if choice then
		Planets.determine_planet(choice)
		planet = global.objective.planet
	end
	generate_overworld(surface, planet)
	if objective.chronojumps == 6 then
		game.print("Comfylatron: Biters start to evolve faster! We need to charge forward or they will be stronger! (hover over timer to see evolve timer)", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronojumps == 15 then
		game.print("Comfylatron: You know...I have big quest. Deliver fish to fish market. But this train is broken. Please help me fix the train computer!", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronojumps == 20 then
		game.print("Comfylatron: Ah, we need to give this machine more power and better navigation chipset. Please bring me some additional things.", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronojumps == 25 then
		game.print("Comfylatron: Finally found the main issue. We will need to rebuild whole processor. Exactly what I feared of. Just a few more things...", {r=0.98, g=0.66, b=0.22})
	end
	if overstayed then game.print("Comfylatron: Looks like you stayed on previous planet for so long that enemies on other planets had additional time to evolve!", {r=0.98, g=0.66, b=0.22}) end
	game.forces.player.set_spawn_position({12, 10}, surface)
	local inventories = {one = global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon), two = global.locomotive_cargo3.get_inventory(defines.inventory.cargo_wagon)}
	inventories.one.sort_and_merge()
	inventories.two.sort_and_merge()
	local wagons = {}
	wagons[1] = {inventory = inventories.one.get_contents(), bar = inventories.one.get_bar(), filters = {}}
	wagons[2] = {inventory = inventories.two.get_contents(), bar = inventories.two.get_bar(), filters = {}}
	for i = 1, 40, 1 do
		wagons[1].filters[i] = inventories.one.get_filter(i)
		wagons[2].filters[i] = inventories.two.get_filter(i)
	end
	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, wagons)
	render_train_hp()
	game.delete_surface(oldsurface)
	game.forces.enemy.reset_evolution()
	if objective.chronojumps + objective.passivejumps <= 40 and objective.planet[1].name.id ~= 17 then
		game.forces.enemy.evolution_factor = 0 + 0.025 * (objective.chronojumps + objective.passivejumps)
	else
		game.forces.enemy.evolution_factor = 1
	end
	if objective.planet[1].name.id == 17 then
		objective.chrononeeds = 200000000
	end
	game.map_settings.enemy_evolution.time_factor = 7e-05 + 3e-06 * (objective.chronojumps + objective.passivejumps)
	surface.pollute(global.locomotive.position, 150 * (4 / (objective.filterupgradetier / 2 + 1)) * (1 + global.objective.chronojumps))
	game.forces.scrapyard.set_ammo_damage_modifier("bullet", 0.01 * objective.chronojumps)
	game.forces.scrapyard.set_turret_attack_modifier("gun-turret", 0.01 * objective.chronojumps)
	game.forces.enemy.set_ammo_damage_modifier("melee", 0.1 * objective.passivejumps)
	game.forces.enemy.set_ammo_damage_modifier("biological", 0.1 * objective.passivejumps)
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 0.8
end

local function check_chronoprogress()
	local objective = global.objective
	--game.print(objective.chronotimer)
	if objective.chronotimer == objective.chrononeeds - 180  then
		game.print("Comfylatron: Acumulator charging disabled, 180 seconds countdown to jump!", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer == objective.chrononeeds - 60  then
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
	if objective.planet[1].name.id == 17 then return end
	local acus = global.acumulators
	if #acus < 1 then return end
	for i = 1, #acus, 1 do
		if not acus[i].valid then return end
		local energy = acus[i].energy
		if energy > 3000000 and objective.chronotimer < objective.chrononeeds - 182 and objective.chronotimer > 130 then
			acus[i].energy = acus[i].energy - 3000000
			objective.chronotimer = objective.chronotimer + 1
			game.surfaces[global.active_surface_index].pollute(global.locomotive.position, (10 + 2 * objective.chronojumps) * (4 / (objective.filterupgradetier / 2 + 1)) * global.difficulty_vote_value)
			--log("energy charged from acu")
		end
	end
end

local function transfer_pollution()
	local surface = game.surfaces["cargo_wagon"]
	if not surface then return end
	local pollution = surface.get_total_pollution() * (3 / (global.objective.filterupgradetier / 3 + 1)) * global.difficulty_vote_value
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
		if global.objective.planet[1].name.id == 17 then
			surface.request_to_generate_chunks({-800,0}, 3 + math_floor(global.objective.chronotimer / 5))
		else
			surface.request_to_generate_chunks({0,0}, 3 + math_floor(global.objective.chronotimer / 5))
		end
		--surface.force_generate_chunk_requests()


	end
	if tick % 30 == 0 then
		if tick % 600 == 0 then
			charge_chronosphere()
			transfer_pollution()
			if global.objective.poisontimeout > 0 then
				global.objective.poisontimeout = global.objective.poisontimeout - 1
			end
		end
		if tick % 1800 == 0 then
			Locomotive.set_player_spawn_and_refill_fish()
			repair_train()
			Upgrades.check_upgrades()
		end
		local key = tick % 3600
		if tick_minute_functions[key] then tick_minute_functions[key]() end
		if tick % 60 == 0 and global.objective.planet[1].name.id ~= 17 then
			global.objective.chronotimer = global.objective.chronotimer + 1
			global.objective.passivetimer = global.objective.passivetimer + 1
			check_chronoprogress()
		end
		if tick % 120 == 0 then
			move_items()
			output_items()
		end
		if global.game_reset_tick then
			if global.game_reset_tick < tick then
				global.game_reset_tick = nil
				reset_map()
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
	global.objective.game_won = false
	game.create_force("scrapyard")
	game.forces.scrapyard.set_friend('enemy', true)
	game.forces.enemy.set_friend('scrapyard', true)
	--global.rocks_yield_ore_maximum_amount = 999
	--global.rocks_yield_ore_base_amount = 50
	--global.rocks_yield_ore_distance_modifier = 0.025
	--if game.surfaces["nauvis"] then game.delete_surface(game.surfaces["nauvis"]) end
	reset_map()
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
		return
	end
	if objective.health < objective.max_health / 2 and final_damage_amount > 0 and objective.poisondefense > 0 and objective.poisontimeout == 0 then
		objective.poisondefense = objective.poisondefense - 1
		objective.poisontimeout = 120
		local objs = {global.locomotive, global.locomotive_cargo, global.locomotive_cargo2, global.locomotive_cargo3}
		local surface = objective.surface
		game.print("Comfylatron: Triggering poison defense. Let's kill everything!", {r=0.98, g=0.66, b=0.22})
		for i = 1, 4, 1 do
			surface.create_entity({name = "poison-capsule", position = objs[i].position, force = "player", target = objs[i], speed = 1 })
		end
		for i = 1 , #global.comfychests, 1 do
			surface.create_entity({name = "poison-capsule", position = global.comfychests[i].position, force = "player", target = global.comfychests[i], speed = 1 })
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
			if event.cause == global.comfylatron or event.entity == global.comfylatron then
				return
			end
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
	if global.objective.planet[1].name.id == 14 and event.entity.force.name == "enemy" then --lava planet
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

local function trap(entity, trap)
	if trap then
		tick_tack_trap(entity.surface, entity.position)
		tick_tack_trap(entity.surface, {x = entity.position.x + math_random(-2,2), y = entity.position.y + math_random(-2,2)})
		return
	end
	if math_random(1,256) == 1 then tick_tack_trap(entity.surface, entity.position) return end
	if math_random(1,128) == 1 then unearthing_worm(entity.surface, entity.surface.find_non_colliding_position("big-worm-turret",entity.position,5,1)) end
	if math_random(1,64) == 1 then unearthing_biters(entity.surface, entity.position, math_random(4,8)) end
end

local function get_ore_amount()
	local scaling = 5 * global.objective.chronojumps
	local amount = (30 + scaling ) * (1 + game.forces.player.mining_drill_productivity_bonus) * global.objective.planet[1].ore_richness.factor
	if amount > 600 then amount = 600 end
	amount = math_random(math_floor(amount * 0.7), math_floor(amount * 1.3))
	return amount
end

local function pre_player_mined_item(event)
	local surface = game.surfaces[global.active_surface_index]
	local player = game.players[event.player_index]
	local objective = global.objective
	if objective.planet[1].name.id == 11 then --rocky planet
		if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
			trap(event.entity, false)
			event.entity.destroy()
			surface.spill_item_stack(player.position,{name = "raw-fish", count = math_random(1,3)},true)
			local amount = get_ore_amount()
			local rock_mining = {"iron-ore", "iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "copper-ore", "stone", "stone", "coal", "coal"}
			local mined_loot = rock_mining[math_random(1,#rock_mining)]
			surface.create_entity({
				name = "flying-text",
				position = {player.position.x, player.position.y - 0.5},
				text = "+" .. amount .. " [img=item/" .. mined_loot .. "]",
				color = {r=0.98, g=0.66, b=0.22}
			})
			local i = player.insert {name = mined_loot, count = amount}
			amount = amount - i
			if amount > 0 then
				surface.spill_item_stack(player.position, {name = mined_loot, count = amount},true)
				--surface.create_entity{name="item-on-ground", position=game.player.position, stack={name=mined_loot, count=50}}
			end
		end
	end
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "tree" and global.objective.planet[1].name.id == 12 then --choppy planet
		trap(entity, false)
		if choppy_entity_yield[entity.name] then
			if event.buffer then event.buffer.clear() end
			if not event.player_index then return end
			local amount = get_ore_amount()
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
				entity.surface.spill_item_stack(player.position,{name = main_item, count = amount}, true)
			end

			local inserted_count = player.insert({name = second_item, count = second_item_amount})
			second_item_amount = second_item_amount - inserted_count
			if second_item_amount > 0 then
				entity.surface.spill_item_stack(entity.position,{name = second_item, count = second_item_amount}, true)
			end
		end
	end
	if entity.name == "rock-huge" or entity.name == "rock-big" or entity.name == "sand-rock-big" then
		if global.objective.planet[1].name.id ~= 11 and global.objective.planet[1].name.id ~= 16 then --rocky and maze planet
			Ores.prospect_ores(entity, entity.surface, entity.position)
		elseif
			global.objective.planet[1].name.id == 11 then event.buffer.clear() -- rocky planet
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

	if event.entity.type == "tree" and global.objective.planet[1].name.id == 12 then --choppy planet
		if event.cause then
			if event.cause.valid then
				if event.cause.force.index ~= 2 then
					trap(event.entity, false)
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
	if entity.force.name == "scrapyard" and entity.name == "gun-turret" and global.objective.planet[1].name.id == 16 then
		trap(entity, true)
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
	if global.objective.planet[1].name.id ~= 14 then return end --lava planet
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving then return end
	if player.surface.name == "cargo_wagon" then return end
	local safe = {"stone-path", "concrete", "hazard-concrete-left", "hazard-concrete-right", "refined-concrete", "refined-hazard-concrete-left", "refined-hazard-concrete-right"}
	local pavement = player.surface.get_tile(player.position.x, player.position.y)
	for i = 1, 7, 1 do
		if pavement.name == safe[i] then return end
	end
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

if _DEBUG then
	local Session = require 'utils.session_data'
	local Color = require 'utils.color_presets'

	commands.add_command(
	    'chronojump',
	    'Weeeeee!',
	    function(cmd)
	        local player = game.player
	        local trusted = Session.get_trusted_table()
	        local param = tostring(cmd.parameter)
	        local p

	        if player then
	            if player ~= nil then
	                p = player.print
	                if not trusted[player.name] then
	                    if not player.admin then
	                        p("[ERROR] Only admins and trusted weebs are allowed to run this command!", Color.fail)
	                        return
	                    end
	                end
	            else
	                p = log
	            end
	        end
	        chronojump(param)
	end)
end
