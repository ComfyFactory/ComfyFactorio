local Global = require 'utils.global'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Loot = require'maps.amap.loot'
local Alert = require 'utils.alert'
local rpgtable = require 'modules.rpg.table'

local this = {
 
}
local Public = {}

Global.register(
this,
function(tbl)
  this = tbl
end
)




--一次性代码
local function rich_son(player)
    player.insert({name = 'coin', count = 2000})
    player.print({'tianfu.rich_son_over'})
    return true
end

local function shit_luck(player)
    local luck = math.floor(math.random(1,150))
    player.print({'amap.lucknb',luck})
    local magic = luck*5+100
    Loot.cool(player.surface, player.surface.find_non_colliding_position("steel-chest", player.position, 20, 1, true) or player.position, 'steel-chest', magic)
    
    local luck = math.floor(math.random(1,150))
    player.print({'amap.lucknb',luck})
    local magic = luck*5+100
    Loot.cool(player.surface, player.surface.find_non_colliding_position("steel-chest", player.position, 20, 1, true) or player.position, 'steel-chest', magic)
    
    local msg = {'amap.whatopen'}
    Alert.alert_player(player, 5, msg)
    player.print({'tianfu.shit_luck_over'})
    return true
end

--周期性代码
local function boom_player(player)
    if check_tick(player,'boom_player') then 
        local count = player.surface.count_entities_filtered{position = player.position, radius = 100, force = "enemy"}
        if count >0 then 
        local  e =  player.surface.create_entity(
            {
              name ='grenade' ,
              position = player.position,
              force = 'player',
              source = player.position,
              target = player.position,
              speed = 1,
              player=player
            }
        )
        
        player.print({'tianfu.boom_player_over'})
    end
    end
    return true
end


local function small_buss(player)
    if check_tick(player,'small_buss') then 
        local coin = -30+math.floor(math.random(1,90))
        if coin>=0 then 
            
          player.insert({name = 'coin', count = coin})
          player.print({'tianfu.small_buss_win',coin})
        else
          player.remove_item{name='coin', count = coin*-1}
          player.print({'tianfu.small_buss_lose',coin*-1})
        end


    end
    
    return true
end



local function fish(player)
    if check_tick(player,'fish') then 
    local count = math.random(1,4)
    player.insert({name = 'raw-fish', count = count})
    player.print({'tianfu.fish_over',count})
    end
    return true
end

local function zrsc(player)
    if check_tick(player,'zrsc') then 
    local rpg_t = rpgtable.get('rpg_t')
    rpg_t[player.index].vitality = rpg_t[player.index].vitality +1
    player.print({'tianfu.zrsc_over'})
    end
    return true
end

local function tsxf(player)
    local rpg_t = rpgtable.get('rpg_t')
    rpg_t[player.index].xp = rpg_t[player.index].xp +500
    return true
end

local function wolf(player)
    if check_tick(player,'wolf') then 

    local max=player.character_health_bonus+player.character.prototype.max_health
    local now=player.character.health

    if max ~= now then 
        player.character.health=player.character.health+(max-now)*0.1
    end
    end
    return true
end

local function dutu(player)
    if check_tick(player,'dutu') then 

        local something = player.get_inventory(defines.inventory.chest)
        local qian=1500
        local ok= false
        for k, v in pairs(something.get_contents()) do
            if k=='coin' and v >= qian then
             ok = true
            end
        end

        if ok and math.random(1,6)==1 then 
            player.remove_item{name='coin', count = qian}

            local luck = math.floor(math.random(1,150))
            player.print({'amap.lucknb',luck})
            local magic = luck*5+100
            Loot.cool(player.surface, player.surface.find_non_colliding_position("steel-chest", player.position, 20, 1, true) or player.position, 'steel-chest', magic)
            
            local msg = {'amap.whatopen'}
            Alert.alert_player(player, 5, msg)
            player.print({'tianfu.dutu_over'})
        end
        
   
    end
    return true
end

