local Event = require 'utils.event'
local WPT = require 'maps.amap.table'

local WD = require 'maps.amap.modules.wave_defense.table'
local entity_types = {
    ['unit'] = true,
    ['turret'] = true,
    ['unit-spawner'] = true
}

local projectiles = {
    'laser',
    'rocket',
    'poison-capsule',
    'explosive-rocket',
    'destroyer-capsule'
}

local wepeon ={
  'slowdown-capsule',

  'land-mine',
  'biter-spawner',
  'gun-turret'
}
local aoe ={
  'grenade',
  'cluster-grenade'
}

local function unstuck_player(index)

	local player = game.get_player(index)
	local surface = player.surface
	local position = surface.find_non_colliding_position('character', player.position, 32, 0.5)
	if not position then
		return
	end
	player.teleport(position, surface)
end

local function loaded_biters(event)

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    local cause = event.cause
    if not cause then
        return
    end
    local position = false
    if cause then
        if cause.valid then
            position = cause.position
        end
    end
    if not position then
        position = {entity.position.x + (-20 + math.random(0, 40)), entity.position.y + (-20 + math.random(0, 40))}
    end


local abc = {
  wepeon[math.random(1, #wepeon)],
  projectiles[math.random(1, #projectiles)],
  aoe[math.random(1, #aoe)]
}
local k=math.random(1, #aoe+#wepeon+#projectiles)

if k>1 and k <=#wepeon then
  k=1
end
if k>#wepeon and k <=#wepeon+#projectiles then
  k=2
end
if k>#wepeon+#projectiles and k <=#aoe+#wepeon+#projectiles then
  k=3
end

if k~=2 then
  position=entity.position
end
local name = abc[k]
local  e =  entity.surface.create_entity(
        {
            name =name ,
            position = entity.position,
            force = 'enemy',
            source = entity.position,
            target = position,
            max_range = 32,
            speed = 0.3
        }

    )
    if e.name == 'gun-turret' then
      --  local this = WPT.get()
      local ammo_name= require 'maps.amap.enemy_arty'.get_ammo()
      e.insert{name=ammo_name, count = 200}
    --  e.destructible = false
    --  this.biter_wudi[#this.biter_wudi+1]=e

    end
    if e.name == 'biter-spawner' then
      local this = WPT.get()
      e.destructible = false
      this.biter_wudi[#this.biter_wudi+1]=e


      for k, player in pairs(game.connected_players) do
unstuck_player(player.index)
      end

    end
end

local on_entity_died = function(event)
  local entity = event.entity
  if not (entity and entity.valid) then
      return
  end
  local cause = event.cause
  if not cause then
      return
  end
if entity.force.index == game.forces.player.index then
  return
end
if not entity_types[entity.type] then
    return
end
local wave_number = WD.get('wave_number')
--从1000波以后，开启虫子亡语
if wave_number <= 1000 then return end

local k = wave_number*0.0025-1
if k >= 5 then k = 5 end
--if math.random(1, 8) <= k then
  if entity.name == 'land-mine' then
    --body...
        loaded_biters(event)
  --end
end


  if math.random(1, 100) <= k then
      loaded_biters(event)
 end
end

local no_wudi = function()
 local this = WPT.get()

 for i,v in ipairs(this.biter_wudi) do
   local e = this.biter_wudi[i]
   e.destructible = true
   this.biter_wudi[i]=nil
 end

end

Event.on_nth_tick(480, no_wudi)
Event.add(defines.events.on_entity_died, on_entity_died)
