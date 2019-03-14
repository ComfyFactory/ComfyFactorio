local event = require 'utils.event' 

local particles = {"coal-particle", "copper-ore-particle", "iron-ore-particle", "stone-particle"}
local function create_fireworks_rocket(surface, position)
	local particle = particles[math_random(1, #particles)]
	local m = math_random(16, 36)
	local m2 = m * 0.005
				
	for i = 1, 80, 1 do 
		surface.create_entity({
			name = particle,
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
		})
	end
	
	if math_random(1,16) ~= 1 then return end
	surface.create_entity({name = "explosion", position = position})
end

local function fireworks(surface)
	local radius = 96
	for t = 1, 18000, 1 do
		if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end
		for x = 1, 3, 1 do
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = create_fireworks_rocket,
				args = {surface, {x = radius - math_random(0, radius * 2),y = radius - math_random(0, radius * 2)}}
			}								
		end
		t = t + 1
	end
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	if event.entity.name ~= "rocket-silo" then return end	
	if event.entity == global.rocket_silo.south or event.entity == global.rocket_silo.north then 					
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_won", volume_modifier=1}
		end		
		fireworks(surface)									
	end		
end

event.add(defines.events.on_entity_died, on_entity_died)
