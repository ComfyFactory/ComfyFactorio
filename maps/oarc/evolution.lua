local Public = {}
local log10 = math.log10
local random = math.random
local max = math.max
local round = math.round

local MT = require 'maps.oarc.table'
local MtUtils = require 'maps.oarc.ms_utils'
local Utils = require 'utils.utils'
local Event = require 'utils.event'
local Surface = require 'utils.surface'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'

local biters =
{
    [1] = 'small-biter',
    [2] = 'medium-biter',
    [3] = 'big-biter',
    [4] = 'behemoth-biter'
}

local spitters =
{
    [1] = 'small-spitter',
    [2] = 'medium-spitter',
    [3] = 'big-spitter',
    [4] = 'behemoth-spitter'
}

local worms =
{
    [1] = 'small-worm-turret',
    [2] = 'medium-worm-turret',
    [3] = 'big-worm-turret',
    [4] = 'behemoth-worm-turret'
}

-- evolution max distance in tiles
local max_evolution_distance = 1024
-- max_factor < 1.0 means technology sum of weights will be greater than 1.0
local max_factor = 0.8

-- technology weights (biter, spitter, worm)
local technology_weights =
{
    ['advanced-electronics'] = { biter = 1, spitter = 1, worm = 1 },
    ['advanced-electronics-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['advanced-material-processing'] = { biter = 1, spitter = 1, worm = 1 },
    ['advanced-material-processing-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['advanced-oil-processing'] = { biter = 1, spitter = 1, worm = 1 },
    ['artillery'] = { biter = 1, spitter = 1, worm = 1 },
    ['artillery-shell-range-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['artillery-shell-speed-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['atomic-bomb'] = { biter = 1, spitter = 1, worm = 1 },
    ['automated-rail-transportation'] = { biter = 1, spitter = 1, worm = 1 },
    ['automation'] = { biter = 1, spitter = 1, worm = 1 },
    ['automation-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['automation-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['automobilism'] = { biter = 1, spitter = 1, worm = 1 },
    ['battery'] = { biter = 1, spitter = 1, worm = 1 },
    ['battery-equipment'] = { biter = 1, spitter = 1, worm = 1 },
    ['battery-mk2-equipment'] = { biter = 1, spitter = 1, worm = 1 },
    ['belt-immunity-equipment'] = { biter = 1, spitter = 1, worm = 1 },
    ['braking-force-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['braking-force-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['braking-force-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['braking-force-4'] = { biter = 1, spitter = 1, worm = 1 },
    ['braking-force-5'] = { biter = 1, spitter = 1, worm = 1 },
    ['braking-force-6'] = { biter = 1, spitter = 1, worm = 1 },
    ['braking-force-7'] = { biter = 1, spitter = 1, worm = 1 },
    ['chemical-science-pack'] = { biter = 125, spitter = 125, worm = 125 },
    ['circuit-network'] = { biter = 1, spitter = 1, worm = 1 },
    ['cliff-explosives'] = { biter = 1, spitter = 1, worm = 1 },
    ['coal-liquefaction'] = { biter = 1, spitter = 1, worm = 1 },
    ['concrete'] = { biter = 1, spitter = 1, worm = 1 },
    ['construction-robotics'] = { biter = 1, spitter = 1, worm = 1 },
    ['defender'] = { biter = 1, spitter = 1, worm = 1 },
    ['destroyer'] = { biter = 1, spitter = 1, worm = 1 },
    ['discharge-defense-equipment'] = { biter = 5, spitter = 5, worm = 5 },
    ['distractor'] = { biter = 1, spitter = 1, worm = 1 },
    ['effect-transmission'] = { biter = 1, spitter = 1, worm = 1 },
    ['efficiency-module'] = { biter = 1, spitter = 1, worm = 1 },
    ['efficiency-module-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['efficiency-module-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['electric-energy-accumulators'] = { biter = 1, spitter = 1, worm = 1 },
    ['electric-energy-distribution-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['electric-energy-distribution-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['electric-engine'] = { biter = 1, spitter = 1, worm = 1 },
    ['electronics'] = { biter = 1, spitter = 1, worm = 1 },
    ['energy-shield-equipment'] = { biter = 5, spitter = 5, worm = 5 },
    ['energy-shield-mk2-equipment'] = { biter = 5, spitter = 5, worm = 5 },
    ['energy-weapons-damage-1'] = { biter = 5, spitter = 5, worm = 5 },
    ['energy-weapons-damage-2'] = { biter = 5, spitter = 5, worm = 5 },
    ['energy-weapons-damage-3'] = { biter = 5, spitter = 5, worm = 5 },
    ['energy-weapons-damage-4'] = { biter = 5, spitter = 5, worm = 5 },
    ['energy-weapons-damage-5'] = { biter = 5, spitter = 5, worm = 5 },
    ['energy-weapons-damage-6'] = { biter = 5, spitter = 5, worm = 5 },
    ['energy-weapons-damage-7'] = { biter = 5, spitter = 5, worm = 5 },
    ['engine'] = { biter = 1, spitter = 1, worm = 1 },
    ['exoskeleton-equipment'] = { biter = 5, spitter = 5, worm = 5 },
    ['explosive-rocketry'] = { biter = 1, spitter = 1, worm = 1 },
    ['explosives'] = { biter = 5, spitter = 5, worm = 5 },
    ['fast-inserter'] = { biter = 1, spitter = 1, worm = 1 },
    ['flamethrower'] = { biter = 5, spitter = 5, worm = 5 },
    ['flammables'] = { biter = 1, spitter = 1, worm = 1 },
    ['fluid-handling'] = { biter = 1, spitter = 1, worm = 1 },
    ['fluid-wagon'] = { biter = 1, spitter = 1, worm = 1 },
    ['follower-robot-count-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['follower-robot-count-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['follower-robot-count-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['follower-robot-count-4'] = { biter = 1, spitter = 1, worm = 1 },
    ['follower-robot-count-5'] = { biter = 1, spitter = 1, worm = 1 },
    ['follower-robot-count-6'] = { biter = 1, spitter = 1, worm = 1 },
    ['follower-robot-count-7'] = { biter = 1, spitter = 1, worm = 1 },
    ['fusion-reactor-equipment'] = { biter = 1, spitter = 1, worm = 1 },
    ['gate'] = { biter = 1, spitter = 1, worm = 1 },
    ['gun-turret'] = { biter = 1, spitter = 1, worm = 1 },
    ['heavy-armor'] = { biter = 5, spitter = 5, worm = 5 },
    ['inserter-capacity-bonus-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['inserter-capacity-bonus-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['inserter-capacity-bonus-4'] = { biter = 1, spitter = 1, worm = 1 },
    ['inserter-capacity-bonus-5'] = { biter = 1, spitter = 1, worm = 1 },
    ['inserter-capacity-bonus-6'] = { biter = 1, spitter = 1, worm = 1 },
    ['inserter-capacity-bonus-7'] = { biter = 1, spitter = 1, worm = 1 },
    ['kovarex-enrichment-process'] = { biter = 1, spitter = 1, worm = 1 },
    ['land-mine'] = { biter = 5, spitter = 5, worm = 5 },
    ['landfill'] = { biter = 1, spitter = 1, worm = 1 },
    ['laser'] = { biter = 5, spitter = 5, worm = 5 },
    ['laser-shooting-speed-1'] = { biter = 5, spitter = 5, worm = 5 },
    ['laser-shooting-speed-2'] = { biter = 5, spitter = 5, worm = 5 },
    ['laser-shooting-speed-3'] = { biter = 5, spitter = 5, worm = 5 },
    ['laser-shooting-speed-4'] = { biter = 5, spitter = 5, worm = 5 },
    ['laser-shooting-speed-5'] = { biter = 5, spitter = 5, worm = 5 },
    ['laser-shooting-speed-6'] = { biter = 5, spitter = 5, worm = 5 },
    ['laser-shooting-speed-7'] = { biter = 5, spitter = 5, worm = 5 },
    ['laser-turret'] = { biter = 5, spitter = 5, worm = 5 },
    ['logistic-robotics'] = { biter = 1, spitter = 1, worm = 1 },
    ['logistic-science-pack'] = { biter = 25, spitter = 25, worm = 25 },
    ['logistic-system'] = { biter = 1, spitter = 1, worm = 1 },
    ['logistics'] = { biter = 1, spitter = 1, worm = 1 },
    ['logistics-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['logistics-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['low-density-structure'] = { biter = 1, spitter = 1, worm = 1 },
    ['lubricant'] = { biter = 1, spitter = 1, worm = 1 },
    ['military'] = { biter = 5, spitter = 5, worm = 5 },
    ['military-2'] = { biter = 5, spitter = 5, worm = 5 },
    ['military-3'] = { biter = 5, spitter = 5, worm = 51 },
    ['military-4'] = { biter = 5, spitter = 5, worm = 5 },
    ['military-science-pack'] = { biter = 50, spitter = 50, worm = 50 },
    ['mining-productivity-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['mining-productivity-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['mining-productivity-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['mining-productivity-4'] = { biter = 1, spitter = 1, worm = 1 },
    ['modular-armor'] = { biter = 1, spitter = 1, worm = 1 },
    ['modules'] = { biter = 1, spitter = 1, worm = 1 },
    ['night-vision-equipment'] = { biter = 1, spitter = 1, worm = 1 },
    ['nuclear-fuel-reprocessing'] = { biter = 1, spitter = 1, worm = 1 },
    ['nuclear-power'] = { biter = 1, spitter = 1, worm = 1 },
    ['oil-processing'] = { biter = 1, spitter = 1, worm = 1 },
    ['optics'] = { biter = 1, spitter = 1, worm = 1 },
    ['personal-laser-defense-equipment'] = { biter = 5, spitter = 5, worm = 5 },
    ['personal-roboport-equipment'] = { biter = 1, spitter = 1, worm = 1 },
    ['personal-roboport-mk2-equipment'] = { biter = 1, spitter = 1, worm = 1 },
    ['physical-projectile-damage-1'] = { biter = 5, spitter = 5, worm = 5 },
    ['physical-projectile-damage-2'] = { biter = 5, spitter = 5, worm = 5 },
    ['physical-projectile-damage-3'] = { biter = 5, spitter = 5, worm = 5 },
    ['physical-projectile-damage-4'] = { biter = 5, spitter = 5, worm = 5 },
    ['physical-projectile-damage-5'] = { biter = 5, spitter = 5, worm = 5 },
    ['physical-projectile-damage-6'] = { biter = 5, spitter = 5, worm = 5 },
    ['physical-projectile-damage-7'] = { biter = 5, spitter = 5, worm = 5 },
    ['plastics'] = { biter = 1, spitter = 1, worm = 1 },
    ['power-armor'] = { biter = 5, spitter = 5, worm = 5 },
    ['power-armor-mk2'] = { biter = 5, spitter = 5, worm = 5 },
    ['production-science-pack'] = { biter = 250, spitter = 250, worm = 250 },
    ['productivity-module'] = { biter = 1, spitter = 1, worm = 1 },
    ['productivity-module-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['productivity-module-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['rail-signals'] = { biter = 1, spitter = 1, worm = 1 },
    ['railway'] = { biter = 1, spitter = 1, worm = 1 },
    ['refined-flammables-1'] = { biter = 5, spitter = 5, worm = 5 },
    ['refined-flammables-2'] = { biter = 5, spitter = 5, worm = 51 },
    ['refined-flammables-3'] = { biter = 5, spitter = 5, worm = 5 },
    ['refined-flammables-4'] = { biter = 5, spitter = 5, worm = 5 },
    ['refined-flammables-5'] = { biter = 5, spitter = 5, worm = 5 },
    ['refined-flammables-6'] = { biter = 5, spitter = 5, worm = 5 },
    ['refined-flammables-7'] = { biter = 5, spitter = 5, worm = 51 },
    ['research-speed-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['research-speed-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['research-speed-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['research-speed-4'] = { biter = 1, spitter = 1, worm = 1 },
    ['research-speed-5'] = { biter = 1, spitter = 1, worm = 1 },
    ['research-speed-6'] = { biter = 1, spitter = 1, worm = 1 },
    ['robotics'] = { biter = 1, spitter = 1, worm = 1 },
    ['rocket-control-unit'] = { biter = 1, spitter = 1, worm = 1 },
    ['rocket-fuel'] = { biter = 1, spitter = 1, worm = 1 },
    ['rocket-silo'] = { biter = 1, spitter = 1, worm = 1 },
    ['rocketry'] = { biter = 1, spitter = 1, worm = 1 },
    ['solar-energy'] = { biter = 1, spitter = 1, worm = 1 },
    ['solar-panel-equipment'] = { biter = 1, spitter = 1, worm = 1 },
    ['space-science-pack'] = { biter = 1000, spitter = 1000, worm = 1000 },
    ['speed-module'] = { biter = 1, spitter = 1, worm = 1 },
    ['speed-module-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['speed-module-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['spidertron'] = { biter = 1, spitter = 1, worm = 1 },
    ['stack-inserter'] = { biter = 1, spitter = 1, worm = 1 },
    ['steel-axe'] = { biter = 1, spitter = 1, worm = 1 },
    ['steel-processing'] = { biter = 1, spitter = 1, worm = 1 },
    ['stone-wall'] = { biter = 1, spitter = 1, worm = 1 },
    ['stronger-explosives-1'] = { biter = 5, spitter = 5, worm = 5 },
    ['stronger-explosives-2'] = { biter = 5, spitter = 5, worm = 5 },
    ['stronger-explosives-3'] = { biter = 5, spitter = 5, worm = 5 },
    ['stronger-explosives-4'] = { biter = 5, spitter = 5, worm = 5 },
    ['stronger-explosives-5'] = { biter = 5, spitter = 5, worm = 5 },
    ['stronger-explosives-6'] = { biter = 5, spitter = 5, worm = 5 },
    ['stronger-explosives-7'] = { biter = 5, spitter = 5, worm = 51 },
    ['sulfur-processing'] = { biter = 1, spitter = 1, worm = 1 },
    ['tank'] = { biter = 1, spitter = 1, worm = 1 },
    ['toolbelt'] = { biter = 1, spitter = 1, worm = 1 },
    ['uranium-ammo'] = { biter = 1, spitter = 1, worm = 1 },
    ['uranium-processing'] = { biter = 1, spitter = 1, worm = 1 },
    ['utility-science-pack'] = { biter = 500, spitter = 500, worm = 500 },
    ['weapon-shooting-speed-1'] = { biter = 5, spitter = 5, worm = 5 },
    ['weapon-shooting-speed-2'] = { biter = 5, spitter = 5, worm = 5 },
    ['weapon-shooting-speed-3'] = { biter = 5, spitter = 5, worm = 5 },
    ['weapon-shooting-speed-4'] = { biter = 5, spitter = 5, worm = 5 },
    ['weapon-shooting-speed-5'] = { biter = 5, spitter = 5, worm = 5 },
    ['weapon-shooting-speed-6'] = { biter = 5, spitter = 5, worm = 5 },
    ['worker-robots-speed-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['worker-robots-speed-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['worker-robots-speed-3'] = { biter = 1, spitter = 1, worm = 1 },
    ['worker-robots-speed-4'] = { biter = 1, spitter = 1, worm = 1 },
    ['worker-robots-speed-5'] = { biter = 1, spitter = 1, worm = 1 },
    ['worker-robots-speed-6'] = { biter = 1, spitter = 1, worm = 1 },
    ['worker-robots-storage-1'] = { biter = 1, spitter = 1, worm = 1 },
    ['worker-robots-storage-2'] = { biter = 1, spitter = 1, worm = 1 },
    ['worker-robots-storage-3'] = { biter = 1, spitter = 1, worm = 1 }
}

local max_biter_weight = 0
local max_spitter_weight = 0
local max_worm_weight = 0
for _, weight in pairs(technology_weights) do
    max_biter_weight = max_biter_weight + weight.biter
    max_spitter_weight = max_spitter_weight + weight.spitter
    max_worm_weight = max_worm_weight + weight.worm
end
max_biter_weight = max_biter_weight * max_factor
max_spitter_weight = max_spitter_weight * max_factor
max_worm_weight = max_worm_weight * max_factor

local function clear_all_attacks_for_towns()
    local towns = MT.get('towns')

    for _, town in pairs(towns) do
        town.attacked = false
    end
end

local function log_err(str)
    local evolution_settings = MT.get('evolution_settings')
    if evolution_settings.log then
        print(str)
    end
end

local function spawn_enemy_with_health_boost(town, biter)
    if not town then
        return
    end
    local unit_settings = BiterHealthBooster.get('unit_settings')
    if not unit_settings then
        return
    end
    local modified_unit_health = (town.evolution.biters + town.evolution.spitters + town.evolution.worms) * 5
    local unit_type = 'units'

    if biter and biter.type == 'turret' then
        unit_type = 'worms'
    end

    if random(1, 30) == 1 then
        local final_health = round(modified_unit_health * (unit_settings[unit_type][biter.name] + 1), 3)
        if final_health < 1 then
            final_health = 1
        end
        log_err('final_health - boss: ' .. biter.name .. ' with h-m: ' .. final_health)

        BiterHealthBooster.add_boss_unit(biter, final_health, 0.38)
    else
        local final_health = round(modified_unit_health * unit_settings[unit_type][biter.name], 3)
        if final_health < 1 then
            final_health = 1
        end
        log_err('final_health - unit: ' .. biter.name .. ' with h-m: ' .. final_health)
        BiterHealthBooster.add_unit(biter, final_health)
    end
end

local function is_nighttime()
    local evolution_settings = MT.get('evolution_settings')
    if not evolution_settings.night_time_only then
        return true
    end

    local surface_index = Surface.get_surface_index()
    local surface = game.get_surface(surface_index)
    if not surface or not surface.valid then
        return
    end
    if surface.daytime >= 0.4 and surface.daytime <= 0.6 then
        return true
    end
    return false
end

local function is_on_tick_check_enabled()
    local evolution_settings = MT.get('evolution_settings')
    return evolution_settings.on_tick_check
end

local function create_unit_group(town, surface, position)
    if random(1, 32) ~= 1 then
        return
    end

    local group = surface.create_unit_group({ position = position })
    local to_add = random(1, 10)
    local count = 0

    local area =
    {
        left_top = { x = group.position.x - 50, y = group.position.y - 50 },
        right_bottom = { x = group.position.x + 50, y = group.position.y + 50 }
    }

    for _, unit in pairs(group.surface.find_entities_filtered { area = area, type = 'unit', force = 'enemy' }) do
        if unit and unit.valid then
            count = count + 1
            if count > to_add then
                break
            end
            unit.ai_settings.allow_try_return_to_spawner = true
            group.add_member(unit)
        end
    end

    group.set_command(
        {
            type = defines.command.attack_area,
            destination = town.position,
            radius = 32,
            distraction = defines.distraction.by_anything
        }
    )
end

local function get_town_evolution(town)
    if town.evolution then
        local evo = town.evolution
        if evo.biters == 0 or evo.spitters == 0 or evo.worms == 0 then
            return false
        end
        return true
    end
end

local function set_town_attacked(town)
    local evolution_settings = MT.get('evolution_settings')

    town.attacked = true
    town.grace = game.tick + evolution_settings.towns_grace
    log_err('set_town_attacked - ' .. town.owner .. ' is being attacked!')
end

local function get_town_near_position(position)
    if not is_nighttime() then
        return log_err('get_town_near_position - not nighttime')
    end
    local towns = MT.get('towns')
    local evolution_settings = MT.get('evolution_settings')
    local found_town
    local radius = evolution_settings.radius
    local find_town_tries = 10
    local current_tries = 0
    ::retry::
    for _, town in pairs(towns) do
        if town and town.position then
            if get_town_evolution(town) and not town.attacked then
                local area =
                {
                    left_top = { x = town.position.x - radius, y = town.position.y - radius },
                    right_bottom = { x = town.position.x + radius, y = town.position.y + radius }
                }

                if Utils.inside(position, area) then
                    if town.grace and game.tick <= town.grace then
                        found_town = nil
                    else
                        found_town = town
                        break
                    end
                end
            end
        end
    end
    if not found_town then
        clear_all_attacks_for_towns()

        current_tries = current_tries + 1
        if current_tries <= find_town_tries then
            radius = radius + 500
            goto retry
        end
        return log_err('get_town_near_position - no town was found.')
    end

    return found_town
end

local function get_town_near_position_forced(position)
    if not is_nighttime() then
        return log_err('get_town_near_position_forced - not nighttime')
    end

    local towns = MT.get('towns')
    local evolution_settings = MT.get('evolution_settings')
    local found_town
    local radius = evolution_settings.radius
    local find_town_tries = 10
    local current_tries = 0
    ::retry::
    for _, town in pairs(towns) do
        if town and town.position then
            local area =
            {
                left_top = { x = town.position.x - radius, y = town.position.y - radius },
                right_bottom = { x = town.position.x + radius, y = town.position.y + radius }
            }

            if Utils.inside(position, area) then
                if town.grace and game.tick <= town.grace then
                    break
                end
                found_town = town
                break
            end
        end
    end
    if not found_town then
        current_tries = current_tries + 1
        if current_tries <= find_town_tries then
            radius = radius + 500
            goto retry
        end
        return log_err('get_town_near_position_forced - no town was found.')
    end

    return found_town
end

local function get_unit_size(evolution)
    if (evolution < 0.1) then
        return 1
    end
    -- 10%
    if (evolution >= 0.1 and evolution < 0.2) then
        local r = random()
        if r < 0.6 then
            return 1
        end
        return 2
    end
    -- 20%
    if (evolution >= 0.2 and evolution < 0.3) then
        local r = random()
        if r < 0.8 then
            if r < 0.4 then
                return 1
            else
                return 2
            end
        end
        return 2
    end
    -- 30%
    if (evolution >= 0.3 and evolution < 0.4) then
        local r = random()
        if r < 0.6 then
            if r < 0.3 then
                return 1
            else
                return 2
            end
        end
        return 2
    end
    -- 40%
    if (evolution >= 0.4 and evolution < 0.5) then
        local r = random()
        if r < 0.4 then
            if r < 0.2 then
                return 1
            else
                return 2
            end
        end
        return 2
    end
    -- 50%
    if (evolution >= 0.5 and evolution < 0.6) then
        local r = random()
        if r < 0.9 then
            if r < 0.3 then
                if r < 0.15 then
                    return 1
                else
                    return 2
                end
            end
            return 2
        end
        return 2
    end
    -- 60%
    if (evolution >= 0.60 and evolution < 0.70) then
        local r = random()
        if r < 0.9 then
            if r < 0.15 then
                if r < 0.075 then
                    return 1
                else
                    return 2
                end
            end
            return 2
        end
        return 2
    end
    -- 70%
    if (evolution >= 0.70 and evolution < 0.80) then
        local r = random()
        if r < 0.985 then
            if r < 0.125 then
                return 2
            else
                return 3
            end
        end
        return 3
    end
    -- 80%
    if (evolution >= 0.80 and evolution < 0.90) then
        local r = random()
        if r < 0.75 then
            if r < 0.25 then
                return 2
            else
                return 3
            end
        end
        return 3
    end
    -- 90%
    if (evolution >= 0.90 and evolution < 1) then
        local r = random()
        if r < 0.5 then
            return 3
        end
        return 3
    end
    -- 100%
    if (evolution >= 1.0) then
        return 4
    end
end

local function distance_squared(pos1, pos2)
    -- calculate the distance squared
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local d2 = dx * dx + dy * dy
    return d2
end

-- calculate the relative evolution based on evolution factor (0.0-1.0) and distance factor (0.0-1.0)
local function calculate_relative_evolution(evolution_factor, distance_factor)
    -- distance factor will be from 0.0 to 1.0 but drop off dramatically towards zero
    local log_distance_factor = log10(distance_factor * 10 + 1)
    local evo = log_distance_factor * evolution_factor
    if evo < 0.0 then
        evo = 0.0
    end
    if evo > 1.0 then
        evo = 1.0
    end
    return evo
end

local function get_relative_biter_evolution(town, position)
    local relative_evolution = 0.0
    local max_d2 = max_evolution_distance * max_evolution_distance
    if not town.position then
        return relative_evolution
    end
    -- calculate the distance squared
    local d2 = distance_squared(position, town.position)
    if d2 < max_d2 then
        -- get the distance factor (0.0-1.0)
        local distance_factor = 1.0 - d2 / max_d2
        -- get the evolution factor (0.0-1.0)
        if not town.evolution then
            town.evolution = {}
        end
        if town.evolution.biters == nil then
            town.evolution.biters = 0.0
        end
        local evo = calculate_relative_evolution(town.evolution.biters, distance_factor)
        -- get the highest of the relative evolutions of each town
        relative_evolution = max(relative_evolution, evo)
    end

    return relative_evolution
end

local function get_relative_spitter_evolution(town, position)
    local relative_evolution = 0.0
    local max_d2 = max_evolution_distance * max_evolution_distance
    if not town.position then
        return relative_evolution
    end
    -- calculate the distance squared
    local d2 = distance_squared(position, town.position)
    if d2 < max_d2 then
        -- get the distance factor (0.0-1.0)
        local distance_factor = 1.0 - d2 / max_d2
        -- get the evolution factor (0.0-1.0)
        if not town.evolution then
            town.evolution = {}
        end
        if town.evolution.spitters == nil then
            town.evolution.spitters = 0.0
        end
        local evo = calculate_relative_evolution(town.evolution.spitters, distance_factor)
        -- get the highest of the relative evolutions of each town
        relative_evolution = max(relative_evolution, evo)
    end

    return relative_evolution
end

local function get_relative_worm_evolution(town, position)
    local relative_evolution = 0.0
    local max_d2 = max_evolution_distance * max_evolution_distance
    if not town.position then
        return relative_evolution
    end
    -- calculate the distance squared
    local d2 = distance_squared(position, town.position)
    if d2 < max_d2 then
        -- get the distance factor (0.0-1.0)
        local distance_factor = 1.0 - d2 / max_d2
        -- get the evolution factor (0.0-1.0)
        if not town.evolution then
            town.evolution = {}
        end
        if town.evolution.worms == nil then
            town.evolution.worms = 0.0
        end
        local evo = calculate_relative_evolution(town.evolution.worms, distance_factor)
        -- get the highest of the relative evolutions of each town
        relative_evolution = max(relative_evolution, evo)
    end
    return relative_evolution
end

function Public.get_evolution(town, position)
    return get_relative_biter_evolution(town, position)
end

function Public.get_biter_evolution(town, entity)
    return get_relative_biter_evolution(town, entity.position)
end

function Public.get_spitter_evolution(town, entity)
    return get_relative_spitter_evolution(town, entity.position)
end

function Public.get_worm_evolution(town, entity)
    return get_relative_worm_evolution(town, entity.position)
end

local function get_nearby_location(position, surface, radius, entity_name)
    return surface.find_non_colliding_position(entity_name, position, radius, 0.5, false)
end

local function set_biter_type(entity)
    -- checks nearby evolution levels for bases and returns an appropriately leveled type
    local position = entity.position
    if not position then
        return
    end

    local town = get_town_near_position(position)
    if not town then
        return
    end
    local evo = get_relative_biter_evolution(town, position)
    local unit_size = get_unit_size(evo)
    local entity_name = biters[unit_size]
    if entity.name == entity_name then
        return
    end

    local surface = entity.surface

    if unit_size > 1 then
        unit_size = random(1, unit_size)
    end

    local near_position = get_nearby_location(position, surface, 5, biters[unit_size])

    if entity.valid then
        local e = surface.create_entity(
            {
                name = biters[unit_size],
                position = near_position
            })
        e.copy_settings(entity)
        e.ai_settings.allow_try_return_to_spawner = true
        spawn_enemy_with_health_boost(town, e)
        local o = surface.create_entity(
            {
                name = entity_name,
                position = get_nearby_location(position, surface, 5,
                    entity_name)
            })
        o.copy_settings(entity)
        o.ai_settings.allow_try_return_to_spawner = true
        spawn_enemy_with_health_boost(town, o)

        create_unit_group(town, surface, position)

        entity.destroy()
    end
end

local function set_spitter_type(entity)
    -- checks nearby evolution levels for bases and returns an appropriately leveled type
    local position = entity.position
    if not position then
        return
    end

    local town = get_town_near_position(position)
    if not town then
        return
    end
    local evo = get_relative_biter_evolution(town, position)
    local unit_size = get_unit_size(evo)
    local entity_name = spitters[unit_size]

    if entity.name == entity_name then
        return
    end

    set_town_attacked(town)

    local surface = entity.surface

    if unit_size > 1 then
        unit_size = random(1, unit_size)
    end

    if entity.valid then
        local e = surface.create_entity(
            {
                name = spitters[unit_size],
                position = get_nearby_location(position, surface, 5,
                    spitters[unit_size])
            })
        e.copy_settings(entity)
        e.ai_settings.allow_try_return_to_spawner = true
        spawn_enemy_with_health_boost(town, e)
        local o = surface.create_entity(
            {
                name = entity_name,
                position = get_nearby_location(position, surface, 5,
                    entity_name)
            })
        o.copy_settings(entity)
        o.ai_settings.allow_try_return_to_spawner = true
        spawn_enemy_with_health_boost(town, o)

        create_unit_group(town, surface, position)

        entity.destroy()
    end
end

local function set_worm_type(entity)
    -- checks nearby evolution levels for bases and returns an appropriately leveled type
    local position = entity.position
    if not position then
        return
    end

    local town = get_town_near_position_forced(position)
    if not town then
        return log_err('set_worm_type - no town found - grace?')
    end
    local evo = get_relative_worm_evolution(town, position)
    local unit_size = get_unit_size(evo)
    local entity_name = worms[unit_size]
    if entity.name == entity_name then
        return
    end

    local surface = entity.surface
    if entity.valid then
        entity.destroy()
        local w = surface.create_entity({ name = entity_name, position = position })
        spawn_enemy_with_health_boost(town, w)
        --log("spawned " .. entity_name)
    end
end

local function is_biter(entity)
    if entity == nil or not entity.valid then
        return false
    end
    if entity.name == 'small-biter' or entity.name == 'medium-biter' or entity.name == 'big-biter' or entity.name == 'behemoth-biter' then
        return true
    end
    return false
end

local function is_spitter(entity)
    if entity == nil or not entity.valid then
        return false
    end
    if entity.name == 'small-spitter' or entity.name == 'medium-spitter' or entity.name == 'big-spitter' or entity.name == 'behemoth-spitter' then
        return true
    end
    return false
end

local function is_worm(entity)
    if entity == nil or not entity.valid then
        return false
    end
    if entity.name == 'small-worm-turret' or entity.name == 'medium-worm-turret' or entity.name == 'big-worm-turret' or entity.name == 'behemoth-worm-turret' then
        return true
    end
    return false
end

-- update evolution based on research completed (weighted)
-- sets the evolution to a value from 0.0 to 1.0 based on research progress
local function update_evolution(force_name, technology)
    if technology == nil then
        return
    end
    MtUtils.get_owner_of_town(
        force_name,
        function (town)
            -- town is a reference to a global table
            if not town then
                return
            end

            -- initialize if not already
            local evo = town.evolution
            -- get the weights for this technology
            local weight = technology_weights[technology]
            if weight == nil then
                log('no technology_weights for ' .. technology)
                return
            end

            local biter_weight = weight.biter
            local spitter_weight = weight.spitter
            local worm_weight = weight.worm
            -- update the evolution values (0.0 to 1.0)
            -- max weights might be less than 1.0, to allow for evo > 1.0
            local b = biter_weight / max_biter_weight
            local s = spitter_weight / max_spitter_weight
            local w = worm_weight / max_worm_weight
            b = b + evo.biters
            s = s + evo.spitters
            w = w + evo.worms
            evo.biters = b
            evo.spitters = s
            evo.worms = w
        end
    )
end

local function on_research_finished(event)
    local research = event.research
    local force = research.force
    local technology = research.name

    update_evolution(force.name, technology)
end

local function on_entity_spawned(event)
    local entity = event.entity
    -- check the unit type and handle appropriately
    if is_biter(entity) then
        set_biter_type(entity)
    end
    if is_spitter(entity) then
        set_spitter_type(entity)
    end
    if is_worm(entity) then
        set_worm_type(entity)
    end
end

local function on_biter_base_built(event)
    local entity = event.entity
    if not entity.valid then
        return
    end

    if is_worm(entity) then
        set_worm_type(entity)
    end
end

local function get_spawner(town, surface)
    local evolution_settings = MT.get('evolution_settings')
    local radius = evolution_settings.radius
    local area =
    {
        left_top = { x = town.position.x - radius, y = town.position.y - radius },
        right_bottom = { x = town.position.x + radius, y = town.position.y + radius }
    }

    local spawners = surface.find_entities_filtered({ type = 'unit-spawner', area = area })

    if not spawners[1] then
        return false
    end
    spawners = MtUtils.shuffle(spawners)

    if not evolution_settings.last_spawners then
        evolution_settings.last_spawners = { { x = spawners[1].position.x, y = spawners[1].position.y } }
        return spawners[1]
    end

    for i = 1, #spawners, 1 do
        local spawner_valid = true
        for i2 = #evolution_settings.last_spawners, #evolution_settings.last_spawners - 4, -1 do
            if i2 < 1 then
                break
            end
            local distance = math.sqrt((spawners[i].position.x - evolution_settings.last_spawners[i2].x) ^ 2 +
                (spawners[i].position.y - evolution_settings.last_spawners[i2].y) ^ 2)
            if distance < 200 then
                spawner_valid = false
                break
            end
        end
        if spawner_valid then
            evolution_settings.last_spawners[#evolution_settings.last_spawners + 1] =
            {
                x = spawners[i].position.x,
                y =
                    spawners[i].position.y
            }
            if #evolution_settings.last_spawners > 8 then
                evolution_settings.last_spawners[#evolution_settings.last_spawners - 8] = nil
            end
            return spawners[i]
        end
    end

    return false
end

local function send_attack_group()
    MtUtils.get_towns(
        function (town)
            if town.grace and game.tick <= town.grace then
                log_err('send_attack_group - town in grace period - grace: ' .. town.grace .. ' game.tick: ' .. game.tick)
                return
            end

            local surface = game.get_surface(town.surface)
            if not surface or not surface.valid then
                log_err('send_attack_group - surface not valid - grace?')
                return
            end

            local spawner = get_spawner(town, surface)
            if not spawner then
                log_err('send_attack_group - spawner not found - grace?')
                return false
            end

            local biter_units = surface.find_enemy_units(spawner.position, 128, 'player')
            if not biter_units[1] then
                log_err('send_attack_group - biter units not found - grace?')
                return
            end

            biter_units = MtUtils.shuffle(biter_units)

            local pos = surface.find_non_colliding_position('rocket-silo', spawner.position, 64, 1)
            if not pos then
                log_err('send_attack_group - position not found - grace?')
                return
            end

            local unit_group = surface.create_unit_group({ position = pos, force = 'enemy' })

            local evo = get_relative_biter_evolution(town, biter_units[1].position)

            local unit_size = get_unit_size(evo)
            if unit_size > 1 then
                unit_size = random(1, unit_size)
            end

            local group_size = 6 + (unit_size * 6)

            if group_size > 200 then
                group_size = 200
            end

            for i = 1, group_size, 1 do
                if not biter_units[i] then
                    break
                end
                unit_group.add_member(biter_units[i])
            end

            set_town_attacked(town)

            unit_group.set_command(
                {
                    type = defines.command.compound,
                    structure_type = defines.compound_command.return_last,
                    commands =
                    {
                        {
                            type = defines.command.attack_area,
                            destination = town.position,
                            radius = 48,
                            distraction = defines.distraction.by_anything
                        }
                    }
                }
            )
        end
    )
end

Event.on_nth_tick(
    60,
    function ()
        if is_nighttime() and is_on_tick_check_enabled() then
            send_attack_group()
        end
    end
)
Event.on_init(
    function ()
        game.map_settings.pollution.enabled = true
        game.map_settings.pollution.diffusion_ratio = 0.02 -- amount that is diffused to neighboring chunk each second
        game.map_settings.pollution.min_to_diffuse = 15 -- minimum number of pollution units on the chunk to start diffusing
        game.map_settings.pollution.ageing = 1 -- percent of pollution eaten by a chunk's tiles per second
        game.map_settings.pollution.expected_max_per_chunk = 150 -- anything greater than this number of pollution units is visualized similarly
        game.map_settings.pollution.min_to_show_per_chunk = 50
        game.map_settings.pollution.min_pollution_to_damage_trees = 60
        game.map_settings.pollution.pollution_with_max_forest_damage = 150
        game.map_settings.pollution.pollution_per_tree_damage = 50
        game.map_settings.pollution.pollution_restored_per_tree_damage = 10
        game.map_settings.pollution.max_pollution_to_restore_trees = 20
        game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 1

        -- enemy evolution settings
        game.map_settings.enemy_evolution.enabled = true
        game.map_settings.enemy_evolution.time_factor = 0.0 -- percent increase in the evolution factor per second
        game.map_settings.enemy_evolution.destroy_factor = 0.0 -- percent increase in the evolution factor for each spawner destroyed
        game.map_settings.enemy_evolution.pollution_factor = 0.0 -- percent increase in the evolution factor for each pollution unit
    end
)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_biter_base_built, on_biter_base_built)

return Public
