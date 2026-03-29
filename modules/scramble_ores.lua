local Global = require 'utils.global'
local Event = require 'utils.event'

local Public = {}

local insert = table.insert

local this =
{
    diversity_quote = 1,
    exempt_area = 200,
    stone_byproduct = false,
    stone_byproduct_ratio = 0.25,
    diverse_ores = {}
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local function init()
    for _, v in pairs(prototypes.entity) do
        if v.type == 'resource' and v.resource_category == 'basic-solid' and v.mineable_properties.required_fluid == nil then
            insert(this.diverse_ores, v.name)
        end
    end
end

function Public.scramble(event)
    local surface = event.surface
    if not surface then
        return
    end

    local area = event.area

    local ores = surface.find_entities_filtered { type = 'resource', area = area }
    for _, v in pairs(ores) do
        if math.abs(v.position.x) > this.exempt_area or math.abs(v.position.y) > this.exempt_area then
            if v.prototype.resource_category == 'basic-solid' then
                local random = math.random()
                if v.name == 'stone' and this.stone_byproduct then
                    v.destroy()
                elseif random < this.diversity_quote then --Replace!
                    local o = this.diverse_ores[math.random(#this.diverse_ores)]
                    surface.create_entity { name = o, position = v.position, amount = v.amount }
                    v.destroy()
                elseif this.stone_byproduct and random < this.stone_byproduct_ratio then
                    surface.create_entity { name = 'stone', position = v.position, amount = v.amount }
                    v.destroy()
                end
            end
        end
    end
end

function Public.register()
    Event.add(defines.events.on_chunk_generated, Public.scramble)
end

Event.on_init(init)

return Public
