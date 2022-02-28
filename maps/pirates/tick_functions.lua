
local Memory = require 'maps.pirates.memory'
local Gui = require 'maps.pirates.gui.gui'
local Ai = require 'maps.pirates.ai'
local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Islands = require 'maps.pirates.surfaces.islands.islands'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Interface = require 'maps.pirates.interface'
local Roles = require 'maps.pirates.roles.roles'
local Classes = require 'maps.pirates.roles.classes'
local Progression = require 'maps.pirates.progression'
local Crowsnest = require 'maps.pirates.surfaces.crowsnest'
local Hold = require 'maps.pirates.surfaces.hold'
local Cabin = require 'maps.pirates.surfaces.cabin'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Overworld = require 'maps.pirates.overworld'
local Utils = require 'maps.pirates.utils_local'
local Crew = require 'maps.pirates.crew'
local Parrot = require 'maps.pirates.parrot'
local Math = require 'maps.pirates.math'
local inspect = require 'utils.inspect'.inspect

local Quest = require 'maps.pirates.quest'
local Loot = require 'maps.pirates.loot'
local ShopMini = require 'maps.pirates.shop.minimarket'
local ShopCovered = require 'maps.pirates.shop.covered'

local Public = {}


function Public.strobe_player_colors(tickinterval)
	local memory = Memory.get_crew_memory()

	local strobing_players = memory.speed_boost_characters

	if strobing_players and #strobing_players > 0 then
		local col = Utils.rgb_from_hsv((game.tick*6) % 360, 0.7, 0.9)
		for index, val in pairs(strobing_players) do
			if val then
				local player = game.players[index]
				if Common.validate_player_and_character(player) then
					player.color = col
				end
			end
		end
	end
end


