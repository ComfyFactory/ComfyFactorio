--[[
It's a Minesweeper thingy - MewMew

Cell Values:
	-- 1 to 8 = adjacent mines
	-- 9 = empty cell with grid
	-- 10 = mine
	-- 11 = marked mine

]] --


local FlyingText = require 'utils.functions.flying_texts'

require 'modules.satellite_score'

local Functions = require 'maps.minesweeper.functions'
local Map_score = require 'utils.gui.map_score'
local Map = require 'modules.map_info'
local Global = require 'utils.global'

local minesweeper = {}

Global.register(
    minesweeper,
    function (tbl)
        minesweeper = tbl
    end
)

local number_colors =
{
    [1] = { 0, 0, 210 },
    [2] = { 0, 100, 0 },
    [3] = { 180, 0, 0 },
    [4] = { 0, 0, 120 },
    [5] = { 120, 0, 0 },
    [6] = { 0, 110, 110 },
    [7] = { 0, 0, 0 },
    [8] = { 125, 125, 125 },
    [11] = { 185, 0, 255 }
}

local rendering_tile_values =
{
    ['nuclear-ground'] = { offset = { 0.6, -0.2 }, zoom = 3, font = 'scenario-message-dialog' },
    --['stone-path'] = {offset = {0.54, -0.27}, zoom = 3, font = 'default-large'},
    ['stone-path'] = { offset = { 0.52, -0.28 }, zoom = 3, font = 'default-large-bold' },
    ['concrete'] = { offset = { 0.52, -0.28 }, zoom = 3, font = 'default-large-bold' },
    ['hazard-concrete-left'] = { offset = { 0.52, -0.28 }, zoom = 3, font = 'default-large-bold' },
    ['hazard-concrete-right'] = { offset = { 0.52, -0.28 }, zoom = 3, font = 'default-large-bold' },
    ['refined-concrete'] = { offset = { 0.54, -0.26 }, zoom = 3, font = 'default-game' },
    ['refined-hazard-concrete-left'] = { offset = { 0.54, -0.26 }, zoom = 3, font = 'default-game' },
    ['refined-hazard-concrete-right'] = { offset = { 0.54, -0.26 }, zoom = 3, font = 'default-game' }
}

local chunk_divide_vectors = {}
for x = 0, 30, 2 do
    for y = 0, 30, 2 do
        table.insert(chunk_divide_vectors, { x, y })
    end
end
local size_of_chunk_divide_vectors = #chunk_divide_vectors

local cell_update_vectors = {}
for x = -2, 2, 2 do
    for y = -2, 2, 2 do
        table.insert(cell_update_vectors, { x, y })
    end
end

local cell_adjacent_vectors = {}
for x = -2, 2, 2 do
    for y = -2, 2, 2 do
        if x ~= 0 or y ~= 0 then
            table.insert(cell_adjacent_vectors, { x, y })
        end
    end
end

local solving_vector_tables = {}
local i = 1
for r = 3, 10, 1 do
    solving_vector_tables[i] = {}
    for x = r * -2, r * 2, 2 do
        for y = r * -2, r * 2, 2 do
            table.insert(solving_vector_tables[i], { x, y })
        end
    end
    i = i + 1
end
local size_of_solving_vector_tables = #solving_vector_tables

