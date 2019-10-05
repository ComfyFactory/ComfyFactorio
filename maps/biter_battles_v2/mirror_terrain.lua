-- Mirrored Terrain for Biter Battles -- by MewMew
local event = require 'utils.event'

local direction_translation = {
	[0] = 4,
	[1] = 5,
	[2] = 6,
	[3] = 7,
	[4] = 0,
	[5] = 1,
	[6] = 2,
	[7] = 3
}

local cliff_orientation_translation = {
	["east-to-none"] =  "west-to-none",
	["east-to-north"] =  "west-to-south",
	["east-to-south"] =  "west-to-north",
	["east-to-west"] =  "west-to-east",
	["north-to-east"] =  "south-to-west",
	["north-to-none"] =  "south-to-none",
	["north-to-south"] =  "south-to-north",
	["north-to-west"] =  "south-to-east",
	["south-to-east"] =  "north-to-west",
	["south-to-none"] =  "north-to-none",
	["south-to-north"] =  "north-to-south",
	["south-to-west"] =  "north-to-east",
	["west-to-east"] =  "east-to-west",
	["west-to-none"] =  "east-to-none",
	["west-to-north"] =  "east-to-south",
	["west-to-south"] =  "east-to-north",
	["none-to-east"] =  "none-to-west",
	["none-to-north"] =  "none-to-south",
	["none-to-south"] =  "none-to-north",
	["none-to-west"] =  "none-to-east"
}

local valid_types = {
	["tree"] = true,
	["simple-entity"] = true,
	["cliff"] = true,
	["resource"] = true,
	["unit-spawner"] = true,
	["turret"] = true,
	["rocket-silo"] = true,
	["character"] = true,
	["ammo-turret"] = true,
	["wall"] = true,
	["fish"] = true,
}

local function process_entity(surface, entity)
	if not entity.valid then return end
	if not valid_types[entity.type] then return end
	local new_pos = {x = entity.position.x * -1, y = entity.position.y * -1}
	if entity.type == "tree" then
		if not surface.can_place_entity({name = entity.name, position = new_pos}) then return end
		entity.clone({position=new_pos, surface=surface, force="neutral"})
		return
	end
	if entity.type == "simple-entity" then
		local new_e = {name = entity.name, position = new_pos, direction = direction_translation[entity.direction]}
		if not surface.can_place_entity(new_e) then return end
		local e = surface.create_entity(new_e)
		e.graphics_variation = entity.graphics_variation
		return
	end
	if entity.type == "cliff" then
		local new_e = {name = entity.name, position = new_pos, cliff_orientation = cliff_orientation_translation[entity.cliff_orientation]}
		if not surface.can_place_entity(new_e) then return end
		surface.create_entity(new_e)
		return
	end
	if entity.type == "resource" then
		surface.create_entity({name = entity.name, position = new_pos, amount = entity.amount})
		return
	end
	--if entity.type == "unit-spawner" or entity.type == "unit" or entity.type == "turret" then
	if entity.type == "unit-spawner" or entity.type == "turret" then
		local new_e = {name = entity.name, position = new_pos, direction = direction_translation[entity.direction], force = "south_biters"}
		if not surface.can_place_entity(new_e) then return end
		surface.create_entity(new_e)
		return
	end
	if entity.name == "rocket-silo" then
		if surface.count_entities_filtered({name = "rocket-silo", area = {{new_pos.x - 8, new_pos.y - 8},{new_pos.x + 8, new_pos.y + 8}}}) > 0 then return end
		global.rocket_silo["south"] = surface.create_entity({name = entity.name, position = new_pos, direction = direction_translation[entity.direction], force = "south"})
		global.rocket_silo["south"].minable = false
		return
	end
	if entity.name == "gun-turret" or entity.name == "stone-wall" then
		if not surface.can_place_entity({name = entity.name, position = new_pos, force = "south"}) then return end
		entity.clone({position=new_pos, surface=surface, force="south"})
		return
	end
	if entity.name == "character" then
		return
	end
	if entity.name == "fish" then
		local new_e = {name = entity.name, position = new_pos, direction = direction_translation[entity.direction]}
		if not surface.can_place_entity(new_e) then return end
		local e = surface.create_entity(new_e)
		return
	end
end

local function clear_chunk(surface, area)
	surface.destroy_decoratives{area=area}
	if area.left_top.y > 32 or area.left_top.x > 32 or area.left_top.x < -32 then
		for _, e in pairs(surface.find_entities_filtered({area = area})) do
			if e.valid then
				e.destroy()
			end
		end
	else
		for _, e in pairs(surface.find_entities_filtered({area = area})) do
			if e.valid then
				if e.name ~= "character" then
					e.destroy()
				end
			end
		end
	end
end

local function mirror_chunk(surface, chunk)
	--local x = chunk.x * -32 + 32
	--local y = chunk.y * -32 + 32
	--clear_chunk(surface, {left_top = {x = x, y = y}, right_bottom = {x = x + 32, y = y + 32}})
	local chunk_area = {left_top = {x = chunk.x * 32, y = chunk.y * 32}, right_bottom = {x = chunk.x * 32 + 32, y = chunk.y * 32 + 32}}
	if not surface.is_chunk_generated(chunk) then
		surface.request_to_generate_chunks({x = chunk_area.left_top.x - 16, y = chunk_area.left_top.y - 16}, 1)
		surface.force_generate_chunk_requests()
	end
	for _, tile in pairs(surface.find_tiles_filtered({area = chunk_area})) do
		surface.set_tiles({{name = tile.name, position = {x = tile.position.x * -1, y = (tile.position.y * -1) - 1}}}, true)
	end
	for _, entity in pairs(surface.find_entities_filtered({area = chunk_area})) do
		process_entity(surface, entity)
	end
	for _, decorative in pairs(surface.find_decoratives_filtered{area=chunk_area}) do
		surface.create_decoratives{
			check_collision=false,
			decoratives={{name = decorative.decorative.name, position = {x = decorative.position.x * -1, y = (decorative.position.y * -1) - 1}, amount = decorative.amount}}
		}
	end
