--luacheck: ignore
local Public = {}

local GetNoise = require 'utils.get_noise'
local Constants = require 'maps.cave_miner_v2.constants'
local BiterRaffle = require 'utils.functions.biter_raffle'
local LootRaffle = require 'utils.functions.loot_raffle'
local Esq = require 'modules.entity_spawn_queue'
local Pets = require 'modules.biter_pets'

local math_sqrt = math.sqrt
local math_random = math.random
local math_floor = math.floor

local spawn_amount_rolls = {}
for a = 48, 1, -1 do
    table.insert(spawn_amount_rolls, math_floor(a ^ 5))
end

function Public.get_difficulty_modifier(position)
    local difficulty = math_sqrt(position.x ^ 2 + position.y ^ 2) * 0.0001
    return difficulty
end

function Public.get_colored_name(player_index)
    local player = game.players[player_index]
    local colored_name = table.concat({'[color=', player.chat_color.r, ',', player.chat_color.g, ',', player.chat_color.b, ']', player.name, '[/color]'})
    return colored_name
end

function Public.unstuck_player(player_index)
    local player = game.players[player_index]
    local surface = player.surface
    local position = surface.find_non_colliding_position('character', player.position, 32, 0.5)
    if not position then
        return
    end
    player.teleport(position, surface)
end

function Public.roll_biter_amount()
    local max_chance = 0
    for k, v in pairs(spawn_amount_rolls) do
        max_chance = max_chance + v
    end
    local r = math_random(0, max_chance)
    local current_chance = 0
    for k, v in pairs(spawn_amount_rolls) do
        current_chance = current_chance + v
        if r <= current_chance then
            return k
        end
    end
end

--lab-dark-1 > position has been copied
--lab-dark-2 > position has been visited
function Public.reveal(cave_miner, surface, source_surface, position, brushsize)
    local tile = source_surface.get_tile(position)
    if tile.name == 'lab-dark-2' then
        return
    end
    local tiles = {}
    local copied_tiles = {}
    local i = 0
    local brushsize_square = brushsize ^ 2
    for _, tile in pairs(source_surface.find_tiles_filtered({area = {{position.x - brushsize, position.y - brushsize}, {position.x + brushsize, position.y + brushsize}}})) do
        local tile_position = tile.position
        if tile.name ~= 'lab-dark-2' and tile.name ~= 'lab-dark-1' and (position.x - tile_position.x) ^ 2 + (position.y - tile_position.y) ^ 2 < brushsize_square then
            i = i + 1
            copied_tiles[i] = {name = 'lab-dark-1', position = tile.position}
            tiles[i] = {name = tile.name, position = tile.position}
        end
    end
    surface.set_tiles(tiles, true, false, false, false)
    source_surface.set_tiles(copied_tiles, false, false, false, false)

    for _, entity in pairs(source_surface.find_entities_filtered({area = {{position.x - brushsize, position.y - brushsize}, {position.x + brushsize, position.y + brushsize}}})) do
        local entity_position = entity.position
        if (position.x - entity_position.x) ^ 2 + (position.y - entity_position.y) ^ 2 < brushsize_square then
            local e = entity.clone({position = entity_position, surface = surface})
            if entity.force.index == 2 then
                e.active = true
                table.insert(cave_miner.reveal_queue, {entity.type, entity.position.x, entity.position.y})
            end
            entity.destroy()
        end
    end

    source_surface.set_tiles({{name = 'lab-dark-2', position = position}}, false)
    source_surface.request_to_generate_chunks(position, 3)
end

function Public.get_base_ground_tile(position, seed)
    local noise = GetNoise('large_caves', position, seed)
    local name
    if noise < 0.1 then
        name = 'dirt-7'
    else
        name = 'nuclear-ground'
    end
    return name
end

function Public.spawn_player(player)
    if not player.character then
        player.create_character()
    end

    local surface = player.surface
    local position
    position = surface.find_non_colliding_position('character', player.force.get_spawn_position(surface), 48, 1)
    if not position then
        position = player.force.get_spawn_position(surface)
    end
    player.teleport(position, surface)

    for name, count in pairs(Constants.starting_items) do
        player.insert({name = name, count = count})
    end
end

function Public.set_mining_speed(cave_miner, force)
    force.manual_mining_speed_modifier = -0.60 + cave_miner.pickaxe_tier * 0.40
    return force.manual_mining_speed_modifier
