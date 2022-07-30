-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Math = require 'maps.pirates.math'
local _inspect = require 'utils.inspect'.inspect

local Public = {}

Public.scenario_id_name = 'pirates'
Public.version_string = '1.3.3' --major.minor.patch versioning, to match factorio mod portal

Public.blueprint_library_allowed = true
Public.blueprint_importing_allowed = true

Public.rocket_silo_death_causes_loss = false

Public.victory_x = 1000

Public.total_max_biters = 2000

Public.lobby_surface_name = '000-000-Lobby'

Public.colors = {
	coal = {r=0.5, g=0.5, b=0.5},
	wood = {r=204, g=158, b=67},
	stone = {r=230, g=220, b=190},
	coin = {r=242, g=193, b=97},
	oil = {r=181, g=107, b=91},
	['raw-fish'] = {r=0, g=237, b=170},
	['iron-plate'] = {r=170, g=180, b=190},
	['iron-ore'] = {r=170, g=180, b=190},
	['copper-plate'] = {r=219, g=149, b=96},
	['copper-ore'] = {r=219, g=149, b=96},
	notify_error = {r=170, g=170, b=170},
	notify_player_expected = {r=255, g=231, b=46},
	notify_player_announce = {r=244, g=255, b=145},
	notify_game = {r=249, g=103, b=56},
	notify_lobby = {r=249, g=153, b=56},
	notify_force = {r=249, g=153, b=56},
	notify_force_light = {r=255, g=220, b=161},
	parrot = {r=87, g=255, b=148},
	notify_victory = {r=84, g=249, b=84},
	notify_gameover = {r=249, g=84, b=84},
	renderingtext_green = {r=88, g=219, b=88},
	renderingtext_yellow = {r=79, g=136, b=209},
	quartermaster_rendering = {r=237, g=157, b=45, a=0.15},
	toughness_rendering = {r=40, g=40, b=40, a=0.5},
}

Public.static_boat_floor = 'brown-refined-concrete'
Public.moving_boat_floor = 'lab-dark-2'
Public.world_concrete_tile = 'black-refined-concrete'
Public.walkway_tile = 'orange-refined-concrete'
Public.landing_tile = 'red-refined-concrete'
Public.enemy_landing_tile = 'purple-refined-concrete'
Public.overworld_loading_tile = 'yellow-refined-concrete'
Public.overworld_presence_tile = 'green-refined-concrete'
Public.kraken_tile = 'pink-refined-concrete'

Public.enemy_units = {
	'small-biter',
	'small-spitter',
	'medium-biter',
	'medium-spitter',
	'big-biter',
	'big-spitter',
	'behemoth-biter',
	'behemoth-spitter',
}

Public.water_tile_names = {'water', 'deepwater', 'water-green', 'deepwater-green'}

Public.edgemost_tile_names = {'sand-1'}

Public.tiles_that_conflict_with_resource_layer = {'water', 'deepwater', 'water-green', 'deepwater-green', 'water-shallow', 'water-mud', 'out-of-map'}

Public.tiles_that_conflict_with_resource_layer_extended = {'water', 'deepwater', 'water-green', 'deepwater-green', 'water-shallow', 'water-mud', 'out-of-map', 'red-refined-concrete', 'brown-refined-concrete', 'orange-refined-concrete'}

Public.noworm_tile_names = {'red-refined-concrete', 'purple-refined-concrete', 'green-refined-concrete', 'orange-refined-concrete', 'brown-refined-concrete', 'lab-dark-2', 'sand-1', 'red-desert-3'}

Public.worm_solid_tile_names = {'black-refined-concrete', 'stone-path', 'concrete', 'refined-concrete', 'red-refined-concrete', 'purple-refined-concrete', 'brown-refined-concrete', 'lab-dark-2', 'sand-1', 'red-desert-3'}

