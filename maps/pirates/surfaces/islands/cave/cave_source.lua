-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local GetNoise = require 'utils.get_noise'
local BoatData = require 'maps.pirates.structures.boats.sloop.data'
local Balance = require 'maps.pirates.balance'
local ShopCovered = require 'maps.pirates.shop.covered'
local Classes = require 'maps.pirates.roles.classes'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.cave.data'

local math_random = Math.random

-- Code imported from cave_miner_v2 scenario for cave generation

local function spawn_market(args, is_main)
    is_main = is_main or false
    local destination_data = Common.current_destination()
    --if not (destination_data and destination_data.dynamic_data and destination_data.dynamic_data.cave_miner) then return end
    if not (destination_data and destination_data.dynamic_data) then return end

    local offers
    if is_main then
        offers = ShopCovered.market_generate_coin_offers(6)
        if destination_data.static_params.class_for_sale then
            offers[#offers+1] = {price={{'coin', Balance.class_cost(true)}}, offer={type="nothing", effect_description = {'pirates.market_description_purchase_class', Classes.display_form(destination_data.static_params.class_for_sale)}}}
        end
        offers[#offers+1] = {price = {{'coin', 200}}, offer = {type = 'give-item', item = 'small-lamp', count = 100}}
    else
        -- This doesn't really prevent markets spawning near each other, since markets aren't spawned immediately for a given chunk, but it helps a bit
        local cave_miner = destination_data.dynamic_data.cave_miner
        if not cave_miner then
            -- this can be nil if cave island is first and run is launched using proposal
            -- should probably investigate this some time
            local message = 'ERROR: cave_miner is nil'
            if _DEBUG then
                game.print(message)
            else
                log(message)
            end

            return
        end
        local surface = cave_miner.cave_surface
        if not surface then return end

        local r = 64
        if surface.count_entities_filtered({name = 'market', area = {{args.p.x - r, args.p.y - r}, {args.p.x + r, args.p.y + r}}}) > 0 then
            return
        end

        offers = ShopCovered.market_generate_coin_offers(4)
    end

    args.specials[#args.specials + 1] = {name = 'market', position = args.p, offers = offers}
end

local function place_rock(args)
    local a = math_random(-49, 49) * 0.01
    local b = math_random(-49, 49) * 0.01

    args.entities[#args.entities + 1] = IslandsCommon.random_rock_1({x = args.p.x + a, y = args.p.y + b})
end

local function place_spawner(args)
    local memory = Memory.get_crew_memory()

    local name
    if math_random(1, 2) == 1 then
        name = 'biter-spawner'
    else
        name = 'spitter-spawner'
    end
    args.entities[#args.entities + 1] = {name = name, position = args.p, force = memory.enemy_force_name}
end

local function place_worm(args)
    local memory = Memory.get_crew_memory()
    local name = Common.get_random_worm_type(memory.evolution_factor)
    local force = memory.enemy_force_name
    args.entities[#args.entities + 1] = {name = name, position = args.p, force = force}
end

local biomes = {}

function biomes.oasis(args, noise)
	local seed = args.seed
	local position = args.p
    if noise > 0.83 then
		args.tiles[#args.tiles + 1] = {name = 'deepwater', position = args.p}
        Public.Data.spawn_fish(args);
        return
    end

    local noise_decoratives = GetNoise('decoratives', position, seed + 50000)
	args.tiles[#args.tiles + 1] = {name = 'grass-1', position = args.p}
    if math_random(1, 16) == 1 and Math.abs(noise_decoratives) > 0.17 then
		args.entities[#args.entities + 1] = {name = 'tree-04', position = args.p}
    end

    if math_random(1, 64) == 1 then
        args.entities[#args.entities + 1] = {name = 'crude-oil', position = args.p, amount = Balance.pick_default_oil_amount() * 2}
    end

    if noise < 0.73 then
        place_rock(args)
    end
end

function biomes.void(args)
	args.tiles[#args.tiles + 1] = {name = 'out-of-map', position = args.p}
end

function biomes.pond_cave(args, noise)
	local seed = args.seed
	local position = args.p
    local noise_2 = GetNoise('cm_ponds', position, seed)

    if Math.abs(noise_2) > 0.60 then
		args.tiles[#args.tiles + 1] = {name = 'water', position = args.p}
        Public.Data.spawn_fish(args);
        return
    end

    args.tiles[#args.tiles + 1] = {name = 'dirt-7', position = args.p}

    if math_random(1, 512) == 1 then
        args.specials[#args.specials + 1] = {name = 'chest', position = args.p}
        return
    end

    if Math.abs(noise_2) > 0.25 then
        if math_random(1, 64) == 1 then
            place_spawner(args)
        else
            place_rock(args)
        end

        return
    end

    if math_random(1, 32) == 1 then
        place_spawner(args)
        return
    end

    if noise > -0.53 then
        place_rock(args)
        return
    else
        if math_random(1, 1024) == 1 then
            spawn_market(args)
            return
        end
    end
end

-- Spawn refers to the "middle of the map" where the market is located
function biomes.spawn(args, square_distance)
	local seed = args.seed
	local position = args.p

    -- If coordinate iteration ever changes to xn instead of 0.5 + xn this will need to change
    if Math.abs(position.x - 0.5) < 0.1 and Math.abs(position.y - 0.5) < 0.1 then
        args.tiles[#args.tiles + 1] = {name = 'dirt-7', position = args.p}
        spawn_market(args, true)
        return
    end

    local noise = GetNoise('decoratives', position, seed)
    if Math.abs(noise) > 0.60 and square_distance < 900 and square_distance > 10 then
		args.tiles[#args.tiles + 1] = {name = 'water', position = args.p}
        Public.Data.spawn_fish(args);
        return
    end

    args.tiles[#args.tiles + 1] = {name = 'dirt-7', position = args.p}

    if square_distance > 100 then
        place_rock(args)
    end
end

function biomes.ocean(args, noise)
    if noise > 0.66 then
		args.tiles[#args.tiles + 1] = {name = 'deepwater', position = args.p}
        Public.Data.spawn_fish(args);
        return
    end
    if noise > 0.63 then
		args.tiles[#args.tiles + 1] = {name = 'water', position = args.p}
        Public.Data.spawn_fish(args);
        return
    end

    args.tiles[#args.tiles + 1] = {name = 'dirt-7', position = args.p}

    place_rock(args)
end

function biomes.worm_desert(args, noise)
	local seed = args.seed
	local position = args.p

    local i = Math.floor((GetNoise('decoratives', position, seed) * 8) % 3) + 1
    args.tiles[#args.tiles + 1] = {name = 'sand-' .. i, position = args.p}

    if noise > -0.65 then
        place_rock(args)
        return
    end

    if math_random(1, 64) == 1 then
        place_worm(args)
        return
    end

    if math_random(1, 32) == 1 then
        local n = GetNoise('decoratives', position, seed + 10000)
        if n > 0.2 then
            local trees = {'dead-grey-trunk', 'dead-grey-trunk', 'dry-tree'}
			args.entities[#args.entities + 1] = {name = trees[math_random(1, 3)], position = args.p}
            return
        end
    end

    if math_random(1, 512) == 1 then
        args.specials[#args.specials + 1] = {name = 'chest', position = args.p}
    end
end

function biomes.cave(args, square_distance)
	local seed = args.seed
	local position = args.p

    local noise_cave_rivers1 = GetNoise('cave_rivers_2', position, seed + 100000)
    if Math.abs(noise_cave_rivers1) < 0.025 then
        local noise_cave_rivers2 = GetNoise('cave_rivers_3', position, seed + 200000)
        if noise_cave_rivers2 > 0 then
			args.tiles[#args.tiles + 1] = {name = 'water-shallow', position = args.p}
            Public.Data.spawn_fish(args);
            return
        end
    end

    local no_rocks_2 = GetNoise('no_rocks_2', position, seed)
    if no_rocks_2 > 0.7 then
        if no_rocks_2 > 0.73 then
            if math_random(1, 256) == 1 then
                spawn_market(args)
            end
        end
		args.tiles[#args.tiles + 1] = {name = 'dirt-' .. Math.floor(no_rocks_2 * 16) % 4 + 3, position = args.p}
        return
    end

    args.tiles[#args.tiles + 1] = {name = 'dirt-7', position = args.p}

    if Math.abs(no_rocks_2) < 0.05 then
        return
    end

    local noise_rock = GetNoise('small_caves', position, seed)

    if noise_rock < 0.6 then
        local ring1_range = 10
        local ring2_range = 20
        local ring1_radius = 150
        local ring2_radius = 300

        local ring1_start = (ring1_radius - ring1_range) * (ring1_radius - ring1_range)
        local ring1_end = (ring1_radius + ring1_range) * (ring1_radius + ring1_range)
        local ring2_start = (ring2_radius - ring2_range) * (ring2_radius - ring2_range)
        local ring2_end = (ring2_radius + ring2_range) * (ring2_radius + ring2_range)

        -- add nest obstacles in these rings on "main" wide cave roads
        if (square_distance > ring1_start and square_distance < ring1_end) or
            (square_distance > ring2_start and square_distance < ring2_end) then
            if math_random(1, 32) == 1 then
                if math_random(1, 3) == 1 then
                    place_worm(args)
                else
                    place_spawner(args)
                end
                return
            end

            if math_random(1, 512) == 1 then
                args.specials[#args.specials + 1] = {name = 'chest', position = args.p}
                return
            end

            if math_random(1, 16) == 1 then
                place_rock(args)
                return
            end
        end

        if math_random(1, 1024) == 1 then
            args.specials[#args.specials + 1] = {name = 'chest', position = args.p}
            return
        end

        place_rock(args)
        return
    end

    if square_distance < 4096 then
        return
    end

    if math_random(1, 8192) == 1 then
        spawn_market(args)
        return
    end

    if math_random(1, 16) == 1 then
        if math_random(1, 3) == 1 then
            place_worm(args)
            return
        else
            place_spawner(args)
            return
        end
    end
end

local function pick_biome(args)
	local position = args.p
    local d = position.x ^ 2 + position.y ^ 2


    local boat_height = Math.max(BoatData.height, 15) -- even if boat height is smaller, we need to be at least 10+ just so formulas below play out nicely
    local spawn_radius = boat_height + 15
    local entrance_radius = boat_height + 45
    local river_width = boat_height + 40

	-- Spawn location for market
    if d < spawn_radius ^ 2 then
        biomes.spawn(args, d)
        return
    end

	-- River upon which ship arrives + ship entrance
	if position.x < 0 and 2 * Math.abs(position.y) < river_width then
        biomes.void(args)
        return
	end

	-- Prevent cave expansion in west direction
    -- NOTE: although "river_width ^ 2 - entrance_radius ^ 2" should never be "< 0", it's a small safe check
    -- NOTE: the complex calculation here calculates wanted intersection of river and spawn area (or in other words line and circle intersection)
	if position.x < 0 and -position.x + (river_width - Math.sqrt(Math.max(0, river_width ^ 2 - entrance_radius ^ 2))) > Math.abs(2 * position.y) then
        biomes.void(args)
        return
	end

	-- Actual cave generation below
    local cm_ocean = GetNoise('cm_ocean', position, args.seed + 100000)
    if cm_ocean > 0.6 then
        biomes.ocean(args, cm_ocean)
        return
    end

    local noise = GetNoise('cave_miner_01', position, args.seed)
    local abs_noise = Math.abs(noise)
    if abs_noise < 0.075 then
        biomes.cave(args, d)
        return
    end

    if abs_noise > 0.25 then
        noise = GetNoise('cave_rivers', position, args.seed)
        if noise > 0.72 then
            biomes.oasis(args, noise)
            return
        end
        if cm_ocean < -0.6 then
            biomes.worm_desert(args, cm_ocean)
            return
        end
        if noise < -0.5 then
            biomes.pond_cave(args, noise)
            return
        end
    end

    -- make 4 times as much narrow caves
    local position2 = {x = position.x*2, y = position.y*2}
    noise = GetNoise('cave_miner_02', position2, args.seed)
    if Math.abs(noise) < 0.1 then
        biomes.cave(args, d)
        return
    end

    biomes.void(args)
end

function Public.terrain(args)
    local tiles_placed = #args.tiles
    pick_biome(args)

    -- fallback case that should never happen
    if #args.tiles == tiles_placed then
        -- game.print('no tile was placed!')
        args.tiles[#args.tiles + 1] = {name = 'dirt-7', position = args.p}
        return
    end
end


-- Finding a spot for structures is very hard (it might cause structures to spawn in weird locations, like ship)
-- function Public.chunk_structures(args)

-- end

-- Launching rocket in caves sounds silly (as well as hard to pick position for rocket)
-- function Public.generate_silo_setup_position(points_to_avoid)

-- end


return Public