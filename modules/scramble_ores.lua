local Event = require 'utils.event'

local diversity = 0.20
local exempt_area = 200 --This is the radius of the starting area that can't be affected.
local stone_byproduct = false --Delete patches of stone.  Stone only appears as a byproduct.
local stone_ratio = 0.25 --If math.random() is between diversity and this, it's stone.

--Build a table of potential ores to pick from.  Uranium is exempt from popping up randomly.
local function init()
    global.diverse_ores = {}
    for k, v in pairs(game.entity_prototypes) do
        if v.type == 'resource' and v.resource_category == 'basic-solid' and v.mineable_properties.required_fluid == nil then
            table.insert(global.diverse_ores, v.name)
        end
    end
end

local function scramble(event)
    local ores = event.surface.find_entities_filtered {type = 'resource', area = event.area}
    for k, v in pairs(ores) do
        if math.abs(v.position.x) > exempt_area or math.abs(v.position.y) > exempt_area then
            if v.prototype.resource_category == 'basic-solid' then
                local random = math.random()
                if v.name == 'stone' and stone_byproduct then
                    v.destroy()
                elseif random < diversity then --Replace!
                    local refugee = global.diverse_ores[math.random(#global.diverse_ores)]
                    event.surface.create_entity {name = refugee, position = v.position, amount = v.amount}
                    v.destroy()
                elseif stone_byproduct and random < stone_ratio then --Replace with stone!
                    event.surface.create_entity {name = 'stone', position = v.position, amount = v.amount}
                    v.destroy()
                end
            end
        end
    end
end

Event.on_init(init)
Event.add(defines.events.on_chunk_generated, scramble)
