local Event = require 'utils.event'
local WPT = require 'maps.amap.table'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'
local diff=require 'maps.amap.diff'
local format_number = require 'util'.format_number
local WD = require 'maps.amap.modules.wave_defense.table'

local Public = {}

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local floor = math.floor

local function validate_entity(entity)
    if not (entity and entity.valid) then
        return false
    end

    return true
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.name] then
        return false
    end
    return true
end

local function create_button(player)
    local b =
        player.gui.top.add(
        {
            type = 'sprite-button',
            name = main_button_name,
            sprite = 'item/dummy-steel-axe',
            tooltip = ({'amap.show_map_info'})
        }
    )
    b.style.minimal_height = 38
    b.style.maximal_height = 38
end

local function create_main_frame(player)
    local label
    local line

    local frame = player.gui.top.add({type = 'frame', name = main_frame_name})
    frame.location = {x = 1, y = 40}
    frame.style.minimal_height = 37
    frame.style.maximal_height = 37

    label = frame.add({type = 'label', caption = ' ', name = 'label'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'


    label = frame.add({type = 'label', caption = ' ', name = 'best_record'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'final_wave_record'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'biter_target'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'landmine'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'flame_turret'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4


end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not player then
        return
    end

    if not player.gui.top[main_button_name] then
        create_button(player)
    end
end

local function on_gui_click(event)
    local element = event.element
    if not element.valid then
        return
    end

    local name = element.name

    if name == main_button_name then
        local player = game.players[event.player_index]
        if not validate_player(player) then
            return
        end

        if not player or not player.valid then
            return
        end
        if not player.surface or not player.surface.valid then
            return
        end

        if player.gui.top[main_frame_name] then
            local info = player.gui.top[main_frame_name]

            if info and info.visible then
                info.visible = false
                return

            elseif info and not info.visible then
                for _, child in pairs(player.gui.left.children) do
                    child.destroy()
                end
                info.visible = true
                Public.update_gui(player)
                return
            end
        else
            for _, child in pairs(player.gui.left.children) do
                child.destroy()
            end
            create_main_frame(player)
            Public.update_gui(player)
        end
    end
end


function Public.update_gui(player)
    if not validate_player(player) then
        return
    end

    if not player.gui.top[main_frame_name] then
        return
    end

    if not player.gui.top[main_frame_name].visible then
        return
    end
    local gui = player.gui.top[main_frame_name]
    local map = diff.get()
    local this = WPT.get()
    local best_record = map.map_record[map.world]
    local now_mine=this.now_mine
    local max_mine=this.max_mine
    local now_flame=this.flame
    local max_flame=this.max_flame
    local car_name= this.car_name
    local final_wave_record=map.final_wave_record[map.world]
local wave_number = WD.get('wave_number')
    if best_record == nil then
      best_record=0
    end
    if best_record < wave_number then
best_record=wave_number
    end

    gui.best_record.caption = ' [img=item.submachine-gun]: '.. best_record .. ''
    gui.best_record.tooltip = {'amap.best_record',best_record}

    if final_wave_record then
      final_wave_record="true"
    else
      final_wave_record="false"
    end
    gui.final_wave_record.caption = ' [img=entity.behemoth-biter]: '.. final_wave_record .. ''
    gui.final_wave_record.tooltip = {'amap.final_wave_record'}

     if this.start_game ~= 2 or car_name == nil then
       car_name="  "
     end
    gui.biter_target.caption = ' [img=entity.car]: '  .. car_name .. ''
    gui.biter_target.tooltip = ({'amap.biter_target'})


    gui.landmine.caption = ' [img=entity.land-mine]: ' .. format_number(now_mine, true) .. ' / ' .. format_number(max_mine, true)
    gui.landmine.tooltip = ({'amap.land_mine_placed'})

    gui.flame_turret.caption =
        ' [img=entity.flamethrower-turret]: ' .. format_number(now_flame, true) .. ' / ' .. format_number(max_flame, true)
    gui.flame_turret.tooltip = ({'amap.flamethrowers_placed'})



end
local function on_player_changed_surface(event)
  local this=WPT.get()
  local player = game.players[event.player_index]
  if not validate_player(player) then
      return
  end
    local main_surface= game.surfaces[this.active_surface_index]
  if player.surface==main_surface then
    return
  end

    if player.gui.top[main_frame_name] then
        local info = player.gui.top[main_frame_name]

        if info and info.visible then
            info.visible = false
            return
end
    else
        for _, child in pairs(player.gui.left.children) do
            child.destroy()
        end
        create_main_frame(player)
        Public.update_gui(player)
    end
end

local function updata_gui()
  for k, player in pairs(game.connected_players) do
    if validate_player(player) then
      if player.gui.top[main_frame_name] then
        local info = player.gui.top[main_frame_name]
        if info and info.visible then
          Public.update_gui(player)
        end
      end
    end
  end
end
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.on_nth_tick(600, updata_gui)

return Public
