--luacheck: ignore
--luacheck ignores because tickinterval arguments are a code templating choice...

local Memory = require 'maps.pirates.memory'
local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Classes = require 'maps.pirates.roles.classes'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Math = require 'maps.pirates.math'
local _inspect = require 'utils.inspect'.inspect

local Public = {}

function Public.class_update_auxiliary_data(tickinterval)
	local memory = Memory.get_crew_memory()
	if not memory.classes_table then return end

	local class_auxiliary_data = memory.class_auxiliary_data

	local crew = Common.crew_get_crew_members()

	local processed_players = {}

	for _, player in pairs(crew) do
		local player_index = player.index
		local class = memory.classes_table[player_index]
		if class and class == Classes.enum.IRON_LEG then
			if (not class_auxiliary_data[player_index]) then class_auxiliary_data[player_index] = {} end
			local data = class_auxiliary_data[player_index]
			processed_players[player_index] = true
			local check
			if Common.validate_player_and_character(player) then
				local inv = player.character.get_inventory(defines.inventory.character_main)
				if inv and inv.valid then
					local count = inv.get_item_count('iron-ore')
					if count and count >= Balance.iron_leg_iron_ore_required then
						check = true
					end
				end
			end
			if check then
				data.iron_leg_active = true
			else
				data.iron_leg_active = false
			end
		end
	end

	for k, _ in pairs(class_auxiliary_data) do
		if not processed_players[k] then
			class_auxiliary_data[k] = nil
		end
	end
end

function Public.class_renderings(tickinterval)
	local memory = Memory.get_crew_memory()
	if not memory.classes_table then return end

	local class_renderings = memory.class_renderings

	local crew = Common.crew_get_crew_members()

	local processed_players = {}

	for _, player in pairs(crew) do
		local player_index = player.index
		local class = memory.classes_table[player_index]
		if class then
			if not class_renderings[player_index] then class_renderings[player_index] = {} end
			local rendering_data = class_renderings[player_index]
			local r = rendering_data.rendering
			local c = rendering_data.class
			processed_players[player_index] = true
			if Common.validate_player_and_character(player) and (c ~= Classes.enum.IRON_LEG or (memory.class_auxiliary_data[player_index] and memory.class_auxiliary_data[player_index].iron_leg_active)) then
				if class == c then
					if r and rendering.is_valid(r) then
						rendering.set_target(r, player.character)
					end
				else
					if r and rendering.is_valid(r) then
						rendering.destroy(r)
					end
					if class == Classes.enum.QUARTERMASTER then
						class_renderings[player_index] = {
							rendering = rendering.draw_circle{
								surface = player.surface,
								target = player.character,
								color = CoreData.colors.quartermaster_rendering,
								filled = false,
								radius = Balance.quartermaster_range,
								only_in_alt_mode = true,
								draw_on_ground = true,
							}
						}
					elseif class == Classes.enum.SAMURAI then
						class_renderings[player_index] = {
							rendering = rendering.draw_circle{
								surface = player.surface,
								target = player.character,
								color = CoreData.colors.toughness_rendering,
								filled = false,
								radius = (1 - Balance.samurai_damage_taken_multiplier)^2,
								only_in_alt_mode = false,
								draw_on_ground = true,
							}
						}
					elseif class == Classes.enum.HATAMOTO then
						class_renderings[player_index] = {
							rendering = rendering.draw_circle{
								surface = player.surface,
								target = player.character,
								color = CoreData.colors.toughness_rendering,
								filled = false,
								radius = (1 - Balance.hatamoto_damage_taken_multiplier)^2,
								only_in_alt_mode = false,
								draw_on_ground = true,
							}
						}
					elseif class == Classes.enum.IRON_LEG and memory.class_auxiliary_data[player_index] and memory.class_auxiliary_data[player_index].iron_leg_active then
						class_renderings[player_index] = {
							rendering = rendering.draw_circle{
								surface = player.surface,
								target = player.character,
								color = CoreData.colors.toughness_rendering,
								filled = false,
								radius = (1 - Balance.iron_leg_damage_taken_multiplier)^2,
								only_in_alt_mode = false,
								draw_on_ground = true,
							}
						}
					end
				end
			else
				if r then
					rendering.destroy(r)
				end
				class_renderings[player_index] = nil
			end
		end
	end

	for k, data in pairs(class_renderings) do
		if not processed_players[k] then
			local r = data.rendering
			if r and rendering.is_valid(r) then
				rendering.destroy(r)
			end
			class_renderings[k] = nil
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
			local class = memory.classes_table and memory.classes_table[player_index] or nil
			if class then
				--local max_reach_bonus = 0
				-- if memory.classes_table[player_index] == Classes.enum.DECKHAND then
				-- 	max_reach_bonus = Math.max(max_reach_bonus, 6)
				-- 	character.character_build_distance_bonus = 6
				-- else
				-- 	character.character_build_distance_bonus = 0
				-- end

				if class == Classes.enum.FISHERMAN then
					character.character_reach_distance_bonus = Balance.fisherman_reach_bonus
				elseif class == Classes.enum.MASTER_ANGLER then
					character.character_reach_distance_bonus = Balance.master_angler_reach_bonus
				elseif class == Classes.enum.DREDGER then
					character.character_reach_distance_bonus = Balance.dredger_reach_bonus
				else
					character.character_reach_distance_bonus = 0
				end

				--character.character_reach_distance_bonus = max_reach_bonus
			end

			local health_boost = 0 -- base health is 250

			-- moved to damage resistance:
			-- if memory.classes_table and memory.classes_table[player_index] then
			-- 	local class = memory.classes_table[player_index]
			-- 	if class == Classes.enum.SAMURAI then
			-- 		health_boost = health_boost + 800
			-- 	elseif class == Classes.enum.HATAMOTO then
			-- 		health_boost = health_boost + 1300
			-- 	end
			-- end

			-- Captain health boost:
			-- if Common.is_captain(player) then
			-- 	health_boost = health_boost + 50
			-- end
			character.character_health_bonus = health_boost

			local speed_boost = Balance.base_extra_character_speed

			if memory.speed_boost_characters and memory.speed_boost_characters[player_index] then
				speed_boost = speed_boost * Balance.respawn_speed_boost
			elseif memory.classes_table and memory.classes_table[player_index] then
				if class == Classes.enum.SCOUT then
					speed_boost = speed_boost * Balance.scout_extra_speed
				elseif (class == Classes.enum.DECKHAND) or (class == Classes.enum.BOATSWAIN) or (class == Classes.enum.SHORESMAN) then
					local surfacedata = Surfaces.SurfacesCommon.decode_surface_name(player.surface.name)
					local type = surfacedata.type
					local on_ship_bool = (type == Surfaces.enum.HOLD) or (type == Surfaces.enum.CABIN) or (type == Surfaces.enum.CROWSNEST) or (player.surface.name == memory.boat.surface_name and Boats.on_boat(memory.boat, player.position))
					local hold_bool = (type == Surfaces.enum.HOLD)

					if class == Classes.enum.DECKHAND then
						if on_ship_bool and (not hold_bool) then
							speed_boost = speed_boost * Balance.deckhand_extra_speed
						end
					elseif class == Classes.enum.BOATSWAIN then
						if hold_bool then
							speed_boost = speed_boost * Balance.boatswain_extra_speed
						end
					elseif class == Classes.enum.SHORESMAN then
						if not on_ship_bool then
							speed_boost = speed_boost * Balance.shoresman_extra_speed
						end
					end
				end
			end
			character.character_running_speed_modifier = speed_boost - 1
		end
	end
