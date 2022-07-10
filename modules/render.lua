local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'

local this = {
    renders = {}
}

local Public = {}

Public.metatable = {__index = Public}

Global.register(
    this,
    function(tbl)
        this = tbl
        for _, render in pairs(this.renders) do
            setmetatable(render, Public.metatable)
        end
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

local sqrt = math.sqrt
local random = math.random
local remove = table.remove
local speed = 0.06

--- Draws a new render.
---@return integer
function Public:new_render()
    local surface = game.get_surface(self.surface_id)
    return rendering.draw_sprite {target = self.position, sprite = self.sprite, surface = surface}
end

--- Sets a new target for a given render.
---@return table
---@return table
function Public:new_target()
    local surface = game.get_surface(self.surface_id)
    local position
    local entities = surface.find_entities_filtered {type = target_entities}
    if entities and #entities > 0 then
        position = entities[random(#entities)].position
    end

    local chunk = surface.get_random_chunk()
    local random_position = {x = (chunk.x + random()) * 32, y = (chunk.y + random()) * 32}

    return position, random_position
end

--- Subtracts the given positions
---@return table|integer
function Public:subtr()
    if not self.position and self.target_position then
        return 0
    end
    return {x = self.target_position.x - self.position.x, y = self.target_position.y - self.position.y}
end

--- Sets the render scale.
function Public:set_render_scalar_size()
    if not self.target_id then
        return
    end

    rendering.set_y_scale(self.target_id, 3.5) -- 1.5
    rendering.set_x_scale(self.target_id, 7) -- 2
    rendering.set_color(
        self.target_id,
        {
            r = 1,
            g = 0.7,
            b = 0.7
        }
    )
end
--- Gets a random position.
---@return table
function Public:random_position()
    return {x = self.position.x + (random() - 0.5) * 64, y = self.position.y + (random() - 0.5) * 64}
end

--- Changes the position of a render.
---@param max_abs number
---@param value boolean
---@return table|nil
function Public:change_position(max_abs, value)
    if not self.position or not self.target_position then
        return
    end
    local scalar = 0.9
    local subtr = self:subtr()
    if value then
        subtr.y = subtr.y / scalar
    end
    local multiply = sqrt(subtr.x * subtr.x + subtr.y * subtr.y)
    if (multiply > max_abs) then
        local close = max_abs / multiply
        subtr = {x = subtr.x * close, y = subtr.y * close}
    end
    if value then
        subtr.y = subtr.y * scalar
    end
    return {x = self.position.x + subtr.x, y = self.position.y + subtr.y}
end

--- If a render is stuck, give it a new position.
function Public:switch_position()
    if random() < 0.4 then
        self.target_position = self:random_position()
    else
        local surface = game.get_surface(self.surface_id)
        local chunk = surface.get_random_chunk()
        self.target_position = {x = (chunk.x + math.random()) * 32, y = (chunk.y + math.random()) * 32}
    end
end

--- Sets a new position for a render.
function Public:set_new_position()
    self.position = self:change_position(speed, false)

    if not self.random_pos_set then
        self.random_pos_set = true
        self.random_pos_tick = game.tick + 300
    end
    if self.position.x == self.target_position.x and self.position.y == self.target_position.y then
        self:switch_position()
    end

    if self:validate() then
        rendering.set_target(self.render_id, self.position)
        self:set_render_scalar_size()
    end
end

--- Creates fire flame.
function Public:render_fire_damage()
    if random(1, 15) == 1 then
        local surface = game.get_surface(self.surface_id)
        surface.create_entity({name = 'fire-flame', position = {x = self.position.x, y = self.position.y + 5}})
        if random(1, 5) == 1 then
            surface.create_entity({name = 'medium-scorchmark', position = {x = self.position.x, y = self.position.y + 5}, force = 'neutral'})
        end
    end
end

--- Damages entities nearby.
function Public:damage_entities_nearby()
    if random(1, 5) == 1 then
        local surface = game.get_surface(self.surface_id)
        local radius = 10
        local damage = random(10, 15)
        local entities = surface.find_entities_filtered({area = {{self.position.x - radius - 4, self.position.y - radius - 6}, {self.position.x + radius + 4, self.position.y + radius + 6}}})
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
---@return boolean
function Public:validate()
    if rendering.is_valid(self.render_id) then
        return true
    end
    return false
end

--- Destroys a render.
function Public:destroy_render()
    if rendering.is_valid(self.render_id) then
        rendering.destroy(self.render_id)
    end
    return self
end

--- Removes a render.
---@param id integer
function Public:remove_render(id)
    self:destroy_render()

    remove(this.renders, id)
    return self
end

--- Creates a new render.
---@param sprite string
---@param surface userdata
---@param ttl integer|nil
---@param scalar table|nil
---@return table
function Public.new(sprite, surface, ttl, scalar)
    local render = setmetatable({}, Public.metatable)
    render.surface_id = surface.index
    local position, random_position = render:new_target()
    render.position = position
    render.sprite = sprite
    render.target_position = random_position
    render.render_id = render:new_render()
    render.ttl = ttl or game.tick + 7200 -- 2 minutes duration
    if not scalar then
        render:set_render_scalar_size()
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
                    render:set_new_position()
                    render:render_fire_damage()
                    render:damage_entities_nearby()
                    if render.random_pos_set and tick > render.random_pos_tick then
                        render:switch_position()
                        render.random_pos_set = nil
                        render.random_pos_tick = nil
                    end
                else
                    render:remove_render(id)
                end
            end
        end
    end
)

commands.add_command(
    'laser',
    'new laser',
    function()
        local player = game.player
        if player and player.valid then
            if not player.admin then
                return
            end

            Public.new(Gui.beam, player.surface)
        end
    end
)

return Public
