
local Public = {}

local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
local CustomEvents = require 'maps.pirates.custom_events'

-- local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Crowsnest = require 'maps.pirates.surfaces.crowsnest'
local Server = require 'utils.server'
local Dock = require 'maps.pirates.surfaces.dock'
-- local Islands = require 'maps.pirates.surfaces.islands.islands'
local Sea = require 'maps.pirates.surfaces.sea.sea'
local Crew = require 'maps.pirates.crew'
local Roles = require 'maps.pirates.roles.roles'
-- local Parrot = require 'maps.pirates.parrot'
-- local Quest = require 'maps.pirates.quest'

local Shop = require 'maps.pirates.shop.shop'
local Overworld = require 'maps.pirates.overworld'
local Hold = require 'maps.pirates.surfaces.hold'
local Cabin = require 'maps.pirates.surfaces.cabin'
local Upgrades = require 'maps.pirates.boat_upgrades'
local Task = require 'utils.task'
local Token = require 'utils.token'
local ShopDock = require 'maps.pirates.shop.dock'



function Public.fuel_depletion_rate()
	local memory = Memory.get_crew_memory()
	local state = memory.boat.state

	if state == Boats.enum_state.ATSEA_SAILING or state == Boats.enum_state.APPROACHING then
		return Balance.fuel_depletion_rate_sailing()
	elseif state == Boats.enum_state.LEAVING_DOCK then
		return Balance.fuel_depletion_rate_sailing() * 2
	elseif state == Boats.enum_state.RETREATING then
		return Balance.fuel_depletion_rate_sailing() / 4
	elseif state == Boats.enum_state.LANDED then
		return Balance.fuel_depletion_rate_static()
	elseif state == Boats.enum_state.DOCKED then
		return -0.1
	else
		return 0
	end
end



function Public.set_off_from_starting_dock()
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end

	memory.crewstatus = Crew.enum.LEAVING_INITIAL_DOCK
	memory.boat.state = Boats.enum_state.LEAVING_DOCK

	Boats.place_boat(memory.boat, CoreData.moving_boat_floor, false, false)

	Common.current_destination().type = Surfaces.enum.LOBBY

	memory.mapbeingloadeddestination_index = 1 -- whatever the index of the first island is
	memory.loadingticks = 0

	local surface = game.surfaces[CoreData.lobby_surface_name]
	local p = Utils.psum{memory.boat.position, Boats.get_scope(memory.boat).Data.crewname_rendering_position}
	memory.boat.rendering_crewname_text = rendering.draw_text{
		text = memory.name,
		-- render_layer = '125', --does nothing
		surface = surface,
		target = p,
		color = CoreData.colors.renderingtext_yellow,
		scale = 8,
		font = 'default-game',
		alignment = 'left'
	}
end




