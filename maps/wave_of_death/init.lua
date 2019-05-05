local function init_surface()
	local map_gen_settings = {}
	map_gen_settings.water = "0.35"
	map_gen_settings.starting_area = "5"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 12, cliff_elevation_0 = 32}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "3", size = "1.2", richness = "1"},
		["stone"] = {frequency = "3", size = "1.2", richness = "1"},
		["copper-ore"] = {frequency = "3", size = "1.2", richness = "1"},
		["iron-ore"] = {frequency = "3", size = "1.2", richness = "1"},
		["uranium-ore"] = {frequency = "2", size = "1", richness = "1"},
		["crude-oil"] = {frequency = "3", size = "1.2", richness = "1.5"},
		["trees"] = {frequency = "1.25", size = "0.5", richness = "0.65"},
		["enemy-base"] = {frequency = "5.5", size = "2", richness = "2"}	
	}
	game.create_surface("wave_of_death", map_gen_settings)
			
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.pollution.enabled = false	
	game.map_settings.enemy_expansion.enabled = false
end

local function init_forces()
	game.create_force(1)
	game.create_force(2)
	game.create_force(3)
	game.create_force(4)
	
	for _, force in pairs(game.forces) do
		if force.name ~= "enemy" then
			force.technologies["landfill"].enabled = false
			force.technologies["artillery"].enabled = false
			force.technologies["artillery-shell-range-1"].enabled = false					
			force.technologies["artillery-shell-speed-1"].enabled = false	
			force.technologies["atomic-bomb"].enabled = false			
			force.set_ammo_damage_modifier("shotgun-shell", 1)
			force.research_queue_enabled = true
			force.share_chart = true
			for _, force_2 in pairs(game.forces) do
				if force.name ~= "enemy" then
					force.set_friend(force_2.name, true)
				end
			end
		end
	end
	
	for i = 1, 4, 1 do
		game.forces[i].set_spawn_position({0,0}, game.surfaces["wave_of_death"])
	end
end

local function init_globals()
	global.spread_amount_modifier = 0.75 --percentage of a cleared wave to spawn at all other teams
	--local wave_spawn_y = -128
	--local wave_spawn_x = -64
	global.wod_lane = {}
	global.wod_biters = {}
	
	for i = 1, 4, 1 do
		global.wod_lane[i] = {}
		global.wod_lane[i].current_wave = 1
		global.wod_lane[i].alive_biters = 0
		--global.wod_lane[i].wave_spawn_point = {x = wave_spawn_x + (32 * i), y = wave_spawn_y}
		--global.wod_lane[i].target = {x = wave_spawn_x + (32 * i), y = wave_spawn_y + 96}			
	end
end

local function init()
	if global.spread_amount_modifier then return end
	init_surface()	
	init_globals()
	init_forces()		
end

return init