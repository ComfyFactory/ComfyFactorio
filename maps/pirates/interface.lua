
local boats = require "maps.pirates.structures.boats.boats"
local simplex_noise = require "utils.simplex_noise"

local Memory = require 'maps.pirates.memory'
local Balance = require 'maps.pirates.balance'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local inspect = require 'utils.inspect'.inspect
local Ai = require 'maps.pirates.ai'
local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Progression = require 'maps.pirates.progression'
local Islands = require 'maps.pirates.surfaces.islands.islands'
local Roles = require 'maps.pirates.roles.roles'
local Gui = require 'maps.pirates.gui.gui'
local Sea = require 'maps.pirates.surfaces.sea.sea'
local Hold = require 'maps.pirates.surfaces.hold'
local Cabin = require 'maps.pirates.surfaces.cabin'
local Crowsnest = require 'maps.pirates.surfaces.crowsnest'
local Ores = require 'maps.pirates.ores'
local Parrot = require 'maps.pirates.parrot'
local Kraken = require 'maps.pirates.surfaces.sea.kraken'

local Jailed = require 'utils.datastore.jail_data'

local Crew = require 'maps.pirates.crew'
local Quest = require 'maps.pirates.quest'
local Shop = require 'maps.pirates.shop.shop'
local Loot = require 'maps.pirates.loot'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Classes = require 'maps.pirates.roles.classes'

local Server = require 'utils.server'
-- local Modifers = require 'player_modifiers'

local tick_tack_trap = require 'maps.pirates.from_comfy.tick_tack_trap' --'enemy' force, but that's okay

local Public = {}

function Public.silo_died()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local force = memory.force
	if memory.game_lost == true then return end

	destination.dynamic_data.rocketsilohp = 0
	if destination.dynamic_data.rocketsilos and destination.dynamic_data.rocketsilos[1] and destination.dynamic_data.rocketsilos[1].valid then
		local surface = destination.dynamic_data.rocketsilos[1].surface
		surface.create_entity({name = 'big-artillery-explosion', position = destination.dynamic_data.rocketsilos[1].position})

		if memory.boat and memory.boat.surface_name and surface.name == memory.boat.surface_name then
			
			if CoreData.rocket_silo_death_causes_loss then
				-- Crew.lose_life()
				Crew.try_lose('silo destroyed')
			elseif (not destination.dynamic_data.rocketlaunched) and destination.static_params and destination.static_params.base_cost_to_undock and destination.static_params.base_cost_to_undock['launch_rocket'] and destination.static_params.base_cost_to_undock['launch_rocket'] == true then
				Crew.try_lose('silo destroyed before a necessary launch')
			elseif (not destination.dynamic_data.rocketlaunched) then
				Common.notify_force(force, 'The silo was destroyed.')
			end
		end

		destination.dynamic_data.rocketsilos[1].destroy()
		destination.dynamic_data.rocketsilos = nil
	end
end

function Public.damage_silo(final_damage_amount)
	if final_damage_amount == 0 then return end
	local destination = Common.current_destination()
	local memory = Memory.get_crew_memory()

	-- if we are doing the 'no damage' quest, then damage in the first 20 seconds after landing doesn't count:
	if destination and destination.dynamic_data and destination.dynamic_data.quest_type == Quest.enum.NODAMAGE then
		if not (destination.dynamic_data.timer and destination.dynamic_data.timeratlandingtime and destination.dynamic_data.timer > destination.dynamic_data.timeratlandingtime + 20) then return end
	end

	-- manual 'resistance:'
	local final_damage_amount2 = Utils.deepcopy(final_damage_amount) / 5
	
	destination.dynamic_data.rocketsilohp = Math.max(0, Math.floor(destination.dynamic_data.rocketsilohp - final_damage_amount2))
	if destination.dynamic_data.rocketsilohp > destination.dynamic_data.rocketsilomaxhp then destination.dynamic_data.rocketsilohp = destination.dynamic_data.rocketsilomaxhp end

	if destination.dynamic_data.rocketsilohp <= 0 then
	-- if destination.dynamic_data.rocketsilohp <= 0 and (not destination.dynamic_data.rocketlaunched) then
		Public.silo_died()
		rendering.destroy(destination.dynamic_data.rocketsilohptext)
	else
		rendering.set_text(destination.dynamic_data.rocketsilohptext, 'HP: ' .. destination.dynamic_data.rocketsilohp .. ' / ' .. destination.dynamic_data.rocketsilomaxhp)
	end
	-- if destination.dynamic_data.rocketsilohp < destination.dynamic_data.rocketsilomaxhp / 2 and final_damage_amount > 0 then
	-- 	Upgrades.trigger_poison()
	-- end
end


local function biters_chew_stuff_faster(event)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	if not (event.cause and event.cause.valid and event.cause.force and event.cause.force.name and event.entity and event.entity.valid and event.entity.force and event.entity.force.name) then return end
	if string.sub(event.cause.force.name, 1, 5) ~= 'enemy' then return end --Enemy Forces only

	if (event.entity.force.index == 3 or event.entity.force.name == 'environment') then
		event.entity.health = event.entity.health - event.final_damage_amount * 5
		if destination and destination.type and destination.subtype and destination.type == Surfaces.enum.ISLAND and destination.subtype == Islands.enum.MAZE then
			event.entity.health = event.entity.health - event.final_damage_amount * 10
		end
	elseif event.entity.name == 'pipe' then
		event.entity.health = event.entity.health - event.final_damage_amount * 0.5
	elseif event.entity.name == 'stone-furnace' then
		event.entity.health = event.entity.health - event.final_damage_amount * 0.5
	elseif event.entity.name == 'wooden-chest' or event.entity.name == 'stone-chest' or event.entity.name == 'steel-chest' then
		event.entity.health = event.entity.health - event.final_damage_amount * 0.5
	end
end



local function event_on_player_repaired_entity(event)
	local entity = event.entity

	if entity and entity.valid and entity.name and entity.name == 'artillery-turret' then
		entity.health = entity.health - 2 --prevents repairing
	end
	--@TODO: somehow fix the fact that drones can repair the turret
end


local function silo_damage(event)
	local memory = Memory.get_crew_memory()

	if event.cause and event.cause.valid and event.entity and event.entity.valid then
		if event.entity.force.name == memory.force_name then
			local surfacedata = Surfaces.SurfacesCommon.decode_surface_name(event.entity.surface.name)
			local dest = Common.current_destination()
			if surfacedata.type == Surfaces.enum.CROWSNEST or surfacedata.type == Surfaces.enum.LOBBY then
				event.entity.health = event.entity.health + event.final_damage_amount
			elseif dest.dynamic_data.rocketsilos and dest.dynamic_data.rocketsilos[1] and dest.dynamic_data.rocketsilos[1].valid and event.entity == Common.current_destination().dynamic_data.rocketsilos[1] then
				event.entity.health = event.entity.health + event.final_damage_amount
				if string.sub(event.cause.force.name, 1, 4) ~= 'crew' then
					Public.damage_silo(event.original_damage_amount)
				end
			end
		end
	end
end


local function damage_to_enemyboat_spawners(event)
	local memory = Memory.get_crew_memory()

	if memory.enemyboats and #memory.enemyboats > 0 then
		if event.cause and event.cause.valid and event.entity and event.entity.valid then
			if event.entity.force.name == memory.enemy_force_name then
				for i = 1, #memory.enemyboats do
					local eb = memory.enemyboats[i]
					if eb.spawner and eb.spawner.valid and event.entity == eb.spawner then
					-- if eb.spawner and eb.spawner.valid and event.entity == eb.spawner and eb.state == Structures.Boats.enum_state.APPROACHING then
						local damage = event.final_damage_amount
						local adjusted_damage = damage

						adjusted_damage = adjusted_damage / 3

						if event.cause.name == 'artillery-turret' then
							adjusted_damage = adjusted_damage / 1.8
						end

						if Common.entity_damage_healthbar(event.entity, adjusted_damage) < 0 then
							event.entity.die()
						end
					end
				end
			end
		end
	end
