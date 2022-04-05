local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Server = require 'utils.server'
local Global = require 'utils.global'
local SpamProtection = require 'utils.spam_protection'

local max = math.max
local round = math.round

local main_frame_name = Gui.uid_name()
local selection_button_name = Gui.uid_name()
local close_main_frame = Gui.uid_name()
local top_button_name = Gui.uid_name()

local this = {
    difficulties = {
        [1] = {
            name = "I'm too young to die",
            index = 1,
            value = 0.75,
            color = {r = 0.00, g = 0.25, b = 0.00},
            print_color = {r = 0.00, g = 0.4, b = 0.00},
            count = 0,
            strength_modifier = 1.00,
            boss_modifier = 6.0
        },
        [2] = {
            name = 'Hurt me plenty',
            index = 2,
            value = 1,
            color = {r = 0.00, g = 0.00, b = 0.25},
            print_color = {r = 0.0, g = 0.0, b = 0.5},
            count = 0,
            strength_modifier = 1.25,
            boss_modifier = 7.0
        },
        [3] = {
            name = 'Ultra-violence',
            index = 3,
            value = 1.5,
            color = {r = 255, g = 128, b = 0.00},
            print_color = {r = 255, g = 128, b = 0.00},
            count = 0,
            strength_modifier = 1.75,
            boss_modifier = 8.0
        }
    },
    tooltip = {
        [1] = '',
        [2] = '',
        [3] = ''
    },
    difficulty_vote_value = 0.75,
    difficulty_vote_index = 1,
    fair_vote = false,
    difficulty_poll_closing_timeout = 54000,
    difficulty_player_votes = {},
    gui_width = 108,
    name = "I'm too young to die",
    strength_modifier = 1.00,
    button_tooltip = nil
}

local Public = {}

Global.register(
    this,
    function(t)
        this = t
    end
)

local function clear_main_frame(player)
    local screen = player.gui.center
    if screen[main_frame_name] and screen[main_frame_name].valid then
        screen[main_frame_name].destroy()
    end
end

function Public.difficulty_gui()
    local tooltip = 'Current difficulty of the map is ' .. this.difficulties[this.difficulty_vote_index].name .. '.'

    for _, player in pairs(game.connected_players) do
        local top = player.gui.top
        if top[top_button_name] then
            top[top_button_name].caption = this.difficulties[this.difficulty_vote_index].name
            top[top_button_name].tooltip = this.button_tooltip or tooltip
            top[top_button_name].style.font_color = this.difficulties[this.difficulty_vote_index].print_color
        else
            local b =
                top.add {
                type = 'button',
                caption = this.difficulties[this.difficulty_vote_index].name,
                tooltip = tooltip,
                name = top_button_name
            }
            b.style.font = 'heading-2'
            b.style.font_color = this.difficulties[this.difficulty_vote_index].print_color
            b.style.minimal_height = 37
            b.style.maximal_height = 37
            b.style.minimal_width = this.gui_width
        end
    end
end