Public.unteleportable_names = {'transport-belt', 'underground-belt', 'splitter', 'loader', 'fast-transport-belt', 'fast-underground-belt', 'fast-splitter', 'fast-loader', 'express-transport-belt', 'express-underground-belt', 'express-splitter', 'express-loader',	'pipe', 'pipe-to-ground', 'offshore-pump', 'chemical-plant', 'oil-refinery', 'flamethrower-turret', 'storage-tank', 'assembling-machine-2', 'assembling-machine-3', 'boiler', 'steam-engine', 'heat-exchanger', 'steam-turbine', 'pump', 'straight-rail', 'curved-rail', 'cargo-wagon', 'artillery-turret', 'electric-energy-interface', 'accumulator', 'linked-belt'}


Public.comfy_emojis = {
	monkas = '<:monkas:555120573752279056>',
	trashbin = '<:trashbin:835887736253710396>',
	pogkot = '<:pogkot:763854655612518420>',
	goldenobese = '<:goldenobese:491135683508043786>',
	wut = '<:wut:493320605592977443>',
	smolfish = '<:smolfish:673942701682589731>',
	mjau = '<:mjau:789611417132073010>',
	spurdo = '<:spurdo:669546779360100382>',
	loops = '<:loops:783508194755346462>',
	ree1 = '<:ree1:555118905090244618>',
	derp = '<:derp:527570293850505266>',
	doge = '<:doge:491152224681066496>',
	yum1 = '<:yum1:740341272451219517>',
	feel = '<:feel:491147760553164800>',
	kewl = '<:kewl:837016976937189418>',
}

Public.capacity_options = {
	{value = 2, icon = 'virtual-signal/signal-2', text = '2', text2 = '/2', text3 = '2'},
	{value = 4, icon = 'virtual-signal/signal-4', text = '4', text2 = '/4', text3 = '4'},
	{value = 8, icon = 'virtual-signal/signal-8', text = '8', text2 = '/8', text3 = '8'},
	{value = 24, icon = 'virtual-signal/signal-blue', text = '24', text2 = '/24', text3 = '24'},
	{value = 999, icon = 'virtual-signal/signal-white', text = 'Inf.', text2 = '', text3 = 'Inf'},
	-- {value = 64, icon = 'item/storage-tank', text = '64'},
}

Public.difficulty_options = {
	-- The difficulty values we currently offer

	--For the value of Easy difficulty, we are pulled in two directions: We wish to make the game comfy to play for those who haven't played it, but we also wish to represent the game mechanics faithfully so that Normal is not a crazy distance away.
	{value = 0.5, icon = 'item/firearm-magazine', text = {'pirates.difficulty_easy'}, associated_color = {r = 50, g = 255, b = 50}},

	{value = 0.9, icon = 'item/piercing-rounds-magazine', text = {'pirates.difficulty_normal'}, associated_color = {r = 255, g = 255, b = 50}},

	{value = 1.3, icon = 'item/uranium-rounds-magazine', text = {'pirates.difficutly_hard'}, associated_color = {r = 255, g = 50, b = 50}},

	{value = 1.8, icon = 'item/atomic-bomb', text = {'pirates.difficulty_nightmare'}, associated_color = {r = 170, g = 60, b = 60}},
}
function Public.get_difficulty_option_from_value(difficulty_value)
	-- given a difficulty value, key in to the closesy entry in the above table. (organising things this way allows us to make changes to the 'value' keys in the above table without disrupting e.g. past highscores data)
	if difficulty_value <= 0.75 then
		return 1
	elseif difficulty_value < 1.2 then
		return 2
	elseif difficulty_value <= 1.7 then
		return 3
	else
		return 4
	end
end
function Public.get_difficulty_option_informal_name_from_value(difficulty_value)
	-- given a difficulty value, provide a simple named description of the difficulty. for internal use
	if difficulty_value <= 0.75 then
		return 'easy'
	elseif difficulty_value < 1.2 then
		return 'normal'
	elseif difficulty_value <= 1.7 then
		return 'hard'
	else
		return 'nightmare'
	end
end

