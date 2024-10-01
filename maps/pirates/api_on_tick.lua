-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

--luacheck: ignore
--luacheck ignores because tick_interval arguments are a code templating choice...

local Memory = require('maps.pirates.memory')
local Gui = require('maps.pirates.gui.gui')
local Ai = require('maps.pirates.ai')
local Structures = require('maps.pirates.structures.structures')
local Boats = require('maps.pirates.structures.boats.boats')
local Islands = require('maps.pirates.surfaces.islands.islands')
local IslandEnum = require('maps.pirates.surfaces.islands.island_enum')
local Surfaces = require('maps.pirates.surfaces.surfaces')
local PiratesApiEvents = require('maps.pirates.api_events')
local Roles = require('maps.pirates.roles.roles')
local Progression = require('maps.pirates.progression')
local Crowsnest = require('maps.pirates.surfaces.crowsnest')
local Hold = require('maps.pirates.surfaces.hold')
local Cabin = require('maps.pirates.surfaces.cabin')
local Balance = require('maps.pirates.balance')
local Common = require('maps.pirates.common')
local CoreData = require('maps.pirates.coredata')
local Overworld = require('maps.pirates.overworld')
local Utils = require('maps.pirates.utils_local')
local Crew = require('maps.pirates.crew')
-- local Parrot = require 'maps.pirates.parrot'
local Math = require('maps.pirates.math')
local _inspect = require('utils.inspect').inspect
local Kraken = require('maps.pirates.surfaces.sea.kraken')

local Quest = require('maps.pirates.quest')
-- local ShopDock = require 'maps.pirates.shop.dock'
local QuestStructures = require('maps.pirates.structures.quest_structures.quest_structures')

local Public = {}

function Public.strobe_player_colors(tick_interval)
	local memory = Memory.get_crew_memory()

	local strobing_players = memory.speed_boost_characters

	if strobing_players and #strobing_players > 0 then
		local col = Utils.rgb_from_hsv((game.tick * 6) % 360, 0.7, 0.9)
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

function Public.prevent_unbarreling_off_ship(tick_interval)
	if Common.allow_barreling_off_ship then
		return
	end
	if Common.activecrewcount() == 0 then
		return
	end

	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local boat = memory.boat
	local surface_name = boat.surface_name
	if not (surface_name and game.surfaces[surface_name] and game.surfaces[surface_name].valid) then
		return
	end
	local surface = game.surfaces[surface_name]

	local assemblers = surface.find_entities_filtered({ type = 'assembling-machine', force = memory.force_name })

	for _, a in pairs(assemblers) do
		if a and a.valid then
			local r = a.get_recipe()
			if
				r
				and r.subgroup
				and r.subgroup.name
				and r.subgroup.name == 'fill-barrel'
				and not (r.name and r.name == 'fill-water-barrel')
			then
				if not Boats.on_boat(boat, a.position) then
					Common.notify_force_error(memory.force, { 'pirates.error_cant_carry_barrels' })
					a.set_recipe('fill-water-barrel')
				end
			end
		end
	end
end

function Public.apply_restrictions_to_machines(tick_interval)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if memory.game_lost then
		return
	end
	if memory.crewstatus == Crew.enum.LEAVING_INITIAL_DOCK then
		return
	end

	local should_update = false

	if boat.state == Boats.enum_state.ATSEA_VICTORIOUS or boat.state == Boats.enum_state.ATSEA_WAITING_TO_SAIL then
		if boat.state == Boats.enum_state.ATSEA_VICTORIOUS then
			if memory.crafters_disabled then
				if Common.activecrewcount() > 0 then
					should_update = true
				end
			else
				memory.crafters_disabled = true
				should_update = true
				Boats.update_EEIs(boat)
			end
		else
			if memory.crafters_disabled then
				if Common.activecrewcount() > 0 then
					should_update = true
				end
			else
				if
					game.tick
					> memory.at_sea_waiting_game_tick + Balance.seconds_until_machines_shut_down_at_sea() * 60
				then
					memory.crafters_disabled = true
					should_update = true
					Boats.update_EEIs(boat)
					Common.parrot_speak(memory.force, { 'pirates.parrot_crafters_disabled' })
				end
			end
		end
	else
		if memory.crafters_disabled then
			memory.crafters_disabled = false
			should_update = true
			Boats.update_EEIs(boat)
		end
	end

	if not should_update then
		return
	end

	local surfaces_to_check = {}

	if boat.surface_name and game.surfaces[boat.surface_name] and game.surfaces[boat.surface_name].valid then
		table.insert(surfaces_to_check, game.surfaces[boat.surface_name])
	end

	for i = 1, memory.hold_surface_count do
		local hold_surface = Hold.get_hold_surface(i)
		if hold_surface and hold_surface.valid then
			table.insert(surfaces_to_check, hold_surface)
		end
	end

	local destination = Common.current_destination()
	if
		destination.dynamic_data
		and destination.dynamic_data.cave_miner
		and destination.dynamic_data.cave_miner.cave_surface
	then
		local cave_surface = destination.dynamic_data.cave_miner.cave_surface
		if cave_surface and cave_surface.valid then
			table.insert(surfaces_to_check, cave_surface)
		end
	end

	for _, surface in ipairs(surfaces_to_check) do
		local crafters = surface.find_entities_filtered({
			type = { 'assembling-machine', 'furnace', 'lab' },
			force = memory.force_name,
		})
		-- local drills = surface.find_entities_filtered {
		-- 	type = { 'mining-drill' },
		-- 	force = memory.force_name
		-- }
		local power_machines = surface.find_entities_filtered({
			type = { 'generator', 'solar-panel', 'boiler', 'reactor' },
			force = memory.force_name,
		})

		for _, machine in ipairs(crafters) do
			if machine and machine.valid then
				machine.active = not memory.crafters_disabled
			end
		end
		for _, machine in ipairs(power_machines) do
			if machine and machine.valid then
				machine.active = not memory.crafters_disabled
			end
		end
	end
end

function Public.prevent_disembark(tick_interval)
	local memory = Memory.get_crew_memory()

	if Common.activecrewcount() == 0 then
		return
	end

	local destination = Common.current_destination()
	local boat = memory.boat

	if
		boat
		and (
			boat.state == Boats.enum_state.RETREATING
			or (boat.state == Boats.enum_state.LEAVING_DOCK and memory.crewstatus ~= Crew.enum.LEAVING_INITIAL_DOCK)
		)
	then
		if not destination.dynamic_data.cant_disembark_players then
			destination.dynamic_data.cant_disembark_players = {}
		end
		local cant_disembark_players = destination.dynamic_data.cant_disembark_players

		for _, player in pairs(game.connected_players) do
			if
				player.surface
				and player.surface.valid
				and player.surface.name == boat.surface_name
				and Common.validate_player_and_character(player)
				and Boats.on_boat(boat, player.character.position)
			then
				cant_disembark_players[player.index] = true
			end
		end

		for _, player in pairs(game.connected_players) do
			if
				player.surface
				and player.surface.valid
				and player.surface.name == boat.surface_name
				and Common.validate_player_and_character(player)
				and cant_disembark_players[player.index]
				and (not Boats.on_boat(boat, player.character.position))
			then
				Common.notify_player_error(player, { 'pirates.error_disembark' })

				if player.driving then
					local vehicle = player.vehicle
					if vehicle then
						local passenger = vehicle.get_passenger()
						if passenger then
							vehicle.set_passenger(nil)
							local p =
								passenger.surface.find_non_colliding_position('character', memory.spawnpoint, 5, 0.1)
							if p then
								passenger.teleport(p)
							else
								passenger.teleport(memory.spawnpoint)
							end
						end

						vehicle.set_driver(nil)
					end
				end

				local p = player.surface.find_non_colliding_position('character', memory.spawnpoint, 5, 0.1)
				if p then
					player.character.teleport(p)
				else
					player.character.teleport(memory.spawnpoint)
				end
			end
		end
	end
end

