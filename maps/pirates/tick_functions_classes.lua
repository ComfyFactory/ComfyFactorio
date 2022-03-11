local Memory = require 'maps.pirates.memory'
local Gui = require 'maps.pirates.gui.gui'
local Ai = require 'maps.pirates.ai'
local Structures = require 'maps.pirates.structures.structures'
local Islands = require 'maps.pirates.surfaces.islands.islands'
local Boats = require 'maps.pirates.structures.boats.boats'
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
local Math = require 'maps.pirates.math'
local inspect = require 'utils.inspect'.inspect

local Quest = require 'maps.pirates.quest'

local Public = {}


function Public.class_renderings(tickinterval)
	local memory = Memory.get_crew_memory()
	if not memory.classes_table then return end

	local crew = Common.crew_get_crew_members()

	if not memory.quartermaster_renderings then
		memory.quartermaster_renderings = {}
	end

	local processed_renderings = {}

	for _, player in pairs(crew) do
		local player_index = player.index
		if memory.classes_table[player_index] == Classes.enum.QUARTERMASTER then
			local r = memory.quartermaster_renderings[player_index]
			processed_renderings[player_index] = true
			if Common.validate_player_and_character(player) then
				if r and rendering.is_valid(r) then
					rendering.set_target(r, player.character)
				else
					memory.quartermaster_renderings[player_index] = rendering.draw_circle{
						surface = player.surface,
						target = player.character,
						color = CoreData.colors.quartermaster_rendering,
						filled = false,
						radius = Common.quartermaster_range,
						only_in_alt_mode = true,
						draw_on_ground = true,
					}
				end
			else
				if r then
					rendering.destroy(r)
					memory.quartermaster_renderings[player_index] = nil
				end
			end
		end
	end

	for k, r in pairs(memory.quartermaster_renderings) do
		if not processed_renderings[k] then
			rendering.destroy(r)
			memory.quartermaster_renderings[k] = nil
		end
	end
end




function Public.update_character_properties(tickinterval)
	local memory = Memory.get_crew_memory()

	local crew = Common.crew_get_crew_members()

	for _, player in pairs(crew) do
		if Common.validate_player_and_character(player) then
			local player_index = player.index
			local character = player.character
			if memory.classes_table and memory.classes_table[player_index] then
				local max_reach_bonus = 0
				-- if memory.classes_table[player_index] == Classes.enum.DECKHAND then
				-- 	max_reach_bonus = Math.max(max_reach_bonus, 6)
				-- 	character.character_build_distance_bonus = 6
				-- else
				-- 	character.character_build_distance_bonus = 0
				-- end

				if memory.classes_table[player_index] == Classes.enum.FISHERMAN then
					max_reach_bonus = Math.max(max_reach_bonus, 10)
					character.character_resource_reach_distance_bonus = 10
				elseif memory.classes_table[player_index] == Classes.enum.MASTER_ANGLER or memory.classes_table[player_index] == Classes.enum.DREDGER then
					max_reach_bonus = Math.max(max_reach_bonus, 16)
					character.character_resource_reach_distance_bonus = 16
				else
					character.character_resource_reach_distance_bonus = 0
				end

				character.character_reach_distance_bonus = max_reach_bonus
			end

			local health_boost = 0
			-- base health is 250
			if memory.classes_table and memory.classes_table[player_index] then
				local class = memory.classes_table[player_index]
				if class == Classes.enum.SAMURAI then
					health_boost = health_boost + 800
				elseif class == Classes.enum.HATAMOTO then
					health_boost = health_boost + 1300
				end
			end
			if Common.is_captain(player) then
				health_boost = health_boost + 50
			end
			character.character_health_bonus = health_boost

			local speed_boost = Balance.base_extra_character_speed
			if memory.speed_boost_characters and memory.speed_boost_characters[player_index] then
				speed_boost = speed_boost + 0.75
			else
				if memory.classes_table and memory.classes_table[player_index] then
					local class = memory.classes_table[player_index]
					if class == Classes.enum.SCOUT then
						speed_boost = speed_boost + 0.35
					elseif class == Classes.enum.DECKHAND or class == Classes.enum.BOATSWAIN or class == Classes.enum.SHORESMAN then
						local surfacedata = Surfaces.SurfacesCommon.decode_surface_name(player.surface.name)
						local type = surfacedata.type
						local on_ship_bool = type == Surfaces.enum.HOLD or type == Surfaces.enum.CABIN or type == Surfaces.enum.CROWSNEST or (player.surface.name == memory.boat.surface_name and Boats.on_boat(memory.boat, player.position))
						local hold_bool = surfacedata.type == Surfaces.enum.HOLD

						if class == Classes.enum.DECKHAND then
							if on_ship_bool and (not hold_bool) then
								speed_boost = speed_boost + 0.25
							elseif (not on_ship_bool) then
								speed_boost = speed_boost - 0.25
							end
						elseif class == Classes.enum.BOATSWAIN then
							if hold_bool then
								speed_boost = speed_boost + 0.25
							elseif (not on_ship_bool) then
								speed_boost = speed_boost - 0.25
							end
						elseif class == Classes.enum.SHORESMAN then
							if on_ship_bool then
								speed_boost = speed_boost - 0.25
							else
								speed_boost = speed_boost + 0.07
							end
						end
					end
				end
			end
			character.character_running_speed_modifier = speed_boost
		end
	end
