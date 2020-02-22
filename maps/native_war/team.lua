local Public = {}
local math_random = math.random

Public.starting_items = {['iron-plate'] = 32, ['iron-gear-wheel'] = 16, ['stone'] = 25, ['radar'] = 25, ["automation-science-pack"]= 2000, ["logistic-science-pack"]= 2000, ["military-science-pack"]= 2000, ["chemical-science-pack"]= 2000}

function Public.set_force_attributes()
	game.forces.west.set_friend("spectator", true)
	game.forces.east.set_friend("spectator", true)
	game.forces.spectator.set_friend("west", true)
	game.forces.spectator.set_friend("east", true)

	for _, force_name in pairs({"west", "east"}) do
		game.forces[force_name].share_chart = true
		game.forces[force_name].research_queue_enabled = true
		game.forces[force_name].technologies["artillery"].enabled = false
		game.forces[force_name].technologies["artillery-shell-range-1"].enabled = false
		game.forces[force_name].technologies["artillery-shell-speed-1"].enabled = false
		game.forces[force_name].technologies["land-mine"].enabled = false
		local force_index = game.forces[force_name].index
		global.map_forces[force_name].unit_health_boost = 1
		global.map_forces[force_name].unit_count = 0
		global.map_forces[force_name].units = {}
		global.map_forces[force_name].radar = {}
		global.map_forces[force_name].max_unit_count = 768
		global.map_forces[force_name].player_count = 0
		global.map_forces[force_name].ate_buffer_potion = {
			["automation-science-pack"] = 0,
			["logistic-science-pack"]= 0,
			["military-science-pack"]= 0,
			["chemical-science-pack"]= 0,
			["production-science-pack"]= 0,
			["utility-science-pack"]= 0
		}
		if force_name == "west" then
			global.map_forces[force_name].worm_turrets_positions = {
				[1] = {x=-127,y=-38},
				[2] = {x=-112,y=-38},
				[3] = {x=-127,y=-70},
				[4] = {x=-112,y=-70},
				[5] = {x=-127,y=-102},
				[6] = {x=-112,y=-102},
				[7] = {x=-90,y=-119},
				[8] = {x=-90,y=-136},
				[9] = {x=-70,y=-90},
				[10] = {x=-50,y=-90},
				[11] = {x=-70,y=-58},
				[12] = {x=-50,y=-58},
				[13] = {x=-70,y=-26},
				[14] = {x=-50,y=-26},
				[15] = {x=-70,y=0},
				[16] = {x=-50,y=0},
				[17] = {x=-70,y=36},
				[18] = {x=-50,y=36},
				[19] = {x=-70,y=68},
				[20] = {x=-50,y=68},
				[21] = {x=-70,y=100},
				[22] = {x=-50,y=100},
				[23] = {x=-30,y=119},
				[24] = {x=-30,y=136},
				[25] = {x=-9,y=90},
				[26] = {x=9,y=90},
				[27] = {x=-9,y=59},
				[28] = {x=9,y=59},
				[29] = {x=-9,y=27},
				[30] = {x=9,y=27}
			}
			global.map_forces[force_name].modifier ={damage = 1, resistance = 1, splash = 1}
			global.map_forces[force_name].spawn = {x=-137,y=0}
			global.biter_reanimator.forces[force_index] = 0
			global.map_forces[force_name].eei = {x=-200,y=0}
			global.map_forces[force_name].energy = 0
		else
			global.map_forces[force_name].worm_turrets_positions ={
				[1] = {x=127,y=38},
				[2] = {x=112,y=38},
				[3] = {x=127,y=70},
				[4] = {x=112,y=70},
				[5] = {x=127,y=102},
				[6] = {x=112,y=102},
				[7] = {x=90,y=119},
				[8] = {x=90,y=136},
				[9] = {x=70,y=90},
				[10] = {x=50,y=90},
				[11] = {x=70,y=58},
				[12] = {x=50,y=58},
				[13] = {x=70,y=26},
				[14] = {x=50,y=26},
				[15] = {x=70,y=0},
				[16] = {x=50,y=0},
				[17] = {x=70,y=-36},
				[18] = {x=50,y=-36},
				[19] = {x=70,y=-68},
				[20] = {x=50,y=-68},
				[21] = {x=70,y=-100},
				[22] = {x=50,y=-100},
				[23] = {x=30,y=-119},
				[24] = {x=30,y=-136},
				[25] = {x=-9,y=-90},
				[26] = {x=9,y=-90},
				[27] = {x=9,y=-59},
				[28] = {x=-9,y=-59},
				[29] = {x=9,y=-27},
				[30] = {x=-9,y=-27}
			}
			global.map_forces[force_name].modifier ={damage = 1, resistance = 1, splash = 1}
			global.map_forces[force_name].spawn = {x=137,y=0}
			global.map_forces[force_name].eei = {x=201,y=0}
			global.biter_reanimator.forces[force_index] = 0
			global.map_forces[force_name].energy = 0
		end
	end