local function update_rendering(cell, position)
    local surface = game.surfaces[1]
    local tile = surface.get_tile(position.x, position.y)
    local tile_values = rendering_tile_values[tile.name]
    if not tile_values then
        tile_values = { offset = { 0.6, -0.2 }, zoom = 3, font = 'scenario-message-dialog' }
    end

    if cell[2] then
        cell[2].destroy()
    end
    if cell[3] then
        cell[3].destroy()
        cell[3] = nil
    end

    local cell_value = cell[1]

    local color
    if number_colors[cell_value] then
        color = number_colors[cell_value]
    else
        color = { 125, 125, 125 }
    end

    local p = { position.x + tile_values.offset[1], position.y + tile_values.offset[2] }
    local text = cell_value
    if cell_value == 10 or cell_value == 9 then
        text = ' '
    end
    if cell_value == 11 then
        text = 'X'
    end

    cell[2] =
        rendering.draw_text
        {
            text = text,
            surface = surface,
            target = p,
            color = color,
            scale = tile_values.zoom,
            font = tile_values.font,
            draw_on_ground = true,
            scale_with_zoom = false,
            only_in_alt_mode = false
        }

    if not Functions.has_paved_minefield_tile(position) then
        return
    end

    cell[3] =
        rendering.draw_rectangle
        {
            width = 2,
            filled = false,
            surface = surface,
            left_top = position,
            right_bottom = { position.x + 2, position.y + 2 },
            color = { 0, 0, 0 },
            draw_on_ground = true,
            only_in_alt_mode = false
        }
end

local function get_adjacent_mine_count(position)
    local count = 0
    for _, vector in pairs(cell_adjacent_vectors) do
        local p = { x = position.x + vector[1], y = position.y + vector[2] }
        local key = Functions.position_to_string(p)
        local cell = minesweeper.cells[key]
        if cell and cell[1] >= 10 then
            count = count + 1
        end
    end
    return count
end

local function kill_cell(position)
    local key = Functions.position_to_string(position)
    local cell = minesweeper.cells[key]
    if not cell then
        return
    end
    if cell[2] then
        cell[2].destroy()
    end
    if cell[3] then
        cell[3].destroy()
    end
    minesweeper.cells[key] = nil
end

local function trigger_mine(cell, position)
    cell[1] = -1
    minesweeper.active_mines = minesweeper.active_mines - 1
    for _, vector in pairs(cell_update_vectors) do
        local p = { x = position.x + vector[1], y = position.y + vector[2] }
        local adjacent_cell = minesweeper.cells[Functions.position_to_string(p)]
        if adjacent_cell and adjacent_cell[1] < 10 then
            table.insert(minesweeper.visit_queue, p)
        end
    end
end

local function launch_blast(position)
    local blast = Functions.kaboom(position)
    if blast then
        minesweeper.blasts = minesweeper.blasts or {}
        table.insert(minesweeper.blasts, blast)
    end
end

local function visit_cell(position)
    local score_change = 0

    if not Functions.is_minefield_tile(position, true) then
        return score_change
    end

    local key = Functions.position_to_string(position)
    local cell = minesweeper.cells[key]
    local cell_value_before_visit = false

    if cell then
        if cell[1] == 10 then
            trigger_mine(cell, position)
            return -8
        end

        if cell[1] == 11 then
            update_rendering(cell, position)
            return score_change
        end

        cell_value_before_visit = cell[1]
    end

    if not cell then
        minesweeper.cells[key] = {}
    end
    cell = minesweeper.cells[key]

    cell[1] = get_adjacent_mine_count(position)

    if cell[1] == 0 then
        for _, vector in pairs(cell_adjacent_vectors) do
            local adjacent_position = { x = position.x + vector[1], y = position.y + vector[2] }
            if Functions.is_minefield_tile(adjacent_position, true) then
                local adjacent_key = Functions.position_to_string(adjacent_position)
                if not minesweeper.cells[adjacent_key] then
                    minesweeper.cells[adjacent_key] = {}
                end
                local adjacent_cell = minesweeper.cells[adjacent_key]
                local mine_count = get_adjacent_mine_count(adjacent_position)
                if adjacent_cell[1] ~= mine_count then
                    adjacent_cell[1] = mine_count
                    if mine_count == 0 then
                        table.insert(minesweeper.visit_queue, adjacent_position)
                    else
                        update_rendering(adjacent_cell, adjacent_position)
                    end
                end
            end
        end
        Functions.uncover_terrain(position)
        kill_cell(position)
        return score_change
    end

    if cell_value_before_visit and cell_value_before_visit ~= cell[1] then
        for _, vector in pairs(cell_adjacent_vectors) do
            local adjacent_position = { x = position.x + vector[1], y = position.y + vector[2] }
            local adjacent_key = Functions.position_to_string(adjacent_position)
            local adjacent_cell = minesweeper.cells[adjacent_key]
            if adjacent_cell and adjacent_cell[1] < 9 then
                table.insert(minesweeper.visit_queue, { x = adjacent_position.x, y = adjacent_position.y })
            end
        end
    end

    update_rendering(cell, position)

    return score_change
