require 'modules.satellite_score'
require 'modules.thirst'

local Event = require 'utils.event'
local Map_info = require 'modules.map_info'
local FT = require 'utils.functions.flying_texts'
local Gui = require 'utils.gui'
local PG = require 'utils.terrain_layouts.planet_generation'

local get_noise = require 'utils.math.get_noise'
local math = require 'utils.math.math'

local oasis_start = 0.50
local water_start = 0.81
local sand_damage = oasis_start * 100 + 16

local trees = { 'tree-01', 'tree-04', 'tree-06', 'tree-08-red', 'tree-08', 'tree-09' }

local safe_tiles =
{
    ['stone-path'] = true,
    ['concrete'] = true,
    ['hazard-concrete-left'] = true,
    ['hazard-concrete-right'] = true,
    ['refined-concrete'] = true,
    ['refined-hazard-concrete-left'] = true,
    ['refined-hazard-concrete-right'] = true,
    ['water'] = true,
    ['water-shallow'] = true,
    ['water-mud'] = true,
    ['grass-1'] = true,
    ['grass-2'] = true,
    ['grass-3'] = true,
    ['deepwater'] = true
}

local function calculate_vulcanus(surface, position)
    local temperatures = surface.calculate_tile_properties({ 'vulcanus_temperature' }, { position })
    local temperature = temperatures and temperatures['vulcanus_temperature'][1]
    -- 75 mini hot, 100 hot a lot
    -- 50% moisture, 0% moisture
    local moisture = math.round((-2) * temperature + 200, 1)
    return moisture
end

local function calculate_nauvis(_, position)
    local moisture = get_noise('oasis', position, storage.desert_oasis_seed)
    moisture = moisture * 128
    moisture = math.round(moisture, 1)
    return moisture
end

local function calculate_fulgora(surface, position)
    local elevations = surface.calculate_tile_properties({ 'fulgora_elevation' }, { position })
    local elevation = elevations['fulgora_elevation'][1]
    -- 0 ocean, 105 plateaus
    -- 60% moisture, 45% moisture
    local moisture = math.round((-1 / 7) * elevation + 60, 1)
    return moisture
end

local function calculate_gleba(surface, position)
    local elevations = surface.calculate_tile_properties({ 'gleba_elevation' }, { position })
    local elevation = elevations['gleba_elevation'][1]
    -- 0 water, 150 plateaus
    -- 100%+ moisture, 80% moisture
    local moisture = math.round((-2 / 15) * elevation + 100, 1)
    return moisture
end

local function calculate_aquilo(_, _)
    local moisture = 45
    return moisture
end

local function get_moisture(surface, position)
    if surface.platform then
        return 50
    end
    local planet_calcs =
    {
        nauvis = calculate_nauvis,
        gleba = calculate_gleba,
        vulcanus = calculate_vulcanus,
        aquilo = calculate_aquilo,
        fulgora = calculate_fulgora
    }
    local planet = surface.name == 'nauvis' and 'nauvis' or (surface.planet and surface.planet.name)
    local moisture = 50
    if planet_calcs[planet] then
        moisture = planet_calcs[planet](surface, position)
    end
    return moisture
end

local function moisture_meter(player, moisture)
    local parent = Gui.get_mod_gui_top_frame() and Gui.get_button_flow(player) or player.gui.top
    local legacy_meter = player.gui.top.moisture_meter
    if legacy_meter and (parent ~= player.gui.top or legacy_meter.type ~= 'button') then
        legacy_meter.destroy()
    end
    local moisture_meter_gui = parent.moisture_meter
    if not moisture_meter_gui then
        moisture_meter_gui = parent.add({ type = 'button', name = 'moisture_meter', style = 'mod_gui_button', tooltip = 'Local moisture. Low moisture can cause heat damage on unprotected ground.' })
        moisture_meter_gui.style.minimal_height = 36
        moisture_meter_gui.style.maximal_height = 36
        moisture_meter_gui.style.minimal_width = 150
    end
    moisture_meter_gui.caption = string.format('Moisture: %.1f', moisture)
end