local function highest_count(tbl)
    local init = {
        count = {},
        index = {}
    }
    for i = 1, #tbl do
        init.count[#init.count + 1] = tbl[i].count
        init.index[#init.index + 1] = tbl[i].index
    end

    local highest = max(unpack(init.count))

    local pre = {}

    if this.fair_vote then
        for x = 1, #init.count do
            if init.count[x] == highest then
                pre[#pre + 1] = {i = init.index[x], c = init.count[x]}
            end
        end
    else
        for x = 1, #init.count do
            if init.count[x] ~= 0 then
                if round(init.count[x] / highest) == 1 then
                    pre[#pre + 1] = {i = init.index[x], c = init.count[x]}
                end
            end
        end
    end

    local post = {}
    for i = 1, #pre do
        post[#post + 1] = pre[i].i
    end

    highest = round(table.mean(post))

    return highest
end

local function poll_difficulty(player)
    if player.gui.center[main_frame_name] then
        clear_main_frame(player)
    end

    if game.tick > this.difficulty_poll_closing_timeout then
        if player.online_time ~= 0 then
            local t = math.abs(math.floor((this.difficulty_poll_closing_timeout - game.tick) / 3600))
            local str = 'Votes have closed ' .. t
            str = str .. ' minute'
            if t > 1 then
                str = str .. 's'
            end
            str = str .. ' ago.'
            player.print(str)
        end
        return
    end

    local _, inside_frame = Gui.add_main_frame_with_toolbar(player, 'center', main_frame_name, nil, close_main_frame, 'Difficulty')

    for i = 1, #this.difficulties, 1 do
        local button_flow =
            inside_frame.add {
            type = 'flow',
            name = tostring(i)
        }
        local b = button_flow.add({type = 'button', name = selection_button_name, caption = this.difficulties[i].name})
        b.style.font_color = this.difficulties[i].color
        b.style.font = 'heading-2'
        b.style.minimal_width = 160
        b.tooltip = this.tooltip[i]
    end

    local label_flow =
        inside_frame.add {
        type = 'flow'
    }

    label_flow.add({type = 'label', caption = '- - - - - - - - - - - - - - - - - -'})

    label_flow.style.horizontal_align = 'center'
    label_flow.style.horizontally_stretchable = true

    local timeleft_flow =
        inside_frame.add {
        type = 'flow'
    }
    timeleft_flow.style.horizontal_align = 'center'
    timeleft_flow.style.horizontally_stretchable = true

    local b =
        timeleft_flow.add(
        {
            type = 'button',
            caption = math.floor((this.difficulty_poll_closing_timeout - game.tick) / 3600) .. ' minutes left.'
        }
    )
    b.style.font_color = {r = 0.66, g = 0.0, b = 0.66}
    b.style.font = 'heading-3'
    b.style.minimal_width = 96
    b.enabled = false
end

local function set_difficulty()
    local index = highest_count(this.difficulties)
    if not index or not this.difficulties[index] then
        return
    end

    if this.difficulty_vote_index ~= index then
        local message = table.concat({'*** Map difficulty has changed to ', this.difficulties[index].name, ' difficulty! ***'})
        game.print(message, this.difficulties[index].print_color)
        Server.to_discord_embed(message)
    end
    this.difficulty_vote_index = index
    this.difficulty_vote_value = this.difficulties[index].value
    this.boss_modifier = this.difficulties[index].boss_modifier
    this.strength_modifier = this.difficulties[index].strength_modifier
end

function Public.reset_difficulty_poll(tbl)
    if tbl then
        this.difficulty_vote_value = tbl.difficulty_vote_value or 0.75
        this.difficulty_vote_index = tbl.difficulty_vote_index or 1
        this.difficulty_player_votes = {}
        this.difficulty_poll_closing_timeout = tbl.difficulty_poll_closing_timeout or game.tick + 54000
        for _, p in pairs(game.connected_players) do
            if p.gui.center[main_frame_name] then
                clear_main_frame(p)
            end
            poll_difficulty(p)
        end
        for _, vote in pairs(this.difficulties) do
            vote.count = 0
        end
        Public.difficulty_gui()
    else
        this.difficulty_vote_value = 0.75
        this.difficulty_vote_index = 1
        this.difficulty_player_votes = {}
        this.difficulty_poll_closing_timeout = game.tick + 54000
        for _, p in pairs(game.connected_players) do
            if p.gui.center[main_frame_name] then
                clear_main_frame(p)
            end
            poll_difficulty(p)
        end
        for _, vote in pairs(this.difficulties) do
            vote.count = 0
        end
        Public.difficulty_gui()
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if game.tick < this.difficulty_poll_closing_timeout then
        if not this.difficulty_player_votes[player.name] then
            poll_difficulty(player)
        end
    else
        clear_main_frame(player)
    end
    Public.difficulty_gui()
end

local function on_player_left_game(event)
    if game.tick > this.difficulty_poll_closing_timeout then
        return
    end
    local player = game.get_player(event.player_index)
    if not this.difficulty_player_votes[player.name] then
        return
    end
    local index = this.difficulty_player_votes[player.name].index
    this.difficulties[index].count = this.difficulties[index].count - 1
    if this.difficulties[index].count <= 0 then
        this.difficulties[index].count = 0
    end
    this.difficulty_player_votes[player.name] = nil
    set_difficulty()
    Public.difficulty_gui()
end

function Public.set_tooltip(...)
    if type(...) == 'table' then
        this.tooltip = ...
    end
end

function Public.set_difficulties(...)
    if type(...) == 'table' then
        this.difficulties = ...
    end
end

function Public.set_poll_closing_timeout(...)
    this.difficulty_poll_closing_timeout = ...
end

function Public.get_fair_vote()
    return this.fair_vote
end

function Public.set_fair_vote(value)
    this.fair_vote = value or false
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

Gui.on_click(
    selection_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Poll difficulty selection frame name')
        if is_spamming then
            return
        end
        local element = event.element
        if not element or not element.valid then
            return
        end

        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local i = tonumber(element.parent.name)

        if this.difficulty_player_votes[player.name] and this.difficulty_player_votes[player.name].index == i then
            player.print('You have already voted for ' .. this.difficulties[i].name .. '.', this.difficulties[i].print_color)
            clear_main_frame(player)
            return
        end

        if this.difficulty_player_votes[player.name] then
            local index = this.difficulty_player_votes[player.name].index
            this.difficulties[index].count = this.difficulties[index].count - 1
            if this.difficulties[index].count <= 0 then
                this.difficulties[index].count = 0
            end
        end

        this.difficulties[i].count = this.difficulties[i].count + 1
        this.difficulty_player_votes[player.name] = {voted = true, index = i}

        set_difficulty()
        Public.difficulty_gui()
        clear_main_frame(player)
        local message = '*** ' .. player.name .. ' has voted for ' .. this.difficulties[i].name .. ' difficulty! ***'
        game.print(message, this.difficulties[i].print_color)
        Server.to_discord_embed(message)
    end
)

Gui.on_click(
    top_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Poll difficulty top button')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end
        if game.tick > this.difficulty_poll_closing_timeout then
            clear_main_frame(player)
            return
        end
        local screen = player.gui.center
        if screen[main_frame_name] and screen[main_frame_name].valid then
            clear_main_frame(player)
        else
            poll_difficulty(player)
        end
    end
)

Gui.on_click(
    close_main_frame,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Poll difficulty close button')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end
        clear_main_frame(player)
    end
)

Event.add(defines.events.on_player_created, on_player_joined_game)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)

Public.top_button_name = top_button_name

return Public
