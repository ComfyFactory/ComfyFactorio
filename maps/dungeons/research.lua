--- Tuning factors
local target_room_min = 100
local target_room_floor_scale = 5
---

local Global = require 'utils.global'
local DungeonsTable = require 'maps.dungeons.table'

local function dungeon_table()
   return DungeonsTable.get_dungeontable()
end

local function floorNum(index)
   return index - dungeon_table().original_surface_index
end

local function floorSize(index)
   return dungeon_table().surface_size[index]
end

local function roomsOpened(index)
   local d = dungeon_table()
   local f = index - d.original_surface_index
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
    for _, tech in pairs(locked_researches) do
        game.forces.player.technologies[tech].enabled = false
    end
end

local function get_surface_research(index) 
   return locked_researches[floorNum(index)]
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
        game.print({'dungeons_tiered.tech_unlock', '[technology=' .. tech .. ']', floorNum(surface_index)})
    end
end

function Fixed.room_is_lab(index)
   if floorSize(index) < 225 or math.random(1, 50) ~= 1 then
      return false
   end
   local tech = get_surface_research(index)
   return tech and game.forces.player.technologies[tech].enabled == false
end

-- Variant 2, all research needs unlocking, several can be found on each floor
-- and the research is semi-randomly distributed. Research packs occur at the
-- first half of the ranges.
--
-- target most research found by floor 25; atomic bomb and spidertron 25-35
-- red(0-4), green(3-7), gray(6-10), blue(9-13),
-- blue/gray (10-14), purple(12-19), yellow(14-21), white(20-25)

local state = {}
local Variable = {}

Global.register(state, function(s) state = s end)

