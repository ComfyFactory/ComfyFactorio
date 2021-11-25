local ICT = require 'maps.amap.ic.table'
local Functions = require 'maps.amap.ic.functions'
local Color = require 'utils.color_presets'
local Gui = require 'utils.gui'
local Tabs = require 'comfy_panel.main'
local Event = require 'utils.event'
local WD = require 'maps.amap.modules.wave_defense.table'
local Public = {}
local insert = table.insert

--! Gui Frames
local save_add_player_button_name = Gui.uid_name()
local save_transfer_car_button_name = Gui.uid_name()
local discard_add_player_button_name = Gui.uid_name()
local transfer_player_select_name = Gui.uid_name()
local discard_transfer_car_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local draw_add_player_frame_name = Gui.uid_name()
local draw_transfer_car_frame_name = Gui.uid_name()
local main_toolbar_name = Gui.uid_name()
local add_player_name = Gui.uid_name()
local transfer_car_name = Gui.uid_name()
local allow_anyone_to_enter_name = Gui.uid_name()
local kick_player_name = Gui.uid_name()

local rpgtable = require 'maps.amap.modules.rpg.table'
local Alert = require 'utils.alert'
local Loot = require'maps.amap.loot'
local WPT = require 'maps.amap.table'
local cool = Gui.uid_name()
local gambel = Gui.uid_name()
local buyxp = Gui.uid_name()
local stop_wave=Gui.uid_name()

local raise_event = script.raise_event
local add_toolbar
local remove_toolbar

local function increment(t, k)
    t[k] = true
end

local function decrement(t, k)
    t[k] = nil
end


local function crate_water(surface,position)
  for i=1,3 do
    for b=1,3 do
      local p ={x=position.x-b+2,y=position.y-i-2}
      if surface.can_place_entity{name = "steel-chest", position = p, force=game.forces.player} then
        surface.set_tiles({{name = "water", position = p}})
      end
    end
  end

surface.create_entity({name = "crude-oil", position = {x=position.x,y=position.y+4}, yield='50'})

end

local function crate_ore(surface,position)
  local ores = {'iron-ore', 'copper-ore', 'stone', 'coal'}
local dist = 3
local k =1
 for a=1,20 do
   for b=1,20 do
   local p = {position.x + a+dist, position.y + b+dist}
   p = surface.find_non_colliding_position(ores[k], p, 1, 1)
     if p then
         surface.create_entity({name = ores[k], position = p, amount = 250})
     end
   end
 end
k =2
  for a=1,20 do
    for b=1,20 do
    local p = {position.x - a-dist, position.y + b+dist}
  p = surface.find_non_colliding_position(ores[k], p, 1, 1)
      if p then
          surface.create_entity({name = ores[k], position = p, amount = 250})
      end
    end
  end
 k =3
   for a=1,20 do
     for b=1,20 do
     local p = {position.x + a+dist, position.y - b-dist}
     p = surface.find_non_colliding_position(ores[k], p, 1, 1)
       if p then
           surface.create_entity({name = ores[k], position = p, amount = 250})
       end
     end
   end
 k =4
    for a=1,20 do
      for b=1,20 do
      local p = {position.x - a-dist, position.y - b-dist}
    p = surface.find_non_colliding_position(ores[k], p, 1, 1)
        if p then
            surface.create_entity({name = ores[k], position = p, amount = 250})
        end
      end
    end
end

local function create_player_table(player)
    local trust_system = ICT.get('trust_system')
    if not trust_system[player.index] then
        trust_system[player.index] = {
            players = {
                [player.name] = true
            },
            allow_anyone = 'right'
        }
    end
    return trust_system[player.index]
end

local function does_player_table_exist(player)
    local trust_system = ICT.get('trust_system')
    if not trust_system[player.index] then
        return false
    else
        return true
    end
end

local function get_players(player, frame, all)
    local tbl = {}
    local players = game.connected_players
    local trust_system = create_player_table(player)

    for _, p in pairs(players) do
        if next(trust_system.players) and not all then
            if not trust_system.players[p.name] then
                insert(tbl, tostring(p.name))
            end
        else
            insert(tbl, tostring(p.name))
        end
    end
    insert(tbl, 'Select Player')

    local selected_index = #tbl

    local f = frame.add({type = 'drop-down', name = transfer_player_select_name, items = tbl, selected_index = selected_index})
    return f
end

