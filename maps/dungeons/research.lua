--- Tuning factors
local first_research_room_min = 40
local first_research_floor_scale = 1
local last_research_room_max = 160
local last_research_floor_scale = 2.5

-- Early technologies are cheap and we have lots of excess resources for them. Slow down the early part of the
-- game and lower the technology price as people explore the dungeon to speed up the latter part of the game

local tech_scale_start_price = 20
local tech_scale_end_price = 5
local tech_scale_end_level = 25
---

local Global = require 'utils.global'
local DungeonsTable = require 'maps.dungeons.table'

local function dungeon_table()
   return DungeonsTable.get_dungeontable()
end

local function floor_num(index)
   return index - dungeon_table().original_surface_index
end

local function floor_size(index)
   return dungeon_table().surface_size[index]
end

local function rooms_opened(index)
   local d = dungeon_table()
   local f = index - d.original_surface_index
   if index > #d.depth then
      return 0
   end
   return d.depth[index] - f * 100
end

-- variant 1, fixed set of research with 1 on specific floors

local Fixed = {}

local locked_researches = {
    [0] = 'steel-axe',
    [1] = 'heavy-armor',
    [2] = 'military-2',
    [3] = 'physical-projectile-damage-2',
    [4] = 'oil-processing',
    [5] = 'stronger-explosives-2',
    [6] = 'military-science-pack',
    [7] = 'rocketry',
    [8] = 'chemical-science-pack',
    [9] = 'military-3',
    [10] = 'flamethrower',
    [11] = 'distractor',
    [12] = 'laser',
    [13] = 'laser-shooting-speed-3',
    [14] = 'power-armor',
    [15] = 'nuclear-power',
    [16] = 'production-science-pack',
    [17] = 'energy-weapons-damage-3',
    [18] = 'utility-science-pack',
    [19] = 'kovarex-enrichment-process',
    [20] = 'power-armor-mk2',
    [22] = 'fusion-reactor-equipment',
    [24] = 'discharge-defense-equipment',
    [30] = 'atomic-bomb',
    [35] = 'spidertron'
}

function Fixed.Init()
    game.difficulty_settings.technology_price_multiplier = 3
    for _, tech in pairs(locked_researches) do
        game.forces.player.technologies[tech].enabled = false
    end
end

local function get_surface_research(index)
   return locked_researches[floor_num(index)]
end

function Fixed.techs_remain(index)
   local tech = get_surface_research(index)
   if tech and game.forces.player.technologies[tech].enabled == false then
      return 1
   end
   return 0
end

function Fixed.unlock_research(surface_index)
    local techs = game.forces.player.technologies
    local tech = get_surface_research(surface_index)
    if tech and techs[tech].enabled == false then
        techs[tech].enabled = true
        game.print({'dungeons_tiered.tech_unlock', '[technology=' .. tech .. ']', floor_num(surface_index)})
    end
end

function Fixed.room_is_lab(index)
   if floor_size(index) < 225 or math.random(1, 50) ~= 1 then
      return false
   end
   local tech = get_surface_research(index)
   return tech and game.forces.player.technologies[tech].enabled == false
end

function Fixed.noop()
end

Fixed.noop() -- eliminate luacheck warning

-- Variant 2, all research needs unlocking, several can be found on each floor
-- and the research is semi-randomly distributed. Research packs occur at the
-- first half of the ranges.
--
-- target most research found by floor 25; atomic bomb and spidertron 25-35
-- red(0-1), green(2-5), gray(4-9), blue(7-12),
-- blue/gray (10-14), purple(12-19), yellow(14-21), white(20-25)

local state = {}
local Variable = {}

Global.register(state, function(s) state = s end)