end

local function get_solving_vectors(position)
    local distance_to_center = math.sqrt(position.x ^ 2 + position.y ^ 2)
    local key = math.floor(distance_to_center * 0.005) + 1
    if key > size_of_solving_vector_tables then
        key = size_of_solving_vector_tables
    end
    local solving_vectors = solving_vector_tables[key]
    return solving_vectors
end

local function are_mines_marked_around_target(position)
    local marked_positions = {}
    for _, vector in pairs(get_solving_vectors(position)) do
        local p = { x = position.x + vector[1], y = position.y + vector[2] }
        local key = Functions.position_to_string(p)
        local cell = minesweeper.cells[key]
        if cell then
            if cell[1] == 10 then
                return
            end
            if cell[1] == 11 then
                table.insert(marked_positions, p)
            end
        end
    end
    return marked_positions
end

local function solve_attempt(position)
    local solved = false
    for _, vector in pairs(get_solving_vectors(position)) do
        local p = { x = position.x + vector[1], y = position.y + vector[2] }
        local key = Functions.position_to_string(p)
        local cell = minesweeper.cells[key]
        if cell and cell[1] > 10 then
            local marked_positions = are_mines_marked_around_target(p)
            if marked_positions then
                solved = true
                for _, pp in pairs(marked_positions) do
                    minesweeper.cells[Functions.position_to_string(pp)][1] = -1
                    minesweeper.active_mines = minesweeper.active_mines - 1
                end
                for _, pp in pairs(marked_positions) do
                    visit_cell(pp)
                    Functions.disarm_reward(pp)
                end
            end
        end
    end
    return solved
end

local function mark_mine(entity, player)
    local position = Functions.position_to_cell_position(entity.position)
    local key = Functions.position_to_string(position)
    local cell = minesweeper.cells[key]
    local score_change = 0

    if cell and cell[1] > 9 then
        local surface = entity.surface

        if cell[1] == 10 then
            score_change = 1
        end

        FlyingText.flying_text(nil, surface, entity.position, 'Mine marked.', { r = 0.98, g = 0.66, b = 0.22 })

        cell[1] = 11
        update_rendering(cell, position)
        local stack = { name = 'stone-furnace', count = 1, quality = entity.quality }
        entity.destroy()

        solve_attempt(position)

        -- Put furnace back into inventory if and only if there is space,
        -- If there isn't space put on floor like before.
        if player.insert(stack) == 1 then
            return score_change
        end

        surface.spill_item_stack({ position = { position.x + 1, position.y + 1 }, stack = stack, enable_looted = true })

        return score_change
    end

    local triggered_positions = {}
    for _, vector in pairs(cell_update_vectors) do
        local p = { x = position.x + vector[1], y = position.y + vector[2] }
        local nearby_cell = minesweeper.cells[Functions.position_to_string(p)]
        if nearby_cell and nearby_cell[1] == 10 then
            trigger_mine(nearby_cell, p)
            table.insert(triggered_positions, p)
        end
    end
    if #triggered_positions > 0 then
        entity.destroy()
        for _, p in ipairs(triggered_positions) do
            solve_attempt(p)
        end
        for _, p in ipairs(triggered_positions) do
            launch_blast(p)
        end
        return -8 * #triggered_positions
    end
end

