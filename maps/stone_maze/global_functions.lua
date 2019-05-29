function get_biter()
	local max_chance = 0	
	for i = 1, 4, 1 do
		max_chance = max_chance + global.enemy_appearances[i].chance
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for i = 1, 4, 1 do
		current_chance = current_chance + global.enemy_appearances[i].chance
		if r <= current_chance then return global.enemy_appearances[i].biter end
	end
end

function get_spitter()
	local max_chance = 0	
	for i = 1, 4, 1 do
		max_chance = max_chance + global.enemy_appearances[i].chance
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for i = 1, 4, 1 do
		current_chance = current_chance + global.enemy_appearances[i].chance
		if r <= current_chance then return global.enemy_appearances[i].spitter end
	end
end

function get_worm()
	local max_chance = 0	
	for i = 1, 4, 1 do
		max_chance = max_chance + global.enemy_appearances[i].chance
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for i = 1, 4, 1 do
		current_chance = current_chance + global.enemy_appearances[i].chance
		if r <= current_chance then return global.enemy_appearances[i].worm end
	end
end

function get_ammo()
	local max_chance = 0	
	for i = 1, 4, 1 do
		max_chance = max_chance + global.enemy_appearances[i].chance
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for i = 1, 4, 1 do
		current_chance = current_chance + global.enemy_appearances[i].chance
		if r <= current_chance then return global.enemy_appearances[i].ammo end
	end
end

function ore_market(surface, position)
	local market = surface.create_entity({name = "market", position = position, force = "neutral"})
	market.destructible = false
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}})
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}})
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'stone', count = 50}})
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'coal', count = 50}})
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'uranium-ore', count = 25}})
	market.add_market_item({price = {{'iron-ore', 50}}, offer = {type = 'give-item', item = "coin", count = 5}})
	market.add_market_item({price = {{'copper-ore', 50}}, offer = {type = 'give-item', item = "coin", count = 5}})
	market.add_market_item({price = {{'stone', 50}}, offer = {type = 'give-item', item = "coin", count = 5}})
	market.add_market_item({price = {{'coal', 50}}, offer = {type = 'give-item', item = "coin", count = 5}})
	market.add_market_item({price = {{'uranium-ore', 25}}, offer = {type = 'give-item', item = "coin", count = 5}})
end