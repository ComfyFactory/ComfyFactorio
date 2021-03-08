-- Queue entities to spawn at certain ticks -- mewmew
-- Add entities via .add_to_queue(tick, surface, entity_data, non_colliding_position_search_radius)
-- Example Esq.add_to_queue(3486, game.surfaces.nauvis, {name = "small-biter", position = {16, 17}, force = "player"}, false)

local Event = require 'utils.event'
local Global = require 'utils.global'

local table_insert = table.insert

local Public = {}

local ESQ = {}
Global.register(
    ESQ,
    function(tbl)
        ESQ = tbl
    end
)

local function spawn_entity(surface_index, entity_data, non_colliding_position_search_radius)
	local surface = game.surfaces[surface_index]
	if not surface then return end
	if not surface.valid then return end
	if non_colliding_position_search_radius then
		local p = surface.find_non_colliding_position(entity_data.name, entity_data.position, non_colliding_position_search_radius, 0.5)
		if p then entity_data.position = p end
	end
	surface.create_entity(entity_data)	
end

function Public.add_to_queue(tick, surface, entity_data, non_colliding_position_search_radius)
	if not surface then return end
	if not surface.valid then return end
	if not entity_data then return end
	if not entity_data.position then return end
	if not entity_data.name then return end
	if not tick then return end
	
	local queue = ESQ.queue
	local entity = {}
	
	for k, v in pairs(entity_data) do	entity[k] = v end
	
	tick = tostring(tick)
	if not queue[tick] then queue[tick] = {} end
	table_insert(queue[tick], {surface.index, entity, non_colliding_position_search_radius})	
end

local function on_tick()
	local tick = tostring(game.tick)
	if not ESQ.queue[tick] then return end
	for _, v in pairs(ESQ.queue[tick]) do spawn_entity(v[1], v[2], v[3]) end
	ESQ.queue[tick] = nil
end

local function on_init()
	ESQ.queue = {}
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)

return Public

