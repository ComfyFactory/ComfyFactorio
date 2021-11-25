local Token = require 'utils.token'
local Task = require 'utils.task'
local Event = require 'utils.event'
local Global = require 'utils.global'
local WPT = require 'maps.amap.table'
local Rand = require 'maps.amap.random'
local WD = require 'maps.amap.modules.wave_defense.table'
local RPG = require 'maps.amap.modules.rpg.table'
local diff=require 'maps.amap.diff'
local Alert = require 'utils.alert'

local starting_items = {
  ['submachine-gun'] = 1,
  ['firearm-magazine'] = 30,
  ['wood'] = 16,
  ['car']=1,

}

Global.register(
this,
function(t)
  this = t
end
)

local Public = {}

local random = math.random
local floor = math.floor
local remove = table.remove
local sqrt = math.sqrt

function Public.get_player_data(player, remove_user_data)
  local players = WPT.get('players')
  if remove_user_data then
    if players[player.index] then
      players[player.index] = nil
    end
  end
  if not players[player.index] then
    players[player.index] = {}
  end
  return players[player.index]
end

local get_player_data = Public.get_player_data


local function fast_remove(tbl, index)
  local count = #tbl
  if index > count then
    return
  elseif index < count then
    tbl[index] = tbl[count]
  end

  tbl[count] = nil
end
local function get_car_number()
  local this=WPT.get()
  local car_number=0

  for k, player in pairs(game.connected_players) do
    if  this.tank[player.index] and this.tank[player.index].valid then
    car_number=car_number+1
    this.tank[player.index].destructible=true
  else
    this.tank[player.index]=nil
    this.whos_tank[player.index]=nil
    this.have_been_put_tank[player.index]=false
  end
  end
  return car_number
end


local function clac_time_weights()
  local this=WPT.get()
  if this.start_game~=2 then return end
for k, player in pairs(game.connected_players) do
    if  this.tank[player.index] and this.tank[player.index].valid then
      local index = player.index
      local car =this.tank[player.index]
      if  this.car_pos[index]==nil then
        this.car_pos[index]=car.position
        this.time_weights[index]=0

      else
        if  this.tank[player.index].name == "spidertron"then
          this.time_weights[index]=150
      else

        local x = this.car_pos[index].x-car.position.x
        local y = this.car_pos[index].y-car.position.y
        local dist =x*x+y*y

        if dist > 3025 then
          this.car_pos[index]=car.position
          this.time_weights[index]=0
        else
          this.time_weights[index]=this.time_weights[index]+15
          this.car_pos[index]=car.position

          if   this.time_weights[index] >= 150 then
            this.time_weights[index]=150
          end
        end

        end
      end
   end
end
end

local function calc_players()
  local players = game.connected_players
  local check_afk_players = WPT.get('check_afk_players')
  if not check_afk_players then
    return #players
  end
  local total = 0
  for i = 1, #players do
    local player = players[i]
    if player.afk_time < 36000 then
      total = total + 1
    end
  end
  if total <= 0 then
    total = 1
  end
  return total
end


local world_name ={
  [1]={'amap.world_name_1'},
  [2]={'amap.world_name_2'},
  [3]={'amap.world_name_3'},
  [4]={'amap.world_name_4'},
  [5]={'amap.world_name_5'},
  [6]={'amap.world_name_6'},
}
local function out_info(player)
  local map = diff.get()
  player.print({'amap.game_shuju',map.sum,map.win,map.gg,map.diff})
  player.print({'amap.map_shuju',world_name[map.world],map.final_wave_record[map.world],map.max_world,map.world_number})
  local best_record = map.map_record[map.world]
  if best_record == nil then best_record=0 end
  player.print({'amap.best_record',best_record})
  for i=1,map.record_number do
    player.print({'amap.game_record',map.record[i].wave_number,map.record[i].name,map.record[i].pass_number})
    -- body...
  end
end

function Public.game_info(event)
  for k, p in pairs(game.connected_players) do
    local player = game.connected_players[k]
    out_info(player)
  end
end

local car_weiht={
   ["car"]=10,
   ["tank"]=60,
   ["spidertron"]=360
}


