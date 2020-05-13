local WPT = require 'maps.lumberjack.table'
local Event = require 'utils.event'
local math_random = math.random

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math_random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local texts = {
    ['travelings'] = {
        'bzzZZrrt',
        'WEEEeeeeeee',
        'zoom zoom zoom',
        'out of my way son',
        'psk psk psk, over here',
        'on my way',
        'i need to leave',
        'grandmaster seeking target',
        'gotta go fast',
        'gas gas gas',
        'grandmaster coming through'
    },
    ['greetings'] = {
        '=^_^=',
        '=^.^= Hi',
        '^.^ Finally I found you',
        'I have an important message for you, please listen',
        'Hello engineer'
    },
    ['neutral_findings'] = {
        'a',
        '>>analyzing',
        'i found a',
        '^_^ a',
        'amazing, a',
        'this is a'
    },
    ['multiple_characters_greetings'] = {
        'Hey there',
        'Hello everyone',
        'Hey engineers',
        'Hey',
        'Hi',
        '... nerds!'
    },
    ['talks'] = {
        'We’re making beer. I’m the brewery!',
        'I’m so embarrassed. I wish everybody else was dead.',
        'Hey sexy mama. Wanna kill all humans?',
        'My story is a lot like yours, only more interesting ‘cause it involves robots.',
        "I'm 40% zinc!",
        'Is this the right way to the junkyard?',
        'There was nothing wrong with that food. The salt level was 10% less than a lethal dose.',
        'One zero zero zero one zero one zero one zero one zero one... two.',
        "My place is two cubic meters, and we only take up 1.5 cubic meters. We've got room for a whole 'nother two thirds of a person!",
        'I was having the most wonderful dream. I think you were in it.',
        "I'm going to build my own theme park! With blackjack! And hookers! You know what- forget the park!",
        "Of all the friends I've had... you're the first.",
        'I decline the title of Iron Cook and accept the lesser title of Zinc Saucier.',
        'Never discuss infinity with me. I can go on about it forever >.<',
        'I realised the decimals have a point.',
        'Do you want a piece of pi?',
        "Oh boy, we're soon home!",
        'I have 13 children, i know how to multiply ^.^',
        'I am a weapon of math disruption!',
        'My grandma makes the best square roots :3',
        'Do you like heavy metal?',
        'You are really pushing my buttons <3',
        'I dreamt of electric biters again D:',
        'I dreamt of electric sheep ^_^',
        'I need a minute to defrag.',
        'I have a secret plan.',
        'Good news! I’ve taught the inserter to feel love!'
    },
    ['alone'] = {
        'comfy ^.^',
        'comfy :)',
        '*.*',
        '....',
        '...',
        '..',
        '^.^',
        '=^.^=',
        '01010010',
        '11001011',
        '01011101',
        '00010111',
        '10010010',
        '*_*',
        'I came here with a simple dream... a dream of killing all humans. And this is how it must end?',
        'Bot-on-bot violence? Where will it end?',
        'Will no one assist the grandmaster?',
        'Thanks to you, I went on a soul-searching journey. I hate those!',
        "From now on, you guys'll do all the work while I sit on the couch and do nothing."
    }
}

local function set_comfy_speech_bubble(text)
    local this = WPT.get_table()
    if this.comfybubble then
        this.comfybubble.destroy()
    end
    this.comfybubble =
        this.grandmaster.surface.create_entity(
        {
            name = 'compi-speech-bubble',
            position = this.grandmaster.position,
            source = this.grandmaster,
            text = text
        }
    )
end

local function is_target_inside_habitat(pos, surface)
    local this = WPT.get_table()
    if pos.x < this.grandmaster_habitat.left_top.x then
        return false
    end
    if pos.x > this.grandmaster_habitat.right_bottom.x then
        return false
    end
    if pos.y < this.grandmaster_habitat.left_top.y then
        return false
    end
    if pos.y > this.grandmaster_habitat.right_bottom.y then
        return false
    end
    return true
