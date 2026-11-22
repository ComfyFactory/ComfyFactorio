--[[
Extracted some constants from the original minesweeper code for easier access.

Cell Values:
	-- 1 to 8 = adjacent mines
	-- 9 = empty cell with grid
	-- 10 = mine
	-- 11 = marked mine

]] --




local Constants = {}



Constants.number_colors =
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


Constants.rendering_tile_values =
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


Constants.chunk_divide_vectors = {}
for x = 0, 30, 2 do
    for y = 0, 30, 2 do
        table.insert(Constants.chunk_divide_vectors, { x, y })
    end
end
Constants.size_of_chunk_divide_vectors = #Constants.chunk_divide_vectors

Constants.cell_update_vectors = {}
for x = -2, 2, 2 do
    for y = -2, 2, 2 do
        table.insert(Constants.cell_update_vectors, { x, y })
    end
end

Constants.cell_adjacent_vectors = {}
for x = -2, 2, 2 do
    for y = -2, 2, 2 do
        if x ~= 0 or y ~= 0 then
            table.insert(Constants.cell_adjacent_vectors, { x, y })
        end
    end
end

Constants.solving_vector_tables = {}
local i = 1
for r = 3, 10, 1 do
    Constants.solving_vector_tables[i] = {}
    for x = r * -2, r * 2, 2 do
        for y = r * -2, r * 2, 2 do
            table.insert(Constants.solving_vector_tables[i], { x, y })
        end
    end
    i = i + 1
end
Constants.size_of_solving_vector_tables = #Constants.solving_vector_tables


return Constants