local Event = require 'utils.event'
local Server = require 'utils.server'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local SoftReset = require 'utils.functions.soft_reset'
local Token = require 'utils.token'

local math_random = math.random
local table_shuffle = table.shuffle_table

local dataset = 'scenario_settings'
local dataset_key = 'scrap_towny_ffa'
local dataset_key_dev = 'scrap_towny_ffa_dev'

local Public = {}

local map_width = 3840
local map_height = 3840

local apply_startup_settings_token =
    Token.register(
    function(data)
        local this = ScenarioTable.get_table()
        local settings = {}

        if not data or not data.value then
            if this.shuffle_random_victory_time and math.random(1, 32) == 1 then
                this.required_time_to_win = 48
                this.required_time_to_win_in_ticks = 10368000
                this.surface_terrain = 'forest'
            end
        else
            local value = data.value
            if value.required_time_to_win == 48 then
                this.required_time_to_win = 72
                this.required_time_to_win_in_ticks = 15552000
            else
                this.required_time_to_win = 48
                this.required_time_to_win_in_ticks = 10368000
            end
            if value.surface_terrain == 'forest' then
                this.surface_terrain = 'desert'
            else
                this.surface_terrain = 'forest'
            end
        end

        settings.required_time_to_win = this.required_time_to_win
        settings.required_time_to_win_in_ticks = this.required_time_to_win_in_ticks
        settings.surface_terrain = this.surface_terrain

        Server.set_data(dataset, dataset_key, settings)
    end
)

local apply_startup_settings = function(this, server_name_matches)
    local settings = {}

    if this.required_time_to_win == 48 then
        this.required_time_to_win = 72
        this.required_time_to_win_in_ticks = 15552000
    else
        this.required_time_to_win = 48
        this.required_time_to_win_in_ticks = 10368000
    end
    if this.surface_terrain == 'forest' then
        this.surface_terrain = 'desert'
    else
        this.surface_terrain = 'forest'
    end

    settings.required_time_to_win = this.required_time_to_win
    settings.required_time_to_win_in_ticks = this.required_time_to_win_in_ticks
    settings.surface_terrain = this.surface_terrain

    if server_name_matches then
        Server.set_data(dataset, dataset_key, settings)
    else
        Server.set_data(dataset, dataset_key_dev, settings)
    end
end

function Public.nuke(position)
    local this = ScenarioTable.get_table()
    local map_surface = game.get_surface(this.active_surface_index)
    if not map_surface or not map_surface.valid then
        return
    end
    map_surface.create_entity({name = 'atomic-rocket', position = position, target = position, speed = 0.5})
end

function Public.armageddon()
    local targets = {}
    local offset = 1
    local this = ScenarioTable.get_table()
    for _, town_center in pairs(this.town_centers) do
        local market = town_center.market
        if market and market.valid then
            for _ = 1, 5 do
                local px = market.position.x + math_random(1, 256) - 128
                local py = market.position.y + math_random(1, 256) - 128
                targets[offset] = {x = px, y = py}
                offset = offset + 1
            end
            targets[offset] = {x = market.position.x, y = market.position.y}
            offset = offset + 1
        end
    end
    for _, spaceship in pairs(this.spaceships) do
        local market = spaceship.market
        if market and market.valid then
            for _ = 1, 5 do
                local px = market.position.x + math_random(1, 256) - 128
                local py = market.position.y + math_random(1, 256) - 128
                targets[offset] = {x = px, y = py}
                offset = offset + 1
            end
            targets[offset] = {x = market.position.x, y = market.position.y}
            offset = offset + 1
        end
    end

    table_shuffle(targets)

    for i, pos in pairs(targets) do
        local position = pos
        local future = game.tick + i * 60
        -- schedule to run this method again with a higher radius on next tick
        if not this.nuke_tick_schedule[future] then
            this.nuke_tick_schedule[future] = {}
        end
        this.nuke_tick_schedule[future][#this.nuke_tick_schedule[future] + 1] = {
            callback = 'nuke',
            params = {position}
        }
    end
end

