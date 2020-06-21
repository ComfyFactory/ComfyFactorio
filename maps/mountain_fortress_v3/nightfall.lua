local Event = require 'utils.event'
local Alert = require 'utils.alert'
local WPT = require 'maps.mountain_fortress_v3.table'
local random = math.random

local shuffle = function(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local create_time_gui = function(player)
    local this = WPT.get()
    if player.gui.top['time_gui'] then
        player.gui.top['time_gui'].destroy()
    end
    local frame = player.gui.top.add({type = 'frame', name = 'time_gui'})
    frame.style.maximal_height = 38

    local night_count = 0
    if this.night_count then
        night_count = this.night_count
    end

    local label = frame.add({type = 'label', caption = 'Night: ' .. night_count})
    label.style.font_color = {r = 0.75, g = 0.0, b = 0.25}
    label.style.font = 'default-listbox'
    label.style.left_padding = 4
    label.style.right_padding = 4
    label.style.minimal_width = 50
end

local set_daytime_modifiers = function()
    if game.map_settings.enemy_expansion.enabled == false then
        return
    end

    game.map_settings.enemy_expansion.enabled = false
end

local nightfall_messages = {
    'Night is falling.',
    'It is getting dark.',
    'They are becoming restless.'
}

local set_nighttime_modifiers = function(surface)
    if game.map_settings.enemy_expansion.enabled == true then
        return
    end
    local this = WPT.get()

    if not this.night_count then
        --this.splice_modifier = 1
        this.night_count = 1
    else
        --if game.forces["enemy"].evolution_factor > 0.25 then
        --this.splice_modifier = this.splice_modifier + 0.05
        --if this.splice_modifier > 4 then this.splice_modifier = 4 end
        --end
        this.night_count = this.night_count + 1
    end

    for _, player in pairs(game.connected_players) do
        create_time_gui(player)
        local message = nightfall_messages[random(1, #nightfall_messages)]
        Alert.alert_player_warning(player, 10, message, {r = 150, g = 0, b = 0})
    end

    game.map_settings.enemy_expansion.enabled = true

    local max_expansion_distance = math.ceil(this.night_count / 3)
    if max_expansion_distance > 20 then
        max_expansion_distance = 20
    end
    game.map_settings.enemy_expansion.max_expansion_distance = max_expansion_distance

    local settler_group_min_size = math.ceil(this.night_count / 6)
    if settler_group_min_size > 20 then
        settler_group_min_size = 20
    end
    game.map_settings.enemy_expansion.settler_group_min_size = settler_group_min_size

    local settler_group_max_size = math.ceil(this.night_count / 3)
    if settler_group_max_size > 50 then
        settler_group_max_size = 50
    end
    game.map_settings.enemy_expansion.settler_group_max_size = settler_group_max_size

    local min_expansion_cooldown = 54000 - this.night_count * 540
    if min_expansion_cooldown < 3600 then
        min_expansion_cooldown = 3600
    end
    game.map_settings.enemy_expansion.min_expansion_cooldown = min_expansion_cooldown

    local max_expansion_cooldown = 108000 - this.night_count * 1080
    if max_expansion_cooldown < 3600 then
        max_expansion_cooldown = 3600
    end
    game.map_settings.enemy_expansion.max_expansion_cooldown = max_expansion_cooldown
end

local get_spawner = function(surface)
    local this = WPT.get()
    local spawners = {}
    for r = 512, 51200, 512 do
        spawners = surface.find_entities_filtered({type = 'unit-spawner', area = {{0 - r, 0 - r}, {0 + r, 0 + r}}})
        if #spawners > 16 then
            break
        end
    end

    if not spawners[1] then
        return false
    end
    spawners = shuffle(spawners)

    if not this.last_spawners then
        this.last_spawners = {{x = spawners[1].position.x, y = spawners[1].position.y}}
        return spawners[1]
    end

    for i = 1, #spawners, 1 do
        local spawner_valid = true
        for i2 = #this.last_spawners, #this.last_spawners - 4, -1 do
            if i2 < 1 then
                break
            end
            local distance =
                math.sqrt(
                (spawners[i].position.x - this.last_spawners[i2].x) ^ 2 +
                    (spawners[i].position.y - this.last_spawners[i2].y) ^ 2
            )
            if distance < 200 then
                spawner_valid = false
                break
            end
        end
        if spawner_valid then
            this.last_spawners[#this.last_spawners + 1] = {x = spawners[i].position.x, y = spawners[i].position.y}
            if #this.last_spawners > 8 then
                this.last_spawners[#this.last_spawners - 8] = nil
            end
            return spawners[i]
        end
    end

    return false
end

local send_attack_group = function(surface)
    local spawner = get_spawner(surface)
    if not spawner then
        game.print('it failed')
        return false
    end
    local this = WPT.get()

    local biters = surface.find_enemy_units(spawner.position, 128, 'player')
    if not biters[1] then
        game.print('no biters')
        return
    end

    biters = shuffle(biters)

    local pos = surface.find_non_colliding_position('rocket-silo', spawner.position, 64, 1)
    if not pos then
        game.print('no pos')
        return
    end

    local unit_group = surface.create_unit_group({position = pos, force = 'enemy'})

    local group_size = 6 + (this.night_count * 6)
    if group_size > 200 then
        group_size = 200
    end

    for i = 1, group_size, 1 do
        if not biters[i] then
            break
        end
        unit_group.add_member(biters[i])
    end

    if this.locomotive.valid then
        unit_group.set_command(
            {
                type = defines.command.compound,
                structure_type = defines.compound_command.return_last,
                commands = {
                    {
                        type = defines.command.attack_area,
                        destination = {x = 0, y = 0},
                        radius = 48,
                        distraction = defines.distraction.by_anything
                    },
                    {
                        type = defines.command.attack,
                        target = this.locomotive,
                        distraction = defines.distraction.by_enemy
                    }
                }
            }
        )
    else
        unit_group.set_command(
            {
                type = defines.command.compound,
                structure_type = defines.compound_command.return_last,
                commands = {
                    {
                        type = defines.command.attack_area,
                        destination = {x = 0, y = 0},
                        radius = 48,
                        distraction = defines.distraction.by_anything
                    }
                }
            }
        )
    end
end

local on_tick = function()
    if game.tick % 600 ~= 0 then
        return
    end
    local this = WPT.get()
    local surface = game.surfaces[this.active_surface_index]
    if surface.daytime > 0.25 and surface.daytime < 0.75 then
        set_nighttime_modifiers(surface)
        if surface.daytime < 0.65 then
            send_attack_group(surface)
        end
    else
        set_daytime_modifiers()
    end
end

Event.on_nth_tick(10, on_tick)
