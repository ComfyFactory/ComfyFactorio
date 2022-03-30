local Event = require 'utils.event'
local Global = require 'utils.global'

local state = {}
Global.register(state, function(s) state = s end)

local function create_gui_button(player)
   if player.gui.top.melee_mode then
      return
   end
   local tooltip = 'Melee/Ranged mode toggle. Guns and ammo will stay in inventory in melee mode and be restored in ranged mode'
   local b = player.gui.top.add({
	 type = 'sprite-button',
	 sprite = 'item/pistol',
	 name = 'melee_mode',
	 tooltip = tooltip})
   b.style.font_color = {r = 0.11, g = 0.8, b = 0.44}
   b.style.font = 'heading-1'
   b.style.minimal_height = 40
   b.style.maximal_width = 40
   b.style.minimal_width = 38
   b.style.maximal_height = 38
   b.style.padding = 1
   b.style.margin = 0
end

local function on_player_joined_game(event)
   create_gui_button(game.players[event.player_index])
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
	    ret[#ret + 1] = { name=c.name, count=amt }
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
	 local amt_in = to.insert({name = what[i].name, count = amt_out})
	 if amt_in < amt_out then
	    main.insert({name = what[i].name, count = amt_out - amt_in})
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
   if not event.element then
      return
   end
   if not event.element.valid then
      return
   end
   if event.element.name ~= 'melee_mode' then
      return
   end
   local player = game.players[event.player_index]
   local mm = player.gui.top.melee_mode
   if mm.sprite == 'item/pistol' then
      if change_to_melee(player) then
	 player.print('Switching to melee mode, ammo and weapons will stay in main inventory')
	 mm.sprite = 'item/dummy-steel-axe'
      else
	 player.print('Unable to switch to melee mode. Are you dead?')
      end
   else
      if change_to_ranged(player) then
	 player.print('Switching to ranged mode, trying to restore previous guns and ammo')
	 mm.sprite = 'item/pistol'
      else
	 player.print('Unable to switch to ranged mode. Are you dead?')
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
   local player = game.players[player_index]
   if player.gui.top.melee_mode.sprite == 'item/pistol' then
      return
   end
   local inv = player.get_inventory(inv_id)
   local moved = move_to_main(player, inv, player.get_main_inventory())
   if #moved > 0 then
      player.print('In melee mode, moved ' .. moved_to_string(moved) .. ' to main inventory')
   end
   if not inv.is_empty() then
      player.print('WARNING: in melee mode, unable to empty ' .. name .. ' to main inventory')
   end
end

local function on_player_ammo_inventory_changed(event)
   player_inventory_changed(event.player_index, defines.inventory.character_ammo, 'ammo')
end

local function on_player_gun_inventory_changed(event)
   player_inventory_changed(event.player_index, defines.inventory.character_guns, 'guns')
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_ammo_inventory_changed, on_player_ammo_inventory_changed)
Event.add(defines.events.on_player_gun_inventory_changed, on_player_gun_inventory_changed)

