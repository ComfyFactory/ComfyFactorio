local Event = require 'utils.event'
local diff=require'maps.amap.diff'
local Global = require 'utils.global'
local Task = require 'utils.task'
local arty_count = {}
local Public = {}
local get_baolei_pos=require'stronghold_generation_algorithm_v2'.find_available_stronghold_position
local RPG = require 'maps.amap.modules.rpg.table'
local Token = require 'utils.token'
local WPT = require 'maps.amap.table'
local Loot = require'maps.amap.loot'
local WD = require 'maps.amap.modules.wave_defense.table'

local ammo={}
ammo={
  [1]={name='firearm-magazine'},
  [2]={name='piercing-rounds-magazine'},
  [3]={name='uranium-rounds-magazine'}
}



local enemy_build_name = {
    ['biter-spawner'] = true,
    ['laser-turret'] = true,
    ['gun-turret'] = true,
    ['medium-worm-turret'] = true,
    ['flamethrower-turret'] = true,
    ['big-worm-turret'] = true,
    ['behemoth-worm-turret'] = true,
    ['artillery-turret'] = true,

}


local artillery_target_entities = {
  'character',
  --  'tank',
  --  'car',
  'radar',
  'biter-spawner',
  'spitter-spawner',
  --'lab',
  --  'electric-mining-drill',
  'roboport',
  --  'furnace',
  --'locomotive',
  --  'cargo-wagon',
  --'fluid-wagon',
  'artillery-wagon',
  'artillery-turret',
  --'laser-turret',
  --  'gun-turret',
  'flamethrower-turret',
  --  'silo',
    'spidertron'
}

Global.register(
arty_count,
function(tbl)
  arty_count = tbl
end
)

function Public.reset_table()
  arty_count.max = 100
  arty_count.unit={}
arty_count.neet_to_kill={}
  arty_count.pace = 1.5
  arty_count.radius = 135
  arty_count.distance = 1050
  arty_count.surface = {}
  arty_count.index=1
  arty_count.fire = {}
  arty_count.arty={}
  arty_count.roboport_wave={}
  arty_count.all = {}
  arty_count.gun={}
  arty_count.laser={}
  arty_count.flame={}

  arty_count.last={}
  arty_count.ammo_index=1
  arty_count.count=0
end



local on_init = function()
  Public.reset_table()
end
function Public.get_ammo()
  local index = arty_count.ammo_index
  local ammo_name =ammo[index].name
  return ammo_name
end

local function fast_remove(tbl, index)
  local count = #tbl
  if index > count then
    return
  elseif index < count then
    tbl[index] = tbl[count]
  end

  tbl[count] = nil
end

local function gun_bullet ()
  for index = 1, #arty_count.gun do
    local turret = arty_count.gun[index]
    if not (turret and turret.valid) then
      fast_remove(arty_count.gun, index)
      return
    end
    local index = arty_count.ammo_index
    local ammo_name =ammo[index].name
    turret.insert{name=ammo_name, count = 200}
  end
end

local function flame_bullet ()
  for index = 1, #arty_count.flame do
    local turret = arty_count.flame[index]
    if not (turret and turret.valid) then
      fast_remove(arty_count.flame, index)
      return
    end

    turret.fluidbox[1]={name = 'light-oil', amount = 100}

  end
end

local function energy_bullet ()

  for index = 1, #arty_count.laser do
    local turret = arty_count.laser[index]
    if not (turret and turret.valid) then
      fast_remove(arty_count.laser, index)
      return
    end
turret.energy = 99999999
  end
end

local function baolei_base(surface,position,robot_number,fix_number,out_wall,something,wave_number,baolei_id)
  local this = WPT.get()
  local k = 30
local area = {left_top = {position.x-k, position.y-k}, right_bottom = {position.x+k, position.y+k}}
  for _, e in pairs(surface.find_entities_filtered({type = {"unit-spawner",  "unit", "tree","simple-entity","cliff"}, area = area})) do
    if e.type =="unit-spawner" then
      local pos = surface.find_non_colliding_position(e.name, e.position, 128, 4)
      if position then
        local entity = surface.create_entity({name = e.name, position = pos, force = "enemy"})
      end
    end
    e.destroy()
  end