-- Public.mode_options = {
-- 	left = {value = 'speedrun', icon = 'achievement/watch-your-step', text = 'Speedrun'},
-- 	right = {value = 'infinity', icon = 'achievement/mass-production-1', text = 'Infinity'},
-- }

Public.daynightcycle_types = {
	{displayname = {'pirates.daynightcycle_static'}, 0},
	{displayname = {'pirates.daynightcycle_slowcyclic'}, ticksperday = 100000},
	{displayname = {'pirates.daynightcycle_cyclic'}, ticksperday = 80000},
	{displayname = {'pirates.daynightcycle_fastcyclic'}, ticksperday = 60000},
	{displayname = {'pirates.daynightcycle_rapidcyclic'}, ticksperday = 40000},
}

Public.ore_types = {
	{name = 'iron-ore', sprite_name = 'entity/iron-ore'},
	{name = 'copper-ore', sprite_name = 'entity/copper-ore'},
	{name = 'coal', sprite_name = 'entity/coal'},
	{name = 'stone', sprite_name = 'entity/stone'},
	{name = 'uranium-ore', sprite_name = 'entity/uranium-ore'},
	{name = 'crude-oil', sprite_name = 'entity/crude-oil'},
}

Public.cost_items = {
	{name = 'electronic-circuit', display_name = 'Electronic circuit', sprite_name = 'item/electronic-circuit', color={r=0,g=255,b=0}},
	{name = 'engine-unit', display_name = 'Engine unit', sprite_name = 'item/engine-unit', color={r=255,g=255,b=0}},
	{name = 'advanced-circuit', display_name = 'Advanced circuit', sprite_name = 'item/advanced-circuit', color={r=0,g=0,b=255}},
	{name = 'uranium-235', display_name = 'Uranium-235', sprite_name = 'item/uranium-235', color={r=0,g=255,b=0}},
	{name = 'flying-robot-frame', display_name = 'Flying robot frame', sprite_name = 'item/flying-robot-frame', color={r=0,g=255,b=255}},
	-- {name = 'rocket-fuel', display_name = 'Rocket Fuel', sprite_name = 'item/rocket-fuel', color={r=255,g=255,b=255}},
	-- {name = 'fluid-wagon', display_name = 'Fluid Wagon', sprite_name = 'item/fluid-wagon', color={r=255,g=255,b=255}},
}

Public.fallthrough_destination = {
	dynamic_data = {},
	static_params = {},
	type = 'Lobby',
	surface_name = Public.lobby_surface_name,
}

-- hacked to make spitters 25% cheaper:
Public.biterPollutionValues = {
    ['behemoth-biter'] = 400,
    ['behemoth-spitter'] = 150,
    ['big-biter'] = 80,
    ['big-spitter'] = 22,
    ['medium-biter'] = 20,
    ['medium-spitter'] = 9,
    ['small-biter'] = 4,
    ['small-spitter'] = 3
}
-- base game:
-- Public.biterPollutionValues = {
--     ['behemoth-biter'] = 400,
--     ['behemoth-spitter'] = 200,
--     ['big-biter'] = 80,
--     ['big-spitter'] = 30,
--     ['medium-biter'] = 20,
--     ['medium-spitter'] = 12,
--     ['small-biter'] = 4,
--     ['small-spitter'] = 4
-- }

--@TODO: Add a function to compare/print two version numbers

Public.max_extra_seconds_at_sea = 8 * 60


Public.loco_bp_1 = [[0eNqV0ttqwzAMBuB30bVTVufsVxljpKloBYkcbLdrCH73Oi6UMrxDLm3zf7KEFjgMF5wMsQO1APWaLaj3BSyduBvWOzdPCArI4QgCuBvX06B7PWpHVwQvgPiIN1B7L/4Mmo6Gl4j0HwKQHTnCR+F4mD/5Mh7QBDNVUsCkbYhoXusEJmsFzKCqAGtDgegej2/rj76J8il+aX1EzvozWpcwm10ZVbkrfcLJ/+u0vzvF07EuTOd0dlkc0k9NJpFyI1KnkGrrZJp0R/XWyUQnLEJcFfWykgKuaGxMyGZf1K2sC5nnTVl5fwdTR+VL]]

