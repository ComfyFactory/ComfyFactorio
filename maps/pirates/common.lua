
local Math = require 'maps.pirates.math'
local Server = require 'utils.server'
local Utils = require 'maps.pirates.utils_local'
local CoreData = require 'maps.pirates.coredata'
local Memory = require 'maps.pirates.memory'
local _inspect = require 'utils.inspect'.inspect
-- local simplex_noise = require 'utils.simplex_noise'.d2
-- local perlin_noise = require 'utils.perlin_noise'
-- local Force_health_booster = require 'modules.force_health_booster'

local Public = {}

-- Public.active_crews_cap = 1
Public.active_crews_cap = 2
Public.minimum_capacity_slider_value = 1
Public.minimum_run_capacity_to_enforce_space_for = 32
-- auto-disbanding when there are no players left in the crew:
Public.autodisband_ticks = nil
-- Public.autodisband_ticks = 30*60*60
-- Public.autodisband_ticks = 30 --the reason this is low is because the comfy server runs very slowly when no-one is on it

Public.boat_steps_at_a_time = 1

Public.seconds_after_landing_to_enable_AI = 45

Public.boat_default_starting_distance_from_shore = 22
-- Public.mapedge_distance_from_boat_starting_position = 136
Public.mapedge_distance_from_boat_starting_position = 272 -- to accommodate horseshoe
Public.deepwater_distance_from_leftmost_shore = 32
Public.lobby_spawnpoint = {x = -72, y = -8}

Public.quartermaster_range = 17
Public.allow_barreling_off_ship = true

Public.fraction_of_map_loaded_atsea = 1
Public.map_loading_ticks_atsea = 68 * 60
Public.map_loading_ticks_atsea_maze = 80 * 60
Public.map_loading_ticks_atsea_dock = 20 * 60
Public.map_loading_ticks_onisland = 2 * 60 * 60
Public.loading_interval = 5

Public.minimum_ore_placed_per_tile = 10

Public.maze_minimap_jam_league = 960

Public.ban_from_rejoining_crew_ticks = 45 * 60 --to prevent observing map and rejoining

Public.afk_time = 60 * 60 * 5
Public.afk_warning_time = 60 * 60 * 4.5
Public.logged_off_items_preserved_minutes = 5
Public.logout_unprotected_items = {'coin', 'uranium-235', 'rail-signal', 'uranium-238', 'fluid-wagon', 'coal', 'electric-engine-unit', 'flying-robot-frame', 'advanced-circuit', 'beacon', 'speed-module-3', 'speed-module-2', 'roboport', 'construction-robot'} --internal inventories of these will not be preserved

-- Public.mainshop_rate_limit_ticks = 11


function Public.ore_real_to_abstract(amount)
	return amount/1800
end
function Public.ore_abstract_to_real(amount)
	return Math.ceil(amount*1800)
end

-- 3000 oil resource is '1% yield'
function Public.oil_real_to_abstract(amount)
	return amount/(3000)
end
function Public.oil_abstract_to_real(amount)
	return Math.ceil(amount*3000)
end

function Public.difficulty_scale()
	local memory = Memory.get_crew_memory()
	if memory.overworldx > 0 then
		return memory.difficulty
	else
		return 0.75
	end
end
function Public.capacity() return Memory.get_crew_memory().capacity end
-- function Public.mode() return Memory.get_crew_memory().mode end
function Public.overworldx() return Memory.get_crew_memory().overworldx end
function Public.game_completion_progress() return Public.overworldx()/CoreData.victory_x end
function Public.game_completion_progress_capped() return Math.min(Public.overworldx()/CoreData.victory_x, 1) end
function Public.capacity_scale()
	local capacity = Public.capacity()
	if not capacity then --e.g. for EE wattage on boats not owned by a crew
		return 1
	elseif capacity <= 1 then
		return 0.5
	elseif capacity <= 4 then
		return 0.75
	elseif capacity <= 8 then
		return 1
	elseif capacity <= 16 then
		return 1.3
	else
		return 1.5
	end
end

function Public.activecrewcount()
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()
	if memory.id == 0 then return 0 end

	local count = 0
	for _, id in pairs(memory.crewplayerindices) do
		local player = game.players[id]
		if player and player.valid and not Utils.contains(global_memory.afk_player_indices, player.index) then
			count = count + 1
		end
	end

	return count
end


function Public.notify_game(message, color_override)
	color_override = color_override or CoreData.colors.notify_game
	game.print('>> ' .. message, color_override)
end

function Public.notify_lobby(message, color_override)
	color_override = color_override or CoreData.colors.notify_lobby
	game.forces['player'].print('>> ' .. message, color_override)
end

function Public.notify_force(force, message, color_override)
	color_override = color_override or CoreData.colors.notify_force
	force.print('>> ' .. message, color_override)
end

function Public.notify_force_light(force, message, color_override)
	color_override = color_override or CoreData.colors.notify_force_light
	force.print('>> ' .. message, color_override)
end

function Public.notify_force_error(force, message, color_override)
	color_override = color_override or CoreData.colors.notify_error
	force.print('>> ' .. message, color_override)
end

function Public.notify_player_error(player, message, color_override)
	color_override = color_override or CoreData.colors.notify_error
	player.print('## [Whisper] ' .. message, color_override)
end

function Public.notify_player_expected(player, message, color_override)
	color_override = color_override or CoreData.colors.notify_player_expected
	player.print('>> [Whisper] ' .. message, color_override)
end

function Public.notify_player_announce(player, message, color_override)
	color_override = color_override or CoreData.colors.notify_player_announce
	player.print('>> [Whisper] ' .. message, color_override)
end

function Public.parrot_speak(force, message)
	force.print('Parrot: ' .. message, CoreData.colors.parrot)

	local memory = Memory.get_crew_memory()
	Server.to_discord_embed_raw('[' .. memory.name .. '] Parrot: ' .. message)
end


