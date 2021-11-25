local WPT = require 'maps.amap.table'

local Loot = require "maps.amap.loot"
local BiterRolls = require 'maps.amap.modules.wave_defense.biter_rolls'

local MT = require "maps.amap.basic_markets"


local math_random = math.random

local math_abs = math.abs

local Factories = require 'maps.amap.production'

local diff = require 'maps.amap.diff'
local world_cave=require 'maps.amap.world.world_function'.world_cave
local world_quarter=require 'maps.amap.world.world_function'.quarter
--local world_crossing=require 'maps.amap.world.world_function'.crossing
local world_winter=require 'maps.amap.world.world_function'.winter
local world_water=require 'maps.amap.world.world_function'.water
local world_water_dungle=require 'maps.amap.world.world_function'.water_dungle

local weight_shop = 1
local weight_build = 3
local weight_box= 6
local weight_worm= 0

require "maps.amap.rocks_yield_ore"
require "modules.rocks_broken_paint_tiles"
require "modules.rocks_heal_over_time"
require "modules.rocks_yield_ore_veins"
require "modules.no_deconstruction_of_neutral_entities"


local function move_away_things(surface, area)
  for _, e in pairs(surface.find_entities_filtered({type = {"unit-spawner",  "unit", "tree"}, area = area})) do
    local position = surface.find_non_colliding_position(e.name, e.position, 128, 4)
    if position then
      surface.create_entity({name = e.name, position = position, force = "enemy"})
      e.destroy()
    end
  end
end



local function build_base(surface,maxs,event,position)
  if position.x>-4 and position.x<4 then
    if position.y>1 and position.y<5 then
      surface.set_tiles({{name = "water", position = position}})
    end
  end
  if maxs <= 65   then
    if maxs == 56  then
      move_away_things(surface, event.area)
      if surface.can_place_entity{name = "stone-wall", position = {x=position.x,y=position.y}, force=game.forces.player} then
        surface.create_entity{name = "stone-wall", position = {x=position.x,y=position.y}, force=game.forces.player}
      end
    end
  end
end

local function rand_box(surface, position)
  local chest = 'iron-chest'
  Loot.add(surface, position, chest)
end

local function rand_building(surface,maxs,position)
  local factory = Factories.roll_random_assembler(maxs)
  local entity = surface.create_entity({name = factory.entity, force = "neutral", position = position})
  entity.destructible = false
  entity.minable = false
  entity.operable = false
  entity.active = false
  Factories.register_random_assembler(entity, factory.id, factory.tier)

end
local function rand_shop(surface,position)
  local q =math_abs(position.x)/70
  local w =math_abs(position.y)/70
  local maxs =math.floor(q+w)
  MT.mountain_market(surface,position,maxs)
end

local function rand_worm(surface,position)
  BiterRolls.wave_defense_set_worm_raffle(math.sqrt(position.x ^ 2 + position.y ^ 2) * 0.19)
  surface.create_entity({name = BiterRolls.wave_defense_roll_worm_name(), position = position, force = 'enemy'})
end

local function on_chunk_generated(event)

  local surface = event.surface
  local this = WPT.get()
  if	not(surface.index == game.surfaces[this.active_surface_index].index) then return end

  local left_top_x = event.area.left_top.x
  local left_top_y = event.area.left_top.y

  local seed = surface.map_gen_settings.seed
  local area = event.area
  local set_tiles = surface.set_tiles
  local get_tile = surface.get_tile
  local position

  local map=diff.get()
  for x = 0, 31, 1 do
    for y = 0, 31, 1 do
      position = {x = left_top_x + x, y = left_top_y + y}
      local q =position.x
      local w =position.y
      local maxs =math.abs(q+w)+math.abs(q-w)


      if maxs<64 then
        build_base(surface,maxs,event,position)
      end

      if maxs>=170 then

        local rand_k=math_random(1,20000)

        if rand_k <= weight_shop then
          rand_shop(surface,position)
        end

        if weight_shop<rand_k and rand_k<= weight_shop+weight_build then
          rand_building(surface,maxs,position)
        end

        if  weight_shop+weight_build<rand_k and rand_k <= weight_shop+weight_build+weight_box then
          rand_box(surface, position)
        end

        if  weight_shop+weight_build+weight_box <rand_k and rand_k <= weight_shop+weight_build+weight_box+weight_worm then
          rand_worm(surface, position)
        end
      end
      if maxs>=64 then

        --if map.world == 1 then

        --  end
        if map.world == 2 then
          world_quarter(event,x,y)
        end
        if map.world == 3 and maxs<8800 then
          --  world_crossing(surface,maxs,position,area,left_top)
          world_water(surface,position,seed)
        end
        if map.world == 4  then

        world_water_dungle(surface,position,seed)
        end
        -- if map.world == 5 then
        --
        -- end
        if map.world ~= 4 then
        world_cave(surface,position,seed,get_tile,set_tiles,event)
      end
      end

    end
  end
  if map.world == 6 then
    world_winter(surface,event,seed)
  end
end



local function on_init()
  global.rocks_yield_ore_maximum_amount = 999
  global.rocks_yield_ore_base_amount = 100
  global.rocks_yield_ore_distance_modifier = 0.020

  global.watery_world_fishes = {}
  for _, prototype in pairs(game.entity_prototypes) do
    if prototype.type == "fish" then
      table.insert(global.watery_world_fishes, prototype.name)
    end
  end
end




local Event = require 'utils.event'
Event.on_init(on_init)

--Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
