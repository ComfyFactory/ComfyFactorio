local Task = require 'utils.task'
local RPG = require 'modules.rpg.table'
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'
local Token = require 'utils.token'

local Public = {}

local level_up_floating_text_color = {0, 205, 0}

--RPG Frames
local main_frame_name = RPG.main_frame_name

local travelings = {
    'bzzZZrrt',
    'WEEEeeeeeee',
    'out of my way son',
    'on my way',
    'i need to leave',
    'comfylatron seeking target',
    'gotta go fast',
    'gas gas gas',
    'comfylatron coming through'
}

local desync =
    Token.register(
    function(data)
        local entity = data.entity
        if not entity or not entity.valid then
            return
        end
        local surface = data.surface
        local fake_shooter = surface.create_entity({name = 'character', position = entity.position, force = 'enemy'})
        for i = 1, 3 do
            surface.create_entity(
                {
                    name = 'explosive-rocket',
                    position = entity.position,
                    force = 'enemy',
                    speed = 1,
                    max_range = 1,
                    target = entity,
                    source = fake_shooter
                }
            )
        end
        if fake_shooter and fake_shooter.valid then
            fake_shooter.destroy()
        end
    end
)

local function create_healthbar(player, size)
    return rendering.draw_sprite(
        {
            sprite = 'virtual-signal/signal-white',
            tint = Color.green,
            x_scale = size * 8,
            y_scale = size - 0.2,
            render_layer = 'light-effect',
            target = player.character,
            target_offset = {0, -2.5},
            surface = player.surface
        }
    )
end

local function create_manabar(player, size)
    return rendering.draw_sprite(
        {
            sprite = 'virtual-signal/signal-white',
            tint = Color.blue,
            x_scale = size * 8,
            y_scale = size - 0.2,
            render_layer = 'light-effect',
            target = player.character,
            target_offset = {0, -2.0},
            surface = player.surface
        }
    )
end

local function set_bar(min, max, id, mana)
    local m = min / max
    if not rendering.is_valid(id) then
        return
    end
    local x_scale = rendering.get_y_scale(id) * 8
    rendering.set_x_scale(id, x_scale * m)
    if not mana then
        rendering.set_color(id, {math.floor(255 - 255 * m), math.floor(200 * m), 0})
    end
end