end

local function damage_to_artillery(event)
	local memory = Memory.get_crew_memory()

	if not (event.entity and event.entity.valid and event.entity.name and event.entity.name == 'artillery-turret') then return end
	if not event.cause then return end
	if not event.cause.valid then return end
	if not event.cause.name then return end

	if (event.cause.name == 'small-biter') or (event.cause.name == 'small-spitter') or (event.cause.name == 'medium-biter') or (event.cause.name == 'medium-spitter') or (event.cause.name == 'big-biter') or (event.cause.name == 'big-spitter') or (event.cause.name == 'behemoth-biter') or (event.cause.name == 'behemoth-spitter') then
		if string.sub(event.cause.force.name, 1, 5) ~= 'enemy' then return end
		-- remove resistances:
		event.entity.health = event.entity.health + event.final_damage_amount - event.original_damage_amount
	else
		event.entity.health = event.entity.health + event.final_damage_amount --nothing else should damage it
	end
end

local function damage_to_krakens(event)

	if not (event.entity and event.entity.valid and event.entity.name and event.entity.name == 'biter-spawner') then return end

	if string.sub(event.entity.force.name, 1, 5) ~= 'enemy' then
		return
	end

	if not event.cause then return end
	if not event.cause.valid then return end
	if not event.cause.name then return end

	local memory = Memory.get_crew_memory()

	local surface_name = memory.boat and memory.boat.surface_name
	if not (surface_name == memory.sea_name) then return end

    local unit_number = event.entity.unit_number
	local damage = event.final_damage_amount
	local adjusted_damage = damage

	if event.damage_type.name and event.damage_type.name == 'poison' then
	-- if event.cause.name == 'artillery-turret' then
		adjusted_damage = adjusted_damage / 1.25
	elseif event.damage_type.name and (event.damage_type.name == 'explosion') then
		adjusted_damage = adjusted_damage / 1.5
	elseif event.damage_type.name and (event.damage_type.name == 'fire') then
		adjusted_damage = adjusted_damage / 1.25
	end
	-- and additionally:
	if event.cause.name == 'artillery-turret' then
		adjusted_damage = adjusted_damage / 1.1
	end

	if event.damage_type.name and (event.damage_type.name == 'laser') then
		adjusted_damage = adjusted_damage / 8 --laser turrets are in range
	end

	if Common.entity_damage_healthbar(event.entity, adjusted_damage) < 0 then
		Kraken.kraken_die(memory.healthbars[unit_number].id)
	end
end




local function damage_to_players_changes(event)
	local memory = Memory.get_crew_memory()

	if not (event.entity and event.entity.valid and event.entity.name and event.entity.name == 'character') then return end
	if not event.cause then return end
	if not event.cause.valid then return end
	if not event.cause.name then return end

	-- if not (event.cause.name == 'small-biter') or (event.cause.name == 'small-spitter') or (event.cause.name == 'medium-biter') or (event.cause.name == 'medium-spitter') or (event.cause.name == 'big-biter') or (event.cause.name == 'big-spitter') or (event.cause.name == 'behemoth-biter') or (event.cause.name == 'behemoth-spitter') then return end
	-- if string.sub(event.cause.force.name, 1, 5) ~= 'enemy' then return end --Enemy Forces

	local player_index = event.entity.player.index
	local class = memory.classes_table and memory.classes_table[player_index]

	local damage_multiplier = 1

	if event.damage_type.name == 'poison' then --make all poison damage stronger
		damage_multiplier = damage_multiplier * 1.5
	else
		if class and class == Classes.enum.SCOUT then
			damage_multiplier = damage_multiplier * 1.25
		-- elseif class and class == Classes.enum.MERCHANT then
		-- 	damage_multiplier = damage_multiplier * 1.10
		elseif class and class == Classes.enum.SAMURAI then
			damage_multiplier = damage_multiplier * 0.25
		elseif class and class == Classes.enum.HATAMOTO then --lethal damage needs to be unaffected
			damage_multiplier = damage_multiplier * 0.16
		elseif class and class == Classes.enum.IRON_LEG then --lethal damage needs to be unaffected
			local inv = event.entity.get_inventory(defines.inventory.character_main)
			if not (inv and inv.valid) then return end
			local count = inv.get_item_count('iron-ore')
			if count and count >= 3500 then
				damage_multiplier = damage_multiplier * 0.14
			end
		else
			damage_multiplier = damage_multiplier * (1 + Balance.bonus_damage_to_humans())
		end
	end


	if damage_multiplier > 1 then
		event.entity.health = event.entity.health - event.final_damage_amount * (damage_multiplier - 1)
	elseif damage_multiplier < 1 and event.final_health > 0 then --lethal damage needs to be unaffected, else they never die
		event.entity.health = event.entity.health + event.final_damage_amount * (1 - damage_multiplier)
	end
end


local function damage_dealt_by_players_changes(event)
	local memory = Memory.get_crew_memory()

	if not event.cause then return end
	if not event.cause.valid then return end
	if not event.entity.valid then return end
	if event.cause.name ~= 'character' then return end

	local character = event.cause
	local player = character.player

	local physical = event.damage_type.name == 'physical'
	local acid = event.damage_type.name == 'acid'

	local player_index = player.index
	local class = memory.classes_table and memory.classes_table[player_index]

	if class and class == Classes.enum.SCOUT and event.final_health > 0 then --lethal damage must be unaffected
		event.entity.health = event.entity.health + 0.4 * event.final_damage_amount
	elseif class and (class == Classes.enum.SAMURAI or class == Classes.enum.HATAMOTO) then
		local samurai = memory.classes_table[player_index] == Classes.enum.SAMURAI
		local hatamoto = memory.classes_table[player_index] == Classes.enum.HATAMOTO

		--==Note this!
		if not (samurai or hatamoto) then return end

		local no_weapon = (not (character.get_inventory(defines.inventory.character_guns) and character.get_inventory(defines.inventory.character_guns)[character.selected_gun_index] and character.get_inventory(defines.inventory.character_guns)[character.selected_gun_index].valid_for_read))

		local melee = (physical or acid) and no_weapon

		local extra_damage_to_deal = 0

		local big_number = 1000

		if melee and event.final_health > 0 then
			if physical then
				if samurai then
					extra_damage_to_deal = 30
				elseif hatamoto then
					extra_damage_to_deal = 50
				end
			elseif acid then --this hacky stuff is to implement repeated spillover splash damage, whilst getting around the fact that if ovekill damage takes something to zero health, we can't tell in that event how much double-overkill damage should be dealt by reading off its HP. it assumes that characters only deal acid damage via this function.
				extra_damage_to_deal = event.original_damage_amount * big_number
			end
		elseif (not melee) and event.final_health > 0 then
			if samurai or hatamoto then
				event.entity.health = event.entity.health + 0.25 * event.final_damage_amount
			end
		end

		if extra_damage_to_deal > 0 then
			if event.entity.health >= extra_damage_to_deal then
				event.entity.health = event.entity.health - extra_damage_to_deal
			else
				local surplus = (extra_damage_to_deal - event.entity.health)*0.8
				event.entity.die(character.force, character)
				local nearest = player.surface.find_nearest_enemy{position = player.position, max_distance = 2, force = player.force}
				if nearest and nearest.valid then
					nearest.damage(surplus/big_number, character.force, 'acid', character)
				end
			end
		end
	end

	if physical then

		-- QUARTERMASTER BUFFS
		local nearby_players = player.surface.find_entities_filtered{position = player.position, radius = Common.quartermaster_range, type = {'character'}}
	
		for _, p2 in pairs(nearby_players) do
			if p2.player and p2.player.valid then
				local p2_index = p2.player.index
				if player_index ~= p2_index and memory.classes_table[p2_index] and memory.classes_table[p2_index] == Classes.enum.QUARTERMASTER then
					event.entity.damage(0.1 * event.final_damage_amount, character.force, 'impact', character) --triggers this function again, but not physical this time
				end
			end
		end


		-- PISTOL BUFFS
		if character.shooting_state.state ~= defines.shooting.not_shooting then
			local weapon = character.get_inventory(defines.inventory.character_guns)[character.selected_gun_index]
			local ammo = character.get_inventory(defines.inventory.character_ammo)[character.selected_gun_index]
			if weapon.valid_for_read and ammo.valid_for_read and weapon.name == 'pistol' and (ammo.name == 'firearm-magazine' or ammo.name == 'piercing-rounds-magazine' or ammo.name == 'uranium-rounds-magazine') then
				event.entity.damage(event.final_damage_amount * (Balance.pistol_damage_multiplier() - 1), character.force, 'impact', character) --triggers this function again, but not physical this time
			end
		end
	end
