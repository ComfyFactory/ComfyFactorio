require 'modules.rpg.main'
local Functions = require 'maps.amap.functions'
local IC = require 'maps.amap.ic.table'
local CS = require 'maps.amap.surface'
local Event = require 'utils.event'
local WD = require 'modules.wave_defense.table'
local Map = require 'modules.map_info'
local AntiGrief = require 'antigrief'
local Explosives = require 'modules.explosives'
local WPT = require 'maps.amap.table'
local Autostash = require 'modules.autostash'
local BuriedEnemies = require 'maps.amap.buried_enemies'
local RPG_Settings = require 'modules.rpg.table'
local RPG_Func = require 'modules.rpg.functions'
local Commands = require 'commands.misc'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Alert = require 'utils.alert'
local rock = require 'maps.amap.rock'
local RPG = require 'modules.rpg.table'
biter = {}
local h = 1
local k = 10
local last = 0
require 'modules.burden'
require "modules.spawners_contain_biters"
require 'modules.biters_yield_coins'
require 'maps.amap.sort'
local Public = {}
local floor = math.floor
local remove = table.remove

--加载地形
require 'maps.amap.caves'

require 'maps.amap.ic.main'
require 'modules.shotgun_buff'
require 'modules.no_deconstruction_of_neutral_entities'
require 'modules.spawners_contain_biters'
require 'modules.wave_defense.main'
require 'modules.charging_station'

local init_new_force = function()
    local new_force = game.forces.protectors
    local enemy = game.forces.enemy
    if not new_force then
        new_force = game.create_force('protectors')
    end
    new_force.set_friend('enemy', true)
    enemy.set_friend('protectors', true)
end

function Public.reward()
return(k)
end
function Public.reset_map()

local this = WPT.get()
local wave_defense_table = WD.get_table()

--创建一个地表
this.active_surface_index = CS.create_surface()

 Autostash.insert_into_furnace(true)
 Autostash.bottom_button(true)
 BuriedEnemies.reset()
 IC.reset()
 IC.allowed_surface('amap')
 game.reset_time_played()
 WPT.reset_table()
 
 --记得后面改为失去一半经验！并且修订技能！
 local rpg_t = RPG.get('rpg_t')
  for k, p in pairs(game.connected_players) do
	 local player = game.connected_players[k]
	rpg_t[player.index].xp = rpg_t[player.index].xp / 3
	rpg_t[player.index].level = 1
	rpg_t[player.index].strength = 10
	rpg_t[player.index].magicka = 10
	rpg_t[player.index].dexterity = 10
	rpg_t[player.index].vitality = 10
	rpg_t[player.index].mana_max = 0
	rpg_t[player.index].points_to_distribute = 0
 if rpg_t[player.index].xp > 5000 then 
 rpg_t[player.index].xp = 5000
 end
    end
	
    RPG_Settings.set_surface_name('amap')
    RPG_Settings.enable_health_and_mana_bars(true)
    RPG_Settings.enable_wave_defense(true)
    RPG_Settings.enable_mana(true)
    RPG_Settings.enable_flame_boots(true)
    RPG_Settings.enable_stone_path(true)
    RPG_Settings.enable_one_punch(true)
    RPG_Settings.enable_one_punch_globally(false)
    RPG_Settings.enable_auto_allocate(true)
    RPG_Settings.disable_cooldowns_on_spells()
	
	--初始化部队
	init_new_force()
	
	
	local surface = game.surfaces[this.active_surface_index]
    Explosives.set_surface_whitelist({[surface.name] = true})
	game.forces.player.set_spawn_position({0, 0}, surface)
	
	
	
	local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Commands.insert_all_items(player)
    end
	
	--生产火箭发射井
	rock.spawn(surface,{x=0,y=10})
	rock.market(surface)
	
	 WD.reset_wave_defense()
    wave_defense_table.surface_index = this.active_surface_index
	--记得修改目标！
    wave_defense_table.target = this.rock
    wave_defense_table.nest_building_density = 32
    wave_defense_table.game_lost = false
	--生成随机位置！
	local positions = {x = 200, y = 200}
	positions.x = math.random(-200,200)
	positions.y = math.random(-200,200)
	
	if positions.y < 75 and positions.y > -75 then
	
	if positions.y < 0 then
	positions.y = positions.y - 100
	else
	positions.y = positions.y + 100
	end
	end
	if positions.x < 75 and positions.x > -75 then
	if positions.x < 0 then
	positions.x = positions.x - 100
	else
	positions.x = positions.x + 100
	end
	end

    wave_defense_table.spawn_position = positions
	--game.print(positions)
    WD.alert_boss_wave(true)
    WD.clear_corpses(false)
    WD.remove_entities(true)
    WD.enable_threat_log(true)
    WD.set_disable_threat_below_zero(true)
	WD.set_biter_health_boost(2.5)
	WD.set().next_wave = game.tick + 7000* 15
	--初始化虫子科技
	biter.d=false
	biter.c=false
	biter.b=false
	biter.a=false
	
	Functions.disable_tech()
	game.forces.player.set_spawn_position({0, 0}, surface)
	
	Task.start_queue()
    Task.set_queue_speed(16)
	
	this.chunk_load_tick = game.tick + 1200
    this.game_lost = false
	last = 0
	k=0
	--setting()