function Public.go_from_starting_dock_to_first_destination()

	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	local crew_members = Crew.choose_crew_members()
	local crew_members_count = #memory.crewplayerindices

	if crew_members_count > 0 then
		memory.crewstatus = Crew.enum.ADVENTURING

		local message = '[' .. memory.name .. '] Crew members: '
		local b = false
		for _, index in pairs(memory.crewplayerindices) do
			if game.players[index] and game.players[index].name then
				if b == true then
					message = message .. ', '
				else b = true end
				message = message .. game.players[index].name
			end
		end
		message = message .. '.'
		Server.to_discord_embed_raw(CoreData.comfy_emojis.pogkot .. message)

		Roles.assign_captain_based_on_priorities()

		for _, player in pairs(crew_members) do
			Crew.player_abandon_endorsements(player)
			for item, amount in pairs(Balance.starting_items_player) do
				player.insert({name = item, count = amount})
			end
		end

		boat.stored_resources = {}

		Shop.Captains.initialise_captains_shop()

		Hold.create_hold_surface(1)
		Cabin.create_cabin_surface()

		local items = Balance.starting_items_crew_upstairs()
		-- Boats.deck_place_random_obstacle_boxes(boat, 6, items, 0)

		-- Let's try just adding the items to nearby boxes
		local scope = Boats.get_scope(boat)
		local surface = game.surfaces[boat.surface_name]
		local boxes = surface.find_entities_filtered{
			name = 'wooden-chest',
			area = {
				{x = boat.position.x - scope.Data.width/2, y = boat.position.y - scope.Data.height/2},
				{x = boat.position.x + scope.Data.width/2, y = boat.position.y + scope.Data.height/2}
			},
		}
		boxes = Math.shuffle(boxes)
		for i = 1, #items do
			if boxes[i] then
				local inventory = boxes[i].get_inventory(defines.inventory.chest)
				for name, count in pairs(items[i]) do
					inventory.insert{name = name, count = count}
				end
			else
				game.print('fail at ' .. boxes[i].position.x .. ' ' .. boxes[i].position.y)
			end
		end

		Public.progress_to_destination(1) --index of first destination

		-- local scope = Boats.get_scope(boat)
		-- local boatwidth, boatheight = scope.Data.width, scope.Data.height
		-- Common.surface_place_random_obstacle_boxes(game.surfaces[boat.surface_name], {x = boat.position.x - boatwidth*0.575, y = boat.position.y}, boatwidth*0.85, boatheight*0.8, 'oil-refinery', {[1] = 3, [2] = 3, [3] = 0, [4] = 0}, items)
		-- go:
		-- Public.progress_to_destination(1) --index of first destination

		boat.EEI_stage = 1
		Boats.update_EEIs(boat)

		-- if Common.difficulty_scale() == 1 then
		-- 	Boats.upgrade_chests(boat, 'iron-chest')
		-- 	Hold.upgrade_chests(1, 'iron-chest')
		-- 	Crowsnest.upgrade_chests('iron-chest')
		-- elseif Common.difficulty_scale() > 1 then
		-- 	Boats.upgrade_chests(boat, 'steel-chest')
		-- 	Hold.upgrade_chests(1, 'steel-chest')
		-- 	Crowsnest.upgrade_chests('steel-chest')
		-- end

		memory.age = 0
		memory.real_age = 0

	else
		Boats.destroy_boat(boat)
		Crew.disband_crew()
	end
end


local place_dock_jetty_and_boats = Token.register(
	function(data)
		Memory.set_working_id(data.crew_id)
		local memory = Memory.get_crew_memory()
		if memory.game_lost then return end
		Surfaces.Dock.place_dock_jetty_and_boats()

		local destination = Common.current_destination()
		ShopDock.create_dock_markets(game.surfaces[destination.surface_name], Surfaces.Dock.Data.markets_position)
	end
)



