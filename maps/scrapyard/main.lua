require "on_tick_schedule"
require "modules.dynamic_landfill"
require "modules.mineable_wreckage_yields_ores"
require "modules.rocks_heal_over_time"
require "modules.rocks_yield_ore_veins"
require "modules.spawners_contain_biters"
require "modules.biters_yield_coins"
require "modules.dangerous_goods"
require "modules.wave_defense.main"

local WD = require "modules.wave_defense.table"
local Map = require 'modules.map_info'
local RPG = require 'modules.rpg'
local Reset = require "functions.soft_reset"
local BiterRolls = require "modules.wave_defense.biter_rolls"

local Loot = require 'maps.scrapyard.loot'
local Pets = require "modules.biter_pets"
local Modifier = require "player_modifiers"
local tick_tack_trap = require "functions.tick_tack_trap"
local Terrain = require 'maps.scrapyard.terrain'
local Event = require 'utils.event'
local math_random = math.random

local Locomotive = require "maps.scrapyard.locomotive".locomotive_spawn

local Public = {}

local disabled_for_deconstruction = {["fish"] = true, ["rock-huge"] = true,	["rock-big"] = true, ["sand-rock-big"] = true, ["mineable-wreckage"] = true}
local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['wood'] = 4, ['rail'] = 16, ['raw-fish'] = 2}

local treasure_chest_messages = {
	"You notice an old crate within the rubble. It's filled with treasure!",
	"You find a chest underneath the broken rocks. It's filled with goodies!",
	"We has found the precious!",
}

function Public.reset_map()
	global.spawn_generated = false
	local wave_defense_table = WD.get_table()

	local map_gen_settings = {
		["seed"] = math_random(1, 1000000),
		["water"] = 0.001,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = true,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = true},
			["decorative"] = {treat_missing_as_default = true},
		},
	}

	if not global.active_surface_index then
		global.active_surface_index = game.create_surface("scrapyard", map_gen_settings).index
	else
		game.forces.player.set_spawn_position({0, 0}, game.surfaces[global.active_surface_index])
		global.active_surface_index = Reset.soft_reset_map(game.surfaces[global.active_surface_index], map_gen_settings, starting_items).index
	end

	local surface = game.surfaces[global.active_surface_index]

	surface.request_to_generate_chunks({0,0}, 2)
	surface.force_generate_chunk_requests()


	local p = surface.find_non_colliding_position("character-corpse", {2,-2}, 32, 2)
	surface.create_entity({name = "character-corpse", position = p})

	game.forces.player.technologies["landfill"].enabled = false
	game.forces.player.technologies["optics"].researched = true
	game.forces.player.set_spawn_position({0, 0}, surface)

	surface.ticks_per_day = surface.ticks_per_day * 2
	surface.min_brightness = 0.08
	surface.daytime = 0.7

	Locomotive(surface, {x = -18, y = 10})

	rendering.draw_text{
		text = "Welcome to Scrapyard!",
		surface = surface,
		target = {-0,30},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}

	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,40},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,50},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,60},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,70},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,80},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,90},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,100},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "▼",
		surface = surface,
		target = {-0,110},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}
	rendering.draw_text{
		text = "Biters will attack this area.",
		surface = surface,
		target = {-0,120},
		color = { r=0.98, g=0.66, b=0.22},
		scale = 3,
		font = "heading-1",
		alignment = "center",
		scale_with_zoom = false
		}

	WD.reset_wave_defense()
	wave_defense_table.surface_index = global.active_surface_index
	wave_defense_table.target = global.locomotive_cargo
	wave_defense_table.nest_building_density = 32
	wave_defense_table.game_lost = false
	wave_defense_table.spawn_position = {x=0,y=220}

	surface.create_entity({name = "electric-beam", position = {-96, 190}, source = {-96, 190}, target = {96,190}})
	surface.create_entity({name = "electric-beam", position = {-96, 190}, source = {-96, 190}, target = {96,190}})

	RPG.rpg_reset_all_players()
end

local function protect_train(event)
	if event.entity.force.index ~= 1 then return end --Player Force
	if event.entity == global.locomotive_cargo then
		if event.cause then
			if event.cause.force.index == 2 then
				return
			end
		end
		event.entity.health = event.entity.health + event.final_damage_amount
	end
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	local surface = game.surfaces[global.active_surface_index]
	if player.position.y < 20 then Terrain.reveal(player) end
	if player.position.y >= 190 then
		player.teleport({player.position.x, player.position.y - 1}, surface)
		player.print("The forcefield does not approve.",{r=0.98, g=0.66, b=0.22})
		if player.character then
			player.character.health = player.character.health - 5
			player.character.surface.create_entity({name = "water-splash", position = player.position})
			if player.character.health <= 0 then player.character.die("enemy") end
		end
	end
end