end

function Public.place_worm(surface, position, multiplier)
    local e = surface.create_entity({name = BiterRaffle.roll('worm', Public.get_difficulty_modifier(position) * multiplier), position = position, force = 'enemy'})
    return e
end

function Public.spawn_random_biter(surface, position, multiplier)
    local name = BiterRaffle.roll('mixed', Public.get_difficulty_modifier(position) * multiplier)
    local non_colliding_position = surface.find_non_colliding_position(name, position, 16, 1)
    local unit
    if non_colliding_position then
        unit = surface.create_entity({name = name, position = non_colliding_position, force = 'enemy'})
    else
        unit = surface.create_entity({name = name, position = position, force = 'enemy'})
    end
    unit.ai_settings.allow_try_return_to_spawner = false
    unit.ai_settings.allow_destroy_when_commands_fail = false
    return unit
end

function Public.rock_spawns_biters(cave_miner, position)
    local amount = Public.roll_biter_amount()
    local surface = game.surfaces.nauvis
    local difficulty_modifier = Public.get_difficulty_modifier(position)
    local tick = game.tick
    for c = 1, amount, 1 do
        Esq.add_to_queue(tick + c * 25, surface, {name = BiterRaffle.roll('mixed', difficulty_modifier), position = position, force = 'enemy'}, 8)
    end
end

