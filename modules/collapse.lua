local Event = require 'utils.event'
local Global = require 'utils.global'
local Public = {}

local math_floor = math.floor
local table_shuffle_table = table.shuffle_table

local this = {
    debug = false,
    disabled = false
}
Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local directions = {
    ['north'] = function(position)
        local surface_index = this.surface_index
        if not surface_index then
            return
        end

        local surface = game.get_surface(surface_index)
        if not surface or not surface.valid then
            return
        end
        local width = surface.map_gen_settings.width
        if width > this.max_line_size then
            width = this.max_line_size
        end
        if this.max_line_size_force then
            width = this.max_line_size
        end
        local a = width * 0.5 + 4
        this.vector = {0, -1}
        this.area = {{position.x - a, position.y - 1}, {position.x + a, position.y}}
    end,
    ['south'] = function(position)
        local surface_index = this.surface_index
        if not surface_index then
            return
        end

        local surface = game.get_surface(surface_index)
        if not surface or not surface.valid then
            return
        end
        local width = surface.map_gen_settings.width
        if width > this.max_line_size then
            width = this.max_line_size
        end
        if this.max_line_size_force then
            width = this.max_line_size
        end
        local a = width * 0.5
        this.vector = {0, 1}
        this.area = {{position.x - a, position.y}, {position.x + a, position.y + 1}}
    end,
    ['west'] = function(position)
        local surface_index = this.surface_index
        if not surface_index then
            return
        end

        local surface = game.get_surface(surface_index)
        if not surface or not surface.valid then
            return
        end
        local width = surface.map_gen_settings.height
        if width > this.max_line_size then
            width = this.max_line_size
        end
        if this.max_line_size_force then
            width = this.max_line_size
        end
        local a = width * 0.5 + 1
        this.vector = {-1, 0}
        this.area = {{position.x - 1, position.y - a}, {position.x, position.y + a}}
    end,
    ['east'] = function(position)
        local surface_index = this.surface_index
        if not surface_index then
            return
        end

        local surface = game.get_surface(surface_index)
        if not surface or not surface.valid then
            return
        end
        local width = surface.map_gen_settings.height
        if width > this.max_line_size then
            width = this.max_line_size
        end
        if this.max_line_size_force then
            width = this.max_line_size
        end
        local a = width * 0.5 + 1
        this.vector = {1, 0}
        this.area = {{position.x, position.y - a}, {position.x + 1, position.y + a}}
    end
}

local function print_debug(a)
    if not this.debug then
        return
    end
    print('Collapse error #' .. a)
end

local function set_collapse_tiles(surface)
    if not surface or surface.valid then
        print_debug(45)
    end
    game.forces.player.chart(surface, this.area)
    this.tiles = surface.find_tiles_filtered({area = this.area, name = 'out-of-map', invert = true})

    if not this.tiles then
        return
    end
    this.size_of_tiles = #this.tiles
    if this.size_of_tiles > 0 then
        table_shuffle_table(this.tiles)
    end
    this.position = {x = this.position.x + this.vector[1], y = this.position.y + this.vector[2]}
    local v = this.vector
    local area = this.area
    this.area = {{area[1][1] + v[1], area[1][2] + v[2]}, {area[2][1] + v[1], area[2][2] + v[2]}}
    local chart_area = {{area[1][1] + v[1] - 4, area[1][2] + v[2] - 4}, {area[2][1] + v[1] + 4, area[2][2] + v[2] + 4}}
    game.forces.player.chart(surface, chart_area)
end