function Public.flying_text(surface, position, text)
	surface.create_entity(
		{
			name = 'flying-text',
			position = {position.x - 0.7, position.y - 3.05},
			text = text,
		}
	)
end


function Public.flying_text_small(surface, position, text) --differs just in the location of the text, more suitable for small things like '+'
	surface.create_entity(
		{
			name = 'flying-text',
			position = {position.x - 0.08, position.y - 1.5},
			-- position = {position.x - 0.06, position.y - 1.5},
			text = text,
		}
	)
end



function Public.processed_loot_data(raw_data)
	local ret = {}
	for i = 1, #raw_data do
		local loot_data_item = raw_data[i]
		ret[#ret + 1] = {
            weight = loot_data_item[1],
            game_completion_progress_min = loot_data_item[2],
            game_completion_progress_max = loot_data_item[3],
            scaling = loot_data_item[4],
            name = loot_data_item[5],
            min_count = loot_data_item[6],
            max_count = loot_data_item[7],
            map_subtype = loot_data_item[8]
        }
	end
	return ret
end

--=='raw' data is in the form e.g.
--  {
-- 	{100, 0, 1, false, 'steel-plate', 140, 180},
-- 	{50, 0, 1, false, 'defender-capsule', 15, 25},
-- 	{20, 0, 1, false, 'flying-robot-frame', 20, 35},
-- }