end

local function on_chunk_generated(event)
	if event.area.left_top.y < 0 then return end
	if event.surface.name ~= "biter_battles" then return end

	clear_chunk(event.surface, event.area)

	local x = ((event.area.left_top.x + 16) * -1) - 16
	local y = ((event.area.left_top.y + 16) * -1) - 16

	local delay = 30
	if not global.chunks_to_mirror[game.tick + delay] then global.chunks_to_mirror[game.tick + delay] = {} end
	global.chunks_to_mirror[game.tick + delay][#global.chunks_to_mirror[game.tick + delay] + 1] = {x = x / 32, y = y / 32}
end

local function ocg (event)
	if event.area.left_top.y < 0 then return end
	if event.surface.name ~= "biter_battles" then return end

	event.surface.destroy_decoratives{ area = event.area }
	-- Destroy biters here before they get active and attack other biters;
	-- prevents threat decrease
	for _, e in pairs(event.surface.find_entities_filtered{ area = event.area, force = "enemy" }) do
		if e.valid then e.destroy() end
	end

	local x = ((event.area.left_top.x + 16) * -1) - 16
	local y = ((event.area.left_top.y + 16) * -1) - 16

	if not global.ctp then global.ctp = { continue = 1, last = 0 } end
	local idx = global.ctp.last + 1
	global.ctp[idx] = {x = x / 32, y = y / 32, state = 1}
	global.ctp.last = idx
end


local function ticking_work()
	if not global.ctp then return end
	local work = global.mws or 137 -- define the number of work per tick here (for copies, creations, deletions)
	-- 136.5333 is the number of work needed to finish 4*(32*32) operations over 30 ticks (spreading a chunk copy over 30 ticks)
	local w = 0
	local i = global.ctp.continue
	local c = global.ctp[i]
	if not c then return end
	local state = c.state
	local d = c.data
	local area = {
		left_top = {x = c.x * 32, y = c.y * 32},
		right_bottom = {x = c.x * 32 + 32, y = c.y * 32 + 32}
	}
	local inverted_area = {
		left_top = { -area.right_bottom.x, -area.right_bottom.y },
		right_bottom = { -area.left_top.x, -area.left_top.y }
	}
	local surface = game.surfaces["biter_battles"]
	if not surface.is_chunk_generated(c) then
		-- game.print("Chunk not generated yet, requesting..")
		surface.request_to_generate_chunks({x = area.left_top.x - 16, y = area.left_top.y - 16}, 1)
		return
	end

	local tasks = {
		[1] = {
			name = "Clearing entities",
			list = function () return surface.find_entities_filtered({area = inverted_area, name = "character", invert = true}) end,
			action = function (e) e.destroy() end
		},
		[2] = {
			name = "Tile copy",
			list = function () return surface.find_tiles_filtered({area = area}) end,
			action = function (tile)
				surface.set_tiles({{
					name = tile.name,
					position = {x = tile.position.x * -1, y = (tile.position.y * -1) - 1}
				}}, true)
			end
		},
		[3] = {
			name = "Entity copy",
			list = function () return surface.find_entities_filtered({area = area}) end,
			action = function (entity) process_entity(surface, entity) end
		},
		[4] = {
			name = "Decorative copy",
			list = function () return surface.find_decoratives_filtered{area = area} end,
			action = function (decorative)
				surface.create_decoratives{
					check_collision = false,
					decoratives = {{
						name = decorative.decorative.name,
						position = {x = decorative.position.x * -1, y = (decorative.position.y * -1) - 1},
						amount = decorative.amount
					}}
				}
			end
		}
	}

	local task = tasks[c.state]
	-- game.print(task.name)
	d = d or task.list()
	for k, v in pairs(d) do
		task.action(v)
		d[k] = nil
		w = w + 1
		if w > work then break end
	end
	if #d == 0 then
		c.state = c.state + 1
		c.data = nil
	else
		c.data = d
	end

	if c.state == 5 then
		-- game.print("Finished processing chunk "..c.x..","..c.y)
		global.ctp.continue = i+1
		global.ctp[i] = nil
	else
		global.ctp.continue = i
	end
end

local function mirror_map()
	--local limit = 32
	for i, c in pairs(global.chunks_to_mirror) do
		if i < game.tick then
			for k, chunk in pairs(global.chunks_to_mirror[i]) do
				mirror_chunk(game.surfaces["biter_battles"], chunk)
				--global.chunks_to_mirror[i][k] = nil
				--limit = limit - 1
				--if limit == 0 then return end
			end
			global.chunks_to_mirror[i] = nil
		end
	end
end

event.add(defines.events.on_chunk_generated, ocg)
-- event.add(defines.events.on_chunk_generated, on_chunk_generated)

return ticking_work
-- return mirror_map