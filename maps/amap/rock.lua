local WPT = require 'maps.amap.table'
local Event = require 'utils.event'
local Public = {}
local Alert = require 'utils.alert'
local WD = require 'maps.amap.modules.wave_defense.table'
local HealthBooster = require 'maps.amap.modules.biter_health_booster_v2'
local RPG = require 'maps.amap.modules.rpg.table'
--local HS = require 'maps.amap.highscore'
local Server = require 'utils.server'
------自动化工厂
local Factories = require 'maps.amap.production'--核心程序
local diff=require 'maps.amap.diff'
local round = math.round
local List = require 'maps.amap.production_list'--列表引用
local get_random_car =require "maps.amap.functions".get_random_car
local function protect(entity, operable)
  entity.minable = false
  entity.destructible = false
  entity.operable = operable
end
----
local urgrade_item = function(market)
  local this = WPT.get()
  local pirce_mine=this.urgrad_mine*4000+1000
  local pirce_wall=this.health*1000 + 10000
  local pirce_arty=this.arty*1000 +10000
  local biter_health=this.biter_health*700 + 700
  local spider_health=this.spider_health*1000 + 7000
  local pirce_biter_dam=this.biter_dam*700 +700
  local pirce_rock_dam=this.urgrad_rock_dam*5000 +10000
  local max_price = 50000
  if pirce_arty >= max_price then
    pirce_arty = max_price
  end
  if pirce_rock_dam >= max_price then
    pirce_rock_dam = max_price
  end

  if pirce_mine >= max_price then
    pirce_mine = max_price
  end


  if pirce_wall >= max_price then
    pirce_wall = max_price
  end


  if biter_health >= max_price then
    biter_health = max_price
  end
  if spider_health >= max_price then
    spider_health = max_price
  end
  if pirce_biter_dam >= max_price then
    pirce_biter_dam = max_price
  end
  local health_wall = {price = {{"coin", pirce_wall}}, offer = {type = 'nothing', effect_description = {'amap.buy_health_wall',this.health*0.1}}}
  local buy_car_health={price = {{"coin", spider_health}}, offer = {type = 'nothing', effect_description = {'amap.player_spider_health',this.spider_health*0.1}}}

  local arty_dam = {price = {{"coin", pirce_arty}}, offer = {type = 'nothing', effect_description = {'amap.buy_arty_dam',this.arty*0.1}}}

  local player_biter_health={price = {{"coin", biter_health}}, offer = {type = 'nothing', effect_description = {'amap.player_biter_health',this.biter_health*0.1}}}
  local player_biter_dam={price = {{"coin", pirce_biter_dam}}, offer = {type = 'nothing', effect_description = {'amap.player_biter_dam',this.biter_dam*0.1}}}



  local buy_urgrade_rock_dam = {price = {{"coin", pirce_rock_dam}}, offer = {type = 'nothing', effect_description = {'amap.buy_rock_dam',0.1*this.urgrad_rock_dam}}}
  local urgrade_mine={price = {{"coin", pirce_mine}}, offer = {type = 'nothing', effect_description = {'amap.urgrade_mine',this.urgrad_mine*200+400}}}

  local buy_cap={price = {{"coin", 50000}}, offer = {type = 'nothing', effect_description = {'amap.buy_cap'}}}
  market.add_market_item(health_wall)
  market.add_market_item(buy_car_health)
  market.add_market_item(arty_dam)
  market.add_market_item(player_biter_health)
  market.add_market_item(player_biter_dam)
  market.add_market_item(buy_urgrade_rock_dam)
  market.add_market_item(urgrade_mine)
  market.add_market_item(buy_cap)

end