local function transfer_player_table(player, new_player)
    local trust_system = ICT.get('trust_system')
    if not trust_system[player.index] then
        return false
    end

    if player.index == new_player.index then
        return false
    end

    if not trust_system[new_player.index] then
        trust_system[new_player.index] = trust_system[player.index]
        local name = new_player.name

        if not trust_system[new_player.index].players[name] then
            increment(trust_system[new_player.index].players, name)
        end

        local cars = ICT.get('cars')
        local renders = ICT.get('renders')
        local c = Functions.get_owner_car_object(cars, player)
        local car = cars[c]
        car.owner = new_player.index

        Functions.render_owner_text(renders, player, car.entity, new_player)

        remove_toolbar(player)
        add_toolbar(new_player)

        local old_index = player.index
        local new_index = new_player.index

        local this = WPT.get()
        if this.tank[new_index] ==nil and this.tank[old_index] then
        this.tank[new_index]=this.tank[old_index]
        this.tank[old_index]=nil
        this.have_been_put_tank[new_index]=true
        this.have_been_put_tank[old_index]=false
        this.whos_tank[new_index]=this.whos_tank[old_index]
        this.whos_tank[old_index]=nil

        if this.time_weights[old_index] then
            this.time_weights[new_index]= this.time_weights[old_index]
           this.time_weights[old_index]=0
        end

        if this.car_pos[old_index] then
            this.car_pos[new_index]=  this.car_pos[old_index]
             this.car_pos[old_index]=nil
        end

        if this.spidertron[old_index] then
          if not this.spidertron[new_index] then
             this.spidertron[new_index]=true
             this.spidertron[old_index]=false
          end
        end



      end

        trust_system[player.index] = nil
    else
        return false
    end

    return trust_system[new_player.index]
end

local function remove_main_frame(main_frame)
    if not main_frame or not main_frame.valid then
        return
    end

    Gui.remove_data_recursively(main_frame)
    main_frame.destroy()
end

local function draw_add_player(player, frame)
    local main_frame =
        frame.add(
        {
            type = 'frame',
            name = draw_add_player_frame_name,
            caption = 'Add Player',
            direction = 'vertical'
        }
    )
    local main_frame_style = main_frame.style
    main_frame_style.width = 370
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 325

    local add_player_frame = get_players(player, main_frame)

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_add_player_button_name, caption = 'Discard'})
    close_button.style = 'back_button'
    close_button.style.maximal_width = 100

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_add_player_button_name, caption = 'Save'})
    save_button.style = 'confirm_button'
    save_button.style.maximal_width = 100

    Gui.set_data(save_button, add_player_frame)
end

local function draw_transfer_car(player, frame)
    local main_frame =
        frame.add(
        {
            type = 'frame',
            name = draw_transfer_car_frame_name,
            caption = 'Transfer Car',
            direction = 'vertical'
        }
    )
    local main_frame_style = main_frame.style
    main_frame_style.width = 370
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 325

    local transfer_car_alert_frame = main_frame.add({type = 'label', caption = "Warning, this action can't be undone!"})
    transfer_car_alert_frame.style.font_color = {r = 255, g = 0, b = 0}
    local transfer_car_frame = get_players(player, main_frame, true)

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_transfer_car_button_name, caption = 'Discard'})
    close_button.style = 'back_button'
    close_button.style.maximal_width = 100

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_transfer_car_button_name, caption = 'Save'})
    save_button.style = 'confirm_button'
    save_button.style.maximal_width = 100

    Gui.set_data(save_button, transfer_car_frame)
end

local function draw_players(data)
    local player_table = data.player_table
    local add_player_frame = data.add_player_frame
    local player = data.player
    local player_list = create_player_table(player)

    for p, _ in pairs(player_list.players) do
        Gui.set_data(add_player_frame, p)
        local t_label =
            player_table.add(
            {
                type = 'label',
                caption = p
            }
        )
        t_label.style.minimal_width = 75
        t_label.style.horizontal_align = 'center'

        local a_label =
            player_table.add(
            {
                type = 'label',
                caption = '✔️'
            }
        )
        a_label.style.minimal_width = 75
        a_label.style.horizontal_align = 'center'
        a_label.style.font = 'default-large-bold'

        local kick_flow = player_table.add {type = 'flow'}
        local kick_player_button =
            kick_flow.add(
            {
                type = 'button',
                caption = 'Kick ' .. p,
                name = kick_player_name
            }
        )
        if player.name == t_label.caption then
            kick_player_button.enabled = false
        end
        kick_player_button.style.minimal_width = 75
        Gui.set_data(kick_player_button, p)
    end
end

