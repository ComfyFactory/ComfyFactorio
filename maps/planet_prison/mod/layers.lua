local this, public = {}, {}
local _global = require("utils.global")
local _common = require(".common")
local _simplex = require(".simplex_noise")

_global.register(this, function(t) this = t end)
this._grid = {}
this._exclusions = {}
this._layers = {}
this._collision_mask = {}

public.init = function()
   _simplex.init()
end

local function _push_bounding_box(_, x, y)
   table.insert(this._grid, { x, y })
end

--[[
push_bounding_box - Pushes bounding box into a grid for later processing.
@param bb - BoundingBox.
--]]
public.push_bounding_box = function(bb)
   _common.for_bounding_box(nil, bb, _push_bounding_box)
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
   for _, object in pairs(layer.cache) do
      if object.name == "character" or object.name == "gun-turret" then
         if not surf.can_place_entity(object) then
            goto continue
         end
      end

      local ent = surf.create_entity(object)
      if not ent or not ent.valid then
         goto continue
      end

      if hook then
         hook(ent)
      end

      ::continue::
   end
end

--[[
do_job - Do a single step propagation of a layers.
@param surf - LuaSurface, onto which action is taken.
@param limit - How many requests to process.
--]]
public.do_job = function(surf, limit)
   for i = 1, #this._grid do
      local point = table.remove(this._grid)
      for _, box in pairs(this._exclusions) do
         if _common.point_in_bounding_box(point, box) then
            goto next_point
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
               position = point,
            }
            table.insert(layer.cache, object)

            break
            ::continue::
         end
      end

      ::next_point::
      if i >= limit then
         break
      end
   end

   for _, layer in pairs(this._layers) do
      local cache = layer.cache
      if #cache >= 1 then
         if layer.type == "LuaTile" then
            _do_job_tile(surf, layer)
         elseif layer.type == "LuaEntity" then
            _do_job_entity(surf, layer)
         end

         layer.cache = {}
      end
   end
end

return public
