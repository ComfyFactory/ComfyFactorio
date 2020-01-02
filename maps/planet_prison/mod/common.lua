local public, this = {}, {}
local _global = require("utils.global")
_global.register(this, function(t) this = t end)

--[[
rand_range - Return random integer within the range.
@param start - Start range.
@param stop - Stop range.
--]]
public.rand_range = function(start, stop)
   if not this.rng then
      this.rng = game.create_random_generator()
   end

   return this.rng(start, stop)
end

--[[
for_bounding_box - Execute function per every position within bb.
@param surf - LuaSurface, that will be given into func.
@param bb - BoundingBox
@param func - User supplied callback that will be executed.
--]]
public.for_bounding_box = function(surf, bb, func)
   for x = bb.left_top.x, bb.right_bottom.x do
      for y = bb.left_top.y, bb.right_bottom.y do
         func(surf, x, y)
      end
   end
end

--[[
get_axis - Extract axis value from any point format.
@param point - Table with or without explicity axis members.
@param axis - Single character string describing the axis.
--]]
public.get_axis = function(point, axis)
   if point[axis] then
      return point[axis]
   end

   if #point ~= 2 then
      log("get_axis: invalid point format")
      return nil
   end

   if axis == "x" then
      return point[1]
   end

   return point[2]
end

--[[
get_close_random_position - Gets randomized close position to origin,
@param origin - Position that will be taken as relative
                point for calculation.
@param radius - Radius space.
--]]
public.get_close_random_position = function(origin, radius)
   local x = public.get_axis(origin, "x")
   local y = public.get_axis(origin, "y")

   x = public.rand_range(x - radius, x + radius)
   y = public.rand_range(y - radius, y + radius)

   return { x = x, y = y }
end

--[[
get_distance - Returns distance in tiles between 2 points.
@param a - Position, first point.
@param b - Position, second point.
--]]
public.get_distance = function(a, b)
   local h = (public.get_axis(a, "x") - public.get_axis(b, "x")) ^ 2
   local v = (public.get_axis(a, "y") - public.get_axis(b, "y")) ^ 2

   return math.sqrt(h + v)
end

--[[
point_in_bounding_box - Check whatever point is within bb.
@param point - Position
@param bb - BoundingBox
--]]
public.point_in_bounding_box = function(point, bb)
   local x = public.get_axis(point, "x")
   local y = public.get_axis(point, "y")

   if bb.left_top.x <= x and bb.right_bottom.x >= x and
      bb.left_top.y <= y and bb.right_bottom.y >= y then
      return true
   end

   return false
end

public.direction_lookup = {
   [-1] = {
      [1] = defines.direction.southwest,
      [0] = defines.direction.west,
      [-1] = defines.direction.northwest,
   },
   [0] = {
      [1] = defines.direction.south,
      [-1] = defines.direction.north
   },
   [1] = {
      [1] = defines.direction.southeast,
      [0] = defines.direction.east,
      [-1] = defines.direction.northeast,
   },
}

--[[
get_readable_direction - Return readable direction from point a to b.
@param a - Position A
@param b - Position B
--]]
public.get_readable_direction = function(a, b)
   local a_x = public.get_axis(a, "x")
   local a_y = public.get_axis(a, "y")
   local b_x = public.get_axis(b, "x")
   local b_y = public.get_axis(b, "y")
   local h, v

   if a_x < b_x then
      h = 1
   elseif a_x > b_x then
      h = -1
   else
      h = 0
   end

   if a_y < b_y then
      v = 1
   elseif a_y > b_y then
      v = -1
   else
      v = 0
   end

   local mapping = {
      [defines.direction.southwest] = "south-west",
      [defines.direction.west] = "west",
      [defines.direction.northwest] = "north-west",
      [defines.direction.south] = "south",
      [defines.direction.north] = "north",
      [defines.direction.southeast] = "south-east",
      [defines.direction.east] = "east",
      [defines.direction.northeast] = "north-east",
   }
   return mapping[public.direction_lookup[h][v]]
end

--[[
create_bounding_box_by_points - Construct a BoundingBox using points
from any array of objects with "position" or "bounding_box" datafield.
@param objects - Array of objects that have "position" datafield.
--]]
public.create_bounding_box_by_points = function(objects)
   local box = {
      left_top = {
         x = public.get_axis(objects[1].position, "x"),
         y = public.get_axis(objects[1].position, "y")
      },
      right_bottom = {
         x = public.get_axis(objects[1].position, "x"),
         y = public.get_axis(objects[1].position, "y")
      }
   }

   for i = 2, #objects do
      local object = objects[i]
      if object.bounding_box then
         local bb = object.bounding_box
         if box.left_top.x > bb.left_top.x then
            box.left_top.x = bb.left_top.x
         end

         if box.right_bottom.x < bb.right_bottom.x then
            box.right_bottom.x = bb.right_bottom.x
         end

         if box.left_top.y > bb.left_top.y then
            box.left_top.y = bb.left_top.y
         end

         if box.right_bottom.y < bb.right_bottom.y then
            box.right_bottom.y = bb.right_bottom.y
         end
      else
         local point = objects[i].position
         local x = public.get_axis(point, "x")
         local y = public.get_axis(point, "y")

         if box.left_top.x > x then
            box.left_top.x = x
         elseif box.right_bottom.x < x then
            box.right_bottom.x = x
         end

         if box.left_top.y > y then
            box.left_top.y = y
         elseif box.right_bottom.y < y then
            box.right_bottom.y = y
         end
      end
   end

   box.left_top.x = box.left_top.x - 1
   box.left_top.y = box.left_top.y - 1
   box.right_bottom.x = box.right_bottom.x + 1
   box.right_bottom.y = box.right_bottom.y + 1
   return box
end

--[[
merge_bounding_boxes - Merge array of BoundingBox objects into a single
object.
@param bbs - Array of BoundingBox objects.
--]]
public.merge_bounding_boxes = function(bbs)
   if bbs == nil then
      log("common.merge_bounding_boxes: bbs is nil")
      return
   end

   if #bbs <= 0 then
      log("common.merge_bounding_boxes: bbs is empty")
      return
   end

   local box = {
      left_top = {
         x = bbs[1].left_top.x,
         y = bbs[1].left_top.y,
      },
      right_bottom = {
         x = bbs[1].right_bottom.x,
         y = bbs[1].right_bottom.y,
      }
   }
   for i = 2, #bbs do
      local bb = bbs[i]
      if box.left_top.x > bb.left_top.x then
         box.left_top.x = bb.left_top.x
      end

      if box.right_bottom.x < bb.right_bottom.x then
         box.right_bottom.x = bb.right_bottom.x
      end

      if box.left_top.y > bb.left_top.y then
         box.left_top.y = bb.left_top.y
      end

      if box.right_bottom.y < bb.right_bottom.y then
         box.right_bottom.y = bb.right_bottom.y
      end
   end

   return box
end

return public
