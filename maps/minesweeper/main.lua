--luacheck: ignore
--[[
It's a Minesweeper thingy - MewMew

Cell Values:
	-- 1 to 8 = adjacent mines
	-- 9 = empty cell with grid
	-- 10 = mine
	-- 11 = marked mine

]] --

require 'modules.satellite_score'

local Functions = require 'maps.minesweeper.functions'
local Map_score = require 'comfy_panel.map_score'
local Map = require 'modules.map_info'
local Global = require 'utils.global'

local minesweeper = {}
Global.register(
    minesweeper,
    function(tbl)
        minesweeper = tbl
    end
)

local number_colors = {
    [1] = {0, 0, 210},
    [2] = {0, 100, 0},
    [3] = {180, 0, 0},
    [4] = {0, 0, 120},
    [5] = {120, 0, 0},
    [6] = {0, 110, 110},
    [7] = {0, 0, 0},
    [8] = {125, 125, 125},
    [11] = {185, 0, 255}
}

local rendering_tile_values = {
    ['nuclear-ground'] = {offset = {0.6, -0.2}, zoom = 3, font = 'scenario-message-dialog'},
    --['stone-path'] = {offset = {0.54, -0.27}, zoom = 3, font = 'default-large'},
    ['stone-path'] = {offset = {0.52, -0.28}, zoom = 3, font = 'default-large-bold'},
    ['concrete'] = {offset = {0.52, -0.28}, zoom = 3, font = 'default-large-bold'},
    ['hazard-concrete-left'] = {offset = {0.52, -0.28}, zoom = 3, font = 'default-large-bold'},
    ['hazard-concrete-right'] = {offset = {0.52, -0.28}, zoom = 3, font = 'default-large-bold'},
    ['refined-concrete'] = {offset = {0.54, -0.26}, zoom = 3, font = 'default-game'},
    ['refined-hazard-concrete-left'] = {offset = {0.54, -0.26}, zoom = 3, font = 'default-game'},
    ['refined-hazard-concrete-right'] = {offset = {0.54, -0.26}, zoom = 3, font = 'default-game'}
}

local chunk_divide_vectors = {}
for x = 0, 30, 2 do
    for y = 0, 30, 2 do
        table.insert(chunk_divide_vectors, {x, y})
    end
end
local size_of_chunk_divide_vectors = #chunk_divide_vectors

local chunk_vectors = {}
for x = -32, 32, 32 do
    for y = -32, 32, 32 do
        table.insert(chunk_vectors, {x, y})
    end
end

local cell_update_vectors = {}
for x = -2, 2, 2 do
    for y = -2, 2, 2 do
        table.insert(cell_update_vectors, {x, y})
    end
end

local cell_adjacent_vectors = {}
for x = -2, 2, 2 do
    for y = -2, 2, 2 do
        if x == 0 and y == 0 then
        else
            table.insert(cell_adjacent_vectors, {x, y})
        end
    end
end

local solving_vector_tables = {}
local i = 1
for r = 3, 10, 1 do
    solving_vector_tables[i] = {}
    for x = r * -2, r * 2, 2 do
        for y = r * -2, r * 2, 2 do
            table.insert(solving_vector_tables[i], {x, y})
        end
    end
    i = i + 1
end
local size_of_solving_vector_tables = #solving_vector_tables