end

local setting = function()
local map_gen_settings = {}
game.map_settings.enemy_evolution.destroy_factor = 0.001
		game.map_settings.enemy_evolution.pollution_factor = 0.000001
		game.map_settings.enemy_expansion.enabled = true
		game.map_settings.enemy_expansion.min_expansion_cooldown = 6000
		game.map_settings.enemy_expansion.max_expansion_cooldown = 24000
		game.map_settings.enemy_evolution.time_factor = 0.00006
		game.map_settings.enemy_expansion.max_expansion_distance = 20
		game.map_settings.enemy_expansion.settler_group_min_size = 20
		game.map_settings.enemy_expansion.settler_group_max_size = 50
end

local on_init = function()

 Public.reset_map()
 
 
 local T = Map.Pop_info()
    T.localised_category = 'amap'
    T.main_caption_color = {r = 150, g = 150, b = 0}
    T.sub_caption_color = {r = 0, g = 150, b = 0}
	
	
	
    Explosives.set_whitelist_entity('character')
    Explosives.set_whitelist_entity('spidertron')
    Explosives.set_whitelist_entity('car')
    Explosives.set_whitelist_entity('tank')
	--地图设置
	
	setting()
end
local is_player_valid = function()
    local players = game.connected_players
    for _, player in pairs(players) do
        if player.connected and not player.character or not player.character.valid then
            if not player.admin then
                local player_data = Functions.get_player_data(player)
                if player_data.died then
                    return
                end
                player.set_controller {type = defines.controllers.god}
                player.create_character()
            end
        end
    end
end


local has_the_game_ended = function()
    local game_reset_tick = WPT.get('game_reset_tick')
    if game_reset_tick then
        if game_reset_tick < 0 then
            return
        end

        local this = WPT.get()

        this.game_reset_tick = this.game_reset_tick - 30
        if this.game_reset_tick % 1800 == 0 then
            if this.game_reset_tick > 0 then
                local cause_msg
                if this.restart then
                    cause_msg = 'restart'
              
                end

                game.print(({'main.reset_in', cause_msg, this.game_reset_tick / 60}), {r = 0.22, g = 0.88, b = 0.22})
            end

            if this.soft_reset and this.game_reset_tick == 0 then
                this.game_reset_tick = nil
                Public.reset_map()
                return
            end
            
          
        end
    end
end

local chunk_load = function()
    local chunk_load_tick = WPT.get('chunk_load_tick')
    if chunk_load_tick then
        if chunk_load_tick < game.tick then
            WPT.get().chunk_load_tick = nil
            Task.set_queue_speed(2)
        end
    end
end
local biterbuff = function()
if h ~= 5 then 
h=h+0.2
WD.set_biter_health_boost(h)


