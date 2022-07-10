local Event = require 'utils.event'
local Global = require 'utils.global'

local this = {
    renders = {}
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local target_entities = {
    'character',
    'tank',
    'car',
    'radar',
    'lab',
    'furnace',
    'locomotive',
    'cargo-wagon',
    'fluid-wagon',
    'artillery-wagon',
    'artillery-turret',
    'laser-turret',
    'gun-turret',
    'flamethrower-turret',
    'silo',
    'spidertron'
}

local Public = {}

local sqrt = math.sqrt
local random = math.random
local remove = table.remove
local speed = 0.06

--- Draws a new render.
---@param target table
---@param sprite string
---@param surface userdata
---@return integer
function Public.new_render(target, sprite, surface)
    return rendering.draw_sprite {target = target, sprite = sprite, surface = surface}
end

--- Sets a new target for a given render.
---@param surface userdata
---@return table
---@return table
function Public.new_target(surface)
    local position
    local entities = surface.find_entities_filtered {type = target_entities}
    if entities and #entities > 0 then
        position = entities[random(#entities)].position
    end

    local chunk = surface.get_random_chunk()
    local random_position = {x = (chunk.x + random()) * 32, y = (chunk.y + random()) * 32}

    return position, random_position
end

--- Increments the given position
---@param p1 table
---@param p2 table
---@return table
function Public.increment(p1, p2)
    return {x = p1.x + p2.x, y = p1.y + p2.y}
end

--- Multiples a given position
---@param a table|integer
---@return number|table
function Public.multiply(a)
    return sqrt(a.x * a.x + a.y * a.y)
end

--- Subtracts the given positions
---@param p1 table
---@param p2 table
---@return table|integer
function Public.subtr(p1, p2)
    if not p1 and p2 then
        return 0
    end
    return {x = p2.x - p1.x, y = p2.y - p1.y}
end

--- Sets the render scale.
---@param target_id any
function Public.set_render_scalar_size(target_id)
    if not target_id then
        return
    end

    rendering.set_y_scale(target_id, 3.5) -- 1.5
    rendering.set_x_scale(target_id, 7) -- 2
    rendering.set_color(
        target_id,
        {
            r = 1,
            g = 0.7,
            b = 0.7
        }
    )
end
--- local render = Public.new_render(target, sprite, surface)
--- render.target_position = random_position()
--- Gets a random position.
---@param position any
---@return table
function Public.random_position(position)
    return Public.increment(position, {x = (random() - 0.5) * 64, y = (random() - 0.5) * 64})
end

--- Changes the position of a render.
---@param position table
---@param target_position table
---@param max_abs number
---@param value boolean
---@return table|nil
function Public.change_position(position, target_position, max_abs, value)
    if not position or not target_position then
        return
    end
    local scalar = 0.9
    local subtr = Public.subtr(position, target_position)
    if value then
        subtr.y = subtr.y / scalar
    end
    local multiply = Public.multiply(subtr)
    if (multiply > max_abs) then
        local close = max_abs / multiply
        subtr = {x = subtr.x * close, y = subtr.y * close}
    end
    if value then
        subtr.y = subtr.y * scalar
    end
    return {x = position.x + subtr.x, y = position.y + subtr.y}
end

--- If a render is stuck, give it a new position.
---@param render table
function Public.switch_position(render)
    if random() < 0.4 then
        render.target_position = Public.random_position(render.target_position)
    else
        local surface = game.get_surface(render.surface_id)
        local chunk = surface.get_random_chunk()
        render.target_position = {x = (chunk.x + math.random()) * 32, y = (chunk.y + math.random()) * 32}
    end
end

--- Sets a new position for a render.
---@param render table
function Public.set_new_position(render)
    render.position = Public.change_position(render.position, render.target_position, speed, false)

    if not render.random_pos_set then
        render.random_pos_set = true
        render.random_pos_tick = game.tick + 300
    end
    if render.position.x == render.target_position.x and render.position.y == render.target_position.y then
        Public.switch_position(render)
    end

    if Public.validate(render) then
        rendering.set_target(render.render_id, render.position)
        Public.set_render_scalar_size(render.render_id)
    end
end

--- Creates fire flame.
---@param render table
function Public.render_fire_damage(render)
    if random(1, 15) == 1 then
        local surface = game.get_surface(render.surface_id)
        surface.create_entity({name = 'fire-flame', position = {x = render.position.x, y = render.position.y + 5}})
        if random(1, 5) == 1 then
            surface.create_entity({name = 'medium-scorchmark', position = {x = render.position.x, y = render.position.y + 5}, force = 'neutral'})
        end
    end
end

--- Damages entities nearby.
---@param render table
function Public.damage_entities_nearby(render)
    if random(1, 5) == 1 then
        local surface = game.get_surface(render.surface_id)
        local radius = 10
        local damage = random(10, 15)
        local entities = surface.find_entities_filtered({area = {{render.position.x - radius - 4, render.position.y - radius - 6}, {render.position.x + radius + 4, render.position.y + radius + 6}}})
        for _, entity in pairs(entities) do
            if entity.valid then
                if entity.health then
                    if entity.force.name ~= 'enemy' then
                        if entity.name == 'character' then
                            entity.damage(damage, 'enemy')
                        else
                            entity.health = entity.health - damage
                            if entity.health <= 0 then
                                entity.die('enemy')
                            end
                        end
                    end
                end
            end
        end
    end
end

--- Validates if a render is valid.
---@param render table
---@return boolean
function Public.validate(render)
    if rendering.is_valid(render.render_id) then
        return true
    end
    return false
end

--- Destroys a render.
---@param render table
function Public.destroy_render(render)
    if rendering.is_valid(render.render_id) then
        rendering.destroy(render.render_id)
    end
end

--- Removes a render.
---@param render table
---@param id integer
function Public.remove_render(render, id)
    Public.destroy_render(render)

    remove(this.renders, id)
end

--- Creates a new render.
---@param sprite string
---@param surface userdata
---@param ttl integer
---@param scalar table
---@return table
function Public.new(sprite, surface, ttl, scalar)
    local render = {}
    local position, random_position = Public.new_target(surface)
    render.position = position
    render.surface_id = surface.index
    render.sprite = sprite
    render.target_position = random_position
    render.render_id = Public.new_render(render.position, sprite, surface)
    render.ttl = ttl or game.tick + 7200 -- 2 minutes duration
    if not scalar then
        Public.set_render_scalar_size(render.render_id)
    end

    this.renders[#this.renders + 1] = render

    return render
end

Event.add(
    defines.events.on_tick,
    function()
        if #this.renders == 0 then
            return
        end

        local tick = game.tick

        for id, render in pairs(this.renders) do
            if render then
                if tick < render.ttl then
                    Public.set_new_position(render)
                    Public.render_fire_damage(render)
                    Public.damage_entities_nearby(render)
                    if render.random_pos_set and tick > render.random_pos_tick then
                        Public.switch_position(render)
                        render.random_pos_set = nil
                        render.random_pos_tick = nil
                    end
                else
                    Public.remove_render(render, id)
                end
            end
        end
    end
)

return Public
