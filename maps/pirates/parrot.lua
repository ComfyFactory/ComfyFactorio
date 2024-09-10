-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


-- local Math = require 'maps.pirates.math'
-- local Memory = require 'maps.pirates.memory'
local _inspect = require 'utils.inspect'.inspect
-- local Token = require 'utils.token'
-- local CoreData = require 'maps.pirates.coredata'
-- local Task = require 'utils.task'
-- local Balance = require 'maps.pirates.balance'
-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'

local Public = {}
local enum = {
	IDLE_FLY = 'idle_fly',
	FLY = 'fly',
	TIP_FLYING_1 = 'tip_flying_1',
	TIP_FLYING_2 = 'tip_flying_2',
	TIP_LANDED_1 = 'tip_landed_1',
	TIP_LANDED_2 = 'tip_landed_2',
	TIP_SQUAWK = 'tip_squawk',
}
Public.enum = enum

-- local parrot_tip_interval = 15*60

Public.framecounts = {
	idle_fly = 5,
	fly = 8,
	fly_right = 8,
	squawk = 6,
	freak = 2,
	walk = 8,
	chill = 1,
}

-- local parrot_tips = {
-- 	"Why not buy the map designer a coffee! ko-fi.com/thesixthroc!",
-- 	"Why not buy the map designer a coffee! ko-fi.com/thesixthroc!",
-- 	"Make suggestions at getcomfy.eu/discord!",
-- 	"Resources granted to the ship appear in the captain's cabin!",
-- 	"On each island after the first, the ship generates ore!",
-- 	"Charge the silo to launch a rocket!",
-- 	"Launching rockets makes fuel and doubloon!",
-- 	"Charging silos makes pollution and evo!",
-- 	"The number of non-afk crewmembers affects pollution, evo and maximum stay time!",
-- 	"Once a silo has launched a rocket, biters will ignore it!",
-- 	"Charging a silo drains power from everything else on the network...",
-- 	"You can steer the boat from the crow's nest by placing 100 rail signals in one of the blue boxes!",
-- 	"When you visit a dock, the shop is updated with special trades!",
-- 	"Labs produce more research the further you've travelled!",
-- 	"On radioactive islands, biters don\'t care if you emit pollution! They only care how long you stay...",
-- 	"If X marks the spot - use inserters to dig!",
-- }

-- function Public.parrot_800_tip()
-- 	local memory = Memory.get_crew_memory()
-- 	Common.parrot_speak(memory.force, 'The resources needed to leave will get a bit harder now...')
-- end
-- function Public.parrot_overstay_tip()
-- 	local memory = Memory.get_crew_memory()
-- 	Common.parrot_speak(memory.force, 'We\'ve been here quite a while! Check the evo.')
-- end

-- function Public.parrot_say_tip()
-- 	local memory = Memory.get_crew_memory()
-- 	local crew_force = memory.force