local function get_car_index()
local all_cars={}
local spider_cars={}
local rpg_t = RPG.get('rpg_t')
local this= WPT.get()
for k, player in pairs(game.connected_players) do
    if  this.tank[player.index] and this.tank[player.index].valid then

      local car = this.tank[player.index]
      local base_weight=car_weiht[car.name]
      if this.had_sipder[player.index]==true then
        base_weight=360
      end
      --   game.print("基础权重为: " .. base_weight .. '')
      if this.car_pos[player.index] and car then
      local x = this.car_pos[player.index].x-car.position.x
      local y = this.car_pos[player.index].y-car.position.y
      local dist =x*x+y*y

      if dist > 3025 then
        this.car_pos[player.index]=car.position
        this.time_weights[player.index]=0
      end
      end

      local time_weight=0
      if this.time_weights[player.index] then
        time_weight=this.time_weights[player.index]
      end

      if this.had_sipder[player.index] then
        time_weight=150
      end


  --  game.print("时间权重为: " .. time_weight .. '')
      local enemy = game.forces.enemy
      local rpg_weight = 0
    --  if enemy.evolution_factor < 0.5 then
        local lv =rpg_t[player.index].level
        rpg_weight=lv
--game.print("RPG权重为: " .. rpg_weight .. '')
      --end

      local all_weight = base_weight+time_weight+rpg_weight
    --   game.print("总权重为: " .. all_weight .. '')

     local id = #all_cars+1
      all_cars[id]={}
      all_cars[id].index=player.index
      all_cars[id].weight=all_weight
     local sipder_id=#spider_cars+1
      if this.had_sipder[player.index] then
        spider_cars[sipder_id]={}
        spider_cars[sipder_id].index=player.index
        spider_cars[sipder_id].weight=all_weight
      end
    end
end

if #spider_cars~=0 then
local k_rand
k_rand=math.random(1, 3)
if k_rand ~=1 then
all_cars=spider_cars
end

end


  local choices = {indexs = {}, weights = {}}
  for _, car in pairs(all_cars) do
      table.insert(choices.indexs, car.index)
      table.insert(choices.weights, car.weight)
  end
--  game.print("总随机成员 " .. #all_cars .. '')
  return Rand.raffle(choices.indexs, choices.weights)
end


function Public.get_random_car(print)

  local this=WPT.get()
  local index = get_car_index()
--   game.print("随机结果为:" .. index .. '')
    if print then
      local name=game.players[index].name
      game.print(({'amap.car_will_attack',name}),{r=255,b=100,g=100})
      this.car_name=name
    end
    return this.tank[index]
end


local function get_base_biter()
  local this=WPT.get()
  local main_surface= game.surfaces[this.active_surface_index]
  if not main_surface then return false end
  local entities = main_surface.find_entities_filtered{position=game.forces.player.get_spawn_position(main_surface), radius = 50 , force = game.forces.enemy}

  if #entities == 0 then
    return false
  else
    return true
  end
end

function Public.on_player_joined_game(event)
  local active_surface_index = WPT.get('active_surface_index')
  local player = game.players[event.player_index]
  local surface = game.surfaces[active_surface_index]
  local reward = require 'maps.amap.main'.reward
  local player_data = get_player_data(player)
  if not player_data.first_join then

    for item, amount in pairs(starting_items) do
      player.insert({name = item, count = amount})
    end
    local rpg_t = RPG.get('rpg_t')
    local wave_number = WD.get('wave_number')
    local this = WPT.get()

    for i=0,this.science do
      local point = math.floor(math.random(1,5))
      local money = math.floor(math.random(1,100))
      rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+point
      player.insert{name='coin', count = money}
      player.print({'amap.science',point,money}, {r = 0.22, g = 0.88, b = 0.22})
    end

    rpg_t[player.index].xp = rpg_t[player.index].xp + wave_number*10



    player_data.first_join = true
    player.print({'amap.joingame'})
    out_info(player)
  end

  local this=WPT.get()
  local index = player.index
  local main_surface = game.surfaces[this.active_surface_index]
  if player.surface.index ~= active_surface_index then
    --player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 20, 1, false) or {x=0,y=0}, surface)
--不在同一个时间
    if  this.tank[index] and this.tank[index].valid then --有坦克 并且有效
      player.teleport(main_surface.find_non_colliding_position('character', this.tank[player.index].position, 20, 1, false) or {x=0,y=0}, main_surface)
    else
	--无坦克

  player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 20, 1, false) or {x=0,y=0}, surface)
  if get_base_biter() then
    if get_car_number()~=0 then
   local car=Public.get_random_car(false)
   if car then
     local pos = car.position
     player.teleport(main_surface.find_non_colliding_position('character',pos, 20, 1, false) or {x=0,y=0}, main_surface)
     end
  end
end
    end


   --在同一个世界！
	else

  local p = {x = player.position.x, y = player.position.y}
    local get_tile = surface.get_tile(p)
    if get_tile.valid and get_tile.name == 'out-of-map' then
      player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 20, 1, false) or {x=0,y=0}, surface)
      --player.teleport({x=0,y=0}, surface)
    end
  end