end
function Public.create_forces()
	game.create_force("west")
	game.create_force("east")
	game.create_force("spectator")
end
function Public.add_unit(force_name,unit_number, unit)
	global.map_forces[force_name].units[unit_number] = unit
end
function Public.assign_random_force_to_active_players()
	local player_indexes = {}
	for _, player in pairs(game.connected_players) do
		if player.force.name ~= "spectator" then	player_indexes[#player_indexes + 1] = player.index end
	end
	if #player_indexes > 1 then table.shuffle_table(player_indexes) end
	local a = math_random(0, 1)
	for key, player_index in pairs(player_indexes) do
		if key % 2 == a then
			game.players[player_index].force = game.forces.west
		else
			game.players[player_index].force = game.forces.east
		end
	end
end

function Public.assign_force_to_player(player)
	player.spectator = false
	if math_random(1, 2) == 1 then
		if #game.forces.east.connected_players > #game.forces.west.connected_players then
			player.force = game.forces.west
		else
			player.force = game.forces.east
		end
	else
		if #game.forces.east.connected_players < #game.forces.west.connected_players then
			player.force = game.forces.east
		else
			player.force = game.forces.west
		end
	end
end

function Public.teleport_player_to_active_surface(player)
	local surface = game.surfaces[global.active_surface_index]
	local position
	if player.force.name == "spectator" then
		position = player.force.get_spawn_position(surface)
		position = {x = (position.x - 160) + math_random(0, 320), y = (position.y - 16) + math_random(0, 32)}
	else
		position = surface.find_non_colliding_position("character", player.force.get_spawn_position(surface), 48, 1)
		if not position then position = player.force.get_spawn_position(surface) end
	end
	player.teleport(position, surface)
end

function Public.put_player_into_random_team(player)
	if player.character then
		if player.character.valid then
			player.character.destroy()
		end
	end
	player.character = nil
	player.set_controller({type=defines.controllers.god})
	player.create_character()
	for item, amount in pairs(Public.starting_items) do
		player.insert({name = item, count = amount})
	end
	global.map_forces[player.force.name].player_count = global.map_forces[player.force.name].player_count + 1
end

function Public.set_player_to_spectator(player)
	if player.character then player.character.die() end
	player.force = game.forces.spectator
	player.character = nil
	player.spectator = true
	player.set_controller({type=defines.controllers.spectator})
end

function Public.on_buy_wave(surface, force, tier)
	if tier == "red" or tier == "green" then
		local random_biter = math.random(5,9)
		for i = 1, random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "small-biter", position = {global.map_forces[force].spawn.x + i, global.map_forces[force].spawn.y} , force = game.forces[force]}
				global.map_forces[force].units[unit.unit_number] = unit
		end
		for i = 1, 10-random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "small-spitter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
				global.map_forces[force].units[unit.unit_number] = unit
		end
	  return
	end
	if tier=="grey" then
		local random_biter=math.random(5,9)
		for i = 1, random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "medium-biter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
		for i = 1, 10-random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "medium-spitter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
	  return
	end
	if tier=="blue" then
		local random_biter = math.random(5,9)
		for i = 1, random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "big-biter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
		for i = 1, 10-random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "big-spitter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
		return
	end
	if tier=="purple" or tier=="yellow" then
		local random_biter = math.random(5,9)
		for i = 1, random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "-biter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
		for i = 1, 10-random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "behemoth-spitter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
	  return
	end
end

