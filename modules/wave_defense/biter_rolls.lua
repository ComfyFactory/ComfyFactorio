function wave_defense_roll_biter_name()
	local max_chance = 0
	for k, v in pairs(global.wave_defense.biter_raffle) do
		max_chance = max_chance + v
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for k, v in pairs(global.wave_defense.biter_raffle) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

function wave_defense_set_biter_raffle(level)
	global.wave_defense.biter_raffle = {
		["small-biter"] = 1000 - level * 1.75,
		["small-spitter"] = 1000 - level * 1.75,
		["medium-biter"] = level,
		["medium-spitter"] = level,
		["big-biter"] = 0,
		["big-spitter"] = 0,
		["behemoth-biter"] = 0,
		["behemoth-spitter"] = 0,
	}
	if level > 500 then
		global.wave_defense.biter_raffle["medium-biter"] = 500 - (level - 500)
		global.wave_defense.biter_raffle["medium-spitter"] = 500 - (level - 500)
		global.wave_defense.biter_raffle["big-biter"] = (level - 500) * 2
		global.wave_defense.biter_raffle["big-spitter"] = (level - 500) * 2
	end
	if level > 800 then
		global.wave_defense.biter_raffle["behemoth-biter"] = (level - 800) * 4
		global.wave_defense.biter_raffle["behemoth-spitter"] = (level - 800) * 4
	end
	for k, v in pairs(global.wave_defense.biter_raffle) do
		if global.wave_defense.biter_raffle[k] < 0 then global.wave_defense.biter_raffle[k] = 0 end
	end
end

function wave_defense_roll_worm_name()
	local max_chance = 0
	for k, v in pairs(global.wave_defense.worm_raffle) do
		max_chance = max_chance + v
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for k, v in pairs(global.wave_defense.worm_raffle) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

function wave_defense_set_worm_raffle(level)
	global.wave_defense.worm_raffle = {
		["small-worm-turret"] = 1000 - level * 1.75,
		["medium-worm-turret"] = level,		
		["big-worm-turret"] = 0,		
		["behemoth-worm-turret"] = 0,		
	}
	if level > 500 then
		global.wave_defense.worm_raffle["medium-worm-turret"] = 500 - (level - 500)
		global.wave_defense.worm_raffle["big-worm-turret"] = (level - 500) * 2		
	end
	if level > 800 then
		global.wave_defense.worm_raffle["behemoth-worm-turret"] = (level - 800) * 4		
	end
	for k, v in pairs(global.wave_defense.worm_raffle) do
		if global.wave_defense.worm_raffle[k] < 0 then global.wave_defense.worm_raffle[k] = 0 end
	end
end

function wave_defense_print_chances(tbl)
	for k, v in pairs(tbl) do
		game.print(k .. " chance = " .. v)
	end
end