local function chishang(player)
    for l, player1 in pairs(game.connected_players) do
        player1.insert({name = 'coin', count = 1000})
        player1.print({'tianfu.chishang_over',player.name})
    end
    player.remove_item{name='coin', count = 1000}

    return true
end


local function bulider(player)
    local rpg_t = rpgtable.get('rpg_t')
    rpg_t[player.index].dexterity = rpg_t[player.index].dexterity +25
    return true
end



local function onlytishu(player)
    local rpg_t = rpgtable.get('rpg_t')
    rpg_t[player.index].vitality = rpg_t[player.index].vitality +40
    rpg_t[player.index].strength = rpg_t[player.index].strength +40
    rpg_t[player.index].dexterity = rpg_t[player.index].dexterity +40

    this.tishu[player.index]=true
    return true
end


local function fali(player)
    if check_tick(player,'fali') then 
    local rpg_t = rpgtable.get('rpg_t')
    for l, player in pairs(game.connected_players) do

        if rpg_t[player.index].mana  ~= rpg_t[player.index].mana_max then 
        rpg_t[player.index].mana = rpg_t[player.index].mana +30
        end
        if rpg_t[player.index].mana  > rpg_t[player.index].mana_max then 
            rpg_t[player.index].mana  =rpg_t[player.index].mana_max
        end

    end
    game.print({'tianfu.fali_over'})
    end
    return true
end
local function rs(player)
    local rpg_t = rpgtable.get('rpg_t')
    rpg_t[player.index].vitality = rpg_t[player.index].vitality +30
    player.print({'tianfu.rs_over'})
    return true
end

local function quanneng(player)
    local rpg_t = rpgtable.get('rpg_t')
    rpg_t[player.index].vitality = rpg_t[player.index].vitality +10
    rpg_t[player.index].magicka = rpg_t[player.index].magicka +10
    rpg_t[player.index].strength = rpg_t[player.index].strength +10
    rpg_t[player.index].dexterity = rpg_t[player.index].dexterity +10
    return true
end



local function high_debt(player)
    player.insert({name = 'coin', count = 10000})
    this.qiankuang[player.index]=20000
    return true
end

local kill_forces =
Token.register(
function(data)
  for _,v in pairs(data) do
  if  v and  v.valid then
    v.destroy()
  end
end
end
)


local lowdowm =
Token.register(
function(player)
    player.character_running_speed_modifier=player.character_running_speed_modifier-1
end
)

local kill =
Token.register(
function(v)
  if  v and  v.valid then
    v.destroy()
  end
end
)

local xiuxing_k =
Token.register(
function(player)
    local rpg_t = rpgtable.get('rpg_t')
    rpg_t[player.index].xp = rpg_t[player.index].xp+2000
    player.print({'tianfu.xiuxing_over'})
    
end
)