function Public.initialize(init)
    local this = ScenarioTable.get_table()

    if not init then
        local server_name_matches = Server.check_server_name('Towny')
        apply_startup_settings(this, server_name_matches)
    end

    local surface_seed = game.surfaces['nauvis']
    -- this overrides what is in the map_gen_settings.json file
    local mgs = surface_seed.map_gen_settings
    mgs.default_enable_all_autoplace_controls = true -- don't mess with this!
    mgs.autoplace_controls = {
        coal = {frequency = 2, size = 0.1, richness = 0.2},
        stone = {frequency = 2, size = 0.1, richness = 0.2},
        ['copper-ore'] = {frequency = 5, size = 0.1, richness = 0.1},
        ['iron-ore'] = {frequency = 5, size = 0.1, richness = 0.1},
        ['uranium-ore'] = {frequency = 0, size = 0.1, richness = 0.2},
        ['crude-oil'] = {frequency = 5, size = 0.05, richness = 0.5},
        trees = {frequency = 2, size = 1, richness = 1},
        ['enemy-base'] = {frequency = 2, size = 2, richness = 1}
    }
    mgs.autoplace_settings = {
        entity = {
            settings = {
                ['rock-huge'] = {frequency = 2, size = 1, richness = 1},
                ['rock-big'] = {frequency = 2, size = 1, richness = 1},
                ['sand-rock-big'] = {frequency = 2, size = 1, richness = 1}
            }
        },
        decorative = {
            settings = {
                ['rock-tiny'] = {frequency = 10, size = 'normal', richness = 'normal'},
                ['rock-small'] = {frequency = 5, size = 'normal', richness = 'normal'},
                ['rock-medium'] = {frequency = 2, size = 'normal', richness = 'normal'},
                ['sand-rock-small'] = {frequency = 10, size = 'normal', richness = 'normal'},
                ['sand-rock-medium'] = {frequency = 5, size = 'normal', richness = 'normal'}
            }
        },
        tile = {
            settings = {
                ['deepwater'] = {frequency = 1, size = 0, richness = 1},
                ['deepwater-green'] = {frequency = 1, size = 0, richness = 1},
                ['water'] = {frequency = 1, size = 0, richness = 1},
                ['water-green'] = {frequency = 1, size = 0, richness = 1},
                ['water-mud'] = {frequency = 1, size = 0, richness = 1},
                ['water-shallow'] = {frequency = 1, size = 0, richness = 1}
            },
            treat_missing_as_default = true
        }
    }
    mgs.cliff_settings = {
        name = 'cliff',
        cliff_elevation_0 = 5,
        cliff_elevation_interval = 10,
        richness = 0.4
    }
    mgs.water = 0
    mgs.peaceful_mode = false
    mgs.starting_area = 'none'
    mgs.terrain_segmentation = 8
    -- terrain size is 64 x 64 chunks, water size is 80w x 80
    mgs.width = map_width
    mgs.height = map_height
    --mgs.starting_points = {
    --	{x = 0, y = 0}
    --}
    if this.surface_terrain == 'forest' then
        mgs.terrain_segmentation = 'very-low'
        mgs.autoplace_controls.trees = {
            frequency = 0.666,
            richness = 2,
            size = 2
        }
        mgs.property_expression_names = {
            ['control-setting:aux:bias'] = '-0.500000',
            ['control-setting:moisture:bias'] = '0.500000',
            ['control-setting:moisture:frequency:multiplier'] = '4.000000',
            ['starting-lake-noise-amplitude'] = 0,
            -- allow enemies to get up close on spawn
            ['starting-area'] = 0,
            ['enemy-base-intensity'] = 1,
            -- adjust this value to set how many nests spawn per tile
            ['enemy-base-frequency'] = 0.4,
            -- this will make and average base radius around 12 tiles
            ['enemy-base-radius'] = 12
        }
    else
        mgs.terrain_segmentation = 'very-big'
        mgs.property_expression_names = {
            ['control-setting:aux:bias'] = '-0.500000',
            ['control-setting:aux:frequency:multiplier'] = '6.000000',
            ['control-setting:moisture:bias'] = '-0.500000',
            ['control-setting:moisture:frequency:multiplier'] = '6.000000',
            ['enemy-base-frequency'] = '0.4',
            ['enemy-base-intensity'] = '1',
            ['enemy-base-radius'] = '12',
            ['starting-area'] = '0',
            ['starting-lake-noise-amplitude'] = '0'
        }
    end

    mgs.seed = math_random(100000, 9999999)

    if not this.active_surface_index then
        this.active_surface_index = game.create_surface('towny', mgs).index
    else
        this.active_surface_index = SoftReset.soft_reset_map(game.surfaces[this.active_surface_index], mgs, nil).index
    end

    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end

    -- Server.try_get_data(dataset, dataset_key, set_victory_length_token)

    surface.map_gen_settings = mgs
    surface.peaceful_mode = false
    surface.always_day = false
    surface.freeze_daytime = false
    -- surface.map_gen_settings.water = 0.5
    surface.clear(true)
    surface.regenerate_entity({'rock-huge', 'rock-big', 'sand-rock-big'})
    surface.regenerate_decorative()
end

local function on_tick()
    local this = ScenarioTable.get_table()
    if not this.nuke_tick_schedule[game.tick] then
        return
    end
    for _, token in pairs(this.nuke_tick_schedule[game.tick]) do
        local callback = token.callback
        local params = token.params
        if callback == 'nuke' then
            Public.nuke(params[1])
        end
    end
    this.nuke_tick_schedule[game.tick] = nil
end

function Public.clear_nuke_schedule()
    local this = ScenarioTable.get_table()
    this.nuke_tick_schedule = {}
end

Event.add(defines.events.on_tick, on_tick)

Event.add(
    Server.events.on_server_started,
    function()
        local this = ScenarioTable.get_table()
        if this.settings_applied then
            return
        end

        local server_name_matches = Server.check_server_name('Towny')

        this.settings_applied = true

        if server_name_matches then
            Server.try_get_data(dataset, dataset_key, apply_startup_settings_token)
        else
            Server.try_get_data(dataset, dataset_key_dev, apply_startup_settings_token)
            this.test_mode = true
        end
    end
)

return Public
