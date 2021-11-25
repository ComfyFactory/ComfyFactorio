local WPT = require 'maps.amap.table'

local nom_msg = {'munch', 'munch', 'yum'}

local Public = {}
local random = math.random
local floor = math.floor

local function feed_floaty_text(unit)
    unit.surface.create_entity(
        {
            name = 'flying-text',
            position = unit.position,
            text = nom_msg[random(1, #nom_msg)],
            color = {random(50, 100), 0, 255}
        }
    )
end

local function floaty_hearts(entity, c)
    local position = {x = entity.position.x - 0.75, y = entity.position.y - 1}
    local b = 1.35
    for _ = 1, c, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + random(0, b * 20) * 0.1),
            position.y + (b * -1 + random(0, b * 20) * 0.1)
        }
        entity.surface.create_entity({name = 'flying-text', position = p, text = '♥', color = {random(150, 255), 0, 255}})
    end
end

local function tame_unit_effects(player, entity)
    floaty_hearts(entity, 7)

    rendering.draw_text {
        text = '~' .. player.name .. "'s pet~",
        surface = player.surface,
        target = entity,
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
end

local function find_unit(player, entity)
    local units =
        player.surface.find_entities_filtered(
        {
            type = 'unit',
            area = {{entity.position.x - 1, entity.position.y - 1}, {entity.position.x + 1, entity.position.y + 1}},
            limit = 1
        }
    )
    return units[1]
end

local function feed_pet(unit)
    if unit.prototype.max_health == unit.health then
        return
    end
    unit.health = unit.health + 8 + floor(unit.prototype.max_health * 0.05)
    feed_floaty_text(unit)
    floaty_hearts(unit, random(1, 2))
    return true
end

local function is_valid_player(player, unit)
    if not player.character then
        return
    end
    if not player.character.valid then
        return
    end
    if player.surface.index ~= unit.surface.index then
        return
    end
    return true
end

function Public.biter_pets_tame_unit(player, unit)
  local this=WPT.get()
  local index=player.index
  if not this.biter_pets[index] then
     this.biter_pets[index]={}
  end
    local biter_pets = this.biter_pets[index]


    if not this.biter_number[index] then
        this.biter_number[index]=0
      --  game.print("设置成0 了")
    end

    if this.biter_number[index] >this.biter_max then
      player.print({'amap.too_many_biter'})
      unit.die()
      return false
    end

    unit.ai_settings.allow_destroy_when_commands_fail = false
    unit.ai_settings.allow_try_return_to_spawner = false
    unit.set_command({type = defines.command.wander, distraction = defines.distraction.by_enemy})
    biter_pets[#biter_pets+1] =  unit
    tame_unit_effects(player, unit)
  this.biter_number[index]=this.biter_number[index]+1

    return true
end

function Public.tame_unit_for_closest_player(unit)
    local valid_players = {}
    for _, player in pairs(game.connected_players) do
        if is_valid_player(player, unit) then
            table.insert(valid_players, player)
        end
    end

    local nearest_player = valid_players[1]
    if not nearest_player then
        return
    end

    Public.biter_pets_tame_unit(nearest_player, unit, true)
end


local function can_move(entity, player)
  if entity.surface ~= player.surface then
      return false
  end
    local square_distance = (player.position.x - entity.position.x) ^ 2 + (player.position.y - entity.position.y) ^ 2
  if square_distance < 64 or square_distance > 25600 then
    return false
  end
  return true
end

local function command_unit(entity, player)
        entity.set_command(
            {
                type = defines.command.go_to_location,
                destination_entity = player.character,
                radius = 4,
                distraction = defines.distraction.by_damage
            }
        )

end

local function on_player_changed_position(event)

  if random(1, 100) ~= 1 then
      return
  end
  local this=WPT.get()
  local player = game.players[event.player_index]
  local index = player.index
  if not this.biter_command[index] then
    this.biter_command[index]=0
  end

  if this.biter_command[index] + 600 > game.tick then
  --  game.print("退出循环")
      return
  end
this.biter_command[index]= game.tick


--game.print("开始")
    local biter_pets = this.biter_pets[index]
    if not biter_pets then return end
    if not player.character then
        return
    end

--game.print("进入循环")



for k,v in pairs(biter_pets) do
  if not v or not v.valid then
    biter_pets[k]=nil
    this.biter_number[index]= this.biter_number[index]-1
  end
end

local biter_arty=0
local follow_number = this.biter_follow_number
  --game.print("跟随！")
for k,v in pairs(biter_pets) do
  if can_move(v, player) then
    biter_arty=biter_arty+1
    command_unit(v, player)
  end
  if biter_arty>= follow_number then
    return
  end

end

end


local event = require 'utils.event'
--event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
event.add(defines.events.on_player_changed_position, on_player_changed_position)

return Public
