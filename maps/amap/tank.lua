local Event = require 'utils.event'
local WPT = require 'maps.amap.table'
local RPG = require 'maps.amap.modules.rpg.table'
local diff=require 'maps.amap.diff'
local WD = require 'maps.amap.modules.wave_defense.table'
local game_info=require 'maps.amap.functions'.game_info
local IC = require 'maps.amap.ic.table'
local Alert = require 'utils.alert'
local Server = require 'utils.server'
local get_random_car =require "maps.amap.functions".get_random_car

local world_time = {
  [1]=7200* 10*2,
  [2]=7200* 15,
  [3]=7200* 10*2,
  [4]=7200* 10*2,
  [5]=7200* 15*3,
  [6]=7200* 15*2,
}
local car_name={
  ["car"]=true,
  ["tank"]=true,
  ["spidertron"]=true,
  ["wood"]=true,
}

local car_items = {
  ['gun-turret'] = 16,
  ['firearm-magazine'] = 240,
  ['stone-wall'] = 144,
  ['burner-mining-drill'] = 8,
  ['electric-mining-drill'] = 8,
  ['stone-furnace'] = 20,
  ['steam-engine'] = 2,
  ['boiler'] = 1,
  ['offshore-pump'] = 1,
}

local function item_build_car(player)
  game.print({'amap.build_car',player.name})
  player.print({'amap.car_jingao'},{r=255,b=100,g=100})
  local wave_number = WD.get('wave_number')

  for item, amount in pairs(car_items) do
    if item =='firearm-magazine' or item == 'gun-turret' or item == 'stone-wall' then
      local k = wave_number/35-1
      if k <0 then k =1 end
      if k >= 10 then k = 10 end
        player.insert({name = item, count = amount*k})
    end
    player.insert({name = item, count = amount})
  end


    if wave_number>=350 then
      local k = wave_number/35-10
      if k <0 then k =1 end
      if k >= 10 then k = 10 end
        player.insert({name = 'laser-turret', count = 4*k})
        player.insert({name = 'laser-turret', count = 10})
    end
end
local function kill_base_biter()
  local this=WPT.get()
  local main_surface= game.surfaces[this.active_surface_index]
  if not main_surface then return false end
  local entities = main_surface.find_entities_filtered{position=game.forces.player.get_spawn_position(main_surface), radius = 25 , force = game.forces.enemy}

  if #entities ~= 0 then
    for k,v in pairs(entities) do
      v.die()
    end

  end
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