local dis=44
  for a=1,dis do
    for b=1,dis do
    local p = {position.x-dis*0.5+a, position.y-dis*0.5+b}
      surface.set_tiles({{name = "sand-1", position = p}})
    end
  end

arty_count.neet_to_kill[baolei_id]={}
local all_thing={}

  local roboport=surface.create_entity({name = "roboport", position = position, force = "enemy"})
  local chest=surface.create_entity({name = "logistic-chest-storage", position = {x=position.x,y=position.y-3}, force = "enemy"})
  local inserter=surface.create_entity({name = "stack-inserter", position = {x=position.x,y=position.y-2}, force = "enemy"})

all_thing[#all_thing+1]=chest
all_thing[#all_thing+1]=inserter
--运行shi请删除
arty_count.arty[baolei_id].roboport=roboport
arty_count.arty[baolei_id].baolei_id=baolei_id
  if robot_number>=350 then
    robot_number=350
  end
  if fix_number>=700 then
    fix_number=700
  end
  local unit_number=roboport.unit_number
arty_count.roboport_wave[unit_number]=wave_number

  roboport.insert{name="repair-pack",count=fix_number}
  roboport.insert{name="construction-robot",count=robot_number}

  roboport.destructible=false
  chest.destructible=false
  inserter.destructible=false

if something~=nil then
  for _, v in pairs(something) do
  if v.number ~= 0 then
    chest.insert({name = v.name, count = v.number})
  end
  end
end

  ---electric_power!
  arty_count.laser[#arty_count.laser+1]=roboport
  arty_count.laser[#arty_count.laser+1]=inserter

  --wall
  for i=1,14 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x-19+i,y=position.y-18}, force=game.forces.neutral} then
      local e=surface.create_entity{name = "stone-wall", position = {x=position.x-19+i,y=position.y-18}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end

  for i=1,18 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x+i,y=position.y-18}, force=game.forces.neutral} then
        local e=surface.create_entity{name = "stone-wall", position = {x=position.x+i,y=position.y-18}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end

  for i=1,36 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x-18+i,y=position.y+18}, force=game.forces.neutral} then
    local e=  surface.create_entity{name = "stone-wall", position = {x=position.x-18+i,y=position.y+18}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end
  for i=1,36 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x-18,y=position.y-18+i}, force=game.forces.neutral} then
    local e=  surface.create_entity{name = "stone-wall", position = {x=position.x-18,y=position.y-18+i}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end
  for i=1,36 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x+18,y=position.y-18+i}, force=game.forces.neutral} then
    local e=  surface.create_entity{name = "stone-wall", position = {x=position.x+18,y=position.y-18+i}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end


  if out_wall then

  --out_wall

  for i=1,18 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x-24+i,y=position.y-23}, force=game.forces.neutral} then
    local e=  surface.create_entity{name = "stone-wall", position = {x=position.x-24+i,y=position.y-23}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end

  for i=1,23 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x+i,y=position.y-23}, force=game.forces.neutral} then
    local e=  surface.create_entity{name = "stone-wall", position = {x=position.x+i,y=position.y-23}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end

  for i=1,46 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x-23+i,y=position.y+23}, force=game.forces.neutral} then
    local e=  surface.create_entity{name = "stone-wall", position = {x=position.x-23+i,y=position.y+23}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end
  for i=1,46 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x-23,y=position.y-23+i}, force=game.forces.neutral} then
    local e=  surface.create_entity{name = "stone-wall", position = {x=position.x-23,y=position.y-23+i}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end
  for i=1,46 do
    if surface.can_place_entity{name = "stone-wall", position = {x=position.x+23,y=position.y-23+i}, force=game.forces.neutral} then
    local e=  surface.create_entity{name = "stone-wall", position = {x=position.x+23,y=position.y-23+i}, force=game.forces.neutral}
      all_thing[#all_thing+1]=e
    end
  end
end
arty_count.neet_to_kill[baolei_id]=all_thing
end

local function urgrade_ammo(wave_number)
  if wave_number > 500 and arty_count.ammo_index==1 then
    arty_count.ammo_index=2
  end

  if wave_number > 800 and arty_count.ammo_index==2 then
    arty_count.ammo_index=3
  end
end

local enemy_turret={
--  [1]={name='stone-wall',worth=1,wave_number=0},
  [2]={name='biter-spawner',worth=20,wave_number=200},
  [3]={name='laser-turret',worth=10,wave_number=100},
  [4]={name='gun-turret',worth=5,wave_number=100},
  [5]={name='medium-worm-turret',worth=5,wave_number=100},
  [6]={name='flamethrower-turret',worth=10,wave_number=150},
  [7]={name='big-worm-turret',worth=10,wave_number=150},
  [8]={name='behemoth-worm-turret',worth=25,wave_number=400},
  [9]={name='artillery-turret',worth=500,wave_number=1300}
}


local function get_new_arty()
  local this = WPT.get()
  local wave_number = WD.get('wave_number')
  if wave_number <100 then return end
    local wave_defense_table = WD.get_table()
    if not wave_defense_table.target  then return end
    if not wave_defense_table.target.valid  then return end
    local target= wave_defense_table.target
    local surface=target.surface

local position=get_baolei_pos(target.position,65,surface)
if position == nil then return end
local a = position.x
local b = position.y
  game.print({'amap.biter_build',position.x,position.y,surface.name})
  urgrade_ammo(wave_number)
  local map=diff.get()
  local all_worth = wave_number*map.diff
  local fix_function=wave_number-500
  if fix_function<0 then fix_function=0 end
  if fix_function>1000 then fix_function=1000 end
  local robot_number= 1+math.floor(fix_function*0.35)
  local fix_number=1+math.floor(fix_function*0.7)
  local out_wall=false
  if wave_number >= 500 then out_wall= true end


  --  local q = dis - arty_count.last -5
    local fix_worth=0
  if all_worth<=20 then all_worth=20 end
  if all_worth>=1000 then
     fix_worth = all_worth-1000
    all_worth=1000
  end

  local can_build_turret={}
  for i,building in pairs(enemy_turret) do
    if wave_number>=building.wave_number then
     can_build_turret[#can_build_turret+1]=building
end
  end

local baolei_id=#arty_count.arty+1
arty_count.arty[baolei_id]={}
arty_count.arty[baolei_id].number=0
arty_count.arty[baolei_id].roboport={}

  while all_worth > 0 do

    local index = math.random(1,#can_build_turret)
    local turret_name = can_build_turret[index].name
    local worth=can_build_turret[index].worth

    local e = surface.create_entity{
    name = turret_name,
    position = {x=position.x+math.random(-18,18),y=position.y+math.random(-18,18)},
    force=game.forces.enemy,
    direction= math.random(1,7)}


    if e then
      if e.name == 'gun-turret' then arty_count.gun[#arty_count.gun+1]=e end
      if e.name == 'laser-turret' then arty_count.laser[#arty_count.laser+1]=e end
      if e.name == 'flamethrower-turret' then arty_count.flame[#arty_count.flame+1]=e end
      if e.name == 'artillery-turret' then
        arty_count.all[#arty_count.all+1]=e
        arty_count.fire[#arty_count.fire+1]=0
        arty_count.count = arty_count.count + 1
      end

    end
    if e.name ~= "biter-spawner" then
    arty_count.arty[baolei_id].number=arty_count.arty[baolei_id].number+1
    arty_count.unit[e.unit_number]=baolei_id
  end
    all_worth=all_worth-worth
  end

  local something={
    [1]={name='repair-pack',worth=3,wave_number=100,index=1,number=0},
    [2]={name='construction-robot',worth=2,wave_number=100,index=2,number=0},
    [3]={name='laser-turret',worth=10,wave_number=100,index=4,number=0},
    [4]={name='gun-turret',worth=5,wave_number=100,index=5,number=0},
    [5]={name='flamethrower-turret',worth=10,wave_number=150,index=6,number=0},
    [6]={name='land-mine',worth=1,wave_number=100,index=1,number=0},
  }

  if wave_number >= 1300 then
something[7]={name='artillery-turret',worth=500,wave_number=1300,index=7,number=0}
  end

  while fix_worth > 0 do
    local index = math.random(1,#something)
    local name = something[index].name
    local worth=something[index].worth
    fix_worth=fix_worth-worth
    something[index].number=something[index].number+1
  end


     baolei_base(surface,position,robot_number,fix_number,out_wall,something,wave_number,baolei_id)

  if wave_number>=2000 and map.final_wave then
    local e = surface.create_entity{name = 'artillery-turret', position = {x=pos.x,y=pos.y},
    force=game.forces.enemy,
    direction= math.random(1,7)}
    arty_count.all[#arty_count.all+1]=e
    arty_count.fire[#arty_count.fire+1]=0
    arty_count.count = arty_count.count + 1
  end

local mind_number = wave_number*0.01
  for i=1,14+mind_number do
    surface.create_entity{name = "land-mine", position ={x=position.x+math.random(-18,18)*1.5,y=position.y+math.random(-18,18)*1.5}, force=game.forces.enemy}
  end

  local many_baozhang =math.floor(wave_number*0.008)
  if many_baozhang >10 then many_baozhang=10 end
local max_luck = wave_number*0.25+100
local min_luck = wave_number*0.15+50
if max_luck>=800 then max_luck =800 end
if min_luck>=500 then min_luck =500 end

  while many_baozhang>=0 do
    local magic = math.random(min_luck, max_luck)
  local chest= Loot.cool(surface, surface.find_non_colliding_position("steel-chest", position, 20, 1, true), 'steel-chest', magic)
  chest.operable=false
  chest.minable=false
  chest.destructible=false
  chest.force=game.forces.enemy
    many_baozhang= many_baozhang-1
  end

end

local artillery_target_callback =
Token.register(
function(data)
  local position = data.position
  local entity = data.entity

  if not entity.valid then
    return
  end

  local tx, ty = position.x, position.y
  local pos = entity.position
  local x, y = pos.x, pos.y
  local dx, dy = tx - x, ty - y
  local d = dx * dx + dy * dy
  if d >= 1024 and d <= 441398 then -- 704 in depth~
    if entity.name == 'character' then
      entity.surface.create_entity {
        name = 'artillery-projectile',
        position = position,
        target = entity,
        force = 'enemy',
        speed = arty_count.pace
      }
    elseif entity.name ~= 'character' then
      entity.surface.create_entity {
        name = 'artillery-projectile',
        position = position,
        target = entity,
        force = 'enemy',
        speed = arty_count.pace
      }
    end
  end
end
)


local function add_bullet()
  flame_bullet()
end
local function energy()
  energy_bullet()
end

local function do_artillery_turrets_targets()
  if arty_count.count <= 0 then return end

  --选取重炮

  arty_count.index=arty_count.index+1
  if arty_count.index > arty_count.count then arty_count.index=1 end

  local index = arty_count.index
  local turret = arty_count.all[index]

  if not (turret and turret.valid) then
    fast_remove(arty_count.all, index)
    fast_remove(arty_count.fire, index)
    arty_count.count=arty_count.count-1
    return
  end

  local now =game.tick
  if not arty_count.fire[index] then
    arty_count.fire[index] = 0
  end
  if (now - arty_count.fire[index]) < 480 then return end
  arty_count.fire[index] = now

  local position = arty_count.all[index].position


  --扫描区域
  local this = WPT.get()
  local surface = game.surfaces[this.active_surface_index]
  local entities = surface.find_entities_filtered{position = position, radius = arty_count.radius, name = artillery_target_entities, force = game.forces.player}

  -- local entities = surface.find_entities_filtered {area = normal_area, name = artillery_target_entities, force = 'player'}
  if #entities == 0 then
    return
  end
  for i,v in ipairs(entities) do
    if v.destructible ==false then
      entities[i]=nil
    end
    -- body...
  end

  --开火
  for i = 1, arty_count.count do
    local entity = entities[math.random(#entities)]
    --game.print(entity.position)
    if entity and entity.valid then
      local data = {position = position, entity = entity}
      Task.set_timeout_in_ticks(i * 60, artillery_target_callback, data)
    end
  end
end

local function is_roboport_hear(surface,position,area)
local roboport=false
roboports=surface.find_entities_filtered({type = {"roboport"}, area = area,force=game.forces.enemy})
if #roboports-1~=0 then
roboport=true
end
return roboport
end

local function kill_wall(baolei_id)

for i,v in pairs(arty_count.neet_to_kill[baolei_id]) do
  if v and v.valid then
  if v.name ~= "logistic-chest-storage" or  v.name ~= "stack-inserter" then
     v.destructible=true
     v.die()

  end
end
end


end

local function on_entity_died(event)
  local entity = event.entity

if not entity.valid or not entity then return end
local name = event.entity.name
local force = event.entity.force
if force~=game.forces.enemy then return end

 if  arty_count.unit[entity.unit_number] then
    local unit_number=entity.unit_number
    local baolei_id=arty_count.unit[unit_number]
    arty_count.arty[baolei_id].number=arty_count.arty[baolei_id].number-1
    if arty_count.arty[baolei_id].number <= 0 then
arty_count.arty[baolei_id].roboport.destructible=true



     kill_wall(baolei_id)
    end
  arty_count.unit[unit_number]=nil

 end


if name ~="roboport" then return end

local position=entity.position
local surface=entity.surface

local k = 5
local area_1 = {left_top = {position.x-k, position.y-k}, right_bottom = {position.x+k, position.y+k}}

for _, e in pairs(surface.find_entities_filtered({name = {"steel-chest","crash-site-chest-1","crash-site-chest-2"}, area = area_1})) do
  e.operable=true
  e.minable=true
   e.force=game.forces.player
end



local unit_number=entity.unit_number
local wave_number=arty_count.roboport_wave[unit_number]
arty_count.roboport_wave[unit_number]=nil

 --if is_roboport_hear(surface,position,area)== false then
 local baolei_id
 for i,v in pairs(arty_count.arty) do
   local id=v.baolei_id
   local roboport= arty_count.arty[id].roboport
  if roboport== entity then
    baolei_id=id
    break
  end
 end
 arty_count.arty[baolei_id]=nil


-- end
game.print({'amap.baolei_die'})

if not event.cause then
    return
end
if not event.cause.valid then
    return
end

if event.cause.name ~= 'character' then
    return
end

if not event.cause.player then
    return
end

local player = event.cause.player
local rpg_t = RPG.get('rpg_t')

player.insert{name="coin",count=wave_number*5}
rpg_t[player.index].xp= rpg_t[player.index].xp +wave_number
game.print({'amap.kill_baolei',player.name,wave_number,wave_number*5})

end

local function on_robot_built_entity(event)
  --change_pos  改变位置

  local e = event.created_entity
  if not e or not e.valid then return end
  if e.force~= game.forces.enemy then return end

  if e then
    if e.name == 'gun-turret' then arty_count.gun[#arty_count.gun+1]=e end
    if e.name == 'laser-turret' then arty_count.laser[#arty_count.laser+1]=e end
    if e.name == 'flamethrower-turret' then arty_count.flame[#arty_count.flame+1]=e end
    if e.name == 'artillery-turret' then
      arty_count.all[#arty_count.all+1]=e
      arty_count.fire[#arty_count.fire+1]=0
      arty_count.count = arty_count.count + 1
    end

    if  e.name~="land-mine" then
    local position=e.position
    for i,v in pairs(arty_count.arty) do
      if v.roboport and v.roboport.valid then
      local pos=v.roboport.position
      local x= pos.x
      local y = pos.y
      local dist = math.sqrt(x*x+y*y)
      if dist <= 24 then
        local baolei_id=v.baolei_id
        arty_count.arty[baolei_id].number=arty_count.arty[baolei_id].number+1
        arty_count.unit[e.unit_number]=baolei_id

         return
      end
      end
end
    end
  end
end

Event.add(defines.events.on_entity_died, on_entity_died)
Event.on_nth_tick(2000, gun_bullet)
--Event.on_nth_tick(1600, get_new_arty)
Event.on_nth_tick(54000, get_new_arty)
Event.on_nth_tick(120, add_bullet)
Event.on_nth_tick(10, energy)
Event.on_nth_tick(60, do_artillery_turrets_targets)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.on_init(on_init)


return Public
