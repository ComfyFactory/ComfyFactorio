local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'

local math_random = math.random
local math_abs = math.abs
local table_shuffle = table.shuffle_table

local Public = {}

--local Server = require 'utils.server'
local map_width = 2560
local map_height = 2560

function Public.nuke(position)
    local surface = game.surfaces['nauvis']
    surface.create_entity({name = 'atomic-rocket', position = position, target = position, speed = 0.5})
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

local function get_seed()
    local max = 4294967296
    local salt = game.surfaces[1].map_gen_settings.seed
    local seed = math_abs(salt + math_random(1, max)) % max + 1
    return seed
end

function Public.initialize()
    if game.surfaces['nauvis'] then
        -- clear the surface
        game.surfaces['nauvis'].clear(false)
    end
    local surface = game.surfaces['nauvis']

    -- this overrides what is in the map_gen_settings.json file
    local mgs = surface.map_gen_settings
    mgs.default_enable_all_autoplace_controls = true -- don't mess with this!
    mgs.autoplace_controls = {
        coal = {frequency = 2, size = 0.1, richness = 0.2},
        stone = {frequency = 2, size = 0.1, richness = 0.2},
        ['copper-ore'] = {frequency = 5, size = 0.1, richness = 0.2},
        ['iron-ore'] = {frequency = 5, size = 0.1, richness = 0.2},
        ['uranium-ore'] = {frequency = 0, size = 0.1, richness = 0.2},
        ['crude-oil'] = {frequency = 5, size = 0.05, richness = 0.5},
        trees = {frequency = 2, size = 1, richness = 1},
        ['enemy-base'] = {frequency = 2, size = 2, richness = 1}
    }
    mgs.autoplace_settings = {
        entity = {
            settings = {
                ['rock-huge'] = {frequency = 2, size = 3, richness = 'very-high'},
                ['rock-big'] = {frequency = 2, size = 3, richness = 'very-high'},
                ['sand-rock-big'] = {frequency = 2, size = 3, richness = 1, 'very-high'}
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
        }
    }
    mgs.cliff_settings = {
        name = 'cliff',
        cliff_elevation_0 = 5,
        cliff_elevation_interval = 10,
        richness = 0.4
    }
    -- water = 0 means no water allowed
    -- water = 1 means elevation is not reduced when calculating water tiles (elevation < 0)
    -- water = 2 means elevation is reduced by 10 when calculating water tiles (elevation < 0)
    --			or rather, the water table is 10 above the normal elevation
    mgs.water = 0.5
    mgs.peaceful_mode = false
    mgs.starting_area = 'none'
    mgs.terrain_segmentation = 8
    -- terrain size is 64 x 64 chunks, water size is 80 x 80
    mgs.width = map_width
    mgs.height = map_height
    --mgs.starting_points = {
    --	{x = 0, y = 0}
    --}
    -- here we put the named noise expressions for the specific noise-layer if we want to override them
    mgs.property_expression_names = {
        -- here we are overriding the moisture noise-layer with a fixed value of 0 to keep moisture consistently dry across the map
        -- it allows to free up the moisture noise expression
        -- low moisture
        --moisture = 0,

        -- here we are overriding the aux noise-layer with a fixed value to keep aux consistent across the map
        -- it allows to free up the aux noise expression
        -- aux should be not sand, nor red sand
        --aux = 0.5,

        -- here we are overriding the temperature noise-layer with a fixed value to keep temperature consistent across the map
        -- it allows to free up the temperature noise expression
        -- temperature should be 20C or 68F
        --temperature = 20,

        -- here we are overriding the cliffiness noise-layer with a fixed value of 0 to disable cliffs
        -- it allows to free up the cliffiness noise expression (which may or may not be useful)
        -- disable cliffs
        --cliffiness = 0,

        -- we can disable starting lakes two ways, one by setting starting-lake-noise-amplitude = 0
        -- or by making the elevation a very large number
        -- make sure starting lake amplitude is 0 to disable starting lakes
        ['starting-lake-noise-amplitude'] = 0,
        -- allow enemies to get up close on spawn
        ['starting-area'] = 0,
        -- this accepts a string representing a named noise expression
        -- or number to determine the elevation based on x, y and distance from starting points
        -- we can not add a named noise expression at this point, we can only reference existing ones
        -- if we have any custom noise expressions defined from a mod, we will be able to use them here
        -- setting it to a fixed number would mean a flat map
        -- elevation < 0 means there is water unless the water table has been changed
        --elevation = -1,
        --elevation = 0,
        --elevation-persistence = 0,

        -- testing
        --["control-setting:moisture:bias"] = 0.5,
        --["control-setting:moisture:frequency:multiplier"] = 0,
        --["control-setting:aux:bias"] = 0.5,
        --["control-setting:aux:frequency:multiplier"] = 1,
        --["control-setting:temperature:bias"] = 0.01,
        --["control-setting:temperature:frequency:multiplier"] = 100,

        --["tile:water:probability"] = -1000,
        --["tile:deep-water:probability"] = -1000,

        -- a constant intensity means base distribution will be consistent with regard to distance
        ['enemy-base-intensity'] = 1,
        -- adjust this value to set how many nests spawn per tile
        ['enemy-base-frequency'] = 0.4,
        -- this will make and average base radius around 12 tiles
        ['enemy-base-radius'] = 12
    }
    mgs.seed = get_seed(game.surfaces[1].map_gen_settings.seed)
    surface.map_gen_settings = mgs
    surface.peaceful_mode = false
    surface.always_day = false
    surface.freeze_daytime = false
    surface.clear(true)
    surface.regenerate_entity({'rock-huge', 'rock-big', 'sand-rock-big'})
    surface.regenerate_decorative()
    -- this will force generate the entire map
    --Server.to_discord_embed('ScrapTownyFFA Map Regeneration in Progress')
    --surface.request_to_generate_chunks({x=0,y=0},64)
    --surface.force_generate_chunk_requests()
    --Server.to_discord_embed('Regeneration Complete')
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

return Public
