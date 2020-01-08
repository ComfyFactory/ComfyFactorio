global.this = {}
local _global = require("utils.global")
local _evt = require("utils.event")
local _map = require("tools.map_functions")
local _common = require("planet_prison.mod.common")
local _layers = require("planet_prison.mod.layers")
local _ai = require("planet_prison.mod.ai")
local _bp = require("planet_prison.mod.bp")
global.this._config = require("planet_prison.config")

global.this.maps = {
   {
      name = "Flooded metropolia",
      height = 2000,
      width = 2000,
      water = 1,
      terrain_segmentation = 8,
      property_expression_names = {
         moisture = 0,
         temperature = 30.
      },
      starting_area = "none",
      autoplace_controls = {
         ["iron-ore"] = {
            frequency = 0,
         },
         ["copper-ore"] = {
            frequency = 0,
         },
         ["stone"] = {
            frequency = 0,
         },
         ["coal"] = {
            frequency = 0,
         },
         ["crude-oil"] = {
            frequency = 10,
            size = 1,
         },
         ["trees"] = {
            frequency = 4,
         },
         ["enemy-base"] = {
            frequency = 0,
         }
      },
   }
}

global.this.entities_cache = nil
global.this.surface = nil
global.this.last_friend = nil
local function pick_map()
   return global.this.maps[_common.rand_range(1, #global.this.maps)]
end

local function find_force(name)
   for _, f in pairs(game.forces) do
      if f.name == name then
         return f
      end
   end

   return nil
end

local function init_player_ship_bp(entity, player)
   entity.force = player.force
   if entity.name == "crash-site-chest-1" then
      for _, stack in pairs(global.this._config.player_ship_loot) do
         entity.insert(stack)
      end
   end

   if entity.name == "crash-site-generator" then
      entity.electric_buffer_size = 2000
      entity.power_production = 2000
   end
end

global.this.events = {
   merchant = {
      alive = false,
      moving = false,
      spawn_tick = 0,
      embark_tick = 0,
      position = { x = 0, y = 0 },
      offer = global.this._config.merchant_offer,
   }
}
local function init_merchant_bp(entity, _)
   entity.force = "merchant"
   entity.rotatable = false
   entity.minable = false
   if entity.name ~= "market" then
      entity.operable = false
   else
      for _, entry in pairs(global.this.events.merchant.offer) do
         entity.add_market_item(entry)
      end
   end
end

local function noise_hostile_hook(ent)
   ent.force = "enemy"
   if ent.name == "character" then
      ent.insert({name="pistol", count=1})
      ent.insert({name="firearm-magazine", count=20})
   else
      ent.insert({name="firearm-magazine", count=200})
   end
end

local function noise_set_neutral_hook(ent)
   ent.force = "neutral"
end

global.this.bp = {
   player_ship = require("planet_prison.bp.player_ship"),
   merchant = require("planet_prison.bp.merchant")
}
local function init_game()
   global.this.surface = game.create_surface("arena", pick_map())
   global.this.surface.min_brightness = 0
   global.this.surface.ticks_per_day = 25000 * 4
   global.this.perks = {}
   global.this.events.merchant.spawn_tick = game.tick + 5000

   game.map_settings.pollution.enabled = false
   game.map_settings.enemy_evolution.enabled = false
   game.difficulty_settings.technology_price_multiplier = 0.1
   game.difficulty_settings.research_queue_setting = "always"

   _layers.init()
   _layers.set_collision_mask({"water-tile"})
   _layers.add_noise_layer("LuaTile", "concrete", {"concrete"}, 0.3, 0.2)
   _layers.add_noise_layer("LuaTile", "stones", {"stone-path"},  0.2, 0.4)
   _layers.add_noise_layer("LuaTile", "shallows", {"water-shallow"}, 0.5, 0.005)
   _layers.add_noise_layer("LuaEntity", "scrap", {"mineable-wreckage"}, 0.5, 0.1)
   _layers.add_noise_layer("LuaEntity", "walls", {"stone-wall"}, 0.5, 0.09)
   _layers.add_noise_layer("LuaEntity", "hostile", {"character",
                                                    "gun-turret"}, 0.92, 0.99)
   _layers.add_noise_layer("LuaEntity", "structures", {"big-electric-pole",
                                                       "medium-electric-pole"}, 0.9, 0.9)
   _layers.add_noise_layer_hook("structures", noise_set_neutral_hook)
   _layers.add_noise_layer_hook("walls", noise_set_neutral_hook)
   _layers.add_noise_layer_hook("hostile", noise_hostile_hook)
   _bp.push_blueprint("player_ship", global.this.bp.player_ship)
   _bp.set_blueprint_hook("player_ship", init_player_ship_bp)
   _bp.push_blueprint("merchant", global.this.bp.merchant)
   _bp.set_blueprint_hook("merchant", init_merchant_bp)
end

local function do_spawn_point(player)
   local point = {
      x = _common.get_axis(player.position, "x"),
      y = _common.get_axis(player.position, "y") - 2
   }
   local instance = _bp.build(player.surface, "player_ship", point, player)
   _layers.push_excluding_bounding_box(instance.bb)
end

local function get_non_obstructed_position(s, radius)
   while true do
      local chunk = s.get_random_chunk()
      chunk.x = chunk.x * 32
      chunk.y = chunk.y * 32

      for x = 1, radius do
         for y = 1, radius do
            local tile = s.get_tile({chunk.x + x, chunk.y + y})
            if not tile.collides_with("ground-tile") then
               goto continue
            end
         end
      end

      local search_info = {
         position = chunk,
         radius = radius,
         force = {"neutral", "enemy"},
         invert = true
      }
      local ents = s.find_entities_filtered(search_info)
      if not ents then
         return chunk
      end

      if #ents == 0 then
         return chunk
      end

      if ents[1].name == "character" then
         return chunk
      end

      ::continue::
   end
end

local function redraw_gui(p)
   p.gui.left.clear()

   local merchant = global.this.events.merchant
   local perks = global.this.perks[p.tag]
   local chat_type = "Global chat"
   if not perks.chat_global then
      chat_type = "Buddies chat"
   end

   local button = {
      type = "button",
      name = "manual_toggle",
      caption = "Manual"
   }
   p.gui.left.add(button)

   button = {
      type = "button",
      name = "chat_toggle",
      caption = chat_type,
   }
   p.gui.left.add(button)

   if merchant.alive and not perks.minimap then
      button = {
         type = "button",
         name = "merchant_find",
         caption = "Merchant",
      }
      p.gui.left.add(button)
   end

   if perks.flashlight then
      button = {
         type = "button",
         name = "flashlight_toggle",
         caption = "Toggle flashlight"
      }
      p.gui.left.add(button)
   end
end

local function print_merchant_position(player)
   local position = global.this.events.merchant.position
   local perks = global.this.perks[player.tag]
   if not perks.minimap then
      player.print(string.format(">> You were able to spot him %s from your location",
                                 _common.get_readable_direction(player.position, position)))
   else
      player.print(string.format(">> You received a broadcast with [gps=%d,%d] coordinates", position.x, position.y))
   end
end

local function on_gui_click(e)
   local elem = e.element
   local p = game.players[e.player_index]
   local perks = global.this.perks[p.tag]

   if elem.name == "chat_toggle" then
      if perks.chat_global then
         elem.caption = "Buddies chat"
         perks.chat_global = false
      else
         elem.caption = "Global chat"
         perks.chat_global = true
      end
   elseif elem.name == "flashlight_toggle" then
      if perks.flashlight_enable then
         perks.flashlight_enable = false
         p.character.disable_flashlight()
      else
         perks.flashlight_enable = true
         p.character.enable_flashlight()
      end
   elseif elem.name == "merchant_find" then
      print_merchant_position(p)
   elseif elem.name == "manual_toggle" then
      local children = p.gui.center.children
      if #children >= 1 then
         p.gui.center.clear()
         return
      end

      local text_box = {
         type = "text-box",
         text = global.this._config.manual
      }
      text_box = p.gui.center.add(text_box)
      text_box.style.minimal_width = 512
      text_box.read_only = true
      text_box.word_wrap = true
   end
end

local function init_player(p)
   p.teleport({0, 0}, "arena")
   local s = p.surface
   local position = get_non_obstructed_position(s, 10)

   p.teleport(position, "arena")
   p.name = "inmate"
   p.tag = string.format("[%d]", _common.rand_range(1000, 9999))
   p.force = game.create_force(p.tag)
   p.force.set_friend("neutral", true)
   global.this.perks[p.tag] = {
      flashlight = false,
      flashlight_enabled = false,
      minimap = false,
      chat_global = true,
   }

   local merch = find_force("merchant")
   if merch then
      p.force.set_friend(merch, true)
      merch.set_friend(p.force, true)
   end

   p.force.research_queue_enabled = true
   for _, tech in pairs(p.force.technologies) do
      for name, status in pairs(global.this._config.technologies) do
         if tech.name == name then
            tech.researched = status
            tech.enabled = status
         end
      end
   end

   p.minimap_enabled = false
   redraw_gui(p)
   do_spawn_point(p)
end

local function on_player_joined_game(e)
   local p = game.players[e.player_index]
   init_player(p)
end

local function _build_merchant_bp(surf, position)
   local instance = _bp.build(surf, "merchant", position, nil)
   _layers.push_excluding_bounding_box(instance.bb)
end

local function _remove_merchant_bp(surf)
   local refs = _bp.get_references("merchant")
   local bb = _bp.reference_get_bounding_box(refs[1])
   _layers.remove_excluding_bounding_box(bb)
   _bp.destroy_references(surf, "merchant")
   global.this.events.merchant.position = {
      x = 0,
      y = 0
   }
end

local function spawn_merchant(s)
   local merchant = global.this.events.merchant
   local position = get_non_obstructed_position(s, 10)
   local merch
   if not merchant.moving then
      merch = game.create_force("merchant")
   else
      merch = find_force("merchant")
   end

   merchant.position = position
   merchant.alive = true
   merchant.moving = false
   merchant.embark_tick = game.tick + 90000
   _build_merchant_bp(s, position)

   s.print(">> Merchant appeared in the area")
   for _, p in pairs(game.players) do
      p.force.set_friend(merch, true)
      merch.set_friend(p.force, true)
      print_merchant_position(p)
      redraw_gui(p)
   end
end

local function embark_merchant(s)
   global.this.events.merchant.alive = false
   global.this.events.merchant.moving = true
   global.this.events.merchant.spawn_tick = game.tick + 10000

   s.print(">> Merchant is moving to new location")
   _remove_merchant_bp(s)
   for _, player in pairs(game.players) do
      redraw_gui(player)
   end
end

local function merchant_event(s)
   local e = global.this.events
   local m = e.merchant
   if not m.alive and m.spawn_tick <= game.tick then
      spawn_merchant(s)
   end

   if m.alive and not m.moving and m.embark_tick <= game.tick then
      embark_merchant(s)
   end
end

local function cause_event(s)
   merchant_event(s)
end

local function unlink_old_blueprints(name)
   local query = {
      timestamp = game.tick,
   }

   local refs = _bp.unlink_references_filtered(name, query)
   for _, ref in pairs(refs) do
      local bb = _bp.reference_get_bounding_box(ref)
      _layers.remove_excluding_bounding_box(bb)
   end
end

local function on_tick()
   local s = global.this.surface
   if not s then
      log("on_tick: surface empty!")
      return
   end

   if not s.is_chunk_generated then
      log("on_tick: is_chunk_generated nil, map save?")
      return
   end

   if not s.is_chunk_generated({0, 0}) then
      return
   end

   local surf = global.this.surface
   if game.tick % 4 == 0 then
      _ai.do_job(surf, _ai.command.seek_and_destroy_player)
   end

   if game.tick % 10000 == 0 then
      unlink_old_blueprints("player_ship")
   end

   _layers.do_job(surf, 64)
   cause_event(s)
end

local function make_ore_patch(e)
   if _common.rand_range(1, 60) ~= 1 then
      return
   end

   local surf = e.surface
   local point = e.area.left_top
   _map.draw_entity_circle(point, "stone", surf, 6, true, 1000000)
   _map.draw_entity_circle(point, "coal", surf, 12, true, 1000000)
   _map.draw_entity_circle(point, "copper-ore", surf, 18, true, 1000000)
   _map.draw_entity_circle(point, "iron-ore", surf, 24, true, 1000000)
   _map.draw_noise_tile_circle(point, "water", surf, 4)
end

local function on_chunk_generated(e)
   if e.surface.name ~= "arena" then
      return
   end

   make_ore_patch(e)
   _layers.push_bounding_box(e.area)
end

local function on_player_mined_entity(e)
   if e.entity.name ~= "mineable-wreckage" then
      return
   end

   local candidates = {}
   local chance = _common.rand_range(0, 1000)
   for name, attrs in pairs(global.this._config.wreck_loot) do
      local prob = attrs.rare * 100
      if prob < chance then
         local cand = {
            name = name,
            count = _common.rand_range(attrs.count[1], attrs.count[2]),
         }
         table.insert(candidates, cand)
      end
   end

   local count = #candidates
   if count == 0 then
      return
   end

   local cand = candidates[_common.rand_range(1, count)]
   e.buffer.insert(cand)
end

local function on_player_died(e)
   local index = e.player_index
   if not index then
      return -- banned/kicked somewhere else
   end

   local p = game.players[index]
   game.merge_forces(p.tag, "neutral")
   global.this.perks[p.tag] = {
      flashlight = false,
      flashlight_enabled = false,
      minimap = false,
      chat_global = true,
   }
end

local function on_player_respawned(e)
   local p = game.players[e.player_index]
   init_player(p)
end

local function on_player_dropped_item(e)
   if not global.this.last_friend then
      global.this.last_friend = {}
   end

   local p = game.players[e.player_index]
   local ent = e.entity
   if ent.stack.name == "raw-fish" then
      local ent_list = p.surface.find_entities_filtered({
         name = p.character.name,
         position = ent.position,
         limit = 1,
         radius = 2,
      })
      if not ent_list or not #ent_list then
         return
      end

      local peer = ent_list[1].player
      if p.force.get_friend(peer.force) then
         p.print(string.format("The %s %s is your buddy already", peer.name,
                               peer.tag))
         return
      end

      if global.this.last_friend[peer.tag] == p.tag then
         p.force.set_cease_fire(peer.force, true)
         peer.force.set_cease_fire(p.force, true)
         p.print(string.format("%s %s is now your buddy", peer.name, peer.tag))
         peer.print(string.format("%s %s is now your buddy", p.name, p.tag))
         global.this.last_friend[p.tag] = ""
         return
      end

      global.this.last_friend[p.tag] = peer.tag
      p.print(string.format("You want %s %s to be your buddy", peer.name, peer.tag))
      peer.print(string.format("The %s %s wants to be your buddy", p.name, p.tag))
   elseif ent.stack.name == "coal" then
      local ent_list = p.surface.find_entities_filtered({
         name = p.character.name,
         position = ent.position,
         limit = 1,
         radius = 1,
      })
      if not ent_list or not #ent_list then
         return
      end

      local peer = ent_list[1].player
      if p.force.get_friend(peer.force) then
         p.print(string.format("The %s %s is not your buddy", p.name, p.tag))
         return
      end

      p.force.set_cease_fire(peer.force, false)
      peer.force.set_cease_fire(p.force, false)

      p.print(string.format("The %s %s is no longer your buddy", peer.name, peer.tag))
      peer.print(string.format("The %s %s is no longer your buddy", p.name, p.tag))
   end
end

local function on_chunk_charted(e)
   local f_perks = global.this.perks[e.force.name]

   if not f_perks then
      return
   end

   if not f_perks.minimap then
      e.force.clear_chart()
   end
end

local function on_entity_damaged(e)
   local ent = e.entity

   if ent.force.name == "merchant" then
      if not ent.force.get_friend(e.force) then
         return
      end

      ent.force.set_friend(e.force, false)
      e.force.set_friend(ent.force, false)
   end
end

local function merchant_death(e)
   local ent = e.entity
   if ent.force.name ~= "merchant" then
      return false
   end

   if ent.name ~= "character" and ent.name ~= "market" then
      return false
   end

   local s = ent.surface
   local explosion = {
      name = "massive-explosion",
      position = ent.position
   }
   s.create_entity(explosion)
   _remove_merchant_bp(s)

   global.this.events.merchant.alive = false
   global.this.events.merchant.moving = false
   global.this.events.merchant.spawn_tick = game.tick + 1000
   game.merge_forces("merchant", "neutral")

   s.print(">> Merchant died")
   for _, player in pairs(game.players) do
      redraw_gui(player)
   end

   return true
end

local function hostile_death(e)
   local ent = e.entity
   local loot = e.loot
   if ent.name ~= "character" then
      return false
   end

   if ent.player then
      loot.insert({name = "coin", count = 70})
   else
      loot.insert({name = "coin", count = 10})
   end

   return true
end

local function on_entity_died(e)
   if not e.entity.valid then
      return
   end

   if merchant_death(e) then
      return
   end

   hostile_death(e)
end


local function merchant_exploit_check(e)
   local ent = e.created_entity
   if ent.type ~= "electric-pole" then
      return
   end

   local refs = _bp.get_references("merchant")
   if not refs or #refs <= 0 then
      return
   end

   local bp_ent = _bp.reference_get_entities(refs[1])[1]
   local surf = bp_ent.surface

   local query = {
      type = "electric-pole",
      position = bp_ent.position,
      radius = 15
   }
   local ents = surf.find_entities_filtered(query)
   for _, s_ent in pairs(ents) do
      if s_ent.valid and s_ent.force.name ~= "merchant" then
         s_ent.die()
      end
   end
end

local function on_built_entity(e)
   merchant_exploit_check(e)
end

local function on_market_item_purchased(e)
   local p = game.players[e.player_index]
   local m = e.market
   local o = m.get_market_items()[e.offer_index].offer
   local perks = global.this.perks[p.tag]

   if o.effect_description == "Construct a flashlight" then
      perks.flashlight = true
      perks.flashlight_enable = true
      p.character.enable_flashlight()
      redraw_gui(p)
   elseif o.effect_description == "Construct a GPS receiver" then
      perks.minimap = true
      p.minimap_enabled = true
   end
end

local function stringify_color(color)
   local r, g, b = color.r, color.g, color.b
   if r <= 1 then
      r = math.floor(r * 255)
   end

   if g <= 1 then
      g = math.floor(g * 255)
   end

   if b <= 1 then
      b = math.floor(b * 255)
   end

   return string.format("%d,%d,%d", r, g, b)
end

local function create_console_message(p, message)
   local prefix_fmt = "[color=%s]%s %s:[/color]"
   local msg_fmt = "[color=%s]%s[/color]"
   local color = stringify_color(p.chat_color)
   local prefix = string.format(prefix_fmt, color, p.name, p.tag)
   local p_msg = string.format(msg_fmt, color, message)

   if global.this.perks[p.tag].chat_global then
      msg_fmt = "[color=red]global:[/color] %s %s"
   else
      msg_fmt = "[color=green]buddies:[/color] %s %s"
   end

   return string.format(msg_fmt, prefix, p_msg)
end

local function filter_out_gps(message)
   local msg = string.gsub(message, '%[gps=%-?%d+%,?%s*%-?%d+%]', '[gps]')
   return msg
end

local function on_console_chat(e)
   local pid = e.player_index

   if not pid then
      return
   end

   local p = game.players[pid]
   local msg = create_console_message(p, e.message)
   if global.this.perks[p.tag].chat_global then
      for _, peer in pairs(game.players) do
         local perks = global.this.perks[peer.tag]
         if peer.tag ~= p.tag then
            if perks.minimap then
               peer.print(msg)
            else
               peer.print(filter_out_gps(msg))
            end
         end
      end
   else
      for _, f in pairs(game.forces) do
         if p.force.get_cease_fire(f) then
            local peer = f.players[1]
            local perks = global.this.perks[peer.tag]
            if peer.tag ~= p.tag then
               if perks.minimap then
                  peer.print(msg)
               else
                  peer.print(filter_out_gps(msg))
               end
            end
         end
      end
   end
end

local function on_research_finished(e)
   local r = e.research
   if not r.valid then
      return
   end

   local reward = {
      name = "coin",
      count = math.ceil(r.research_unit_count * 3)
   }
   local f = r.force
   for _, player in pairs(f.players) do
      if player.can_insert(reward) then
         player.insert(reward)
      end
   end
end

local function on_rocket_launched(e)
   local surf = global.this.surface
   local pid = e.player_index
   surf.print(">> The rocket was launched")
   if pid == nil then
      surf.print(">> Nobody escaped by it")
   else
      local p = game.players[pid]
      surf.print(string.format(">> The inmate %s was able to escape", p.tag))
      on_player_died({player_index = pid})
      p.character.die()
   end
end

_evt.on_init(init_game)
_evt.add(defines.events.on_built_entity, on_built_entity)
_evt.add(defines.events.on_research_finished, on_research_finished)
_evt.add(defines.events.on_player_joined_game, on_player_joined_game)
_evt.add(defines.events.on_chunk_generated, on_chunk_generated)
_evt.add(defines.events.on_player_mined_entity, on_player_mined_entity)
_evt.add(defines.events.on_player_died, on_player_died)
_evt.add(defines.events.on_player_kicked, on_player_died)
_evt.add(defines.events.on_player_banned, on_player_died)
_evt.add(defines.events.on_player_respawned, on_player_respawned)
_evt.add(defines.events.on_player_dropped_item, on_player_dropped_item)
_evt.add(defines.events.on_pre_player_left_game, on_player_died)
_evt.add(defines.events.on_entity_damaged, on_entity_damaged)
_evt.add(defines.events.on_entity_died, on_entity_died)
_evt.add(defines.events.on_market_item_purchased, on_market_item_purchased)
_evt.add(defines.events.on_chunk_charted, on_chunk_charted)
_evt.add(defines.events.on_console_chat, on_console_chat)
_evt.add(defines.events.on_gui_click, on_gui_click)
_evt.add(defines.events.on_tick, on_tick)
_evt.add(defines.events.on_rocket_launched, on_rocket_launched)

_global.register_init({},
   function(tbl)
      tbl.this = global.this
   end,
   function(tbl)
      global.this = tbl.this
end)
