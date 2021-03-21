local public = {}
local _common = require('.common')
local _simplex = require('.simplex_noise')
local Token = require 'utils.token'
local Global = require 'utils.global'

local this = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

public.init = function()
    this._grid = {}
    this._exclusions = {}
    this._layers = {}
    this._collision_mask = {}
    _simplex.init()
end
--[[
push_chunk - Pushes chunk position into a grid for later processing.
@param chunk - ChunkPosition
--]]
public.push_chunk = function(chunk)
    table.insert(this._grid, chunk)
end

--[[
add_excluding_bounding_box - Pushes bounding box into exclusion list.
@param bb - BoundindBox.
--]]
public.push_excluding_bounding_box = function(bb)
    table.insert(this._exclusions, bb)
end

--[[
remove_ecluding_bounding_box - Removes bounding box from exclusion list.
@param bb - BoundingBox to get rid of.
--]]
public.remove_excluding_bounding_box = function(bb)
    for i = 1, #this._exclusions do
        local box = this._exclusions[i]
        if box == bb then
            table.remove(this._exclusions, i)
            break
        end
    end
end

--[[
add_noise_layer - Add noise layer that will be applied onto the grid.
@param type - Type of an object that will be placed onto layer.
@param name - Name of the layer
@param objects - Names of the objects that will be placed.
@param resolution - Resolution of a layer [0f - 1f]
@param elevation - Layer visibility [0f - 1f)
--]]
public.add_noise_layer = function(type, name, objects, elevation, resolution)
    local layer = {
        type = type,
        name = name,
        objects = objects,
        elevation = elevation,
        resolution = resolution,
        cache = {},
        hook = nil,
        deps = nil
    }

    table.insert(this._layers, layer)
end

--[[
add_noise_layer_hook - Execute callback on created object.
@param name - Name of the layer.
@param hook - Callback that will be called with an object argument.
--]]
public.add_noise_layer_hook = function(name, hook)
    for _, layer in pairs(this._layers) do
        if layer.name == name then
            layer.hook = hook
            break
        end
    end
end

--[[
add_noise_layer_dependency - Adds dependency to the layer. It can be any
lua variable. This dependency then is injected into hook.
@param deps - Dependencies, any variable.
--]]
public.add_noise_layer_dependency = function(name, deps)
    for _, layer in pairs(this._layers) do
        if layer.name == name then
            layer.deps = deps
            break
        end
    end
end

--[[
set_collision_mask - Set which tiles should be ignored.
@param mask - Table of collision masks.
--]]
public.set_collision_mask = function(mask)
    this._collision_mask = mask
end

local function _do_job_tile(surf, layer)
    surf.set_tiles(layer.cache)
end

local function _do_job_entity(surf, layer)
    local hook = layer.hook
    if not hook then
        return
    end
    local func = Token.get(hook)
    if not func then
        return
    end
    func = Token.get(func)
    local deps = layer.deps
    if not deps then
        return
    end
    local func2 = Token.get(deps)
    if not func2 then
        return
    end
    for _, object in pairs(layer.cache) do
        if object.name == 'character' or object.name == 'gun-turret' then
            if not surf.can_place_entity(object) then
                goto continue
            end
        end

        local ent = surf.create_entity(object)
        if not ent or not ent.valid then
            goto continue
        end

        if hook then
            func(ent, func2)
        end

        ::continue::
    end
end

local function _do_job(surf, x, y)
    local point = {
        x = x,
        y = y
    }

    for _, exclusion in pairs(this._exclusions) do
        if _common.point_in_bounding_box(point, exclusion) then
            return
        end
    end

    for _, layer in pairs(this._layers) do
        local ret = _simplex.get(point, layer.resolution)
        if ret >= layer.elevation then
            local tile = surf.get_tile(point)
            for _, mask in pairs(this._collision_mask) do
                if tile.collides_with(mask) then
                    goto continue
                end
            end

            local object_name = layer.objects[1]
            if #layer.objects > 1 then
                local index = _common.rand_range(1, #layer.objects)
                object_name = layer.objects[index]
            end

            local object = {
                name = object_name,
                position = point
            }
            table.insert(layer.cache, object)

            break
            ::continue::
        end
    end
end

--[[
do_job - Do a single step propagation of a layers.
@param surf - LuaSurface, onto which action is taken.
--]]
public.do_job = function(surf)
    if #this._grid <= 0 then
        return
    end

    local chunk = table.remove(this._grid)
    local x = _common.get_axis(chunk, 'x')
    local y = _common.get_axis(chunk, 'y')

    chunk = {
        left_top = {
            x = x * 32,
            y = y * 32
        },
        right_bottom = {
            x = (x * 32) + 32,
            y = (y * 32) + 32
        }
    }

    _common.for_bounding_box(surf, chunk, _do_job)

    for _, layer in pairs(this._layers) do
        local cache = layer.cache
        if #cache >= 1 then
            if layer.type == 'LuaTile' then
                _do_job_tile(surf, layer)
            elseif layer.type == 'LuaEntity' then
                _do_job_entity(surf, layer)
            end

            layer.cache = {}
        end
    end
end

return public