end

function Public.class_rewards_tick(tickinterval)
	--assuming tickinterval = 6 seconds for now
	local memory = Memory.get_crew_memory()

	local crew = Common.crew_get_crew_members()
	for _, player in pairs(crew) do
		if Common.validate_player_and_character(player) then
			local player_index = player.index

			if memory.classes_table and memory.classes_table[player_index] then
				if game.tick % tickinterval == 0 and Common.validate_player_and_character(player) then
					if memory.classes_table[player.index] == Classes.enum.SMOLDERING then
						local inv = player.get_inventory(defines.inventory.character_main)
						if not (inv and inv.valid) then return end
						local max_coal = 25
						-- local max_transfer = 1
						local wood_count = inv.get_item_count('wood')
						local coal_count = inv.get_item_count('coal')
						if wood_count >= 1 and coal_count < max_coal then
							-- local count = Math.min(wood_count, max_coal-coal_count, max_transfer)
							local count = 1
							inv.remove({name = 'wood', count = count})
							inv.insert({name = 'coal', count = count})
							Common.flying_text_small(player.surface, player.position, '[item=coal]')
						end
					end
				end
			end


			if game.tick % tickinterval == 0 and (not (memory.boat and memory.boat.state and memory.boat.state == Structures.Boats.enum_state.ATSEA_LOADING_MAP)) then --it is possible to spend extra time here, so don't give out freebies

				if memory.classes_table and memory.classes_table[player_index] then
					local class = memory.classes_table[player_index]
					if class == Classes.enum.DECKHAND or class == Classes.enum.SHORESMAN or class == Classes.enum.BOATSWAIN or class == Classes.enum.QUARTERMASTER then --watch out for this line!
						local surfacedata = Surfaces.SurfacesCommon.decode_surface_name(player.surface.name)
						local type = surfacedata.type
						local on_ship_bool = type == Surfaces.enum.HOLD or type == Surfaces.enum.CABIN or type == Surfaces.enum.CROWSNEST or (player.surface.name == memory.boat.surface_name and Boats.on_boat(memory.boat, player.position))
						local hold_bool = surfacedata.type == Surfaces.enum.HOLD
	
						if class == Classes.enum.DECKHAND and on_ship_bool and (not hold_bool) then
							Classes.class_ore_grant(player, 4)
						elseif class == Classes.enum.BOATSWAIN and hold_bool then
							Classes.class_ore_grant(player, 6)
						elseif class == Classes.enum.SHORESMAN and (not on_ship_bool) then
							Classes.class_ore_grant(player, 2)
						elseif class == Classes.enum.QUARTERMASTER then
							local nearby_players = #player.surface.find_entities_filtered{position = player.position, radius = Common.quartermaster_range, name = 'character'}
				
							if nearby_players > 1 then
								Classes.class_ore_grant(player, nearby_players - 1, true)
							end
						end
					end
				end
			end
		end
	end
end

return Public