-- improves the damage of the railgun and adds visual effects -- by mewmew

local event = require 'utils.event'
local damage_min = 1000
local damage_max = 2000
local math_random = math.random
local additional_visual_effects = true
local do_splash_damage = true

local biological_target_types = {
	["unit"] = true,
	["player"] = true,
	["turret"] = true,
	["unit-spawner"] = true	
}

local function create_visuals(source_entity, target_entity)
	if additional_visual_effects then
		local surface = target_entity.surface
		local beams = surface.find_entities_filtered({name = "railgun-beam", area = {{source_entity.position.x - 1, source_entity.position.y - 1}, {source_entity.position.x + 1, source_entity.position.y + 1}}, limit = 1})
		if beams[1] then
			surface.create_entity({name = "railgun-beam", position = beams[1].position, source = beams[1].position, target = target_entity.position})
		else
			surface.create_entity({name = "railgun-beam", position = source_entity.position, source = source_entity.position, target = target_entity.position})
		end		
		surface.create_entity({name = "water-splash", position = target_entity.position})
		if biological_target_types[target_entity.type] then
			surface.create_entity({name = "blood-explosion-small", position = target_entity.position})
			for x = -8, 8, 1 do
				for y = -8, 8, 1 do
					if math_random(1, 16) == 1 then
						surface.create_entity({name = "blood-fountain", position = {target_entity.position.x + (x * 0.1), target_entity.position.y + (y * 0.1)}})
						surface.create_entity({name = "blood-fountain-big", position = {target_entity.position.x + (x * 0.1), target_entity.position.y + (y * 0.1)}})
					end
				end
			end
		else
			for x = -4, 4, 1 do
				for y = -4, 4, 1 do													
					if math_random(1, 3) == 1 then
						surface.create_trivial_smoke({name="smoke-fast", position={target_entity.position.x + (x * 0.35), target_entity.position.y + (y * 0.35)}})
					end													
				end
			end
		end		
	end
end

local function do_splash_damage_around_entity(source_entity)
	if not do_splash_damage then return end
	local entities = source_entity.surface.find_entities_filtered({area = {{source_entity.position.x - 2.5, source_entity.position.y - 2.5}, {source_entity.position.x + 2.5, source_entity.position.y + 2.5}}})
	for _, entity in pairs(entities) do
		if entity.health and entity ~= source_entity then			
			create_visuals(source_entity, entity)
			entity.damage(math_random(math.ceil(damage_min / 50), math.ceil(damage_max / 50)), source_entity.force, "physical")	
		end
	end
end

local function on_entity_damaged(event)	
	if not event.cause then return end
	if event.cause.name ~= "player" then return end
	if event.damage_type.name ~= "physical" then return end
	if event.original_damage_amount ~= 100 then return end
	
	local player = event.cause
	if player.shooting_state.state == defines.shooting.not_shooting then return end
	local selected_weapon = player.get_inventory(defines.inventory.player_guns)[player.selected_gun_index]
	if selected_weapon.name ~= "railgun" then return end
	
	create_visuals(event.cause, event.entity)
	do_splash_damage_around_entity(event.entity)
	
	event.entity.health = event.entity.health + event.final_damage_amount
	event.entity.damage(math_random(damage_min, damage_max), player.force, "physical")	
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)