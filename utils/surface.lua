require 'util'
local Global = require 'utils.global'
local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Commands = require 'utils.commands'
local Public = {}

local this =
{
    surface = nil,
    spawn_position = nil,
    island = false,
    surface_name = 'wbtc',
    surface_index = nil,
    death_mode = true,
    modded = false,
    bypass = false,
    darkness_enabled = false,
    custom_ore_generation = false
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local random = math.random

local function randomFloat()
    local r = 0 + random() * (2 - 0)
    if r < 0.25 then
        r = 0.25
    end
    return r
end

function Public.create_surface(is_modded)
    local map_gen_settings
    if is_modded then
        if not this.surface then
            this.surface = game.surfaces.nauvis.index
            this.surface_name = 'nauvis'
            this.modded = true
        end

        local surface = game.get_surface(this.surface)
        if not surface or not surface.valid then
            return
        end

        -- surface.map_gen_settings = map_gen_settings

        -- surface.request_to_generate_chunks({0, 0}, 0.1)
        -- surface.force_generate_chunk_requests()

        game.forces.player.set_spawn_position({ 0, 0 }, surface)
        this.spawn_position = { 0, 0 }

        if this.darkness_enabled then
            -- surface.ticks_per_day = surface.ticks_per_day * 2
            surface.min_brightness = 0
            surface.brightness_visual_weights = { 1, 1, 1 }
        else
            -- surface.ticks_per_day = surface.ticks_per_day * 2
            surface.min_brightness = 0.08
        end
    else -- not modded
        map_gen_settings = {}
        map_gen_settings.water = random(0, 15) / 10
        if this.death_mode then
            map_gen_settings.starting_area = random(1, 5) / 2
        else
            map_gen_settings.starting_area = random(2, 4)
        end
        map_gen_settings.seed = random(12345, 999999)
        map_gen_settings.cliff_settings = { cliff_elevation_interval = random(10, 35), cliff_elevation_0 = random(10, 35) }
        if this.custom_ore_generation then
            map_gen_settings.autoplace_controls =
            {
                ['coal'] = { frequency = 0, size = 0, richness = 0 },
                ['stone'] = { frequency = 0, size = 0, richness = 0 },
                ['copper-ore'] = { frequency = 0, size = 0, richness = 0 },
                ['iron-ore'] = { frequency = 0, size = 0, richness = 0 },
                ['crude-oil'] = { frequency = randomFloat(), size = randomFloat() / 2, richness = 1 },
                ['uranium-ore'] = { frequency = 0, size = 0, richness = 0 },
                ['trees'] = { frequency = 0.88, size = random(0, 15) / 10, richness = 1 },
                ['enemy-base'] = { frequency = 1, size = 1, richness = 1 }
            }
        elseif this.death_mode then
            map_gen_settings.autoplace_controls =
            {
                ['coal'] = { frequency = randomFloat(), size = randomFloat() / 2, richness = 1 },
                ['stone'] = { frequency = randomFloat(), size = randomFloat() / 2, richness = 1 },
                ['copper-ore'] = { frequency = randomFloat(), size = randomFloat() / 2, richness = 1 },
                ['iron-ore'] = { frequency = randomFloat(), size = randomFloat() / 2, richness = 1 },
                ['crude-oil'] = { frequency = randomFloat(), size = randomFloat() / 2, richness = 1 },
                ['uranium-ore'] = { frequency = randomFloat(), size = randomFloat() / 2, richness = 1 },
                ['trees'] = { frequency = 0.44, size = random(0, 15) / 10, richness = 1 },
                ['enemy-base'] = { frequency = 1, size = 1, richness = 1 }
            }
        else
            map_gen_settings.autoplace_controls =
            {
                ['coal'] = { frequency = 1, size = random(1, 5) / 2, richness = random(1, 5) / 2 },
                ['stone'] = { frequency = 1, size = random(1, 5) / 2, richness = random(1, 5) / 2 },
                ['copper-ore'] = { frequency = 1, size = random(1, 5) / 2, richness = random(1, 5) / 2 },
                ['iron-ore'] = { frequency = 1, size = random(1, 5) / 2, richness = random(1, 5) / 2 },
                ['crude-oil'] = { frequency = 1, size = random(1, 5) / 2, richness = random(1, 5) / 2 },
                ['uranium-ore'] = { frequency = 1, size = random(1, 5) / 2, richness = random(1, 5) / 2 },
                ['trees'] = { frequency = 0.88, size = random(0, 15) / 10, richness = 1 },
                ['enemy-base'] = { frequency = 1, size = 1, richness = 1 }
            }
        end

        map_gen_settings.terrain_segmentation = random(2, 4)

        map_gen_settings.property_expression_names =
        {
            cliffiness = 0,
            -- ['tile:water:probability'] = -10000,
            -- ['tile:deep-water:probability'] = -10000,
            ['control-setting:aux:frequency:multiplier'] = '4.000000',
            ['control-setting:moisture:bias'] = '-0.150000',
            ['control-setting:moisture:frequency:multiplier'] = '3.000000'
        }

        if (this.island) then
            map_gen_settings.property_expression_names.elevation = '0_17-island'
        end

        if not this.surface then
            this.surface = game.create_surface(this.surface_name, map_gen_settings).index
        end

        local surface = game.get_surface(this.surface)
        if not surface or not surface.valid then
            return
        end

        if this.darkness_enabled then
            -- surface.ticks_per_day = surface.ticks_per_day * 2
            surface.min_brightness = 0
            surface.brightness_visual_weights = { 1, 1, 1 }
        else
            -- surface.ticks_per_day = surface.ticks_per_day * 2
            surface.min_brightness = 0.08
        end

        surface.request_to_generate_chunks({ 0, 0 }, 2)
        surface.force_generate_chunk_requests()

        -- 4x difficulty_settings
        game.difficulty_settings.technology_price_multiplier = 4

        --game.forces.player.technologies["landfill"].enabled = false
        --game.forces.player.technologies["optics"].researched = true
        game.forces.player.set_spawn_position({ 0, 0 }, surface)
        this.spawn_position = { 0, 0 }
    end
    -- game.map_settings.pollution.enabled = false
end

local function on_init()
    if ServerCommands.is_game_modded() then
        this.surface_name = 'nauvis'
        this.modded = true
        Public.create_surface(true)
        return
    end

    if not this.nauvis_cleared then
        local mgs = game.surfaces['nauvis'].map_gen_settings
        mgs.width = 16
        mgs.height = 16
        game.surfaces['nauvis'].map_gen_settings = mgs
        game.surfaces['nauvis'].clear()
        this.nauvis_cleared = true
    end
    Public.create_surface()
end

function Public.get_surface()
    return this.surface
end

function Public.get_surface_name()
    return this.surface_name
end

function Public.get_surface_index()
    return Public.get_surface()
end

function Public.set_spawn_pos(var)
    this.spawn_position = var
end

function Public.set_modded(value)
    this.modded = value or false
end

function Public.bypass(value)
    this.bypass = value or false
end

function Public.set_island(value)
    this.island = value or false
end

function Public.custom_ore_generation(value)
    this.custom_ore_generation = value or false
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Event.on_init(on_init)

Event.add(
    defines.events.on_player_created,
    function (event)
        local player = game.players[event.player_index]

        -- Move the player to the game surface immediately.
        local pos = game.surfaces[this.surface_name].find_non_colliding_position('character', { x = 0, y = 0 }, 3, 0)
        player.teleport(pos, this.surface_name)

        if this.modded then
            if player.online_time == 0 then
                player.insert({ name = 'pistol', count = 1 })
                player.insert({ name = 'firearm-magazine', count = 16 })
                player.insert({ name = 'iron-plate', count = 64 })
                player.insert({ name = 'burner-mining-drill', count = 4 })
                player.insert({ name = 'stone-furnace', count = 4 })
            end
        end
    end
)

Commands.new('surface_resource_increase', 'Increases surface resources.')
    :require_role('surface_resource')
    :callback(function (player)
        for _, surface in pairs(game.surfaces) do
            for _, resource in pairs(surface.find_entities_filtered { type = 'resource' }) do
                if resource and resource.amount < 1000 then
                    resource.amount = math.random(5000, 15000)
                end
            end
        end
        player.print('[Resources] Resources has been increased.', Color.yellow)
    end
    )

Commands.new('surface_resource_decrease', 'Decreases surface resources.')
    :require_role('surface_resource')
    :callback(function (player)
        for _, surface in pairs(game.surfaces) do
            for _, resource in pairs(surface.find_entities_filtered { type = 'resource' }) do
                if resource and resource.amount > 1000 then
                    resource.amount = math.random(500, 1000)
                end
            end
        end
        player.print('[Surface] Resources has been decreased.', Color.yellow)
    end
    )

Commands.new('surface_toggle_darkness', 'Toggles between darkness.')
    :require_role('surface_darkness')
    :callback(function (player)
        local surface = game.get_surface(this.surface)
        if not surface or not surface.valid then
            return
        end

        if this.darkness_enabled then
            this.darkness_enabled = false
            surface.min_brightness = 0.08
            surface.brightness_visual_weights = { 0, 0, 0 }
            player.print('[Surface] Darkness have been deactivated.', Color.yellow)
        else
            this.darkness_enabled = true
            surface.min_brightness = 0
            surface.brightness_visual_weights = { 1, 1, 1 }
            player.print('[Surface] Darkness have been activated.', Color.yellow)
        end
    end
    )

return Public
