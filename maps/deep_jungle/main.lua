require 'modules.no_deconstruction_of_neutral_entities'
require 'modules.spawners_contain_biters'
require 'modules.biters_yield_coins'
require 'modules.rocks_yield_coins'
require 'modules.flashlight_toggle_button'
require 'maps.deep_jungle.generate'

local Event = require 'utils.event'
local map_functions = require 'utils.tools.map_functions'
local Task = require 'utils.task'
local DPT = require 'maps.deep_jungle.table'
local random = math.random

local function on_chunk_charted(event)
    local settings = DPT.get('settings')
    local surface = game.get_surface(event.surface_index)
    local deco = game.decorative_prototypes
    local position = event.position
    if settings.chunks_charted[tostring(position.x) .. tostring(position.y)] then
        return
    end
    settings.chunks_charted[tostring(position.x) .. tostring(position.y)] = true

    local decorative_names = {}
    for k, v in pairs(deco) do
        if v.autoplace_specification then
            decorative_names[#decorative_names + 1] = k
        end
    end
    surface.regenerate_decorative(decorative_names, {position})

    if random(1, 14) ~= 1 then
        return
    end

    map_functions.draw_rainbow_patch({x = position.x * 32 + random(1, 32), y = position.y * 32 + random(1, 32)}, surface, random(14, 26), 2000)
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    local surface = game.get_surface('deep_jungle')
    if player.online_time < 5 and surface.is_chunk_generated({0, 0}) then
        player.teleport(surface.find_non_colliding_position('character', {0, 0}, 2, 1), 'deep_jungle')
    else
        if player.online_time < 5 then
            player.teleport({0, 0}, 'deep_jungle')
        end
    end
    if player.online_time < 2 then
        player.insert {name = 'iron-plate', count = 32}
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    local surface = entity.surface
    if entity.type == 'tree' then
        if random(1, 8) == 1 then
            local p = surface.find_non_colliding_position('small-biter', entity.position, 2, 0.5)
            if p then
                surface.create_entity {name = 'small-biter', position = entity.position}
            end
            return
        end
        if random(1, 16) == 1 then
            local p = surface.find_non_colliding_position('medium-biter', entity.position, 2, 0.5)
            if p then
                surface.create_entity {name = 'medium-biter', position = entity.position}
            end
            return
        end
        if random(1, 32) == 1 then
            local p = surface.find_non_colliding_position('big-biter', entity.position, 2, 0.5)
            if p then
                surface.create_entity {name = 'big-biter', position = entity.position}
            end
            return
        end
        if random(1, 512) == 1 then
            local p = surface.find_non_colliding_position('behemoth-biter', entity.position, 2, 0.5)
            if p then
                surface.create_entity {name = 'behemoth-biter', position = entity.position}
            end
            return
        end
    end
    if entity.type == 'simple-entity' then
        if random(1, 8) == 1 then
            surface.create_entity {name = 'small-worm-turret', position = entity.position}
            return
        end
        if random(1, 16) == 1 then
            surface.create_entity {name = 'medium-worm-turret', position = entity.position}
            return
        end
        if random(1, 32) == 1 then
            surface.create_entity {name = 'big-worm-turret', position = entity.position}
            return
        end
    end
end

local function chunk_load()
    local tick = game.tick
    local settings = DPT.get('settings')
    if settings.chunk_load_tick then
        if settings.chunk_load_tick < tick then
            settings.force_chunk = false
            DPT.remove('settings', 'chunk_load_tick')
            Task.set_queue_speed(8)
        end
    end
end

local on_tick = function()
    local tick = game.tick
    if tick % 40 == 0 then
        chunk_load()
    end
end

local function on_init()
    local map_gen_settings = {}
    local settings = DPT.get('settings')

    map_gen_settings.moisture = 0.99
    map_gen_settings.water = 'none'
    map_gen_settings.starting_area = 'normal'
    map_gen_settings.cliff_settings = {cliff_elevation_interval = 4, cliff_elevation_0 = 0.1}
    map_gen_settings.autoplace_controls = {
        ['coal'] = {frequency = 'none', size = 'none', richness = 'none'},
        ['stone'] = {frequency = 'none', size = 'none', richness = 'none'},
        ['copper-ore'] = {frequency = 'none', size = 'none', richness = 'none'},
        ['iron-ore'] = {frequency = 'none', size = 'none', richness = 'none'},
        ['crude-oil'] = {frequency = 'very-high', size = 'big', richness = 'normal'},
        ['trees'] = {frequency = 'none', size = 'none', richness = 'none'},
        ['enemy-base'] = {frequency = 'high', size = 'big', richness = 'good'}
    }
    game.create_surface('deep_jungle', map_gen_settings)
    game.forces.player.set_spawn_position({0, 0}, game.surfaces['deep_jungle'])
    settings.force_chunk = true
    settings.chunk_load_tick = game.tick + 200
end

Event.on_init(on_init)
Event.add(defines.events.on_chunk_charted, on_chunk_charted)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.on_nth_tick(10, on_tick)

require 'modules.rocks_yield_ore'
