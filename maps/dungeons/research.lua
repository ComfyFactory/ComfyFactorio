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

local Public = {}

function Public.Init(dungeontable) 
   game.print('Eric RInit')
   Public.dungeontable = dungeontable
    for _, tech in pairs(locked_researches) do
        game.forces.player.technologies[tech].enabled = false
    end
end

local function get_surface_research(index) 
    return locked_researches[index - Public.dungeontable.original_surface_index]
end

function Public.techs_remain(index)
   local tech = get_surface_research(index) 
   if tech and game.forces.player.technologies[tech].enabled == false then
      return 1
   end
   return 0
end

function Public.unlock_research(surface_index)
    local techs = game.forces.player.technologies
    local tech = get_surface_research(surface_index)
    game.print('ERIC DB UR ' .. tech)
    if tech and techs[tech].enabled == false then
        techs[tech].enabled = true
        game.print({'dungeons_tiered.tech_unlock', '[technology=' .. tech .. ']', surface_index - Public.dungeontable.original_surface_index})
    end
end

function Public.room_is_lab(index)
--   game.print('ERIC Debug RIL ' .. Public.dungeontable.surface_size[index])
--   if true then
--      return true
--   end
   if Public.dungeontable.surface_size[index] < 225 or
        math.random(1, 50) ~= 1 then
      return false
   end
   local tech = get_surface_research(index)
   return tech and game.forces.player.technologies[tech].enabled == false
end

return Public
