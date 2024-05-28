local Public = {}
local Event = require 'utils.event'
local Global = require 'utils.global'
local Collapse = require 'modules.collapse'
local this = {
    explosives = {},
    settings = {
        disabled = false,
        check_growth_below_void = false,
        valid_items = {
            ['explosives'] = 500,
            ['cliff-explosives'] = 750
        }
    }
}
Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local math_abs = math.abs
local math_floor = math.floor
local math_sqrt = math.sqrt
local math_round = math.round
local math_random = math.random
local shuffle_table = table.shuffle_table
local speed = 3
local density = 1
local density_r = density * 0.5
local valid_container_types = {
    ['container'] = true,
    ['logistic-container'] = true,
    ['car'] = true,
    ['cargo-wagon'] = true
}

local function pos_to_key(position)
    return tostring(position.x .. '_' .. position.y)
end

local function check_y_pos(position)
    if not this.settings.check_growth_below_void then
        return false
    end
    if not position or not position.y then
        return false
    end
    local collapse_pos = Collapse.get_position()

    local radius = 10

    local dy = position.y - collapse_pos.y
    if dy ^ 2 < radius ^ 2 then
        return true
    end

    if position.y >= collapse_pos.y then
        return true
    else
        return false
    end
end

local function get_explosion_name(health)
    if health < 2500 then
        return 'explosion'
    end
    if health < 25000 then
        return 'big-explosion'
    end
    return 'big-artillery-explosion'
end

local function cell_birth(surface_index, origin_position, origin_tick, position, health, atomic)
    local key = pos_to_key(position)

    --Merge cells that are overlapping.
    if this.explosives.cells[key] then
        this.explosives.cells[key].health = this.explosives.cells[key].health + health
        return
    end

    if not atomic then
        atomic = false
    end

    --Spawn new cell.
    this.explosives.cells[key] = {
        surface_index = surface_index,
        origin_position = origin_position,
        origin_tick = origin_tick,
        position = {x = position.x, y = position.y},
        spawn_tick = game.tick + speed,
        health = health,
        atomic = atomic
    }
end

