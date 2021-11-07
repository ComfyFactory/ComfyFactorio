local Event = require 'utils.event'
local WPT = require 'maps.mountain_fortress_v3.table'

local random = math.random

local Public = {}

local function shoo(event)
    local icw_locomotive = WPT.get('icw_locomotive')
    local loco_surface = icw_locomotive.surface

    if not loco_surface.valid then
        return
    end

    local player = game.players[event.player_index]

    if player and player.valid then
        if player.surface.index ~= loco_surface.index then
            return
        end
    end

    local locomotive_biter = WPT.get('locomotive_biter')
    local surface = player.surface
    local message = event.message
    message = string.lower(message)
    for word in string.gmatch(message, '%g+') do
        if word == 'shoo' then
            if not locomotive_biter or not locomotive_biter.valid then
                Public.spawn_biter()
                return
            end
            surface.create_entity(
                {
                    name = 'rocket',
                    position = locomotive_biter.position,
                    force = 'enemy',
                    speed = 1,
                    max_range = 1200,
                    target = locomotive_biter,
                    source = locomotive_biter
                }
            )
            if locomotive_biter and locomotive_biter.valid then
                local explosion = {
                    name = 'massive-explosion',
                    position = locomotive_biter.position
                }
                surface.create_entity(explosion)
                locomotive_biter.destroy()
                WPT.set().locomotive_biter = nil
            end
            return
        end
    end
end

function Public.spawn_biter()
    local this = WPT.get()
    local loco_surface = this.icw_locomotive.surface

    if not loco_surface.valid then
        return
    end

    local locomotive = this.icw_locomotive

    local center_position = {
        x = locomotive.area.left_top.x + (locomotive.area.right_bottom.x - locomotive.area.left_top.x) * 0.5,
        y = locomotive.area.left_top.y + (locomotive.area.right_bottom.y - locomotive.area.left_top.y) * 0.5
    }

    if not this.icw_area then
        this.icw_area = center_position
    end

    local position = loco_surface.find_non_colliding_position('market', center_position, 128, 0.5)
    local biters = {
        'small-biter',
        'medium-biter',
        'big-biter',
        'behemoth-biter',
        'small-spitter',
        'medium-spitter',
        'big-spitter',
        'behemoth-spitter',
        'compilatron'
    }

    local size_of = #biters

    if not position then
        return
    end

    local chosen_ent = biters[random(1, size_of)]

    this.locomotive_biter = loco_surface.create_entity({name = chosen_ent, position = position, force = 'player', create_build_effect_smoke = false})

    rendering.draw_text {
        text = ({'locomotive.shoo'}),
        surface = this.locomotive_biter.surface,
        target = this.locomotive_biter,
        target_offset = {0, -3.5},
        scale = 1.05,
        font = 'default-large-semibold',
        color = {r = 175, g = 75, b = 255},
        alignment = 'center',
        scale_with_zoom = false
    }

    this.locomotive_biter.ai_settings.allow_destroy_when_commands_fail = false
    this.locomotive_biter.ai_settings.allow_try_return_to_spawner = false
end

local function on_console_chat(event)
    if not event.player_index then
        return
    end
    shoo(event)
end

Event.add(defines.events.on_console_chat, on_console_chat)

return Public
