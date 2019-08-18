--adds constant biter attacks onto players

local event = require 'utils.event'

local function get_random_close_spawner(surface)
	if not game.connected_players[1] then return false end
	local surface = game.connected_players[1].surface
	local spawners = surface.find_entities_filtered({type = "unit-spawner", force = "enemy"})	
	if not spawners[1] then return false end
	local spawner = spawners[math.random(1,#spawners)]
	for i = 1, 4, 1 do
		local spawner_2 = spawners[math.random(1,#spawners)]
		if spawner_2.position.x ^ 2 + spawner_2.position.y ^ 2 < spawner.position.x ^ 2 + spawner.position.y ^ 2 then spawner = spawner_2 end	
	end	
	return spawner
end

local function recruit_biters()
	local spawner = get_random_close_spawner(surface)
	if not spawner then return end
	
	local biters = spawner.surface.find_enemy_units(spawner.position, 256, "player")
	if not biters[1] then return false end
	
	local amount = math.floor(game.tick * 0.001) + 1
	if amount > 256 then amount = 256 end
	
	for _, biter in pairs(biters) do
		global.more_attacks.biters[biter.unit_number] = {entity = biter, recruitment_tick = game.tick}
		amount = amount - 1
		if amount <= 0 then break end
	end	
end

local function kill_idle_biters()
	for index, biter in pairs(global.more_attacks.biters) do
		if game.tick - biter.recruitment_tick > 36000 then
			if global.more_attacks.biters[index].entity.valid then
				global.more_attacks.biters[index].entity.destroy()
			end
			global.more_attacks.biters[index] = nil
		end
	end
end

local function send_biters()
	local k, v = next(global.more_attacks.biters)
	if not k then return end
	local surface = global.more_attacks.biters[k].entity.surface
	local pos = surface.find_non_colliding_position("rocket-silo", global.more_attacks.biters[k].entity.position, 128, 1)
	if not pos then return end
	local unit_group = surface.create_unit_group({position = pos, force = "enemy"})
	
	for _, biter in pairs(global.more_attacks.biters) do
		unit_group.add_member(biter.entity)
	end
	
	local target = game.connected_players[math.random(1, #game.connected_players)].position
	
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = {
			{
				type = defines.command.attack_area,
				destination = target,
				radius = 32,
				distraction=defines.distraction.by_enemy
			}
		}
	})
	
	global.more_attacks.last_sending = game.tick
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	if not event.entity.unit_number then return end
	if global.more_attacks.biters[event.entity.unit_number] then
		global.more_attacks.biters[event.entity.unit_number] = nil 
		global.more_attacks.last_death = game.tick
	end
end

local function tick()
	if game.tick < 100 then return end
	
	local k, v = next(global.more_attacks.biters)
	if not k then
		recruit_biters()
		send_biters()
		return
	end
	
	if game.tick - global.more_attacks.last_death < 1800 then return end
	kill_idle_biters()
	if game.tick - global.more_attacks.last_sending < 3600 then return end	
	send_biters()						
end

local function on_init(event)
	global.more_attacks = {}
	global.more_attacks.biters = {}
	global.more_attacks.last_death = 0
	global.more_attacks.last_sending = 0
end

event.add(defines.events.on_entity_died, on_entity_died)
event.on_nth_tick(300, tick)
event.on_init(on_init)