local function draw_main_frame(player)
    local main_frame =
        player.gui.screen.add(
        {
            type = 'frame',
            name = main_frame_name,
            caption = 'Car Settings',
            direction = 'vertical',
            style = 'inner_frame_in_outer_frame'
        }
    )

    main_frame.auto_center = true
    local main_frame_style = main_frame.style
    main_frame_style.width = 400
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0

    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 350

    local player_list = create_player_table(player)

    local add_player_frame = inside_table.add({type = 'button', caption = 'Add Player', name = add_player_name})
    local transfer_car_frame = inside_table.add({type = 'button', caption = 'Transfer Car', name = transfer_car_name})
    local allow_anyone_to_enter =
        inside_table.add(
        {
            type = 'switch',
            name = allow_anyone_to_enter_name,
            switch_state = player_list.allow_anyone,
            allow_none_state = false,
            left_label_caption = 'Allow everyone to enter: ON',
            right_label_caption = 'OFF'
        }
    )

    local player_table =
        inside_table.add {
        type = 'table',
        column_count = 3,
        draw_horizontal_lines = true,
        draw_vertical_lines = true,
        vertical_centering = true
    }
    local player_table_style = player_table.style
    player_table_style.vertical_spacing = 10
    player_table_style.width = 350
    player_table_style.horizontal_spacing = 30

    local name_label =
        player_table.add(
        {
            type = 'label',
            caption = 'Name',
            tooltip = ''
        }
    )
    name_label.style.minimal_width = 75
    name_label.style.horizontal_align = 'center'

    local trusted_label =
        player_table.add(
        {
            type = 'label',
            caption = 'Allowed',
            tooltip = ''
        }
    )
    trusted_label.style.minimal_width = 75
    trusted_label.style.horizontal_align = 'center'

    local operations_label =
        player_table.add(
        {
            type = 'label',
            caption = 'Operations',
            tooltip = ''
        }
    )
    operations_label.style.minimal_width = 75
    operations_label.style.horizontal_align = 'center'

    local data = {
        player_table = player_table,
        add_player_frame = add_player_frame,
        transfer_car_frame = transfer_car_frame,
        allow_anyone_to_enter = allow_anyone_to_enter,
        player = player
    }
    draw_players(data)

    player.opened = main_frame
end

local function add_stop_botton (player)
  local this = WPT.get()
  local pirce_wave=this.stop_wave*5000+1
    local stop_function=true
    if pirce_wave >= 50000 then
       pirce_wave=50000
       stop_function = false
    end
      if stop_function then
  player.gui.top.add(
    {
        type = 'sprite-button',
        sprite = 'entity/behemoth-biter',
        name = stop_wave,
        tooltip = {'amap.stop_wave',pirce_wave}
    }
)
end
end

local function toggle(player, recreate)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if recreate and main_frame then
        local location = main_frame.location
        remove_main_frame(main_frame)
        draw_main_frame(player, location)
        return
    end
    if main_frame then
        remove_main_frame(main_frame)
        Tabs.comfy_panel_restore_left_gui(player)
    else
        Tabs.comfy_panel_clear_left_gui(player)
        draw_main_frame(player)
    end
end

add_toolbar = function(player, remove)
    if remove then
        if player.gui.top[main_toolbar_name] then
          player.gui.top[cool].destroy()
          player.gui.top[buyxp].destroy()
          player.gui.top[gambel].destroy()
          if player.gui.top[stop_wave] then
          player.gui.top[stop_wave].destroy()
        end
            player.gui.top[main_toolbar_name].destroy()
            return
        end
    end
    if player.gui.top[main_toolbar_name] then
        return
    end
      local this = WPT.get()
          local index = player.index
    local tooltip = 'Control who may enter your vehicle.'
    player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/spidertron',
            name = main_toolbar_name,
            tooltip = tooltip
        }
    )
    player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/logistic-chest-storage',
            name = cool,
            tooltip = {'amap.openchest'}
        }
    )

if not this.ore_record[index] then
  this.ore_record[index]=0
end
    local need_coin= math.floor(this.ore_record[index]/3)*10+10
    player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/coin',
            name = gambel,
            tooltip = {'amap.buy_water',need_coin}
        }
    )
	    player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/rocket-part',
            name = buyxp,
            tooltip = {'amap.buyxp'}
        }
    )
add_stop_botton(player)
end