local function on_marked_for_deconstruction(event)
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_player_joined_game(event)
	local surface = game.surfaces[global.active_surface_index]
	local player = game.players[event.player_index]


	if player.surface.index ~= global.active_surface_index then
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 3, 0,5), surface)
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end

	global.player_modifiers[player.index].character_mining_speed_modifier["scrapyard"] = 0
	Modifier.update_player_modifiers(player)
	if global.first_load then return end
	Public.reset_map()
	global.first_load = true
end

local function hidden_biter(entity)
	BiterRolls.wave_defense_set_unit_raffle(math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2) * 0.25)
	if math.random(1,3) == 1 then
		entity.surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = entity.position})
	else
		entity.surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = entity.position})
	end
end

local function hidden_worm(entity)
	BiterRolls.wave_defense_set_worm_raffle(math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2) * 0.25)
	entity.surface.create_entity({name = BiterRolls.wave_defense_roll_worm_name(), position = entity.position})
end

local function hidden_biter_pet(event)
	if math.random(1, 2048) ~= 1 then return end
	BiterRolls.wave_defense_set_unit_raffle(math.sqrt(event.entity.position.x ^ 2 + event.entity.position.y ^ 2) * 0.25)
	local unit
	if math.random(1,3) == 1 then
		unit = event.entity.surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = event.entity.position})
	else
		unit = event.entity.surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = event.entity.position})
	end
	Pets.biter_pets_tame_unit(game.players[event.player_index], unit, true)
end

local function hidden_treasure(event)
	if math.random(1, 320) ~= 1 then return end
	game.players[event.player_index].print(treasure_chest_messages[math.random(1, #treasure_chest_messages)], {r=0.98, g=0.66, b=0.22})
	Loot.create_loot(event.entity.surface, event.entity.position, "wooden-chest")
end

local function give_coin(player)
	player.insert({name = "coin", count = 1})
end


local function on_player_mined_entity(event)
	local entity = event.entity
	local player = game.players[event.player_index]
	if not player.valid then
	    return
	end
	if not entity.valid then
		return
	end

	if math_random(1,160) == 1 then tick_tack_trap(entity.surface, entity.position) return end

	if entity.name == "mineable-wreckage" then
		give_coin(player)

		if math.random(1,32) == 1 then
			hidden_biter(event.entity)
			return
		end
		if math.random(1,512) == 1 then
			hidden_worm(event.entity)
			return
		end
		hidden_biter_pet(event)
		hidden_treasure(event)

	end

	if entity.force.name ~= "scrap" then return end
end

local function on_entity_damaged(event)
	if not event.entity.valid then	return end
	protect_train(event)
end

local function on_entity_died(event)
	local wave_defense_table = WD.get_table()
	local entity = event.entity
	if not entity.valid then
		return
	end

	if event.entity == global.locomotive_cargo then
		game.print("Fools! The cargo was destroyed!")
		wave_defense_table.game_lost = true
		wave_defense_table.target = nil
		global.game_reset_tick = game.tick + 1800
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_lost", volume_modifier=0.75}
		end
		event.entity.surface.spill_item_stack(event.entity.position,{name = "raw-fish", count = 512}, false)
		return
	end

	if math_random(1,160) == 1 then tick_tack_trap(entity.surface, entity.position) return end

	if entity.name == "mineable-wreckage" then
		if math.random(1,32) == 1 then
			hidden_biter(event.entity)
			return
		end
		if math.random(1,512) == 1 then
			hidden_worm(event.entity)
			return
		end
	end
end

local function on_research_finished(event)
	event.research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 50 -- +5 Slots / level
	local mining_speed_bonus = game.forces.player.mining_drill_productivity_bonus * 5 -- +50% speed / level
	if event.research.force.technologies["steel-axe"].researched then mining_speed_bonus = mining_speed_bonus + 0.5 end -- +50% speed for steel-axe research
	event.research.force.manual_mining_speed_modifier = mining_speed_bonus
end

local on_init = function()
	Public.reset_map()
	local T = Map.Pop_info()
		T.main_caption = "S c r a p y a r d"
		T.sub_caption =  "    ---defend the choo---"
		T.text = table.concat({
		"The biters have catched the scent of fish in the cargo wagon.\n",
		"Guide the choo through the black mist and protect it for as long as possible!\n",
		"This will not be an easy task however,\n",
		"since their strength and numbers increase over time.\n",
		"\n",
		"Delve deep for greater treasures, but also face increased dangers.\n",
		"Mining productivity research, will overhaul your mining equipment,\n",
		"reinforcing your pickaxe as well as increasing the size of your backpack.\n",
		"\n",
		"Good luck, over and out!"
		})
		T.main_caption_color = {r = 150, g = 150, b = 0}
		T.sub_caption_color = {r = 0, g = 150, b = 0}
		game.create_force("scrap")
		game.create_force("scrap_defense")
		game.forces.player.set_friend('scrap', true)
		game.forces.enemy.set_friend('scrap', true)
		game.forces.scrap.set_friend('player', true)
		game.forces.scrap.set_friend('enemy', true)
		game.forces.scrap.share_chart = false
end


Event.on_init(on_init)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)

return Public