-- red floor 0&1 6.5
-- green floor 1-5 31/5 = 7.75
-- green floor 4-7 13/4 = 3.25
-- gray floor 6-9 14/4 = 3.5
-- blue 31
-- blue/gray 22
-- purple 18
-- yellow 46
-- white 10
-- spider/atomic 2
local all_research = {
   -- always found on 0
   -- { name = "automation", min = 0, max = 0 }, -- specially handled to always be found first.
   { name = "gun-turret", min = 0, max = 0 },
   { name = "logistics", min = 0, max = 0 },
   { name = "military", min = 0, max = 0 },
   { name = "stone-wall", min = 0, max = 0 },
   { name = "steel-axe", min = 0, max = 0 },
   { name = "steel-processing", min = 0, max = 0 },
   { name = "heavy-armor", min = 0, max = 0 },
   { name = "electronics", min = 0, max = 0 },


   { name = "fast-inserter", min = 1, max = 1 },
   { name = "optics", min = 1, max = 1 },
   { name = "weapon-shooting-speed-1", min = 1, max = 1 },
   { name = "physical-projectile-damage-1", min = 1, max = 1 },

   -- green research (31+13)
   { name = "logistic-science-pack", min = 1, max = 1 },
   { name = "military-2", min = 1, max = 5 },
   { name = "automation-2", min = 1, max = 5 },
   { name = "fluid-handling", min = 1, max = 5 },
   { name = "flammables", min = 1, max = 5 },
   { name = "battery-equipment", min = 1, max = 5 },
   { name = "modules", min = 1, max = 5 },
   { name = "speed-module", min = 1, max = 5 },
   { name = "productivity-module", min = 1, max = 5 },
   { name = "effectivity-module", min = 1, max = 5 },
   { name = "advanced-material-processing", min = 1, max = 5 },
   { name = "circuit-network", min = 1, max = 5 },
   { name = "explosives", min = 1, max = 5 },
   { name = "toolbelt", min = 1, max = 5 },
   { name = "engine", min = 1, max = 5 },
   { name = "oil-processing", min = 1, max = 5 },
   { name = "stronger-explosives-1", min = 1, max = 5 },
   { name = "modular-armor", min = 1, max = 5 },
   { name = "solar-panel-equipment", min = 1, max = 5 },
   { name = "electric-energy-distribution-1", min = 1, max = 5 },
   { name = "battery", min = 1, max = 5 },
   { name = "electric-energy-accumulators", min = 1, max = 5 },
   { name = "stack-inserter", min = 1, max = 5 },
   { name = "sulfur-processing", min = 1, max = 5 },
   { name = "advanced-electronics", min = 1, max = 5 },
   { name = "logistics-2", min = 1, max = 5 },
   { name = "plastics", min = 1, max = 5 },
   { name = "physical-projectile-damage-2", min = 1, max = 5 },
   { name = "weapon-shooting-speed-2", min = 1, max = 5 },
   { name = "solar-energy", min = 1, max = 5 },
   { name = "mining-productivity-1", min = 1, max = 5 },

   { name = "night-vision-equipment", min = 3, max = 8 },
   { name = "belt-immunity-equipment", min = 3, max = 8 },
   { name = "railway", min = 3, max = 8 },
   { name = "automated-rail-transportation", min = 3, max = 8 },
   { name = "gate", min = 3, max = 8 },
   { name = "rail-signals", min = 3, max = 8 },
   { name = "research-speed-1", min = 3, max = 8 },
   { name = "automobilism", min = 3, max = 8 },
   { name = "fluid-wagon", min = 3, max = 8 },
   { name = "inserter-capacity-bonus-1", min = 3, max = 8 },
   { name = "concrete", min = 3, max = 8 },
   { name = "research-speed-2", min = 3, max = 8 },
   { name = "inserter-capacity-bonus-2", min = 3, max = 8 },

   -- gray research (14)
   { name = "military-science-pack", min = 4, max = 5 },
   { name = "flamethrower", min = 5, max = 10 },
   { name = "refined-flammables-1", min = 5, max = 10 },
   { name = "defender", min = 5, max = 10 },
   { name = "rocketry", min = 5, max = 10 },
   { name = "energy-shield-equipment", min = 5, max = 10 },
   { name = "stronger-explosives-2", min = 5, max = 10 },
   { name = "follower-robot-count-1", min = 5, max = 10 },
   { name = "physical-projectile-damage-3", min = 5, max = 10 },
   { name = "weapon-shooting-speed-3", min = 5, max = 10 },
   { name = "refined-flammables-2", min = 5, max = 10 },
   { name = "follower-robot-count-2", min = 5, max = 10 },
   { name = "physical-projectile-damage-4", min = 5, max = 10 },
   { name = "weapon-shooting-speed-4", min = 5, max = 10 },

   -- blue research 31
   { name = "chemical-science-pack", min = 7, max = 8 },
   { name = "electric-engine", min = 8, max = 13 },
   { name = "lubricant", min = 8, max = 13 },
   { name = "personal-roboport-equipment", min = 8, max = 13 },
   { name = "worker-robots-speed-1", min = 8, max = 13 },
   { name = "exoskeleton-equipment", min = 8, max = 13 },
   { name = "robotics", min = 8, max = 13 },
   { name = "advanced-oil-processing", min = 8, max = 13 },
   { name = "speed-module-2", min = 8, max = 13 },
   { name = "productivity-module-2", min = 8, max = 13 },
   { name = "effectivity-module-2", min = 8, max = 13 },
   { name = "laser", min = 8, max = 13 },
   { name = "braking-force-1", min = 8, max = 13 },
   { name = "electric-energy-distribution-2", min = 8, max = 13 },
   { name = "construction-robotics", min = 8, max = 13 },
   { name = "battery-mk2-equipment", min = 8, max = 13 },
   { name = "worker-robots-storage-1", min = 8, max = 13 },
   { name = "uranium-processing", min = 8, max = 13 },
   { name = "power-armor", min = 8, max = 13 },
   { name = "advanced-material-processing-2", min = 8, max = 13 },
   { name = "logistic-robotics", min = 8, max = 13 },
   { name = "research-speed-3", min = 8, max = 13 },
   { name = "inserter-capacity-bonus-3", min = 8, max = 13 },
   { name = "advanced-electronics-2", min = 8, max = 13 },
   { name = "low-density-structure", min = 8, max = 13 },
   { name = "rocket-fuel", min = 8, max = 13 },
   { name = "mining-productivity-2", min = 8, max = 13 },
   { name = "nuclear-power", min = 8, max = 13 },
   { name = "worker-robots-speed-2", min = 8, max = 13 },
   { name = "braking-force-2", min = 8, max = 13 },
   { name = "research-speed-4", min = 8, max = 13 },

   -- blue/gray research
   { name = "laser-shooting-speed-1", min = 10, max = 14 },
   { name = "military-3", min = 10, max = 14 },
   { name = "explosive-rocketry", min = 10, max = 14 },
   { name = "energy-weapons-damage-1", min = 10, max = 14 },
   { name = "laser-shooting-speed-2", min = 10, max = 14 },
   { name = "personal-laser-defense-equipment", min = 10, max = 14 },
   { name = "discharge-defense-equipment", min = 10, max = 14 },
   { name = "laser-turret", min = 10, max = 14 },
   { name = "distractor", min = 10, max = 14 },
   { name = "energy-shield-mk2-equipment", min = 10, max = 14 },
   { name = "tank", min = 10, max = 14 },
   { name = "refined-flammables-3", min = 10, max = 14 },
   { name = "stronger-explosives-3", min = 10, max = 14 },
   { name = "follower-robot-count-3", min = 10, max = 14 },
   { name = "physical-projectile-damage-5", min = 10, max = 14 },
   { name = "weapon-shooting-speed-5", min = 10, max = 14 },
   { name = "energy-weapons-damage-2", min = 10, max = 14 },
   { name = "energy-weapons-damage-3", min = 10, max = 14 },
   { name = "energy-weapons-damage-4", min = 10, max = 14 },
   { name = "laser-shooting-speed-3", min = 10, max = 14 },
   { name = "laser-shooting-speed-4", min = 10, max = 14 },
   { name = "follower-robot-count-4", min = 10, max = 14 },

   -- purple research
   { name = "production-science-pack", min = 11, max = 12 },
   { name = "nuclear-fuel-reprocessing", min = 12, max = 19 },
   { name = "effect-transmission", min = 12, max = 19 },
   { name = "automation-3", min = 12, max = 19 },
   { name = "coal-liquefaction", min = 12, max = 19 },
   { name = "braking-force-3", min = 12, max = 19 },
   { name = "inserter-capacity-bonus-4", min = 12, max = 19 },
   { name = "logistics-3", min = 12, max = 19 },
   { name = "worker-robots-storage-2", min = 12, max = 19 },
   { name = "speed-module-3", min = 12, max = 19 },
   { name = "productivity-module-3", min = 12, max = 19 },
   { name = "effectivity-module-3", min = 12, max = 19 },
   { name = "research-speed-5", min = 12, max = 19 },
   { name = "kovarex-enrichment-process", min = 12, max = 19 },
   { name = "inserter-capacity-bonus-5", min = 12, max = 19 },
   { name = "inserter-capacity-bonus-6", min = 12, max = 19 },
   { name = "braking-force-4", min = 12, max = 19 },
   { name = "braking-force-5", min = 12, max = 19 },

   -- yellow research
   { name = "utility-science-pack", min = 13, max = 14 },
   { name = "worker-robots-speed-3", min = 14, max = 21 },
   { name = "worker-robots-speed-4", min = 14, max = 21 },
   { name = "worker-robots-speed-5", min = 14, max = 21 },
   { name = "worker-robots-speed-6", min = 14, max = 21 },
   { name = "personal-roboport-mk2-equipment", min = 14, max = 21 },
   { name = "rocket-control-unit", min = 14, max = 21 },
   { name = "logistic-system", min = 14, max = 21 },
   { name = "military-4", min = 14, max = 21 },
   { name = "fusion-reactor-equipment", min = 14, max = 21 },
   { name = "destroyer", min = 14, max = 21 },
   { name = "refined-flammables-4", min = 14, max = 21 },
   { name = "refined-flammables-5", min = 14, max = 21 },
   { name = "refined-flammables-6", min = 14, max = 21 },
   { name = "stronger-explosives-4", min = 14, max = 21 },
   { name = "stronger-explosives-5", min = 14, max = 21 },
   { name = "stronger-explosives-6", min = 14, max = 21 },
   { name = "power-armor-mk2", min = 14, max = 21 },
   { name = "physical-projectile-damage-6", min = 14, max = 21 },
   { name = "weapon-shooting-speed-6", min = 14, max = 21 },
   { name = "uranium-ammo", min = 14, max = 21 },
   { name = "artillery", min = 14, max = 21 },
   { name = "worker-robots-storage-3", min = 14, max = 21 },
   { name = "research-speed-6", min = 14, max = 21 },
   { name = "mining-productivity-3", min = 14, max = 21 },
   { name = "laser-shooting-speed-5", min = 14, max = 21 },
   { name = "laser-shooting-speed-6", min = 14, max = 21 },
   { name = "laser-shooting-speed-7", min = 14, max = 21 },
   { name = "energy-weapons-damage-5", min = 14, max = 21 },
   { name = "energy-weapons-damage-6", min = 14, max = 21 },
   { name = "follower-robot-count-5", min = 14, max = 21 },
   { name = "follower-robot-count-6", min = 14, max = 21 },
   { name = "braking-force-6", min = 14, max = 21 },
   { name = "braking-force-7", min = 14, max = 21 },
   { name = "inserter-capacity-bonus-7", min = 14, max = 21 },

   -- white science and atomic/spider
   { name = "rocket-silo", min = 19, max = 20 },
   { name = "space-science-pack", min = 19, max = 20 },
   { name = "mining-productivity-4", min = 20, max = 25 },
   { name = "artillery-shell-range-1", min = 20, max = 25 },
   { name = "artillery-shell-speed-1", min = 20, max = 25 },
   { name = "energy-weapons-damage-7", min = 20, max = 25 },
   { name = "physical-projectile-damage-7", min = 20, max = 25 },
   { name = "refined-flammables-7", min = 20, max = 25 },
   { name = "stronger-explosives-7", min = 20, max = 25 },
   { name = "follower-robot-count-7", min = 20, max = 25 },

   { name = "spidertron", min = 22, max = 25 },
   { name = "atomic-bomb", min = 22, max = 25 },

-- --  ["landfill"] = { min = 1, max = 100 },
-- --  ["land-mine"] = { min = 1, max = 100 },
-- --  ["cliff-explosives"] = { min = 1, max = 100 },
}