end



local function swamp_resist_poison(event)
	local memory = Memory.get_crew_memory()

	local entity = event.entity
	if not entity.valid then return end

	if not (event.damage_type.name and event.damage_type.name == 'poison') then return end

	local destination = Common.current_destination()
	if not (destination and destination.subtype and destination.subtype == Islands.enum.SWAMP) then return end
	
	if not (destination.surface_name == entity.surface.name) then return end

	if not ((entity.type and entity.type == 'tree') or (event.entity.force and string.sub(event.entity.force.name, 1, 5) == 'enemy')) then return end

	local damage = event.final_damage_amount
	event.entity.health = event.entity.health + damage
end


local function maze_walls_resistance(event)
	local memory = Memory.get_crew_memory()

	local entity = event.entity
	if not entity.valid then return end

	local destination = Common.current_destination()
	if not (destination and destination.subtype and destination.subtype == Islands.enum.MAZE) then return end
	
	if not (destination.surface_name == entity.surface.name) then return end

	if not ((entity.type and entity.type == 'tree') or entity.name == 'rock-huge' or entity.name == 'rock-big' or entity.name == 'sand-rock-big') then return end

	local damage = event.final_damage_amount

	if (event.damage_type.name and (event.damage_type.name == 'explosion' or event.damage_type.name == 'poison')) then
		event.entity.health = event.entity.health + damage
	elseif event.damage_type.name and event.damage_type.name == 'fire' then
		-- put out forest fires:
		for _, e2 in pairs(entity.surface.find_entities_filtered({area = {{entity.position.x - 4, entity.position.y - 4},{entity.position.x + 4, entity.position.y + 4}}, name = "fire-flame-on-tree"})) do
			if e2.valid then e2.destroy() end
		end
	else
		if string.sub(event.cause.force.name, 1, 4) == 'crew' then --player damage only
			event.entity.health = event.entity.health + damage * 0.9
		end
	end
end


local function event_on_entity_damaged(event)

	-- figure out which crew this is about:
	local crew_id = nil
	if not crew_id and event.entity.surface.valid then crew_id = tonumber(string.sub(event.entity.surface.name, 1, 3)) or nil end
	if not crew_id and event.force.valid then crew_id = tonumber(string.sub(event.force.name, -3, -1)) or nil end
	if not crew_id and event.entity.valid then crew_id = tonumber(string.sub(event.entity.force.name, -3, -1)) or nil end
	Memory.set_working_id(crew_id)

	local memory = Memory.get_crew_memory()
	local difficulty = memory.difficulty
	
	if not event.entity.valid then return end
	silo_damage(event)
	if not event.entity.valid then return end -- need to call again, silo might be dead
	if not event.entity.health then return end
	
	damage_to_players_changes(event)
	
	damage_to_enemyboat_spawners(event)
	biters_chew_stuff_faster(event)
	damage_to_artillery(event)
	swamp_resist_poison(event)
	maze_walls_resistance(event)
	damage_to_krakens(event)

	damage_dealt_by_players_changes(event)

	-- if string.sub(event.entity.force.name, 1, 5) == 'enemy' then
	-- 	-- Balance.biter_immunities(event)
	-- end
end




function Public.biter_immunities(event)
	local memory = Memory.get_crew_memory()
	-- local planet = memory.planet[1].type.id
	-- if event.damage_type.name == 'fire' then
	-- 	if planet == 14 then --lava planet
	-- 		event.entity.health = event.entity.health + event.final_damage_amount
	-- 		local fire = event.entity.stickers
	-- 		if fire and #fire > 0 then
	-- 			for i = 1, #fire, 1 do
	-- 				if fire[i].sticked_to == event.entity and fire[i].name == 'fire-sticker' then fire[i].destroy() break end
	-- 			end
	-- 		end
	-- 	-- else -- other planets
	-- 	-- 	event.entity.health = Math.floor(event.entity.health + event.final_damage_amount - (event.final_damage_amount / (1 + 0.02 * memory.difficulty * memory.chronojumps)))
	-- 	end
	-- elseif event.damage_type.name == 'poison' then
	-- 	if planet == 18 then --swamp planet
	-- 		event.entity.health = event.entity.health + event.final_damage_amount
	-- 	end
	-- end
end




function Public.load_some_map_chunks(destination_index, fraction, force_load) --in a 'spear' from the left
	--WARNING: if force_load is true, THIS DOES NOT PLAY NICELY WITH DELAYED TASKS. log(inspect{global_memory.working_id}) was observed to vary before and after this function.
	force_load = force_load or false

	local memory = Memory.get_crew_memory()

	local destination_data = memory.destinations[destination_index]
	if not destination_data then return end
	local surface_name = destination_data.surface_name
	if not surface_name then return end
	local surface = game.surfaces[surface_name]
	if not surface then return end

	local w, h = surface.map_gen_settings.width, surface.map_gen_settings.height
	local c = {x = 0, y = 0}
	if destination_data.static_params and destination_data.static_params.islandcenter_position then
		c = destination_data.static_params.islandcenter_position
		w = w - 2 * Math.abs(c.x)
		h = h - 2 * Math.abs(c.y)
	end
	local l = Math.max(Math.floor(w/32), Math.floor(h/32))
	
	local i, j, s = 0, 0, {x = 0, y = 0}
	while i < 4*l^2 and j <= fraction * w/32*h/32 do
		i = i + 1

		if s.y < 0 then
			s.y = -s.y
		elseif s.y > 0 then
			s = {x = s.x + 1, y = 1 - s.y}
		else
			s = {x = 0, y = - (s.x + 1)}
		end

		if s.x <= w/32 and s.y <= h/32/2 and s.y >= -h/32/2 then
			surface.request_to_generate_chunks({x = c.x - w/2 + 32*s.x, y = c.y + 32*s.y}, 0.1)
			j = j + 1
		end
	end
	if force_load then
		surface.force_generate_chunk_requests() --WARNING: THIS DOES NOT PLAY NICELY WITH DELAYED TASKS. log(inspect{global_memory.working_id}) was observed to vary before and after this function.
	end
end






function Public.load_some_map_chunks_random_order(destination_index, fraction)
	local memory = Memory.get_crew_memory()

	local destination_data = memory.destinations[destination_index]
	if not destination_data then return end
	local surface_name = destination_data.surface_name
	if not surface_name then return end
	local surface = game.surfaces[surface_name]
	if not surface then return end

	local shuffled_chunks
	if not destination_data.dynamic_data then destination_data.dynamic_data = {} end
	if not destination_data.dynamic_data.shuffled_chunks then

		local w, h = surface.map_gen_settings.width, surface.map_gen_settings.height
		local c = {x = 0, y = 0}
		if destination_data.static_params and destination_data.static_params.islandcenter_position then
			c = destination_data.static_params.islandcenter_position
			w = w - 2 * Math.abs(c.x)
			h = h - 2 * Math.abs(c.y)
		end
	
		local chunks_list = {}
		for i = 0, Math.ceil(w/32 - 1), 1 do
			for j = 0, Math.ceil(h/32 - 1), 1 do
				table.insert(chunks_list, {x = c.x - w/2 + 32*i, y = c.y - h/2 + 32*j})
			end
		end
	
		destination_data.dynamic_data.shuffled_chunks = Math.shuffle(chunks_list)
	end
	shuffled_chunks = destination_data.dynamic_data.shuffled_chunks

	for i = 1, #shuffled_chunks do
		if i > fraction * #shuffled_chunks then
			break
		end
		surface.request_to_generate_chunks(shuffled_chunks[i], 0.2)
	end