-- 	local tip = parrot_tips[Math.random(#parrot_tips)]
-- 	Common.parrot_speak(crew_force, tip)
-- end



-- if we're using custom sprites, we have access to this dynamic parrot that flies around:

-- function Public.parrot_tick()
-- 	local memory = Memory.get_crew_memory()

-- 	if not (memory.boat and memory.boat.surface_name) then return end
-- 	local surface = game.surfaces[memory.boat.surface_name]
-- 	if not surface and surface.valid then return end
-- 	local destination = Common.current_destination()

-- 	if destination.dynamic_data and destination.dynamic_data.timer and destination.dynamic_data.timer == Math.ceil(Balance.expected_time_on_island()) and (not destination.dynamic_data.parrot_gave_overstay_tip) then
-- 		destination.dynamic_data.parrot_gave_overstay_tip = true

-- 		local spawners = surface.find_entities_filtered({type = 'unit-spawner', force = memory.enemy_force_name})
-- 		local spawnerscount = #spawners or 0
-- 		if spawnerscount > 0 then --check biter bases actually exist
-- 			Public.parrot_overstay_tip()
-- 		end
-- 	end

-- 	local boat = memory.boat
-- 	local parrot = boat.parrot
-- 	local frame = parrot.frame
-- 	local render = parrot.render
-- 	local render_name = parrot.render_name
-- 	local state = parrot.state
-- 	local state_counter = parrot.state_counter or parrot_tip_interval*60/5
-- 	local resting_position_relative_to_boat = parrot.resting_position_relative_to_boat
-- 	local position_relative_to_boat = parrot.position_relative_to_boat
-- 	local sprite_extra_offset = boat.parrot.sprite_extra_offset
-- 	local text_extra_offset = boat.parrot.text_extra_offset
-- 	local real_position = Utils.psum{position_relative_to_boat, boat.position}

-- 	if state == enum.IDLE_FLY then
-- 		local ate_fish

-- 		if boat.state and boat.state == 'landed' and state_counter >= parrot_tip_interval*60/5 then
-- 			local nearby_characters = surface.find_entities_filtered{position = real_position, radius = 4, name = 'character'}
-- 			local nearby_characters_count = #nearby_characters
-- 			if nearby_characters_count > 0 then
-- 				local j = 1
-- 				while j <= nearby_characters_count do
-- 					if nearby_characters[j] and nearby_characters[j].valid and nearby_characters[j].player and Common.validate_player(nearby_characters[j].player) then
-- 						local player = nearby_characters[j].player
-- 						local inv = player.get_inventory(defines.inventory.character_main)
-- 						if inv and inv.get_item_count('raw-fish') >= 2 then
-- 							Common.give(player, {{name = 'raw-fish', count = -2, color = CoreData.colors.fish}})
-- 							ate_fish = true
-- 							break
-- 						end
-- 					end
-- 					j = j + 1
-- 				end
-- 			end
-- 		end
-- 		state_counter = state_counter + 1

-- 		if ate_fish then
-- 			Common.parrot_speak(memory.force, 'Tasty...')

-- 			local p1 = {x = boat.position.x - 15 - Math.random(35), y = boat.position.y - 8 + Math.random(15)}
-- 			local p2 = surface.find_non_colliding_position('stone-furnace', p1, 6, 0.5)

-- 			parrot.spot_to_fly_from = position_relative_to_boat
-- 			local real_fly_to = p2 or p1
-- 			parrot.spot_to_fly_to = {x = real_fly_to.x - boat.position.x, y = real_fly_to.y - boat.position.y}
-- 			parrot.fly_distance = Math.distance(parrot.spot_to_fly_from, parrot.spot_to_fly_to)
-- 			state = enum.TIP_FLYING_1
-- 			state_counter = 0
-- 		else
-- 			if game.tick % 10 == 0 then
-- 				frame = frame + 1
-- 			end

-- 			if boat.speed and boat.speed > 0 then
-- 				state = enum.FLY
-- 			end
-- 		end

-- 	elseif state == enum.TIP_FLYING_1 then

-- 		if boat.speed and boat.speed > 0 then
-- 			state_counter = 0
-- 			state = enum.IDLE_FLY
-- 			position_relative_to_boat = resting_position_relative_to_boat
-- 		else
-- 			if game.tick % 10 == 0 then
-- 				frame = frame + 1
-- 			end

-- 			if state_counter < parrot.fly_distance then
-- 				position_relative_to_boat = Utils.interpolate(parrot.spot_to_fly_from, parrot.spot_to_fly_to, state_counter/parrot.fly_distance)
-- 				state_counter = state_counter + 0.5
-- 			else
-- 				state_counter = 0
-- 				state = enum.TIP_LANDED_1
-- 			end
-- 		end

-- 	elseif state == enum.TIP_LANDED_1 then

-- 		if boat.speed and boat.speed > 0 then
-- 			state_counter = 0
-- 			state = enum.IDLE_FLY
-- 			position_relative_to_boat = resting_position_relative_to_boat
-- 		else
-- 			if state_counter < 20 then
-- 				state_counter = state_counter + 1
-- 			else
-- 				state_counter = 0
-- 				state = enum.TIP_SQUAWK
-- 			end
-- 		end

-- 	elseif state == enum.TIP_SQUAWK then

-- 		if boat.speed and boat.speed > 0 then
-- 			state_counter = 0
-- 			state = enum.IDLE_FLY
-- 			position_relative_to_boat = resting_position_relative_to_boat
-- 		else
-- 			if state_counter == 0 then
-- 				Public.parrot_say_tip()
-- 			end

-- 			if state_counter < 18 then
-- 				if game.tick % 15 == 0 then
-- 					frame = frame + 1
-- 				end
-- 				state_counter = state_counter + 1
-- 			else
-- 				state_counter = 0
-- 				state = enum.TIP_LANDED_2
-- 			end
-- 		end

-- 	elseif state == enum.TIP_LANDED_2 then

-- 		if boat.speed and boat.speed > 0 then
-- 			state_counter = 0
-- 			state = enum.IDLE_FLY
-- 			position_relative_to_boat = resting_position_relative_to_boat
-- 		else
-- 			if state_counter < 20 then
-- 				state_counter = state_counter + 1
-- 			else
-- 				state_counter = 0
-- 				state = enum.TIP_FLYING_2
-- 				local hold = parrot.spot_to_fly_to
-- 				parrot.spot_to_fly_to = parrot.spot_to_fly_from
-- 				parrot.spot_to_fly_from = hold
-- 			end
-- 		end

-- 	elseif state == enum.TIP_FLYING_2 then

-- 		if boat.speed and boat.speed > 0 then
-- 			state_counter = 0
-- 			state = enum.IDLE_FLY
-- 			position_relative_to_boat = resting_position_relative_to_boat
-- 		else
-- 			if game.tick % 10 == 0 then
-- 				frame = frame + 1
-- 			end

-- 			if state_counter < parrot.fly_distance then
-- 				position_relative_to_boat = Utils.interpolate(parrot.spot_to_fly_from, parrot.spot_to_fly_to, state_counter/parrot.fly_distance)
-- 				state_counter = state_counter + 0.5
-- 			else
-- 				state_counter = 0
-- 				state = enum.IDLE_FLY
-- 			end
-- 		end

-- 	elseif state == enum.FLY then

-- 		if game.tick % 10 == 0 then
-- 			frame = frame + 1
-- 		end

-- 		if (not boat.speed) or (boat.speed == 0) then state = enum.IDLE_FLY end
-- 	end

-- 	local sprite_name = state
-- 	if state == enum.TIP_FLYING_1 then sprite_name = 'fly' end
-- 	if state == enum.TIP_FLYING_2 then sprite_name = 'fly_right' end
-- 	if state == enum.TIP_LANDED_1 or state == enum.TIP_LANDED_2 then sprite_name = 'chill' end
-- 	if state == enum.TIP_SQUAWK then sprite_name = 'squawk' end

-- 	if frame > Public.framecounts[sprite_name] then frame = 1 end
-- 	parrot.state = state
-- 	parrot.frame = frame
-- 	parrot.state_counter = state_counter
-- 	parrot.position_relative_to_boat = position_relative_to_boat

-- 	rendering.set_sprite(render, "file/parrot/parrot_" .. sprite_name .. "_" .. frame .. ".png")
-- 	rendering.set_target(render, rendering.get_target(render).entity, Utils.psum{sprite_extra_offset, position_relative_to_boat})
-- 	rendering.set_visible(render, true)
-- 	rendering.set_target(render_name, rendering.get_target(render_name).entity, Utils.psum{text_extra_offset, position_relative_to_boat})
-- 	rendering.set_visible(render_name, true)
-- end

return Public