function Public.loot_crate(surface, position, container_name, player_index)
    local amount_multiplier = Constants.treasures[container_name].amount_multiplier
    local base_amount = 16 * amount_multiplier
    local difficulty_modifier = Public.get_difficulty_modifier(position)
    local slots = game.entity_prototypes[container_name].get_inventory_size(defines.inventory.chest)
    local tech_bonus = Constants.treasures[container_name].tech_bonus
    local description = Constants.treasures[container_name].description

    local blacklist = LootRaffle.get_tech_blacklist(difficulty_modifier + tech_bonus)

    local item_stacks = LootRaffle.roll(base_amount + difficulty_modifier * amount_multiplier * 5000, slots, blacklist)
    local container = surface.create_entity({name = container_name, position = position, force = 'neutral'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false

    if not description then
        return
    end
    if not player_index then
        return
    end
    local player = game.players[player_index]
    local text
    if math_random(1, 2) == 1 then
        text = player.name .. ' found ' .. description
    else
        text = player.name .. ' uncovered ' .. description
    end

    for _, player in pairs(game.forces.player.connected_players) do
        player.add_custom_alert(container, {type = 'item', name = 'wooden-chest'}, text, true)
    end
end

function Public.place_crude_oil(surface, position, multiplier)
    if not surface.can_place_entity({name = 'crude-oil', position = position, amount = 1}) then
        return
    end
    local d = math_sqrt(position.x ^ 2 + position.y ^ 2)
    local amount = math_random(50000, 100000) + d * 100 * multiplier
    surface.create_entity({name = 'crude-oil', position = position, amount = amount})
end

function Public.create_top_gui(player)
    local frame = player.gui.top.cave_miner
    if frame then
        return
    end
    frame = player.gui.top.add({type = 'frame', name = 'cave_miner', direction = 'horizontal'})
    frame.style.maximal_height = 38

    local label = frame.add({type = 'label', caption = 'Loading...'})
    label.style.font = 'heading-2'
    label.style.font_color = {225, 225, 225}
    label.style.margin = 0
    label.style.padding = 0

    local label = frame.add({type = 'label', caption = 'Loading...'})
    label.style.font = 'heading-2'
    label.style.font_color = {225, 225, 225}
    label.style.margin = 0
    label.style.padding = 0
end

function Public.update_top_gui(cave_miner)
    local pickaxe_tiers = Constants.pickaxe_tiers
    for _, player in pairs(game.connected_players) do
        local element = player.gui.top.cave_miner
        if element and element.valid then
            element.children[1].caption = pickaxe_tiers[cave_miner.pickaxe_tier] .. ' Pickaxe  | '
            element.children[1].tooltip = 'Mining speed ' .. (1 + game.forces.player.manual_mining_speed_modifier) * 100 .. '%'
            element.children[2].caption = 'Rocks broken: ' .. cave_miner.rocks_broken
        end
    end
end

local function is_entity_in_darkness(entity)
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    local position = entity.position

    local d = position.x ^ 2 + position.y ^ 2
    if d < 512 then
        return false
    end

    for _, lamp in pairs(entity.surface.find_entities_filtered({area = {{position.x - 16, position.y - 16}, {position.x + 16, position.y + 16}}, name = 'small-lamp'})) do
        local circuit = lamp.get_or_create_control_behavior()
        if circuit then
            if lamp.energy > 25 and circuit.disabled == false then
                return
            end
        else
            if lamp.energy > 25 then
                return
            end
        end
    end

    return true
end

local function darkness_event(cave_miner, entity)
    local index = tostring(entity.unit_number)
    local darkness = cave_miner.darkness

    if darkness[index] then
        darkness[index] = darkness[index] + 1
    else
        darkness[index] = -3
    end

    if darkness[index] <= 0 then
        return
    end

    local position = entity.position
    local difficulty_modifier = Public.get_difficulty_modifier(position)

    local count = math_floor(darkness[index] * 0.33) + 1
    if count > 16 then
        count = 16
    end
    for c = 1, count, 1 do
        Esq.add_to_queue(game.tick + math_random(5, 45) * c, entity.surface, {name = BiterRaffle.roll('mixed', difficulty_modifier), position = position, force = 'enemy'}, 8)
    end

    entity.damage(darkness[index] * 2, 'neutral', 'poison')
end

function Public.darkness(cave_miner)
    for _, player in pairs(game.connected_players) do
        local character = player.character
        if character and character.valid and not character.driving then
            character.disable_flashlight()
            if is_entity_in_darkness(character) then
                darkness_event(cave_miner, character)
            else
                cave_miner.darkness[tostring(character.unit_number)] = nil
            end
        end
    end
end

Public.mining_events = {
    {
        function(cave_miner, entity, player_index)
            if math.random(1, 8) == 1 then
                entity.surface.spill_item_stack(entity.position, {name = 'raw-fish', count = 1}, true)
            end
        end,
        350000,
        'Nothing'
    },
    {
        function(cave_miner, entity, player_index)
            local amount = Public.roll_biter_amount()
            local position = entity.position
            local surface = entity.surface
            local difficulty_modifier = Public.get_difficulty_modifier(position)
            local tick = game.tick
            for c = 1, amount, 1 do
                Esq.add_to_queue(tick + c * 25, surface, {name = BiterRaffle.roll('mixed', difficulty_modifier), position = position, force = 'enemy'}, 8)
            end
        end,
        16384,
        'Mixed_Biters'
    },
    {
        function(cave_miner, entity, player_index)
            local amount = Public.roll_biter_amount()
            local position = entity.position
            local surface = entity.surface
            local difficulty_modifier = Public.get_difficulty_modifier(position)
            local tick = game.tick
            for c = 1, amount, 1 do
                Esq.add_to_queue(tick + c * 25, surface, {name = BiterRaffle.roll('biter', difficulty_modifier), position = position, force = 'enemy'}, 8)
            end
        end,
        2048,
        'Biters'
    },
    {
        function(cave_miner, entity, player_index)
            local amount = Public.roll_biter_amount()
            local position = entity.position
            local surface = entity.surface
            local difficulty_modifier = Public.get_difficulty_modifier(position)
            local tick = game.tick
            for c = 1, amount, 1 do
                Esq.add_to_queue(tick + c * 25, surface, {name = BiterRaffle.roll('spitter', difficulty_modifier), position = position, force = 'enemy'}, 8)
            end
        end,
        2048,
        'Spitters'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            Public.loot_crate(surface, position, 'wooden-chest', player_index)
        end,
        1024,
        'Treasure_Tier_1'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            Public.loot_crate(surface, position, 'iron-chest', player_index)
        end,
        512,
        'Treasure_Tier_2'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            Public.loot_crate(surface, position, 'steel-chest', player_index)
        end,
        256,
        'Treasure_Tier_3'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            Public.loot_crate(surface, position, 'crash-site-spaceship-wreck-medium-' .. math_random(1, 3), player_index)
        end,
        128,
        'Treasure_Tier_4'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            Public.loot_crate(surface, position, 'crash-site-spaceship-wreck-big-' .. math_random(1, 2), player_index)
        end,
        64,
        'Treasure_Tier_5'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            Public.loot_crate(surface, position, 'big-ship-wreck-' .. math_random(1, 3), player_index)
        end,
        32,
        'Treasure_Tier_6'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            Public.loot_crate(surface, position, 'crash-site-chest-' .. math_random(1, 2), player_index)
        end,
        16,
        'Treasure_Tier_7'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            Public.loot_crate(surface, position, 'crash-site-spaceship', player_index)
            Public.unstuck_player(player_index)
        end,
        8,
        'Treasure_Tier_8'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            local unit = Public.spawn_random_biter(surface, position, 2)
            Pets.biter_pets_tame_unit(game.players[player_index], unit, true)
        end,
        256,
        'Pet'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            surface.create_entity({name = 'biter-spawner', position = position, force = 'enemy'})
            Public.unstuck_player(player_index)
        end,
        1024,
        'Nest'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            Public.place_worm(surface, position, 1)
            Public.unstuck_player(player_index)
        end,
        1024,
        'Worm'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            if position.x ^ 2 + position.y ^ 2 < 8000 then
                return
            end
            local surface = entity.surface
            Public.place_worm(surface, position, 1)
            Public.unstuck_player(player_index)
            local difficulty_modifier = Public.get_difficulty_modifier(position)
            local tick = game.tick
            for c = 1, math_random(1, 7), 1 do
                Esq.add_to_queue(
                    tick + c * 90 + math_random(0, 90),
                    surface,
                    {
                        name = BiterRaffle.roll('worm', difficulty_modifier),
                        position = {position.x + (-4 + math_random(0, 8)), position.y + (-4 + math_random(0, 8))},
                        force = 'enemy'
                    },
                    16
                )
            end
        end,
        128,
        'Worms'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            surface.create_entity({name = 'compilatron', position = position, force = 'player'})
        end,
        64,
        'Friendly Compilatron'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            surface.create_entity({name = 'compilatron', position = position, force = 'enemy'})
        end,
        128,
        'Enemy Compilatron'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            local entity = surface.create_entity({name = cave_miner.buildings_raffle[math_random(1, #cave_miner.buildings_raffle)], position = position, force = 'player'})
            entity.health = math_random(1, entity.prototype.max_health)
            local player = game.players[player_index]
            game.print(Public.get_colored_name(player_index) .. ' discovered an abandoned building', Constants.chat_color)
        end,
        128,
        'Abandoned Building'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            surface.create_entity({name = 'car', position = position, force = 'player'})
            Public.unstuck_player(player_index)
            local player = game.players[player_index]
            game.print(player.name .. ' has finally found their car!!', Constants.chat_color)
        end,
        32,
        'Car'
    },
    {
        function(cave_miner, entity, player_index)
            local position = entity.position
            local surface = entity.surface
            local tick = game.tick

            local trees = {}
            for k, prototype in pairs(game.entity_prototypes) do
                if prototype.type == 'tree' then
                    table.insert(trees, k)
                end
            end
            table.shuffle_table(trees)
            local tree = game.entity_prototypes[trees[1]].name

            for c = 1, math_random(4, 96), 1 do
                Esq.add_to_queue(tick + c * 5, surface, {name = tree, position = position, force = 'neutral'}, 64)
            end
            local player = game.players[player_index]
            game.print(player.name .. ' found a whole forest!', Constants.chat_color)
        end,
        64,
        'Forest'
    }
}

Public.on_entity_died = {
    ['unit'] = function(cave_miner, entity)
        local position = entity.position
        local surface = entity.surface
        if math.random(1, 8) == 1 then
            surface.spill_item_stack(position, {name = 'raw-fish', count = 1}, true)
        end
    end,
    ['unit-spawner'] = function(cave_miner, entity)
        local position = entity.position
        local surface = entity.surface
        local a = 64 * 0.0001
        local b = math.sqrt(position.x ^ 2 + position.y ^ 2)
        local c = math_floor(a * b) + 1
        for _ = 1, c, 1 do
            Public.spawn_random_biter(surface, position, 1)
        end
    end,
    ['simple-entity'] = function(cave_miner, entity)
        local position = entity.position
        cave_miner.rocks_broken = cave_miner.rocks_broken + 1
        if math.random(1, 6) == 1 then
            Public.rock_spawns_biters(cave_miner, position)
        end
    end,
    ['container'] = function(cave_miner, entity)
        local position = entity.position
        Public.reveal(cave_miner, game.surfaces.nauvis, game.surfaces.cave_miner_source, position, 20)
    end
}

return Public