local all_research = {
   -- always found on 0
   ["automation"] = { min = 0, max = 0 },
   ["gun-turret"] = { min = 0, max = 0 },
   ["logistics"] = { min = 0, max = 0 },
   -- always 0 or 1, important for progressing
   ["military"] = { min = 0, max = 1 },
   ["stone-wall"] = { min = 0, max = 1 },

   -- red research
   ["steel-axe"] = { min = 1, max = 4 },
   ["optics"] = { min = 1, max = 4 },
   ["steel-processing"] = { min = 1, max = 4 },
   ["electronics"] = { min = 1, max = 4 },
   ["fast-inserter"] = { min = 1, max = 4 },
   ["weapon-shooting-speed-1"] = { min = 1, max = 4 },
   ["physical-projectile-damage-1"] = { min = 1, max = 4 },
   ["heavy-armor"] = { min = 1, max = 4 },

   -- green research
   ["logistic-science-pack"] = { min = 3, max = 5 },
   ["military-2"] = { min = 3, max = 7 },
   ["automation-2"] = { min = 3, max = 7 },
   ["fluid-handling"] = { min = 3, max = 7 },
   ["flammables"] = { min = 3, max = 7 },
   ["battery-equipment"] = { min = 3, max = 7 },
   ["modules"] = { min = 3, max = 7 },
   ["speed-module"] = { min = 3, max = 7 },
   ["productivity-module"] = { min = 3, max = 7 },
   ["effectivity-module"] = { min = 3, max = 7 },
   ["advanced-material-processing"] = { min = 3, max = 7 },
   ["circuit-network"] = { min = 3, max = 7 },
   ["explosives"] = { min = 3, max = 7 },
   ["toolbelt"] = { min = 3, max = 7 },
   ["engine"] = { min = 3, max = 7 },
   ["oil-processing"] = { min = 3, max = 7 },
   ["stronger-explosives-1"] = { min = 3, max = 7 },
   ["modular-armor"] = { min = 3, max = 7 },
   ["solar-panel-equipment"] = { min = 3, max = 7 },
   ["electric-energy-distribution-1"] = { min = 3, max = 7 },
   ["battery"] = { min = 3, max = 7 },
   ["electric-energy-accumulators"] = { min = 3, max = 7 },
   ["stack-inserter"] = { min = 3, max = 7 },
   ["sulfur-processing"] = { min = 3, max = 7 },
   ["advanced-electronics"] = { min = 3, max = 7 },
   ["logistics-2"] = { min = 3, max = 7 },
   ["plastics"] = { min = 3, max = 7 },
   ["physical-projectile-damage-2"] = { min = 3, max = 7 },
   ["weapon-shooting-speed-2"] = { min = 3, max = 7 },
   ["solar-energy"] = { min = 3, max = 7 },
   ["mining-productivity-1"] = { min = 3, max = 7 },

   ["night-vision-equipment"] = { min = 3, max = 7 },
   ["belt-immunity-equipment"] = { min = 3, max = 7 },
   ["railway"] = { min = 3, max = 7 },
   ["automated-rail-transportation"] = { min = 3, max = 7 },
   ["gate"] = { min = 3, max = 7 },
   ["rail-signals"] = { min = 3, max = 7 },
   ["research-speed-1"] = { min = 3, max = 7 },
   ["automobilism"] = { min = 3, max = 7 },
   ["fluid-wagon"] = { min = 3, max = 7 },
   ["inserter-capacity-bonus-1"] = { min = 3, max = 7 },
   ["concrete"] = { min = 3, max = 7 },
   ["research-speed-2"] = { min = 3, max = 7 },
   ["inserter-capacity-bonus-2"] = { min = 3, max = 7 },

   -- gray research
   ["military-science-pack"] = { min = 6, max = 8 },
   ["flamethrower"] = { min = 6, max = 10 },
   ["refined-flammables-1"] = { min = 6, max = 10 },
   ["defender"] = { min = 6, max = 10 },
   ["rocketry"] = { min = 6, max = 10 },
   ["energy-shield-equipment"] = { min = 6, max = 10 },
   ["stronger-explosives-2"] = { min = 6, max = 10 },
   ["follower-robot-count-1"] = { min = 6, max = 10 },
   ["physical-projectile-damage-3"] = { min = 6, max = 10 },
   ["weapon-shooting-speed-3"] = { min = 6, max = 10 },
   ["refined-flammables-2"] = { min = 6, max = 10 },
   ["follower-robot-count-2"] = { min = 6, max = 10 },
   ["physical-projectile-damage-4"] = { min = 6, max = 10 },
   ["weapon-shooting-speed-4"] = { min = 6, max = 10 },

   -- blue research
   ["chemical-science-pack"] = { min = 9, max = 11 },
   ["electric-engine"] = { min = 9, max = 13 },
   ["lubricant"] = { min = 9, max = 13 },
   ["personal-roboport-equipment"] = { min = 9, max = 13 },
   ["worker-robots-speed-1"] = { min = 9, max = 13 },
   ["exoskeleton-equipment"] = { min = 9, max = 13 },
   ["robotics"] = { min = 9, max = 13 },
   ["advanced-oil-processing"] = { min = 9, max = 13 },
   ["speed-module-2"] = { min = 9, max = 13 },
   ["productivity-module-2"] = { min = 9, max = 13 },
   ["effectivity-module-2"] = { min = 9, max = 13 },
   ["laser"] = { min = 9, max = 13 },
   ["braking-force-1"] = { min = 9, max = 13 },
   ["electric-energy-distribution-2"] = { min = 9, max = 13 },
   ["construction-robotics"] = { min = 9, max = 13 },
   ["battery-mk2-equipment"] = { min = 9, max = 13 },
   ["worker-robots-storage-1"] = { min = 9, max = 13 },
   ["uranium-processing"] = { min = 9, max = 13 },
   ["power-armor"] = { min = 9, max = 13 },
   ["advanced-material-processing-2"] = { min = 9, max = 13 },
   ["logistic-robotics"] = { min = 9, max = 13 },
   ["research-speed-3"] = { min = 9, max = 13 },
   ["inserter-capacity-bonus-3"] = { min = 9, max = 13 },
   ["advanced-electronics-2"] = { min = 9, max = 13 },
   ["low-density-structure"] = { min = 9, max = 13 },
   ["rocket-fuel"] = { min = 9, max = 13 },
   ["mining-productivity-2"] = { min = 9, max = 13 },
   ["nuclear-power"] = { min = 9, max = 13 },
   ["worker-robots-speed-2"] = { min = 9, max = 13 },
   ["braking-force-2"] = { min = 9, max = 13 },
   ["research-speed-4"] = { min = 9, max = 13 },

   -- blue/gray research
   ["laser-shooting-speed-1"] = { min = 10, max = 14 },
   ["military-3"] = { min = 10, max = 14 },
   ["explosive-rocketry"] = { min = 10, max = 14 },
   ["energy-weapons-damage-1"] = { min = 10, max = 14 },
   ["laser-shooting-speed-2"] = { min = 10, max = 14 },
   ["personal-laser-defense-equipment"] = { min = 10, max = 14 },
   ["discharge-defense-equipment"] = { min = 10, max = 14 },
   ["laser-turret"] = { min = 10, max = 14 },
   ["distractor"] = { min = 10, max = 14 },
   ["energy-shield-mk2-equipment"] = { min = 10, max = 14 },
   ["tank"] = { min = 10, max = 14 },
   ["refined-flammables-3"] = { min = 10, max = 14 },
   ["stronger-explosives-3"] = { min = 10, max = 14 },
   ["follower-robot-count-3"] = { min = 10, max = 14 },
   ["physical-projectile-damage-5"] = { min = 10, max = 14 },
   ["weapon-shooting-speed-5"] = { min = 10, max = 14 },
   ["energy-weapons-damage-2"] = { min = 10, max = 14 },
   ["energy-weapons-damage-3"] = { min = 10, max = 14 },
   ["energy-weapons-damage-4"] = { min = 10, max = 14 },
   ["laser-shooting-speed-3"] = { min = 10, max = 14 },
   ["laser-shooting-speed-4"] = { min = 10, max = 14 },
   ["follower-robot-count-4"] = { min = 10, max = 14 },

   -- purple research
   ["production-science-pack"] = { min = 12, max = 14 },
   ["nuclear-fuel-reprocessing"] = { min = 12, max = 19 },
   ["effect-transmission"] = { min = 12, max = 19 },
   ["automation-3"] = { min = 12, max = 19 },
   ["coal-liquefaction"] = { min = 12, max = 19 },
   ["braking-force-3"] = { min = 12, max = 19 },
   ["inserter-capacity-bonus-4"] = { min = 12, max = 19 },
   ["logistics-3"] = { min = 12, max = 19 },
   ["worker-robots-storage-2"] = { min = 12, max = 19 },
   ["speed-module-3"] = { min = 12, max = 19 },
   ["productivity-module-3"] = { min = 12, max = 19 },
   ["effectivity-module-3"] = { min = 12, max = 19 },
   ["research-speed-5"] = { min = 12, max = 19 },
   ["kovarex-enrichment-process"] = { min = 12, max = 19 },
   ["inserter-capacity-bonus-5"] = { min = 12, max = 19 },
   ["inserter-capacity-bonus-6"] = { min = 12, max = 19 },
   ["braking-force-4"] = { min = 12, max = 19 },
   ["braking-force-5"] = { min = 12, max = 19 },

   -- yellow research
   ["utility-science-pack"] = { min = 14, max = 16 },
   ["worker-robots-speed-3"] = { min = 14, max = 21 },
   ["worker-robots-speed-4"] = { min = 14, max = 21 },
   ["worker-robots-speed-5"] = { min = 14, max = 21 },
   ["worker-robots-speed-6"] = { min = 14, max = 21 },
   ["personal-roboport-mk2-equipment"] = { min = 14, max = 21 },
   ["rocket-control-unit"] = { min = 14, max = 21 },
   ["logistic-system"] = { min = 14, max = 21 },
   ["military-4"] = { min = 14, max = 21 },
   ["fusion-reactor-equipment"] = { min = 14, max = 21 },
   ["destroyer"] = { min = 14, max = 21 },
   ["refined-flammables-4"] = { min = 14, max = 21 },
   ["refined-flammables-5"] = { min = 14, max = 21 },
   ["refined-flammables-6"] = { min = 14, max = 21 },
   ["stronger-explosives-4"] = { min = 14, max = 21 },
   ["stronger-explosives-5"] = { min = 14, max = 21 },
   ["stronger-explosives-6"] = { min = 14, max = 21 },
   ["power-armor-mk2"] = { min = 14, max = 21 },
   ["physical-projectile-damage-6"] = { min = 14, max = 21 },
   ["weapon-shooting-speed-6"] = { min = 14, max = 21 },
   ["uranium-ammo"] = { min = 14, max = 21 },
   ["artillery"] = { min = 14, max = 21 },
   ["worker-robots-storage-3"] = { min = 14, max = 21 },
   ["research-speed-6"] = { min = 14, max = 21 },
   ["mining-productivity-3"] = { min = 14, max = 21 },
   ["laser-shooting-speed-5"] = { min = 14, max = 21 },
   ["laser-shooting-speed-6"] = { min = 14, max = 21 },
   ["laser-shooting-speed-7"] = { min = 14, max = 21 },
   ["energy-weapons-damage-5"] = { min = 14, max = 21 },
   ["energy-weapons-damage-6"] = { min = 14, max = 21 },
   ["follower-robot-count-5"] = { min = 14, max = 21 },
   ["follower-robot-count-6"] = { min = 14, max = 21 },
   ["braking-force-6"] = { min = 14, max = 21 },
   ["braking-force-7"] = { min = 14, max = 21 },
   ["inserter-capacity-bonus-7"] = { min = 14, max = 21 },

   -- white science and atomic/spider
   ["space-science-pack"] = { min = 20, max = 22 },
   ["rocket-silo"] = { min = 20, max = 22 },
   ["mining-productivity-4"] = { min = 20, max = 25 },
   ["artillery-shell-range-1"] = { min = 20, max = 25 },
   ["artillery-shell-speed-1"] = { min = 20, max = 25 },
   ["energy-weapons-damage-7"] = { min = 20, max = 25 },
   ["physical-projectile-damage-7"] = { min = 20, max = 25 },
   ["refined-flammables-7"] = { min = 20, max = 25 },
   ["stronger-explosives-7"] = { min = 20, max = 25 },
   ["follower-robot-count-7"] = { min = 20, max = 25 },

   ["spidertron"] = { min = 22, max = 25 },
   ["atomic-bomb"] = { min = 22, max = 25 },

-- --  ["landfill"] = { min = 1, max = 100 },
-- --  ["land-mine"] = { min = 1, max = 100 },
-- --  ["cliff-explosives"] = { min = 1, max = 100 },
}