remove_toolbar = function(player)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if main_frame and main_frame.valid then
        remove_main_frame(main_frame)
    end

    if player.gui.top[main_toolbar_name] then
        player.gui.top[main_toolbar_name].destroy()
        player.gui.top[cool].destroy()
        player.gui.top[buyxp].destroy()
        player.gui.top[gambel].destroy()
        if player.gui.top[stop_wave] then
  player.gui.top[stop_wave].destroy()
        end
        return
    end
end

local function trigger_on_used_car_door(data)
    local state = data.state
    local player = data.player

    if state == 'add' then
        add_toolbar(player)
    elseif state == 'remove' then
        remove_toolbar(player)
    end
end
Gui.on_click(
    gambel ,
    function(event)

  local player = event.player
   local index = player.index
  local can_buy = false
  local this = WPT.get()
  local need_coin= math.floor(this.ore_record[index]/3)*10000+10000



 if this.ore_record[index]==0 then
   player.insert{name = 'coin', count = 10000}
 end

  local something = player.get_inventory(defines.inventory.chest)

  for k, v in pairs(something.get_contents()) do
      if k=='coin' and v >= need_coin then
      can_buy=true
      end
  end

  if can_buy then
    player.print({'amap.over_ore'})
    player.remove_item{name='coin', count = need_coin}
    local entity=this.tank[player.index]
    local position=entity.position
    local surface=entity.surface
    crate_ore(surface,position)
    crate_water(surface,position)
    this.ore_record[index]=this.ore_record[index]+1
  else
  player.print({'amap.noenough'})
  end


    end
)
Gui.on_click(
    cool ,
    function(event)

   local player = event.player
   local can_buy = false
   local something = player.get_inventory(defines.inventory.chest)
   local need_coin=3000
   for k, v in pairs(something.get_contents()) do
       if k=='coin' and v >= need_coin then
       can_buy=true
       end
   end

   if can_buy then
     local luck = math.floor(math.random(1,150))
     player.print({'amap.lucknb'})
     player.print(luck)
     local magic = luck*5+100
     local msg = {'amap.whatopen'}
      Loot.cool(player.surface, player.surface.find_non_colliding_position("steel-chest", player.position, 20, 1, true) or player.position, 'steel-chest', magic)
    Alert.alert_player(player, 5, msg)
    player.remove_item{name='coin', count = need_coin}
   else
   player.print({'amap.noenough'})
   end
    end
)
Gui.on_click(
    buyxp ,
    function(event)
        local player = event.player
        local can_buy = false
        local need_coin=5000
		    local something = player.get_inventory(defines.inventory.chest)

        for k, v in pairs(something.get_contents()) do
            if k=='coin' and v >= need_coin then
            can_buy=true
            end
        end

        if can_buy then
          local rpg_t = rpgtable.get('rpg_t')
          local msg = {'amap.buyover'}
   		    Alert.alert_player(player,5,msg)
          rpg_t[player.index].xp = rpg_t[player.index].xp +1000
          player.remove_item{name='coin', count = need_coin}
        else
        player.print({'amap.noenough'})
        end

    end
)

Gui.on_click(
    stop_wave ,
    function(event)
        local player = event.player
        local this=WPT.get()
        local pirce_stop_wave= this.stop_wave*5000+1
        local can_buy = false
        local something = player.get_inventory(defines.inventory.chest)
         for k, v in pairs(something.get_contents()) do
             if k=='coin' and v >= pirce_stop_wave then
             can_buy=true
             end
         end
        if can_buy then
          local wave_defense_table = WD.get_table()
            wave_defense_table.game_lost = true
            this.stop_time=this.stop_time+108000*0.5
            this.stop_wave=this.stop_wave+1
            game.print({'amap.buy_stop_wave',player.name,this.stop_time/3600})
            player.remove_item{name='coin', count = pirce_stop_wave}
            if player.gui.top[stop_wave] then
              player.gui.top[stop_wave].destroy()
              add_stop_botton(player)
            end
        else
        player.print({'amap.noenough'})
        end
    end
)

Gui.on_click(
    add_player_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_add_player_frame_name]
        if not player_frame or not player_frame.valid then
            draw_add_player(player, frame)
        else
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    transfer_car_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_transfer_car_frame_name]
        if not player_frame or not player_frame.valid then
            draw_transfer_car(player, frame)
        else
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    allow_anyone_to_enter_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_list = create_player_table(player)

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            if player_list.allow_anyone == 'right' then
                player_list.allow_anyone = 'left'
                player.print('[IC] Everyone is allowed to enter your car!', Color.warning)
            else
                player_list.allow_anyone = 'right'
                player.print('[IC] Everyone is disallowed to enter your car except your trusted list!', Color.warning)
            end

            if player.gui.screen[main_frame_name] then
                toggle(player, true)
            end
        end
    end
)