local function on_player_build_entity(event)

  local entity=event.created_entity
  if not entity then return end
  if not entity.valid then return end
  local player = game.players[event.player_index]
  local this=WPT.get()
  local index=player.index
  local position=entity.position
  local surface=entity.surface
  if	not(surface.index == game.surfaces[this.active_surface_index].index) then return end


  --如果放的是坦克，并且没有放过坦克

  if  car_name[entity.name]  then
    if entity.name=="spidertron" then this.had_sipder[index] = true end
    this.player_position[index]=nil
    if this.have_been_put_tank[index]==false then
      this.have_been_put_tank[index]=true
    end
    if this.tank[index] == nil then
      this.tank[index]=entity
      entity.minable=false
      this.whos_tank[index]=entity.unit_number
      player.print({'amap.car_info'},{r=100,b=200,g=200})
      if not this.first_build_car[index] then
        item_build_car(player)
        this.first_build_car[index]=true
      end


      local area = {left_top = {position.x-24, position.y-2}, right_bottom = {position.x, position.y+3}}
      for _, e in pairs(surface.find_entities_filtered({type = {"cliff"}, area = area})) do
        e.destroy()
      end

      if this.start_game~=2 then
        game.print({'amap.start_game'})
        this.start_game=2

        local wave_number = WD.get('wave_number')
        local world_1 = diff.get()
        local number=world_1.world
        if wave_number<1 then
          WD.set().next_wave = game.tick +world_time[number]
        end

        local wave_defense_table = WD.get_table()
        wave_defense_table.target =get_random_car(true)
      end

    end
    --如果没有放过坦克
  end
    if entity.name~=car_name[entity.name]  and this.have_been_put_tank[index]==false then

      if entity.name == 'flamethrower-turret' then
        this.flame = this.flame - 1
        if  this.flame<0 then
          this.flame=0
        end

      end
      if entity.name == 'land-mine' then
        this.now_mine = this.now_mine - 1
        if   this.now_mine<0 then
          this.now_mine=0
        end
      end
      if entity.type~='entity-ghost' and entity.name~='tile-ghost' then
        local health = entity.health
        local name = entity.name


        if name == "straight-rail" or name == "curved-rail" then
          name = "rail"
        end
        player.insert{name=name, count =1,health=health}
      end
      entity.destroy()
      player.print({'amap.no_put_tank'})
    end
    --如果试图放蜘蛛
    if not entity.valid then return end

    if entity.name=="spidertron"  and this.tank[index].name=="tank" then
      local entities = surface.find_entities_filtered{position=player.position, radius = 7 ,name = "tank", force = game.forces.player}
      local old_car_is_hear=false
      for i,car in ipairs(entities) do
        if car ==  this.tank[index] then
          old_car_is_hear=true
        end
      end
      if old_car_is_hear then
        this.player_position[index]=player.position
        this.tank[index].minable=true
        player.print({'amap.try_to_put_zhizhu'})
      else
        player.print({'amap.old_car_is_hear'})
      end
    end
    if entity.name=="tank"  and this.tank[index].name=="car" then
      --    local entities = surface.find_entities_filtered{position=player.position, radius = 15 , force = game.forces.enemy}
      local entities = surface.find_entities_filtered{position=player.position, radius = 7 ,name = "car", force = game.forces.player}
      local old_car_is_hear=false
      for i,car in ipairs(entities) do
        if car ==  this.tank[index] then
          old_car_is_hear=true
        end
      end
      if old_car_is_hear then
        this.player_position[index]=player.position
        this.tank[index].minable=true
        player.print({'amap.try_to_put_zhizhu'})
      else
        player.print({'amap.old_car_is_hear'})
      end
    end
    if entity.name=="spidertron"  and this.tank[index].name=="car" then
      local entities = surface.find_entities_filtered{position=player.position, radius = 7 ,name = "car", force = game.forces.player}
      local old_car_is_hear=false
      for i,car in ipairs(entities) do
        if car ==  this.tank[index] then
          old_car_is_hear=true
        end
      end
      if old_car_is_hear then
        this.player_position[index]=player.position
        this.tank[index].minable=true
        player.print({'amap.try_to_put_zhizhu'})
      else
        player.print({'amap.old_car_is_hear'})
      end
    end


end


local function game_over()
  local this = WPT.get()
  local map=diff.get()
  local wave_defense_table = WD.get_table()
  local wave_number = WD.get('wave_number')
  local msg = {'amap.lost',wave_number}


  for _, p in pairs(game.connected_players) do
    Alert.alert_player(p, 25, msg)
  end
  Server.to_discord_embed(table.concat({'** we lost the game ! Record is ', wave_number}))
  local Reset_map = require 'maps.amap.main'.reset_map
  wave_defense_table.game_lost = true
  wave_defense_table.target = nil

  if map.map_record[map.world] ==nil then
    map.map_record[map.world]=0
  end
  if wave_number>map.map_record[map.world] then
    map.map_record[map.world]=wave_number
  end

  map.sum=map.sum+1
--  map.world=map.world+1
 map.world=math.random(1, map.max_world)


  if this.pass == true then
    map.win=map.win+1
    if map.max_world<map.world_number and this.times>=2 then
      map.max_world =map.max_world+1
    end
    map.world=map.max_world
    map.diff=map.diff+0.1
  else
    map.gg=map.gg+1
    map.diff=map.diff-0.05
    if  map.diff<1 then
      map.diff=1
    end
  end
  if map.world > map.max_world then
    map.world =1
  end
  map.final_wave=true
  map.rocket_diff=true

  Reset_map()
  for _, player in pairs(game.connected_players) do
    player.play_sound {path = 'utility/game_lost', volume_modifier = 0.75}
  end
  game_info()
  for k, player in pairs(game.connected_players) do
    local index = player.index
    this.have_been_put_tank[index]=false
  end
end

