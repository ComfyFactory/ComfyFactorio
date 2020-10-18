local Public = {}

local Constants = require 'maps.cave_miner_v2.constants'
local BiterRaffle = require "functions.biter_raffle"
local LootRaffle = require "functions.loot_raffle"

local math_sqrt = math.sqrt
local math_random = math.random
local math_floor = math.floor

local spawn_amount_rolls = {}
for a = 48, 1, -1 do table.insert(spawn_amount_rolls, math_floor(a ^ 5)) end

function Public.roll_biter_amount()
	local max_chance = 0
	for k, v in pairs(spawn_amount_rolls) do
		max_chance = max_chance + v
	end
	local r = math_random(0, max_chance)	
	local current_chance = 0
	for k, v in pairs(spawn_amount_rolls) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

function Public.spawn_player(player)
	if not player.character then
		player.create_character()
	end
	
	local surface = player.surface	
	local position		
	position = surface.find_non_colliding_position("character", player.force.get_spawn_position(surface), 48, 1)
	if not position then position = player.force.get_spawn_position(surface) end	
	player.teleport(position, surface)
	
	for name, count in pairs(Constants.starting_items) do
		player.insert({name = name, count = count})
	end
end

function Public.set_mining_speed(cave_miner, force)
	force.manual_mining_speed_modifier = -0.50 + cave_miner.pickaxe_tier * 0.35
	return force.manual_mining_speed_modifier
end

function Public.place_worm(surface, position, multiplier)
	local d = math_sqrt(position.x ^ 2 + position.y ^ 2)
	surface.create_entity({name = BiterRaffle.roll("worm", d * 0.0001 * multiplier), position = position, force = "enemy"})
	return 
end

function Public.spawn_random_biter(surface, position, multiplier)
	local d = math_sqrt(position.x ^ 2 + position.y ^ 2)
	local name = BiterRaffle.roll("mixed", d * 0.0001 * multiplier)
	local non_colliding_position = surface.find_non_colliding_position(name, position, 16, 1)
	local unit
	if non_colliding_position then
		unit = surface.create_entity({name = name, position = non_colliding_position, force = "enemy"})
	else
		unit = surface.create_entity({name = name, position = position, force = "enemy"})
	end
	unit.ai_settings.allow_try_return_to_spawner = true
	unit.ai_settings.allow_destroy_when_commands_fail = false
	return unit
end

function Public.loot_crate(surface, position, multiplier, slots, container_name)
	local d = math_sqrt(position.x ^ 2 + position.y ^ 2)
	local item_stacks = LootRaffle.roll(d * multiplier, slots, loot_blacklist)
	local container = surface.create_entity({name = container_name, position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do container.insert(item_stack) end
	container.minable = false
end

function Public.place_crude_oil(surface, position, multiplier)
	if not surface.can_place_entity({name = "crude-oil", position = position, amount = 1}) then return end
	local d = math_sqrt(position.x ^ 2 + position.y ^ 2)
	local amount = math_random(50000, 100000) + d * 100 * multiplier
	surface.create_entity({name = "crude-oil", position = position, amount = amount})
end

function Public.create_top_gui(player)
	local frame = player.gui.top.cave_miner
	if frame then return end
	frame = player.gui.top.add({type = "frame", name = "cave_miner", direction = "horizontal"})
	frame.style.maximal_height = 38
	
	local label = frame.add({type = "label", caption = "Loading..."})
	label.style.font = "heading-2"
	label.style.font_color = {225, 225, 225}
	label.style.margin = 0
	label.style.padding = 0
	
	local label = frame.add({type = "label", caption = "Loading..."})
	label.style.font = "heading-2"
	label.style.font_color = {225, 225, 225}
	label.style.margin = 0
	label.style.padding = 0
end

function Public.update_top_gui(cave_miner)
	local pickaxe_tiers = Constants.pickaxe_tiers
	for _, player in pairs(game.connected_players) do
		local element = player.gui.top.cave_miner
		if element and element.valid then		
			element.children[1].caption = "Tier " .. cave_miner.pickaxe_tier .. " - " .. pickaxe_tiers[cave_miner.pickaxe_tier] .. "  | "
			element.children[1].tooltip = "Mining speed " .. (1 + game.forces.player.manual_mining_speed_modifier) * 100 .. "%"
			
			element.children[2].caption = "Rocks broken: " .. cave_miner.rocks_broken
		end
	end
end

return Public