end


local function on_player_mined_entity(event)
  if not event.entity.valid then return end
  local name = event.entity.name
  local force = event.entity.force
  local entity = event.entity

  local this = WPT.get()
  if force.index == game.forces.player.index then
    if name == 'flamethrower-turret' then
    this.flame = this.flame - 1
    if this.flame <= 0 then
      this.flame = 0
    end
  end

if name == 'land-mine' then
this.now_mine = this.now_mine - 1
if this.now_mine <= 0 then
  this.now_mine = 0
end
end
end

end


function Public.on_pre_player_left_game(event)
  local offline_players_enabled = WPT.get('offline_players_enabled')
  if not offline_players_enabled then
    return
  end

  local offline_players = WPT.get('offline_players')
  local player = game.players[event.player_index]
  local ticker = game.tick
  if player.character then
    offline_players[#offline_players + 1] = {
      index = event.player_index,
      name = player.name,
      tick = ticker
    }
  end
end

local steal_oil = {
  'assembling-machine-1',
  'assembling-machine-2',
  'assembling-machine-3',
  'oil-refinery',
  'chemical-plant',
  'pipe',
  'pipe-to-ground',
  'pump',
  'storage-tank',
  'flamethrower-turret',

}
local on_player_or_robot_built_entity = function(event)
  --change_pos  改变位置
  local name = event.created_entity.name
  local force = event.created_entity.force
  local entity = event.created_entity
  local this = WPT.get()

  if force.index ~= game.forces.player.index then return end
for i,v in ipairs(steal_oil) do
  if name == v  then
    local main_surface = game.surfaces[this.active_surface_index]
    local entities = main_surface.find_entities_filtered{position = entity.position, radius = 5, name = 'flamethrower-turret'  , force = game.forces.enemy}
if #entities~=0 then
    entity.die()
  end
  end
end


  if force.index == game.forces.player.index then
     if name == 'flamethrower-turret'  then
    if this.flame >= this.max_flame then
      game.print({'amap.too_many'})
      entity.destroy()
    else
      this.flame = this.flame + 1
      game.print({'amap.ok_many',this.flame,this.max_flame})
    end
  end

  if name == 'land-mine'  then
 if this.now_mine >= this.max_mine then
   game.print({'amap.too_many_mine'})
   entity.destroy()
 else
   this.now_mine = this.now_mine + 1
 end
end


  end
end



local disable_recipes = function()
  local force = game.forces.player
  --force.recipes['car'].enabled = false
  force.recipes['tank'].enabled = false
  force.recipes['pistol'].enabled = false
  --force.recipes['land-mine'].enabled = false
  force.recipes['spidertron-remote'].enabled = false
  if is_mod_loaded('Krastorio2') then
    force.recipes['kr-advanced-tank'].enabled = false
  end
  --  force.recipes['flamethrower-turret'].enabled = false
end




function Public.disable_tech()
  game.forces.player.technologies['landfill'].enabled = false
  game.forces.player.technologies['spidertron'].enabled = false
  game.forces.player.technologies['spidertron'].researched = false
  local force = game.forces.player
  if is_mod_loaded('Krastorio2') then
    force.technologies['kr-advanced-tank'].enabled = false
    force.technologies['kr-advanced-tank'].researched = false
  end

  disable_recipes()
end

local disable_tech = Public.disable_tech
function Public.on_research_finished(event)
--  disable_tech()
if event.research.force.index==game.forces.enemy.index then return end
local this = WPT.get()
this.science=this.science+1
local rpg_t = RPG.get('rpg_t')
for k, p in pairs(game.connected_players) do
  local player = game.connected_players[k]
  local point = math.floor(math.random(1,5))
  local money = math.floor(math.random(1,100))
  rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+point
  player.insert{name='coin', count = money}
  --	player.print({'amap.science',point,money}, {r = 0.22, g = 0.88, b = 0.22})
  Alert.alert_player(player, 5, {'amap.science',point,money})
  k=k+1
end

disable_recipes()
end



local on_research_finished = Public.on_research_finished
local on_player_joined_game = Public.on_player_joined_game


local on_pre_player_left_game = Public.on_pre_player_left_game

Event.add(defines.events.on_built_entity, on_player_or_robot_built_entity)
Event.add(defines.events.on_robot_built_entity, on_player_or_robot_built_entity)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)


Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)

  Event.on_nth_tick(108000, clac_time_weights)


return Public