end






local function event_pre_player_mined_item(event)
	-- figure out which crew this is about:
	local crew_id = nil
	if event.player_index and game.players[event.player_index].valid then crew_id = tonumber(string.sub(game.players[event.player_index].force.name, -3, -1)) or nil end
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	
	-- if memory.planet[1].type.id == 11 then --rocky planet
	-- 	if event.entity.name == 'rock-huge' or event.entity.name == 'rock-big' or event.entity.name == 'sand-rock-big' then
	-- 		Event_functions.trap(event.entity, false)
	-- 		event.entity.destroy()
	-- 		Event_functions.rocky_loot(event)
	-- 	end
	-- end
end

local function event_on_player_mined_entity(event)
	if not event.player_index then return end
	local player = game.players[event.player_index]
	if not game.players[event.player_index].valid then return end
	local crew_id = tonumber(string.sub(game.players[event.player_index].force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local entity = event.entity
	if not entity.valid then return end

	if player.surface.name == 'gulag' then
		event.buffer.clear()
		return
	end
	
    if entity.type == 'tree' then
        if not event.buffer then return end
		local available = destination.dynamic_data.wood_remaining
		local starting = destination.static_params.starting_wood
		
		if available and destination.type == Surfaces.enum.ISLAND then

			if destination and destination.subtype and destination.subtype == Islands.enum.MAZE then
				if Math.random(1, 35) == 1 then
					tick_tack_trap(memory.enemy_force_name, entity.surface, entity.position)
					return
				end

				local give = {}
				if memory.classes_table and memory.classes_table[event.player_index] then
					if memory.classes_table[event.player_index] == Classes.enum.LUMBERJACK then
						if Math.random(7) == 1 then
							give[#give + 1] = {name = 'coin', count = 15}
						end
					elseif memory.classes_table[event.player_index] == Classes.enum.WOOD_LORD then
						give[#give + 1] = {name = 'iron-ore', count = 2}
						give[#give + 1] = {name = 'copper-ore', count = 2}
						give[#give + 1] = {name = 'coal', count = 2}
						if Math.random(7) == 1 then
							give[#give + 1] = {name = 'coin', count = 15}
						end
					end
				end

				if #give > 0 then
					Common.give(player, give, entity.position)
				end
			else
				local give = {}
	
				local baseamount = 4
				--minimum 1 wood
				local amount = Math.max(Math.ceil(Math.min(available, baseamount * available/starting)),1)
				destination.dynamic_data.wood_remaining = destination.dynamic_data.wood_remaining - amount
	
				if memory.classes_table and memory.classes_table[event.player_index] and memory.classes_table[event.player_index] == Classes.enum.LUMBERJACK then
					give[#give + 1] = {name = 'wood', count = amount + 3}
					if Math.random(7) == 1 then
						give[#give + 1] = {name = 'coin', count = 15}
					end
				elseif memory.classes_table and memory.classes_table[event.player_index] and memory.classes_table[event.player_index] == Classes.enum.WOOD_LORD then
					give[#give + 1] = {name = 'wood', count = amount + 3}
					give[#give + 1] = {name = 'iron-ore', count = 1}
					give[#give + 1] = {name = 'copper-ore', count = 1}
					give[#give + 1] = {name = 'coal', count = 1}
					if Math.random(7) == 1 then
						give[#give + 1] = {name = 'coin', count = 15}
					end
				else
					give[#give + 1] = {name = 'wood', count = amount}
					if Math.random(7) == 1 then --tuned
						give[#give + 1] = {name = 'coin', count = 5}
					end
				end
	
				Common.give(player, give, entity.position)
			end
		end
		event.buffer.clear()
	
	elseif entity.type == 'fish' then
        if not event.buffer then return end


		if memory.classes_table and memory.classes_table[event.player_index] and memory.classes_table[event.player_index] == Classes.enum.MASTER_ANGLER then
			Common.give(player, {{name = 'raw-fish', count = 4}, {name = 'coin', count = 8}}, entity.position)
		elseif memory.classes_table and memory.classes_table[event.player_index] and memory.classes_table[event.player_index] == Classes.enum.DREDGER then
			local to_give = {{name = 'raw-fish', count = 4}}
			to_give[#to_give + 1] = Loot.dredger_loot()[1]
			Common.give(player, to_give, entity.position)
		else
			Common.give(player, {{name = 'raw-fish', count = 3}}, entity.position)
		end
		
		event.buffer.clear()
	
	elseif entity.name == 'coal' or entity.name == 'stone' or entity.name == 'copper-ore' or entity.name == 'iron-ore' then
        if not event.buffer then return end

		local give = {}

		if memory.overworldx > 0 then
			if memory.classes_table and memory.classes_table[event.player_index] and memory.classes_table[event.player_index] == Classes.enum.PROSPECTOR then
				give[#give + 1] = {name = 'coin', count = 3}
				give[#give + 1] = {name = entity.name, count = 6}
			elseif memory.classes_table and memory.classes_table[event.player_index] and memory.classes_table[event.player_index] == Classes.enum.CHIEF_EXCAVATOR then
				give[#give + 1] = {name = 'coin', count = 4}
				give[#give + 1] = {name = entity.name, count = 12}
			else
				if memory.overworldx > 0 then
					give[#give + 1] = {name = 'coin', count = 1}
				end
				give[#give + 1] = {name = entity.name, count = 2}
			end
		else
			give[#give + 1] = {name = entity.name, count = 2}
		end

		Common.give(player, give, entity.position)
		event.buffer.clear()
	
	elseif entity.name == 'rock-huge' or entity.name == 'rock-big' or entity.name == 'sand-rock-big' then
        if not event.buffer then return end

		local available = destination.dynamic_data.rock_material_remaining
		local starting = destination.static_params.starting_rock_material

		if available and destination.type == Surfaces.enum.ISLAND then

			if destination and destination.subtype and destination.subtype == Islands.enum.MAZE then
				if Math.random(1, 35) == 1 then
					tick_tack_trap(memory.enemy_force_name, entity.surface, entity.position)
					return
				end
			else
				local c = event.buffer.get_contents()
				table.sort(c, function(a,b) return a.name < b.name end)
				local c2 = {}
	
				if memory.overworldx >= 0 then --used to be only later levels
					if entity.name == 'rock-huge' then
						c2[#c2 + 1] = {name = 'coin', count = 45, color = CoreData.colors.coin}
					else
						c2[#c2 + 1] = {name = 'coin', count = 30, color = CoreData.colors.coin}
					end
				end
	
				for k, v in pairs(c) do
					local color
					if k == 'coal' then
						color = CoreData.colors.coal
					elseif k == 'stone' then
						color = CoreData.colors.stone
					end
	
					local amount = Math.max(Math.min(available,Math.ceil(v * available/starting)),1)
					--override, decided to remove this effect:
					amount = v
	
					c2[#c2 + 1] = {name = k, count = amount, color = color}
				end
				Common.give(player, c2, entity.position)
	
				destination.dynamic_data.rock_material_remaining = available
	
				Surfaces.get_scope(destination).break_rock(entity.surface, entity.position, entity.name)
			end
		end

		event.buffer.clear()
	end
end

local function shred_nearby_simple_entities(entity)
	local memory = Memory.get_crew_memory()
	if memory.evolution_factor < 0.25 then return end
	local simple_entities = entity.surface.find_entities_filtered({type = {'simple-entity', 'tree'}, area = {{entity.position.x - 3, entity.position.y - 3},{entity.position.x + 3, entity.position.y + 3}}})
	if #simple_entities == 0 then return end
	for i = 1, #simple_entities, 1 do
		if not simple_entities[i] then break end
		if simple_entities[i].valid then
			simple_entities[i].die(memory.enemy_force_name, simple_entities[i])
		end
	end
end

local function base_kill_rewards(event)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local entity = event.entity
	if not (entity and entity.valid) then return end
	if not (event.force and event.force.valid) then return end

	-- no worm loot in the maze:
	local maze = (destination and destination.subtype and destination.subtype == Islands.enum.MAZE)
	if maze and not (entity.name == 'biter-spawner' or entity.name == 'spitter-spawner') then return end

	local revenge_target
	if event.cause and event.cause.valid and event.cause.name == 'character' then
		revenge_target = event.cause
	end

	local iron_amount = 0
	local coin_amount = 0

	if memory.overworldx >= 0 then
		if entity.name == 'small-worm-turret' then
			iron_amount = 5
			coin_amount = 40
		elseif entity.name == 'medium-worm-turret' then
			iron_amount = 20
			coin_amount = 70
		elseif entity.name == 'biter-spawner' or entity.name == 'spitter-spawner'
		then
			iron_amount = 30
			coin_amount = 70
		elseif entity.name == 'big-worm-turret'
		then
			iron_amount = 30
			coin_amount = 100
		elseif entity.name == 'behemoth-worm-turret'
		then
			iron_amount = 50
			coin_amount = 200
		end
	end

	if iron_amount > 0 then
		local stack = {{name = 'iron-plate', count = iron_amount}, {name = 'coin', count = coin_amount}}

		if revenge_target then
			Common.give(event.cause.player, stack)
		else
			Common.give(nil, stack, entity.position, entity.surface)
		end
	end
	
	if (entity.name == 'biter-spawner' or entity.name == 'spitter-spawner') and entity.position and entity.surface and entity.surface.valid then
		--check if its a boat biter entity
		local boat_spawner = false
		if memory.enemyboats then
			for i = 1, #memory.enemyboats do
				local eb = memory.enemyboats[i]
				if eb.spawner and eb.spawner.valid and event.entity == eb.spawner then
					boat_spawner = true
					break
				end
			end
		end
		if boat_spawner then
			Ai.revenge_group(entity.surface, entity.position, revenge_target, 'biter', 0.3, 2)
		elseif entity.name == 'biter-spawner' then
			Ai.revenge_group(entity.surface, entity.position, revenge_target, 'biter')
		else
			Ai.revenge_group(entity.surface, entity.position, revenge_target, 'spitter')
		end
	end
end

local function spawner_died(event)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	if (destination and destination.type and destination.type == Surfaces.enum.ISLAND) then

		local not_boat = true
		if memory.enemyboats and #memory.enemyboats > 0 then
			for i = 1, #memory.enemyboats do
				local eb = memory.enemyboats[i]
				if eb.spawner and eb.spawner.valid and event.entity and event.entity.valid and event.entity == eb.spawner then
					not_boat = false
					break
				end
			end
		end

		if not_boat then
			local extra_evo = Balance.evolution_per_nest_kill()
			Common.increment_evo(extra_evo)
		
			if destination.dynamic_data then
				destination.dynamic_data.evolution_accrued_nests = destination.dynamic_data.evolution_accrued_nests + extra_evo
			end
		end
	end
end

local function event_on_entity_died(event)
	--== MODDING NOTE: event.cause is not always provided.
	local entity = event.entity
	if not (entity and entity.valid) then return end
	if not (event.force and event.force.valid) then return end

	local crew_id = nil
	if not crew_id and event.force.valid then crew_id = tonumber(string.sub(event.force.name, -3, -1)) or nil end
	if not crew_id and entity.valid then crew_id = tonumber(string.sub(entity.force.name, -3, -1)) or nil end
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	if memory.id == 0 then return end

	base_kill_rewards(event)
	
	if memory.scripted_biters and entity.type == 'unit' and entity.force.name == memory.enemy_force_name then
		memory.scripted_biters[entity.unit_number] = nil
	end

	if entity.force.index == 3 or entity.force.name == 'environment' then
		if event.cause and event.cause.valid and event.cause.force.name == memory.enemy_force_name then
			shred_nearby_simple_entities(entity)
		end
	end

	if event.entity and event.entity.valid and event.entity.force and event.entity.force.name == memory.force_name then
		if memory.boat and memory.boat.cannonscount and entity.name and entity.name == 'artillery-turret' then
			memory.boat.cannonscount = memory.boat.cannonscount - 1
			-- if memory.boat.cannonscount <= 0 then
			-- 	Crew.try_lose()
			-- end
			Crew.try_lose('cannon destroyed')
		end
	end
	
	if entity and entity.valid and entity.force and entity.force.name == memory.enemy_force_name then
		if (entity.name == 'biter-spawner' or entity.name == 'spitter-spawner') then
			spawner_died(event)
			-- I think the only reason krakens don't trigger this right now is that they are destroyed rather than .die()
		else
			local destination = Common.current_destination()
			if not (destination and destination.dynamic_data and destination.dynamic_data.quest_type and (not destination.dynamic_data.quest_complete)) then return end
			if destination.dynamic_data.quest_type == Quest.enum.WORMS and entity.type == 'turret' then
				destination.dynamic_data.quest_progress = destination.dynamic_data.quest_progress + 1
				Quest.try_resolve_quest()
			end
		end
	end
end

function Public.research_apply_buffs(event)
	local memory = Memory.get_crew_memory()
	local force = memory.force

	if Balance.research_buffs[event.research.name] then
		local tech = Balance.research_buffs[event.research.name]
		-- @FIXME: This code is from another scenario but doesn't work
		-- for k, v in pairs(tech) do
		-- 	force[k] = force[k] + v
		-- end
	end
end


function Public.apply_flamer_nerfs()
	local memory = Memory.get_crew_memory()
	local difficulty = memory.difficulty
	local force = memory.force

	-- This code matches the vanilla game. Written by Hanakocz I think.
	local flame_researches = {
		[1] = {name = 'refined-flammables-1', bonus = 0.2},
		[2] = {name = 'refined-flammables-2', bonus = 0.2},
		[3] = {name = 'refined-flammables-3', bonus = 0.2},
		[4] = {name = 'refined-flammables-4', bonus = 0.3},
		[5] = {name = 'refined-flammables-5', bonus = 0.3},
		[6] = {name = 'refined-flammables-6', bonus = 0.4},
		[7] = {name = 'refined-flammables-7', bonus = 0.2}
	}
	local flamer_power = 0
	for i = 1, 6, 1 do
		if force.technologies[flame_researches[i].name].researched then
			flamer_power = flamer_power + flame_researches[i].bonus
		end
	end
	flamer_power = flamer_power + (force.technologies[flame_researches[7].name].level - 7) * 0.2

	force.set_ammo_damage_modifier('flamethrower', flamer_power * Balance.flamers_tech_multipliers() + Balance.flamers_base_nerf())
	force.set_turret_attack_modifier('flamethrower-turret', flamer_power * Balance.flamers_tech_multipliers() + Balance.flamers_base_nerf())
end

local function event_on_research_finished(event)
	-- figure out which crew this is about:
	local research = event.research
	local p_force = research.force
	local crew_id = tonumber(string.sub(p_force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()

	-- using a localised string means we have to write this out (recall that "" signals concatenation)
	memory.force.print({"", '>> ', event.research.localised_name, ' researched.'}, CoreData.colors.notify_force_light)

	Public.apply_flamer_nerfs()
	Public.research_apply_buffs(event)
	
	for _, e in ipairs(research.effects) do
	local t = e.type
		if t == 'ammo-damage' then
			local category = e.ammo_category
			local factor = Balance.player_ammo_damage_modifiers()[category]

			if factor then
				local current_m = p_force.get_ammo_damage_modifier(category)
				local m = e.modifier
				p_force.set_ammo_damage_modifier(category, current_m + factor * m)
			end
		elseif t == 'gun-speed' then
			local category = e.ammo_category
			local factor = Balance.player_gun_speed_modifiers()[category]

			if factor then
				local current_m = p_force.get_gun_speed_modifier(category)
				local m = e.modifier
				p_force.set_gun_speed_modifier(category, current_m + factor * m)
			end
		elseif t == 'turret-attack' then
			local category = e.ammo_category
			local factor = Balance.player_turret_attack_modifiers()[category]

			if factor then
				local current_m = p_force.get_turret_attack_modifier(category)
				local m = e.modifier
				p_force.set_turret_attack_modifier(category, current_m + factor * m)
			end
		end
	end

	-- even after research, force disable these:
	-- p_force.recipes['underground-belt'].enabled = false
	-- p_force.recipes['fast-underground-belt'].enabled = false
	-- p_force.recipes['express-underground-belt'].enabled = false
	p_force.recipes['pistol'].enabled = false
	p_force.recipes['centrifuge'].enabled = false
	-- p_force.recipes['flamethrower-turret'].enabled = false
	p_force.recipes['locomotive'].enabled = false
	p_force.recipes['car'].enabled = false
	p_force.recipes['cargo-wagon'].enabled = false
	p_force.recipes['slowdown-capsule'].enabled = false
	p_force.recipes['nuclear-fuel'].enabled = false
	-- p_force.recipes['rail'].enabled = false
end

local function event_on_player_joined_game(event)
	local global_memory = Memory.get_global_memory()

	local player = game.players[event.player_index]

	--figure out if we should drop them back into a crew:

	local crew_to_put_back_in = nil
	for _, mem in pairs(global_memory.crew_memories) do
		if mem.id and mem.crewstatus and mem.crewstatus == Crew.enum.ADVENTURING and mem.temporarily_logged_off_characters[player.index] then
			crew_to_put_back_in = mem.id
			break
		end
	end

	if crew_to_put_back_in then
		Crew.join_crew(player, crew_to_put_back_in, true)

		if _DEBUG then log('putting player back in their old crew') end
	else
		if player.character and player.character.valid then
			player.character.destroy()
		end
		player.set_controller({type=defines.controllers.god})
		player.create_character()
	
		local spawnpoint = Common.lobby_spawnpoint
		local surface = game.surfaces[CoreData.lobby_surface_name]
	
		player.teleport(surface.find_non_colliding_position('character', spawnpoint, 32, 0.5) or spawnpoint, surface)
		Roles.add_player_to_permission_group(player)
	
		if not player.name then return end
	
		-- start at Common.starting_island_spawnpoint or not?
	
		if game.tick == 0 then
			Common.ensure_chunks_at(surface, spawnpoint, 5)
		end
	
		-- Auto-join the oldest crew:
		local ages = {}
		for _, mem in pairs(global_memory.crew_memories) do
			if mem.id and mem.crewstatus and mem.crewstatus == Crew.enum.ADVENTURING and mem.capacity and mem.crewplayerindices and #mem.crewplayerindices < mem.capacity and (not (mem.tempbanned_from_joining_data and mem.tempbanned_from_joining_data[player.index] and game.tick < mem.tempbanned_from_joining_data[player.index] + Common.ban_from_rejoining_crew_ticks)) then
				ages[#ages+1] = {id = mem.id, age = mem.age}
			end
		end
		table.sort(
			ages,
			function(a, b) --true if a should be to the left of b
				return a.age > b.age
			end
		)
		if ages[1] then
			Crew.join_crew(player, ages[1].id)
			if ages[2] then
				Common.notify_player_announce(player, 'There are multiple crews on this server. You have been placed in the oldest.')
			end
		end
	end

	if not _DEBUG then
		Gui.info.toggle_window(player)
	end

	-- 	player.teleport(surface.find_non_colliding_position('character', spawnpoint, 32, 0.5), surface)
	-- 	-- for item, amount in pairs(Balance.starting_items_player) do
	-- 	-- 	player.insert({name = item, count = amount})
	-- 	-- end
	-- end


	-- if player.surface.name ~= Common.current_destination().surface_name and string.sub(player.surface.name, 1, 10) ~= 'crowsnest-' then -- add other adventuring surfaces here
	-- 	player.character = nil
	-- 	player.set_controller({type=defines.controllers.god})
	-- 	player.create_character()
	-- 	player.teleport(surface.find_non_colliding_position('character', memory.force.get_spawn_position(surface), 32, 0.5), surface)
	-- 	for item, amount in pairs(starting_items_player) do
	-- 		player.insert({name = item, count = amount})
	-- 	end
	-- end

	-- local tile = surface.get_tile(player.position)
	-- if tile.valid then
	-- 	if tile.name == 'out-of-map' then
	-- 		player.teleport(surface.find_non_colliding_position('character', memory.force.get_spawn_position(surface), 32, 0.5), surface)
	-- 	end
	-- end
end


local function event_on_pre_player_left_game(event)
	local player = game.players[event.player_index]

	local global_memory = Memory.get_global_memory()
	-- figure out which crew this is about:
	local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or 0
	
	for k, proposal in pairs(global_memory.crewproposals) do
		for k2, i in pairs(proposal.endorserindices) do
			if i == event.player_index then
				proposal.endorserindices[k2] = nil
				if #proposal.endorserindices == 0 then
					proposal = nil
					global_memory.crewproposals[k] = nil
				end
			end
		end
	end

	if crew_id == 0 then
		if player.character and player.character.valid then
			player.character.destroy()
		end
		return -- nothing more needed
	end

	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()

	if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end

	for _, id in pairs(memory.crewplayerindices) do
		if player.index == id then
			Crew.leave_crew(player, false, true)
			break
		end
	end
	for _, id in pairs(memory.spectatorplayerindices) do
		if player.index == id then
			Crew.leave_spectators(player, true)
			break
		end
	end
end


local function event_on_player_left_game(event)
	-- n/a
end

-- local function on_player_changed_position(event)
-- 	local memory = Chrono_table.get_table()
-- 	if memory.planet[1].type.id == 14 then --lava planet
-- 		Event_functions.lava_planet(event)
-- 	end
-- end


local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    local jailed = Jailed.get_jailed_table()

    if player.name and jailed and jailed[player.name] then
		-- not quite sure this is necessary, but let's send their items to the crew:
		Common.send_important_items_from_player_to_crew(player, true)
        return
    end

	-- prevent connecting power between surfaces: (for the ship we do this automatically, but no need to let players do it in the general case:)
	if not player.is_cursor_empty() then
		if player.cursor_stack and player.cursor_stack.valid_for_read then
			local blacklisted = {
				['small-electric-pole'] = true,
				['medium-electric-pole'] = true,
				['big-electric-pole'] = true,
				['substation'] = true,
			}
			if blacklisted[player.cursor_stack.name] then
				player.get_main_inventory().insert(player.cursor_stack)
				player.cursor_stack.clear()
			end
		end
		if player.cursor_ghost then
			player.cursor_ghost = nil
		end
	end

    Roles.update_privileges(player)
end

function Public.player_entered_vehicle(player, vehicle)

	if not vehicle then log('no vehicle') return end
	-- if not vehicle.name then log('no vehicle') return end
	-- if not vehicle.valid then log('vehicle invalid') return end

	local player_relative_pos = {x = player.position.x - vehicle.position.x, y = player.position.y - vehicle.position.y}
		
	local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	
	local player_boat_relative_pos
	if memory and memory.boat and memory.boat.position then
		player_boat_relative_pos = {x = player.position.x - memory.boat.position.x, y = player.position.y - memory.boat.position.y}
	else
		player_boat_relative_pos = {x = player.position.x - vehicle.position.x, y = player.position.y - vehicle.position.y}
	end

	local surfacedata = Surfaces.SurfacesCommon.decode_surface_name(player.surface.name)

	if vehicle.name == 'car' then

		if surfacedata.type ~= Surfaces.enum.CROWSNEST and surfacedata.type ~= Surfaces.enum.CABIN and surfacedata.type ~= Surfaces.enum.LOBBY then
			if player_boat_relative_pos.x < -47 then
				Surfaces.player_goto_cabin(player, {x = 2, y = player_relative_pos.y})
			else
				Surfaces.player_goto_crows_nest(player, player_relative_pos)
			end
			player.play_sound{path = "utility/picked_up_item"}
		elseif surfacedata.type == Surfaces.enum.CROWSNEST then
			Surfaces.player_exit_crows_nest(player, player_relative_pos)
			player.play_sound{path = "utility/picked_up_item"}
		elseif surfacedata.type == Surfaces.enum.CABIN then
			Surfaces.player_exit_cabin(player, player_relative_pos)
			player.play_sound{path = "utility/picked_up_item"}
		end
		vehicle.color = {148, 106, 52}

	elseif vehicle.name == 'locomotive' then

		if surfacedata.type ~= Surfaces.enum.HOLD and surfacedata.type ~= Surfaces.enum.LOBBY and Math.abs(player_boat_relative_pos.y) < 8 then --<8 in order not to enter holds of boats you haven't bought yet
			Surfaces.player_goto_hold(player, player_relative_pos, 1)
			player.play_sound{path = "utility/picked_up_item"}
		elseif surfacedata.type == Surfaces.enum.HOLD then
			local current_hold_index = surfacedata.destination_index
			if current_hold_index >= memory.hold_surface_count then
				Surfaces.player_exit_hold(player, player_relative_pos)
			else
				Surfaces.player_goto_hold(player, player_relative_pos, current_hold_index + 1)
			end
			player.play_sound{path = "utility/picked_up_item"}
		end
	end

	player.driving = false
end

local function event_on_player_driving_changed_state(event)
	local player = game.players[event.player_index]
	local vehicle = event.entity

	-- figure out which crew this is about:
	local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)

	Public.player_entered_vehicle(player, vehicle)
end


function Public.event_on_chunk_generated(event)

	local surface = event.surface
	if not surface then return end
	if not surface.valid then return end
	if surface.name == 'nauvis' or surface.name == 'piratedev1' or surface.name == 'gulag' then return end

	local seed = surface.map_gen_settings.seed
	local name = surface.name

	local surface_name_decoded = Surfaces.SurfacesCommon.decode_surface_name(name)
	local type = surface_name_decoded.type
	local subtype = surface_name_decoded.subtype
	local chunk_destination_index = surface_name_decoded.destination_index
	local crewid = surface_name_decoded.crewid

	Memory.set_working_id(crewid)

	local chunk_left_top = event.area.left_top
	local width, height = nil, nil
	local terraingen_coordinates_offset = {x = 0, y = 0}
	local static_params = {}
	local other_map_generation_data = {}
	local scope

	local memory = Memory.get_crew_memory()
	if type == Surfaces.enum.ISLAND and memory.destinations and memory.destinations[chunk_destination_index] then
		local destination = memory.destinations[chunk_destination_index]
		scope = Surfaces.get_scope(destination)
		static_params = destination.static_params
		other_map_generation_data = destination.dynamic_data.other_map_generation_data or {}
		terraingen_coordinates_offset = static_params.terraingen_coordinates_offset
		width = static_params.width
		height = static_params.height
	end

	if not scope then
		scope = Surfaces[type]
	end

	local noise_params, terrain_fn, chunk_structures_fn
	if scope then
		if scope.Data then
			if scope.Data.noiseparams then
				noise_params = scope.Data.noiseparams
			end
			if (not width) and scope.Data.width then
				width = scope.Data.width
			end
			if (not height) and scope.Data.height then
				height = scope.Data.height
			end
		end
		if scope.terrain then terrain_fn = scope.terrain end
		if scope.chunk_structures then chunk_structures_fn = scope.chunk_structures end
	end

	if not width then
		width = 999
		log('no surface width? ' .. type)
	end
	if not height then height = 999 end

	local tiles, entities, decoratives, specials = {}, {}, {}, {}
	-- local noise_generator = nil
	local noise_generator = Utils.noise_generator(noise_params, seed)

	for y = 0.5, 31.5, 1 do
		for x = 0.5, 31.5, 1 do
			local p = {x = chunk_left_top.x + x, y = chunk_left_top.y + y}

			if (p.x >= -width/2 and p.y >=-height/2 and p.x <= width/2 and p.y <= height/2) then

				terrain_fn{p = Utils.psum{p, {1, terraingen_coordinates_offset}}, true_p = p, true_left_top = chunk_left_top, left_top = Utils.psum{chunk_left_top, {1, terraingen_coordinates_offset}}, noise_generator = noise_generator, static_params = static_params, tiles = tiles, entities = entities, decoratives = decoratives, specials = specials, seed = seed, other_map_generation_data = other_map_generation_data, iconized_generation = false}
			else
				tiles[#tiles + 1] = {name = 'out-of-map', position = Utils.psum{p, {1, terraingen_coordinates_offset}}}
			end
		end
	end

	chunk_structures_fn{true_left_top = chunk_left_top, left_top = Utils.psum{chunk_left_top, {1, terraingen_coordinates_offset}}, noise_generator = noise_generator, static_params = static_params, specials = specials, entities = entities, seed = seed, other_map_generation_data = other_map_generation_data, biter_base_density_scale = Balance.biter_base_density_scale()}

	local tiles_corrected = {}
	for i = 1, #tiles do
		local t = tiles[i]
		t.position = Utils.psum{t.position, {-1, terraingen_coordinates_offset}}
		tiles_corrected[i] = t
	end
	local correct_tiles = true --tile borders etc
	
	if #tiles_corrected > 0 then surface.set_tiles(tiles_corrected, correct_tiles) end

	

	local destination = Common.current_destination()

	if destination.dynamic_data then

		if not destination.dynamic_data.structures_waiting_to_be_placed then
			destination.dynamic_data.structures_waiting_to_be_placed = {}
		end

		for _, special in pairs(specials) do

			-- recoordinatize:
			special.position = Utils.psum{special.position, {-1, terraingen_coordinates_offset}}

			if special.name and special.name == 'buried-treasure' then
				if destination.dynamic_data.buried_treasure and crewid ~= 0 then

					
					destination.dynamic_data.buried_treasure[#destination.dynamic_data.buried_treasure + 1] = {treasure = Loot.buried_treasure_loot(), position = special.position}
				end
			elseif special.name and special.name == 'chest' then
				local e = surface.create_entity{name = 'wooden-chest', position = special.position, force = string.format('ancient-friendly-%03d', memory.id)}
				if e and e.valid then
					e.minable = false
					e.rotatable = false
					e.destructible = false
					
					local inv = e.get_inventory(defines.inventory.chest)
					local loot = Loot.wooden_chest_loot()
					for i = 1, #loot do
						local l = loot[i]
						inv.insert(l)
					end
				end
			end

			if special.components then
				destination.dynamic_data.structures_waiting_to_be_placed[#destination.dynamic_data.structures_waiting_to_be_placed + 1] = {data = special, tick = game.tick}
			end
		end

	end

	for i = 1, #entities do
		local e = entities[i]
		e.position = Utils.psum{e.position, {-1, terraingen_coordinates_offset}}
		local e2 = e
		-- e2.build_check_type = defines.build_check_type.ghost_revive
		-- log(inspect(e2))
		if surface.can_place_entity(e2) then
			local ee = surface.create_entity(e)
			if e.indestructible then
				ee.destructible = false
			end
		end
	end

	local decoratives_corrected = {}
	for i = 1, #decoratives do
		local d = decoratives[i]
		d.position = Utils.psum{d.position, {-1, terraingen_coordinates_offset}}
		decoratives_corrected[i] = d
	end
	if #decoratives_corrected > 0 then surface.create_decoratives{decoratives = decoratives_corrected} end
end

local function event_on_rocket_launched(event)
	-- figure out which crew this is about:
	local crew_id = tonumber(string.sub(event.rocket.force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	destination.dynamic_data.rocketlaunched = true
	if memory.stored_fuel and destination.dynamic_data and destination.dynamic_data.rocketcoalreward then
		memory.stored_fuel = memory.stored_fuel + destination.dynamic_data.rocketcoalreward
		Common.give_items_to_crew{{name = 'coin', count = Balance.rocket_launch_coin_reward}}
	end
	
	local force = memory.force
	Common.notify_force_light(force,'Granted ' .. string.format('%.1fk', Balance.rocket_launch_coin_reward/1000) .. ' doubloons and ' .. string.format('%.1fk', destination.dynamic_data.rocketcoalreward/1000) .. ' fuel.')

	if destination.dynamic_data.quest_type == Quest.enum.TIME and (not destination.dynamic_data.quest_complete) then
		destination.dynamic_data.quest_progressneeded = 1
		Quest.try_resolve_quest()
	end

	if destination.dynamic_data.quest_type == Quest.enum.NODAMAGE and (not destination.dynamic_data.quest_complete) then
		destination.dynamic_data.quest_progress = destination.dynamic_data.rocketsilohp
		Quest.try_resolve_quest()
	end
end



local function event_on_built_entity(event)
    local entity = event.created_entity
    if not entity or not entity.valid then
        return
    end

	local crew_id = nil
	if event.player_index and game.players[event.player_index].valid then crew_id = tonumber(string.sub(game.players[event.player_index].force.name, -3, -1)) or nil end
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	local player = game.players[event.player_index]

    if entity.type == 'entity-ghost' and entity.force and entity.force.valid then
        entity.time_to_live = entity.force.ghost_time_to_live
	end

	if memory.boat and memory.boat.surface_name and player.surface == game.surfaces[memory.boat.surface_name] and entity.position then
		if (entity.type and (entity.type == 'underground-belt')) or (entity.name == 'entity-ghost' and entity.ghost_type and (entity.ghost_type == 'underground-belt')) then
			if Boats.on_boat(memory.boat, entity.position) then
				-- if (entity.type and (entity.type == 'underground-belt' or entity.type == 'pipe-to-ground')) or (entity.name == 'entity-ghost' and entity.ghost_type and (entity.ghost_type == 'underground-belt' or entity.ghost_type == 'pipe-to-ground')) then
					if not (entity.name and entity.name == 'entity-ghost') then
						player.insert{name = entity.name, count = 1}
					end
					entity.destroy()
					Common.notify_player_error(player, 'Build error: Undergrounds can\'t be built on the boat, due to conflicts with the boat movement code.')
					return
			end
		end
	end


	-- hanas code for selective spidertrons:
    -- local objective = Chrono_table.get_table()
    -- if entity.name == 'spidertron' then
    --     if objective.world.id ~= 7 or entity.surface.name == 'cargo_wagon' then
    --         entity.destroy()
    --         local player = game.players[event.player_index]
    --         Alert.alert_player_warning(player, 8, {'chronosphere.spidertron_not_allowed'})
    --         player.insert({name = 'spidertron', count = 1})
    --     end
    -- end
end

local function event_on_console_chat(event)
    if not (event.message and event.player_index and game.players[event.player_index]) then return end

	local global_memory = Memory.get_global_memory()

    local player = game.players[event.player_index]
    local tag = player.tag
    if not tag then
        tag = ''
    end
    local color = player.chat_color

    -- if global.tournament_mode then
    --     return
    -- end

	local message_force_name = player.force.name
	
	local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()

    if message_force_name == 'player' then
		local other_force_indices = global_memory.crew_active_ids

		for _, index in pairs(other_force_indices) do
			local recipient_force_name = global_memory.crew_memories[index].force_name
			game.forces[recipient_force_name].print(player.name .. tag .. ' [LOBBY]: ' .. event.message, color)
		end
	else
		game.forces.player.print(player.name .. tag .. ' [' .. memory.name .. ']: ' .. event.message, color)
	end
end

local function event_on_market_item_purchased(event)
	Shop.event_on_market_item_purchased(event)
end



local remove_boost_movement_speed_on_respawn =
    Token.register(
    function(data)
        local player = data.player
		local crew_id = data.crew_id
        if not (player and player.valid) then
            return
        end

		-- their color was strobing, so now reset it to their chat color:
		player.color = player.chat_color

		Memory.set_working_id(crew_id)
		local memory = Memory.get_crew_memory()
		if not (memory.id and memory.id > 0) then return end --check if crew disbanded
		if memory.game_lost then return end
		memory.speed_boost_characters[player.index] = nil

		Common.notify_player_expected(player, 'Respawn speed bonus removed.')
    end
)


local boost_movement_speed_on_respawn =
    Token.register(
    function(data)
        local player = data.player
		local crew_id = data.crew_id
        if not player or not player.valid then
            return
        end

		Memory.set_working_id(crew_id)
		local memory = Memory.get_crew_memory()
		if not (memory.id and memory.id > 0) then return end --check if crew disbanded
		if memory.game_lost then return end
		memory.speed_boost_characters[player.index] = true

        Task.set_timeout_in_ticks(1050, remove_boost_movement_speed_on_respawn, {player = player, crew_id = crew_id})
		Common.notify_player_expected(player, 'Respawn speed bonus applied.')
    end
)


local function event_on_player_respawned(event)
	local player = game.players[event.player_index]

	local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil

	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if player.surface == game.surfaces[Common.current_destination().surface_name] then
		if boat and boat.state == Boats.enum_state.ATSEA_SAILING then
			-- assuming sea is always default:
			local seasurface = game.surfaces[memory.sea_name]
			player.teleport(memory.spawnpoint, seasurface)
		elseif boat and (boat.state == Boats.enum_state.LANDED or boat.state == Boats.enum_state.RETREATING) then

			if player.character and player.character.valid then
				Task.set_timeout_in_ticks(360, boost_movement_speed_on_respawn, {player = player, crew_id = crew_id})
			end
		end
	end
end


local event = require 'utils.event'
event.add(defines.events.on_built_entity, event_on_built_entity)
event.add(defines.events.on_entity_damaged, event_on_entity_damaged)
event.add(defines.events.on_entity_died, event_on_entity_died)
event.add(defines.events.on_player_repaired_entity, event_on_player_repaired_entity)
event.add(defines.events.on_player_joined_game, event_on_player_joined_game)
event.add(defines.events.on_pre_player_left_game, event_on_pre_player_left_game)
event.add(defines.events.on_player_left_game, event_on_player_left_game)
event.add(defines.events.on_pre_player_mined_item, event_pre_player_mined_item)
event.add(defines.events.on_player_mined_entity, event_on_player_mined_entity)
event.add(defines.events.on_research_finished, event_on_research_finished)
event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
event.add(defines.events.on_player_driving_changed_state, event_on_player_driving_changed_state)
-- event.add(defines.events.on_player_changed_position, event_on_player_changed_position)
-- event.add(defines.events.on_technology_effects_reset, event_on_technology_effects_reset)
-- event.add(defines.events.on_chunk_generated, Interface.on_chunk_generated) --moved to main in order to make the debug properties clear
event.add(defines.events.on_rocket_launched, event_on_rocket_launched)
event.add(defines.events.on_console_chat, event_on_console_chat)
event.add(defines.events.on_market_item_purchased, event_on_market_item_purchased)
event.add(defines.events.on_player_respawned, event_on_player_respawned)


return Public