-- check if cell position is at or near spawn by checking if it's neighborhood is a tile of spawn
local function is_cell_near_spawn(position)
    for dx = -1, 2, 1 do
        for dy = -1, 2, 1 do
            if Functions.is_spawn({ x = position.x + dx, y = position.y + dy }) then
                return true
            end
        end
    end
    return false
end

local function add_mines_to_chunk(left_top, distance_to_center, restore_existing)
    local base_mine_count = 40
    local max_mine_count = 128
    local mine_count = distance_to_center * 0.043 + base_mine_count
    if mine_count > max_mine_count then
        mine_count = max_mine_count
    end

    local shuffle_index = {}
    for iv = 1, size_of_chunk_divide_vectors, 1 do
        table.insert(shuffle_index, iv)
    end
    table.shuffle_table(shuffle_index)

    for iv = 1, mine_count do
        local vector = chunk_divide_vectors[shuffle_index[iv]]
        local position = { x = left_top.x + vector[1], y = left_top.y + vector[2] }
        if not Functions.is_spawn(position) and (not restore_existing or Functions.is_minefield_tile(position, true)) then
            local key = Functions.position_to_string(position)
            minesweeper.cells[key] = { 10 }
            minesweeper.active_mines = minesweeper.active_mines + 1
        end
    end

    for x = left_top.x - 2, left_top.x + 32, 2 do
        for y = left_top.y - 2, left_top.y + 32, 2 do
            local position = { x = x, y = y }
            local key = Functions.position_to_string(position)
            local cell = minesweeper.cells[key]
            if cell and cell[1] == 10 then
                if get_adjacent_mine_count(position) == 8 then
                    minesweeper.cells[key] = nil
                    minesweeper.active_mines = minesweeper.active_mines - 1
                end
            end
        end
    end
end

-- balance and QoL change: start area is already revealed as if clicked and cleared a free area
-- the previous implementation was not consistent with minesweeper rules
local function reveal_spawn_area()
    if minesweeper.spawn_revealed then
        return
    end
    local spawn_chunk_keys =
    {
        Functions.position_to_string({ x = -32, y = -32 }),
        Functions.position_to_string({ x = 0, y = -32 }),
        Functions.position_to_string({ x = -32, y = 0 }),
        Functions.position_to_string({ x = 0, y = 0 })
    }
    for _, chunk_key in pairs(spawn_chunk_keys) do
        if not minesweeper.chunks[chunk_key] then
            return
        end
    end
    minesweeper.spawn_revealed = true

    -- remove mines near spawn area, distance can be adjusted by neighborhood range of is_cell_near_spawn check
    for x = -20, 18, 2 do
        for y = -20, 18, 2 do
            local position = { x = x, y = y }
            local cell = minesweeper.cells[Functions.position_to_string(position)]
            if cell and cell[1] == 10 and is_cell_near_spawn(position) then
                kill_cell(position)
                minesweeper.active_mines = minesweeper.active_mines - 1
            end
        end
    end

    -- reveal all cells closest to spawn, triggering 0 zones, would not reveal mines if they were still present
    -- situation is made consistent with minesweeper aestetic, no more hard edge into bomb from "revealed cell"
    for x = -20, 18, 2 do
        for y = -20, 18, 2 do
            local position = { x = x, y = y }
            local cell = minesweeper.cells[Functions.position_to_string(position)]
            local is_mine = cell and cell[1] == 10
            if not is_mine and is_cell_near_spawn(position) and Functions.is_minefield_tile(position, true) then
                visit_cell(position)
            end
        end
    end
end

