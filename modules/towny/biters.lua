local Public = {}
local math_random = math.random

local function roll_market()
	local r_max = 0
	local town_centers = global.towny.town_centers
	for k, town_center in pairs(town_centers) do
		r_max = r_max + town_center.research_counter
	end
	if r_max == 0 then return end	
	local r = math_random(0, r_max)
	
	local chance = 0
	for k, town_center in pairs(town_centers) do
		chance = chance + town_center.research_counter
		if r <= chance then return town_center end
	end
end

local function get_random_close_spawner(surface, market)
	local spawners = surface.find_entities_filtered({type = "unit-spawner"})
	if not spawners[1] then return false end
	local size_of_spawners = #spawners
	local center = market.position
	local spawner = spawners[math_random(1, size_of_spawners)]
	for i = 1, 3, 1 do
		local spawner_2 = spawners[math_random(1, size_of_spawners)]
		if (center.x - spawner_2.position.x) ^ 2 + (center.y - spawner_2.position.y) ^ 2 < (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2 then spawner = spawner_2 end
	end
	return spawner
end

function Public.swarm()
	local town_center = roll_market()
	if not town_center then return end
	local market = town_center.market
	local surface = market.surface
	local spawner = get_random_close_spawner(surface, market)
	if not spawner then return end	
	local units = spawner.surface.find_enemy_units(spawner.position, 256, market.force)
	if not units[1] then return end
	local unit_group_position = units[1].position
	local unit_group = surface.create_unit_group({position = units[1].position, force = units[1].force})
	local count = town_center.research_counter
	for key, unit in pairs(units) do
		if key > count then break end
		unit_group.add_member(unit) 
	end
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = {
			{
				type = defines.command.attack_area,
				destination = market.position,
				radius = 12,
				distraction = defines.distraction.by_enemy
			},									
			{
				type = defines.command.attack,
				target = market,
				distraction = defines.distraction.by_enemy
			}
		}
	})
	unit_group.start_moving()
end

return Public