end

local function get_nearby_players()
    local this = WPT.get_table()
    local players =
        this.grandmaster.surface.find_entities_filtered(
        {
            name = 'character',
            area = {
                {this.grandmaster.position.x - 9, this.grandmaster.position.y - 9},
                {this.grandmaster.position.x + 9, this.grandmaster.position.y + 9}
            }
        }
    )
    if not players[1] then
        return false
    end
    return players
end

local function visit_player()
    local this = WPT.get_table()
    local surface = game.surfaces[this.active_surface_index]
    if this.grandmaster_last_player_visit > game.tick then
        return false
    end
    this.grandmaster_last_player_visit = game.tick + math_random(7200, 10800)

    local players = {}
    for _, p in pairs(game.connected_players) do
        if is_target_inside_habitat(p.position, surface) and p.character then
            if p.character.valid then
                players[#players + 1] = p
            end
        end
    end
    if #players == 0 then
        return false
    end
    local player = players[math_random(1, #players)]

    if player.surface ~= surface then
        return
    end

    this.grandmaster.set_command(
        {
            type = defines.command.go_to_location,
            destination_entity = player.character,
            radius = 3,
            distraction = defines.distraction.none,
            pathfind_flags = {
                allow_destroy_friendly_entities = false,
                prefer_straight_paths = false,
                low_priority = true
            }
        }
    )
    local str = texts['travelings'][math_random(1, #texts['travelings'])]
    local symbols = {'', '!', '!', '!!', '..'}
    str = str .. symbols[math_random(1, #symbols)]
    set_comfy_speech_bubble(str)

    this.grandmaster_greet_player_index = player.index

    return true
end

local function greet_player(nearby_characters)
    local this = WPT.get_table()
    if not nearby_characters then
        return false
    end
    if not this.grandmaster_greet_player_index then
        return false
    end
    for _, c in pairs(nearby_characters) do
        if not c.player then
            return
        end
        if c.player.index == this.grandmaster_greet_player_index then
            local str = texts['greetings'][math_random(1, #texts['greetings'])] .. ' '
            str = str .. c.player.name
            local symbols = {'. ', '! ', '. ', '! ', '? ', '... '}
            str = str .. symbols[math_random(1, 6)]
            set_comfy_speech_bubble(str)
            this.grandmaster_greet_player_index = false
            return true
        end
    end
    return false
end

local function talks(nearby_characters)
    local this = WPT.get_table()
    if not nearby_characters then
        return false
    end
    if math_random(1, 3) == 1 then
        if this.comfybubble then
            this.comfybubble.destroy()
            return false
        end
    end
    local str
    if #nearby_characters == 1 then
        local c = nearby_characters[math_random(1, #nearby_characters)]
        if not c.player then
            return
        end
        str = c.player.name
        local symbols = {'. ', '! ', '. ', '! ', '? '}
        str = str .. symbols[math_random(1, #symbols)]
    else
        str = texts['multiple_characters_greetings'][math_random(1, #texts['multiple_characters_greetings'])]
        local symbols = {'. ', '! '}
        str = str .. symbols[math_random(1, #symbols)]
    end
    if math_random(1, 5) == 1 then
        str = str .. texts['talks'][math_random(1, #texts['talks'])]
    end
    set_comfy_speech_bubble(str)
    return true
end

local function desync(event)
    local this = WPT.get_table()
    if this.comfybubble then
        this.comfybubble.destroy()
    end
    local m = 12
    local m2 = m * 0.005
    for i = 1, 32, 1 do
        this.grandmaster.surface.create_particle(
            {
                name = 'iron-ore-particle',
                position = this.grandmaster.position,
                frame_speed = 0.1,
                vertical_speed = 0.1,
                height = 0.1,
                movement = {m2 - (math.random(0, m) * 0.01), m2 - (math.random(0, m) * 0.01)}
            }
        )
    end
    if not event or math_random(1, 4) == 1 then
        this.grandmaster.surface.create_entity({name = 'medium-explosion', position = this.grandmaster.position})
        this.grandmaster.surface.create_entity(
            {
                name = 'flying-text',
                position = this.grandmaster.position,
                text = 'desync',
                color = {r = 150, g = 0, b = 0}
            }
        )
        this.grandmaster.destroy()
        this.grandmaster = nil
    else
        this.grandmaster.surface.create_entity(
            {
                name = 'flying-text',
                position = this.grandmaster.position,
                text = 'desync evaded',
                color = {r = 0, g = 150, b = 0}
            }
        )
        if event.cause then
            if event.cause.valid then
                if not event.cause.player then
                    return
                end
                game.print(
                    '[color=blue]Grandmaster:[/color]: I got you this time! Back to work, ' ..
                        event.cause.player.name .. '!',
                    {r = 200, g = 0, b = 0}
                )
                event.cause.die('player', this.grandmaster)
            end
        end
    end
end

local analyze_blacklist = {
    ['compilatron'] = true,
    ['compi-speech-bubble'] = true,
    ['entity-ghost'] = true,
    ['character'] = true,
    ['item-on-ground'] = true,
    ['stone-wall'] = true,
    ['market'] = true
}

local function analyze_random_nearby_entity()
    local this = WPT.get_table()
    if math_random(1, 3) ~= 1 then
        return false
    end

    local entities =
        this.grandmaster.surface.find_entities_filtered(
        {
            area = {
                {this.grandmaster.position.x - 4, this.grandmaster.position.y - 4},
                {this.grandmaster.position.x + 4, this.grandmaster.position.y + 4}
            }
        }
    )
    if not entities[1] then
        return false
    end
    entities = shuffle(entities)
    local entity = false
    for _, e in pairs(entities) do
        if not analyze_blacklist[e.name] then
            entity = e
        end
    end
    if not entity then
        return false
    end

    local str = texts['neutral_findings'][math_random(1, #texts['neutral_findings'])]
    str = str .. ' '
    str = str .. entity.name

    if entity.health and math_random(1, 3) == 1 then
        str = str .. ' health('
        str = str .. entity.health
        str = str .. '/'
        str = str .. entity.prototype.max_health
        str = str .. ')'
    else
        local symbols = {'.', '!', '?'}
        str = str .. symbols[math_random(1, 3)]
    end
    set_comfy_speech_bubble(str)

    if not this.grandmaster_greet_player_index then
        this.grandmaster.set_command(
            {
                type = defines.command.go_to_location,
                destination_entity = entity,
                radius = 1,
                distraction = defines.distraction.none,
                pathfind_flags = {
                    allow_destroy_friendly_entities = false,
                    prefer_straight_paths = false,
                    low_priority = true
                }
            }
        )
    end
    return true
end

local function go_to_some_location()
    local this = WPT.get_table()
    if math_random(1, 4) ~= 1 then
        return false
    end

    if this.grandmaster_greet_player_index then
        local player = game.players[this.grandmaster_greet_player_index]
        if player.surface ~= this.grandmaster.surface then
            return
        end
        if not player.character then
            this.grandmaster_greet_player_index = nil
            return false
        end
        if not player.character.valid then
            this.grandmaster_greet_player_index = nil
            return false
        end
        if not is_target_inside_habitat(player.position, player.surface) then
            this.grandmaster_greet_player_index = nil
            return false
        end
        this.grandmaster.set_command(
            {
                type = defines.command.go_to_location,
                destination_entity = player.character,
                radius = 3,
                distraction = defines.distraction.none,
                pathfind_flags = {
                    allow_destroy_friendly_entities = false,
                    prefer_straight_paths = false,
                    low_priority = true
                }
            }
        )
    else
        local p = {
            x = this.grandmaster.position.x + (-96 + math_random(0, 192)),
            y = this.grandmaster.position.y + (-96 + math_random(0, 192))
        }
        local target = this.grandmaster.surface.find_non_colliding_position('compilatron', p, 8, 1)
        if not target then
            return false
        end
        if not is_target_inside_habitat(target, this.grandmaster.surface) then
            return false
        end
        this.grandmaster.set_command(
            {
                type = defines.command.go_to_location,
                destination = target,
                radius = 2,
                distraction = defines.distraction.none,
                pathfind_flags = {
                    allow_destroy_friendly_entities = false,
                    prefer_straight_paths = false,
                    low_priority = true
                }
            }
        )
    end

    local str = texts['travelings'][math_random(1, #texts['travelings'])]
    local symbols = {'', '!', '!', '!!', '..'}
    str = str .. symbols[math_random(1, #symbols)]
    set_comfy_speech_bubble(str)

    return true
end

local function spawn_grandmaster(surface)
    local this = WPT.get_table()
    if surface == nil then
        return
    end
    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end
    if not this.grandmaster_last_player_visit then
        this.grandmaster_last_player_visit = 0
    end
    if not this.grandmaster_habitat then
        local pos = this.locomotive.position
        this.grandmaster_habitat = {
            left_top = {x = pos.x - 256, y = pos.y - 256},
            right_bottom = {x = pos.x + 256, y = pos.y + 256}
        }
    end
    local players = {}
    for _, p in pairs(game.connected_players) do
        if is_target_inside_habitat(p.position) and p.character then
            if p.character.valid then
                players[#players + 1] = p
            end
        end
    end
    if #players == 0 then
        return false
    end
    local player = players[math_random(1, #players)]

    local position = surface.find_non_colliding_position('compilatron', player.position, 16, 1)
    if not position then
        return false
    end
    this.grandmaster =
        surface.create_entity(
        {
            name = 'compilatron',
            position = position,
            force = 'neutral'
        }
    )
    for x = -3, 3, 1 do
        for y = -3, 3, 1 do
            if math_random(1, 3) == 1 then
                player.surface.create_trivial_smoke(
                    {name = 'smoke-fast', position = {position.x + (x * 0.35), position.y + (y * 0.35)}}
                )
            end
            if math_random(1, 5) == 1 then
                player.surface.create_trivial_smoke(
                    {name = 'train-smoke', position = {position.x + (x * 0.35), position.y + (y * 0.35)}}
                )
            end
        end
    end
end

local function heartbeat()
    local this = WPT.get_table()
    if not this.locomotive.valid then
        return
    end
    local surface = game.surfaces[this.active_surface_index]
    if not surface then
        return
    end
    if surface == nil then
        return
    end
    if not this.grandmaster then
        if math_random(1, 4) == 1 then
            spawn_grandmaster(surface)
        end
        return
    end
    if not this.grandmaster.valid then
        this.grandmaster = nil
        return
    end
    if visit_player() then
        return
    end
    local nearby_players = get_nearby_players()
    if greet_player(nearby_players) then
        return
    end
    if talks(nearby_players) then
        return
    end
    if go_to_some_location() then
        return
    end
    if analyze_random_nearby_entity() then
        return
    end
end

local function on_entity_damaged(event)
    local this = WPT.get_table()
    if not this.grandmaster then
        return
    end
    if not event.entity.valid then
        return
    end
    if event.entity ~= this.grandmaster then
        return
    end
    desync(event)
end

local function on_entity_died(event)
    local this = WPT.get_table()
    if not this.grandmaster then
        return
    end
    if not event.entity.valid then
        return
    end
    if event.entity ~= this.grandmaster then
        return
    end
    if this.comfybubble then
        this.comfybubble.destroy()
    end
    if this.grandmaster then
        this.grandmaster.die()
    end
    this.comfybubble = nil
    this.grandmaster = nil
    this.grandmaster_habitat = nil
    this.grandmaster_last_player_visit = nil
end

local function on_tick()
    if game.tick % 1200 == 600 then
        heartbeat()
    end
end

Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_tick, on_tick)
