local Public = {}

local tick_tack_trap = require "functions.tick_tack_trap"
local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"

local math_random = math.random
local math_floor = math.floor

local choppy_entity_yield = {
		["tree-01"] = {"iron-ore"},
		["tree-02-red"] = {"copper-ore"},
		["tree-04"] = {"coal"},
		["tree-08-brown"] = {"stone"}
	}

local function get_ore_amount()
	local scaling = 5 * global.objective.chronojumps
	local amount = (30 + scaling ) * (1 + game.forces.player.mining_drill_productivity_bonus) * global.objective.planet[1].ore_richness.factor
	if amount > 600 then amount = 600 end
	amount = math_random(math_floor(amount * 0.7), math_floor(amount * 1.3))
	return amount
end

local function reward_ores(amount, mined_loot, surface, player)
	local i = player.insert {name = mined_loot, count = amount}
	amount = amount - i
	if amount > 0 then
		if amount >= 50 then
			for i = 1, math_floor(amount / 50), 1 do
				surface.create_entity{name = "item-on-ground", position = player.position, stack = {name = mined_loot, count = 50}}
				amount = amount - 50
			end
		end
		if amount > 0 then
			surface.spill_item_stack(player.position, {name = mined_loot, count = amount},true)
		end
	end
end

function Public.biters_chew_rocks_faster(event)
	if event.entity.force.index ~= 3 then return end --Neutral Force
	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.force.index ~= 2 then return end --Enemy Force
	event.entity.health = event.entity.health - event.final_damage_amount * 5
end

function Public.isprotected(entity)
	if entity.surface.name == "cargo_wagon" then return true end
	local protected = {global.locomotive, global.locomotive_cargo, global.locomotive_cargo2, global.locomotive_cargo3}
	for i = 1, #global.comfychests,1 do
		table.insert(protected, global.comfychests[i])
	end
	for i = 1, #protected do
    if protected[i] == entity then
      return true
    end
  end
	return false
end

function Public.trap(entity, trap)
	if trap then
		tick_tack_trap(entity.surface, entity.position)
		tick_tack_trap(entity.surface, {x = entity.position.x + math_random(-2,2), y = entity.position.y + math_random(-2,2)})
		return
	end
	if math_random(1,256) == 1 then tick_tack_trap(entity.surface, entity.position) return end
	if math_random(1,128) == 1 then unearthing_worm(entity.surface, entity.surface.find_non_colliding_position("big-worm-turret",entity.position,5,1)) end
	if math_random(1,64) == 1 then unearthing_biters(entity.surface, entity.position, math_random(4,8)) end
end

function Public.lava_planet(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving then return end
	if player.surface.name == "cargo_wagon" then return end
	local safe = {"stone-path", "concrete", "hazard-concrete-left", "hazard-concrete-right", "refined-concrete", "refined-hazard-concrete-left", "refined-hazard-concrete-right"}
	local pavement = player.surface.get_tile(player.position.x, player.position.y)
	for i = 1, 7, 1 do
		if pavement.name == safe[i] then return end
	end
	if not global.flame_boots[player.index].steps then global.flame_boots[player.index].steps = {} end
	local steps = global.flame_boots[player.index].steps

	local elements = #steps

	steps[elements + 1] = {x = player.position.x, y = player.position.y}

	if elements > 10 then
		player.surface.create_entity({name = "fire-flame", position = steps[elements - 1], })
		for i = 1, elements, 1 do
			steps[i] = steps[i+1]
		end
		steps[elements + 1] = nil
	end
end

function Public.shred_simple_entities(entity)
	--game.print(entity.name)
	if game.forces["enemy"].evolution_factor < 0.25 then return end
	local simple_entities = entity.surface.find_entities_filtered({type = {"simple-entity", "tree"}, area = {{entity.position.x - 3, entity.position.y - 3},{entity.position.x + 3, entity.position.y + 3}}})
	if #simple_entities == 0 then return end
	for i = 1, #simple_entities, 1 do
		if not simple_entities[i] then break end
		if simple_entities[i].valid then
			simple_entities[i].die("enemy", simple_entities[i])
		end
	end
end

function Public.choppy_loot(event)
	local entity = event.entity
	if choppy_entity_yield[entity.name] then
		if event.buffer then event.buffer.clear() end
		if not event.player_index then return end
		local amount = get_ore_amount()
		local second_item_amount = math_random(2,5)
		local second_item = "wood"
		local main_item = choppy_entity_yield[entity.name][math_random(1,#choppy_entity_yield[entity.name])]

		entity.surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "+" .. amount .. " [item=" .. main_item .. "] +" .. second_item_amount .. " [item=" .. second_item .. "]",
			color = {r=0.8,g=0.8,b=0.8}
		})

		local player = game.players[event.player_index]
		reward_ores(amount, main_item, entity.surface, player)

		local inserted_count = player.insert({name = second_item, count = second_item_amount})
		second_item_amount = second_item_amount - inserted_count
		if second_item_amount > 0 then
			entity.surface.spill_item_stack(entity.position,{name = second_item, count = second_item_amount}, true)
		end
	end
end

function Public.rocky_loot(event)
	local surface = game.surfaces[global.active_surface_index]
	local player = game.players[event.player_index]
	surface.spill_item_stack(player.position,{name = "raw-fish", count = math_random(1,3)},true)
	local amount = get_ore_amount()
	local rock_mining = {"iron-ore", "iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "copper-ore", "stone", "stone", "coal", "coal"}
	local mined_loot = rock_mining[math_random(1,#rock_mining)]
	surface.create_entity({
		name = "flying-text",
		position = {player.position.x, player.position.y - 0.5},
		text = "+" .. amount .. " [img=item/" .. mined_loot .. "]",
		color = {r=0.98, g=0.66, b=0.22}
	})
	reward_ores(amount, mined_loot, surface, player)
end

local ore_yield = {
	["behemoth-biter"] = 5,
	["behemoth-spitter"] = 5,
	["behemoth-worm-turret"] = 9,
	["big-biter"] = 3,
	["big-spitter"] = 3,
	["big-worm-turret"] = 7,
	["biter-spawner"] = 16,
	["medium-biter"] = 2,
	["medium-spitter"] = 2,
	["medium-worm-turret"] = 5,
	["small-biter"] = 1,
	["small-spitter"] = 1,
	["small-worm-turret"] = 3,
	["spitter-spawner"] = 16,
}

function Public.swamp_loot(event)
	local surface = game.surfaces[global.active_surface_index]
	local amount = get_ore_amount() / 10
	if ore_yield[event.entity.name] then
		amount = get_ore_amount() / 10 * ore_yield[event.entity.name]
	end
	game.print(amount)
	local rock_mining = {"iron-ore", "coal", "coal", "coal", "coal"}
	local mined_loot = rock_mining[math_random(1,#rock_mining)]
	surface.spill_item_stack(event.entity.position,{name = mined_loot, count = amount}, true)
end

return Public