end

function Public.class_rewards_tick(tickinterval)
	--assuming tickinterval = 7 seconds for now
	local memory = Memory.get_crew_memory()
	local crew = Common.crew_get_crew_members()

	for _, player in pairs(crew) do
		if Common.validate_player_and_character(player) and
			game.tick % tickinterval == 0 and
			memory.classes_table and
			memory.classes_table[player.index]
		then
			local class = memory.classes_table[player.index]

			if not Boats.is_boat_at_sea() and --it is possible to spend infinite time here, so don't give out freebies
				(
					class == Classes.enum.DECKHAND or
					class == Classes.enum.SHORESMAN or
					class == Classes.enum.BOATSWAIN or
					class == Classes.enum.QUARTERMASTER
				)
			then --watch out for this line! (why?)
				local surfacedata = Surfaces.SurfacesCommon.decode_surface_name(player.surface.name)
				local type = surfacedata.type
				local on_ship_bool = (type == Surfaces.enum.HOLD) or (type == Surfaces.enum.CABIN) or (type == Surfaces.enum.CROWSNEST) or (player.surface.name == memory.boat.surface_name and Boats.on_boat(memory.boat, player.position))
				local hold_bool = (type == Surfaces.enum.HOLD)

				if class == Classes.enum.DECKHAND and on_ship_bool and (not hold_bool) then
					Classes.class_ore_grant(player, Balance.deckhand_ore_grant_multiplier, Balance.deckhand_ore_scaling_enabled)
				elseif class == Classes.enum.BOATSWAIN and hold_bool then
					Classes.class_ore_grant(player, Balance.boatswain_ore_grant_multiplier, Balance.boatswain_ore_scaling_enabled)
				elseif class == Classes.enum.SHORESMAN and (not on_ship_bool) then
					Classes.class_ore_grant(player, Balance.shoresman_ore_grant_multiplier, Balance.shoresman_ore_scaling_enabled)
				elseif class == Classes.enum.QUARTERMASTER then
					local nearby_players = #player.surface.find_entities_filtered{position = player.position, radius = Balance.quartermaster_range, name = 'character'}

					if nearby_players > 1 then
						Classes.class_ore_grant(player, nearby_players - 1, Balance.quartermaster_ore_scaling_enabled)
					end
				end
			end

			-- Smoldering class is disabled
			-- if memory.classes_table and memory.classes_table[player.index] then
			-- 	if game.tick % tickinterval == 0 and Common.validate_player_and_character(player) then
			-- 		if memory.classes_table[player.index] == Classes.enum.SMOLDERING then
			-- 			local inv = player.get_inventory(defines.inventory.character_main)
			-- 			if not (inv and inv.valid) then return end
			-- 			local max_coal = 50
			-- 			-- local max_transfer = 1
			-- 			local wood_count = inv.get_item_count('wood')
			-- 			local coal_count = inv.get_item_count('coal')
			-- 			if wood_count >= 1 and coal_count < max_coal then
			-- 				-- local count = Math.min(wood_count, max_coal-coal_count, max_transfer)
			-- 				local count = 1
			-- 				inv.remove({name = 'wood', count = count})
			-- 				inv.insert({name = 'coal', count = count})
			-- 				Common.flying_text_small(player.surface, player.position, '[item=coal]')
			-- 			end
			-- 		end
			-- 	end
			-- end
		end
	end
end

return Public