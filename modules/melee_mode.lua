local Event = require 'utils.event'
local Global = require 'utils.global'
local SpamProtection = require 'utils.spam_protection'
local BottomFrame = require 'utils.gui.bottom_frame'
local Gui = require 'utils.gui'

local melee_mode_name = Gui.uid_name()

local state = {}
Global.register(state, function (s) state = s end)

local function create_gui_button(player)
   if player.gui.top[melee_mode_name] then
      return
   end
   local tooltip = { "modules_melee.tooltip" }
   local b = player.gui.top.add(
      {
         type = 'sprite-button',
         sprite = 'item/pistol',
         name = melee_mode_name,
         tooltip = tooltip
      })
   b.style.font_color = { r = 0.11, g = 0.8, b = 0.44 }
   b.style.font = 'heading-1'
   b.style.minimal_height = 40
   b.style.maximal_width = 40
   b.style.minimal_width = 38
   b.style.maximal_height = 38
   b.style.padding = 1
   b.style.margin = 0
end

local function on_player_joined_game(event)
   local activate_custom_buttons = BottomFrame.get('activate_custom_buttons')
   local player = game.get_player(event.player_index)

   if activate_custom_buttons then
      BottomFrame.add_inner_frame(
         {
            player = player,
            element_name = melee_mode_name,
            tooltip =
            {
               'modules_melee.tooltip'
            },
            sprite = 'item/pistol'
         }
      )
   else
      create_gui_button(player)
   end
end

local function move_to_main(player, from, to)
   local ret = {}
   if from == nil or to == nil then
      return {}
   end
   for i = 1, #from do
      local c = from[i]
      if c.valid_for_read then
         if to.can_insert(c) then
            local amt = to.insert(c)
            ret[#ret + 1] = { name = c.name, count = amt, quality = c.quality }
            c.count = c.count - amt
         else
            player.print('Unable to move ' .. c.name .. ' to main inventory')
         end
      end
   end
   return ret
end

local function change_to_melee(player)
   local main_inv = player.get_main_inventory()
   local gun_inv = player.get_inventory(defines.inventory.character_guns)
   local ammo_inv = player.get_inventory(defines.inventory.character_ammo)
   if main_inv == nil or gun_inv == nil or ammo_inv == nil then
      return false
   end
   local gun_moved = move_to_main(player, gun_inv, main_inv)
   local ammo_moved = move_to_main(player, ammo_inv, main_inv)

   state[player.index] = { gun = gun_moved, ammo = ammo_moved }
   return true
end

local function try_move_from_main(main, to, what)
   if what == nil or main == nil or to == nil then
      return
   end
   for i = 1, #what do
      local amt_out = main.remove(what[i])
      if amt_out > 0 then
         local amt_in = to.insert({ name = what[i].name, count = amt_out, quality = what[i].quality })
         if amt_in < amt_out then
            main.insert({ name = what[i].name, count = amt_out - amt_in, quality = what[i].quality })
         end
      end
   end
end

local function change_to_ranged(player)
   local moved = state[player.index]
   if moved == nil then
      moved = {}
   end
   local main_inv = player.get_main_inventory()
   local gun_inv = player.get_inventory(defines.inventory.character_guns)
   local ammo_inv = player.get_inventory(defines.inventory.character_ammo)
   if main_inv == nil or gun_inv == nil or ammo_inv == nil then
      return false
   end
   try_move_from_main(main_inv, gun_inv, moved.gun)
   try_move_from_main(main_inv, ammo_inv, moved.ammo)
   state[player.index] = {}
   return true
end

local function on_gui_click(event)
   local activate_custom_buttons = BottomFrame.get('activate_custom_buttons')
   if activate_custom_buttons then
      return
   end

   if not event.element then
      return
   end
   if not event.element.valid then
      return
   end
   if event.element.name ~= melee_mode_name then
      return
   end
   local player = game.get_player(event.player_index)
   if not player or not player.valid then
      return
   end
   local mm = player.gui.top[melee_mode_name]
   if mm and mm.valid and mm.sprite == 'item/pistol' then
      if change_to_melee(player) then
         player.print({ "modules_melee.change_to_melee" })
         mm.sprite = 'technology/steel-axe'
      else
         player.print({ "modules_melee.change_to_melee_failed" })
      end
   else
      if change_to_ranged(player) then
         player.print({ "modules_melee.change_to_ranged" })
         mm.sprite = 'item/pistol'
      else
         player.print({ "modules_melee.change_to_ranged_failed" })
      end
   end
end

local function moved_to_string(tbl)
   local ret = ''
   for i = 1, #tbl do
      if ret ~= '' then
         ret = ret .. ', '
      end
      ret = ret .. tbl[i].count .. ' ' .. tbl[i].name
   end
   return ret
end

local function player_inventory_changed(player_index, inv_id, name)
   local player = game.get_player(player_index)
   if not player or not player.valid then
      return
   end

   local activate_custom_buttons = BottomFrame.get('activate_custom_buttons')
   if activate_custom_buttons then
      local old_frame = BottomFrame.get_frame_by_element_name(player, melee_mode_name)
      if old_frame and old_frame.sprite == 'item/pistol' then
         return
      end
   else
      if player.gui.top[melee_mode_name] and player.gui.top[melee_mode_name].valid and player.gui.top[melee_mode_name].sprite == 'item/pistol' then
         return
      end
   end

   local inv = player.get_inventory(inv_id)
   local moved = move_to_main(player, inv, player.get_main_inventory())
   if #moved > 0 then
      player.print({ "modules_melee.move_to_main_inventory", moved_to_string(moved) })
   end
   if not inv or not inv.is_empty() then
      player.print({ "modules_melee.move_to_main_inventory_failed", name })
   end
end

local function on_player_ammo_inventory_changed(event)
   if event.tick < 200 then return end
   player_inventory_changed(event.player_index, defines.inventory.character_ammo, 'ammo')
end

local function on_player_gun_inventory_changed(event)
   if event.tick < 200 then return end
   player_inventory_changed(event.player_index, defines.inventory.character_guns, 'guns')
end

Gui.on_click(
   melee_mode_name,
   function (event)
      local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Mtn v3 Spectate Ready Button')
      if is_spamming then
         return
      end

      local player = event.player
      if not player or not player.valid or not player.connected then
         return
      end

      local old_frame = BottomFrame.get_frame_by_element_name(player, melee_mode_name)
      if old_frame and old_frame.sprite == 'item/pistol' then
         if change_to_melee(player) then
            player.print({ "modules_melee.change_to_melee" })
            old_frame.sprite = 'technology/steel-axe'
            BottomFrame.refresh_inner_frames(player)
         else
            player.print({ "modules_melee.change_to_melee_failed" })
         end
      else
         if change_to_ranged(player) then
            player.print({ "modules_melee.change_to_ranged" })
            old_frame.sprite = 'item/pistol'
            BottomFrame.refresh_inner_frames(player)
         else
            player.print({ "modules_melee.change_to_ranged_failed" })
         end
      end

      on_gui_click(event)
   end
)

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_ammo_inventory_changed, on_player_ammo_inventory_changed)
Event.add(defines.events.on_player_gun_inventory_changed, on_player_gun_inventory_changed)