local market_items = {

  {price = {{"coin", 5}}, offer = {type = 'give-item', item = "raw-fish", count = 1}},
  {price = {{"raw-fish", 1}}, offer = {type = 'give-item', item = 'coin', count = 5}},
  {price = {{"coin", 1000}}, offer = {type = 'give-item', item = 'car', count = 1}},
  {price = {{"coin", 8000}}, offer = {type = 'give-item', item = 'tank', count = 1}},
  {price = {{"coin", 60000}}, offer = {type = 'give-item', item = 'spidertron', count = 1}},
  {price = {{"coin", 500}}, offer = {type = 'give-item', item = 'spidertron-remote', count = 1}},
  {price = {{"coin", 25000}}, offer = {type = 'give-item', item = 'tank-cannon', count = 1}},
  {price = {{"coin", 128}}, offer = {type = 'give-item', item = 'loader', count = 1}},
  {price = {{"coin", 512}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}},
  {price = {{"coin", 4096}}, offer = {type = 'give-item', item = 'express-loader', count = 1}},
 {price = {{"coin", 15}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
  {price = {{"coin", 8}}, offer = {type = 'give-item', item = 'firearm-magazine', count = 1}},
   {price = {{"coin", 40}}, offer = {type = 'give-item', item = 'grenade', count = 1}},
{price = {{"coin", 60}}, offer = {type = 'give-item', item = 'slowdown-capsule', count = 1}},
{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'landfill', count = 1}},


}
if is_mod_loaded('Krastorio2') then
  market_items[#market_items+1]={price = {{"coin", 40000}}, offer = {type = 'give-item', item = 'kr-advanced-tank', count = 1}
}
end

function Public.ft(surface)
  local factory = "assembling-machine-2"
  for key = 1, 20, 1 do
    if List[key].kind == "furnace" then factory = "electric-furnace" else factory = "assembling-machine-2" end
    local position = {x = -16 + key * 3, y = -18}
    if (key>=11) then
      position = {x = -46+ key * 3, y = -12}
    end
    local e = surface.create_entity({name = factory, force = "player", position = position})
    e.active = false
    protect(e, false)
    e.rotatable = false
    Factories.register_train_assembler(e, key)
    if List[key].kind == "assembler" or List[key].kind == "fluid-assembler" then
      e.set_recipe(List[key].recipe_override or List[key].name)
      e.recipe_locked = true
      e.direction = defines.direction.south
    end
  end
end


function Public.market(surface)


  local this = WPT.get()
  local market = surface.create_entity{name = "market", position = {x=0, y=-5}, force=game.forces.player}
  this.shop=market
  market.last_user = nil
  if market ~= nil then
    market.destructible = false
    if market ~= nil then
      urgrade_item(market)
      for _, item in pairs(market_items) do
        market.add_market_item(item)
      end
    end
  end
end



local function on_rocket_launched()
  local this = WPT.get()
  --game.print({'amap.times',this.times})
  local rpg_t = RPG.get('rpg_t')
  --local money = 1000 + this.times*1000
  local money = 7000
  local point = 1
local map=diff.get()
  if map.rocket_diff then
money=money+this.times*1000
  end

  if money>=15000 then
    money =15000
  end
  if this.goal==1 and this.times==2 then
    this.goal=2
    game.print {'amap.goal_1'}
  end
  for k, player in pairs(game.connected_players) do
    rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+point
    player.insert{name='coin', count = money}
    player.print({'amap.reward',this.times,point,money}, {r = 0.22, g = 0.88, b = 0.22})

  end
  if not this.pass then
    local wave_number = WD.get('wave_number')
    local msg = {'amap.pass',wave_number}
    for k, player in pairs(game.connected_players) do
      Alert.alert_player(player, 25, msg)
    end
    Server.to_discord_embed(table.concat({'** we win the game ! Record is ', wave_number}))
    this.pass = true
  end
  this.times=this.times+1
end


local function Resist_calc(health)
  return round(1/health, 5)
end

local function on_market_item_purchased(event)
    local this = WPT.get()
    local market = event.market
    if market~=this.shop then return end
  local player = game.players[event.player_index]

  local offer_index = event.offer_index
  local offers = market.get_market_items()
  local bought_offer = offers[offer_index].offer


  if bought_offer.type ~= "nothing" then return end
  local health_boost =HealthBooster.get()
    local wave_number = WD.get('wave_number')

  if offer_index == 1 then

    local times = math.floor(wave_number/100)+this.cap
    if this.health >= times then
      player.print({'amap.cap_upgrad'})
      local pirce_wall=this.health*1000 + 10000
      if pirce_wall >= 50000 then
        pirce_wall = 50000
      end
      player.insert{name='coin',count = pirce_wall}
      return
    end
    this.health=this.health+1
    local health = this.health*0.1+1
    health_boost.player_build_health_boost=health
    health_boost.player_build_resist=Resist_calc(health)
    game.print({'amap.buy_wall_over',player.name,this.health*0.1+1})

  end

  if offer_index == 2 then
    local times = math.floor(wave_number/100)+this.cap
    if this.spider_health >= times then
      player.print({'amap.cap_upgrad'})
      local spider_health=this.spider_health*1000 + 7000
      if spider_health >= 50000 then
        spider_health = 50000
      end
      player.insert{name='coin',count = spider_health}
      return
    end
    this.spider_health=this.spider_health+1

    local health=this.spider_health*0.1+1
    health_boost.car_health_boost=health
    health_boost.car_resist=Resist_calc(health)
  --  spider_health(index,this.spider_health*0.1+1.1)
    game.print({'amap.buy_spider_health_over',player.name,this.spider_health*0.1+1})
  end

  if offer_index == 3 then

    this.arty=this.arty+1
    game.forces.player.set_ammo_damage_modifier("artillery-shell", this.arty*0.1)
    game.print({'amap.buy_arty_over',player.name,this.arty*0.1+1})
  end
  if offer_index == 4 then
    local times = math.floor(wave_number/50)+this.cap
  if times >= 100 then
      times = 100
    end
if this.biter_health >= times then
      player.print({'amap.cap_upgrad'})
      local pirce_biter_health=this.biter_health*700 + 700
      if pirce_biter_health >= 50000 then
        pirce_biter_health = 50000
      end
      player.insert{name='coin',count =pirce_biter_health}
      return
    end
    this.biter_health=this.biter_health+1
    local health = this.biter_health*0.1+1
    health_boost.player_biter_health_boost=health
    health_boost.player_biter_resist=Resist_calc(health)
    game.print({'amap.buy_player_biter_over',player.name,this.biter_health*0.1+1})
  end

  if offer_index == 5 then
    local times = math.floor(wave_number/100)+this.cap+1
    if times >= 100 then
      times = 100
    end
    if this.biter_dam >= times then
      player.print({'amap.cap_upgrad'})
      local pirce_biter_dam=this.biter_dam*700 + 700
      if pirce_biter_dam >= 50000 then
        pirce_biter_dam = 50000
      end
      player.insert{name='coin',count = pirce_biter_dam}
      return
    end
    this.biter_dam=this.biter_dam+1
    local damage_increase = this.biter_dam*0.1
    game.forces.player.set_ammo_damage_modifier("melee", damage_increase)
    game.forces.player.set_ammo_damage_modifier("biological", damage_increase)
    game.print({'amap.buy_biter_dam',player.name,this.biter_dam*0.1+1})
  end

  if offer_index == 6 then
    this.urgrad_rock_dam=this.urgrad_rock_dam+1
    local old_dam = game.forces.player.get_ammo_damage_modifier("rocket")
   game.forces.player.set_ammo_damage_modifier("rocket", old_dam+0.1)
    game.print({'amap.urgrad_rock_dam_over',player.name,this.urgrad_rock_dam*0.1})
  end


  if offer_index == 7 then
    this.urgrad_mine=this.urgrad_mine+1
    this.max_mine=400+this.urgrad_mine*200
    game.print({'amap.urgrad_mine_over',player.name,this.max_mine})
  end

  if offer_index == 8 then

this.cap=this.cap+1
    game.print({'amap.buy_cap_over',player.name,this.cap})
  end
  market.force.play_sound({path = 'utility/new_objective', volume_modifier = 0.75})
  market.clear_market_items()
  urgrade_item(market)
  for k, item in pairs(market_items) do
    market.add_market_item(item)
  end

  market.force.play_sound({path = 'utility/new_objective', volume_modifier = 0.75})
  market.clear_market_items()
  urgrade_item(market)
  for k, item in pairs(market_items) do
    market.add_market_item(item)
  end

end


local function get_car_number()
  local this=WPT.get()
  local car_number=0

  for k, player in pairs(game.connected_players) do
    if  this.tank[player.index] and this.tank[player.index].valid then
    car_number=car_number+1
  else
    this.tank[player.index]=nil
    this.whos_tank[player.index]=nil
    this.have_been_put_tank[player.index]=false
  end
  end
  return car_number
end

local function count_down()
    local this = WPT.get()
  if this.stop_time==0 then return end

  if this.stop_time % 36000 == 0 then
    game.print({'amap.wave_time',this.stop_time/3600})
  end

  this.stop_time=this.stop_time-60

  if this.stop_time==0 then
    game.print({'amap.over_stop'})
    local wave_defense_table = WD.get_table()
    wave_defense_table.game_lost = false
    if get_car_number()~=0 then
    wave_defense_table.target=get_random_car(true)
  end
  end


end
Event.on_nth_tick(60, count_down)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
Event.add(defines.events.on_market_item_purchased,on_market_item_purchased)
return Public