function Variable.calculate_distribution()
   state.research_by_floor = {}
   for k, v in pairs(all_research) do
      floor = math.random(v.min, v.max)
      res = state.research_by_floor[floor]
      if res == nil then
	 res = {}
	 state.research_by_floor[floor] = res
      end
      game.forces.player.technologies[k].enabled = false
      res[#res+1] = { name = k }
      -- game.print('floor ' .. floor .. ' gets tech ' .. k .. ' count=' .. #res)
   end
   -- previous code did rooms_opened > 100 & 2% chance, ~150 mean to find the one tech
   -- this is on average a bit easier, but overall probably harder because of the lack of tech
   for f = 0, #state.research_by_floor do
      res = state.research_by_floor[f]
      if res ~= nil and #res > 0 then
	 table.shuffle_table(res)
	 target_rooms = target_room_min + f * target_room_floor_scale
	 min_room = math.ceil(target_rooms/3)
	 rooms_per_res = math.ceil(target_rooms - min_room) / #res

	 for i = 1,#res do
	    local range_min = min_room + rooms_per_res * (i - 1)
	    res[i].room = math.random(range_min, range_min + rooms_per_res - 1)
	 end
      end
   end

   Variable.dump_techs()
end

local function res_to_string(res)
   ret = {}
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
      res = state.research_by_floor[f]
      if res == nil then
	 game.print('Floor ' .. f .. ': nothing remains')
      else
	 game.print('Floor ' .. f .. ': ' .. #res .. ' ' .. table.concat(res_to_string(res), ' '))
      end
   end
end

function Variable.Init()
   Variable.calculate_distribution()
end

function Variable.techs_remain(index)
   if state.research_by_floor == nil then
      return -999
   end
   floor = floorNum(index)

   return #state.research_by_floor[floor]
end

function Variable.unlock_research(index)
   floor = floorNum(index)
   res = state.research_by_floor[floor]
   if res == nil or #res == 0 then
      game.print('BUG: tried to unlock research on ' .. index .. ' but none remain')
      return
   end
   tech = res[1]
   table.remove(res, 1)
   if game.forces.player.technologies[tech.name].enabled then
      game.print('BUG: attempt to duplicate-unlock technology ' .. tech.name)
      return
   end
   game.forces.player.technologies[tech.name].enabled = true
   game.print({'dungeons_tiered.tech_unlock', '[technology=' .. tech.name .. ']', floor})
end

function Variable.room_is_lab(index)
   res = state.research_by_floor[floorNum(index)]

   if #res == 0 then
      return false
   end
   if game.forces.player.technologies[res[1].name].enabled then
      game.print('BUG: attempt to duplicate-unlock technology ' .. res[1].name)
      return false
   end
   return roomsOpened(index) >= res[1].room
end

return Variable