function Public.check_all_spawners_dead(tick_interval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local boat = memory.boat

	if
		destination.static_params
		and destination.static_params.base_cost_to_undock
		and not (destination.subtype == IslandEnum.enum.RED_DESERT or destination.subtype == IslandEnum.enum.CAVE)
	then
		if boat and boat.surface_name and boat.surface_name == destination.surface_name then
			local surface = game.surfaces[destination.surface_name]
			if not (surface and surface.valid) then
				return
			end

			local spawners_count = Common.spawner_count(surface)
			if spawners_count == 0 then
				destination.static_params.base_cost_to_undock = nil
				Common.notify_force(memory.force, { 'pirates.destroyed_all_nests' })
			end
		end
	end
end

function Public.raft_raids(tick_interval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then
		return
	end
	local destination = Common.current_destination()
	if not destination then
		return
	end
	if
		not destination.static_params
		or not destination.static_params.scheduled_raft_raids
		or not destination.dynamic_data.timer
	then
		return
	end
	local scheduled_raft_raids = destination.static_params.scheduled_raft_raids
	local timer = destination.dynamic_data.timer

	for k, raid in pairs(scheduled_raft_raids) do
		if timer >= raid.timeinseconds and not scheduled_raft_raids[k].fired then
			local type
			if memory.overworldx >= 40 * 16 then
				type = Boats.enum.RAFTLARGE
			else
				type = Boats.enum.RAFT
			end
			local boat = Islands.spawn_enemy_boat(type)
			if boat then
				Ai.spawn_boat_biters(
					boat,
					raid.max_evo,
					Boats.get_scope(boat).Data.capacity,
					Boats.get_scope(boat).Data.width
				)
			end
			scheduled_raft_raids[k].fired = true
		end
	end
end

function Public.ship_deplete_fuel(tick_interval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then
		return
	end
	if not (memory.stored_fuel and memory.boat.input_chests and memory.boat.input_chests[1]) then
		return
	end

	local rate = Progression.get_fuel_depletion_rate_once_per_second()

	memory.fuel_depletion_rate_memoized = rate

	local boat = memory.boat

	local input_chests = boat.input_chests
	local inv = input_chests[1].get_inventory(defines.inventory.chest)

	local contents = inv.get_contents()
	local count = 0
	for _, item in ipairs(contents) do
		if item.name == 'coal' then
			count = count + item.count
		end
	end

	if count > 0 then
		inv.remove({ name = 'coal', count = count })
	end

	memory.stored_fuel = memory.stored_fuel + count + rate * tick_interval / 60

	if
		rate < 0
		and memory.stored_fuel < 1000
		and not (
			memory.parrot_fuel_most_recent_warning
			and memory.parrot_fuel_most_recent_warning >= game.tick - 60 * 60 * 12
		)
	then --12 minutes
		memory.parrot_fuel_most_recent_warning = game.tick
		Common.parrot_speak(memory.force, { 'pirates.parrot_fuel_warning' })
	end

	if memory.stored_fuel < 0 then
		Crew.try_lose({ 'pirates.loss_out_of_fuel' })
	end
end

function Public.victory_continue_reminder()
	local memory = Memory.get_crew_memory()

	if memory.victory_continue_reminder and game.tick >= memory.victory_continue_reminder then
		memory.victory_continue_reminder = nil
		if memory.boat.state == Boats.enum_state.ATSEA_VICTORIOUS then
			Common.notify_force(memory.force, { 'pirates.victory_continue_reminder' }, CoreData.colors.notify_victory)
		end
	end
end

function Public.transfer_pollution(tick_interval)
	local memory = Memory.get_crew_memory()

	local p = 0
	for i = 1, memory.hold_surface_count do
		local surface = Hold.get_hold_surface(i)
		if not surface then
			return
		end
		p = p + surface.get_total_pollution()
		surface.clear_pollution()
	end

	if not (p and memory.floating_pollution) then
		return
	end

	memory.floating_pollution = memory.floating_pollution + p
end

function Public.shop_ratelimit_tick(tick_interval)
	-- if memory.mainshop_rate_limit_ticker and memory.mainshop_rate_limit_ticker > 0 then
	-- 	memory.mainshop_rate_limit_ticker = memory.mainshop_rate_limit_ticker - tick_interval
	-- end
end

function Public.captain_warn_afk(tick_interval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then
		return
	end
	if memory.run_is_protected then
		return
	end

	if memory.playerindex_captain then
		for _, player in pairs(game.connected_players) do
			if
				Common.is_captain(player)
				and #Common.crew_get_nonafk_crew_members() > 1
				and player.afk_time >= Common.afk_time - 20 * 60 - 60 - tick_interval
				and player.afk_time < Common.afk_time - 20 * 60
			then
				Common.notify_player_announce(player, { 'pirates.warn_nearly_afk_captain' })
				player.play_sound({ path = 'utility/scenario_message' })
			end
		end
	end
end

function Public.prune_offline_characters_list(tick_interval)
	local memory = Memory.get_crew_memory()

	if memory.game_lost then
		return
	end

	local players_to_remove = {}

	for player_index, data in pairs(memory.temporarily_logged_off_player_data) do
		if game.players[player_index] and game.players[player_index].connected then
			if memory.temporarily_logged_off_characters_items[player_index] then
				pcall(function()
					memory.temporarily_logged_off_characters_items[player_index].destroy()
				end)
			end
			memory.temporarily_logged_off_characters_items[player_index] = nil
			players_to_remove[player_index] = true
		else
			local tick = data.tick
			if tick < game.tick - 60 * 60 * Common.temporarily_logged_off_player_data_preservation_minutes then
				local any = false
				local temp_inv = memory.temporarily_logged_off_characters_items[player_index]
				if temp_inv then
					for i = 1, #temp_inv do
						if temp_inv[i] and temp_inv[i].valid and temp_inv[i].valid_for_read then
							Common.give_items_to_crew(temp_inv[i])
							any = true
						end
					end

					if any then
						Common.notify_force_light(memory.force, { 'pirates.recover_offline_player_items' })
					end

					pcall(function()
						temp_inv.destroy()
					end)
				end

				players_to_remove[player_index] = true
			end
		end
	end

	for player_index in pairs(players_to_remove) do
		memory.temporarily_logged_off_player_data[player_index] = nil
		memory.temporarily_logged_off_characters_items[player_index] = nil
	end
end

function Public.periodic_free_resources(tick_interval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then
		return
	end
	local destination = Common.current_destination()
	local boat = memory.boat
	if
		not (
			destination
			and destination.type == Surfaces.enum.ISLAND
			and boat
			and boat.surface_name == destination.surface_name
		)
	then
		return
	end

	-- Common.give_items_to_crew(Balance.periodic_free_resources_per_destination_5_seconds())

	if game.tick % (300 * 30) == 0 and (destination and destination.subtype == IslandEnum.enum.RADIOACTIVE) then -- every 150 seconds
		local count = 2
		Common.give_items_to_crew({ { name = 'sulfuric-acid-barrel', count = count } })
		local force = memory.force
		if not (force and force.valid) then
			return
		end
		local message =
			{ 'pirates.granted_1', { 'pirates.granted_periodic_resource' }, count .. ' [item=sulfuric-acid-barrel]' }
		Common.notify_force_light(force, message)
	end
end

function Public.pick_up_tick(tick_interval)
	if Common.activecrewcount() == 0 then
		return
	end

	local destination = Common.current_destination()
	if not destination then
		return
	end
	local dynamic_data = destination.dynamic_data
	local surface_name = destination.surface_name
	if not (surface_name and dynamic_data) then
		return
	end
	local surface = game.surfaces[surface_name]
	if not (surface and surface.valid) then
		return
	end

	local maps = dynamic_data.treasure_maps or {}
	local buried_treasure = dynamic_data.buried_treasure or {}
	local ghosts = dynamic_data.ghosts or {}

	for i = 1, #maps do
		local map = maps[i]

		if map.state == 'on_ground' then
			local p = map.position

			local nearby_characters = surface.find_entities_filtered({ position = p, radius = 3, name = 'character' })
			local nearby_characters_count = #nearby_characters
			if nearby_characters_count > 0 then
				local player
				local j = 1
				while j <= nearby_characters_count do
					if
						nearby_characters[j]
						and nearby_characters[j].valid
						and nearby_characters[j].player
						and Common.validate_player(nearby_characters[j].player)
					then
						player = nearby_characters[j].player
						break
					end
					j = j + 1
				end
				if player then
					local buried_treasure_candidates = {}
					for _, t in pairs(buried_treasure) do
						if not t.associated_to_map then
							buried_treasure_candidates[#buried_treasure_candidates + 1] = t
						end
					end
					if #buried_treasure_candidates == 0 then
						break
					end
					local chosen = buried_treasure_candidates[Math.random(#buried_treasure_candidates)]

					chosen.associated_to_map = true
					local p2 = chosen.position
					map.buried_treasure_position = p2

					map.state = 'picked_up'
					map.mapobject_rendering.destroy()

					Common.notify_force_light(player.force, { 'pirates.find_map', player.name })

					map.x_renderings = {
						rendering.draw_line({
							width = 8,
							surface = surface,
							from = { p2.x + 3, p2.y + 3 },
							to = { p2.x - 3, p2.y - 3 },
							color = { 1, 0, 0 },
							gap_length = 0.2,
							dash_length = 1,
							draw_on_ground = true,
							-- players = {player},
						}),
						rendering.draw_line({
							width = 8,
							surface = surface,
							from = { p2.x - 3, p2.y + 3 },
							to = { p2.x + 3, p2.y - 3 },
							color = { 1, 0, 0 },
							gap_length = 0.2,
							dash_length = 1,
							draw_on_ground = true,
							-- players = {player},
						}),
					}
				end
			end
		end
	end

	if not (dynamic_data.quest_type and not dynamic_data.quest_complete) then
		return
	end

	for i = 1, #ghosts do
		local ghost = ghosts[i]

		if ghost.state == 'on_ground' then
			local p = ghost.position

			local nearby_characters = surface.find_entities_filtered({ position = p, radius = 3, name = 'character' })
			local nearby_characters_count = #nearby_characters
			if nearby_characters_count > 0 then
				local player
				local j = 1
				while j <= nearby_characters_count do
					if
						nearby_characters[j]
						and nearby_characters[j].valid
						and nearby_characters[j].player
						and Common.validate_player(nearby_characters[j].player)
					then
						player = nearby_characters[j].player
						break
					end
					j = j + 1
				end
				if player then
					ghost.ghostobject_rendering.destroy()

					ghost.state = 'picked_up'

					Common.notify_force(player.force, { 'pirates.find_ghost', player.name })

					dynamic_data.quest_progress = dynamic_data.quest_progress + 1
					Quest.try_resolve_quest()
				end
			end
		end
	end
end

function Public.interpret_shorthanded_force_name(shorthanded_name)
	local memory = Memory.get_crew_memory()

	local ret
	if shorthanded_name == 'ancient-friendly' then
		ret = memory.ancient_friendly_force_name
	elseif shorthanded_name == 'ancient-hostile' then
		ret = memory.ancient_enemy_force_name
	elseif shorthanded_name == 'crew' then
		ret = memory.force_name
	elseif shorthanded_name == 'enemy' then
		ret = memory.enemy_force_name
	else
		ret = shorthanded_name
	end
	return ret
end

function Public.place_cached_structures(tick_interval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface_name = destination.surface_name

	if
		not destination.dynamic_data
		or not destination.dynamic_data.structures_waiting_to_be_placed
		or not surface_name
		or not game.surfaces[surface_name]
		or not game.surfaces[surface_name].valid
	then
		return
	end

	if not (memory.boat and memory.boat.surface_name and memory.boat.surface_name == surface_name) then
		return --We only want to generate structures once the players arrive on the island. Otherwise, the following issue happens. 2x2 structures force-generate nearby chunks. But if the island has many structures, that could cause a domino effect of chunk-generation, lagging the game.
		-- Since this change, this function has little conceptual reason to be an on_tick function, but it makes sense to run it a few ticks after you teleport to the island, so it can stay one for now.
	end

	local surface = game.surfaces[surface_name]

	local structures = destination.dynamic_data.structures_waiting_to_be_placed

	for i = #structures, 1, -1 do
		local structure = structures[i]

		if game.tick > structure.tick + 5 then
			local special = structure.data
			local position = special.position

			-- game.print(special.name)

			-- Since this structure has cliffs, the positions need to be snapped and floored to nearest set of elements for x and y accordingly:
			-- x: {..., -4, 0, 4, 8, ...}
			-- y: {..., -4, 0, 4, 8, ...}
			-- This is assuming that "cliff.position + offset" already has snapped positions as such:
			-- x: {..., -2, 2, 6, ...}
			-- y: {..., -1.5, 2.5, 6.5, ...}
			-- The position would be corrected in "try_place" function, but it gets adjusted later with "terraingen_coordinates_offset", so have to do it here
			if special.name == 'small_cliff_base' then
				position.x = position.x - position.x % 4
				position.y = position.y - position.y % 4

				-- add a small bias to avoid situations such as 7.999999999993
				position.x = position.x + 0.01
				position.y = position.y + 0.01
			end

			Common.ensure_chunks_at(surface, position, Common.structure_ensure_chunk_radius)

			if not special.doNotDestroyExistingEntities then
				Common.delete_entities(surface, position, special.width, special.height)
			end
			Common.replace_unwalkable_tiles(surface, position, special.width, special.height)

			local saved_components = {}
			for k = 1, #special.components do
				local c = special.components[k]

				local force_name
				if c.force then
					force_name = Public.interpret_shorthanded_force_name(c.force)
				end

				if c.type == 'tiles' then
					local tiles = {}
					for _, p in pairs(Common.tile_positions_from_blueprint(c.bp_string, c.offset)) do
						tiles[#tiles + 1] = { name = c.tile_name, position = Utils.psum({ position, p }) }
					end
					if #tiles > 0 then
						surface.set_tiles(tiles, true)
					end
				elseif c.type == 'water_tiles' then
					local tiles = {}
					for _, p in pairs(c.positions) do
						tiles[#tiles + 1] = { name = c.tile_name, position = Utils.psum({ position, p, c.offset }) }
					end
					if #tiles > 0 then
						surface.set_tiles(tiles, true)
					end
				elseif c.type == 'cliffs' then
					--local c2 = {type = c.type, force_name = force_name, built_entities = {}}

					for _, e in pairs(c.instances) do
						local p = Utils.psum({ position, e.position, c.offset })
						local e2 = surface.create_entity({
							name = c.name,
							position = p,
							cliff_orientation = e.cliff_orientation,
						})
						-- c2.built_entities[#c2.built_entities + 1] = e2
					end

					--saved_components[#saved_components + 1] = c2
				elseif c.type == 'entities' or c.type == 'entities_minable' then
					local c2 = { type = c.type, force_name = force_name, built_entities = {} }

					for _, e in pairs(c.instances) do
						local p = Utils.psum({ position, e.position, c.offset })
						if c.type == 'entities_minable' then
							surface.create_entity({
								name = Balance.pick_random_drilling_ore(),
								position = p,
								direction = e.direction,
								force = force_name,
								amount = Balance.pick_drilling_ore_amount(),
							})
						elseif c.name == 'pumpjack' then
							surface.create_entity({
								name = 'crude-oil',
								position = p,
								amount = Balance.pick_default_oil_amount(),
							})
						end
						local e2 = surface.create_entity({
							name = c.name,
							position = p,
							direction = e.direction,
							force = force_name,
							amount = c.amount,
						})
						c2.built_entities[#c2.built_entities + 1] = e2
					end

					saved_components[#saved_components + 1] = c2
				elseif c.type == 'vehicles' then
					local c2 = { type = c.type, force_name = force_name, built_entities = {} }

					if memory.overworldx >= 1000 then
						c.name = 'tank'
					end

					for _, e in pairs(c.instances) do
						local p = Utils.psum({ position, e.position, c.offset })
						local e2 = surface.create_entity({ name = c.name, position = p, direction = e.direction })
						c2.built_entities[#c2.built_entities + 1] = e2
					end

					saved_components[#saved_components + 1] = c2
				elseif c.type == 'entities_grid' then
					local c2 = { type = c.type, force_name = force_name, built_entities = {} }

					for x = Math.ceil(-c.width / 2), Math.ceil(c.width / 2), 1 do
						for y = Math.ceil(-c.height / 2), Math.ceil(c.height / 2), 1 do
							local p = Utils.psum({ position, { x = x, y = y }, c.offset })
							local e2 = surface.create_entity({
								name = c.name,
								position = p,
								direction = c.direction,
								force = force_name,
							})
							c2.built_entities[#c2.built_entities + 1] = e2
						end
					end

					saved_components[#saved_components + 1] = c2
				elseif c.type == 'entities_randomlyplaced' then
					local c2 = { type = c.type, force_name = force_name, built_entities = {} }
					local occupied_positions = {}

					for _ = 1, c.count do
						local whilesafety = 0
						local done = false
						while whilesafety < 100 and not done do
							local rng_x = Math.random(-c.r, c.r)
							local rng_y = Math.random(-c.r, c.r)
							local p = Utils.psum({ position, c.offset, { x = rng_x, y = rng_y } })
							local key = p.x .. ',' .. p.y
							if not occupied_positions[key] then
								local name = c.name
								if name == 'random-worm' then
									name = Common.get_random_worm_type(memory.evolution_factor)
								end
								local e = { name = name, position = p, force = force_name }
								if surface.can_place_entity(e) then
									local e2 = surface.create_entity(e)
									c2.built_entities[#c2.built_entities + 1] = e2
									occupied_positions[key] = true
									done = true
								end
							end
							whilesafety = whilesafety + 1
						end
					end

					saved_components[#saved_components + 1] = c2
				elseif c.type == 'entities_randomlyplaced_border' then
					local c2 = { type = c.type, force_name = force_name, built_entities = {} }
					local occupied_positions = {}

					for _ = 1, c.count do
						local whilesafety = 0
						local done = false
						while whilesafety < 100 and not done do
							local rng_1 = Math.random(c.small_r, c.large_r)
							local rng_2 = Math.random(-c.large_r, c.large_r)
							local p
							if Math.random(2) == 1 then
								if Math.random(2) == 1 then
									p = { x = rng_1, y = rng_2 }
								else
									p = { x = -rng_1, y = rng_2 }
								end
							else
								if Math.random(2) == 1 then
									p = { x = rng_2, y = rng_1 }
								else
									p = { x = rng_2, y = -rng_1 }
								end
							end
							local p2 = Utils.psum({ position, c.offset, p })
							local key = p2.x .. ',' .. p2.y
							if not occupied_positions[key] then
								local e = { name = c.name, position = p2, force = force_name }
								if surface.can_place_entity(e) then
									local e2 = surface.create_entity(e)
									c2.built_entities[#c2.built_entities + 1] = e2
									occupied_positions[key] = true
									done = true
								end
							end
							whilesafety = whilesafety + 1
						end
					end

					saved_components[#saved_components + 1] = c2
				elseif c.bp_string then
					local c2 = { type = c.type, force_name = force_name, built_entities = {} }

					local es = Common.build_from_blueprint(
						c.bp_string,
						surface,
						Utils.psum({ position, c.offset }),
						game.forces[force_name]
					)

					for l = 1, #es do
						c2.built_entities[#c2.built_entities + 1] = es[l]
					end

					saved_components[#saved_components + 1] = c2
				end
			end

			Structures.configure_structure_entities(special.name, saved_components)

			QuestStructures.create_quest_structure_entities(special.name)

			for j = i, #structures - 1 do
				structures[j] = structures[j + 1]
			end
			structures[#structures] = nil
		end
	end
end

function Public.update_boat_stored_resources(tick_interval)
	if Common.activecrewcount() == 0 then
		return
	end

	Common.update_boat_stored_resources()
end

function Public.buried_treasure_check(tick_interval)
	if Common.activecrewcount() == 0 then
		return
	end

	-- local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local remaining = destination.dynamic_data.treasure_remaining

	if
		not (
			remaining
			and remaining > 0
			and destination.surface_name
			and destination.dynamic_data.buried_treasure
			and #destination.dynamic_data.buried_treasure > 0
		)
	then
		return
	end

	local surface = game.surfaces[destination.surface_name]
	local treasure_table = destination.dynamic_data.buried_treasure

	for i = 1, #treasure_table do
		local treasure = treasure_table[i]
		if not treasure then
			break
		end

		local t = treasure.treasure

		if t then
			local p = treasure.position
			local free = surface.can_place_entity({ name = 'wooden-chest', position = p })

			if free then
				local inserters = {
					surface.find_entities_filtered({
						type = 'inserter',
						position = { x = p.x - 1, y = p.y },
						radius = 0.1,
						direction = defines.direction.east,
					}),
					surface.find_entities_filtered({
						type = 'inserter',
						position = { x = p.x + 1, y = p.y },
						radius = 0.1,
						direction = defines.direction.west,
					}),
					surface.find_entities_filtered({
						type = 'inserter',
						position = { x = p.x, y = p.y - 1 },
						radius = 0.1,
						direction = defines.direction.south,
					}),
					surface.find_entities_filtered({
						type = 'inserter',
						position = { x = p.x, y = p.y + 1 },
						radius = 0.1,
						direction = defines.direction.north,
					}),
				}

				for j = 1, 4 do
					if inserters[j] and inserters[j][1] then
						local ins = inserters[j][1]

						if
							destination.dynamic_data.treasure_remaining > 0
							and ins.held_stack.count == 0
							and ins.status == defines.entity_status.waiting_for_source_items
						then
							surface.create_entity({
								name = 'item-on-ground',
								position = p,
								stack = { name = t.name, count = 1 },
							})
							t.count = t.count - 1
							destination.dynamic_data.treasure_remaining = destination.dynamic_data.treasure_remaining
								- 1

							if destination.dynamic_data.treasure_remaining == 0 then
								-- destroy all
								local buried_treasure = destination.dynamic_data.buried_treasure
								for _, t2 in pairs(buried_treasure) do
									t2 = nil
								end
								local maps = destination.dynamic_data.treasure_maps
								for _, m in pairs(maps) do
									if m.state == 'on_ground' then
										m.mapobject_rendering.destroy()
									elseif m.state == 'picked_up' and m.x_renderings and #m.x_renderings > 0 then
										m.x_renderings[1].destroy()
										m.x_renderings[2].destroy()
									end
									m = nil
								end
							elseif t.count <= 0 then
								treasure.treasure = nil

								local maps = destination.dynamic_data.treasure_maps
								for _, m in pairs(maps) do
									if
										m.state == 'picked_up'
										and m.buried_treasure_position
										and m.buried_treasure_position == p
										and m.x_renderings
										and #m.x_renderings > 0
									then
										m.state = 'inactive'
										m.x_renderings[1].destroy()
										m.x_renderings[2].destroy()
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

function Public.boat_movement_tick(tick_interval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local enemy_force_name = memory.enemy_force_name

	local boat = memory.boat
	if
		boat
		and boat.surface_name
		and game.surfaces[boat.surface_name]
		and game.surfaces[boat.surface_name].valid
		and boat.speed
		and boat.speed > 0
		and memory.game_lost == false
	then
		local ticker_increase = boat.speed / 60 * tick_interval
		boat.speedticker1 = boat.speedticker1 + ticker_increase
		boat.speedticker2 = boat.speedticker2 + ticker_increase
		boat.speedticker3 = boat.speedticker3 + ticker_increase

		if boat.speedticker1 >= Common.boat_steps_at_a_time then
			boat.speedticker1 = 0
			if not Progression.check_for_end_of_boat_movement(boat) then
				Structures.Boats.currentdestination_move_boat_natural()
			end
		elseif boat.speedticker2 >= Common.boat_steps_at_a_time then
			if
				destination.type == Surfaces.enum.ISLAND
				and destination.subtype ~= IslandEnum.enum.CAVE
				and boat
				and boat.state == Boats.enum_state.APPROACHING
			then
				Structures.Boats.currentdestination_try_move_boat_steered()
			end
			boat.speedticker2 = 0
		end
	end

	if destination.dynamic_data.enemyboats then
		for i = 1, #destination.dynamic_data.enemyboats do
			local eboat = destination.dynamic_data.enemyboats[i]
			if
				eboat
				and eboat.surface_name
				and game.surfaces[eboat.surface_name]
				and game.surfaces[eboat.surface_name].valid
			then
				if
					eboat.state == Boats.enum_state.APPROACHING
					and eboat.speed
					and eboat.speed > 0
					and memory.game_lost == false
				then
					local ticker_increase = eboat.speed / 60 * tick_interval
					eboat.speedticker1 = eboat.speedticker1 + ticker_increase
					if eboat.speedticker1 >= 1 then
						eboat.speedticker1 = 0
						if not Progression.check_for_end_of_boat_movement(eboat) then
							-- if boat.unit_group and boat.unit_group.ref and boat.unit_group.ref.valid then boat.unit_group.ref.set_command({
							-- 	type = defines.command.attack_area,
							-- 	destination = ({boat.position.x - 32, boat.position.y} or {0,0}),
							-- 	radius = 32,
							-- 	distraction = defines.distraction.by_enemy
							-- }) end

							local p = { x = eboat.position.x + 1, y = eboat.position.y }
							Boats.teleport_boat(eboat, nil, p, CoreData.static_boat_floor)
							if p.x % 7 < 1 then
								Ai.update_landing_party_unit_groups(eboat, 7)
							end
						end
					end
				elseif eboat.state == Boats.enum_state.LANDED then
					do
					end
				end
			else
				Utils.fast_remove(destination.dynamic_data.enemyboats, i)
			end
		end
	end
end

function Public.crowsnest_natural_move(tick_interval)
	local memory = Memory.get_crew_memory()

	if not (memory.boat and memory.boat.state == Structures.Boats.enum_state.ATSEA_SAILING) then
		return
	end
	if memory.loading_ticks then
		return
	end
	if Public.overworld_check_collisions() then
		return
	end

	Overworld.try_overworld_move_v2({ x = 1, y = 0 })
end

function Public.overworld_check_collisions(tick_interval)
	local memory = Memory.get_crew_memory()

	if not memory.loading_ticks then
		Overworld.check_for_kraken_collisions()
		return Overworld.check_for_destination_collisions()
	end
	return false
end

function Public.loading_update(tick_interval)
	local memory = Memory.get_crew_memory()
	if not memory.loading_ticks or memory.game_lost then
		return
	end

	local boat = memory.boat
	if not boat or not boat.state then
		return
	end

	local destination_index = memory.map_being_loaded_destination_index
	if not destination_index then
		memory.loading_ticks = nil
		return
	end

	local currentdestination = Common.current_destination()
	if not currentdestination then
		return
	end

	if currentdestination.type == Surfaces.enum.LOBBY then
		Public.loading_update_lobby(tick_interval, memory, boat, destination_index, currentdestination)
	elseif boat.state == Boats.enum_state.ATSEA_LOADING_MAP then
		Public.loading_update_atsea(tick_interval, memory, boat, destination_index, currentdestination)
	elseif boat.state == Boats.enum_state.LANDED then
		Public.loading_update_landed(tick_interval, memory, boat, destination_index, currentdestination)
	end
end

function Public.loading_update_lobby(tick_interval, memory, boat, destination_index, currentdestination)
	memory.loading_ticks = memory.loading_ticks + tick_interval

	if memory.loading_ticks >= 350 - Common.loading_interval then
		if Boats.players_on_boat_count(boat) > 0 then
			if memory.loading_ticks < 350 then
				Common.notify_game({ '', '[' .. memory.name .. '] ', { 'pirates.loading_new_game' } })
			elseif memory.loading_ticks > 410 then
				if not Crowsnest.get_crowsnest_surface() then
					Crew.initialise_crowsnest_1()
				elseif memory.loading_ticks >= 470 then
					Crew.initialise_crowsnest_2()
					Overworld.ensure_lane_generated_up_to(0, Crowsnest.Data.visibilitywidth)
					Overworld.ensure_lane_generated_up_to(24, Crowsnest.Data.visibilitywidth)
					Overworld.ensure_lane_generated_up_to(-24, Crowsnest.Data.visibilitywidth)

					for i = 1, #memory.destinations do
						if memory.destinations[i].overworld_position.x == 0 then
							memory.map_being_loaded_destination_index = i
							break
						end
					end

					Surfaces.create_surface(memory.destinations[memory.map_being_loaded_destination_index])
				end
			end
		else
			if memory.loading_ticks >= 1100 then
				Boats.destroy_boat(boat)
				Crew.disband_crew()
				return
			end
		end
	end

	if memory.loading_ticks > 500 then
		local d = (Crowsnest.Data.visibilitywidth / 3) * (memory.loading_ticks - 500) / 500
		Overworld.ensure_lane_generated_up_to(0, d + 26)
		Overworld.ensure_lane_generated_up_to(24, d + 13)
		Overworld.ensure_lane_generated_up_to(-24, d)
	end

	if memory.loading_ticks > 860 then
		if Boats.players_on_boat_count(boat) > 0 then
			local fraction = 0.07 + 0.7 * (memory.loading_ticks - 860) / 400
			PiratesApiEvents.load_some_map_chunks(destination_index, fraction)
		else
			Boats.destroy_boat(boat)
			Crew.disband_crew()
			return
		end
	end

	if memory.loading_ticks > 1230 then
		if boat then
			boat.speed = 0
		end
	end

	if memory.loading_ticks >= 1260 then
		if boat and boat.rendering_crewname_text and boat.rendering_crewname_text.valid then
			boat.rendering_crewname_text.destroy()
			boat.rendering_crewname_text = nil
		end

		Progression.go_from_starting_dock_to_first_destination()

		log('starting game for crew ' .. memory.name)
	end
end

function Public.loading_update_atsea(tick_interval, memory, boat, destination_index, currentdestination)
	memory.loading_ticks = memory.loading_ticks + tick_interval

	local total = Common.map_loading_ticks_atsea
	if currentdestination.type == Surfaces.enum.DOCK then
		total = Common.map_loading_ticks_atsea_dock
	elseif currentdestination.type == Surfaces.enum.ISLAND and currentdestination.subtype == IslandEnum.enum.MAZE then
		total = Common.map_loading_ticks_atsea_maze
	end

	local fraction = memory.loading_ticks / (total + (memory.extra_time_at_sea or 0))

	if fraction > Common.fraction_of_map_loaded_at_sea then
		if currentdestination.type == Surfaces.enum.DOCK then
			Progression.progress_to_destination(destination_index)
		else
			boat.state = Boats.enum_state.ATSEA_WAITING_TO_SAIL
			memory.at_sea_waiting_game_tick = game.tick
		end
	else
		local surface = game.surfaces[currentdestination.surface_name]
		if surface and surface.valid then
			PiratesApiEvents.load_some_map_chunks_random_order(surface, currentdestination, fraction)
			if currentdestination.subtype == IslandEnum.enum.CAVE then
				local cave_surface = currentdestination.dynamic_data.cave_miner.cave_surface
				if cave_surface and cave_surface.valid then
					PiratesApiEvents.load_some_map_chunks_random_order(cave_surface, currentdestination, fraction)
				end
			end
		end
	end
end

function Public.loading_update_landed(tick_interval, memory, boat, destination_index, currentdestination)
	memory.loading_ticks = memory.loading_ticks + tick_interval

	local fraction = Common.fraction_of_map_loaded_at_sea
		+ (1 - Common.fraction_of_map_loaded_at_sea) * memory.loading_ticks / Common.map_loading_ticks_onisland

	if fraction > 1 then
		memory.loading_ticks = nil
	else
		PiratesApiEvents.load_some_map_chunks(destination_index, fraction)
	end
end

function Public.crowsnest_steer(tick_interval)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if memory.game_lost then
		return
	end

	if
		not (
			boat
			and boat.state
			and boat.state == Structures.Boats.enum_state.ATSEA_SAILING
			and memory.game_lost == false
			and boat.crows_nest_steering_chests
		)
	then
		return
	end

	local left_chest = boat.crows_nest_steering_chests.left
	local right_chest = boat.crows_nest_steering_chests.right
	if not (left_chest and left_chest.valid and right_chest and right_chest.valid) then
		return
	end

	local inv_left = left_chest.get_inventory(defines.inventory.chest)
	local inv_right = right_chest.get_inventory(defines.inventory.chest)
	local count_left = inv_left.get_item_count('rail-signal')
	local count_right = inv_right.get_item_count('rail-signal')

	if count_left >= 50 and count_right < 50 and memory.overworldy > -24 then
		if Overworld.try_overworld_move_v2({ x = 0, y = -24 }) then
			local force = memory.force
			Common.notify_force(force, { 'pirates.steer_left' })
			inv_left.remove({ name = 'rail-signal', count = 50 })
		end
		return
	elseif count_right >= 50 and count_left < 50 and memory.overworldy < 24 then
		if Overworld.try_overworld_move_v2({ x = 0, y = 24 }) then
			local force = memory.force
			Common.notify_force(force, { 'pirates.steer_right' })
			inv_right.remove({ name = 'rail-signal', count = 50 })
		end
		return
	end
end

function Public.silo_update(tick_interval)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	if not (destination and destination.type == Surfaces.enum.ISLAND) then
		return
	end

	local dynamic_data = destination.dynamic_data
	if not dynamic_data then
		return
	end

	local silos = dynamic_data.rocketsilos
	if not silos then
		return
	end

	local silo = silos[1]
	if not (silo and silo.valid) then
		return
	end

	if dynamic_data.silo_is_charged then
		if not dynamic_data.rocket_launched then
			silo.launch_rocket()
		end
	else
		local p = silo.position

		local e = dynamic_data.energy_charged_in_silo_since_last_check or 0
		dynamic_data.energy_charged_in_silo_since_last_check = 0

		dynamic_data.rocket_silo_energy_consumed = (dynamic_data.rocket_silo_energy_consumed or 0) + e

		dynamic_data.rocket_silo_energy_consumed_within_last_half_second = e

		if memory.enemy_force_name then
			local ef = memory.enemy_force
			if ef and ef.valid then
				local extra_evo = Balance.evolution_per_full_silo_charge() * e / dynamic_data.rocket_silo_energy_needed
				Common.increment_evo(extra_evo)
				dynamic_data.evolution_accrued_silo = (dynamic_data.evolution_accrued_silo or 0) + extra_evo
			end
		end

		local pollution = e / 1000000 * Balance.silo_total_pollution() / Balance.silo_energy_needed_MJ()

		if p and pollution then
			local surface = game.surfaces[destination.surface_name]
			if surface and surface.valid then
				game.get_pollution_statistics(surface).on_flow('rocket-silo', pollution)
				memory.floating_pollution = (memory.floating_pollution or 0) + 3 * pollution / 4
				surface.pollute(p, pollution / 4)

				if
					memory.overworldx >= 0
					and dynamic_data.rocket_silo_energy_consumed >= 0.25 * dynamic_data.rocket_silo_energy_needed
					and not dynamic_data.parrot_silo_warned
				then
					dynamic_data.parrot_silo_warned = true
					local spawners_count = Common.spawner_count(surface)
					if spawners_count > 0 then
						Common.parrot_speak(memory.force, { 'pirates.parrot_silo_warning' })
					end
				elseif
					dynamic_data.rocket_silo_energy_consumed >= dynamic_data.rocket_silo_energy_needed
					and not (silo.rocket_parts == 100)
					and (dynamic_data.silo_is_charged == false)
					and not memory.game_lost
				then
					silo.rocket_parts = 100
					dynamic_data.silo_is_charged = true

					if CoreData.rocket_silo_death_causes_loss then
						silo.destructible = false
					end
				end
			end
		end
	end
end

function Public.slower_boat_tick(tick_interval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then
		return
	end
	local destination = Common.current_destination()

	if memory.boat.state == Boats.enum_state.LEAVING_DOCK then
		memory.boat.speed = Math.min(memory.boat.speed + 40 / tick_interval, 12)
	end

	local p = memory.boat.position
	if p and destination.subtype ~= IslandEnum.enum.RADIOACTIVE and destination.surface_name then --no locomotive pollute on radioactive islands
		local pollution = Balance.boat_passive_pollution_per_minute(destination.dynamic_data.timer)
			/ 3600
			* tick_interval

		local surface = game.surfaces[destination.surface_name]
		if surface and surface.valid then
			surface.pollute(p, pollution)
			game.get_pollution_statistics(destination.surface_name).on_flow('locomotive', pollution)
		end
	end

	-- if memory.enemyboats then
	-- 	for i = 1, #memory.enemyboats do
	-- 		local b = memory.enemyboats[i]

	-- 		-- if b.landing_time and destination.dynamic_data.timer and destination.dynamic_data.timer >= b.landing_time and b.spawner and b.spawner.valid then
	-- 		-- -- if b.landing_time and destination.dynamic_data.timer and destination.dynamic_data.timer >= b.landing_time + 3 and b.spawner and b.spawner.valid then
	-- 		-- 	b.spawner.destructible = true
	-- 		-- 	b.landing_time = nil
	-- 		-- end
	-- 	end
	-- end
end

function Public.LOS_tick(tick_interval)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	local destination = Common.current_destination()
	local force = memory.force
	if not destination.surface_name then
		return
	end
	local surface = game.surfaces[destination.surface_name]

	if
		boat and boat.state == Boats.enum_state.APPROACHING
		or boat.state == Boats.enum_state.LANDED
		or boat.state == Boats.enum_state.RETREATING
	then
		local p = boat.position
		local BoatData = Boats.get_scope(boat).Data

		force.chart(
			surface,
			{ { p.x - BoatData.width / 2 - 70, p.y - 80 }, { p.x - BoatData.width / 2 + 70, p.y + 80 } }
		)
	end

	if
		CoreData.rocket_silo_death_causes_loss
		or (
			destination.static_params
			and destination.static_params.base_cost_to_undock
			and destination.static_params.base_cost_to_undock['launch_rocket'] == true
		)
	then
		local silos = destination.dynamic_data.rocketsilos
		if silos and silos[1] and silos[1].valid then
			local p = silos[1].position
			force.chart(surface, { { p.x - 4, p.y - 4 }, { p.x + 4, p.y + 4 } })
		end
	end
end

function Public.minimap_jam(tick_interval)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if memory.overworldx == Common.maze_minimap_jam_league and boat and boat.state == Boats.enum_state.LANDED then
		local destination = Common.current_destination()
		if destination.type == Surfaces.enum.ISLAND and destination.subtype == IslandEnum.enum.MAZE then
			if not destination.surface_name then
				return
			end
			local surface = game.surfaces[destination.surface_name]
			local force = memory.force
			force.clear_chart(surface)
		end
	end
end

-- function Public.crewtick_handle_delayed_tasks(tick_interval)
-- 	local memory = Memory.get_crew_memory()

-- 	for _, task in pairs(memory.buffered_tasks) do
-- 		if not (memory.game_lost) then
-- 			if task == Delay.enum.PAINT_CROWSNEST then
-- 				Surfaces.Crowsnest.crowsnest_surface_delayed_init()

-- 			elseif task == Delay.enum.PLACE_DOCK_JETTY_AND_BOATS then
-- 				Surfaces.Dock.place_dock_jetty_and_boats()

-- 				local destination = Common.current_destination()
-- 				ShopDock.create_dock_markets(game.surfaces[destination.surface_name], Surfaces.Dock.Data.markets_position)
-- 			end
-- 		end
-- 	end
-- 	Delay.clear_buffer()
-- 	Delay.move_tasks_to_buffer()
-- end

function Public.Kraken_Destroyed_Backup_check(tick_interval) -- a server became stuck when the kraken spawner entity disappeared but the kraken_die had not fired, and I'm not sure why, so this is a backup checker for that case
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if boat and boat.surface_name and boat.state and boat.state == Boats.enum_state.ATSEA_LOADING_MAP then
		if Kraken.get_active_kraken_count(memory.id) > 0 then
			local surface = game.surfaces[boat.surface_name]

			local some_spawners_should_be_alive = false
			for i = 1, Kraken.kraken_slots do
				if memory.active_sea_enemies.krakens[i] then
					local kraken_data = memory.active_sea_enemies.krakens[i]
					if kraken_data.step and kraken_data.step >= 3 then
						some_spawners_should_be_alive = true
					end
				end
			end

			local but_none_are = some_spawners_should_be_alive
				and #surface.find_entities_filtered({ name = 'biter-spawner', force = memory.enemy_force_name })
					== 0
			if but_none_are then
				for i = 1, Kraken.kraken_slots do
					if memory.active_sea_enemies.krakens[i] then
						Kraken.kraken_die(i)
					end
				end
			end
		end
	end
end

function Public.quest_progress_tick(tick_interval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then
		return
	end
	local destination = Common.current_destination()
	local dynamic_data = destination.dynamic_data

	local surface = game.surfaces[destination.surface_name]
	if not (surface and surface.valid) then
		return
	end

	if dynamic_data.quest_type then
		if
			dynamic_data.quest_type == Quest.enum.TIME
			and not dynamic_data.quest_complete
			and dynamic_data.quest_progress > 0
			and dynamic_data.quest_progressneeded ~= 1
		then
			dynamic_data.quest_progress = dynamic_data.quest_progress - tick_interval / 60
		end

		if dynamic_data.quest_type == Quest.enum.RESOURCEFLOW and not dynamic_data.quest_complete then
			local force = memory.force
			if not (force and force.valid and dynamic_data.quest_params) then
				return
			end

			local total_flow_count = force.get_item_production_statistics(surface).get_flow_count({
				name = dynamic_data.quest_params.item,
				category = 'input',
				precision_index = defines.flow_precision_index.five_seconds,
				count = false,
			})

			for i = 1, memory.hold_surface_count do
				local hold_surface = Hold.get_hold_surface(i)
				if hold_surface and hold_surface.valid then
					total_flow_count = total_flow_count
						+ force.get_item_production_statistics(hold_surface).get_flow_count({
							name = dynamic_data.quest_params.item,
							category = 'input',
							precision_index = defines.flow_precision_index.five_seconds,
							count = false,
						})
				end
			end

			local cabin_surface = Cabin.get_cabin_surface()
			if cabin_surface and cabin_surface.valid then
				total_flow_count = total_flow_count
					+ force.get_item_production_statistics(cabin_surface).get_flow_count({
						name = dynamic_data.quest_params.item,
						category = 'input',
						precision_index = defines.flow_precision_index.five_seconds,
						count = false,
					})
			end

			dynamic_data.quest_progress = total_flow_count
			Quest.try_resolve_quest()
		elseif dynamic_data.quest_type == Quest.enum.RESOURCECOUNT and not dynamic_data.quest_complete then
			local force = memory.force
			if not (force and force.valid and dynamic_data.quest_params) then
				return
			end

			local total_count = force.get_item_production_statistics(surface).get_flow_count({
				name = dynamic_data.quest_params.item,
				category = 'input',
				precision_index = defines.flow_precision_index.one_thousand_hours,
				count = true,
			})

			for i = 1, memory.hold_surface_count do
				local hold_surface = Hold.get_hold_surface(i)
				if hold_surface and hold_surface.valid then
					total_count = total_count
						+ force.get_item_production_statistics(hold_surface).get_flow_count({
							name = dynamic_data.quest_params.item,
							category = 'input',
							precision_index = defines.flow_precision_index.one_thousand_hours,
							count = true,
						})
				end
			end

			local cabin_surface = Cabin.get_cabin_surface()
			if cabin_surface and cabin_surface.valid then
				total_count = total_count
					+ force.get_item_production_statistics(cabin_surface).get_flow_count({
						name = dynamic_data.quest_params.item,
						category = 'input',
						precision_index = defines.flow_precision_index.one_thousand_hours,
						count = true,
					})
			end

			dynamic_data.quest_progress = total_count - dynamic_data.quest_params.initial_count
			Quest.try_resolve_quest()
		end
	end
end

function Public.silo_insta_update()
	local memory = Memory.get_crew_memory()
	if memory.game_lost then
		return
	end

	local destination = Common.current_destination()
	local dynamic_data = destination.dynamic_data

	local silos = dynamic_data.rocketsilos

	if silos and silos[1] and silos[1].valid then --need the first silo to be alive in order to charge any others
		if dynamic_data.silo_is_charged then
			for i, silo in ipairs(silos) do
				if silo and silo.valid then --sometimes theyre overwritten by other structures e.g. market
					silo.energy = silo.electric_buffer_size
				end
			end
		else
			for i, silo in ipairs(silos) do
				if silo and silo.valid then --sometimes theyre overwritten by other structures e.g. market
					local e = silo.energy - 1
					local e2 = dynamic_data.rocket_silo_energy_needed - dynamic_data.rocket_silo_energy_consumed
					if e > 0 and e2 > 0 then
						local absorb = Math.min(e, e2)
						dynamic_data.energy_charged_in_silo_since_last_check = dynamic_data.energy_charged_in_silo_since_last_check
							+ absorb
						silo.energy = silo.energy - absorb

						if dynamic_data.rocket_silo_charged_bools and not dynamic_data.rocket_silo_charged_bools[i] then
							dynamic_data.rocket_silo_charged_bools[i] = true
							local inv = silo.get_inventory(defines.inventory.assembling_machine_input)
							inv.insert({ name = 'processing-unit', count = 10 })
							inv.insert({ name = 'low-density-structure', count = 10 })
							inv.insert({ name = 'rocket-fuel', count = 10 })
						end
					else
						silo.energy = 0
					end
				end
			end
		end
	end
end

-- function Public.parrot_tick(tick_interval)
-- 	Parrot.parrot_tick()
-- end

function Public.update_player_guis(tick_interval)
	-- local global_memory = Memory.get_global_memory()
	local players = game.connected_players

	for _, player in pairs(players) do
		local crew_id = Common.get_id_from_force_name(player.force.name)
		Memory.set_working_id(crew_id)

		Gui.update_gui(player)
	end
end

function Public.update_players_second()
	local global_memory = Memory.get_global_memory()
	local connected_players = game.connected_players

	local playerindex_to_time_played_continuously = {}
	local playerindex_to_captainhood_priority = {}
	for playerindex, time in pairs(global_memory.playerindex_to_time_played_continuously) do
		local player = game.players[playerindex]

		if player and Common.validate_player(player) then
			-- port over
			playerindex_to_time_played_continuously[playerindex] = time
		end
	end
	for playerindex, time in pairs(global_memory.playerindex_to_captainhood_priority) do
		local player = game.players[playerindex]

		if player and Common.validate_player(player) then
			-- port over
			playerindex_to_captainhood_priority[playerindex] = time
		end
	end

	for _, player in pairs(connected_players) do
		local crew_id = Common.get_id_from_force_name(player.force.name)
		Memory.set_working_id(crew_id)

		if player.afk_time < Common.afk_time then
			playerindex_to_time_played_continuously[player.index] = playerindex_to_time_played_continuously[player.index]
				or 0

			playerindex_to_time_played_continuously[player.index] = playerindex_to_time_played_continuously[player.index]
				+ 1
			if Common.is_captain(player) then
				playerindex_to_captainhood_priority[player.index] = 0
			else
				playerindex_to_captainhood_priority[player.index] = playerindex_to_captainhood_priority[player.index]
					or 0

				playerindex_to_captainhood_priority[player.index] = playerindex_to_captainhood_priority[player.index]
					+ 1
			end
		else
			playerindex_to_time_played_continuously[player.index] = 0
			playerindex_to_captainhood_priority[player.index] = 0
		end
	end
	global_memory.playerindex_to_captainhood_priority = playerindex_to_captainhood_priority
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
		local crew_id = Common.get_id_from_force_name(player.force.name)
		Memory.set_working_id(crew_id)
		Roles.afk_player_tick(player)
	end
end

function Public.update_alert_sound_frequency_tracker()
	local memory = Memory.get_crew_memory()
	if
		memory.seconds_until_alert_sound_can_be_played_again
		and memory.seconds_until_alert_sound_can_be_played_again > 0
	then
		memory.seconds_until_alert_sound_can_be_played_again = memory.seconds_until_alert_sound_can_be_played_again - 1
		memory.seconds_until_alert_sound_can_be_played_again =
			Math.max(0, memory.seconds_until_alert_sound_can_be_played_again)
	end
end

-- Check for cliff explosives in chest.
function Public.check_for_cliff_explosives_in_hold_wooden_chests()
	if Common.activecrewcount() == 0 then
		return
	end

	local memory = Memory.get_crew_memory()
	local input_chests = memory.hold_surface_destroyable_wooden_chests
	local queued_chests_timers = memory.hold_surface_timers_of_wooden_chests_queued_for_destruction
	local tick_tack_timer = 5 -- how long it takes before chests detonate

	if not input_chests then
		return
	end

	-- check which chests have cliff explosives in them
	for i, chest in pairs(input_chests) do
		-- @TODO: decide what to do when chest is invalid (perhaps it was destroyed by some future feature)
		if chest and chest.valid then
			local item_count = chest.get_item_count('cliff-explosives')
			if item_count and item_count > 0 then
				if not queued_chests_timers[i] then
					queued_chests_timers[i] = tick_tack_timer
				end
			end
		end
	end

	-- update chest timers and when timer reaches 0 explode them
	for i, _ in pairs(queued_chests_timers) do
		local chest = input_chests[i]
		if chest and chest.valid then
			local surface = chest.surface
			queued_chests_timers[i] = queued_chests_timers[i] - 1
			local timer = queued_chests_timers[i]

			if timer <= 0 then
				-- check if sneaky players didn't decide to remove the explosives just before the explosion
				local item_count = chest.get_item_count('cliff-explosives')
				if item_count and item_count > 0 then
					local explosion = {
						name = 'wooden-chest-explosion',
						position = chest.position,
					}
					local remnants = {
						name = 'wooden-chest-remnants',
						position = chest.position,
					}

					chest.destroy()
					surface.create_entity(explosion)
					surface.create_entity(remnants)

					input_chests[i] = nil
				end

				queued_chests_timers[i] = nil
			else
				local tick_tacks = { '*tick*', '*tick*', '*tack*', '*tak*', '*tik*', '*tok*' }

				for _, player in pairs(game.connected_players) do
					if player.surface_index == surface.index then
						player.create_local_flying_text({
							name = 'flying-text',
							position = chest.position,
							text = tick_tacks[Math.random(#tick_tacks)],
							color = { r = 0.75, g = 0.75, b = 0.75 },
						})
					end
				end
			end
		else
			-- we probably don't want to have it in the queue anymore if it's invalid now, do we?
			queued_chests_timers[i] = nil
		end
	end
end

-- Code taken from Mountain fortress
local function equalise_fluid_storage_pair(storage1, storage2)
	if not storage1.valid then
		return
	end
	if not storage2.valid then
		return
	end

	local source_fluid = storage1.fluidbox[1]
	if not source_fluid then
		return
	end

	local target_fluid = storage2.fluidbox[1]
	local source_fluid_amount = source_fluid.amount

	local amount
	if target_fluid then
		amount = source_fluid_amount - ((target_fluid.amount + source_fluid_amount) * 0.5)
	else
		amount = source_fluid.amount * 0.5
	end

	if amount <= 0 then
		return
	end

	local inserted_amount =
		storage2.insert_fluid({ name = source_fluid.name, amount = amount, temperature = source_fluid.temperature })
	if inserted_amount > 0 then
		storage1.remove_fluid({ name = source_fluid.name, amount = inserted_amount })
	end
end

-- This function assumes that there is equal amount of special storage tanks on deck and every hold.
-- NOTE: This function only equalises adjacent storage tank pairs. That is "Deck - 1st Hold" and "Nth Hold - (N+1)th Hold" pairs
function Public.equalise_fluid_storages()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if boat.upstairs_fluid_storages and boat.downstairs_fluid_storages then
		-- Iterate every chain of together connected storages from deck and all holds
		for i = 1, #boat.upstairs_fluid_storages do
			local storages = {}
			storages[1] = boat.upstairs_fluid_storages[i]

			for j = 1, memory.hold_surface_count do
				storages[j + 1] = boat.downstairs_fluid_storages[j][i]
			end

			for j = 2, #storages do
				equalise_fluid_storage_pair(storages[j], storages[j - 1])
				equalise_fluid_storage_pair(storages[j - 1], storages[j])
			end
		end
	end
end

function Public.revealed_buried_treasure_distance_check()
	local destination = Common.current_destination()
	if Common.activecrewcount() == 0 then
		return
	end

	if destination.dynamic_data.some_player_was_close_to_buried_treasure then
		return
	end

	local maps = destination.dynamic_data.treasure_maps or {}
	for _, map in pairs(maps) do
		if map.state == 'picked_up' then
			for _, player in pairs(Common.crew_get_crew_members()) do
				if player.character and player.character.valid then
					if Math.distance(player.character.position, map.buried_treasure_position) <= 20 then
						destination.dynamic_data.some_player_was_close_to_buried_treasure = true
					end
				end
			end
		end
	end
end

function Public.update_pet_biter_lifetime(tick_interval)
	local memory = Memory.get_crew_memory()
	if memory.pet_biters then
		for id, pet_biter in pairs(memory.pet_biters) do
			if pet_biter.pet and pet_biter.pet.valid then
				pet_biter.time_to_live = pet_biter.time_to_live - tick_interval
				if pet_biter.time_to_live <= 0 then
					memory.pet_biters[id].pet.die()
					memory.pet_biters[id] = nil
				end
			else
				memory.pet_biters[id] = nil
			end
		end
	end
end

function Public.update_time_remaining()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	local destination = Common.current_destination()

	if not (destination.dynamic_data.time_remaining and destination.dynamic_data.time_remaining > 0) then
		return
	end
	destination.dynamic_data.time_remaining = destination.dynamic_data.time_remaining - 1

	if destination.dynamic_data.time_remaining ~= 0 then
		return
	end

	if not boat then
		return
	end
	if boat.state == Boats.enum_state.RETREATING then
		return
	end
	if not boat.surface_name then
		return
	end

	if destination.type == Surfaces.enum.ISLAND then
		if
			destination.static_params
			and destination.static_params.base_cost_to_undock
			and Boats.need_resources_to_undock(Common.overworldx(), destination.subtype)
			and (not Common.query_can_pay_cost_to_leave())
		then
			Crew.try_lose({ 'pirates.loss_resources_were_not_collected_in_time' })
		else
			Common.consume_undock_cost_resources()
			Progression.retreat_from_island(false)
		end
	elseif destination.type == Surfaces.enum.DOCK then
		Progression.undock_from_dock(false)
	end
end

return Public
