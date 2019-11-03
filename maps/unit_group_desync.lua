local function move_unit_groups()
	print("move_unit_groups 1")
	local surface = game.surfaces[1]
	local entities = surface.find_entities_filtered({type = "character", limit = 1})
	if not entities[1] then return end
	local character = entities[1]
	
	--local character = game.connected_players[1].character
	--if not character then return end
	--if not character.valid then return end

	print("move_unit_groups 2")
	for key, group in pairs(global.unit_groups) do
		if group.valid then
			print("move_unit_groups 3")
			group.set_command({
				type = defines.command.compound,
				structure_type = defines.compound_command.return_last,
				commands = {
								{
						type = defines.command.attack,
						target = character,
						distraction = defines.distraction.by_enemy,
					},
				},
			})
		else
			print("move_unit_groups 4")
			global.unit_groups[key] = nil
		end
	end
end

local function spawn_unit_group()
	print("spawn_unit_group 1")
	local surface = game.surfaces[1]
	if not global.unit_groups then global.unit_groups = {} end
	print("spawn_unit_group 2")
	local unit = surface.create_entity({name = "small-biter", position = {0,48}, force = "enemy"})
	local unit_group = surface.create_unit_group({position = {0,48}, force = "enemy"})
	print("spawn_unit_group 3")
	unit_group.add_member(unit)
	
	if global.table_insert then
		table.insert(global.unit_groups, unit_group)
	else
		global.unit_groups[#global.unit_groups + 1] = unit_group
	end
	
	print("spawn_unit_group 4")
end

local function on_tick()
	spawn_unit_group()
	if game.tick % 120 == 0 then move_unit_groups() end
end

local function on_player_created(event)
	local player = game.players[event.player_index]
	player.insert({name = "grenade", count = 1000})	
	player.insert({name = "power-armor", count = 1})	
end

local event = require 'utils.event'
event.on_nth_tick(30, on_tick)
event.add(defines.events.on_player_created, on_player_created)