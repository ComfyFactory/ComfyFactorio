-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local _inspect = require 'utils.inspect'.inspect

local Public = {}

-- two things to 'hunt':
-- treasure map for X
-- quest treasure


-- Something to be careful of whilst writing functions for this file:
-- Try to ensure that they only return integer co-ordinates, not half-integer. This will make structures easier to place.





function Public.silo_setup_position(points_to_avoid, x_fractional_offset, x_absolute_offset)
	x_absolute_offset = x_absolute_offset or 0
	x_fractional_offset = x_fractional_offset or 0
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]
	local boatposition = memory.boat.position
	local island_center = Math.snap_to_grid(destination.static_params.islandcenter_position)
	local difficulty_offset = (1 - Common.difficulty_scale()) * 20 or 0

	local silo_count = Balance.silo_count()

	local p = {
		x = Math.min(
			Math.floor(boatposition.x + difficulty_offset + (island_center.x - boatposition.x) * 3/5) - 0.5,
			Math.floor(boatposition.x + 175) - 0.5
		) + (island_center.x - boatposition.x) * x_fractional_offset + x_absolute_offset,
		y = Math.floor(boatposition.y + (island_center.y - boatposition.y) * 3/5) - 0.5
	}

	local tries = 0
	local p_ret = nil
	local p2
	while p_ret == nil and tries < 200 do
		p2 = {x = p.x + Math.random(-30, 0), y = p.y + Math.random(-70, 70)}
		if p2.x >= boatposition.x+5 and Common.can_place_silo_setup(surface, p2, points_to_avoid, silo_count) then p_ret = p2 end
		tries = tries + 1
	end
	while p_ret == nil and tries < 400 do
		p2 = {x = p.x + Math.random(-60, 10), y = p.y + Math.random(-90, 90)}
		if p2.x >= boatposition.x+5 and Common.can_place_silo_setup(surface, p2, points_to_avoid, silo_count, true) then p_ret = p2 end
		tries = tries + 1
	end
	while p_ret == nil and tries < 1200 do
		p2 = {x = p.x + Math.random(-90, 20), y = p.y + Math.random(-130, 130)}
		if p2.x >= boatposition.x+5 and Common.can_place_silo_setup(surface, p2, points_to_avoid, silo_count, true) then p_ret = p2 end
		tries = tries + 1
	end
	-- if _DEBUG then
		if p_ret == nil then
			log("No good position found after 1200 tries")
			p_ret = p
		else
			log(string.format("Silo position generated after %f tries: %f, %f", tries, p_ret.x, p_ret.y))
		end
	-- end

	Common.ensure_chunks_at(surface, p_ret, 1)
	return p_ret
end






function Public.mid_farness_position_1(args, points_to_avoid)
	points_to_avoid = points_to_avoid or {}

	-- local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local island_center = Math.snap_to_grid(destination.static_params.islandcenter_position)
    local width = destination.static_params.width
    local height = destination.static_params.height

	local tries = 0
	local p_ret = nil

    local p2
	while p_ret == nil and tries < 400 do
		p2 = {x = island_center.x + Math.random(Math.ceil(-width/2), Math.ceil(width/2)), y = island_center.y + Math.random(Math.ceil(-height/2), Math.ceil(height/2))}

        Common.ensure_chunks_at(surface, p2, 0.01)

		local tile = surface.get_tile(p2)
        if tile and tile.valid and tile.name then
            if (not Utils.contains(CoreData.tiles_that_conflict_with_resource_layer, tile.name)) and (not Utils.contains(CoreData.edgemost_tile_names, tile.name)) then
                local p3 = {x = p2.x + args.static_params.terraingen_coordinates_offset.x, y = p2.y + args.static_params.terraingen_coordinates_offset.y}

				if IslandsCommon.island_farness_1(args)(p3) > 0.1 and IslandsCommon.island_farness_1(args)(p3) < 0.8 then
					local allowed = true
					for _, pa in pairs(points_to_avoid) do
						if Math.distance({x = pa.x, y = pa.y}, p2) < pa.r then
							allowed = false
							break
						end
					end
					if allowed then
						p_ret = p2
					end
				end
            end
        end

		tries = tries + 1
	end

	if _DEBUG then
		if p_ret == nil then
			log("No good mid_farness_position_1 position found after 500 tries")
			-- p_ret = {x = 0, y = 0}
		else
			log(string.format("mid_farness_position_1 Position found after %f tries: %f, %f", tries, p_ret.x, p_ret.y))
		end
	end

    return p_ret
end







