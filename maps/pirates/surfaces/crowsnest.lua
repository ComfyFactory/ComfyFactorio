
local Memory = require 'maps.pirates.memory'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'

local inspect = require 'utils.inspect'.inspect
local Token = require 'utils.token'
local Task = require 'utils.task'

local SurfacesCommon = require 'maps.pirates.surfaces.common'

-- This file is logically a bit of a mess, because we changed from islands moving to the crowsnest platform moving.

local Public = {}
local enum = {
	DEFAULT = 'Default',
}
Public.enum = enum

Public.Data = {}
Public.Data.chartingdistance = 130
Public.Data.visibilitywidth = 400
Public.Data.width = 10000 --minimap won't chart beyond this point
Public.Data.height = 72
Public.platformwidth = 7
Public.platformheight = 7
Public.platformrightmostedge = 4

Public.Data.chestspos = {
	{x = -2.5, y = -3.5},
	{x = -1.5, y = -3.5},
	{x = -0.5, y = -3.5},
	{x = 1.5, y = -3.5},
	{x = 2.5, y = -3.5},
	{x = 3.5, y = -3.5},
	{x = -2.5, y = 3.5},
	{x = -1.5, y = 3.5},
	{x = -0.5, y = 3.5},
	{x = 1.5, y = 3.5},
	{x = 2.5, y = 3.5},
	{x = 3.5, y = 3.5},
	{x = -2.5, y = -2.5},
	{x = -2.5, y = -1.5},
	{x = -2.5, y = 1.5},
	{x = -2.5, y = 2.5},
	{x = 3.5, y = -2.5},
	{x = 3.5, y = -1.5},
	{x = 3.5, y = 1.5},
	{x = 3.5, y = 2.5},
}

Public.Data.surfacename_rendering_pos = {x = 0.5, y = -6.1}

function Public.crowsnest_surface_name()
	local memory = Memory.get_crew_memory()

	return SurfacesCommon.encode_surface_name(memory.id, 0, SurfacesCommon.enum.CROWSNEST, nil)
end

function Public.get_crowsnest_surface()
	local memory = Memory.get_crew_memory()

	return game.surfaces[Public.crowsnest_surface_name()]
end