local function update_rendering(cell, position)
    local surface = game.surfaces[1]
    local tile = surface.get_tile(position)
    local tile_values = rendering_tile_values[tile.name]
    if not tile_values then
        tile_values = {offset = {0.6, -0.2}, zoom = 3, font = 'scenario-message-dialog'}
    end

    if cell[2] then
        rendering.destroy(cell[2])
    end
    if cell[3] then
        rendering.destroy(cell[3])
    end

    local cell_value = cell[1]

    local color
    if number_colors[cell_value] then
        color = number_colors[cell_value]
    else
        color = {125, 125, 125}
    end

    local p = {position.x + tile_values.offset[1], position.y + tile_values.offset[2]}
    local text = cell_value
    if cell_value == 10 or cell_value == 9 then
        text = ' '
    end
    if cell_value == 11 then
        text = 'X'
    end

    cell[2] =
        rendering.draw_text {
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

    if not tile.hidden_tile then
        return
    end
    if tile.hidden_tile ~= 'nuclear-ground' then
        return
    end

    cell[3] =
        rendering.draw_rectangle {
        width = 2,
        filled = false,
        surface = surface,
        left_top = position,
        right_bottom = {position.x + 2, position.y + 2},
        color = {0, 0, 0},
        draw_on_ground = true,
        only_in_alt_mode = false
    }
end

local function get_adjacent_mine_count(position)
    local count = 0
    for _, vector in pairs(cell_adjacent_vectors) do
        local p = {x = position.x + vector[1], y = position.y + vector[2]}
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
        rendering.destroy(cell[2])
    end
    if cell[3] then
        rendering.destroy(cell[3])
    end
    minesweeper.cells[key] = nil
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
            -- somehow there is a race possible here.
            -- cf this -1 screenie https://discord.com/channels/433039858794233858/832822538634526740/838160964175265813
            -- this CAN happen if there are 2 checks same tick, but that would mean the event + que? idk but -1 is only here.
            Functions.kaboom(position)
            score_change = -8
            cell[1] = -1
            for _, vector in pairs(cell_update_vectors) do
                local p = {x = position.x + vector[1], y = position.y + vector[2]}
                local key = Functions.position_to_string(p)
                if minesweeper.cells[key] and minesweeper.cells[key][1] < 10 then
					-- is duplicate insertion possible here? For the one that is in the que already
                    table.insert(minesweeper.visit_queue, {x = p.x, y = p.y})
                end
            end
            return score_change
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
    local cell = minesweeper.cells[key]

    cell[1] = get_adjacent_mine_count(position)

    if cell[1] == 0 then
        for _, vector in pairs(cell_adjacent_vectors) do
            local adjacent_position = {x = position.x + vector[1], y = position.y + vector[2]}
            if Functions.is_minefield_tile(adjacent_position, true) then
                local adjacent_key = Functions.position_to_string(adjacent_position)
                if not minesweeper.cells[adjacent_key] then
                    minesweeper.cells[adjacent_key] = {}
                end
                local adjacent_cell = minesweeper.cells[adjacent_key]
                local mine_count = get_adjacent_mine_count(adjacent_position)
                adjacent_cell[1] = mine_count
                update_rendering(adjacent_cell, adjacent_position)
                if mine_count == 0 then
                    -- is duplicate insertion possible here? For the one that is in the que already
                    table.insert(minesweeper.visit_queue, {x = adjacent_position.x, y = adjacent_position.y})
                end
            end
        end
        Functions.uncover_terrain(position)
        kill_cell(position)
        return score_change
    end

    if cell_value_before_visit and cell_value_before_visit ~= cell[1] then
        for _, vector in pairs(cell_adjacent_vectors) do
            local adjacent_position = {x = position.x + vector[1], y = position.y + vector[2]}
            local adjacent_key = Functions.position_to_string(adjacent_position)
            local adjacent_cell = minesweeper.cells[adjacent_key]
            if adjacent_cell and adjacent_cell[1] < 9 then
                -- is duplicate insertion possible here? For the one that is in the que already
                table.insert(minesweeper.visit_queue, {x = adjacent_position.x, y = adjacent_position.y})
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
        local p = {x = position.x + vector[1], y = position.y + vector[2]}
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
        local p = {x = position.x + vector[1], y = position.y + vector[2]}
        local key = Functions.position_to_string(p)
        local cell = minesweeper.cells[key]
        if cell and cell[1] > 10 then
            local marked_positions = are_mines_marked_around_target(p)
            if marked_positions then
                solved = true
                for _, p in pairs(marked_positions) do
                    minesweeper.cells[Functions.position_to_string(p)][1] = -1
                    visit_cell(p)
                    Functions.disarm_reward(p)
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

    --Success
    if cell and cell[1] > 9 then
        local surface = game.surfaces.nauvis

        if cell[1] == 10 then
            score_change = 1
        end

        surface.create_entity(
            {
                name = 'flying-text',
                position = entity.position,
                text = 'Mine marked.',
                color = {r = 0.98, g = 0.66, b = 0.22}
            }
        )

        cell[1] = 11
        update_rendering(cell, position)
        entity.destroy()

        local solved = solve_attempt(position)
        if solved then
            player.insert({name = 'stone-furnace', count = 1})
            return score_change
        end

        local e = surface.create_entity({name = 'item-on-ground', position = {position.x + 1, position.y + 1}, stack = {name = 'stone-furnace', count = 1}})
        if e and e.valid then
            e.to_be_looted = true
        end

        return score_change
    end

    --Trigger all adjacent mines when missplacing a disarming furnace.
    for _, vector in pairs(cell_update_vectors) do
        local p = {x = position.x + vector[1], y = position.y + vector[2]}
        local key = Functions.position_to_string(p)
        if minesweeper.cells[key] and minesweeper.cells[key][1] == 10 then
            Functions.kaboom(p)
            score_change = score_change - 8
            -- this is a second point that might lead to races and score -1. The first one is at the usual kaboom.
            minesweeper.cells[key][1] = -1
            solve_attempt(p)
            -- is duplicate insertion possible here? For the one that is in the que already
            table.insert(minesweeper.visit_queue, {x = p.x, y = p.y})
        end
    end
    return score_change
end

local function add_mines_to_chunk(left_top, distance_to_center)
    local base_mine_count = 40
    local max_mine_count = 128
    local mine_count = distance_to_center * 0.043 + base_mine_count
    if mine_count > max_mine_count then
        mine_count = max_mine_count
    end

    local shuffle_index = {}
    for i = 1, size_of_chunk_divide_vectors, 1 do
        table.insert(shuffle_index, i)
    end
    table.shuffle_table(shuffle_index)

    -- place shuffled mines
    if distance_to_center < 128 then
        for i = 1, mine_count, 1 do
            local vector = chunk_divide_vectors[shuffle_index[i]]
            local position = {x = left_top.x + vector[1], y = left_top.y + vector[2]}
            if not Functions.is_spawn(position) then
                local key = Functions.position_to_string(position)
                minesweeper.cells[key] = {10}
                minesweeper.active_mines = minesweeper.active_mines + 1
            end
        end
    else
        for i = 1, mine_count, 1 do
            local vector = chunk_divide_vectors[shuffle_index[i]]
            local position = {x = left_top.x + vector[1], y = left_top.y + vector[2]}
            local key = Functions.position_to_string(position)
            minesweeper.cells[key] = {10}
            minesweeper.active_mines = minesweeper.active_mines + 1
        end
    end

    -- remove mines that would form a 3x3 block
    for _, chunk_vector in pairs(chunk_vectors) do
        local left_top_2 = {x = left_top.x + chunk_vector[1], y = left_top.y + chunk_vector[2]}

        for _, vector in pairs(chunk_divide_vectors) do
            local position = {x = left_top_2.x + vector[1], y = left_top_2.y + vector[2]}
            local key = Functions.position_to_string(position)
            local cell = minesweeper.cells[key]
            if cell and cell[1] == 10 then
                if get_adjacent_mine_count(position) == 8 then
                    --if cell[2] then rendering.destroy(cell[2]) end
                    minesweeper.cells[key] = nil
                end
            end
        end
        --[[
		for _, vector in pairs(chunk_divide_vectors) do
			local position = {x = left_top_2.x + vector[1], y = left_top_2.y + vector[2]}
			local key = Functions.position_to_string(position)
			local cell = minesweeper.cells[key]
			if cell then update_rendering(cell, position) end
		end
		]]
    end
end

local function on_chunk_generated(event)
    local left_top = event.area.left_top
    local surface = event.surface
    if surface.index ~= 1 then
        return
    end

    local distance_to_center = math.sqrt((left_top.x + 16) ^ 2 + (left_top.y + 16) ^ 2)
    local tiles = {}

    if distance_to_center < 128 then
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local position = {x = left_top.x + x, y = left_top.y + y}
                if Functions.is_spawn(position) then
                    table.insert(tiles, {name = Functions.get_terrain_tile(surface, position), position = position})
                else
                    table.insert(tiles, {name = 'nuclear-ground', position = position})
                end
            end
        end
    else
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local position = {x = left_top.x + x, y = left_top.y + y}
                table.insert(tiles, {name = 'nuclear-ground', position = position})
                --table.insert(tiles, {name = Functions.get_terrain_tile(surface, position), position = position})
            end
        end
    end
    surface.set_tiles(tiles, true)

    --surface.clear() will cause to trigger on_chunk_generated twice
    local key = Functions.position_to_string(left_top)
    if minesweeper.chunks[key] then
        return
    end
    minesweeper.chunks[key] = true

    add_mines_to_chunk(left_top, distance_to_center)
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    if not Functions.is_minefield_tile(player.position) then
        return
    end
    local cell_position = Functions.position_to_cell_position(player.position)
    local score_change = visit_cell(cell_position)
    if score_change < 0 then
        solve_attempt(cell_position)
    end
    Map_score.set_score(player, Map_score.get_score(player) + score_change)
end

local function deny_building(event)
    local entity = event.created_entity
    if not entity.valid then
        return
    end

    if not game.item_prototypes[entity.name] then
        return
    end
    if not Functions.is_minefield_tile(entity.position, true) then
        return
    end

    if event.player_index then
        local player = game.players[event.player_index]
        if entity.position.x % 2 == 1 and entity.position.y % 2 == 1 and entity.name == 'stone-furnace' then
            local score_change = mark_mine(entity, player)
            Map_score.set_score(player, Map_score.get_score(player) + score_change)
            return
        end
        player.insert({name = entity.name, count = 1})
    else
        local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
        inventory.insert({name = entity.name, count = 1})
    end
    entity.destroy()
end

local function on_built_entity(event)
    deny_building(event)
end

local function on_robot_built_entity(event)
    deny_building(event)
end

local function update_built_tiles(surface, tiles)
    for _, placed_tile in pairs(tiles) do
        local cell_position = Functions.position_to_cell_position(placed_tile.position)
        local key = Functions.position_to_string(cell_position)
        local cell = minesweeper.cells[key]
        if not cell and Functions.is_minefield_tile(placed_tile.position) then
            minesweeper.cells[key] = {9}
        end
        local cell = minesweeper.cells[key]
        if cell then
            update_rendering(cell, cell_position)
        end
    end
end

local function on_player_built_tile(event)
    update_built_tiles(game.surfaces[event.surface_index], event.tiles)
end

local function on_robot_built_tile(event)
    update_built_tiles(event.robot.surface, event.tiles)
end

local function on_player_mined_tile(event)
    update_built_tiles(game.surfaces[event.surface_index], event.tiles)
end

local function on_robot_mined_tile(event)
    update_built_tiles(event.robot.surface, event.tiles)
end

local function on_player_created(event)
    local player = game.players[event.player_index]
    player.insert({name = 'stone-furnace', count = 1})
end

local function on_player_respawned(event)
    local player = game.players[event.player_index]
    player.insert({name = 'stone-furnace', count = 1})

    game.surfaces.nauvis.destroy_decoratives({name = 'nuclear-ground-patch'})
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.force.index ~= 2 then
        return
    end
    local force = event.force
    if not force then
        return
    end
    if force.name ~= 'minesweeper' then
        return
    end
    local revived_entity = entity.clone({position = entity.position})
    revived_entity.health = entity.prototype.max_health
    entity.destroy()
end

local function on_nth_tick()
    -- that part is a shortcut that tryes to fix at least something
    -- each 2 ticks x 10 per call is *just* 300 ops a sec
    -- however it lags for me on a full que (K). if it is more than 30 sec of small lags I want to drop the table :>
    if #minesweeper.visit_queue > 9000
        -- this should only kill "numbers" render afaics
        -- all the other states *should* go fine
        minesweeper.visit_queue = {}
        -- @XXX: add a better log/message that is more eco friendly.
        game.print("[dbg] (You should NOT see this. Unless a big event went nuts again) The que is over 9000! Tell devs we've dropped some of it. Pls walk on numbers on the ground in case they were dropped and have not been updated yet.")
    end
    
    local threshold = 10 -- 6-10 max on a full que pls; 25 is the frezing max prob.
    for k, position in pairs(minesweeper.visit_queue) do
        visit_cell(position)
        table.remove(minesweeper.visit_queue, k)
        threshold = threshold - 1
        if threshold == 0 then
            break
        end
    end
end

local function on_init()
    game.create_force('minesweeper')

    global.custom_highscore.description = 'Minesweep rank:'

    local surface = game.surfaces[1]
    local mgs = surface.map_gen_settings
    mgs.water = 0
    mgs.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}
    mgs.autoplace_controls = {
        ['coal'] = {frequency = 0, size = 0, richness = 0},
        ['stone'] = {frequency = 0, size = 0, richness = 0},
        ['copper-ore'] = {frequency = 0, size = 0, richness = 0},
        ['iron-ore'] = {frequency = 0, size = 0, richness = 0},
        ['uranium-ore'] = {frequency = 0, size = 0, richness = 0},
        ['crude-oil'] = {frequency = 0, size = 0, richness = 0},
        ['trees'] = {frequency = 4, size = 0.5, richness = 0.1}
    }
    surface.map_gen_settings = mgs
    surface.clear(true)

    minesweeper.chunks = {}
    minesweeper.cells = {}
    minesweeper.visit_queue = {}
    minesweeper.player_data = {}
    minesweeper.active_mines = 0
    minesweeper.disarmed_mines = 0
    minesweeper.triggered_mines = 0

    local T = Map.Pop_info()
    T.main_caption = 'Minesweeper'
    T.sub_caption = ''
    T.text =
        table.concat(
        {
            'Mechanical lifeforms once dominated this world.\n',
            'They have left long ago, leaving an inhabitable wasteland.\n',
            'It also seems riddled with buried explosives.\n\n',
            'Mark mines with your stone furnace.\n',
            'Marked mines are save to walk on.\n',
            'When enough mines in an area are marked,\n',
            'they will disarm and yield rewards!\n',
            'Faulty marking may trigger surrounding mines!!\n\n',
            'As you move away from spawn,\n',
            'mine density and radius required to disarm will increase.\n',
            'Crates will contain more loot and ore will have higher yield.\n\n',
            'The paint for the numerics does not work very well with the dirt.\n',
            'Laying some stone bricks or better may help.\n'
        }
    )
    T.main_caption_color = {r = 255, g = 125, b = 55}
    T.sub_caption_color = {r = 0, g = 250, b = 150}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(2, on_nth_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_robot_mined_tile, on_robot_mined_tile)
Event.add(defines.events.on_player_mined_tile, on_player_mined_tile)
