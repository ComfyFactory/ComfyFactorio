local math_random = math.random
local table_insert = table.insert

local biter_table = {
		[1] = {"small-biter"},
		[2] = {"small-biter","small-biter","small-biter","small-biter","small-biter","medium-biter"},
		[3] = {"small-biter","small-biter","small-biter","small-biter","medium-biter","medium-biter"},
		[4] = {"small-biter","small-biter","small-biter","medium-biter","medium-biter","small-spitter"},
		[5] = {"small-biter","small-biter","medium-biter","medium-biter","medium-biter","small-spitter"},
		[6] = {"small-biter","small-biter","medium-biter","medium-biter","big-biter","small-spitter"},
		[7] = {"small-biter","small-biter","medium-biter","medium-biter","big-biter","medium-spitter"},
		[8] = {"small-biter","medium-biter","medium-biter","medium-biter","big-biter","medium-spitter"},
		[9] = {"small-biter","medium-biter","medium-biter","big-biter","big-biter","medium-spitter"},
		[10] = {"medium-biter","medium-biter","medium-biter","big-biter","big-biter","big-spitter"},
		[11] = {"medium-biter","medium-biter","big-biter","big-biter","big-biter","big-spitter"},
		[12] = {"medium-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"},
		[13] = {"big-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"},
		[14] = {"big-biter","big-biter","big-biter","big-biter","behemoth-biter","big-spitter"},
		[15] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","big-spitter"},
		[16] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[17] = {"big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[18] = {"big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[19] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[20] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter","behemoth-spitter"}
	}

local function create_particles(surface, position, amount)					
	for i = 1, amount, 1 do 
		local m = math_random(6, 12)
		local m2 = m * 0.005
		
		surface.create_entity({
			name = "stone-particle",
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
		})
	end	
end

local function spawn_biter(surface, position)
	local evolution = math.ceil(game.forces.enemy.evolution_factor * 20)
	local raffle = biter_table[evolution]
	local biter_name = raffle[math.random(1,#raffle)]
	local p = surface.find_non_colliding_position(biter_name, position, 8, 0.5)
	if not p then p = {x = position.x, y = position.y} end
	surface.create_entity({name = biter_name, position = p, force = "enemy"})
end

local function unearthing_biters(surface, position, amount)
	if not surface then return end
	if not position then return end
	if not position.x then return end
	if not position.y then return end
	
	local ticks = amount * 30
	ticks = ticks + 120
	for t = 1, ticks, 1 do
		if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end
				
		global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
			func = create_particles,
			args = {surface, position, 5}
		}										
		
		if t > 120 then
			if t % 30 == 29 then
				global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
					func = spawn_biter,
					args = {surface, position}
				}
			end
		end
	end		
end

return unearthing_biters