local function progress()
    local surface_index = this.surface_index
    if not surface_index then
        return
    end

    local surface = game.get_surface(surface_index)
    if not surface or not surface.valid then
        return
    end

    if not this.start_now then
        this.tiles = nil
        return
    end

    local tiles = this.tiles
    if not tiles then
        set_collapse_tiles(surface)
        tiles = this.tiles
    end
    if not tiles then
        return
    end

    for _ = 1, this.amount, 1 do
        local tile = tiles[this.size_of_tiles]
        if not tile then
            this.tiles = nil
            return
        end
        this.size_of_tiles = this.size_of_tiles - 1
        if not tile.valid then
            return
        end
        if this.specific_entities.enabled then
            local position = {tile.position.x + 0.5, tile.position.y + 0.5}
            local entities = this.specific_entities.entities
            for _, e in pairs(surface.find_entities_filtered({area = {{position[1] - 4, position[2] - 2}, {position[1] + 4, position[2] + 2}}})) do
                if entities[e.name] and e.valid and e.health then
                    e.die()
                elseif e.valid then
                    e.destroy()
                end
            end
        end
        if this.kill then
            local position = {tile.position.x + 0.5, tile.position.y + 0.5}
            for _, e in pairs(surface.find_entities_filtered({area = {{position[1] - 4, position[2] - 2}, {position[1] + 4, position[2] + 2}}})) do
                if e.valid and e.health then
                    e.die()
                end
            end
        end
        surface.set_tiles({{name = 'out-of-map', position = tile.position}}, true)
    end
end

function Public.set_surface_index(surface_index)
    if not surface_index then
        print_debug(1)
        return
    end

    local surface = game.get_surface(surface_index)
    if not surface or not surface.valid then
        print_debug(2)
        return
    end

    this.surface_index = surface_index
end

function Public.set_direction(direction)
    if not directions[direction] then
        print_debug(11)
        return
    end
    directions[direction](this.position)
end

function Public.set_speed(speed)
    if not speed then
        print_debug(8)
        return
    end
    speed = math_floor(speed)
    if speed < 1 then
        speed = 1
    end
    this.speed = speed
end

function Public.set_amount(amount)
    if not amount then
        print_debug(9)
        return
    end
    amount = math_floor(amount)
    if amount < 0 then
        amount = 0
    end
    this.amount = amount
end

function Public.set_position(position)
    if not position then
        print_debug(4)
        return
    end
    if not position.x and not position[1] then
        print_debug(5)
        return
    end
    if not position.y and not position[2] then
        print_debug(6)
        return
    end
    local x = 0
    local y = 0
    if position[1] then
        x = position[1]
    end
    if position[2] then
        y = position[2]
    end
    if position.x then
        x = position.x
    end
    if position.y then
        y = position.y
    end
    this.position = {x = x, y = y}
end

function Public.get_position()
    return this.position
end

function Public.get_amount()
    return this.amount
end

function Public.get_speed()
    return this.speed
end

function Public.get_disable_state()
    return this.disabled
end

function Public.disable_collapse(state)
    this.disabled = state or false
end

function Public.start_now(state)
    this.start_now = state or false

    return this.start_now
end

function Public.get_start_now()
    return this.start_now
end

function Public.set_max_line_size(size, force)
    if not size then
        print_debug(22)
        return
    end
    size = math_floor(size)
    if size <= 0 then
        print_debug(21)
        return
    end
    this.max_line_size = size
    this.max_line_size_force = force or false
end

function Public.set_kill_entities(a)
    this.kill = a
end

function Public.set_kill_specific_entities(tbl)
    if tbl then
        this.specific_entities = tbl
    else
        this.specific_entities = {
            enabled = false
        }
    end
end

local function on_init()
    Public.set_surface_index(game.surfaces.nauvis.index)
    Public.set_position({0, 32})
    Public.set_max_line_size(256)
    Public.set_direction('north')
    Public.set_kill_entities(true)
    Public.set_kill_specific_entities()
    this.tiles = nil
    this.speed = 1
    this.amount = 8
    this.start_now = false
end

local function on_tick()
    if this.disabled then
        return
    end

    local tick = game.tick
    if tick % this.speed ~= 0 then
        return
    end

    progress()
end

if not Public.read_tables_only then
    Event.on_init(on_init)
    Event.add(defines.events.on_tick, on_tick)
end

return Public