function Public.buy_worm_turret(surface,force_name, dist, player, player_nb_sp, nb_sp_price, sp)
	local size_table_turret = #global.map_forces[force_name].worm_turrets_positions
	if dist == "All" then
		local player_sp_count = player_nb_sp
		count = 0
		for k, pos in pairs(global.map_forces[force_name].worm_turrets_positions) do
			local turret = surface.find_entity('small-worm-turret',{pos.x,pos.y})
			if turret == nil and player_sp_count >= nb_sp_price then
				local turrets = surface.find_entities_filtered{position = {pos.x,pos.y}, name ={'medium-worm-turret','big-worm-turret','behemoth-worm-turret'}}
				if #turrets ==0 then
					surface.create_entity({name = "small-worm-turret", position = {pos.x,pos.y}, force = force_name})
					player.remove_item({name=sp, count=nb_sp_price})
					player_sp_count = player_sp_count - nb_sp_price
					count = count + 1
				end
			end
		end
		if count == 0 then
			return false
		else
			return true
		end
	elseif dist == "Farthest" then
		for i=size_table_turret,1,-1 do
			local pos = global.map_forces[force_name].worm_turrets_positions[i]
			local turret = surface.find_entity('small-worm-turret',{pos.x,pos.y})
			if turret == nil and player_nb_sp >= nb_sp_price then
				local turrets = surface.find_entities_filtered{position = {pos.x,pos.y}, name ={'medium-worm-turret','big-worm-turret','behemoth-worm-turret'}}
				if #turrets ==0 then
					surface.create_entity({name = "small-worm-turret", position = {pos.x,pos.y}, force = force_name})
					player.remove_item({name=sp, count=nb_sp_price})
					return true
				end
			end
		end
		return false
	elseif dist == "Closest" then
		for i=1,size_table_turret,1 do
			local pos = global.map_forces[force_name].worm_turrets_positions[i]
			local turret = surface.find_entity('small-worm-turret',{pos.x,pos.y})
			if turret == nil and player_nb_sp >= nb_sp_price then
				local turrets = surface.find_entities_filtered{position = {pos.x,pos.y}, name ={'medium-worm-turret','big-worm-turret','behemoth-worm-turret'}}
				if #turrets ==0 then
					surface.create_entity({name = "small-worm-turret", position = {pos.x,pos.y}, force = force_name})
					player.remove_item({name=sp, count=nb_sp_price})
					return true
				end
			end
		end
		return false
	end
end

function Public.upgrade_worm_turret(surface, force_name, dist, player, player_nb_sp, nb_sp_price, sp, tier)
	local table_upgrade = {
		["medium-worm-turret"] = "small-worm-turret",
		["big-worm-turret"] = "medium-worm-turret",
		["behemoth-worm-turret"] = "big-worm-turret"
	}
	local size_table_turret = #global.map_forces[force_name].worm_turrets_positions
	print(size_table_turret)
	if dist == "All" then
		local player_sp_count = player_nb_sp
		count = 0
		for k, pos in pairs(global.map_forces[force_name].worm_turrets_positions) do
			local turret = surface.find_entity(table_upgrade[tier],{pos.x,pos.y})
			if turret ~= nil and player_nb_sp >= nb_sp_price then
				turret.destroy()
				surface.create_entity({name = tier, position = {pos.x,pos.y}, force = force_name})
				player.remove_item({name=sp, count=nb_sp_price})
				player_sp_count = player_sp_count - nb_sp_price
				count = count + 1
			else end
		end
		if count == 0 then
			return false
		else
			return true
		end
	elseif dist == "Farthest" then
		for i = #global.map_forces[force_name].worm_turrets_positions, 1, -1 do
			local turret = surface.find_entity(table_upgrade[tier],{global.map_forces[force_name].worm_turrets_positions[i].x,global.map_forces[force_name].worm_turrets_positions[i].y})
			if turret ~= nil and player_nb_sp >= nb_sp_price then
				turret.destroy()
				surface.create_entity({name = tier, position = {global.map_forces[force_name].worm_turrets_positions[i].x,global.map_forces[force_name].worm_turrets_positions[i].y}, force = force_name})
				player.remove_item({name=sp, count=nb_sp_price})
				return true
			else end
		end
		return false
	elseif dist == "Closest" then
		for k, pos in pairs(global.map_forces[force_name].worm_turrets_positions) do
			local turret = surface.find_entity(table_upgrade[tier],{pos.x,pos.y})
			if turret ~= nil and player_nb_sp >= nb_sp_price then
				turret.destroy()
				surface.create_entity({name = tier, position = {pos.x,pos.y}, force = force_name})
				player.remove_item({name=sp, count=nb_sp_price})
				return true
			else end
		end
		return false
	end
end

function Public.buy_extra_life(force_name)
		local force_index = game.forces[force_name].index
		global.biter_reanimator.forces[force_index] = global.biter_reanimator.forces[force_index] +1
end

return Public