function Public.close_position_try_avoiding_entities(args, points_to_avoid, farness_boost_low, farness_boost_high)
	farness_boost_low = farness_boost_low or 0
	farness_boost_high = farness_boost_high or 0
	points_to_avoid = points_to_avoid or {}

	-- local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local island_center = Math.snap_to_grid(destination.static_params.islandcenter_position)
    local width = destination.static_params.width
    local height = destination.static_params.height

	local tries = 0
	local p_ret = nil

    local p2
	while p_ret == nil and tries < 700 do
		p2 = {x = island_center.x + Math.random(Math.ceil(-width/2), 0), y = island_center.y + Math.random(Math.ceil(-height/3), Math.ceil(height/3))}

        Common.ensure_chunks_at(surface, p2, 0.01)

		local tile = surface.get_tile(p2)
        if tile and tile.valid and tile.name then
            if (not Utils.contains(CoreData.tiles_that_conflict_with_resource_layer, tile.name)) and (not Utils.contains(CoreData.edgemost_tile_names, tile.name)) then
                local p3 = {x = p2.x + args.static_params.terraingen_coordinates_offset.x, y = p2.y + args.static_params.terraingen_coordinates_offset.y}

				if IslandsCommon.island_farness_1(args)(p3) > 0.06 + farness_boost_low and IslandsCommon.island_farness_1(args)(p3) < 0.19 + farness_boost_high then
					local allowed = true
					if tries < 40 and #surface.find_entities({{p2.x - 8, p2.y - 8}, {p2.x + 8, p2.y + 8}}) > 0 then
						allowed = false
					end
					if tries >= 40 and tries < 100 and #surface.find_entities({{p2.x - 6, p2.y - 6}, {p2.x + 6, p2.y + 6}}) > 0 then
						allowed = false
					end
					if tries >= 100 and tries < 200 and #surface.find_entities({{p2.x - 3, p2.y - 3}, {p2.x + 3, p2.y + 3}}) > 0 then
						allowed = false
					end
					for _, pa in pairs(points_to_avoid) do
						if allowed and Math.distance({x = pa.x, y = pa.y}, p2) < pa.r then
							allowed = false
						end
					end
					if allowed then
						p_ret = p2
					end
				end
            end
        end

		tries = tries + 1
	end

	if _DEBUG then
		if p_ret == nil then
			log("No good close_position_try_avoiding_entities found after 500 tries")
			-- p_ret = {x = 0, y = 0}
		else
			log(string.format("close_position_try_avoiding_entities found after %f tries: %f, %f", tries, p_ret.x, p_ret.y))
		end
	end

    return p_ret
end









function Public.position_away_from_players_1(_, radius)
    radius = radius or 60

	-- local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local island_center = Math.snap_to_grid(destination.static_params.islandcenter_position)
    local width = destination.static_params.width
    local height = destination.static_params.height

	local tries = 0
	local p_ret = nil

    local p2
	while p_ret == nil and tries < 500 do
		p2 = {x = island_center.x + Math.random(Math.ceil(-width/2), Math.ceil(width/2)), y = island_center.y + Math.random(Math.ceil(-height/2), Math.ceil(height/2))}

        Common.ensure_chunks_at(surface, p2, 0.01)

        -- local p3 = {x = p2.x + args.static_params.terraingen_coordinates_offset.x, y = p2.y + args.static_params.terraingen_coordinates_offset.y}
        local tile = surface.get_tile(p2)

        if tile and tile.valid and tile.name then
            if not Utils.contains(CoreData.tiles_that_conflict_with_resource_layer_extended, tile.name) then
                local nearby_characters = surface.find_entities_filtered{position = p2, radius = radius, name = 'character'}
                if (not nearby_characters) or (#nearby_characters == 0) then
                    p_ret = p2
                end
            end
        end


		tries = tries + 1
	end

	if _DEBUG then
		if p_ret == nil then
			log("No good position found after 500 tries")
			-- p_ret = {x = 0, y = 0}
		else
			log(string.format("Position found after %f tries: %f, %f", tries, p_ret.x, p_ret.y))
		end
	end

    return p_ret
end










function Public.merchant_ship_position()

	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local island_center = Math.snap_to_grid(destination.static_params.islandcenter_position)
    local width = destination.static_params.width
    local height = destination.static_params.height

	local right_boundary = island_center.x + width/2

	local to_try = {}
	for i = -height/2, height/2, 10 do
		to_try[#to_try + 1] = i
	end
	Math.shuffle(to_try)

	local last_reasonable_position
	local p_ret
	for _, h in ipairs(to_try) do
		local right_boundary_p = {x = right_boundary, y = h}

        Common.ensure_chunks_at(surface, right_boundary_p, 10)

		local i = 0
		while i < 300 and (not p_ret) do
			i = i + 1

			local p2 = {x = right_boundary - i, y = h}

			local tile = surface.get_tile(p2)
			if i < 32 then
				if not Utils.contains(CoreData.tiles_that_conflict_with_resource_layer, tile.name) then
					break
				end
			else
				if not Utils.contains(CoreData.tiles_that_conflict_with_resource_layer, tile.name) then
					local area = {{p2.x - 40, p2.y - 11},{p2.x + 4, p2.y + 11}}

					local spawners = surface.find_entities_filtered({type = 'unit-spawner', force = memory.enemy_force_name, area = area})
					local worms = surface.find_entities_filtered({type = 'turret', force = memory.enemy_force_name, area = area})
					if #spawners == 0 and #worms == 0 then
						p_ret = p2
					else
						last_reasonable_position = p2
					end
					break
				end
			end
		end
	end

	if _DEBUG then
		if p_ret == nil then
			log("No good position found for merchant ship")
			-- p_ret = {x = 0, y = 0}
		else
			log(string.format("Merchant ship position found: %f, %f", p_ret.x, p_ret.y))
		end
	end

    return p_ret or last_reasonable_position
end






return Public