local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'

local Public = {}

function Public.reset()
    local this = ScenarioTable.get_table()
    if this.testing_mode then
        return
    end
    local map_surface = game.get_surface(this.active_surface_index)
    if not map_surface or not map_surface.valid then
        return
    end
    for index = 1, table.size(game.forces), 1 do
        local force = game.forces[index]
        if force ~= nil then
            force.clear_chart(map_surface.name)
        end
    end
end

local function add_force(id, force_name)
    local forces = rendering.get_forces(id)
    for _, force in ipairs(forces) do
        if force.name == force_name or force == force_name then
            return
        end
    end
    forces[#forces + 1] = force_name
    rendering.set_forces(id, forces)
end

local function update_forces(id)
    local forces = rendering.get_forces(id)
    local new_forces = {}
    for _, force in ipairs(forces) do
        if force ~= nil and force.valid then
            new_forces[#new_forces + 1] = force.name
        end
    end
    rendering.set_forces(id, new_forces)
end

local function on_chunk_charted(event)
    local this = ScenarioTable.get_table()
    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    local force = event.force
    local area = event.area
    local markets = surface.find_entities_filtered({area = area, name = 'market'})
    for _, market in pairs(markets) do
        local force_name = market.force.name
        local town_center = this.town_centers[force_name]
        if not town_center then
            return
        end

        -- town caption
        local town_caption = town_center.town_caption
        update_forces(town_caption)
        add_force(town_caption, force.name)
        -- health text
        local health_text = town_center.health_text
        update_forces(health_text)
        add_force(health_text, force.name)
    end
end

Event.add(defines.events.on_chunk_charted, on_chunk_charted)

return Public
