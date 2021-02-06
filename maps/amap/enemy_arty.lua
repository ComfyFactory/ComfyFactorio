local Event = require 'utils.event'
local Global = require 'utils.global'

local arty_count = {}
local Public = {}

local artillery_target_entities = {
    'character',
    'roboport',
    'furnace',

}

Global.register(
    arty_count,
    function(tbl)
        arty_count = tbl
    end
)

function Public.reset_table()
  arty_count.max = 500
  arty_count.all = {}
  arty_count.count = 0
  arty_count.distance = 0
end


function Public.get(key)
    if key then
        return arty_count[key]
    else
        return arty_count
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

local on_init = function()
    Public.reset_table()
end

local function add_bullet ()
  game.print(arty_count.count)
  for k, p in pairs(arty_count.all) do
      if arty_count.all[k].valid then
        arty_count.all[k].insert{name='artillery-shell', count = '5'}
      end
  end
end
local function on_chunk_generated(event)
   local surface = event.surface
   local left_top_x = event.area.left_top.x
   local left_top_y = event.area.left_top.y

  local position
   for x = 0, 31, 1 do
 		for y = 0, 31, 1 do
    	position = {x = left_top_x + x, y = left_top_y + y}
      local q =position.x*position.x
      local w =position.y*position.y
      local distance =math.sqrt(q+w)

      if distance >= arty_count.distance then

        if arty_count.count >= arty_count.max then
          return
        else
        local roll = math.random(1, 1024)
        if roll <= 2 then
          local arty = surface.create_entity{name = "artillery-turret", position = position, force='enemy'}
          arty.insert{name='artillery-shell', count = '5'}
          --local k = #arty_count.all
    --      game.print(k)
         arty_count.all[#arty_count.all+1]=arty
          arty_count.count = arty_count.count + 1
      --    game.print(arty_count.count)
       game.print(position)
        end
      end
    end
  end
  end

end

local function on_entity_died(event)

  local name = event.entity.name
  local entity = event.entity
  local force = event.entity.force

  if name == 'artillery-turret' and force.name == 'enemy' then

    arty_count.count = arty_count.count -1

     if arty_count.count <= 0 then
       arty_count.count = 0
     end
end
end

function on_player_changed_position(event)
local player = game.players[event.player_index]
local position = player.position

local q =position.x*position.x
local w =position.y*position.y
local distance =math.sqrt(q+w)

if distance >= arty_count.distance-200 then



end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.on_nth_tick(600, add_bullet)
Event.on_init(on_init)


return Public