function Public.suicidal_comfylatron(pos, surface)
    local str = travelings[math.random(1, #travelings)]
    local symbols = {'', '!', '!', '!!', '..'}
    str = str .. symbols[math.random(1, #symbols)]
    local text = str
    local e =
        surface.create_entity(
        {
            name = 'compilatron',
            position = {x = pos.x, y = pos.y + 2},
            force = 'neutral'
        }
    )
    surface.create_entity(
        {
            name = 'compi-speech-bubble',
            position = e.position,
            source = e,
            text = text
        }
    )
    local nearest_player_unit =
        surface.find_nearest_enemy({position = e.position, max_distance = 256, force = 'player'})

    if nearest_player_unit and nearest_player_unit.active and nearest_player_unit.force.name ~= 'player' then
        e.set_command(
            {
                type = defines.command.attack,
                target = nearest_player_unit,
                distraction = defines.distraction.none
            }
        )
        local data = {
            entity = e,
            surface = surface
        }
        Task.set_timeout_in_ticks(600, desync, data)
    else
        e.surface.create_entity({name = 'medium-explosion', position = e.position})
        e.surface.create_entity(
            {
                name = 'flying-text',
                position = e.position,
                text = 'DeSyyNC - no target found!',
                color = {r = 150, g = 0, b = 0}
            }
        )
        e.die()
    end
end

function Public.validate_player(player)
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
    if not game.players[player.index] then
        return false
    end
    return true
end

function Public.update_mana(player)
    local rpg_extra = RPG.get('rpg_extra')
    local rpg_t = RPG.get('rpg_t')
    if not rpg_extra.enable_mana then
        return
    end
    if player.gui.left[main_frame_name] then
        local f = player.gui.left[main_frame_name]
        local data = Gui.get_data(f)
        if data.mana and data.mana.valid then
            data.mana.caption = rpg_t[player.index].mana
        end
    end
    if rpg_t[player.index].mana < 1 then
        return
    end
    if rpg_extra.enable_health_and_mana_bars then
        if rpg_t[player.index].show_bars then
            if player.character and player.character.valid then
                if not rpg_t[player.index].mana_bar then
                    rpg_t[player.index].mana_bar = create_manabar(player, 0.5)
                    set_bar(rpg_t[player.index].mana, rpg_t[player.index].mana_max, rpg_t[player.index].mana_bar, true)
                elseif not rendering.is_valid(rpg_t[player.index].mana_bar) then
                    rpg_t[player.index].mana_bar = create_manabar(player, 0.5)
                    set_bar(rpg_t[player.index].mana, rpg_t[player.index].mana_max, rpg_t[player.index].mana_bar, true)
                end
            end
        else
            if rpg_t[player.index].mana_bar then
                if rendering.is_valid(rpg_t[player.index].mana_bar) then
                    rendering.destroy(rpg_t[player.index].mana_bar)
                end
            end
        end
    end
end

function Public.update_health(player)
    local rpg_extra = RPG.get('rpg_extra')
    local rpg_t = RPG.get('rpg_t')
    if rpg_extra.enable_health_and_mana_bars then
        if rpg_t[player.index].show_bars then
            if player and player.valid then
                if player.character and player.character.valid then
                    local max_life =
                        math.floor(
                        player.character.prototype.max_health + player.character_health_bonus +
                            player.force.character_health_bonus
                    )
                    if not rpg_t[player.index].health_bar then
                        rpg_t[player.index].health_bar = create_healthbar(player, 0.5)
                        set_bar(player.character.health, max_life, rpg_t[player.index].health_bar)
                    elseif not rendering.is_valid(rpg_t[player.index].health_bar) then
                        rpg_t[player.index].health_bar = create_healthbar(player, 0.5)
                        set_bar(player.character.health, max_life, rpg_t[player.index].health_bar)
                    end
                    if player.gui.left[main_frame_name] then
                        local f = player.gui.left[main_frame_name]
                        local data = Gui.get_data(f)
                        if data.health and data.health.valid then
                            data.health.caption = (math.round(player.character.health * 10) / 10)
                        end
                        local shield_gui = player.character.get_inventory(defines.inventory.character_armor)
                        if not shield_gui.is_empty() then
                            if shield_gui[1].grid then
                                local shield = math.floor(shield_gui[1].grid.shield)
                                local shield_max = math.floor(shield_gui[1].grid.max_shield)
                                if data.shield and data.shield.valid then
                                    data.shield.caption = shield
                                end
                                if data.shield_max and data.shield_max.valid then
                                    data.shield_max.caption = shield_max
                                end
                            end
                        end
                    end
                end
            end
        else
            if rpg_t[player.index].health_bar then
                if rendering.is_valid(rpg_t[player.index].health_bar) then
                    rendering.destroy(rpg_t[player.index].health_bar)
                end
            end
        end
    end
end

function Public.level_limit_exceeded(player, value)
    local rpg_extra = RPG.get('rpg_extra')
    local rpg_t = RPG.get('rpg_t')
    if not rpg_extra.level_limit_enabled then
        return false
    end

    local limits = {
        [1] = 30,
        [2] = 50,
        [3] = 70,
        [4] = 90,
        [5] = 110,
        [6] = 130,
        [7] = 150,
        [8] = 170,
        [9] = 190,
        [10] = 210
    }

    local level = rpg_t[player.index].level
    local zone = rpg_extra.breached_walls
    if zone >= 11 then
        zone = 10
    end
    if value then
        return limits[zone]
    end

    if level >= limits[zone] then
        return true
    end
    return false
end

function Public.level_up_effects(player)
    local position = {x = player.position.x - 0.75, y = player.position.y - 1}
    player.surface.create_entity(
        {name = 'flying-text', position = position, text = '+LVL ', color = level_up_floating_text_color}
    )
    local b = 0.75
    for _ = 1, 5, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        player.surface.create_entity(
            {name = 'flying-text', position = p, text = '✚', color = {255, math.random(0, 100), 0}}
        )
    end
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.40}
end

function Public.xp_effects(player)
    local position = {x = player.position.x - 0.75, y = player.position.y - 1}
    player.surface.create_entity(
        {name = 'flying-text', position = position, text = '+XP', color = level_up_floating_text_color}
    )
    local b = 0.75
    for _ = 1, 5, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        player.surface.create_entity(
            {name = 'flying-text', position = p, text = '✚', color = {255, math.random(0, 100), 0}}
        )
    end
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.40}
end

function Public.get_melee_modifier(player)
    local rpg_t = RPG.get('rpg_t')
    return (rpg_t[player.index].strength - 10) * 0.10
end

function Public.get_heal_modifier(player)
    local rpg_t = RPG.get('rpg_t')
    return (rpg_t[player.index].vitality - 10) * 0.02
end

function Public.get_mana_modifier(player)
    local rpg_t = RPG.get('rpg_t')
    if rpg_t[player.index].level <= 40 then
        return (rpg_t[player.index].magicka - 10) * 0.02000
    elseif rpg_t[player.index].level <= 80 then
        return (rpg_t[player.index].magicka - 10) * 0.01800
    else
        return (rpg_t[player.index].magicka - 10) * 0.01400
    end
end

function Public.get_life_on_hit(player)
    local rpg_t = RPG.get('rpg_t')
    return (rpg_t[player.index].vitality - 10) * 0.4
end

function Public.get_one_punch_chance(player)
    local rpg_t = RPG.get('rpg_t')
    if rpg_t[player.index].strength < 100 then
        return 0
    end
    local chance = math.round(rpg_t[player.index].strength * 0.01, 1)
    if chance > 100 then
        chance = 100
    end
    return chance
end

function Public.get_magicka(player)
    local rpg_t = RPG.get('rpg_t')
    return (rpg_t[player.index].magicka - 10) * 0.10
end

return Public