function Public.Dock_iconized_map()
	local tiles = {}

	for x = -15.5, 3.5 do
		for y = 19.5, 0.5, -1 do
			if (y <7 and y>2 and x == -2.5)
			or (y == 6.5 and x<2 and x>-6)
			then
				tiles[#tiles + 1] = {name = Public.walkway_tile, position = {x = x, y = y}}
			elseif y < 3 - Math.abs(x+5)^2/20 then --'island'
				if y < 0.5 and x<-3 and x>-7 then
					tiles[#tiles + 1] = {name = 'grass-1', position = {x = x, y = y}}
				elseif y < 3 + Math.abs(x+5)^2/10 then
					tiles[#tiles + 1] = {name = 'dirt-3', position = {x = x, y = y}}
				else
					tiles[#tiles + 1] = {name = 'dry-dirt', position = {x = x, y = y}}
				end
			elseif y<7 then
				tiles[#tiles + 1] = {name = 'water', position = {x = x, y = y}}
			end
		end
	end
	return {
		tiles = tiles,
		entities = {},
	}
end
-- function Public.Dock_iconized_map()
-- 	local tiles = {}

-- 	for x = -15.5, 3.5 do
-- 		for y = -19.5, -0.5 do
-- 			if (y >-7 and y<-2 and x == -2.5)
-- 			or (y == -6.5 and x<2 and x>-6)
-- 			then
-- 				tiles[#tiles + 1] = {name = Public.walkway_tile, position = {x = x, y = y}}
-- 			elseif y > -3 + Math.abs(x+5)^2/20 then --'island'
-- 				if y > -0.5 and x<-3 and x>-7 then
-- 					tiles[#tiles + 1] = {name = 'grass-1', position = {x = x, y = y}}
-- 				elseif y > -3 + Math.abs(x+5)^2/10 then
-- 					tiles[#tiles + 1] = {name = 'dirt-3', position = {x = x, y = y}}
-- 				else
-- 					tiles[#tiles + 1] = {name = 'dry-dirt', position = {x = x, y = y}}
-- 				end
-- 			elseif y>-7 then
-- 				tiles[#tiles + 1] = {name = 'water', position = {x = x, y = y}}
-- 			end
-- 		end
-- 	end
-- 	return {
-- 		tiles = tiles,
-- 		entities = {},
-- 	}
-- end



function Public.Lobby_iconized_map()

	local tiles = {}
	local width = 4
	-- local height = 20

	for x = -100, width do
		for y = -35.5, 35.5 do
			local negx = width - x
			local negxnoisy = negx + Math.random(3)-2
			if negxnoisy >= 50 then
				tiles[#tiles + 1] = {name = 'grass-3', position = {x = x, y = y}}
			elseif negxnoisy >= 30 and (negxnoisy-30) >= Math.abs(y)^2/200 then
				tiles[#tiles + 1] = {name = 'dirt-4', position = {x = x, y = y}}
			elseif negxnoisy >= 15 and (negxnoisy-15) >= Math.abs(y)^2/150 then
				tiles[#tiles + 1] = {name = 'dirt-2', position = {x = x, y = y}}
			else
				if negx >= 5 and (negx-5) >= Math.abs(y)^2/100 then
					tiles[#tiles + 1] = {name = 'sand-2', position = {x = x, y = y}}
				elseif (negx <= 8 and Math.abs(y)<1) or (negx < 1 and Math.abs(y)<3) then
					tiles[#tiles + 1] = {name = Public.walkway_tile, position = {x = x, y = y}}
				else
					tiles[#tiles + 1] = {name = 'water', position = {x = x, y = y}}
				end
			end
		end
	end
	return {
		tiles = tiles,
		entities = {},
	}
end


return Public