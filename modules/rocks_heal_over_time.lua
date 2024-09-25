-- rocks and other entities heal over time -- by mewmew
local Event = require 'utils.event'

local entity_whitelist = {
    ['big-rock'] = true,
    ['big-sand-rock'] = true,
    ['huge-rock'] = true,
    ['mineable-wreckage'] = true
}

local function process_entity(v, key)
    if not v.entity then
        storage.entities_regenerate_health[key] = nil
        return
    end
    if not v.entity.valid then
        storage.entities_regenerate_health[key] = nil
        return
    end

    if v.last_damage + 36000 < game.tick then
        v.entity.health = v.entity.health + math.floor(v.entity.prototype.max_health * 0.02)
        if v.entity.prototype.max_health == v.entity.health then
            storage.entities_regenerate_health[key] = nil
        end
    end
end

local function on_entity_damaged(event)
    if not event.entity.valid then
        return
    end
    if event.entity.force.index ~= 3 then
        return
    end
    if not entity_whitelist[event.entity.name] then
        return
    end
    storage.entities_regenerate_health[tostring(event.entity.position.x) .. '_' .. tostring(event.entity.position.y)] = { last_damage = game.tick, entity = event.entity }
end

local function tick()
    for key, entity in pairs(storage.entities_regenerate_health) do
        process_entity(entity, key)
    end
end

local function on_init()
    storage.entities_regenerate_health = {}
end

Event.on_nth_tick(1800, tick)
Event.on_init(on_init)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
