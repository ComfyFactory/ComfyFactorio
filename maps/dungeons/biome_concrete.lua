local Functions = require 'maps.dungeons.functions'
local BiterRaffle = require 'utils.functions.biter_raffle'
local DungeonsTable = require 'maps.dungeons.table'

local table_shuffle_table = table.shuffle_table

local math_random = math.random

local function add_enemy_units(surface, room)
    local dungeontable = DungeonsTable.get_dungeontable()
    for _, tile in pairs(room.room_tiles) do
        if math_random(1, 2) == 1 then
            local name = BiterRaffle.roll('biter', Functions.get_dungeon_evolution_factor(surface.index) * 1.5)
            surface.create_entity({name = name, position = tile.position, force = dungeontable.enemy_forces[surface.index]})
        end
    end
end

local function concrete(surface, room)
    local dungeontable = DungeonsTable.get_dungeontable()
    for _, tile in pairs(room.path_tiles) do
        surface.set_tiles({{name = 'concrete', position = tile.position}}, true)
    end

    if not room.room_border_tiles[1] then
        return
    end

    table_shuffle_table(room.room_tiles)
    for key, tile in pairs(room.room_tiles) do
        surface.set_tiles({{name = 'stone-path', position = tile.position}}, true)
        if math_random(1, 16) == 1 then
            surface.create_entity({name = 'iron-ore', position = tile.position, amount = Functions.get_common_resource_amount(surface.index)})
        end
        if math_random(1, 128) == 1 then
            Functions.crash_site_chest(surface, tile.position)
        end
        if key % 128 == 1 and math_random(1, 3) == 1 then
            Functions.set_spawner_tier(surface.create_entity({name = 'biter-spawner', position = tile.position, force = dungeontable.enemy_forces[surface.index]}), surface.index)
        end
    end

    table_shuffle_table(room.room_border_tiles)
    for key, tile in pairs(room.room_border_tiles) do
        surface.set_tiles({{name = 'refined-concrete', position = tile.position}}, true)
    end

    for key, tile in pairs(room.room_border_tiles) do
        if key % 8 == 1 then
            Functions.place_border_rock(surface, tile.position)
        else
            surface.create_entity({name = 'stone-wall', position = tile.position, force = 'dungeon'})
        end
    end

    if room.entrance_tile then
        local p = room.entrance_tile.position
        local area = {{p.x - 1, p.y - 1}, {p.x + 1.5, p.y + 1.5}}
        for _, entity in pairs(surface.find_entities_filtered({area = area})) do
            entity.destroy()
        end
    end

    add_enemy_units(surface, room)
end

return concrete