local function on_chunk_generated(event)
    local left_top = event.area.left_top
    local surface = event.surface
    if surface.index ~= 1 or not minesweeper.chunks then
        return
    end

    local key = Functions.position_to_string(left_top)
    if minesweeper.chunks[key] then
        return
    end

    local distance_to_center = math.sqrt((left_top.x + 16) ^ 2 + (left_top.y + 16) ^ 2)
    local tiles = {}

    if distance_to_center < 128 then
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local position = { x = left_top.x + x, y = left_top.y + y }
                if Functions.is_spawn(position) then
                    table.insert(tiles, { name = Functions.get_terrain_tile(surface, position), position = position })
                else
                    table.insert(tiles, { name = 'nuclear-ground', position = position })
                end
            end
        end
    else
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local position = { x = left_top.x + x, y = left_top.y + y }
                table.insert(tiles, { name = 'nuclear-ground', position = position })
            end
        end
    end
    surface.set_tiles(tiles, true)

    -- removes resources that would've spawned from normal map generation, user in map generation does no longer need to set them to 0
    for _, resource in pairs(surface.find_entities_filtered({ area = event.area, type = 'resource' })) do
        resource.destroy()
    end

    add_mines_to_chunk(left_top, distance_to_center)
    minesweeper.chunks[key] = true
    reveal_spawn_area()
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    -- change for 2.0 | 2.1
    -- player.position also gives position in remote view which would trigger mines before
    -- instead use character.position
    local character = player.character
    if not minesweeper.cells or player.controller_type ~= defines.controllers.character or not (character and character.valid) or character.surface.index ~= 1 then
        return
    end
    local position = character.position
    if not Functions.is_minefield_tile(position) then
        return
    end
    local cell_position = Functions.position_to_cell_position(position)
    local score_change = visit_cell(cell_position)
    if score_change < 0 then
        solve_attempt(cell_position)
        launch_blast(cell_position)
    end
    Map_score.set_score(player, Map_score.get_score(player) + score_change)
end

local function on_built_entity(event)
    local entity = event.entity
    if not minesweeper.cells or not entity.valid or entity.surface.index ~= 1 then
        return
    end

    local items = entity.prototype.items_to_place_this
    if not items or not items[1] then
        return
    end
    local position = entity.position
    -- bugfix: check all tiles of cell instead of center position
    -- before mines could spawn near spawn, if mine was marked by furnace, this check would find spawn surface, not a mine
    -- the furnace would build, the player would mine the furnace and confusedly asume the tile safe
    -- the player would walk on the tile and be exploded
    -- even though spawn mines are removed now, this bugfix should still remain, just in case of future changes
    local is_marker = entity.name == 'stone-furnace' and position.x % 2 == 1 and position.y % 2 == 1
    local minefield_position = is_marker and Functions.position_to_cell_position(position) or position
    if not Functions.is_minefield_tile(minefield_position, true) then
        return
    end

    local surface = entity.surface
    local stack = { name = items[1].name, count = items[1].count, quality = entity.quality }
    local inventory
    if event.player_index then
        local player = game.players[event.player_index]
        if is_marker then
            local score_change = mark_mine(entity, player)
            if score_change then
                Map_score.set_score(player, Map_score.get_score(player) + score_change)
                return
            end
        end
        inventory = player
    else
        inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
    end
    entity.destroy()
    if inventory then
        stack.count = stack.count - inventory.insert(stack)
    end
    if stack.count > 0 then
        surface.spill_item_stack({ position = position, stack = stack, enable_looted = true })
    end
end

local function update_built_tiles(event)
    if not minesweeper.cells or event.surface_index ~= 1 then
        return
    end

    local updated = {}
    for _, placed_tile in pairs(event.tiles) do
        local cell_position = Functions.position_to_cell_position(placed_tile.position)
        local key = Functions.position_to_string(cell_position)
        if not updated[key] then
            updated[key] = true
            local cell = minesweeper.cells[key]
            if not cell and Functions.has_paved_minefield_tile(cell_position) then
                cell = { 9 }
                minesweeper.cells[key] = cell
            end
            if cell then
                update_rendering(cell, cell_position)
            end
        end
    end
end

local function on_player_created(event)
    local player = game.players[event.player_index]
    player.insert({ name = 'stone-furnace', count = 1 })
