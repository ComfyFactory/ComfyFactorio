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
local Overworld = require 'maps.pirates.overworld'
local Math = require 'maps.pirates.math'
local inspect = require 'utils.inspect'.inspect

local Quest = require 'maps.pirates.quest'

local Public = {}


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
				else
					character.character_resource_reach_distance_bonus = 0
				end

				character.character_reach_distance_bonus = max_reach_bonus
			end

			local health_boost = 0
			if memory.classes_table and memory.classes_table[player_index] then
				local class = memory.classes_table[player_index]
				if class == Classes.enum.SAMURAI then
					health_boost = health_boost + 225
				end
			end
			if memory.playerindex_captain and memory.playerindex_captain == player_index then
				health_boost = health_boost + 25
			end
			character.character_health_bonus = health_boost

			local speed_boost = Balance.base_extra_character_speed
			if memory.speed_boost_characters and memory.speed_boost_characters[player_index] then
				speed_boost = speed_boost + 0.75
			else
				if memory.classes_table and memory.classes_table[player_index] then
					local class = memory.classes_table[player_index]
					if class == Classes.enum.SCOUT then
						speed_boost = speed_boost + 0.4
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
								speed_boost = speed_boost + 0.05
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
	local memory = Memory.get_crew_memory()

	local crew = Common.crew_get_crew_members()

	for _, player in pairs(crew) do
		if Common.validate_player_and_character(player) then
			local player_index = player.index
			if memory.classes_table and memory.classes_table[player_index] then
				local class = memory.classes_table[player_index]
				if class == Classes.enum.DECKHAND or class == Classes.enum.SHORESMAN or class == Classes.enum.BOATSWAIN then
					local surfacedata = Surfaces.SurfacesCommon.decode_surface_name(player.surface.name)
					local type = surfacedata.type
					local on_ship_bool = type == Surfaces.enum.HOLD or type == Surfaces.enum.CABIN or type == Surfaces.enum.CROWSNEST or (player.surface.name == memory.boat.surface_name and Boats.on_boat(memory.boat, player.position))
					local hold_bool = surfacedata.type == Surfaces.enum.HOLD

					if class == Classes.enum.DECKHAND and on_ship_bool and (not hold_bool) then
						Common.flying_text_small(player.surface, player.position, '[color=0.7,0.8,0.8]+[/color]')
							Common.give_reward_items{{name = 'iron-ore', count = Math.ceil(20 * Balance.class_resource_scale())}}
					elseif class == Classes.enum.BOATSWAIN and hold_bool then
						if Math.random(2) == 2 then
							Common.flying_text_small(player.surface, player.position, '[color=0.85,0.58,0.37]+[/color]')
								Common.give_reward_items{{name = 'copper-ore', count = Math.ceil(30 * Balance.class_resource_scale())}}
						else
							Common.flying_text_small(player.surface, player.position, '[color=0.7,0.8,0.8]+[/color]')
								Common.give_reward_items{{name = 'iron-ore', count = Math.ceil(30 * Balance.class_resource_scale())}}
						end
					elseif class == Classes.enum.SHORESMAN and (not on_ship_bool) then
						Common.flying_text_small(player.surface, player.position, '[color=0.7,0.8,0.8]+[/color]')
							Common.give_reward_items{{name = 'iron-ore', count = Math.ceil(20 * Balance.class_resource_scale())}}
					end
				end
			end
		end
	end
end

return Public