local function on_player_mined_entity(event)

  local entity=event.entity

  if not entity then return end
  if not entity.valid then return end
  if not car_name[entity.name] then return end

  local this=WPT.get()
  local player = game.players[event.player_index]
  local index=player.index

  if entity==this.tank[index] then
    this.tank[index]=nil
    this.have_been_put_tank[index]=false
    this.whos_tank[index]=nil
  end
  if entity == this.upgrade_car[index] then
 this.upgrade_car[index] =nil
this.player_position[index]=nil
  end
end

local function on_entity_died(event)

  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end
  if car_name[entity.name] then
    local unit_number=entity.unit_number

    local this=WPT.get()
    --如果是载具，就循环找出是谁的载具
    local index=0

    for k, player in pairs(game.connected_players) do
      if this.whos_tank[player.index]==unit_number then
        index = player.index
      end
    end



    if index ~= 0 then
      if this.tank[index].name == "spidertron" then
        this.had_sipder[index]=false
      end
      this.tank[index]=nil
      this.whos_tank[index]=nil
      this.have_been_put_tank[index]=false
      if  this.time_weights[index] then
      if this.time_weights[index] >=45  then
      this.time_weights[index]=0
      end


    end
    end
    local car_number=get_car_number()
    if index ~=0 then
    game.print({'amap.tank_die',game.players[index].name,car_number})
  end
    if car_number==0 then
      this.reset_time=3600
      this.start_game=3
      game.print({'amap.ready_to_reset'})
    end
  end
end

local choois_target = function()
  local this = WPT.get()
  local wave_number = WD.get('wave_number')


-- for k, p in pairs(game.connected_players) do
--     local player = game.connected_players[k]
--       local something = player.get_inventory(defines.inventory.chest)
--
--         if something ~= nil then
--
--           for k, v in pairs(something.get_contents()) do
--             if k == "coin" then
--             game.print(player.name .. "有" .. v .. "的" .. k .. "")
--           end
--           end
--         end
-- end

  if   this.start_game==1 then
    for k, player in pairs(game.connected_players) do
      local rpg_t = RPG.get('rpg_t')
      rpg_t[player.index].xp = 0

      local something = player.get_inventory(defines.inventory.chest)
      if something ~= nil then
      for n, v in pairs(something.get_contents()) do
        if not car_name[n] then
          player.remove_item{name=n, count = v}
        end
      end
    end
    end

    game.print({'amap.no_start_game'})
    return
  end

  local player_count = calc_players()
  local car_number =  get_car_number()
  if car_number == 0  then
      if this.reset_time== 0 and this.start_game==2 then
      this.reset_time=3600
      this.start_game=3
      game.print({'amap.ready_to_reset'})
    end
  end
 if wave_number ==1 and this.frist_target==false then
   local wave_defense_table = WD.get_table()
   wave_defense_table.target =get_random_car(true)
    this.frist_target=true
 end
  local last = this.target_last
  if last < wave_number then
    if wave_number % 35 == 0 then
      local wave_defense_table = WD.get_table()
      wave_defense_table.target =get_random_car(true)
     this.target_last=wave_number
     for i,v in ipairs(this.car_wudi) do
       if v and v.valid then
       v.destructible = false
       this.car_wudi[i]=nil
      end
       -- body...
     end
    end

  end
end


local function on_player_joined_game(event)
  local player = game.players[event.player_index]
  local this=WPT.get()
  local index=player.index

  if this.have_been_put_tank[index]==nil then
    this.have_been_put_tank[index]=false
  end

  if this.tank[index] and this.tank[index].valid then
    this.tank[index].destructible = true
    this.tank[index].operable = true
    this.tank[index].active = true
    this.start_game=2
  end

end