function Public.raffle_from_processed_loot_data(processed_loot_data, how_many, game_completion_progress)
	local ret = {}

    local loot_types, loot_weights = {}, {}
    for i = 1, #processed_loot_data, 1 do
		local data = processed_loot_data[i]
        table.insert(loot_types, {['name'] = data.name, ['min_count'] = data.min_count, ['max_count'] = data.max_count})

		local destination = Public.current_destination()
		if not (destination and destination.subtype and data.map_subtype and data.map_subtype == destination.subtype) then
			if data.scaling then -- scale down weights away from the midpoint 'peak' (without changing the mean)
				local midpoint = (data.game_completion_progress_max + data.game_completion_progress_min) / 2
				local difference = (data.game_completion_progress_max - data.game_completion_progress_min)
				local w = 2 * data.weight * Math.max(0, 1 - (Math.abs(game_completion_progress - midpoint) / (difference / 2)))
				table.insert(loot_weights, w)
			else -- no scaling
				if data.game_completion_progress_min <= game_completion_progress and data.game_completion_progress_max >= game_completion_progress then
					table.insert(loot_weights, data.weight)
				else
					table.insert(loot_weights, 0)
				end
			end
		end
    end

	for _ = 1, how_many do
        local loot = Math.raffle(loot_types, loot_weights)
		if loot then
			local low = Math.max(1, Math.ceil(loot.min_count))
			local high = Math.max(1, Math.ceil(loot.max_count))
			local _count = Math.random(low, high)
			local lucky = Math.random(1, 220)
			if lucky == 1 then --lucky
				_count = _count * 3
			elseif lucky <= 12 then
				_count = _count * 2
			end
			ret[#ret + 1] = {name = loot.name, count = _count}
		end
    end

	return ret
end





function Public.give(player, stacks, spill_position, spill_surface, flying_text_position)
	-- stack elements of form {name = '', count = '', color = {r = , g = , b = }}
	-- to just spill on the ground, pass player and nill and give a position and surface directly
	spill_position = spill_position or player.position
	spill_surface = spill_surface or player.surface
	flying_text_position = flying_text_position or spill_position

	local text1 = ''
	local text2 = ''

	local stacks2 = stacks
	table.sort(stacks2, function(a,b) return a.name < b.name end)

	if not (spill_surface and spill_surface.valid) then return end
	local inv

	if player then
		inv = player.get_inventory(defines.inventory.character_main)
		if not (inv and inv.valid) then return end
	end

	for j = 1, #stacks2 do
		local stack = stacks2[j]
		local itemname, itemcount, flying_text_color = stack.name, stack.count or 1, stack.color or (CoreData.colors[stack.name] or {r = 1, g = 1, b = 1})
		local itemcount_remember = itemcount

		if not itemname then return end

		if itemcount > 0 then
			if player then
				local a = inv.insert{name = itemname, count = itemcount}
				itemcount = itemcount - a
				if itemcount >= 50 then
					for i = 1, Math.floor(itemcount / 50), 1 do
						local e = spill_surface.create_entity{name = 'item-on-ground', position = spill_position, stack = {name = itemname, count = 50}}
						if e and e.valid then
							e.to_be_looted = true
						end
						itemcount = itemcount - 50
					end
				end
				if itemcount > 0 then
					-- if itemcount < 5 then
					-- 	spill_surface.spill_item_stack(spill_position, {name = itemname, count = itemcount}, true)
					-- else
					-- 	local e = spill_surface.create_entity{name = 'item-on-ground', position = spill_position, stack = {name = itemname, count = itemcount}}
					-- 	if e and e.valid then
					-- 		e.to_be_looted = true
					-- 	end
					-- end
					spill_surface.spill_item_stack(spill_position, {name = itemname, count = itemcount}, true)
				end
			else
				-- local e = spill_surface.create_entity{name = 'item-on-ground', position = spill_position, stack = {name = itemname, count = itemcount}}
				-- if e and e.valid then
				-- 	e.to_be_looted = true
				-- end
				spill_surface.spill_item_stack(spill_position, {name = itemname, count = itemcount}, true)
			end
		end

		if itemcount_remember > 0 then
			if #stacks2 == 1 and itemname == 'coin' and itemcount_remember == 1 then --for a single coin, drop the '+'
				text1 = text1 .. '[item=' .. itemname .. ']'
			else
				text1 = text1 .. '[color=1,1,1]'
				text1 = text1 .. '+'
				text1 = text1 .. itemcount_remember .. '[/color] [item=' .. itemname .. ']'
			end
		else
			text1 = text1 .. '[color=1,1,1]'
			text1 = text1 .. '-'
			text1 = text1 .. -itemcount_remember .. '[/color] [item=' .. itemname .. ']'
		end


		if player and not (#stacks2 == 1 and itemname == 'coin') then
			-- count total of that item they have:
			local new_total_count = 0

			local cursor_stack = player.cursor_stack
			if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == itemname and cursor_stack.count and cursor_stack.count > 0 then
				new_total_count = new_total_count + cursor_stack.count
			end
			if inv and inv.get_item_count(itemname) and inv.get_item_count(itemname) > 0 then
				new_total_count = new_total_count + inv.get_item_count(itemname)
			end

			if #stacks2 > 1 then
				text2 = text2 .. '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. ']' .. new_total_count .. '[/color]'
			else
				text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. new_total_count .. ')[/color]'
			end
			if j < #stacks2 then
				text2 = text2 .. ', '
			end
		end

		if j < #stacks2 then
			text1 = text1 .. ', '
		end
	end

	if text2 ~= '' then
		if #stacks2 > 1 then
			text2 = '(' .. text2 .. ')'
		end
		Public.flying_text(spill_surface, flying_text_position, text1 .. ' [font=count-font]' .. text2 .. '[/font]')
	else
		Public.flying_text(spill_surface, flying_text_position, text1)
	end
end



function Public.is_captain(player)
	local memory = Memory.get_crew_memory()

	if memory.playerindex_captain and memory.playerindex_captain == player.index then
		return true
	else
		return false
	end
end

-- lifted shamelessly from biter battles, since I haven't done balancing work on this:
function Public.surplus_evo_biter_damage_modifier(surplus_evo)
	return Math.floor(surplus_evo/2*1000)/1000 --is this floor needed?
end
-- function Public.surplus_evo_biter_health_fractional_modifier(surplus_evo)
-- 	return surplus_evo*3
-- 	-- return Math.floor(surplus_evo*3*1000)/1000
-- end

function Public.set_biter_surplus_evo_modifiers()
	local memory = Memory.get_crew_memory()
	local enemy_force = memory.enemy_force

    if not (memory.evolution_factor and enemy_force and enemy_force.valid) then
        return nil
    end
	local surplus = memory.evolution_factor - 1

	local damage_fractional_mod
	-- local health_fractional_mod

	if surplus > 0 then
		damage_fractional_mod = Public.surplus_evo_biter_damage_modifier(surplus)
		-- health_fractional_mod = Public.surplus_evo_biter_health_fractional_modifier(surplus)
	else
		damage_fractional_mod = 0
		-- health_fractional_mod = 0
	end
	enemy_force.set_ammo_damage_modifier('melee', damage_fractional_mod)
	enemy_force.set_ammo_damage_modifier('biological', damage_fractional_mod)
	enemy_force.set_ammo_damage_modifier('artillery-shell', damage_fractional_mod)
	enemy_force.set_ammo_damage_modifier('flamethrower', damage_fractional_mod)

	-- this event is behaving really weirdly, e.g. messing up samurai damage:
	-- Force_health_booster.set_health_modifier(enemy_force.index, 1 + health_fractional_mod)
end

function Public.set_evo(evolution)
	local memory = Memory.get_crew_memory()
	memory.evolution_factor = evolution
	if memory.enemy_force_name then
		local ef = memory.enemy_force
		if ef and ef.valid then
			ef.evolution_factor = memory.evolution_factor
			Public.set_biter_surplus_evo_modifiers()
		end
	end
end

function Public.increment_evo(evolution)
	local memory = Memory.get_crew_memory()
	memory.evolution_factor = memory.evolution_factor + evolution
	if memory.enemy_force_name then
		local ef = memory.enemy_force
		if ef and ef.valid then
			ef.evolution_factor = memory.evolution_factor
			Public.set_biter_surplus_evo_modifiers()
		end
	end
end



function Public.current_destination()
	local memory = Memory.get_crew_memory()

	if memory.currentdestination_index then
		return memory.destinations[memory.currentdestination_index]
	else
		return CoreData.fallthrough_destination
	end
end


function Public.time_adjusted_departure_cost(cost)
	local memory = Memory.get_crew_memory()

	local ret = cost

	-- 1.5s memoization since the gui update will call this function:
	if (not memory.time_adjusted_departure_cost_memoized) or (memory.time_adjusted_departure_cost_memoized.tick < game.tick - 90) then
		local destination = Public.current_destination()
		local dynamic_data = destination.dynamic_data
		local timer = dynamic_data.timer
		local time_remaining = dynamic_data.time_remaining

		if timer and time_remaining and timer >= 0 and time_remaining >= 0 then
			local total_time = timer + time_remaining
			local elapsed_fraction = timer / total_time
			local cost_fraction = 1 - elapsed_fraction

			local new_cost = {}
			for name, count in pairs(cost) do
				if type(count) == "number" then
					new_cost[name] = Math.floor(count * cost_fraction)
					-- new_cost[name] = Math.ceil(count * cost_fraction)
				else
					new_cost[name] = count
				end
			end

			ret = new_cost
		end

		local resources_strings1 = ''
		local j = 1
		for name, count in pairs(cost) do
			if name ~= 'launch_rocket' then
				if j > 1 then
					resources_strings1 = resources_strings1 .. ', '
				end
				resources_strings1 = resources_strings1 .. count .. ' [item=' .. name .. ']'

				j = j + 1
			end
		end
		local resources_strings2 = ''
		j = 1
		for name, count in pairs(ret) do
			if name ~= 'launch_rocket' then
				if j > 1 then
					resources_strings2 = resources_strings2 .. ', '
				end
				resources_strings2 = resources_strings2 .. count .. ' [item=' .. name .. ']'

				j = j + 1
			end
		end

		memory.time_adjusted_departure_cost_memoized = {
			tick = game.tick,
			cost = ret,
			resources_strings = {resources_strings1, resources_strings2}
		}
	else
		ret = memory.time_adjusted_departure_cost_memoized.cost
	end

	return ret
end


function Public.time_adjusted_departure_cost_resources_strings(memory)
	-- written to be efficient... only called in the gui after Public.time_adjusted_departure_cost()

	return memory.time_adjusted_departure_cost_memoized.resources_strings
end


function Public.query_can_pay_cost_to_leave()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	local destination = Public.current_destination()
	if not (boat and destination) then return end

	local cost = destination.static_params.base_cost_to_undock
	if not cost then return true end

	local adjusted_cost = Public.time_adjusted_departure_cost(cost)

	local can_leave = true
	for name, count in pairs(adjusted_cost) do
		if name == 'launch_rocket' then
			if not destination.dynamic_data.rocketlaunched then
				can_leave = false
			end
		else
			local stored = (memory.boat.stored_resources and memory.boat.stored_resources[name]) or 0
			if stored < count then
				can_leave = false
			end
		end
	end

	return can_leave
end




function Public.surface_place_random_obstacle_boxes(surface, center, width, height, spacing_entity, box_size_table, contents)
	contents = contents or {}

	local memory = Memory.get_crew_memory()
	if not surface then return end

	local function boxposition()
		local p1 = {x = center.x - width/2 + Math.random(Math.ceil(width)), y = center.y - height/2 + Math.random(Math.ceil(height))}
		local p2 = surface.find_non_colliding_position(spacing_entity, p1, 32, 2, true) or p1
		return {x = p2.x, y = p2.y}
	end

	local placed = 0
	for size, count in pairs(box_size_table) do
		if count >= 1 then
			for i = 1, count do
				placed = placed + 1
				local p = boxposition()
				for j = 1, size^2 do
					local p2 = surface.find_non_colliding_position('wooden-chest', p, 5, 0.1, true)
					local e = surface.create_entity{name = 'wooden-chest', position = p2, force = memory.force_name, create_build_effect_smoke = false}
					e.destructible = false
					e.minable = false
					e.rotatable = false
					if contents[placed] and j==1 then
						local inventory = e.get_inventory(defines.inventory.chest)
						for name, count2 in pairs(contents[placed]) do
							inventory.insert{name = name, count = count2}
						end
					end
				end
			end
		end
	end
end



function Public.update_boat_stored_resources()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	if not boat.stored_resources then return end
	local input_chests = boat.input_chests

	if not input_chests then return end

	for i, chest in ipairs(input_chests) do
		if i>1 and CoreData.cost_items[i-1] then
			local inv = chest.get_inventory(defines.inventory.chest)
			local contents = inv.get_contents()

			local item_type = CoreData.cost_items[i-1].name
			local count = contents[item_type] or 0

			boat.stored_resources[item_type] = count
		end
	end
end



function Public.spend_stored_resources(to_spend)
	to_spend = to_spend or {}
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	if not memory.boat.stored_resources then return end
	local input_chests = boat.input_chests

	if not input_chests then return end

	for i, chest in ipairs(input_chests) do
		if i>1 then
			local inv = chest.get_inventory(defines.inventory.chest)
			local item_type = CoreData.cost_items[i-1].name
			local to_spend_i = to_spend[item_type] or 0

			if to_spend_i > 0 then
				inv.remove{name = item_type, count = to_spend_i}
			end
		end
	end

	Public.update_boat_stored_resources()
end


function Public.new_healthbar(text, target_entity, max_health, optional_id, health, size, extra_offset, location_override)
	health = health or max_health
	size = size or 0.5
	text = text or false
	extra_offset = extra_offset or 0
	location_override = location_override or Memory.get_crew_memory()

	local render1 = rendering.draw_sprite(
		{
			sprite = 'virtual-signal/signal-white',
			tint = {0, 200, 0},
			x_scale = size * 15,
			y_scale = size,
			render_layer = 'light-effect',
			target = target_entity,
			target_offset = {0, -2.5 + extra_offset},
			surface = target_entity.surface,
		}
	)
	local render2
	if text then
		render2 = rendering.draw_text(
		{
			color = {255, 255, 255},
			scale = 1.2 + size*2,
			render_layer = 'light-effect',
			target = target_entity,
			target_offset = {0, -3.6 - size*0.6 + extra_offset},
			surface = target_entity.surface,
			alignment = 'center',
		}
	)
	end

	local new_healthbar = {
		health = health,
		max_health = max_health,
		size = size,
		extra_offset = extra_offset,
		render1 = render1,
		render2 = render2,
		id = optional_id,
	}

	if not location_override.healthbars then location_override.healthbars = {} end
	location_override.healthbars[target_entity.unit_number] = new_healthbar

	Public.update_healthbar_rendering(new_healthbar, health)

	return new_healthbar
end

function Public.transfer_healthbar(old_unit_number, new_entity, location_override)
	location_override = location_override or Memory.get_crew_memory()
	if not location_override.healthbars then return end
	local old_healthbar = location_override.healthbars[old_unit_number]
	-- local new_unit_number = new_entity.unit_number

	-- if new_surface_bool then
	-- 	Public.new_healthbar(old_healthbar.render2, new_entity, old_healthbar.max_health, old_healthbar.id, old_healthbar.health, rendering.get_y_scale(old_healthbar.render1))
	-- else
	-- 	rendering.set_target(old_healthbar.render1, new_entity)
	-- 	if old_healthbar.render2 then
	-- 		rendering.set_target(old_healthbar.render2, new_entity)
	-- 	end
	-- 	memory.healthbars[new_unit_number] = old_healthbar
	-- end

	Public.new_healthbar(old_healthbar.render2, new_entity, old_healthbar.max_health, old_healthbar.id, old_healthbar.health, old_healthbar.size, old_healthbar.extra_offset, location_override)

	if rendering.is_valid(old_healthbar.render1) then
		rendering.destroy(old_healthbar.render1)
	end
	if rendering.is_valid(old_healthbar.render2) then
		rendering.destroy(old_healthbar.render2)
	end

	location_override.healthbars[old_unit_number] = nil
end

function Public.entity_damage_healthbar(entity, damage, location_override)
	location_override = location_override or Memory.get_crew_memory()
	local unit_number = entity.unit_number

	local healthbar = location_override.healthbars[unit_number]
	if not healthbar then return 0 end

	local new_health = healthbar.health - damage
	healthbar.health = new_health
	Public.update_healthbar_rendering(healthbar, new_health)

	if entity and entity.valid then
		entity.health = entity.prototype.max_health
	end

	return healthbar.health
end

function Public.update_healthbar_rendering(new_healthbar, health)
	local max_health = new_healthbar.max_health
	local render1 = new_healthbar.render1
	local render2 = new_healthbar.render2

	if health > 0 then
		local m = health / max_health
		local x_scale = rendering.get_y_scale(render1) * 15
		rendering.set_x_scale(render1, x_scale * m)
		rendering.set_color(render1, {Math.floor(255 - 255 * m), Math.floor(200 * m), 0})

		if render2 then
			rendering.set_text(render2, string.format('HP: %d/%d',Math.ceil(health),Math.ceil(max_health)))
		end
	else
		rendering.destroy(render1)
		if render2 then
			rendering.destroy(render2)
		end
	end
end

function Public.spawner_count(surface)
	local memory = Memory.get_crew_memory()

	local spawners = surface.find_entities_filtered({type = 'unit-spawner', force = memory.enemy_force_name})
	local spawnerscount = #spawners or 0
	return spawnerscount
end



function Public.create_poison_clouds(surface, position)

    local random_angles = {Math.rad(Math.random(359)), Math.rad(Math.random(359))}

	surface.create_entity({name = 'poison-cloud', position = {x = position.x, y = position.y}})
	surface.create_entity({name = 'poison-cloud', position = {x = position.x + 12 * Math.cos(random_angles[1]), y = position.y + 12 * Math.sin(random_angles[1])}})
	surface.create_entity({name = 'poison-cloud', position = {x = position.x + 12 * Math.cos(random_angles[2]), y = position.y + 12 * Math.sin(random_angles[2])}})
end


function Public.crew_get_crew_members()
	local memory = Memory.get_crew_memory()
	if memory.id == 0 then return {} end

	local playerlist = {}
	for _, id in pairs(memory.crewplayerindices) do
		local player = game.players[id]
		if player and player.valid then playerlist[#playerlist + 1] = player end
	end
	return playerlist
end


function Public.crew_get_crew_members_and_spectators()
	local memory = Memory.get_crew_memory()
	if memory.id == 0 then return {} end

	local playerlist = {}
	for _, id in pairs(memory.crewplayerindices) do
		local player = game.players[id]
		if player and player.valid then playerlist[#playerlist + 1] = player end
	end
	for _, id in pairs(memory.spectatorplayerindices) do
		local player = game.players[id]
		if player and player.valid then playerlist[#playerlist + 1] = player end
	end
	return playerlist
end




function Public.crew_get_nonafk_crew_members()
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()
	if memory.id == 0 then return {} end

	local playerlist = {}
	for _, id in pairs(memory.crewplayerindices) do
		local player = game.players[id]
		if player and player.valid and not Utils.contains(global_memory.afk_player_indices, player.index) then
			playerlist[#playerlist + 1] = player
		end
	end

	return playerlist
end


function Public.destroy_decoratives_in_area(surface, area, offset)
	local area2 = {{area[1][1] + offset.x, area[1][2] + offset.y}, {area[2][1] + offset.x, area[2][2] + offset.y}}

	surface.destroy_decoratives{area = area2}
end

function Public.can_place_silo_setup(surface, p, silo_count, generous, build_check_type_name)

	Public.ensure_chunks_at(surface, p, 0.2)

	build_check_type_name = build_check_type_name or 'manual'
	local build_check_type = defines.build_check_type[build_check_type_name]
	local s = true
	for i=1,silo_count do
		s = (surface.can_place_entity{name = 'rocket-silo', position = {p.x + 9 * (i-1), p.y}, build_check_type = build_check_type} or (generous and i>2)) and s
	end

	return s
end

function Public.ensure_chunks_at(surface, pos, radius) --WARNING: THIS DOES NOT PLAY NICELY WITH DELAYED TASKS. log(_inspect{global_memory.working_id}) was observed to vary before and after this function.
	-- local global_memory = Memory.get_global_memory()
	if surface and surface.valid then
		surface.request_to_generate_chunks(pos, radius)
		surface.force_generate_chunk_requests() --WARNING: THIS DOES NOT PLAY NICELY WITH DELAYED TASKS. log(_inspect{global_memory.working_id}) was observed to vary before and after this function.
	end


end


function Public.default_map_gen_settings(width, height, seed)
	width = width or 512
	height = height or 512
	seed = seed or Math.random(1, 1000000)

	local map_gen_settings = {
		['seed'] = seed,
		['width'] = width,
		['height'] = height,
		['water'] = 0,
		--FIXME: Back when this was at x=2000, a crash was caused once by a player spawning at x=2000. So there will be a crash in future under unknown circumstances if there is no space at x=0,y=0.
		['starting_points'] = {{x = 0, y = 0}},
		['cliff_settings'] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		['default_enable_all_autoplace_controls'] = true,
		['autoplace_settings'] = {
			['entity'] = {treat_missing_as_default = false},
			['tile'] = {treat_missing_as_default = true},
			['decorative'] = {treat_missing_as_default = true},
		},
		['property_expression_names'] = {},
	}

	return map_gen_settings
end


function Public.build_from_blueprint(bp_string, surface, pos, force, flipped)
	flipped = flipped or false

	local bp_entity = game.surfaces['nauvis'].create_entity{name = 'item-on-ground', position = {x = 158.5, y = 158.5}, stack = 'blueprint'}
	bp_entity.stack.import_stack(bp_string)

	local direction = flipped and defines.direction.south or defines.direction.north

	local entities = bp_entity.stack.build_blueprint{surface = surface, force = force, position = {x = pos.x, y = pos.y}, force_build = true, skip_fog_of_war = false, direction = direction}

	bp_entity.destroy()

	local rev_entities = {}
	for _, e in pairs(entities) do
		if e and e.valid then
			local _collisions, revived_entity = e.silent_revive()
			rev_entities[#rev_entities + 1] = revived_entity
		end
	end

	-- once again, to revive wagons:
	for _, e in pairs(entities) do
		if e and e.valid and e.type and e.type == 'entity-ghost' then
			local _collisions, revived_entity = e.silent_revive()
			rev_entities[#rev_entities + 1] = revived_entity

			if revived_entity and revived_entity.valid and revived_entity.name == 'locomotive' then
				revived_entity.color = {255, 106, 52}
				revived_entity.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 16})
				revived_entity.operable = false
			end
		end
	end

	return rev_entities
end

function Public.build_small_loco(surface, pos, force, color)
	local p1 = {x = pos.x, y = pos.y}
	local p2 = {x = pos.x, y = pos.y -2}
	local p3 = {x = pos.x, y = pos.y + 2}
	local es = {}
	es[1] = surface.create_entity({name = 'straight-rail', position = p1, force = force, create_build_effect_smoke = false})
	es[2] = surface.create_entity({name = 'straight-rail', position = p2, force = force, create_build_effect_smoke = false})
	es[3] = surface.create_entity({name = 'straight-rail', position = p3, force = force, create_build_effect_smoke = false})
	es[4] = surface.create_entity({name = 'locomotive', position = p1, force = force, create_build_effect_smoke = false})
	for _, e in pairs(es) do
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			e.operable = false
		end
	end
	if es[4] and es[4].valid then
		es[4].color = color
		es[4].get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 16})
	end
end

function Public.add_tiles_from_blueprint(tilesTable, bp_string, tile_name, offset)

	local bp_entity = game.surfaces['nauvis'].create_entity{name = 'item-on-ground', position = {x = 158.5, y = 158.5}, stack = 'blueprint'}
	bp_entity.stack.import_stack(bp_string)

	local bp_tiles = bp_entity.stack.get_blueprint_tiles()

	if bp_tiles then
		for _, tile in pairs(bp_tiles) do
			tilesTable[#tilesTable + 1] = {name = tile_name, position = {x = tile.position.x + offset.x, y = tile.position.y + offset.y}}
		end
	end

	bp_entity.destroy()

	return tilesTable
end

function Public.tile_positions_from_blueprint(bp_string, offset)

	local bp_entity = game.surfaces['nauvis'].create_entity{name = 'item-on-ground', position = {x = 158.5, y = 158.5}, stack = 'blueprint'}
	bp_entity.stack.import_stack(bp_string)

	local bp_tiles = bp_entity.stack.get_blueprint_tiles()

	local positions = {}
	if bp_tiles then
		for _, tile in pairs(bp_tiles) do
			positions[#positions + 1] = {x = tile.position.x + offset.x, y = tile.position.y + offset.y}
		end
	end

	bp_entity.destroy()

	return positions
end

function Public.tile_positions_from_blueprint_arrayform(bp_string, offset)

	local bp_entity = game.surfaces['nauvis'].create_entity{name = 'item-on-ground', position = {x = 158.5, y = 158.5}, stack = 'blueprint'}
	bp_entity.stack.import_stack(bp_string)

	local bp_tiles = bp_entity.stack.get_blueprint_tiles()

	local positions = {}
	if bp_tiles then
		for _, tile in pairs(bp_tiles) do
			local x = tile.position.x+ offset.x
			local y = tile.position.y + offset.y
			if not positions[x] then positions[x] = {} end
			positions[x][y] = true
		end
	end

	bp_entity.destroy()

	return positions
end

function Public.entity_positions_from_blueprint(bp_string, offset)

	local bp_entity = game.surfaces['nauvis'].create_entity{name = 'item-on-ground', position = {x = 158.5, y = 158.5}, stack = 'blueprint'}
	bp_entity.stack.import_stack(bp_string)

	local es = bp_entity.stack.get_blueprint_entities()

	local positions = {}
	if es then
		for _, e in pairs(es) do
			positions[#positions + 1] = {x = e.position.x + offset.x, y = e.position.y + offset.y}
		end
	end

	bp_entity.destroy()

	return positions
end

function Public.get_random_unit_type(evolution)
	-- designed to approximate https://wiki.factorio.com/Enemies
	local r = Math.random()

	if Math.random(5) == 1 then
		if r < 1 - 1/0.15*(evolution - 0.25) then
			return 'small-biter'
		elseif r < 1 - 1/0.3*(evolution - 0.4) then
			return 'small-spitter'
		elseif r < 1 - 0.85/0.5*(evolution - 0.5) then
			return 'medium-spitter'
		elseif r < 1 - 0.4/0.1*(evolution - 0.9) then
			return 'big-spitter'
		else
			return 'behemoth-spitter'
		end
	else
		if r < 1 - 1/0.4*(evolution - 0.2) then
			return 'small-biter'
		elseif r < 1 - 0.8/0.5*(evolution - 0.5) then
			return 'medium-biter'
		elseif r < 1 - 0.4/0.1*(evolution - 0.9) then
			return 'big-biter'
		else
			return 'behemoth-biter'
		end
	end
end

function Public.get_random_biter_type(evolution)
	-- designed to approximate https://wiki.factorio.com/Enemies
	local r = Math.random()

	if r < 1 - 1/0.4*(evolution - 0.2) then
		return 'small-biter'
	elseif r < 1 - 0.8/0.5*(evolution - 0.5) then
		return 'medium-biter'
	elseif r < 1 - 0.4/0.1*(evolution - 0.9) then
		return 'big-biter'
	else
		return 'behemoth-biter'
	end
end

function Public.get_random_spitter_type(evolution)
	-- designed to approximate https://wiki.factorio.com/Enemies
	local r = Math.random()

	if r < 1 - 1/0.3*(evolution - 0.4) then
		return 'small-spitter'
	elseif r < 1 - 0.85/0.5*(evolution - 0.5) then
		return 'medium-spitter'
	elseif r < 1 - 0.4/0.1*(evolution - 0.9) then
		return 'big-spitter'
	else
		return 'behemoth-spitter'
	end
end

function Public.get_random_worm_type(evolution)
	-- custom
	local r = Math.random()

	if r < 1 - 1/0.7*(evolution + 0.1) then
		return 'small-worm-turret'
	elseif r < 1 - 0.75/0.75*(evolution - 0.25) then
		return 'medium-worm-turret'
	elseif r < 1 - 0.4/0.4*(evolution - 0.6) then
		return 'big-worm-turret'
	else
		return 'behemoth-worm-turret'
	end
end

function Public.maximumUnitPollutionCost(evolution)
	if evolution < 0.2 then return 4
	elseif evolution < 0.5 then return 20
	elseif evolution < 0.9 then return 80
	else return 400
	end
end

function Public.averageUnitPollutionCost(evolution)

	local sum_biters = 0
	local f1 = Math.slopefromto(1 - 1/0.4*(evolution - 0.2), 0, 1)
	local f2 = Math.slopefromto(1 - 0.8/0.5*(evolution - 0.5), 0, 1)
	local f3 = Math.slopefromto(1 - 0.4/0.1*(evolution - 0.9), 0, 1)
	sum_biters = sum_biters + 4 * f1
	sum_biters = sum_biters + 20 * (f2 - f1)
	sum_biters = sum_biters + 80 * (f3 - f2)
	sum_biters = sum_biters + 400 * (1 - f3)

	local sum_spitters = 0
	local g1 = Math.slopefromto(1 - 1/0.15*(evolution - 0.25), 0, 1)
	local g2 = Math.slopefromto(1 - 1/0.3*(evolution - 0.4), 0, 1)
	local g3 = Math.slopefromto(1 - 0.85/0.5*(evolution - 0.5), 0, 1)
	local g4 = Math.slopefromto(1 - 0.4/0.1*(evolution - 0.9), 0, 1)
	sum_spitters = sum_spitters + 4 * g1
	sum_spitters = sum_spitters + 4 * (g2 - g1)
	sum_spitters = sum_spitters + 12 * (g3 - g2)
	sum_spitters = sum_spitters + 30 * (g4 - g3)
	sum_spitters = sum_spitters + 200 * (1 - g4)

	return (5 * sum_biters + sum_spitters)/6
end

function Public.orthog_positions_in_orthog_area(area)
	local positions = {}
		for y = area[1][2] + 0.5, area[2][2] - 0.5, 1 do
				for x = area[1][1] + 0.5, area[2][1] - 0.5, 1 do
						positions[#positions + 1] = {x = x, y = y}
				end
		end
		return positions
end

function Public.tileslist_add_area_offset(tiles_list_to_add_to, area, offset, tile_type)
	for _, p in pairs(Public.orthog_positions_in_orthog_area(area)) do
		tiles_list_to_add_to[#tiles_list_to_add_to + 1] = {name = tile_type, position = {x = offset.x + p.x, y = offset.y + p.y}}
	end
end

function Public.central_positions_within_area(area, offset)
	local offsetx = offset.x or 0
	local offsety = offset.y or 0
	local xr1, xr2, yr1, yr2 = offsetx + Math.ceil(area[1][1] - 0.5), offsetx + Math.floor(area[2][1] + 0.5), offsety + Math.ceil(area[1][2] - 0.5), offsety + Math.floor(area[2][2] + 0.5)

	local positions = {}
		for y = yr1 + 0.5, yr2 - 0.5, 1 do
				for x = xr1 + 0.5, xr2 - 0.5, 1 do
						positions[#positions + 1] = {x = x, y = y}
				end
		end
		return positions
end

function Public.tiles_from_area(tiles_list_to_add_to, area, offset, tile_type)
	for _, p in pairs(Public.central_positions_within_area(area, offset)) do
		tiles_list_to_add_to[#tiles_list_to_add_to + 1] = {name = tile_type, position = {x = p.x, y = p.y}}
	end
end

function Public.tiles_horizontally_flipped(tiles, x_to_flip_about)
	local tiles2 = {}
	for _, t in pairs(tiles) do
		local t2 = Utils.deepcopy(t)
		t2.position = {x = 2 * x_to_flip_about - t2.position.x, y = t2.position.y}
		tiles2[#tiles2 + 1] = t2
	end
	return tiles2
end


function Public.validate_player(player)
	if player and player.valid and player.connected and game.players[player.name] then
		return true
	else
		if _DEBUG then
			log('player validation fail: ' .. (player.name or 'noname'))
		end
		return false
	end
end


function Public.validate_player_and_character(player)
	local ret = Public.validate_player(player)
	ret = ret and player.character and player.character.valid
    return ret
end


function Public.send_important_items_from_player_to_crew(player, all_items)
	local player_inv = {}
	player_inv[1] = game.players[player.index].get_inventory(defines.inventory.character_main)
	player_inv[2] = game.players[player.index].get_inventory(defines.inventory.character_armor)
	player_inv[3] = game.players[player.index].get_inventory(defines.inventory.character_guns)
	player_inv[4] = game.players[player.index].get_inventory(defines.inventory.character_ammo)
	player_inv[5] = game.players[player.index].get_inventory(defines.inventory.character_trash)

	local any = false

	for ii = 1, 5, 1 do
		if player_inv[ii].valid then
			-- local to_keep = {}
			local to_remove = {}
			for iii = 1, #player_inv[ii], 1 do
				-- local item_stack = player_inv[ii][iii] --don't do this as LuaItemStack is a reference!
				if player_inv[ii] and player_inv[ii][iii].valid and player_inv[ii][iii].valid_for_read then
					if all_items or (player_inv[ii][iii].name and Utils.contains(Public.logout_unprotected_items, player_inv[ii][iii].name)) then
						to_remove[#to_remove + 1] = player_inv[ii][iii]
						any = true
					-- else
					-- 	to_keep[#to_keep + 1] = Utils.deepcopy(player_inv[ii][iii])
					end
				end
			end

			if #to_remove > 0 then
				for iii = 1, #to_remove, 1 do
					if to_remove[iii].valid_for_read then
						Public.give_items_to_crew{{name = to_remove[iii].name, count = to_remove[iii].count}}
						to_remove[iii].clear()
					end
				end
				-- clear and move over from to_keep if necessary?
			end
		end
	end

	return any
end


function Public.give_items_to_crew(items, prefer_alternate_chest)
	local memory = Memory.get_crew_memory()

	local boat = memory.boat
	if not boat then return end
	local surface_name = boat.surface_name
	if not surface_name then return end
	local surface = game.surfaces[surface_name]
	if not (surface and surface.valid) then return end
	local chest, chest2
	if prefer_alternate_chest then
		chest = boat.backup_output_chest
		if not (chest and chest.valid) then return end
		chest2 = boat.output_chest
		if not (chest2 and chest2.valid) then return end
	else
		chest = boat.output_chest
		if not (chest and chest.valid) then return end
		chest2 = boat.backup_output_chest
		if not (chest2 and chest2.valid) then return end
	end

	local inventory = chest.get_inventory(defines.inventory.chest)

	if items.name then --1 item
		if not (items.count and items.count>0) then return end
		local inserted = inventory.insert(items)
		if items.count - inserted > 0 then
			local inventory2 = chest2.get_inventory(defines.inventory.chest)
			local i2 = Utils.deepcopy(items)
			if i2.name then
				i2.count = items.count - inserted
				local inserted2 = inventory2.insert(i2)
				if items.count - inserted - inserted2 > 0 then
					local force = memory.force
					if not (force and force.valid) then return end
					Public.notify_force(force, 'Warning: captain\'s cabin chests are full!')
				end
			else
				if _DEBUG then
					log('give_items_to_crew: i2.name is nil. _inspect:')
					log(_inspect(items))
					log(_inspect(i2))
				end
			end
		end
	else
		for _, i in pairs(items) do
			if not (i.count and i.count>0) then return end
			local inserted = inventory.insert(i)
			if i.count - inserted > 0 then
				local inventory2 = chest2.get_inventory(defines.inventory.chest)
				local i2 = Utils.deepcopy(i)
				i2.count = i.count - inserted
				local inserted2 = inventory2.insert(i2)
				if i.count - inserted - inserted2 > 0 then
					local force = memory.force
					if not (force and force.valid) then return end
					Public.notify_force(force, 'Warning: captain\'s cabin chests are full!')
				end
			end
		end
	end
end



function Public.init_game_settings(technology_price_multiplier)

	--== Tuned for Pirate Ship ==--

	global.friendly_fire_history = {}
	global.landfill_history = {}
	global.mining_history = {}

	game.difficulty_settings.technology_price_multiplier = technology_price_multiplier

	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0

	game.map_settings.unit_group.min_group_gathering_time = 60 * 5
	game.map_settings.unit_group.max_group_gathering_time = 60 * 210
	game.map_settings.unit_group.max_wait_time_for_late_members = 60 * 15
	game.map_settings.unit_group.member_disown_distance = 5000
	game.map_settings.unit_group.max_group_radius = 70
	game.map_settings.unit_group.min_group_radius = 0.5 --seems to govern biter 'attack area' stopping distance

	-- (0,2) for a symmetric search:
	game.map_settings.path_finder.goal_pressure_ratio = -0.1 --small pressure for stupid paths
	game.map_settings.path_finder.fwd2bwd_ratio = 2 -- on experiments I found that this value was symmetric, despite the vanilla game comments saying it is 1...
	game.map_settings.max_failed_behavior_count = 2
	game.map_settings.path_finder.max_work_done_per_tick = 20000
	game.map_settings.path_finder.short_cache_min_algo_steps_to_cache = 100
	game.map_settings.path_finder.cache_accept_path_start_distance_ratio = 0.1


	game.map_settings.enemy_expansion.enabled = true
	-- faster expansion:
	-- game.map_settings.enemy_expansion.min_expansion_cooldown = 4 * 3600
	-- game.map_settings.enemy_expansion.max_expansion_cooldown = 30 * 3600
	-- slowed down due to the effect on single-player games:
	game.map_settings.enemy_expansion.min_expansion_cooldown = 6 * 3600
	game.map_settings.enemy_expansion.max_expansion_cooldown = 45 * 3600
	game.map_settings.enemy_expansion.settler_group_max_size = 24
	game.map_settings.enemy_expansion.settler_group_min_size = 6
	-- maybe should be 3.5 if possible:
	game.map_settings.enemy_expansion.max_expansion_distance = 4

	-- could turn off default AI attacks:
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 1
	--
	game.map_settings.pollution.enabled = true
	game.map_settings.pollution.expected_max_per_chunk = 120
	game.map_settings.pollution.min_to_show_per_chunk = 10
	game.map_settings.pollution.min_pollution_to_damage_trees = 20
	game.map_settings.pollution.pollution_per_tree_damage = 0.2
	game.map_settings.pollution.max_pollution_to_restore_trees = 0.04
	game.map_settings.pollution.pollution_restored_per_tree_damage = 0.01
	game.map_settings.pollution.pollution_with_max_forest_damage = 80
	game.map_settings.pollution.ageing = 0.1

	game.map_settings.pollution.diffusion_ratio = 0.035
	--
	-- game.forces.neutral.character_inventory_slots_bonus = 500
	game.forces.enemy.evolution_factor = 0
end


return Public