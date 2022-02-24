local Public = require 'maps.fish_defender_v2.table'
local radius = 3
local random = math.random
local floor = math.floor
local sqrt = math.sqrt

local function splash_damage(surface, position, final_damage_amount)
    local damage = random(floor(final_damage_amount * 3), floor(final_damage_amount * 4))
    for _, e in pairs(surface.find_entities_filtered({area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}})) do
        if e.valid and e.health then
            local distance_from_center = sqrt((e.position.x - position.x) ^ 2 + (e.position.y - position.y) ^ 2)
            if distance_from_center <= radius then
                local damage_distance_modifier = 1 - distance_from_center / radius
                if damage > 0 then
                    if random(1, 3) == 1 then
                        surface.create_entity({name = 'explosion', position = e.position})
                    end
                    e.damage(damage * damage_distance_modifier, 'player', 'explosion')
                end
            end
        end
    end
end

function Public.explosive_bullets(event)
    if random(1, 3) ~= 1 then
        return false
    end
    local damage_type = event.damage_type
    if damage_type.name ~= 'physical' then
        return false
    end
    local cause = event.cause
    local entity = event.entity

    if cause.shooting_state.state == defines.shooting.not_shooting then
        return false
    end
    local selected_weapon = cause.get_inventory(defines.inventory.character_guns)[cause.selected_gun_index]
    if selected_weapon.name ~= 'submachine-gun' and selected_weapon.name ~= 'pistol' then
        return false
    end

    cause.surface.create_entity({name = 'explosion', position = entity.position})

    splash_damage(cause.surface, entity.position, event.final_damage_amount)
end

return Public