Gui.on_click(
    save_add_player_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_list = create_player_table(player)

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local add_player_frame = Gui.get_data(event.element)

        if frame and frame.valid then
            if add_player_frame and add_player_frame.valid and add_player_frame then
                local player_gui_data = ICT.get('player_gui_data')
                local fetched_name = player_gui_data[player.name]
                if not fetched_name then
                    return
                end

                local player_to_add = game.get_player(fetched_name)
                if not player_to_add or not player_to_add.valid then
                    return player.print('[IC] Target player was not valid.', Color.warning)
                end

                local name = player_to_add.name

                if not player_list.players[name] then
                    player.print('[IC] ' .. name .. ' was added to your vehicle.', Color.info)
                    player_to_add.print(player.name .. ' added you to their vehicle. You may now enter it.', Color.info)
                    increment(player_list.players, name)
                else
                    return player.print('[IC] Target player is already trusted.', Color.warning)
                end

                remove_main_frame(event.element)

                if player.gui.screen[main_frame_name] then
                    toggle(player, true)
                end
            end
        end
    end
)

Gui.on_click(
    save_transfer_car_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local transfer_car_frame = Gui.get_data(event.element)

        if frame and frame.valid then
            if transfer_car_frame and transfer_car_frame.valid then
                local player_gui_data = ICT.get('player_gui_data')
                local fetched_name = player_gui_data[player.name]
                if not fetched_name then
                    return
                end

                local player_to_add = game.get_player(fetched_name)
                if not player_to_add or not player_to_add.valid then
                    return player.print('[IC] Target player was not valid.', Color.warning)
                end
                local name = player_to_add.name

                local does_player_have_a_car = does_player_table_exist(player_to_add)
                if does_player_have_a_car then
                    return player.print('[IC] ' .. name .. ' already has a vehicle.', Color.warning)
                end

                local success = transfer_player_table(player, player_to_add)
                if not success then
                    player.print('[IC] Please try again.', Color.warning)
                else
                    player.print('[IC] You have successfully transferred your car to ' .. name, Color.success)
                    player_to_add.print('[IC] You have become the rightfully owner of ' .. player.name .. "'s car!", Color.success)
                end

                remove_main_frame(event.element)

                if player.gui.screen[main_frame_name] then
                    player.gui.screen[main_frame_name].destroy()
                end
            end
        end
    end
)

Gui.on_click(
    kick_player_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_list = create_player_table(player)

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local player_name = Gui.get_data(event.element)

        if frame and frame.valid then
            if not player_name then
                return
            end
            local target = game.get_player(player_name)
            if not target or not target.valid then
                player.print('[IC] Target player was not valid.', Color.warning)
                return
            end
            local name = target.name

            if player_list.players[name] then
                player.print('[IC] ' .. name .. ' was removed from your vehicle.', Color.info)
                decrement(player_list.players, name)
                raise_event(
                    ICT.events.on_player_kicked_from_surface,
                    {
                        player = player,
                        target = target
                    }
                )
            end

            remove_main_frame(event.element)

            if player.gui.screen[main_frame_name] then
                toggle(player, true)
            end
        end
    end
)

Gui.on_click(
    discard_add_player_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_add_player_frame_name]

        if player_frame and player_frame.valid then
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    discard_transfer_car_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_transfer_car_frame_name]

        if player_frame and player_frame.valid then
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    main_toolbar_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            frame.destroy()
        else
            draw_main_frame(player)
        end
    end
)

Gui.on_selection_state_changed(
    transfer_player_select_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end

        local element = event.element
        if not element or not element.valid then
            return
        end

        local player_gui_data = ICT.get('player_gui_data')
        local selected = element.items[element.selected_index]
        if not selected then
            return
        end

        if selected == 'Select Player' then
            player.print('[IC] No target player selected.', Color.warning)
            player_gui_data[player.name] = nil
            return
        end

        if selected == player.name then
            player.print('[IC] You can´t select yourself.', Color.warning)
            player_gui_data[player.name] = nil
            return
        end

        player_gui_data[player.name] = selected
    end
)

Public.draw_main_frame = draw_main_frame
Public.toggle = toggle
Public.add_toolbar = add_toolbar
Public.remove_toolbar = remove_toolbar

Event.add(
    defines.events.on_gui_closed,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            frame.destroy()
        end
    end
)

Event.add(ICT.events.used_car_door, trigger_on_used_car_door)

return Public
