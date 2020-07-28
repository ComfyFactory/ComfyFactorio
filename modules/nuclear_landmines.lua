local math_random = math.random

local function detonate_nuke(entity)
  local surface = entity.surface
  surface.create_entity({name = "atomic-rocket", position = entity.position, force = entity.force, speed = 1, max_range = 800, target = entity, source = entity})
end

local function on_entity_died(event)
  local entity = event.entity
  if not entity.valid then return end
  if entity.name == "land-mine" then
    if math_random(1,global.nuclear_landmines.chance) == 1 then
      detonate_nuke(entity)
    end
  end
end

local function on_init()
  global.nuclear_landmines = {}
  global.nuclear_landmines.chance = 512
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_entity_died, on_entity_died)