function Public.move_crowsnest(vectorx, vectory)
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[Public.crowsnest_surface_name()]

	local old_area = {{memory.overworldx - 2.5, memory.overworldy - 3.5},{memory.overworldx + 3.5, memory.overworldy + 3.5}}
		
	memory.overworldx = memory.overworldx + vectorx
	memory.overworldy = memory.overworldy + vectory

	local new_area = {{memory.overworldx - 2.5, memory.overworldy - 3.5},{memory.overworldx + 3.5, memory.overworldy + 3.5}}

	local new_floor_positions = {}
	local tiles1 = {}
	for y = new_area[1][2], new_area[2][2], 1 do
		for x = new_area[1][1], new_area[2][1], 1 do
			if not new_floor_positions[x] then new_floor_positions[x] = {} end
			new_floor_positions[x][y] = true
			tiles1[#tiles1 + 1] = {name = CoreData.static_boat_floor, position = {x = x, y = y}}
		end
	end

	surface.set_tiles(tiles1, true, true, true)

	local entities_to_teleport = surface.find_entities_filtered{area = old_area}
	for _, e in pairs(entities_to_teleport) do
		e.teleport(vectorx, vectory)
	end

	local tiles2 = {}
	for y = old_area[1][2], old_area[2][2], 1 do
		for x = old_area[1][1], old_area[2][1], 1 do
			if not (new_floor_positions[x] and new_floor_positions[x][y]) then
				tiles2[#tiles2 + 1] = {name = 'deepwater', position = {x = x, y = y}}
			end
		end
	end

	surface.set_tiles(tiles2, true, true, true)

	if memory.crowsnest_surfacename_rendering then
		local p = rendering.get_target(memory.crowsnest_surfacename_rendering).position
		rendering.set_target(memory.crowsnest_surfacename_rendering, {x = p.x + vectorx, y = p.y + vectory})
	end

	if vectorx ~= 0 then
		local crew_force = memory.force
		local area = {{memory.overworldx,-Public.Data.height/2},{memory.overworldx+Public.Data.chartingdistance,Public.Data.height/2}}
		-- crew_force.clear_chart(surface)
		crew_force.chart(surface, area)
	end
end



function Public.update_destination_renderings()
	local memory = Memory.get_crew_memory()
	for _, dest in pairs(memory.destinations) do
		if dest.dynamic_data.crowsnest_renderings then
			if dest.overworld_position.x <= memory.overworldx+Public.Data.chartingdistance and dest.overworld_position.x >= memory.overworldx-Public.Data.chartingdistance then
				for _, r in pairs(dest.dynamic_data.crowsnest_renderings) do
					if type(r) == 'table' then
						if rendering.is_valid(r.text_rendering) then
							rendering.set_visible(r.text_rendering, true)
						end
						if rendering.is_valid(r.sprite_rendering) then
							rendering.set_visible(r.sprite_rendering, true)
						end
					else
						if rendering.is_valid(r) then
							rendering.set_visible(r, true)
						end
					end
				end
			else
				for _, r in pairs(dest.dynamic_data.crowsnest_renderings) do
					if type(r) == 'table' then
						if rendering.is_valid(r.text_rendering) then
							rendering.set_visible(r.text_rendering, false)
						end
						if rendering.is_valid(r.sprite_rendering) then
							rendering.set_visible(r.sprite_rendering, false)
						end
					else
						if rendering.is_valid(r) then
							rendering.set_visible(r, false)
						end
					end
				end
			end
		end
	end
end


function Public.draw_kraken(p)
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[Public.crowsnest_surface_name()]
	
	surface.set_tiles({{name = CoreData.kraken_tile, position = {x = Public.platformrightmostedge + p.x, y = p.y}}}, true, true, true)
end



function Public.draw_destination(destination)
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[Public.crowsnest_surface_name()]

	local tiles = {}
	local entities = {}
	local renderings = {}

	local iconized_map = SurfacesCommon.fetch_iconized_map(destination)

	if not iconized_map then iconized_map = destination.iconized_map end

	local x = Public.platformrightmostedge + destination.overworld_position.x
	local y = destination.overworld_position.y

	for _, t in pairs(iconized_map.tiles) do
		local t2 = Utils.deepcopy(t)
		t2.position = {x = x + t.position.x, y = y + t.position.y}
		tiles[#tiles+1] = t2
	end

	surface.set_tiles(tiles, true, true, true)

	for _, e in pairs(iconized_map.entities) do
		local e2 = Utils.deepcopy(e)
		e2.position = {x = x + e.position.x, y = y + e.position.y}
		if e2.source then e2.source = {x = e2.source.x + x, y = e2.source.y + y} end
		if e2.target then e2.target = {x = e2.target.x + x, y = e2.target.y + y} end
		surface.create_entity(e2)
	end

	-- Now we can destroy the iconized_map... right?
	destination.iconized_map = nil
end

function Public.draw_extra_bits()
	Public.draw_destination{
		type = 'finish line',
		seed = 0,
		overworld_position = {x = CoreData.victory_x, y = 0},
		static_params = {},
		dynamic_data = {},
		iconized_map = {
			tiles = {},
			entities = {
				{name = 'electric-beam', position = {x = 0, y = 0}, source = {x = 0, y = -37}, target = {x = 0, y = 37}},
				{name = 'electric-beam', position = {x = 0, y = 0}, source = {x = 0, y = -37}, target = {x = 0, y = 37}},
			},
		},
		iconized_map_width = 2,
		iconized_map_height = 2,
	}

	Public.draw_destination{
		type = 'Lobby',
		overworld_position = {x = -14, y = 0},
	}
end



function Public.create_crowsnest_surface()
	-- if not game.surfaces[crowsnest_surface_name()] then
		local memory = Memory.get_crew_memory()
		local map_gen_settings = Common.default_map_gen_settings(Public.Data.width, Public.Data.height)

		game.create_surface(Public.crowsnest_surface_name(), map_gen_settings)
		local surface = game.surfaces[Public.crowsnest_surface_name()]
		surface.freeze_daytime = true
		surface.daytime = 0

		Common.ensure_chunks_at(surface, {x = 0, y = 0}, 15)

		Public.paint_crowsnest_background_tiles()
	-- end

		memory.crowsnest_surfacename_rendering = rendering.draw_text{
			text = 'Crow\'s Nest',
			surface = surface,
			target = Public.Data.surfacename_rendering_pos,
			color = CoreData.colors.renderingtext_yellow,
			scale = 2.5,
			font = 'default-game',
			alignment = 'center'
		}
end

function Public.paint_water_between_overworld_positions(overworldx1, overworldx2)
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[Public.crowsnest_surface_name()]

	Common.ensure_chunks_at(surface, {x = overworldx2, y = 0}, 10)

	local tiles = {}
	for y = -(Public.Data.height+32 - 1)/2, (Public.Data.height+32 - 1)/2, 1 do
		for x = Public.platformrightmostedge + overworldx1, Public.platformrightmostedge + overworldx2 do
			if y>= -(Public.Data.height - 1)/2 and y <= (Public.Data.height - 1)/2 then
				tiles[#tiles + 1] = {name = 'deepwater', position = {x = x, y = y}}
			else
				tiles[#tiles + 1] = {name = 'out-of-map', position = {x = x, y = y}}
			end
		end
	end

	surface.set_tiles(tiles)
end

function Public.paint_crowsnest_background_tiles()
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[Public.crowsnest_surface_name()]

	local tiles = {}
	for y = -(Public.Data.height+32 - 1)/2, (Public.Data.height+32 - 1)/2, 1 do
		for x = -(Public.Data.visibilitywidth+32 - 1)/2, (Public.Data.visibilitywidth+32 - 1)/2, 1 do
			if x <= 3.5 and x >= -2.5 and y <= 3.5 and y >= -3.5 then
				tiles[#tiles + 1] = {name = CoreData.static_boat_floor, position = {x = x, y = y}}
			elseif x>= -(Public.Data.visibilitywidth - 1)/2 and x <= (Public.Data.visibilitywidth - 1)/2 and y>= -(Public.Data.height - 1)/2 and y <= (Public.Data.height - 1)/2 then
				tiles[#tiles + 1] = {name = 'deepwater', position = {x = x, y = y}}
			else
				tiles[#tiles + 1] = {name = 'out-of-map', position = {x = x, y = y}}
			end
		end
	end

	surface.set_tiles(tiles)
end


function Public.upgrade_chests(new_chest) --the fast replace doesn't work well on the '/go' tick, but that's okay
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	local surface = Public.get_crowsnest_surface()
	local ps = Public.Data.chestspos

	for _, p in pairs(ps) do
		local p2 = {x = p.x + memory.overworldx, y = p.y + memory.overworldy}
		local es = surface.find_entities_filtered{name = 'wooden-chest', position = p2, radius = 0.05}
		if es and #es == 1 then
			es[1].minable = true
			es[1].destructible = true
			es[1].rotatable = true
			-- es[1].operable = true
			local e2 = surface.create_entity{name = new_chest, position = es[1].position, fast_replace = true, spill = false, force = boat.force_name}
			e2.minable = false
			e2.destructible = false
			e2.rotatable = false
			-- e2.operable = false
		end
	end
end

-- just for debug purposes, might need to fire this again
local crowsnest_delayed = Token.register(
	function(data)
		Memory.set_working_id(data.crew_id)
		Public.crowsnest_surface_delayed_init()
	end
)

function Public.crowsnest_surface_delayed_init()
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[Public.crowsnest_surface_name()]
	local force = memory.force

	if _DEBUG and (not (surface and surface.valid)) then
		game.print('/go issue: crowsnest_surface_delayed_init called when crowsnest surface wasn\'t valid. This happens due to a difficult-to-handle race condition in concurrent delayed events in the /go shortcut. Firing event again...')
		Task.set_timeout_in_ticks(5, crowsnest_delayed, {crew_id = memory.id})
		return
	end
	
	surface.destroy_decoratives{area = {{-3, -4},{4, 4}}}

	local chestspos = Public.Data.chestspos
	local steerchestspos = {
		{x = 0.5, y = -3.5},
		{x = 0.5, y = 3.5},
	}
	local carspos = {
		{x = 3.3, y = 0},
		{x = -2.3, y = 0},
	}
	for _, p in pairs(chestspos) do
		local e = surface.create_entity({name = 'wooden-chest', position = p, force = force, create_build_effect_smoke = false})
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
		end
	end
	for _, p in pairs(steerchestspos) do
		local e = surface.create_entity({name = 'blue-chest', position = p, force = force, create_build_effect_smoke = false})
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			if not memory.boat.crowsneststeeringchests then
				memory.boat.crowsneststeeringchests = {}
			end
			if p.y < 0 then
				memory.boat.crowsneststeeringchests.left = e
			else
				memory.boat.crowsneststeeringchests.right = e
			end
		end
	end
	for _, p in pairs(carspos) do
		local e = surface.create_entity({name = 'car', position = p, force = force, create_build_effect_smoke = false})
		if e and e.valid then
			e.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 16})
			e.destructible = false
			e.minable = false
			e.rotatable = false
			e.operable = false
		end
	end
end




function Public.paint_around_destination(id, tile_name)
	local memory = Memory.get_crew_memory()
	local destination_data = memory.destinations[id]
	local surface = game.surfaces[Public.crowsnest_surface_name()]

	local static_params = destination_data.static_params
	local type = destination_data.type

	local tiles = {}
	if type == SurfacesCommon.enum.ISLAND then

		for x = memory.overworldx + Public.platformrightmostedge + 0.5, memory.overworldx + Public.platformrightmostedge + destination_data.iconized_map_width - 0.5 do
			tiles[#tiles+1] = {name = tile_name, position = {x = x, y = memory.overworldy + destination_data.iconized_map_height/2 - 0.5}}
			tiles[#tiles+1] = {name = tile_name, position = {x = x, y = memory.overworldy - destination_data.iconized_map_height/2 + 0.5}}
		end
		for y = memory.overworldy + -destination_data.iconized_map_height/2 + 1.5, memory.overworldy + destination_data.iconized_map_height/2 - 1.5 do
			tiles[#tiles+1] = {name = tile_name, position = {x = memory.overworldx + Public.platformrightmostedge + 0.5, y = y}}
			tiles[#tiles+1] = {name = tile_name, position = {x = memory.overworldx + Public.platformrightmostedge + destination_data.iconized_map_width - 0.5, y = y}}
		end
	end

	surface.set_tiles(tiles, true, true, true)
end

function Public.terrain(args) --blank since we do this manually
	--
end

function Public.chunk_structures(args)
	--
end

return Public