local function on_pre_player_left_game(event)

  local player = game.players[event.player_index]
  local this=WPT.get()
  local index=player.index
  if not this.tank[index] then return end
  local car = this.tank[index]
  if not car.valid then return end
  this.car_wudi[#this.car_wudi+1]=car
  car.operable = false
  car.active = false
end
--这里可能要把无敌设置改为每35波一次
--上面的要检验有效性！
local function clean_invalid_car()
  get_car_number()
end

local function on_entity_damaged(event)

  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end



  if car_name[entity.name]~=true then return end
  local cause = event.cause
  if cause then
    if cause.valid then
      if (cause and cause.force == game.forces.player ) then
        if cause.name== 'character' then
        local player = cause.player
        local index = player.index
        local this=WPT.get()
        if this.tank[index]==entity then return end
      end
        entity.health=event.final_damage_amount+event.final_health
      end
    end
  end
end

local function car_pollute()
  local this=WPT.get()
  local ic = IC.get()

  for k, player in pairs(game.connected_players) do
    local index = player.index
    local unit_number=this.whos_tank[index]

    if unit_number then
      local entity = this.tank[index]
      local mian_surface = game.surfaces[this.active_surface_index]
      local car = ic.cars[unit_number]
     if car then
        local surface_index = car.surface
        local surface = game.surfaces[surface_index]
        local pollution = surface.get_total_pollution() *2
        mian_surface.pollute(entity.position, pollution)
        --game.pollution_statistics.on_flow('locomotive', pollution - total_interior_pollution)
        surface.clear_pollution()
     end

    end

  end
end


local function on_player_changed_position(event)

  local active_surface_index = WPT.get('active_surface_index')
  if not active_surface_index then
    return
  end
  local player = game.players[event.player_index]
  local index = player.index

  local this=WPT.get()
  if this.player_position[index] then
    player.teleport(this.player_position[index], game.surfaces[this.active_surface_index])
  end
  local wave_number = WD.get('wave_number')
  if wave_number>= 300 then return end

  local main_surface = game.surfaces[this.active_surface_index]

  if player.surface~=main_surface then return  end

  if this.tank[index] ==nil then return end

  local position = player.position
  local car = this.tank[index]
  if not car  then return end
  if not car.valid  then
    this.tank[index]=nil
    this.have_been_put_tank[index]=false
    this.whos_tank[index]=nil
    return end
    local pos_car =car.position

    local dist_x = math.abs(position.x)-math.abs(pos_car.x)
    local dist_y = math.abs(position.y)-math.abs(pos_car.y)
    local sum = math.abs(dist_x)+math.abs(dist_y)

    local max = 675
    local chazhi= max-sum
    if chazhi >= 25 then return end
    if chazhi % 10 <2 then
      player.print({'amap.far_car',chazhi})
    end
    if chazhi < 5 then
      player.print({'amap.far_car',chazhi})
    end
    if chazhi<0 then
      player.print({'amap.too_far_car'})
      --  player.teleport(surface.find_non_colliding_position('character', pos_car, 3, 0, 5), main_surface)
      player.teleport(main_surface.find_non_colliding_position('character', car.position, 20, 1, false) or {x=0,y=0}, game.surfaces[this.active_surface_index])

    end

  end

  local function on_player_respawned(event)
    local player = game.get_player(event.player_index)
    local this=WPT.get()
    local index = player.index
    local main_surface = game.surfaces[this.active_surface_index]


    if this.tank[index] and this.tank[index].valid then
      player.teleport(main_surface.find_non_colliding_position('character', this.tank[player.index].position, 20, 1, false) or {x=0,y=0}, main_surface)
      return
    end
    kill_base_biter()

  end
  local function daojishi()
    local this = WPT.get()
    if this.start_game~=3 then return end
    if this.reset_time<= 0 then
      game_over()
    end
    if this.reset_time % 600==0 then
      game.print({'amap.reset_time',this.reset_time/60})
    end
    this.reset_time=this.reset_time-60
  end


  Event.on_nth_tick(1200, choois_target)
  Event.on_nth_tick(1200, car_pollute)
  Event.on_nth_tick(900, clean_invalid_car)
  Event.on_nth_tick(60, daojishi)
  Event.add(defines.events.on_player_respawned, on_player_respawned)
  Event.add(defines.events.on_player_changed_position, on_player_changed_position)
  Event.add(defines.events.on_entity_damaged, on_entity_damaged)
  Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
  Event.add(defines.events.on_robot_mined_entity, on_player_mined_entity)
  Event.add(defines.events.on_entity_died, on_entity_died)
  Event.add(defines.events.on_built_entity, on_player_build_entity)
  Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
  Event.add(defines.events.on_player_joined_game, on_player_joined_game)
