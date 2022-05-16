--local table_insert = table.insert

local Public = {}

--local Server = require 'utils.server'

--local function clear_all_entities(surface, area)
--	local entities = surface.find_entities(area)
--	for _, entity in pairs(entities) do
--		if entity.can_be_destroyed() then
--			entity.destroy()
--		end
--	end
--end
--
--local function clear_all_tiles(surface, area)
--	local tiles = surface.find_tiles_filtered({area = area})
--	local replacements = {}
--	for _, tile in pairs(tiles) do
--		table_insert(replacements, {name = "out-of-map", position = tile.position})
--	end
--	surface.set_tiles(replacements, true, true, true, false)
--end

local function invalidate_chunks(surface)
	surface.clear(true)
end

local function load_spawn_chunks(surface)
	surface.request_to_generate_chunks({0,0}, 7)
	surface.force_generate_chunk_requests()
end

local function initialize_nauvis()
	local surface = game.surfaces['nauvis']
	-- this overrides what is in the map_gen_settings.json file
	local mgs = surface.map_gen_settings

	mgs.terrain_segmentation = 1
	-- water = 0 means no water allowed
	-- water = 1 means elevation is not reduced when calculating water tiles (elevation < 0)
	-- water = 2 means elevation is reduced by 10 when calculating water tiles (elevation < 0)
	--			or rather, the water table is 10 above the normal elevation
	mgs.water = 1.33
	-- frequency: very-high = 2, high = sqrt(2), normal = 1, low = 1/sqrt(2), very-low = 0.5, none = 0
	mgs.autoplace_controls = {
		coal = {frequency = 'very-high', size = 1, richness = 'normal'},
		stone = {frequency = 'very-high', size = 1, richness = 'normal'},
		['copper-ore'] = {frequency = 'very-high', size = 1, richness = 'normal'},
		['iron-ore'] = {frequency = 'very-high', size = 1, richness = 'normal'},
		['uranium-ore'] = {frequency = 'normal', size = 1, richness = 'normal'},
		['rare-metals'] = {frequency = 'normal', size = 1, richness = 'normal'},
		['imersite'] = {frequency = 'very-high', size = 1, richness = 'normal'},
		['mineral-water'] = {frequency = 'very-high', size = 1, richness = 'normal'},
		['crude-oil'] = {frequency = 'very-high', size = 'very-small', richness = 'normal'},
		trees = {frequency = "very-high", size = 'normal', richness = 'normal'},
		['enemy-base'] = {frequency = 12, size = 'normal', richness = 'normal'}
	}
	mgs.default_enable_all_autoplace_controls = true -- don't mess with this!
	mgs.autoplace_settings = {
	--	entity = {
	--		settings = {
	--			['rock-huge'] = {frequency = 'normal', size = 12, richness = 'very-high'},
	--			['rock-big'] = {frequency = 'normal', size = 12, richness = 'very-high'},
	--			['sand-rock-big'] = {frequency = 'normal', size = 12, richness = 1, 'very-high'}
	--		}
	--	},
	--	decorative = {
	--		settings = {
	--			['rock-tiny'] = {frequency = 'normal', size = 'normal', richness = 'normal'},
	--			['rock-small'] = {frequency = 'normal', size = 'normal', richness = 'normal'},
	--			['rock-medium'] = {frequency = 'normal', size = 'normal', richness = 'normal'},
	--			['sand-rock-small'] = {frequency = 'normal', size = 'normal', richness = 'normal'},
	--			['sand-rock-medium'] = {frequency = 'normal', size = 'normal', richness = 'normal'}
	--		}
	--	}
	}
	mgs.cliff_settings = {
		name = 'cliff',
		cliff_elevation_0 = 10,
		cliff_elevation_interval = 40,
		richness = 1
	}
	if _SEED then
		mgs.seed = _SEED
	else
		mgs.seed = game.surfaces[1].map_gen_settings.seed
	end
	-- terrain size is 64 x 64 chunks, water size is 80 x 80
	mgs.width = 2000000
	mgs.height = 2000000
	mgs.starting_area = 'normal'
	mgs.starting_points = {
		{x = 0, y = 0}
	}
	mgs.peaceful_mode = false
	-- here we put the named noise expressions for the specific noise-layer if we want to override them
	mgs.property_expression_names = {
		-- here we are overriding the moisture noise-layer with a fixed value of 0 to keep moisture consistently dry across the map
		-- it allows to free up the moisture noise expression
		-- low moisture
		--moisture = 0,

		-- here we are overriding the aux noise-layer with a fixed value to keep aux consistent across the map
		-- it allows to free up the aux noise expression
		-- aux should be not sand, nor red sand
		--aux = 0.5,

		-- here we are overriding the temperature noise-layer with a fixed value to keep temperature consistent across the map
		-- it allows to free up the temperature noise expression
		-- temperature should be 20C or 68F
		--temperature = 20,

		-- here we are overriding the cliffiness noise-layer with a fixed value of 0 to disable cliffs
		-- it allows to free up the cliffiness noise expression (which may or may not be useful)
		-- disable cliffs
		--cliffiness = 0,

		-- we can disable starting lakes two ways, one by setting starting-lake-noise-amplitude = 0
		-- or by making the elevation a very large number
		-- make sure starting lake amplitude is 0 to disable starting lakes
		['starting-lake-noise-amplitude'] = 0,
		-- allow enemies to get up close on spawn
		['starting-area'] = 1,
		-- this accepts a string representing a named noise expression
		-- or number to determine the elevation based on x, y and distance from starting points
		-- we can not add a named noise expression at this point, we can only reference existing ones
		-- which can also be defined in mods
		-- if we have any custom noise expressions defined from a mod, we will be able to use them here
		-- setting it to a fixed number would mean a flat map
		-- elevation < 0 means there is water unless the water table has been changed
		--elevation = -1,
		--elevation = 0,
		--elevation-persistence = 0,
		elevation = "kap-islands-world2",

		-- testing
		["control-setting:moisture:bias"] = "0.350000",
		--["control-setting:moisture:frequency:multiplier"] = 1,
		--["control-setting:aux:bias"] = 0.5,
		--["control-setting:aux:frequency:multiplier"] = 100,
		--["control-setting:temperature:bias"] = 0.01,
		--["control-setting:temperature:frequency:multiplier"] = 100,

		--["tile:water:probability"] = -1000,
		--["tile:deep-water:probability"] = -1000,

		-- a constant intensity means base distribution will be consistent with regard to distance
		--['enemy-base-intensity'] = 1,
		-- adjust this value to set how many nests spawn per tile
		--['enemy-base-frequency'] = 0.4,
		-- this will make and average base radius around 12 tiles
		--['enemy-base-radius'] = 12
	}

	surface.map_gen_settings = mgs
	surface.peaceful_mode = false
	surface.always_day = false
	surface.freeze_daytime = false
	invalidate_chunks(surface)
	load_spawn_chunks(surface)
end

local function create_limbo()
	game.create_surface('limbo')
end

local function initialize_limbo()
	local surface = game.surfaces['limbo']
	surface.generate_with_lab_tiles = true
	surface.peaceful_mode = true
	surface.always_day = true
	surface.freeze_daytime = true
	surface.clear(true)
end

function Public.initialize()
	create_limbo()
	initialize_limbo()
	initialize_nauvis()
end

return Public