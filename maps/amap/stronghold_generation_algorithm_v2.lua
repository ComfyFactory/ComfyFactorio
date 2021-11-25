local WPT = require 'maps.amap.table'
local Public = {}
local player_build = {
  'steam-turbine',
  'assembling-machine-1',
  'assembling-machine-2',
  'assembling-machine-3',
  'oil-refinery',
  'chemical-plant',
  'car',
  'spidertron',
  'tank',
  'character',
  'electric-mining-drill',
  'laser-turret',
  'steam-engine',
  'roboport',
  'flamethrower-turret'
}

local rail = {
  "straight-rail",
  "curved-rail"
}
-- 计算堡垒位置是否有冲突
-- return: true/false

local PI = 3.14157
local pi_12=0.261
local is_sh_conflict = function(sh_pos,surface)

  local ok=true
  local juli = 100
  local position=sh_pos

  local entities = surface.find_entities_filtered{position = position, radius = juli, name = player_build , force = game.forces.player}
  if #entities~=0 then
    ok=false
return ok
  end

  local rails = surface.find_entities_filtered{position = position, radius = juli, name = rail , force = game.forces.player}
  if #rails~=0 then
    ok=false
return ok
  end


  local area = {left_top = {position.x-48, position.y-48}, right_bottom = {position.x+48, position.y+48}}
  local roboports=surface.find_entities_filtered({type = {"roboport"}, area = area,force=game.forces.enemy})

  if #roboports~=0 then

    for k,v in pairs(roboports) do
      if not v.destructible then
        ok=false
        return ok
      end
    end

  end


    return ok
end


-- 寻找可能生成堡垒的位置
-- params:
-- car_pos - 靶车位置
-- sh_dis - 堡垒间最小距离，同时也是搜索圆增长的步长（因为 x 轴上两个堡垒至少间隔这个距离，故半径增长不能少于此)
-- return: 堡垒位置

-- 1.读取上次的角度
-- 2.计算这次的角度
-- 3.确定角度后移位置
-- 4.存储角度

function Public.find_available_stronghold_position(car_pos, sh_dis,surface)
    local found = false
    -- 堡垒搜索圆半径
    local sh_radius = sh_dis
    -- 堡垒角度
    local this=WPT.get()
    local sh_theta =this.theta_times*pi_12
  --  local sh_theta = 0

  local sh_pos_x = car_pos.x + sh_radius * math.cos(sh_theta)
  local sh_pos_y = car_pos.y + sh_radius * math.sin(sh_theta)
  local sh_pos = {x=sh_pos_x, y=sh_pos_y}

  local cos_theta = 1 - (sh_dis*sh_dis/(2*sh_radius*sh_radius))
  local theta = math.acos(cos_theta)
    sh_theta = sh_theta + theta
    if sh_theta >= 2*PI then
        sh_theta = sh_theta-2*PI

    end
  --计算后的角度
    while not found do
        -- 计算堡垒位置
--game.print("正在尝试的位置： [gps=".. sh_pos_x .. "," .. sh_pos_y .."," .. surface.name.. "]" )
        if is_sh_conflict(sh_pos,surface) then
         this.theta_times=this.theta_times+1
         if this.theta_times >= 25 then
           this.theta_times=0
      --      game.print("找到了，共计次数为" .. time .."")
         end
            return sh_pos
        else

          sh_radius = sh_radius + sh_dis
          sh_pos_x = car_pos.x + sh_radius * math.cos(sh_theta)
          sh_pos_y = car_pos.y + sh_radius * math.sin(sh_theta)
          sh_pos = {x=sh_pos_x, y=sh_pos_y}

            -- (实际上可以通过勾股定理直接计算出 sin_theta，但考虑到需要判断 theta 超过 pi，没有用这种办法）
            -- local sin_theta = math.sqrt( (1-cos_theta*cos_theta) )

            -- 如果角度超过 2*PI就进入下一个搜索圆

            -- 是否有必要考虑处理无限循环的问题？
            if sh_radius > 10000 then
                return nil
            end
        end
    end

return nil
end
return Public