local function get_research_by_floor(f)
   local res = state.research_by_floor[f]
   if res ~= nil then
      return res
   end
   res = {}
   state.research_by_floor[f] = res
   return res
end

function Variable.calculate_distribution()
   state.research_by_floor = {}
   table.shuffle_table(all_research)
   local technologies = game.forces.player.technologies
   for i = 1, #all_research do
      local v = all_research[i]
      local floor1 = math.random(v.min, v.max)
      local floor2 = math.random(v.min, v.max)
      local res1 = get_research_by_floor(floor1)
      local res2 = get_research_by_floor(floor2)
      local res = res1
      if #res2 < #res1 then
	 res = res2
      end
      technologies[v.name].enabled = false
      technologies[v.name].visible_when_disabled = true
      res[#res+1] = { name = v.name }
      -- game.print('floor ' .. floor .. ' gets tech ' .. k .. ' count=' .. #res)
   end
   -- previous code did rooms_opened > 100 & 2% chance, ~150 mean to find the one tech
   -- this is on average a bit easier, but overall probably harder because of the lack of tech
   for f = 0, #state.research_by_floor do
      local res = state.research_by_floor[f]
      if res ~= nil and #res > 0 then
	 table.shuffle_table(res)
	 if f == 0 then
	    res[#res+1] = res[1]
	    res[1] = { name = "automation", min = 0, max = 0 }
	    technologies["automation"].enabled = false
	    technologies["automation"].visible_when_disabled = true
	 end
	 local room_max = last_research_room_max + math.ceil(f * last_research_floor_scale)
	 local min_room = first_research_room_min + math.floor(f * first_research_floor_scale)
	 local rooms_per_res = math.ceil(room_max - first_research_room_min) / #res

	 for i = 1,#res do
	    local range_min = min_room + rooms_per_res * (i - 1)
	    res[i].room = math.random(range_min, range_min + rooms_per_res - 1)
	 end
      end
   end
end

function Variable.LivePatch()
   local d = dungeon_table()
   Variable.calculate_distribution()
   for f = 0, #state.research_by_floor do
      local res = state.research_by_floor[f]
      local rooms = rooms_opened(f + d.original_surface_index)
      while res ~= nil and #res > 0 and res[1].room <= rooms do
	 local tech = res[1]
	 table.remove(res, 1)
	 game.forces.player.technologies[tech.name].enabled = true
	 game.print('live patch unlocked ' .. tech.name .. ' on floor ' .. f)
      end
   end
end

local function res_to_string(res)
   local ret = {}
   for f = 1, #res do
      ret[f] = res[f].name .. "@" .. res[f].room
   end
   return ret
end

function Variable.dump_techs(max_floor)
   if max_floor == nil then
      max_floor = #state.research_by_floor
   end
   for f = 0, max_floor do
      local res = state.research_by_floor[f]
      if res == nil then
	 game.print('Floor ' .. f .. ': nothing remains')
      else
	 game.print('Floor ' .. f .. ': ' .. #res .. ' ' .. table.concat(res_to_string(res), ' '))
      end
   end
end

function Variable.Init()
   game.difficulty_settings.technology_price_multiplier = tech_scale_start_price
   Variable.calculate_distribution()
end

function Variable.techs_remain(index)
   if state.research_by_floor == nil then
      return -999
   end
   local floor = floor_num(index)

   if state.research_by_floor[floor] == nil then
      return 0
   end
   return #state.research_by_floor[floor]
end

function Variable.relock_research()
   for f = 0, #state.research_by_floor do
      local res = state.research_by_floor[f]
      if res ~= nil then
	 for r = 1, #res do
	    if game.forces.player.technologies[res[r].name].enabled then
	       game.print('BUGFIX: ' .. res[r].name .. ' was incorrectly enabled')
	       game.forces.player.technologies[res[r].name].enabled = false
	    end
	 end
      end
   end
end

function Variable.unlock_research(index)
   Variable.relock_research()
   local floor = floor_num(index)
   local res = state.research_by_floor[floor]
   if res == nil or #res == 0 then
      game.print('BUG: tried to unlock research on ' .. index .. ' but none remain')
      return
   end
   local tech = res[1]
   table.remove(res, 1)
   if game.forces.player.technologies[tech.name].enabled then
      game.print('BUG: attempt to duplicate-unlock technology ' .. tech.name)
      return
   end
   game.forces.player.technologies[tech.name].enabled = true
   game.print({'dungeons_tiered.tech_unlock', '[technology=' .. tech.name .. ']', floor})
   local floor_fraction = (tech_scale_end_level - floor) / tech_scale_end_level
   if floor_fraction < 0 then
      floor_fraction = 0
   end
   local tech_multiplier = tech_scale_end_price +
      (tech_scale_start_price - tech_scale_end_price) * floor_fraction
   if tech_multiplier < game.difficulty_settings.technology_price_multiplier then
      game.difficulty_settings.technology_price_multiplier = tech_multiplier
      game.print('Finding technology on floor ' .. floor .. ' made research easier')
   end
   Variable.relock_research()
end

function Variable.room_is_lab(index)
   local res = state.research_by_floor[floor_num(index)]

   if res == nil or #res == 0 then
      return false
   end
   if game.forces.player.technologies[res[1].name].enabled then
      game.print('BUG: attempt to duplicate-unlock technology ' .. res[1].name)
      return false
   end
   return rooms_opened(index) >= res[1].room
end

function Variable.noop()
end
Variable.noop() -- eliminate luacheck warning if return Fixed is used

-- return Fixed
return Variable
