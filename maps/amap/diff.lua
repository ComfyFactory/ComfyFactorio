local Global = require 'utils.global'

local map = {}
local Public = {}

Global.register(
    map,
    function(tbl)
        map = tbl
    end
)


local WD = require 'maps.amap.modules.wave_defense.table'
local WPT = require 'maps.amap.table'
local Difficulty = require 'modules.difficulty_vote_by_amount'
--local atry_talbe = require "maps.amap.enemy_arty"

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


local goal = function()
local this = WPT.get()
local wave_number = WD.get('wave_number')
local goal=this.goal
if goal == 2 and wave_number >=2000 then
  this.goal=3
  game.print({'amap.goal_2'})
  game.print({'amap.off_final_wave'})
  game.print({'amap.off_rocket_diff'})
end
if goal==3 and wave_number>=2605 and map.final_wave and  map.rocket_diff then
  this.goal=5
  map.final_wave=false
  map.final_wave_record[map.world]=true
  game.map_settings.enemy_expansion.settler_group_min_size =5
  game.map_settings.enemy_expansion.max_expansion_cooldown=216000
  game.map_settings.enemy_expansion.min_expansion_cooldown=14400
  game.print({'amap.finsh_world'})
end

end

local final_wave = function()
  local wave_defense_table = WD.get_table()
game.map_settings.enemy_expansion.settler_group_min_size = 50
game.map_settings.enemy_expansion.min_expansion_cooldown=3600
game.map_settings.enemy_expansion.max_expansion_cooldown=game.map_settings.enemy_expansion.min_expansion_cooldown
wave_defense_table.wave_interval = 1200
end

local set_diff = function()

  local game_lost = WPT.get('game_lost')
  if game_lost then
    return
  end
  local this = WPT.get()
  local wave_defense_table = WD.get_table()
  local wave_number = WD.get('wave_number')
  local diff_k=1
  local player_count = calc_players()

  local diff= Difficulty.get()
  if diff.difficulty_vote_index == 1 then
    diff_k=1
  end
  if diff.difficulty_vote_index == 2 then
    diff_k=1.2
  end
  if diff.difficulty_vote_index == 3 then
    diff_k=1.5
  end
  diff_k=diff_k+map.diff-1
  if wave_number>=2000 and map.rocket_diff then
    diff_k=diff_k+this.times*0.015
  end
goal()
    wave_defense_table.max_active_biters = 768 + player_count * 180*diff_k

    if wave_defense_table.max_active_biters >= 4000*diff_k then
      wave_defense_table.max_active_biters = 4000*diff_k
    end

    local max_threat = 1 + player_count * 0.1*diff_k
    if max_threat >= 4*diff_k then
      max_threat = 4*diff_k
    end

    max_threat = max_threat + wave_number * 0.0013*diff_k

    WD.set_biter_health_boost(wave_number * 0.002*diff_k+1*diff_k)
    wave_defense_table.threat_gain_multiplier =  max_threat

    wave_defense_table.wave_interval = 4200/diff_k - player_count * 50*diff_k
    if wave_defense_table.wave_interval < 1800/diff_k or wave_defense_table.threat <= 0 then
      wave_defense_table.wave_interval = 1800/diff_k
    end

    local enemy = game.forces.enemy
    if  enemy.evolution_factor >= 0.5 and this.max_flame == 28 then
      this.max_flame=24
    end
    if  enemy.evolution_factor >= 0.9 and this.max_flame == 24 then
      this.max_flame=18
    end
    local damage_increase = 0
    damage_increase = wave_number * 0.001*diff_k*1.3
    --game.forces.player.get_ammo_damage_modifier("beam")
    game.forces.enemy.set_ammo_damage_modifier("artillery-shell", damage_increase)
    game.forces.enemy.set_ammo_damage_modifier("rocket", damage_increase)
    game.forces.enemy.set_ammo_damage_modifier("melee", damage_increase)
    game.forces.enemy.set_ammo_damage_modifier("biological", damage_increase)
    if  map.final_wave and wave_number>2000 then final_wave() end
  end

function Public.reset_table()
  map.sum=0
  map.win=0
  map.gg=0

  map.diff=1

  map.world=1
  map.max_world=1
  map.world_number=4


  map.record_number=0
  map.record={}
  map.map_record={}

  map.final_wave=true
  map.final_wave_record={
    [1]=false,
    [2]=false,
    [3]=false,
    [4]=false,
    [5]=false,
    [6]=false,
  }

  map.rocket_diff=true
end


commands.add_command(
    'off_final_wave',
    'off_final_wave,if you affid biter',
    function()
      local player = game.player
      if player then
          if player ~= nil then
              p = player.print
              if not player.admin then
                  p({'amap.no_amdin'})
                  return
              end
               map.final_wave=false
               game.map_settings.enemy_expansion.settler_group_min_size =5
               game.map_settings.enemy_expansion.max_expansion_cooldown=104000
              p({'amap.off_final_wave_over'})
            end
          end
    end
)


commands.add_command(
    'off_rocket_diff',
    'off_rocket_diff,to adoive the game too hard',
    function()
      local player = game.player
      if player then
          if player ~= nil then
              p = player.print
              if not player.admin then
                  p({'amap.no_amdin'})
                  return
              end
               map.rocket_diff=false
              p({'amap.off_rocket_diff_over'})
            end
          end
    end
)

  local on_init = function()
      Public.reset_table()
  end

  function Public.get(key)
      if key then
          return map[key]
      else
          return map
      end
  end

    local Event = require 'utils.event'
    Event.on_init(on_init)
    Event.on_nth_tick(600, set_diff)
  return Public