end

local function on_player_respawned(event)
    local player = game.players[event.player_index]
    player.insert({ name = 'stone-furnace', count = 1 })

    game.surfaces[1].destroy_decoratives({ name = 'nuclear-ground-patch' })
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.surface.index ~= 1 or entity.force.name ~= 'enemy' then
        return
    end
    local force = event.force
    if not force then
        return
    end
    if force.name ~= 'minesweeper' then
        return
    end
    local revived_entity = entity.clone({ position = entity.position })
    if revived_entity then
        revived_entity.health = revived_entity.max_health
        entity.destroy()
    end
end

local function initialize()
    if not game.forces.minesweeper then
        game.create_force('minesweeper')
    end

    minesweeper.chunks = {}
    minesweeper.spawn_revealed = false
    minesweeper.cells = {}
    minesweeper.visit_queue = {}
    minesweeper.player_data = {}
    minesweeper.active_mines = 0
    minesweeper.disarmed_mines = 0
    minesweeper.triggered_mines = 0

    local surface = game.surfaces[1]
    local mgs = surface.map_gen_settings
    mgs.water = 0
    mgs.cliff_settings = { cliff_elevation_interval = 0, cliff_elevation_0 = 0 }
    -- bugfix for Factorio 2.0 | 2.1: frequency & size & richness = 0 makes spotNoise return NaN.
    -- instead opt for ressorce removal in on_chunk_generated
    mgs.autoplace_controls =
    {
        ['trees'] = { frequency = 4, size = 0.5, richness = 0.1 }
    }
    surface.map_gen_settings = mgs
    Map_score.set_score_description('Minesweep rank:')
    local T = Map.get_map_information()
    T.localised_category = 'minesweeper'
    T.main_caption_color = { r = 255, g = 125, b = 55 }
    T.sub_caption_color = { r = 0, g = 250, b = 150 }
end

local function on_init()
    initialize()
    minesweeper.generate_spawn = true
    local surface = game.surfaces[1]
    for _, entity in pairs(surface.find_entities_filtered({ type = 'cliff' })) do
        entity.destroy()
    end
end

local function on_nth_tick()
    if minesweeper.generate_spawn then
        minesweeper.generate_spawn = nil
        local surface = game.surfaces[1]
        surface.request_to_generate_chunks({ 0, 0 }, 1)
        surface.force_generate_chunk_requests()
        for chunk in surface.get_chunks() do
            if surface.is_chunk_generated(chunk) then
                on_chunk_generated({ surface = surface, area = chunk.area })
            end
        end
    end
    if not minesweeper.chunks then
        initialize()
        local surface = game.surfaces[1]
        for chunk in surface.get_chunks() do
            if surface.is_chunk_generated(chunk) then
                local left_top = chunk.area.left_top
                local distance_to_center = math.sqrt((left_top.x + 16) ^ 2 + (left_top.y + 16) ^ 2)
                add_mines_to_chunk(left_top, distance_to_center, true)
                minesweeper.chunks[Functions.position_to_string(left_top)] = true
            end
        end
        reveal_spawn_area()
    end

    local blasts = minesweeper.blasts
    if blasts then
        for index = #blasts, 1, -1 do
            local blast = blasts[index]
            if not blast.projectile.valid then
                Functions.restore_blast_terrain(blast.terrain)
                table.remove(blasts, index)
            end
        end
        if #blasts > 0 then
            return
        end
        minesweeper.blasts = nil
    end

    local position = table.remove(minesweeper.visit_queue, 1)
    if position then
        visit_cell(position)
    end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(2, on_nth_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_robot_built_entity, on_built_entity)
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_robot_built_tile, update_built_tiles)
Event.add(defines.events.on_player_built_tile, update_built_tiles)
Event.add(defines.events.on_robot_mined_tile, update_built_tiles)
Event.add(defines.events.on_player_mined_tile, update_built_tiles)