local function draw_oasis(surface, left_top, seed)
    local tiles = {}
    local entities = {}
    local decoratives = {}
    local left_top_x = left_top.x
    local left_top_y = left_top.y

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local position = { x = left_top_x + x, y = left_top_y + y }
            local noise = get_noise('oasis', position, seed)
            if noise >= oasis_start then
                if noise > water_start or noise > oasis_start + 0.035 and get_noise('cave_ponds', position, seed) > 0.72 then
                    if noise > 0.87 then
                        tiles[#tiles + 1] = { name = 'deepwater', position = position }
                    elseif noise > 0.85 then
                        tiles[#tiles + 1] = { name = 'water', position = position }
                    elseif noise > 0.83 then
                        tiles[#tiles + 1] = { name = 'water-mud', position = position }
                    else
                        tiles[#tiles + 1] = { name = 'water-shallow', position = position }
                        if math.random(1, 6) == 1 then
                            decoratives[#decoratives + 1] = { name = 'green-bush-mini', position = position, amount = math.random(1, 6) }
                        end
                    end

                    if math.random(1, 64) == 1 then
                        entities[#entities + 1] = { name = 'fish', position = position }
                    end
                else
                    tiles[#tiles + 1] = { name = 'grass-' .. math.floor(noise * 32) % 3 + 1, position = position }

                    for _, cliff in pairs(surface.find_entities_filtered({ type = 'cliff', position = position })) do
                        cliff.destroy()
                    end

                    if math.random(1, 12) == 1 and surface.can_place_entity({ name = 'coal', position = position, amount = 1 }) then
                        if math.abs(get_noise('n3', position, seed)) > 0.50 then
                            entities[#entities + 1] = { name = trees[math.floor(get_noise('n2', position, seed) * 9) % 6 + 1], position = position }
                        end
                    end
                end
            elseif noise < -0.9 then
                decoratives[#decoratives + 1] = { name = 'sand-decal', position = position, amount = 1 }
            else
                if math.random(1, 6) == 1 then
                    decoratives[#decoratives + 1] = { name = 'sand-dune-decal', position = position, amount = 1 }
                end
            end
        end
    end

    surface.set_tiles(tiles, true)

    for _, entity in pairs(entities) do
        if surface.can_place_entity(entity) then
            surface.create_entity(entity)
        end
    end
    surface.create_decoratives({ decoratives = decoratives, check_collision = true })
end

local function create_crash_site(surface, position)
    local p = surface.find_non_colliding_position('stone', position, 50, 0.5)
    if not p then
        return
    end
    local e = surface.create_entity({ name = 'crash-site-spaceship', position = p, force = 'player', create_build_effect_smoke = false })
    if not e or not e.valid then return end
    e.insert({ name = 'repair-pack', count = 2 })
    e.insert({ name = 'water-barrel', count = 5 })
    e.minable_flag = false
end

local function on_chunk_generated(event)
    local surface = event.surface
    if surface.name ~= 'nauvis' then
        PG.generate(surface, event.area)
        return
    end
    local seed = storage.desert_oasis_seed
    local left_top = event.area.left_top

    for _, entity in pairs(surface.find_entities_filtered({ area = event.area, type = 'resource' })) do
        if get_noise('oasis', entity.position, seed) <= oasis_start then
            entity.destroy()
        end
    end

    for _, entity in pairs(surface.find_entities_filtered({ area = event.area, force = 'enemy' })) do
        if get_noise('oasis', entity.position, seed) > -0.25 then
            surface.destroy_decoratives(
                {
                    area = { { entity.position.x - 10, entity.position.y - 10 }, { entity.position.x + 10, entity.position.y + 10 } },
                    name = { 'enemy-decal', 'enemy-decal-transparent', 'worms-decal', 'shroom-decal', 'lichen-decal', 'light-mud-decal' }
                }
            )
            entity.destroy()
        end
    end
    draw_oasis(surface, left_top, seed)
    if left_top.x == 64 and left_top.y == 64 then
        create_crash_site(surface, { 75, 75 })
    end
end

local function on_init()
    local T = Map_info.get_map_information()
    T.localised_category = 'desert_oasis'
    T.main_caption_color = { r = 170, g = 170, b = 0 }
    T.sub_caption_color = { r = 120, g = 120, b = 0 }

    local map_gen_settings =
    {
        water = 0.0,
        property_expression_names =
        {
            temperature = 50,
            moisture = 0,
            elevation = 'elevation_nauvis'
        },
        starting_area = 2,
        terrain_segmentation = 0.1,
        cliff_settings =
        {
            cliff_elevation_interval = 40,
            cliff_elevation_0 = 0,
            cliff_smoothing = 0,
            name = 'cliff',
            richness = 1,
            control = 'nauvis_cliff'
        },
        default_enable_all_autoplace_controls = false,
        autoplace_controls =
        {
            ['coal'] = { frequency = 23, size = 0.5, richness = 1.25 },
            ['stone'] = { frequency = 20, size = 0.5, richness = 0.66 },
            ['copper-ore'] = { frequency = 25, size = 0.5, richness = 1.25 },
            ['iron-ore'] = { frequency = 35, size = 0.5, richness = 1.25 },
            ['uranium-ore'] = { frequency = 20, size = 0.5, richness = 1.25 },
            ['crude-oil'] = { frequency = 50, size = 0.55, richness = 2 },
            ['trees'] = { frequency = 0.75, size = 0.75, richness = 0.1 },
            ['enemy-base'] = { frequency = 15, size = 1, richness = 1 },
            ['nauvis_cliff'] = { frequency = 5, size = 3, richness = 2 },
            ['rocks'] = { frequency = 3, size = 6, richness = 5 }
        },
        autoplace_settings =
        {
            decorative =
            {
                treat_missing_as_default = false,
                settings =
                {

                    ['red-desert-bush'] =
                    {
                        frequency = 4,
                        richness = 4,
                        size = 4
                    },
                    ['white-desert-bush'] =
                    {
                        frequency = 4,
                        richness = 4,
                        size = 4
                    },
                    ['small-rock'] =
                    {
                        frequency = 4,
                        richness = 4,
                        size = 4
                    },
                    ['small-sand-rock'] =
                    {
                        frequency = 6,
                        richness = 4,
                        size = 4
                    },
                    ['medium-sand-rock'] =
                    {
                        frequency = 8,
                        richness = 4,
                        size = 4
                    },
                }
            },
            tile =
            {
                treat_missing_as_default = false,
                settings =
                {
                    ["red-desert-1"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ["red-desert-2"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ["red-desert-3"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ["sand-1"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ["sand-2"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ["sand-3"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                }
            },
            entity =
            {
                settings =
                {
                    coal =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ["copper-ore"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ["crude-oil"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    fish =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ['big-sand-rock'] =
                    {
                        frequency = 5,
                        size = 3,
                        richness = 3
                    },
                    ["huge-rock"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ["iron-ore"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    stone =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                    ["uranium-ore"] =
                    {
                        frequency = 1,
                        richness = 1,
                        size = 1
                    },
                },
                treat_missing_as_default = true
            }
        }
    }

    storage.desert_oasis_seed = 0
    local noise
    local seed
    local position = { x = 0, y = 0 }
    for _ = 1, 1024 ^ 2, 1 do
        seed = math.random(1, 999999999)
        noise = get_noise('oasis', position, seed)
        if noise > 0.76 then
            storage.desert_oasis_seed = seed
            break
        end
    end
    map_gen_settings.seed = storage.desert_oasis_seed
    local surface = game.surfaces.nauvis
    surface.map_gen_settings = map_gen_settings
    surface.clear(true)

    surface.request_to_generate_chunks({ 0, 0 }, 3)
    surface.force_generate_chunk_requests()
    surface.set_property('solar-power', 200)
    local force = game.forces.player
    if not script.active_mods['space-age'] then
        force.technologies['cliff-explosives'].enabled = false
    end
end

local type_whitelist =
{
    ['artillery-wagon'] = true,
    ['car'] = true,
    ['spider-vehicle'] = true,
    ['cargo-wagon'] = true,
    ['construction-robot'] = true,
    ['entity-ghost'] = true,
    ['fluid-wagon'] = true,
    ['heat-pipe'] = true,
    ['locomotive'] = true,
    ['logistic-robot'] = true,
    ['rail-chain-signal'] = true,
    ['rail-signal'] = true,
    ['curved-rail-a'] = true,
    ['curved-rail-b'] = true,
    ['straight-rail'] = true,
    ['half-diagonal-rail'] = true,
    ['elevated-straight-rail'] = true,
    ['elevated-half-diagonal-rail'] = true,
    ['elevated-curved-rail-a'] = true,
    ['elevated-curved-rail-b'] = true,
    ['rail-support'] = true,
    ['rail-ramp'] = true,
    ['train-stop'] = true,
    ['crash-site-spaceship'] = true
}

local function refund_item(surface, position, inventory, item)
    local inserted = inventory and inventory.insert(item) or 0
    if inserted < item.count then
        item.count = item.count - inserted
        surface.spill_item_stack({
            position = position,
            stack = item,
            enable_looted = true,
            max_radius = 10,
            use_start_position_on_failure = true
        })
    end
end

local function deny_building(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    if entity.surface.name ~= 'nauvis' then
        return
    end

    local is_ghost = entity.type == 'entity-ghost'
    local entity_type = is_ghost and entity.ghost_type or entity.type
    if type_whitelist[entity_type] or entity.name == 'crash-site-spaceship' then
        return
    end

    if safe_tiles[entity.surface.get_tile(entity.position).name] then
        return
    end
    local player
    local inventory
    if event.player_index then
        player = game.get_player(event.player_index)
        if player and player.valid then
            inventory = player
        end
    elseif event.robot and event.robot.valid then
        inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
    end

    if not is_ghost then
        if event.consumed_items then
            for i = 1, #event.consumed_items do
                local stack = event.consumed_items[i]
                if stack.valid_for_read then
                    refund_item(entity.surface, entity.position, inventory, stack)
                end
            end
        else
            local item = entity.prototype.items_to_place_this and entity.prototype.items_to_place_this[1]
            if item then
                refund_item(entity.surface, entity.position, inventory, { name = item.name, count = item.count, quality = entity.quality })
            end
        end
    end
    FT.flying_text(player, entity.surface, entity.position, 'Can not be built in the sands!', { r = 0.98, g = 0.66, b = 0.22 })
    entity.destroy()
end

local function on_built_entity(event)
    deny_building(event)
end

local function on_robot_built_entity(event)
    deny_building(event)
end

local function deny_tile_building(event, inventory)
    local surface = game.get_surface(event.surface_index)
    if surface.name ~= 'nauvis' then
        return
    end
    for _, t in pairs(event.tiles) do
        if not safe_tiles[t.old_tile.name] then
            surface.set_tiles({ { name = t.old_tile.name, position = t.position } }, true)
            if event.item then
                refund_item(surface, t.position, inventory, { name = event.item.name, count = 1, quality = event.quality })
            end
        end
    end
end

local function on_player_built_tile(event)
    local player = game.players[event.player_index]
    deny_tile_building(event, event.inventory or player)
end

local function on_robot_built_tile(event)
    deny_tile_building(event, event.inventory or event.robot.get_inventory(defines.inventory.robot_cargo))
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if player.online_time == 0 then
        player.insert({ name = 'raw-fish', count = 3 })
        player.insert({ name = 'grenade', count = 1 })
        player.insert({ name = 'iron-plate', count = 16 })
        player.insert({ name = 'iron-gear-wheel', count = 8 })
        player.insert({ name = 'stone', count = 5 })
        player.insert({ name = 'pistol', count = 1 })
        player.insert({ name = 'firearm-magazine', count = 16 })
        player.teleport(game.surfaces.nauvis.find_non_colliding_position('character', { 64, 64 }, 50, 0.5) or { 64, 64 }, 'nauvis')
    end
end

local function on_player_changed_position(event)
    if math.random(1, 4) ~= 1 then
        return
    end
    local player = game.players[event.player_index]
    local surface = player.physical_surface

    local moisture = get_moisture(surface, player.physical_position)
    moisture_meter(player, moisture)

    if player.controller_type == defines.controllers.remote then
        return
    end

    if not player.character then
        return
    end
    if not player.character.valid then
        return
    end
    if player.vehicle then
        return
    end
    if script.active_mods['space-age'] and player.cargo_pod then
        return
    end

    if safe_tiles[surface.get_tile(player.physical_position.x, player.physical_position.y).name] then
        return
    end
    if moisture <= 40 then
        if math.random(1, math.max(1, math.min(40, math.floor(moisture)))) == 1 then
            surface.create_entity({ name = 'fire-flame', position = player.physical_position })
        end
        local damage = (sand_damage - moisture)
        player.character.damage(damage, 'neutral', 'fire')
    end
end

Event.on_init(on_init)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