local function grow_cell(cell)
    shuffle_table(this.explosives.vectors)
    local radius = math_floor((game.tick - cell.origin_tick) / 9) + 2
    local positions = {}
    for i = 1, 4, 1 do
        local position = {
            x = cell.position.x + this.explosives.vectors[i][1],
            y = cell.position.y + this.explosives.vectors[i][2]
        }
        if not this.explosives.cells[pos_to_key(position)] then
            local distance = math_sqrt((cell.origin_position.x - position.x) ^ 2 + (cell.origin_position.y - position.y) ^ 2)
            if distance < radius then
                positions[#positions + 1] = position
            end
        end
    end

    if #positions == 0 then
        positions[#positions + 1] = {
            x = cell.position.x + this.explosives.vectors[1][1],
            y = cell.position.y + this.explosives.vectors[1][2]
        }
    end

    local new_cell_health = math_round(cell.health / #positions, 3) - this.explosives.damage_decay

    if new_cell_health <= 0 then
        return
    end

    if not cell.atomic then
        cell.atomic = false
    end

    for _, p in pairs(positions) do
        cell_birth(cell.surface_index, cell.origin_position, cell.origin_tick, p, new_cell_health, cell.atomic)
    end
end

local function damage_entity(entity, cell)
    if not entity.valid then
        return true
    end
    if not entity.health then
        return true
    end
    if entity.health <= 0 then
        return true
    end
    if not entity.destructible then
        return true
    end

    if this.explosives.whitelist_entity[entity.name] then
        return true
    end

    local damage_required = entity.health
    for _ = 1, 4, 1 do
        if damage_required > cell.health then
            entity.damage(cell.health, 'player', 'explosion')
            return false
        end
        local damage_dealt = entity.damage(damage_required, 'player', 'explosion')
        cell.health = cell.health - damage_required
        if not entity then
            return true
        end
        if not entity.valid then
            return true
        end
        if entity.health <= 0 then
            return true
        end
        damage_required = math_floor(entity.health * (damage_required / damage_dealt)) + 1
    end
end

local function damage_area(cell)
    local surface = game.surfaces[cell.surface_index]
    if not surface then
        return
    end
    if not surface.valid then
        return
    end

    if math_random(1, 4) == 1 then
        if cell.atomic then
            surface.create_entity({name = 'nuke-explosion', position = cell.position})
        else
            surface.create_entity({name = get_explosion_name(cell.health), position = cell.position})
        end
    end

    for _, entity in pairs(
        surface.find_entities(
            {
                {cell.position.x - density_r, cell.position.y - density_r},
                {cell.position.x + density_r, cell.position.y + density_r}
            }
        )
    ) do
        if not damage_entity(entity, cell) then
            return
        end
    end

    local tile = surface.get_tile(cell.position)
    if this.explosives.destructible_tiles[tile.name] then
        local key = pos_to_key(tile.position)
        if not this.explosives.tiles[key] then
            this.explosives.tiles[key] = this.explosives.destructible_tiles[tile.name]
        end

        if cell.health > this.explosives.tiles[key] then
            cell.health = cell.health - this.explosives.tiles[key]
            this.explosives.tiles[key] = nil
            if math_abs(tile.position.y) < surface.map_gen_settings.height * 0.5 and math_abs(tile.position.x) < surface.map_gen_settings.width * 0.5 then
                if not check_y_pos(tile.position) then
                    surface.set_tiles({{name = 'landfill', position = tile.position}}, true)
                end
            end
        else
            this.explosives.tiles[key] = this.explosives.tiles[key] - cell.health
            return
        end
    end

    return true
end

local function life_cycle(cell)
    if not damage_area(cell) then
        return
    end
    grow_cell(cell)
end

local function tick()
    if this.settings.disabled then
        return
    end

    for key, cell in pairs(this.explosives.cells) do
        if cell.spawn_tick < game.tick then
            life_cycle(cell)
            this.explosives.cells[key] = nil
        end
    end
    if game.tick % 216000 == 0 then
        this.explosives.tiles = {}
    end
end

local function check_entity_for_items(item)
    local items = this.settings.valid_items
    for name, damage in pairs(items) do
        local amount = item.get_item_count(name)
        if amount and amount > 1 then
            return amount, damage
        end
    end
    return false
end

local function on_entity_died(event)
    if this.settings.disabled then
        return false
    end

    local entity = event.entity
    if not entity.valid then
        return
    end
    if not valid_container_types[entity.type] then
        return
    end
    if this.explosives.surface_whitelist then
        if not this.explosives.surface_whitelist[entity.surface.name] then
            return
        end
    end

    local inventory = defines.inventory.chest
    if entity.type == 'car' then
        inventory = defines.inventory.car_trunk
    end

    local item = entity.get_inventory(inventory)
    local amount, damage = check_entity_for_items(item)
    if not amount then
        return
    end

    cell_birth(entity.surface.index, {x = entity.position.x, y = entity.position.y}, game.tick, {x = entity.position.x, y = entity.position.y}, amount * damage)
end

function Public.detonate_chest(entity)
    if this.settings.disabled then
        return false
    end

    if not entity or not entity.valid then
        return false
    end
    if not valid_container_types[entity.type] then
        return false
    end
    if this.explosives.surface_whitelist then
        if not this.explosives.surface_whitelist[entity.surface.name] then
            return false
        end
    end

    local inventory = defines.inventory.chest
    if entity.type == 'car' then
        inventory = defines.inventory.car_trunk
    end

    local item = entity.get_inventory(inventory)
    local amount, damage = check_entity_for_items(item)
    if not amount then
        return false
    end
    if amount < 99 then
        return false
    end

    cell_birth(entity.surface.index, {x = entity.position.x, y = entity.position.y}, game.tick, {x = entity.position.x, y = entity.position.y}, amount * damage)
    return true
end

function Public.detonate_entity(entity, amount, damage)
    if this.settings.disabled then
        return false
    end

    if not entity or not entity.valid then
        return false
    end

    if not amount then
        amount = 200
    end

    if not damage then
        damage = 700
    end

    cell_birth(entity.surface.index, {x = entity.position.x, y = entity.position.y}, game.tick, {x = entity.position.x, y = entity.position.y}, amount * damage, true)
    return true
end

function Public.reset()
    this.explosives.cells = {}
    this.explosives.tiles = {}
    if not this.explosives.vectors then
        this.explosives.vectors = {{density, 0}, {density * -1, 0}, {0, density}, {0, density * -1}}
    end
    if not this.explosives.damage_decay then
        this.explosives.damage_decay = 10
    end
    if not this.explosives.destructible_tiles then
        this.explosives.destructible_tiles = {}
    end
    if not this.explosives.whitelist_entity then
        this.explosives.whitelist_entity = {}
    end
end

function Public.set_destructible_tile(tile_name, health)
    this.explosives.destructible_tiles[tile_name] = health
end

function Public.set_whitelist_entity(entity)
    if entity then
        this.explosives.whitelist_entity[entity] = true
    end
end

function Public.set_surface_whitelist(list)
    this.explosives.surface_whitelist = list
end

function Public.disable(state)
    this.settings.disabled = state or false
end

function Public.get_table()
    return this.explosives
end

function Public.check_growth_below_void(value)
    this.settings.check_growth_below_void = value or false
end

local function on_init()
    Public.reset()
end

Event.on_init(on_init)
Event.on_nth_tick(speed, tick)
Event.add(defines.events.on_entity_died, on_entity_died)

return Public