game.print('虫子已获得增强，强度系数为:' .. h .. '.')
end
end
local rondom = function(player)
local rpg_t = RPG.get('rpg_t')
local q = math.random(0,8)
if q == 7 then 
player.print('你的数字为7，哦，很抱歉，什么都没有。')
elseif q == 6 then 
rpg_t[player.index].strength = rpg_t[player.index].strength + 15
player.print('你的数字为6，你获得了15点力量点奖励！')
elseif q == 5 then 
player.print('你的数字为5，你获得了15点魔法点奖励！')
rpg_t[player.index].magicka =rpg_t[player.index].magicka +15
elseif q == 4 then 
player.print('你的数字为4，你获得了15点敏捷点奖励！')
rpg_t[player.index].dexterity = rpg_t[player.index].dexterity+15
elseif q == 3 then 
player.print('你的数字为3，你获得了15点活力点奖励！')
rpg_t[player.index].vitality = rpg_t[player.index].vitality+15
elseif q == 2 then 
player.print('你的数字为2，你获得了10点技能点奖励！')
rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+10
elseif q == 1 then 
player.print('你的数字为1，你获得了2000金币奖励！')
player.insert{name='coin', count = '2000'}
elseif q == 0 then 
player.print('你的数字为0，哦，你真倒霉，你失去了1000金币！如果你连1K都没有，我就不拿了吧。')
player.remove_item{name='coin', count = '1000'}
else
player.print('?发生什么事了（你因为开小差没有参与转盘抽奖！）')
end
end
local timereward = function()
	local wave_number = WD.get('wave_number')
	if last < wave_number then 
	if wave_number % 25 == 0 then 
	game.print('是时候转动命运之轮了，看看你会获得什么吧！',{r = 0.22, g = 0.88, b = 0.22})
	--biterbuff()
  for k, p in pairs(game.connected_players) do
	 local player = game.connected_players[k]
rondom(player)
	k=k+1
 end
last = wave_number
	end

end
end



local biterup = function()
    local wave_number = WD.get('wave_number')
	if wave_number == 100 and biter.a == false then 
	WD.set_biter_health_boost(3)
	game.print('虫族护甲科技研究完成，获得50%的生命值提升！', {r = 0.22, g = 0.88, b = 0.22})
	biter.a = true
	end
	if wave_number == 250 and biter.b == false then
	local wave_defense_table = WD.get_table()
	local positions = {x = 500, y = 500}
	positions.x = math.random(-555,555)
	positions.y = math.random(-555,555)
	
	if positions.y < 350 and positions.y > -350 then
	
	if positions.y < 0 then
	positions.y = positions.y - 350
	else
	positions.y = positions.y + 350
	end
	end
	if positions.x < 350 and positions.x > -350 then
	if positions.x < 0 then
	positions.x = positions.x - 350
	else
	positions.x = positions.x + 350
	end
	end

    wave_defense_table.spawn_position = positions
	game.print('虫族经过讨论决定更换进攻地点！', {r = 0.22, g = 0.88, b = 0.22})
	biter.b=true 
	end 
	if wave_number == 400 and biter.c == false then
	
	game.map_settings.enemy_evolution.time_factor = 0.006
	game.print('虫族地热循环技术研究成功，时间进化因子提升100%！', {r = 0.22, g = 0.88, b = 0.22})
	biter.c=true
	end
	
	if wave_number == 550 and biter.d == false then
	
	WD.set_biter_health_boost(4)
	game.print('虫族启用新型护甲进行战斗', {r = 0.22, g = 0.88, b = 0.22})
	biter.d=true 
	end
end
--时钟任务
local on_tick = function()
    local tick = game.tick

    if tick % 40 == 0 then
timereward()
        is_player_valid()
       has_the_game_ended()
        chunk_load()

	--	biterup()
    end

end

function on_research_finished(Event)

 local rpg_t = RPG.get('rpg_t')
  for k, p in pairs(game.connected_players) do
	 local player = game.connected_players[k]

	rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+3
    player.insert{name='coin', count = '100'}
	game.print('科技研发完成，所有玩家奖励3技能点，100金币。', {r = 0.22, g = 0.88, b = 0.22})
	k=k+1
 end
    end


Event.on_init(on_init)
Event.on_nth_tick(10, on_tick)
Event.add(defines.events.on_research_finished, on_research_finished)
return Public