local function zhs(player)
    if check_tick(player,'zhs') then 
        local forces={}
        for i = 1, 3 do
            local  e =  player.surface.create_entity(
                {
                  name ='small-biter' ,
                  position = player.surface.find_non_colliding_position("small-biter", player.position, 20, 1, true) ,
                  force = 'player',
                }
            )
            rendering.draw_text {
                text = '~' .. player.name .. "'s pet~",
                surface = player.surface,
                target = e,
                target_offset = {0, -2.6},
                color = {
                    r = player.color.r * 0.6 + 0.25,
                    g = player.color.g * 0.6 + 0.25,
                    b = player.color.b * 0.6 + 0.25,
                    a = 1
                },
                scale = 1.05,
                font = 'default-large-semibold',
                alignment = 'center',
                scale_with_zoom = false
            }
            forces[#forces+1]=e
        end
 
        for i = 1, 2 do
             e =  player.surface.create_entity(
                {
                  name ='small-spitter' ,
                  position = player.surface.find_non_colliding_position("small-spitter", player.position, 20, 1, true) ,
                  force = 'player',
                }
            )
            rendering.draw_text {
                text = '~' .. player.name .. "'s pet~",
                surface = player.surface,
                target = e,
                target_offset = {0, -2.6},
                color = {
                    r = player.color.r * 0.6 + 0.25,
                    g = player.color.g * 0.6 + 0.25,
                    b = player.color.b * 0.6 + 0.25,
                    a = 1
                },
                scale = 1.05,
                font = 'default-large-semibold',
                alignment = 'center',
                scale_with_zoom = false
            }
            forces[#forces+1]=e
        end
        player.print({'tianfu.zhs_over'})
        
        Task.set_timeout_in_ticks(60*30, kill_forces, forces)
end
    return true
end



local function xiuxing(player)
    Task.set_timeout_in_ticks(60*60*60*2, xiuxing_k, player)
end
local function biter(player)

    local  e =  player.surface.create_entity(
        {
          name ='biter-spawner' ,
          position = player.surface.find_non_colliding_position("biter-spawner", player.position, 20, 1, true) ,
          force = 'player',
        }
    )

    rendering.draw_text {
        text = '~' .. player.name .. "'s pet~",
        surface = player.surface,
        target = e,
        target_offset = {0, -2.6},
        color = {
            r = player.color.r * 0.6 + 0.25,
            g = player.color.g * 0.6 + 0.25,
            b = player.color.b * 0.6 + 0.25,
            a = 1
        },
        scale = 1.05,
        font = 'default-large-semibold',
        alignment = 'center',
        scale_with_zoom = false
    }
    player.print({'tianfu.biter_over'})
    
    return true
end

local un_wudi =
Token.register(
function(player)
    if player and player.character.valid then 
        player.character.destructible=true
    end
end
)

local biter_name={
    'behemoth-biter',
    'behemoth-spitter',
    'big-biter',
    'big-spitter',
    'medium-biter',
    'medium-spitter',
    'small-biter',
    'small-spitter'
}

local function relife(player)
    if check_tick(player,'relife') then 
    
        player.character.destructible=false
        player.character.health=100
        Task.set_timeout_in_ticks(60*3, un_wudi, player)

        local entities = player.surface.find_entities_filtered{position=player.position, radius = 25 , name =biter_name,force = game.forces.enemy}

        if #entities ~= 0 then
          for k,v in pairs(entities) do
            v.die()
          end
        end

        player.print({'tianfu.relife_over'})
    end
    
    return true
end



local function shiyou(player)

    if check_tick(player,'shiyou') then 
        player.insert({name = 'crude-oil-barrel', count = 4})
        local count = player.surface.count_entities_filtered{position = player.position, radius = 30,name='pumpjack', force = game.forces.player}

        if count >0 then 
            player.insert({name = 'coin', count = count*8})
        end
        player.print({'tianfu.shiyou_over',count})
    end
    return true
end
local function tank(player)
    player.insert({name = 'tank', count = 1})
    
    player.print({'tianfu.tank_over'})
end



local function jingong(player)
    if check_tick(player,'jingong') then 
        player.insert({name = 'destroyer-capsule', count = 1})
        player.print({'tianfu.jingong_over'})
    end
 
    return true
end
local function junhuo(player)
    if check_tick(player,'junhuo') then 
        player.insert({name = 'firearm-magazine', count = 10})
        player.print({'tianfu.junhuo_over'})
        
    end
    return true
end
local function genben(player)
    if check_tick(player,'genben') then 
        player.insert({name = ' defender-capsule', count = 1})
        
        player.print({'tianfu.genben_over'})
    end
    return true
end

local turret_name={
'gun-turret','laser-turret','flamethrower-turret','artillery-turret'

}

local function wxs(player)
    if check_tick(player,'wxs') then 
        local position=player.position
        local entities = player.surface.find_entities_filtered {name = turret_name,force = player.force, area = {{position.x - 16, position.y - 16}, {position.x + 16, position.y + 16}}}
        local count = 0
        for i = 1, #entities do
          local e = entities[i]
          if e.prototype.max_health ~= e.health then
            e.health= e.health+e.prototype.max_health*0.1
          end
        end
        player.print({'tianfu.wxs_over'})
        
    end
    return true
end


local function hd(player)
    if check_tick(player,'hd') then 
        local something = player.get_inventory(defines.inventory.character_guns)
        for k, v in pairs(something.get_contents()) do
            player.remove_item{name=k,count=v}
        end

        local rpg_t = rpgtable.get('rpg_t')
        rpg_t[player.index].vitality =10

        local all = 0
        local k =0
        for l, playerl in pairs(game.connected_players) do
            if playerl.name ~= player.name then 
                local something = player.get_inventory(defines.inventory.chest)
                k=0
                for k, v in pairs(something.get_contents()) do
                    if k=='coin'  then
                        if v> k then k= v end
                    end
                end
                all=all+k
            end
         end
         local count = math.floor(all*0.05)
         if count > 1 then 
         player.insert({name = 'coin', count = count})
         player.print({'tianfu.hd_over'})
         end
         
    end
    return true
end

local function zdfs(player)
    if check_tick(player,'zdfs') then 
        local position=player.position
        local entities = player.surface.find_entities_filtered{position = position, radius = 36, force = game.forces.enemy}
        if #entities ~= 0 then

            local something = player.get_inventory(defines.inventory.chest)
            local count=1
            local ok = false
            for k, v in pairs(something.get_contents()) do
                if k=='explosive-rocket' and v >= count then
                    ok =true
                end
            end
            if ok then 
                local  e =  player.surface.create_entity(
                    {
                      name ='explosive-rocket' ,
                      position=player.position,
                      force = 'player',
                      source = player.position,
                      target = entities[math.random(1,#entities)],
                      speed = 1,
                    }
                )
                player.remove_item{name='explosive-rocket', count = 1}
            end
        end
    end
    return true
end


local time_skills={
    ['boom_player']={name=boom_player,time=600},
    ['small_buss']={name=small_buss,time=60*30},
    ['zrsc']={name=zrsc,time=60*10*5},
    ['zhs']={name=zhs,time=60*30},
    ['wolf']={name=wolf,time=60*10},
    ['dutu']={name=dutu,time=60*10*6},
    ['wxs']={name=wxs,time=60*30},
    ['junhuo']={name=junhuo,time=60*30},
    ['genben']={name=genben,time=60*40},
    ['fish']={name=fish,time=60*60},
    ['zdfs']={name=zdfs,time=60*10},
    ['shiyou']={name=shiyou,time=60*30},
    ['jingong']={name=jingong,time=60*60*5},
    ['hd']={name=hd,time=60*60*10},
    ['fali']={name=fali,time=60*30},
   
}
local once_skills={
    ['rich_son']={name=rich_son},
    ['high_debt']={name=high_debt},
    ['shit_luck']={name=shit_luck},
    ['rs']={name=rs},
    ['tsxf']={name=tsxf},
    ['biter']={name=biter},
    ['tank']={name=tank},
    ['bulider']={name=bulider},
    ['chishang']={name=chishang},
    ['quanneng']={name=quanneng},
    ['onlytishu']={name=onlytishu},
    ['xiuxing']={name=xiuxing}
}
local trigger_skills={
    ['relife']={name=relife,time=60*60*60},
    ['kuangong']={name=kuangong},
    ['yhw']={name=yhw,time=60*40},
    ['ruchong']={name=ruchong,time=60*60*5},
    ['taobing']={name=taobing},
    ['xueshu']={name=xueshu},
}

function check_tick(player,skill)
    --game.print('检查技能冷却')
     if not this.tick_skill[player.name..skill] then
         this.tick_skill[player.name..skill]=0
     end
    -- game.print('技能名'..skill)
     local nap
     if not time_skills[skill] then 
         nap=trigger_skills[skill].time
     --   game.print('扳机天赋')
     else
         
         nap=time_skills[skill].time
    --     game.print('周期天赋')
     end
    --game.print('要求间隔为'..nap)
 --
  if this.tick_skill[player.name..skill]==0 then 
     this.tick_skill[player.name..skill]=game.tick
     return true 
 
 end
 
 
 
     if game.tick-this.tick_skill[player.name..skill]>nap then 
         this.tick_skill[player.name..skill]=game.tick
 
         return true
     else
         return false
     end
 end


function Public.reset_table()
    this.all_skill={}
    this.tick_skill={}
    this.choise_skill={}
    this.qiankuang={}
    this.tishu={}

    for _, v in pairs (time_skills) do
    this.all_skill[#this.all_skill+1]=_
    this[_]={}
    end
    for _, v in pairs (once_skills) do
    this.all_skill[#this.all_skill+1]=_
    end
    for _, v in pairs (trigger_skills) do
        this.all_skill[#this.all_skill+1]=_
        this[_]={}
    end
    
end

local on_init = function()
    Public.reset_table()
  end

local function choise_skill(player)
    local frame =
        player.gui.screen.add {
        type = 'frame',
        caption = {'tianfu.choise_skill'},
        name = '选择你的天赋',
        direction = 'vertical'
    }
    frame.location = {x = 850, y = 400}
    for i = 1,3, 1 do
        local  name=this.all_skill[math.random(1,#this.all_skill)]
        local b = frame.add(
            {
                type = 'button', 
                name = name, 
                caption = {'tianfu.'..name}
    }
    )
        b.style.font_color = {r = 0.00, g = 0.25, b = 0.00}
        b.style.font = 'heading-2'
        b.style.minimal_width = 160
        b.tooltip = {'tianfu.'..name..'_tip'}
    end
    local b = frame.add({type = 'label', caption = 'PS.彩名玩家可以选2个'})
    b.style.font_color = {r = 0.66, g = 0.0, b = 0.66}
    b.style.font = 'heading-3'
    b.style.minimal_width = 96
end


function Public.get_new_tianfu(player)
    choise_skill(player)
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]

    if not this.choise_skill[player.name] then
        choise_skill(player)
    end
    this.choise_skill[player.name]=true
end

function Public.get(key)
  if key then
    return this[key]
  else
    return this
  end
end

function Public.set(key, value)
  if key and (value or value == false) then
    this[key] = value
    return this[key]
  elseif key then
    return this[key]
  else
    return this
  end
end




local function on_gui_click(event)
    if not event then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    if event.element.type ~= 'button' then
        return
    end
    if event.element.parent.name ~= '选择你的天赋' then
        return
    end
    local player = game.players[event.element.player_index]
    game.print({'tianfu.choise_skill_msg', player.name, {'tianfu.'..event.element.name}})
    this.choise_skill[player.name]=true
    if  not once_skills[event.element.name] then 
        this[event.element.name][#this[event.element.name]+1]=player.name
    else
        once_skills[event.element.name].name(player)
    end
    event.element.parent.destroy()
end







local function on_tick()

    for _, v in pairs (time_skills) do
       --game.print('检查技能名'.._)
        for name ,k in pairs(this[_]) do 
         --  game.print('学习改技能的玩家'..k)
            for l, player in pairs(game.connected_players) do
               if player.name == k then 
           --     game.print('释放技能'..player.name)
                time_skills[_].name(player)
             --   game.print('释放技能结束'..player.name)
               end
            end
        end
    end

    if game.tick % 1800 == 0 then 
    --欠款还债
    for l, player in pairs(game.connected_players) do
        for _,k in pairs(this.tishu) do
            local rpg_t = rpgtable.get('rpg_t')
            if player.index==_ then 
                rpg_t[player.index].magicka = 10
            end
        end

        for _,k in pairs(this.qiankuang) do 
        if player.index==_ then 
            local something = player.get_inventory(defines.inventory.chest)
            local qian=30
            for k, v in pairs(something.get_contents()) do
                if k=='coin' and v >= qian then
                    qian=30
                else
                    qian=v
                end
            end
            player.remove_item{name='coin', count = qian}
            this.qiankuang[player.index]=this.qiankuang[player.index]-qian
            player.print({'tianfu.high_debt_lose',qian,this.qiankuang[player.index]})
        end
        end
        end

       

    end

    for k, player in pairs(game.connected_players) do
        if not this.choise_skill[player.name] then
            choise_skill(player)
        end
        this.choise_skill[player.name]=true
 end


end



--扳机类代码
local function have_learn(player,skill)

    for name ,k in pairs(this[skill]) do 
         if player.name == k then 
            return true
         end
    end

    return false
end

local function kuangong(player)

    local name={
        'copper-plate', 'iron-plate','iron-plate'
    }
    player.insert({name = 'coin', count = 2})
    player.insert({name = name[math.random(1,3)], count = math.random(4,10)})
end



local function xueshu(player)
    local rpg_t = rpgtable.get('rpg_t')
    local coin = math.random(1,20)
    local xp =math.random(1,10)
    rpg_t[player.index].xp = rpg_t[player.index].xp+xp
    player.insert{name='coin', count = coin}
    player.print({'tianfu.xueshu_over',xp,coin})
end

local function taobing(player)
    player.character_running_speed_modifier=player.character_running_speed_modifier+1
    player.print({'tianfu.taobing_over'})
    Task.set_timeout_in_ticks(60*3, lowdowm, player)
end

local function ruchong(player)
    if check_tick(player,'ruchong') then 
        local  e =  player.surface.create_entity(
            {
              name ='behemoth-worm-turret' ,
              position=player.position,
              force = 'player',
            }
        )
        player.print({'tianfu.ruchong_over'})
        Task.set_timeout_in_ticks(60*60*5, kill, e)
    end
end


local function yhw(player,target)
    if check_tick(player,'yhw') then 
        local  e =  player.surface.create_entity(
            {
              name ='distractor-capsule' ,
              position=player.position,
              force = 'player',
              source = player.position,
              target = target,
              speed = 0.9,
              player=player
            }
        )
        player.print({'tianfu.yhw_over'})
    end
end



local function on_pre_player_died (event)
    local player = game.players[event.player_index]
    if  have_learn(player,'relife') then
        relife(player)
    end
end

local function on_player_mined_entity (event)
    local player = game.players[event.player_index]

    local entity = event.entity


    if not entity.valid then return end
   
    if entity.type ~= "simple-entity"  then return end
    if  have_learn(player,'kuangong') then
        kuangong(player)
    end
end

local function on_player_used_capsule (event)
    local player = game.players[event.player_index]
    local item=event.item
    if  have_learn(player,'yhw') and item.name=='distractor-capsule' then
        local position=event.position
        yhw(player,position)
    end

    if  have_learn(player,'hd') and item.name~='raw-fish' then
       player.remove_item{name=item.name,count=999999999}
    end
end


local function on_player_died (event)
    local player = game.players[event.player_index]
    local cause = event.cause
    if cause then
      if cause.valid then
        if cause.force==game.forces.enemy and have_learn(player,'ruchong') then
            ruchong(player)
        end
      end
    end

    for l, player1 in pairs(game.connected_players) do
      if  have_learn(player1,'taobing') then
         taobing(player1)
    end
    end



end

local function on_player_gun_inventory_changed (event)
    local player = game.players[event.player_index]
    if  have_learn(player,'hd') then
        local something = player.get_inventory(defines.inventory.character_guns)
        for k, v in pairs(something.get_contents()) do
            player.remove_item{name=k,count=v}
        end
   
     end
end

local function on_research_finished (event)
    for k, player in pairs(game.connected_players) do
        if  have_learn(player,'xueshu') then
            xueshu(player)
        end
      end
end

Event.on_init(on_init)
Event.on_nth_tick(600, on_tick)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_pre_player_died  , on_pre_player_died  )
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_gun_inventory_changed , on_player_gun_inventory_changed )
Event.add(defines.events.on_player_died , on_player_died )
return Public
