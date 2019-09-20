function get_biter()	
	local max_chance = 0
	for k, v in pairs(global.biter_chances) do
		max_chance = max_chance + v
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for k, v in pairs(global.biter_chances) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

function set_biter_chances(level)
	global.biter_chances = {
		["small-biter"] = 1000 - level * 10,
		["small-spitter"] = 1000 - level * 10,
		["medium-biter"] = level * 10,
		["medium-spitter"] = level * 10,
		["big-biter"] = 0,
		["big-spitter"] = 0,
		["behemoth-biter"] = 0,
		["behemoth-spitter"] = 0,
	}
	if level > 100 then
		global.biter_chances["big-biter"] = (level - 100) * 25
		global.biter_chances["big-spitter"] = (level - 100) * 25
	end
	if level > 200 then
		global.biter_chances["behemoth-biter"] = (level - 200) * 50
		global.biter_chances["behemoth-spitter"] = (level - 200) * 50
	end
	for k, v in pairs(global.biter_chances) do
		if global.biter_chances[k] < 0 then global.biter_chances[k] = 0 end
	end
end