function Public.progress_to_destination(destination_index)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end

	local boat = memory.boat

	local oldsurface = game.surfaces[boat.surface_name]
	local old_type = Surfaces.SurfacesCommon.decode_surface_name(oldsurface.name).type

	local destination_data = memory.destinations[destination_index]
	local static_params = destination_data.static_params
	local type = destination_data.type
	local subtype = destination_data.subtype
	local newsurface_name = Surfaces.SurfacesCommon.encode_surface_name(memory.id, destination_index, type, subtype)
	local newsurface = game.surfaces[newsurface_name]

	local initial_boatspeed, starting_boatposition

	if type == Surfaces.enum.ISLAND then --moved from overworld generation, so that it updates properly
		local covered1_requirement = Balance.covered1_entry_price()
		destination_data.dynamic_data.covered1_requirement = covered1_requirement
	end

	if type == Surfaces.enum.DOCK then
		local BoatData = Boats.get_scope(boat).Data
		starting_boatposition = Utils.snap_coordinates_for_rails({x = Dock.Data.playerboat_starting_xcoord, y = Dock.Data.player_boat_top + BoatData.height/2})
		-- starting_boatposition = {x = -destination_data.static_params.width/2 + BoatData.width + 10, y = Dock.Data.player_boat_top - BoatData.height/2}
		Common.current_destination().dynamic_data.time_remaining = 180

		-- memory.mainshop_availability_bools.sell_iron = true
		memory.mainshop_availability_bools.buy_iron = true
		memory.mainshop_availability_bools.buy_copper = true
		-- memory.mainshop_availability_bools.buy_fast_loader = true
		-- memory.mainshop_availability_bools.sell_copper = true

		memory.mainshop_availability_bools.repair_cannons = true

		local boat_for_sale_type = Common.current_destination().static_params.boat_for_sale_type
		if boat_for_sale_type then
			if boat_for_sale_type == Boats.enum.CUTTER then
				memory.mainshop_availability_bools.new_boat_cutter = true
			elseif boat_for_sale_type == Boats.enum.CUTTER_WITH_HOLD then
				memory.mainshop_availability_bools.new_boat_cutter_with_hold = true
			elseif boat_for_sale_type == Boats.enum.SLOOP_WITH_HOLD then
				memory.mainshop_availability_bools.new_boat_sloop_with_hold = true
			end
		end

		local upgrade_for_sale = Common.current_destination().static_params.upgrade_for_sale
		if upgrade_for_sale then
			for _, u in pairs(Upgrades.List) do
				if upgrade_for_sale == u then
					memory.mainshop_availability_bools[u] = true
				end
			end
		end

		script.raise_event(CustomEvents.enum['update_crew_fuel_gui'], {})

		-- Delay.add(Delay.enum.PLACE_DOCK_JETTY_AND_BOATS)
		Task.set_timeout_in_ticks(2, place_dock_jetty_and_boats, {crew_id = memory.id})
	else
		starting_boatposition = {x = static_params.boat_starting_xposition, y = static_params.boat_starting_yposition or 0}
	end

	-- if oldsurface.name == CoreData.lobby_surface_name then
	-- 	initial_boatspeed = 3
	-- else
	-- 	initial_boatspeed = 1.5
	-- end
	initial_boatspeed = 1.4

	boat.speed = initial_boatspeed
	boat.state = destination_data.init_boat_state
	boat.dockedposition = nil

	memory.enemyboats = {}

	local old_water = 'deepwater'
	if old_type == Surfaces.enum.LOBBY or old_type == Surfaces.enum.DOCK then old_water = 'water' end

	Boats.teleport_boat(boat, newsurface_name, starting_boatposition, CoreData.moving_boat_floor, old_water)


	if old_type == Surfaces.enum.LOBBY then
		Crowsnest.draw_extra_bits()
	end
	Crowsnest.paint_around_destination(destination_index, CoreData.overworld_presence_tile)


	if memory.loadingticks then memory.loadingticks = -120 end

	if old_type == Surfaces.enum.SEA then
		game.delete_surface(oldsurface)
	end

	memory.destinationsvisited_indices[#memory.destinationsvisited_indices + 1] = destination_index

	memory.currentdestination_index = destination_index --already done when we collide with it typically
	local destination = Common.current_destination()

	script.raise_event(CustomEvents.enum['update_crew_progress_gui'], {})

	destination.dynamic_data.timer = 0
	destination.dynamic_data.timeratlandingtime = nil

	memory.extra_time_at_sea = 0

	if old_type == Surfaces.enum.SEA or old_type == Surfaces.enum.CHANNEL or old_type == Surfaces.enum.DOCK then
		-- move over anyone who was left behind, such as dead and spectating players
		for _, player in pairs(game.connected_players) do
			if type == Surfaces.enum.ISLAND and player.controller_type == defines.controllers.spectator then
				if player.surface == oldsurface then --avoid moving players in hold etc
					-- put them at a nice viewing position:
					player.teleport({x = memory.spawnpoint.x + 120, y = memory.spawnpoint.y}, newsurface)
				end
			elseif player.surface == oldsurface then
				player.teleport(memory.spawnpoint, newsurface)
			end
		end
	end

	Surfaces.destination_on_arrival(Common.current_destination())
end








function Public.check_for_end_of_boat_movement(boat)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local collided = Boats.collision_infront(boat)

	local approaching_island = boat.state == Boats.enum_state.APPROACHING and destination.type == Surfaces.enum.ISLAND
	local retreating_island = boat.state == Boats.enum_state.RETREATING and destination.type == Surfaces.enum.ISLAND

	local approaching_dock = destination.type == Surfaces.enum.DOCK and boat.state == Boats.enum_state.APPROACHING
	local leaving_dock = destination.type == Surfaces.enum.DOCK and boat.state == Boats.enum_state.LEAVING_DOCK

	--=== Collision
	if approaching_island and collided then
		boat.state = Boats.enum_state.LANDED
		boat.speed = 0
		boat.dockedposition = boat.position


		game.surfaces[boat.surface_name].play_sound{path = "utility/axe_fighting"}
		game.surfaces[boat.surface_name].play_sound{path = "utility/axe_fighting"}
	end

	--=== Enemy
	if boat.force_name == memory.enemy_force_name then

		if approaching_island then

			if collided then
				boat.landing_time = destination.dynamic_data.timer

				Boats.place_landingtrack(boat, CoreData.enemy_landing_tile)

				return true

			-- elseif boat.spawner and boat.spawner.valid and boat.spawner.destructible then
			-- 	-- This code was somehow making the spawners destructible but still able to be shot at.
			-- 	local boat2 = Utils.deepcopy(boat)
			-- 	boat2.position = {x = boat.position.x + 6, y = boat.position.y}
			-- 	if Boats.collision_infront(boat2) then
			-- 		boat.spawner.destructible = false
			-- 	end
			end

		end

	--=== Friendly
	elseif boat.force_name == memory.force_name then

		if approaching_island and collided then

			Surfaces.destination_on_crewboat_hits_shore(destination)
			return true

		elseif retreating_island and boat.position.x < ((boat.dockedposition.x or 999) - Boats.get_scope(boat).Data.width - 2 * Boats.get_scope(boat).Data.rightmost_gate_position - 8) then

			Public.go_from_currentdestination_to_sea()
			return true


		elseif approaching_dock and boat.position.x + Boats.get_scope(boat).Data.rightmost_gate_position >= Dock.Data.rightmostgate_stopping_xposition then

			boat.state = Boats.enum_state.DOCKED
			boat.speed = 0
			boat.dockedposition = boat.position

			destination.dynamic_data.timeratlandingtime = destination.dynamic_data.timer

			Boats.place_boat(boat, CoreData.static_boat_floor, false, false)
			return true


		elseif leaving_dock and boat.position.x >= game.surfaces[boat.surface_name].map_gen_settings.width/2 - 60 then

			memory.mainshop_availability_bools.new_boat_cutter = false
			memory.mainshop_availability_bools.new_boat_cutter_with_hold = false
			memory.mainshop_availability_bools.new_boat_sloop_with_hold = false
			-- memory.mainshop_availability_bools.sell_iron = false
			memory.mainshop_availability_bools.buy_iron = false
			memory.mainshop_availability_bools.buy_copper = false
			-- memory.mainshop_availability_bools.buy_fast_loader = false
			-- memory.mainshop_availability_bools.sell_copper = false
			memory.mainshop_availability_bools.repair_cannons = false

			memory.mainshop_availability_bools.extra_hold = false
			memory.mainshop_availability_bools.upgrade_power = false
			memory.mainshop_availability_bools.unlock_merchants = false
			memory.mainshop_availability_bools.rockets_for_sale = false

			script.raise_event(CustomEvents.enum['update_crew_fuel_gui'], {})

			Public.go_from_currentdestination_to_sea()

			return true


		--=== Fallthrough right-hand side
		elseif destination.type == Surfaces.enum.ISLAND and boat.position.x >= game.surfaces[boat.surface_name].map_gen_settings.width/2 - 10 then
			Public.go_from_currentdestination_to_sea()
			return true
		end
	end



	return false
end





function Public.try_retreat_from_island(player, manual) -- Assumes the cost can be paid
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	local destination = Common.current_destination()

	if Common.query_can_pay_cost_to_leave() then
		if destination.dynamic_data.timeratlandingtime and destination.dynamic_data.timer < destination.dynamic_data.timeratlandingtime + 10 then
			if player and Common.validate_player(player) then
				Common.notify_player_error(player, 'Undock error: Can\'t undock in the first 10 seconds.')
			end
		else
			local cost = destination.static_params.base_cost_to_undock

			if cost then
				local adjusted_cost = Common.time_adjusted_departure_cost(cost)

				Common.spend_stored_resources(adjusted_cost)
			end
			Public.retreat_from_island(manual)
		end
	else
		if player and Common.validate_player(player) then
			Common.notify_force_error(player.force, 'Undock error: Not enough resources stored in the captain\'s cabin.')
		end
	end
end

function Public.retreat_from_island(manual)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if boat.state and boat.state == Boats.enum_state.RETREATING then return end

	boat.state = Boats.enum_state.RETREATING
	boat.speed = 1.25

	Boats.place_boat(boat, CoreData.moving_boat_floor, false, false)

	local force = memory.force
	if not (force and force.valid) then return end
	if manual then
		Common.notify_force(force,'[font=heading-1]Ship undocked[/font] by captain.')
	else
		Common.notify_force(force,'[font=heading-1]Ship auto-undocked[/font]. Return to ship.')
	end

	Surfaces.destination_on_departure(Common.current_destination())
end



function Public.undock_from_dock(manual)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	local destination = Common.current_destination()

	boat.state = Boats.enum_state.LEAVING_DOCK
	destination.dynamic_data.time_remaining = -1

	Boats.place_boat(boat, CoreData.moving_boat_floor, false, false)

	memory.mainshop_availability_bools.new_boat_cutter = false
	memory.mainshop_availability_bools.new_boat_cutter_with_hold = false
	memory.mainshop_availability_bools.new_boat_sloop_with_hold = false

	script.raise_event(CustomEvents.enum['update_crew_fuel_gui'], {})

	Crew.summon_crew()

	local force = memory.force
	if not (force and force.valid) then return end
	if manual then
		Common.notify_force(force,'[font=heading-1]Ship undocked[/font].')
	else
		Common.notify_force(force,'[font=heading-1]Ship auto-undocked[/font].')
	end
end



function Public.go_from_currentdestination_to_sea()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	if memory.game_lost then return end

	local oldsurface = game.surfaces[destination.surface_name]

	Sea.ensure_sea_surface()
	local seaname = memory.sea_name

	local boat = memory.boat

	local new_boatposition = Utils.snap_coordinates_for_rails({x = Boats.get_scope(memory.boat).Data.width / 2, y = 0})

	Boats.teleport_boat(boat, seaname, new_boatposition, CoreData.static_boat_floor, 'water')

	if memory.overworldx == 0 and memory.boat then

		local difficulty_name = CoreData.get_difficulty_name_from_value(memory.difficulty)
		if difficulty_name == CoreData.difficulty_options[#CoreData.difficulty_options].text then
			Boats.upgrade_chests(boat, 'steel-chest')
			Hold.upgrade_chests(1, 'steel-chest')
			Crowsnest.upgrade_chests('steel-chest')

			Common.parrot_speak(memory.force, 'Steel chests for steel players! Squawk!')
		elseif difficulty_name ~= CoreData.difficulty_options[1].text then
			Boats.upgrade_chests(boat, 'iron-chest')
			Hold.upgrade_chests(1, 'iron-chest')
			Crowsnest.upgrade_chests('iron-chest')

			Common.parrot_speak(memory.force, 'Iron chests for iron players! Squawk!')
		end
	end

	memory.boat.state = Boats.enum_state.ATSEA_SAILING
	memory.boat.speed = 0
	memory.boat.position = new_boatposition
	memory.boat.surface_name = seaname

	memory.enemy_force.reset_evolution()

	--@FIX: This doesn't change the evo during sea travel, which is relevant now that krakens are in the game:
	local base_evo = Balance.base_evolution_leagues(memory.overworldx)
	Common.set_evo(base_evo)
	memory.kraken_evo = 0

	memory.loadingticks = nil
	memory.mapbeingloadeddestination_index = nil

	local d = destination.iconized_map_width + Crowsnest.platformwidth

	Crowsnest.paint_around_destination(destination.destination_index, 'deepwater')

	Overworld.try_overworld_move_v2{x = d, y = 0}


	local players_marooned_count = 0
	for _, player in pairs(game.connected_players) do
		if (player.surface == oldsurface and player.character and player.character.valid) then
			players_marooned_count = players_marooned_count + 1
		end
	end
	if players_marooned_count == 0 then
		Surfaces.clean_up(destination)
	end
end








return Public