function Public.prevent_unbarreling_off_ship(tickinterval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local boat = memory.boat
	local surface_name = boat.surface_name
	if not (surface_name and game.surfaces[surface_name] and game.surfaces[surface_name].valid) then return end
	local surface = game.surfaces[surface_name]

	local assemblers = surface.find_entities_filtered{type = 'assembling-machine', force = memory.force_name}

	for _, a in pairs(assemblers) do
		if a and a.valid then
			local r = a.get_recipe()
			if r and r.subgroup and r.subgroup.name and r.subgroup.name == 'fill-barrel' and (not (r.name and r.name == 'fill-water-barrel')) then
				if not Boats.on_boat(boat, a.position) then
					Common.notify_force(game.forces[memory.force_name], 'Barrelling recipe removed; barrels are too heavy to carry back to the ship.')
					a.set_recipe('fill-water-barrel')
				end
			end
		end
	end
end


function Public.prevent_disembark(tickinterval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local boat = memory.boat

	if boat and boat.state and (boat.state == Boats.enum_state.RETREATING or (boat.state == Boats.enum_state.LEAVING_DOCK and (not (memory.crewstatus and memory.crewstatus == Crew.enum.LEAVING_INITIAL_DOCK)))) then

		if not destination.dynamic_data.cant_disembark_players then destination.dynamic_data.cant_disembark_players = {} end
		local ps = destination.dynamic_data.cant_disembark_players

		for _, player in pairs(game.connected_players) do
			if player.surface and player.surface.valid and boat.surface_name and player.surface.name == boat.surface_name and Boats.on_boat(boat, player.position) then
				ps[player.index] = true
			end
		end

		for _, player in pairs(game.connected_players) do
			if player.surface and player.surface.valid and boat.surface_name and player.surface.name == boat.surface_name and ps[player.index] and (not Boats.on_boat(boat, player.position)) then
				Common.notify_player_error(player, 'Now is no time to disembark.')
				-- player.teleport(memory.spawnpoint)
				local p = player.surface.find_non_colliding_position('character', memory.spawnpoint, 5, 0.1)
				if p then
					player.teleport(p)
				else
					player.teleport(memory.spawnpoint)
				end
			end
		end
	end
end

function Public.check_all_spawners_dead(tickinterval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local boat = memory.boat

	if destination.static_params and destination.static_params.cost_to_leave and (not (destination.subtype and destination.subtype == Islands.enum.RED_DESERT)) then
		if boat and boat.surface_name and boat.surface_name == destination.surface_name then
			local surface = game.surfaces[destination.surface_name]
			if not (surface and surface.valid) then return end

			local spawnerscount = Common.spawner_count(surface)
			if spawnerscount == 0 then
				destination.static_params.cost_to_leave = nil
				Common.notify_force(game.forces[memory.force_name], 'All biter bases destroyed — escape cost removed.')
			end
		end
	end
	
end


function Public.raft_raids(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	local destination = Common.current_destination()
	if not destination then return end
	if (not destination.static_params) or (not destination.static_params.scheduled_raft_raids) or (not destination.dynamic_data.timer) then return end
	local scheduled_raft_raids = destination.static_params.scheduled_raft_raids
	local timer = destination.dynamic_data.timer

	for _, raid in pairs(scheduled_raft_raids) do
		if timer == raid.timeinseconds then
			local type
			if memory.overworldx >= 40*18 then
				type = Boats.enum.RAFTLARGE
			else
				type = Boats.enum.RAFT
			end
			local boat = Islands.spawn_enemy_boat(type)
			if boat then
				Ai.spawn_boat_biters(boat, raid.max_evo, Boats.get_scope(boat).Data.capacity, Boats.get_scope(boat).Data.width)
			end
		end
	end
end

function Public.ship_deplete_fuel(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	if not (memory.stored_fuel and memory.boat.input_chests and memory.boat.input_chests[1])then return end

	local rate = Progression.fuel_depletion_rate()

	local boat = memory.boat

	local input_chests = boat.input_chests
	local inv = input_chests[1].get_inventory(defines.inventory.chest)
	local contents = inv.get_contents()
	local item_type = 'coal'
	local count = contents[item_type] or 0
	if count > 0 then
		inv.remove{name = 'coal', count = count}
	end

	memory.stored_fuel = memory.stored_fuel + count + rate*tickinterval/60

	if memory.stored_fuel < 0 then
		Crew.try_lose('out of fuel')
	end
end

function Public.transfer_pollution(tickinterval)
	local memory = Memory.get_crew_memory()
	
	local p = 0
	for i = 1, memory.hold_surface_count do
		local surface = Hold.get_hold_surface(i)
		if not surface then return end
		p = p + surface.get_total_pollution()
		surface.clear_pollution()
	end

	if not (p and memory.floating_pollution) then return end

	memory.floating_pollution = memory.floating_pollution + p
end

function Public.shop_ratelimit_tick(tickinterval)
	local memory = Memory.get_crew_memory()

	-- if memory.mainshop_rate_limit_ticker and memory.mainshop_rate_limit_ticker > 0 then
	-- 	memory.mainshop_rate_limit_ticker = memory.mainshop_rate_limit_ticker - tickinterval
	-- end
end

function Public.captain_warn_afk(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end

	if memory.playerindex_captain then
		for _, player in pairs(game.connected_players) do
			if player.index == memory.playerindex_captain and #Common.crew_get_nonafk_crew_members() > 1 and player.afk_time >= Common.afk_time - 20*60 - 60 - tickinterval and player.afk_time < Common.afk_time - 20*60 then
				Common.notify_player_expected(player, 'Note: If you go idle as captain for too long, the role passes to another crewmember.')
				player.play_sound{path = 'utility/scenario_message'}
			end
		end
	end
end

function Public.periodic_free_resources(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	local destination = Common.current_destination()
	local boat = memory.boat
	if not (destination and destination.type and destination.type == Surfaces.enum.ISLAND and boat and boat.surface_name and boat.surface_name == destination.surface_name) then return end

	Common.give_reward_items(Balance.periodic_free_resources_per_destination_5_seconds())

	if game.tick % 300*5 == 0 and (destination and destination.subtype and destination.subtype == Islands.enum.RADIOACTIVE) then
		-- every 30 seconds
		Common.give_reward_items{{name = 'sulfuric-acid-barrel', count = 1}}
	end
end

function Public.pick_up_tick(tickinterval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	if not destination then return end
	local surface_name = destination.surface_name
	if (not destination.dynamic_data) or (not destination.dynamic_data.treasure_maps) or (not surface_name) or (not game.surfaces[surface_name]) or (not game.surfaces[surface_name].valid) then return end
	local surface = game.surfaces[surface_name]

	local maps = destination.dynamic_data.treasure_maps or {}
	local buried_treasure = destination.dynamic_data.buried_treasure or {}
	local ghosts = destination.dynamic_data.ghosts or {}

	for i = 1, #maps do
		local map = maps[i]

		if map.state == 'on_ground' then
			local p = map.position
	
			local nearby_characters = surface.find_entities_filtered{position = p, radius = 3, name = 'character'}
			local nearby_characters_count = #nearby_characters
			if nearby_characters_count > 0 then
	
				local player
				local j = 1
				while j <= nearby_characters_count do
					if nearby_characters[j] and nearby_characters[j].valid and nearby_characters[j].player and Common.validate_player(nearby_characters[j].player) then
						player = nearby_characters[j].player
						break
					end
					j = j + 1
				end
				if player then
					local buried_treasure_candidates = {}
					for _, t in pairs(buried_treasure) do
						if not (t.associated_to_map) then
							buried_treasure_candidates[#buried_treasure_candidates + 1] = t
						end
					end
					if #buried_treasure_candidates == 0 then break end
					local chosen = buried_treasure_candidates[Math.random(#buried_treasure_candidates)]
		
					chosen.associated_to_map = true
					local p2 = chosen.position
					map.buried_treasure_position = p2
		
					map.state = 'picked_up'
					rendering.destroy(map.mapobject_rendering)
	
					Common.notify_force(player.force, player.name .. ' found a map. Treasure location revealed.')
		
					map.x_renderings = {
						rendering.draw_line{
							width = 8,
							surface = surface,
							from = {p2.x + 3, p2.y + 3},
							to = {p2.x - 3, p2.y - 3},
							color = {1,0,0},
							gap_length = 0.2,
							dash_length = 1,
							draw_on_ground = true,
							-- players = {player},
						},
						rendering.draw_line{
							width = 8,
							surface = surface,
							from = {p2.x - 3, p2.y + 3},
							to = {p2.x + 3, p2.y - 3},
							color = {1,0,0},
							gap_length = 0.2,
							dash_length = 1,
							draw_on_ground = true,
							-- players = {player},
						},
					}
				end
			end
		end
	end

	if not (destination and destination.dynamic_data and destination.dynamic_data.quest_type and (not destination.dynamic_data.quest_complete)) then return end

	for i = 1, #ghosts do
		local ghost = ghosts[i]

		if ghost.state == 'on_ground' then
			local p = ghost.position
	
			local nearby_characters = surface.find_entities_filtered{position = p, radius = 3, name = 'character'}
			local nearby_characters_count = #nearby_characters
			if nearby_characters_count > 0 then
	
				local player
				local j = 1
				while j <= nearby_characters_count do
					if nearby_characters[j] and nearby_characters[j].valid and nearby_characters[j].player and Common.validate_player(nearby_characters[j].player) then
						player = nearby_characters[j].player
						break
					end
					j = j + 1
				end
				if player then
					rendering.destroy(ghost.ghostobject_rendering)
			
					ghost.state = 'picked_up'
	
					Common.notify_force(player.force, player.name .. ' found a ghost.')
	
					destination.dynamic_data.quest_progress = destination.dynamic_data.quest_progress + 1
					Quest.try_resolve_quest()
				end
			end
		end
	end
end

function Public.place_cached_structures(tickinterval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface_name = destination.surface_name

	if (not destination.dynamic_data) or (not destination.dynamic_data.structures_waiting_to_be_placed) or (not surface_name) or (not game.surfaces[surface_name]) or (not game.surfaces[surface_name].valid) then return end

	local surface = game.surfaces[surface_name]

	local structures = destination.dynamic_data.structures_waiting_to_be_placed
	local num = #structures
	for i = num, 1, -1 do
		local structure = structures[i]

		if game.tick > structure.tick + 5 then
			local special = structure.data
			local position = special.position

			Common.ensure_chunks_at(surface, position, 2)

			-- destroy existing entities
			local area = {left_top = {position.x - special.width/2, position.y - special.height/2}, right_bottom = {position.x + special.width/2 + 0.5, position.y + special.height/2 + 0.5}}

			surface.destroy_decoratives{area=area}
			local existing = surface.find_entities_filtered{area = area}
			if existing and (not (special.name == 'covered1b')) then
				for _, e in pairs(existing) do
					if not (((special.name == 'small_primitive_mining_base' or special.name == 'small_mining_base') and (e.name == 'iron-ore' or e.name == 'copper-ore' or e.name == 'stone')) or (special.name == 'uranium_miners' and e.name == 'uranium-ore')) then
						e.destroy()
					end
				end
			end
			
			local saved_components = {}
			for k = 1, #special.components do
				local c = special.components[k]

				local force_name
				if c.force then force_name = c.force end
				if force_name == 'ancient-friendly' then
					force_name = string.format('ancient-friendly-%03d', memory.id)
				elseif force_name == 'ancient-hostile' then
					force_name = string.format('ancient-hostile-%03d', memory.id)
				elseif force_name == 'crew' then
					force_name = string.format('crew-%03d', memory.id)
				end

				if c.type == 'tiles' then
					local tiles = {}
					for _, p in pairs(Common.tile_positions_from_blueprint(c.bp_string, c.offset)) do
						tiles[#tiles + 1] = {name = c.tile_name, position = Utils.psum{position, p}}
					end
					if #tiles > 0 then
						surface.set_tiles(tiles, true)
					end

				elseif c.type == 'entities' or c.type == 'entities_minable' then
					local c2 = {type = c.type, force_name = force_name, built_entities = {}}

					for _, e in pairs(c.instances) do
						local p = Utils.psum{position, e.position, c.offset}
						local e2 = surface.create_entity{name = c.name, position = p, direction = e.direction, force = force_name, amount = c.amount}
						c2.built_entities[#c2.built_entities + 1] = e2
					end

					saved_components[#saved_components + 1] = c2

				elseif c.bp_string then
					local c2 = {type = c.type, force_name = force_name, built_entities = {}}

					local es = Common.build_from_blueprint(c.bp_string, surface, Utils.psum{position, c.offset}, game.forces[force_name])
					for l = 1, #es do
						c2.built_entities[#c2.built_entities + 1] = es[l]
					end

					saved_components[#saved_components + 1] = c2
				end
			end
			Structures.post_creation_process(special.name, saved_components)

			if special.name == 'covered1' then
				local covered_data = destination.dynamic_data.covered_data
				if not covered_data then return end

				local hardcoded_data = Structures.IslandStructures.ROC.covered1.Data

				covered_data.blue_chest = surface.create_entity{name = 'blue-chest', position = Math.vector_sum(special.position, hardcoded_data.blue_chest), force = 'environment'}
				if covered_data.blue_chest and covered_data.blue_chest.valid then
					covered_data.blue_chest.minable = false
					covered_data.blue_chest.rotatable = false
					covered_data.blue_chest.operable = false
					covered_data.blue_chest.destructible = false
				end
				covered_data.red_chest = surface.create_entity{name = 'red-chest', position = Math.vector_sum(special.position, hardcoded_data.red_chest), force = 'environment'}
				if covered_data.red_chest and covered_data.red_chest.valid then
					covered_data.red_chest.minable = false
					covered_data.red_chest.rotatable = false
					covered_data.red_chest.operable = false
					covered_data.red_chest.destructible = false
				end
				covered_data.door_walls = {}
				for _, p in pairs(hardcoded_data.walls) do
					local e = surface.create_entity{name = 'stone-wall', position = Math.vector_sum(special.position, p), force = 'environment'}
					if e and e.valid then
						e.minable = false
						e.rotatable = false
						e.operable = false
						e.destructible = false
					end
					covered_data.door_walls[#covered_data.door_walls + 1] = e
					-- @TODO: Add loot here
				end

			elseif special.name == 'covered1b' then
				local covered_data = destination.dynamic_data.covered_data
				if not covered_data then return end

				local hardcoded_data = Structures.IslandStructures.ROC.covered1b.Data

				covered_data.market = surface.create_entity{name = 'market', position = Math.vector_sum(special.position, hardcoded_data.market), force = string.format('ancient-friendly-%03d', memory.id)}
				if covered_data.market and covered_data.market.valid then
					covered_data.market.minable = false
					covered_data.market.rotatable = false
					covered_data.market.destructible = false
					-- @TODO: Add trades here

					covered_data.market.add_market_item{price={{'pistol', 1}}, offer={type = 'give-item', item = 'coin', count = 400}}
					covered_data.market.add_market_item{price={{'burner-mining-drill', 1}}, offer={type = 'give-item', item = 'iron-plate', count = 9}}

					local coin_offers = ShopCovered.market_generate_coin_offers(4)
					for _, o in pairs(coin_offers) do
						covered_data.market.add_market_item(o)
					end

					covered_data.market.add_market_item{price={{'coin', Balance.class_cost()}}, offer={type="nothing"}}

					destination.dynamic_data.market_class_offer_rendering = rendering.draw_text{
						text = 'Class available: ' .. Classes.display_form[destination.static_params.class_for_sale],
						surface = surface,
						target = Utils.psum{special.position, hardcoded_data.market, {x = 1, y = -3}},
						color = CoreData.colors.renderingtext_green,
						scale = 3,
						font = 'default-game',
						alignment = 'center'
					}
				end

				covered_data.steel_chest = surface.create_entity{name = 'steel-chest', position = Math.vector_sum(special.position, hardcoded_data.steel_chest), force = string.format('ancient-friendly-%03d', memory.id)}
				if covered_data.steel_chest and covered_data.steel_chest.valid then
					covered_data.steel_chest.minable = false
					covered_data.steel_chest.rotatable = false
					covered_data.steel_chest.destructible = false

					local inv = covered_data.steel_chest.get_inventory(defines.inventory.chest)
					local loot = destination.dynamic_data.covered1_requirement.raw_materials
					for j = 1, #loot do
						local l = loot[j]
						if l.count > 0 then
							inv.insert(l)
						end
					end
				end
				-- @TODO: Add loot here

				for _, w in pairs(covered_data.door_walls) do
					w.destructible = true
					w.destroy()
				end

				covered_data.wooden_chests = {}
				for i, p in ipairs(hardcoded_data.wooden_chests) do
					local e = surface.create_entity{name = 'wooden-chest', position = Math.vector_sum(special.position, p), force = string.format('ancient-friendly-%03d', memory.id)}
					if e and e.valid then
						e.minable = false
						e.rotatable = false
						e.destructible = false

						local inv = e.get_inventory(defines.inventory.chest)
						local loot = Loot.covered_wooden_chest_loot()
						if i==1 then loot[#loot + 1] = {name = 'coin', count = 1500} end
						for j = 1, #loot do
							local l = loot[j]
							inv.insert(l)
						end
					end
					covered_data.wooden_chests[#covered_data.wooden_chests + 1] = e
					-- @TODO: Add loot here
				end
			end


			for j = i, #structures-1 do
				structures[j] = structures[j+1]
			end
			structures[#structures] = nil
		end
	end
end

function Public.covered_requirement_check(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	local destination = Common.current_destination()
	if not (destination and destination.dynamic_data) then return end

	local covered_data = destination.dynamic_data.covered_data
	if not covered_data then return end
	
	local blue_chest = covered_data.blue_chest
	local red_chest = covered_data.red_chest
	if not (blue_chest and blue_chest.valid and red_chest and red_chest.valid) then return end
	local blue_inv = covered_data.blue_chest.get_inventory(defines.inventory.chest)
	local red_inv = covered_data.red_chest.get_inventory(defines.inventory.chest)
	
	local blue_contents = blue_inv.get_contents()

	local requirement = covered_data.requirement

	local got = 0
	for k, v in pairs(blue_contents) do
		if covered_data.state == 'covered' and k == requirement.name then
			got = v
		else
			-- @FIX: power armor loses components, items lose health
			red_inv.insert({name = k, count = v});
			blue_inv.remove({name = k, count = v});
		end
	end

	if covered_data.state == 'covered' then
		if got >= requirement.count then
			blue_inv.remove({name = requirement.name, count = requirement.count});
			covered_data.state = 'uncovered'
			rendering.destroy(covered_data.rendering1)
			rendering.destroy(covered_data.rendering2)

			local structureData = Structures.IslandStructures.ROC.covered1b.Data
			local special = {
				position = covered_data.position,
				components = structureData.components,
				width = structureData.width,
				height = structureData.height,
				name = structureData.name,
			}
			destination.dynamic_data.structures_waiting_to_be_placed[#destination.dynamic_data.structures_waiting_to_be_placed + 1] = {data = special, tick = game.tick}
		else
			if covered_data.rendering1 then
				rendering.set_text(covered_data.rendering1, 'Needs ' .. requirement.count - got .. ' x')
			end
		end
	else

	end
end



function Public.update_boat_stored_resources(tickinterval)
	Common.update_boat_stored_resources()
end



function Public.buried_treasure_check(tickinterval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local remaining = destination.dynamic_data.treasure_remaining

	if remaining and remaining > 0 and destination.surface_name and destination.dynamic_data.buried_treasure and #destination.dynamic_data.buried_treasure > 0 then
		local surface = game.surfaces[destination.surface_name]
		local treasure_table = destination.dynamic_data.buried_treasure

		for i = 1, #treasure_table do
			local treasure = treasure_table[i]
			if not treasure then break end
			local p = treasure.position


			local free = surface.can_place_entity{name = 'wooden-chest', position = p}

			if free then
				local inserters = {
					surface.find_entities_filtered{
						type = 'inserter',
						position = {x = p.x - 1, y = p.y},
						radius = 0.1,
						direction = defines.direction.east
					},
					surface.find_entities_filtered{
						type = 'inserter',
						position = {x = p.x + 1, y = p.y},
						radius = 0.1,
						direction = defines.direction.west
					},
					surface.find_entities_filtered{
						type = 'inserter',
						position = {x = p.x, y = p.y - 1},
						radius = 0.1,
						direction = defines.direction.south
					},
					surface.find_entities_filtered{
						type = 'inserter',
						position = {x = p.x, y = p.y + 1},
						radius = 0.1,
						direction = defines.direction.north
					}
				}
	
				for j = 1,4 do
	
					if inserters[j] and inserters[j][1] then
						local ins = inserters[j][1]
	
						local t = treasure.treasure
						-- if #treasure.treasure > 0 then
						-- 	t = treasure.treasure
						-- 	-- t = treasure.treasure[1]
						-- end
						if not t then break end
						
						if destination.dynamic_data.treasure_remaining > 0 and ins.held_stack.count == 0 and ins.status == defines.entity_status.waiting_for_source_items then
							surface.create_entity{name = 'item-on-ground', position = p, stack = {name = t.name, count = 1}}
							t.count = t.count - 1
							destination.dynamic_data.treasure_remaining = destination.dynamic_data.treasure_remaining - 1

							if destination.dynamic_data.treasure_remaining == 0 then
								-- destroy all
								local buried_treasure = destination.dynamic_data.buried_treasure
								for _, t2 in pairs(buried_treasure) do
									t2 = nil
								end
								local maps = destination.dynamic_data.treasure_maps
								for _, m in pairs(maps) do
									if m.state == 'on_ground' then
										rendering.destroy(m.mapobject_rendering)
									elseif m.state == 'picked_up' and m.x_renderings and #m.x_renderings > 0 then
										rendering.destroy(m.x_renderings[1])
										rendering.destroy(m.x_renderings[2])
									end
									m = nil
								end
							elseif t.count <= 0 then
								treasure.treasure = nil

								local maps = destination.dynamic_data.treasure_maps
								for _, m in pairs(maps) do
									if m.state == 'picked_up' and m.buried_treasure_position and m.buried_treasure_position == p and m.x_renderings and #m.x_renderings > 0 then
										m.state = 'inactive'
										rendering.destroy(m.x_renderings[1])
										rendering.destroy(m.x_renderings[2])
									end
								end
							end
						end
					end
				end
			end
		end
	end
end


function Public.boat_movement_tick(tickinterval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local boat = memory.boat
	if boat and boat.surface_name and game.surfaces[boat.surface_name] and game.surfaces[boat.surface_name].valid and boat.speed and boat.speed > 0 and memory.game_lost == false then

		local surface_type = destination.type

		local ticker_increase = boat.speed / 60 * tickinterval
		boat.speedticker1 = boat.speedticker1 + ticker_increase
		boat.speedticker2 = boat.speedticker2 + ticker_increase
		boat.speedticker3 = boat.speedticker3 + ticker_increase

		if boat.speedticker1 >= Common.boat_steps_at_a_time then
			boat.speedticker1 = 0
			if not Progression.check_for_end_of_boat_movement(boat) then
				Structures.Boats.currentdestination_move_boat_natural()
			end
		elseif boat.speedticker2 >= Common.boat_steps_at_a_time then
			if surface_type and surface_type == Surfaces.enum.ISLAND and boat and boat.state and boat.state ==  Boats.enum_state.APPROACHING then
				Structures.Boats.currentdestination_try_move_boat_steered()
			end
			boat.speedticker2 = 0
		end
	end

	if memory.enemyboats then
		for i = 1, #memory.enemyboats do
			local eboat = memory.enemyboats[i]
			if eboat and eboat.surface_name and game.surfaces[eboat.surface_name] and game.surfaces[eboat.surface_name].valid then
				if eboat.state == Boats.enum_state.APPROACHING and eboat.speed and eboat.speed > 0 and memory.game_lost == false then
					local ticker_increase = eboat.speed / 60 * tickinterval
					eboat.speedticker1 = eboat.speedticker1 + ticker_increase
					if eboat.speedticker1 >= 1 then
						eboat.speedticker1 = 0
						if eboat.state == Boats.enum_state.APPROACHING then
							if not Progression.check_for_end_of_boat_movement(eboat) then
								local p = {x = eboat.position.x + 1, y = eboat.position.y}
								Boats.teleport_boat(eboat, nil, p, CoreData.static_boat_floor)
								if p.x % 7 < 1 then
									Ai.update_landing_party_unit_groups(eboat, 7)
								end
							end
						end
					end
				end
			else
				memory.enemyboats[i] = nil
			end
		end
	end
end



function Public.crowsnest_natural_move(tickinterval)
	local memory = Memory.get_crew_memory()

	if not memory.loadingticks then
		if not Public.overworld_check_collisions() then
			Overworld.try_overworld_move_v2{x = 1, y = 0}
		end
	end
end


function Public.overworld_check_collisions(tickinterval)
	local memory = Memory.get_crew_memory()

	if not memory.loadingticks then
		Overworld.check_for_kraken_collisions()
		return Overworld.check_for_destination_collisions()
	end
	return false
end





function Public.loading_update(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	local currentdestination = Common.current_destination()

	if not memory.loadingticks then return end
	
	local destination_index = memory.mapbeingloadeddestination_index
	if not destination_index then memory.loadingticks = nil return end

	if (not memory.boat.state) or (not (memory.boat.state == Boats.enum_state.LANDED or memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP or memory.boat.state == Boats.enum_state.LEAVING_DOCK or (memory.boat.state == Boats.enum_state.APPROACHING and destination_index == 1))) then return end

	memory.loadingticks = memory.loadingticks + tickinterval

	-- if memory.loadingticks % 100 == 0 then game.print(memory.loadingticks) end

	local destination_data = memory.destinations[destination_index]
	if (not destination_data) then
		if memory.boat and currentdestination.type == Surfaces.enum.LOBBY then
			if memory.loadingticks >= 350 - Common.loading_interval then
				if Boats.players_on_boat_count(memory.boat) > 0 then
					if memory.loadingticks < 350 then
						Common.notify_game('[' .. memory.name .. '] Loading new game...')
					elseif memory.loadingticks > 410 then
						if not Crowsnest.get_crowsnest_surface() then
							Crew.initialise_crowsnest_1()
						elseif memory.loadingticks >= 470 then
							Crew.initialise_crowsnest_2()
							Overworld.ensure_lane_generated_up_to(0, 10)
							Surfaces.create_surface(memory.destinations[destination_index])
							-- Interface.load_some_map_chunks(destination_index, 0.02)
						end
					end
				else
					if memory.loadingticks >= 1100 then
						Boats.destroy_boat(memory.boat)
						Crew.disband_crew()
						return
					end
				end
			end
		end
		return
	else
		local surface_name = destination_data.surface_name
		if not surface_name then return end
		local surface = game.surfaces[surface_name]
		if not surface then return end


		if currentdestination.type == Surfaces.enum.LOBBY then

			if memory.loadingticks >= 1260 then
				
				if memory.boat and memory.boat.rendering_crewname_text and rendering.is_valid(memory.boat.rendering_crewname_text) then
					rendering.destroy(memory.boat.rendering_crewname_text)
					memory.boat.rendering_crewname_text = nil
				end
				
				Progression.go_from_starting_dock_to_first_destination()

			elseif memory.loadingticks > 1230 then

				if memory.boat then
					memory.boat.speed = 0
				end

			elseif memory.loadingticks > 860 then

				if Boats.players_on_boat_count(memory.boat) > 0 then
					local fraction = 0.07 + 0.7 * (memory.loadingticks - 860) / 400

					Interface.load_some_map_chunks(destination_index, fraction)
				else
					Boats.destroy_boat(memory.boat)
					Crew.disband_crew()
					return
				end

			elseif memory.loadingticks > 500 then

				local d = (Crowsnest.Data.visibilitywidth/3)*(memory.loadingticks-500)/500
				Overworld.ensure_lane_generated_up_to(0, d+26)
				Overworld.ensure_lane_generated_up_to(24, d+13)
				Overworld.ensure_lane_generated_up_to(-24, d)

			-- elseif memory.loadingticks <= 500 and memory.loadingticks >= 100 then
			-- 	local fraction = 0.02 + 0.05 * (memory.loadingticks - 100) / 400

			-- 	Interface.load_some_map_chunks(destination_index, fraction)
			end

		elseif memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP then

			local total = Common.map_loading_ticks_atsea
			if currentdestination.type == Surfaces.enum.DOCK then
				total = Common.map_loading_ticks_atsea_dock
			end

			local eta_ticks = total + (memory.extra_time_at_sea or 0) - memory.loadingticks

			if eta_ticks < 60*20 and memory.active_sea_enemies and (memory.active_sea_enemies.krakens and #memory.active_sea_enemies.krakens > 0) then
				memory.loadingticks = memory.loadingticks - tickinterval
			else
				local fraction = memory.loadingticks / (total + (memory.extra_time_at_sea or 0))
		
				if fraction > Common.fraction_of_map_loaded_atsea then
					Progression.progress_to_destination(destination_index)
					memory.loadingticks = 0
				else
					Interface.load_some_map_chunks(destination_index, fraction)
				end
			end

		elseif memory.boat.state == Boats.enum_state.LANDED then
			local fraction = Common.fraction_of_map_loaded_atsea + (1 - Common.fraction_of_map_loaded_atsea) * memory.loadingticks / Common.map_loading_ticks_onisland

			if fraction > 1 then
				memory.loadingticks = nil
			else
				Interface.load_some_map_chunks(destination_index, fraction)
			end

		end
	end

end






function Public.crowsnest_steer(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	
	if memory.boat and memory.boat.state == Structures.Boats.enum_state.ATSEA_SAILING and memory.game_lost == false and memory.boat.crowsneststeeringchests then
		local leftchest, rightchest = memory.boat.crowsneststeeringchests.left, memory.boat.crowsneststeeringchests.right
		if leftchest and leftchest.valid and rightchest and rightchest.valid then
			local inv_left = leftchest.get_inventory(defines.inventory.chest)
			local inv_right = rightchest.get_inventory(defines.inventory.chest)
			local count_left = inv_left.get_item_count("rail-signal")
			local count_right = inv_right.get_item_count("rail-signal")

			if count_left >= 100 and count_right < 100 and memory.overworldy > -24 then
				if Overworld.try_overworld_move_v2{x = 0, y = -24} then
					local force = game.forces[memory.force_name]
					Common.notify_force(force, 'Steering portside...')
					inv_left.remove({name = "rail-signal", count = 100})
				end
				return
			elseif count_right >= 100 and count_left < 100 and memory.overworldy < 24 then
				if Overworld.try_overworld_move_v2{x = 0, y = 24} then
					local force = game.forces[memory.force_name]
					Common.notify_force(force, 'Steering starboard...')
					inv_right.remove({name = "rail-signal", count = 100})
				end
				return
			end
		end
	end
end

function Public.silo_update(tickinterval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	if destination.type == Surfaces.enum.ISLAND then
		local silos = destination.dynamic_data.rocketsilos

		if silos and silos[1] and silos[1].valid then
			local silo = silos[1]
			if destination.dynamic_data.silocharged == false then

				local p = silo.position

				local e = destination.dynamic_data.energychargedinsilosincelastcheck or 0
				destination.dynamic_data.energychargedinsilosincelastcheck = 0

				destination.dynamic_data.rocketsiloenergyconsumed = destination.dynamic_data.rocketsiloenergyconsumed + e

				destination.dynamic_data.rocketsiloenergyconsumedwithinlasthalfsecond = e

				if memory.enemy_force_name then
					local ef = game.forces[memory.enemy_force_name]
					if ef and ef.valid then
						local extra_evo = Balance.evolution_per_full_silo_charge() * e/destination.dynamic_data.rocketsiloenergyneeded
						ef.evolution_factor = ef.evolution_factor + extra_evo
						destination.dynamic_data.evolution_accrued_silo = destination.dynamic_data.evolution_accrued_silo + extra_evo
					end
				end

				local pollution = e/1000000 * Balance.silo_total_pollution() / Balance.silo_energy_needed_MJ()

				if p and pollution then
					game.surfaces[destination.surface_name].pollute(p, pollution)
					game.pollution_statistics.on_flow('rocket-silo', pollution)
	
					if destination.dynamic_data.rocketsiloenergyconsumed >= destination.dynamic_data.rocketsiloenergyneeded and (not (silo.rocket_parts == 100)) and (destination.dynamic_data.silocharged == false) and memory.game_lost == false then
						-- silo.energy = 0
						silo.rocket_parts = 100
						silo.destructible = false
						destination.dynamic_data.silocharged = true
					end
				end
			elseif destination.dynamic_data.silocharged == true then
				if destination.dynamic_data.rocketlaunched == false then
					silo.launch_rocket()
				end
			end
		end
	end
end

function Public.slower_boat_tick(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	local destination = Common.current_destination()

	if memory.boat.state == Boats.enum_state.LEAVING_DOCK then
		memory.boat.speed = Math.min(memory.boat.speed + 40/tickinterval, 12)
	end

	local p = memory.boat.position
	if p and (not (destination.subtype and destination.subtype == IslandsCommon.enum.RADIOACTIVE)) and destination.surface_name and game.surfaces[destination.surface_name] and game.surfaces[destination.surface_name].valid then --no locomotive pollute on radioactive islands
		local pollution = Balance.boat_passive_pollution_per_minute(destination.dynamic_data.timer) / 3600 * tickinterval
	
		game.surfaces[destination.surface_name].pollute(p, pollution)
		game.pollution_statistics.on_flow('locomotive', pollution)
	end

	if memory.enemyboats then
		for i = 1, #memory.enemyboats do
			local b = memory.enemyboats[i]
	
			if b.landing_time and destination.dynamic_data.timer >= b.landing_time + 3 and b.spawner and b.spawner.valid then
				b.spawner.destructible = true
				b.landing_time = nil
			end
		end
	end
end

function Public.LOS_tick(tickinterval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local force = game.forces[memory.force_name]
	if not destination.surface_name then return end
	local surface = game.surfaces[destination.surface_name]

	if memory.boat and memory.boat.state == Boats.enum_state.APPROACHING or memory.boat.state == Boats.enum_state.LANDED or memory.boat.state == Boats.enum_state.RETREATING then
		local p = memory.boat.position
		local BoatData = Boats.get_scope(memory.boat).Data
	
		force.chart(surface, {{p.x - BoatData.width/2 - 70, p.y - 80},{p.x - BoatData.width/2 + 70, p.y + 80}})
	end

	local silos = destination.dynamic_data.rocketsilos
	if silos and silos[1] and silos[1].valid then
		local p = silos[1].position
		force.chart(surface, {{p.x - 4, p.y - 4},{p.x + 4, p.y + 4}})
	end
end

-- function Public.crewtick_handle_delayed_tasks(tickinterval)
-- 	local memory = Memory.get_crew_memory()

-- 	for _, task in pairs(memory.buffered_tasks) do
-- 		if not (memory.game_lost) then
-- 			if task == Delay.enum.PAINT_CROWSNEST then
-- 				Surfaces.Crowsnest.crowsnest_surface_delayed_init()
	
-- 			elseif task == Delay.enum.PLACE_DOCK_JETTY_AND_BOATS then
-- 				Surfaces.Dock.place_dock_jetty_and_boats()
	
-- 				local destination = Common.current_destination()
-- 				ShopMini.create_minimarket(game.surfaces[destination.surface_name], Surfaces.Dock.Data.market_position)
-- 			end
-- 		end
-- 	end
-- 	Delay.clear_buffer()
-- 	Delay.move_tasks_to_buffer()
-- end

function Public.quest_progress_tick(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	local destination = Common.current_destination()

	if destination.dynamic_data.quest_type == Quest.enum.TIME and (not destination.dynamic_data.quest_complete) and destination.dynamic_data.quest_progress > 0 and destination.dynamic_data.quest_progressneeded ~= 1 then
		destination.dynamic_data.quest_progress = destination.dynamic_data.quest_progress - tickinterval/60
	end

	if destination.dynamic_data.quest_type == Quest.enum.RESOURCEFLOW and (not destination.dynamic_data.quest_complete) then
		local force = game.forces[memory.force_name]
		if not (force and force.valid and destination.dynamic_data.quest_params) then return end
		destination.dynamic_data.quest_progress = force.item_production_statistics.get_flow_count{name = destination.dynamic_data.quest_params.item, input = true, precision_index = defines.flow_precision_index.five_seconds, count = false}
		Quest.try_resolve_quest()
	end

	if destination.dynamic_data.quest_type == Quest.enum.RESOURCECOUNT and (not destination.dynamic_data.quest_complete) then
		local force = game.forces[memory.force_name]
		if not (force and force.valid and destination.dynamic_data.quest_params) then return end
		destination.dynamic_data.quest_progress = force.item_production_statistics.get_flow_count{name = destination.dynamic_data.quest_params.item, input = true, precision_index = defines.flow_precision_index.one_thousand_hours, count = true} - destination.dynamic_data.quest_params.initial_count
		Quest.try_resolve_quest()
	end

end



function Public.silo_insta_update()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	if memory.game_lost then return end

	local silos = destination.dynamic_data.rocketsilos
	
	if silos and silos[1] and silos[1].valid then
		if destination.dynamic_data.silocharged then
			for i, silo in ipairs(silos) do
				silo.energy = silo.electric_buffer_size
			end
		else
			for i, silo in ipairs(silos) do
				local e = silo.energy - 1
				local e2 = destination.dynamic_data.rocketsiloenergyneeded - destination.dynamic_data.rocketsiloenergyconsumed
				if e > 0 and e2 > 0 then
					local absorb = Math.min(e, e2)
					destination.dynamic_data.energychargedinsilosincelastcheck = destination.dynamic_data.energychargedinsilosincelastcheck + absorb
					silo.energy = silo.energy - absorb
		
					if destination.dynamic_data.rocketsilochargedbools and (not destination.dynamic_data.rocketsilochargedbools[i]) then
						destination.dynamic_data.rocketsilochargedbools[i] = true
						local inv = silo.get_inventory(defines.inventory.assembling_machine_input)
						inv.insert{name = 'rocket-control-unit', count = 10}
						inv.insert{name = 'low-density-structure', count = 10}
						inv.insert{name = 'rocket-fuel', count = 10}
					end
				else
					silo.energy = 0
				end
			end
		end
	end
end

-- function Public.parrot_tick(tickinterval)
-- 	Parrot.parrot_tick()
-- end


function Public.update_recentcrewmember_list(tickinterval)
	local memory = Memory.get_crew_memory()

	-- don't update this unless someone specifically becomes spectator or is planked:
	-- for i = 1, #memory.crewplayerindices do
	-- 	local s = memory.crewplayerindices[i]
	-- 	if s then
	-- 		memory.tempbanned_from_joining_data[s] = game.tick
	-- 	end
	-- end

	-- for k, v in pairs(memory.tempbanned_from_joining_data or {}) do
	-- 	if v <= game.tick - Common.ban_from_rejoining_crew_ticks then
	-- 		memory.tempbanned_from_joining_data[k] = nil
	-- 	end
	-- end
end


-- function Public.globaltick_handle_delayed_tasks(tickinterval)
-- 	local global_memory = Memory.get_global_memory()
	
-- 	for _, task in pairs(global_memory.global_buffered_tasks) do
		
-- 		if task == Delay.global_enum.PLACE_LOBBY_JETTY_AND_BOATS then
-- 			Surfaces.Lobby.place_lobby_jetty_and_boats()

-- 		elseif task == Delay.global_enum.ADMIN_GO2 then
-- 			Delay.global_add(Delay.global_enum.ADMIN_GO3)

-- 		elseif task == Delay.global_enum.ADMIN_GO3 then
-- 			Memory.set_working_id(1)
-- 			local memory = Memory.get_crew_memory()
-- 			Overworld.ensure_generated_up_to_x(Crowsnest.Data.visibilitywidth/2)
-- 			memory.currentdestination_index = 1
-- 			Surfaces.create_surface(Common.current_destination())
-- 			Delay.global_add(Delay.global_enum.ADMIN_GO4)

-- 		elseif task == Delay.global_enum.ADMIN_GO4 then
-- 			Memory.set_working_id(1)
-- 			local memory = Memory.get_crew_memory()
			
-- 			Progression.go_from_starting_dock_to_first_destination()
-- 			memory.mapbeingloadeddestination_index = 1
-- 			memory.loadingticks = 0
			
-- 		end
-- 	end
-- 	Delay.global_clear_buffer()
-- 	Delay.global_move_tasks_to_buffer()
-- end



function Public.update_player_guis(tickinterval)
	local global_memory = Memory.get_global_memory()
    local players = game.connected_players

	for _, player in pairs(players) do
		-- figure out which crew this is about:
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)

		Gui.update_gui(player)
	end
end

function Public.update_players_second()
	local global_memory = Memory.get_global_memory()
    local connected_players = game.connected_players

	local playerindex_to_time_played_continuously = {}
	local playerindex_to_priority = {}
	for playerindex, time in pairs(global_memory.playerindex_to_time_played_continuously) do
		local player = game.players[playerindex]

		if player and Common.validate_player(player) then
			-- port over
			playerindex_to_time_played_continuously[playerindex] = time
		end
	end
	for playerindex, time in pairs(global_memory.playerindex_to_priority) do
		local player = game.players[playerindex]

		if player and Common.validate_player(player) then
			-- port over
			playerindex_to_priority[playerindex] = time
		end
	end

	for _, player in pairs(connected_players) do
		if player.afk_time < Common.afk_time then
			playerindex_to_time_played_continuously[player.index] = playerindex_to_time_played_continuously[player.index] or 0

			playerindex_to_time_played_continuously[player.index] = playerindex_to_time_played_continuously[player.index] + 1

			playerindex_to_priority[player.index] = playerindex_to_priority[player.index] or 0

			playerindex_to_priority[player.index] = playerindex_to_priority[player.index] + 1
		else
			playerindex_to_time_played_continuously[player.index] = nil
			playerindex_to_priority[player.index] = nil
		end
	end
	global_memory.playerindex_to_priority = playerindex_to_priority
	global_memory.playerindex_to_time_played_continuously = playerindex_to_time_played_continuously

	local afk_player_indices = {}
	for _, player in pairs(connected_players) do
		if player.afk_time >= Common.afk_time then
            afk_player_indices[#afk_player_indices + 1] = player.index
		end
	end

	global_memory.afk_player_indices = afk_player_indices

	-- after updating tables:

	for _, index in pairs(afk_player_indices) do
		local player = game.players[index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
			Memory.set_working_id(crew_id)
			Roles.afk_player_tick(player)
	end
end



return Public