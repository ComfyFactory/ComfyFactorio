-- level up ranks with launching satellites -- by mewmew

local Event = require 'utils.event'
local Server = require 'utils.server'
local Global = require 'utils.global'

local this = {}
Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local function get_rank()
    for i = #this.satellite_score, 1, -1 do
        if this.satellites_in_space >= this.satellite_score[i].goal then
            return i
        end
    end
end

local function satellite_score_toggle_button(player)
    if player.gui.top['satellite_score_toggle_button'] then
        return
    end
    local button = player.gui.top.add {name = 'satellite_score_toggle_button', type = 'sprite-button', sprite = 'item/satellite', tooltip = 'Satellites in Space'}
    button.style.font = 'default-bold'
    button.style.minimal_height = 38
    button.style.maximal_height = 38
    button.style.minimal_width = 38
    button.style.padding = 1
end
--[[
local function level_up_popup(player)
    local reward = global.satellite_score[get_rank()]
    if player.gui.center['level_up_popup'] then
        player.gui.center['level_up_popup'].destroy()
    end
    local frame = player.gui.center.add({type = 'frame', name = 'level_up_popup', direction = 'vertical'})
    local label = frame.add({type = 'label', caption = reward.msg})
    label.style.font = 'default-listbox'
    label.style.font_color = reward.color
    local button = frame.add({type = 'button', caption = reward.msg2, name = 'level_up_popup_close'})
    button.style.minimal_width = string.len(reward.msg) * 7
    button.style.font = 'default-listbox'
    button.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
end ]]
local function satellites_in_space_gui(player)
    --if global.satellites_in_space == 0 then return end
    local i = get_rank()

    if player.gui.left['satellites_in_space'] then
        player.gui.left['satellites_in_space'].destroy()
    end

    local frame = player.gui.left.add({type = 'frame', name = 'satellites_in_space'})
    local label = frame.add({type = 'label', caption = 'Satellites launched: '})
    label.style.font_color = {r = 0.11, g = 0.8, b = 0.44}

    local progress = (this.satellites_in_space - this.satellite_score[i].goal) / (this.satellite_score[i + 1].goal - this.satellite_score[i].goal)
    if progress > 1 then
        progress = 1
    end
    local progressbar = frame.add({type = 'progressbar', value = progress})
    progressbar.style = 'achievement_progressbar'
    progressbar.style.minimal_width = 100
    progressbar.style.maximal_width = 100

    label = frame.add({type = 'label', caption = this.satellites_in_space .. '/' .. tostring(this.satellite_score[i + 1].goal)})
    label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

    if this.satellite_score[i].rank then
        label = frame.add({type = 'label', caption = '  ~Rank~'})
        label.style.font_color = {r = 0.75, g = 0.75, b = 0.75}
        label = frame.add({type = 'label', caption = this.satellite_score[i].rank})
        label.style.font = 'default-bold'
        label.style.font_color = this.satellite_score[i].color
    end
end

local function on_rocket_launched(event)
    local rocket_inventory = event.rocket.get_inventory(defines.inventory.rocket)
    local c = rocket_inventory.get_item_count('satellite')
    if c == 0 then
        return
    end
    this.satellites_in_space = this.satellites_in_space + c

    local i = get_rank()

    for _, player in pairs(game.connected_players) do
        satellites_in_space_gui(player)
    end

    if not this.satellite_score[i].achieved then
        for _, player in pairs(game.connected_players) do
            player.play_sound {path = 'utility/game_won', volume_modifier = 0.9}
            --level_up_popup(player)
        end
        this.satellite_score[i].achieved = true
    end
    if (this.satellites_in_space < 10) or ((this.satellites_in_space < 50) and ((this.satellites_in_space % 5) == 0)) or ((this.satellites_in_space % 25) == 0) then
        local message = 'A satellite has been launched! Total count: ' .. this.satellites_in_space
        game.print(message)
        Server.to_discord_embed(message)
    end
end

local function init()
    this.satellites_in_space = 0
    this.satellite_score = {
        {goal = 0, rank = false, achieved = true},
        {goal = 1, rank = 'Copper', color = {r = 201, g = 133, b = 6}, msg = '', msg2 = '', achieved = false},
        {goal = 10, rank = 'Iron', color = {r = 219, g = 216, b = 206}, msg = '', msg2 = '', achieved = false},
        {goal = 100, rank = 'Bronze', color = {r = 186, g = 115, b = 39}, msg = '', msg2 = '', achieved = false},
        {goal = 500, rank = 'Silver', color = {r = 186, g = 178, b = 171}, msg = '', msg2 = '', achieved = false},
        {goal = 1000, rank = 'Gold', color = {r = 255, g = 214, b = 33}, msg = '', msg2 = '', achieved = false},
        {goal = 2500, rank = 'Platinum', color = {r = 224, g = 223, b = 215}, msg = '', msg2 = '', achieved = false},
        {goal = 5000, rank = 'Diamond', color = {r = 237, g = 236, b = 232}, msg = '', msg2 = '', achieved = false},
        {goal = 10000, rank = 'Iridium', color = {r = 255, g = 220, b = 220}, msg = '', msg2 = '', achieved = false},
        {goal = 20000, rank = 'Anti-Matter', color = {r = 190, g = 255, b = 190}, msg = '', msg2 = '', achieved = false},
        {goal = 30000, rank = 'Orange Dwarf', color = {r = 255, g = 150, b = 50}, msg = '', msg2 = '', achieved = false},
        {goal = 40000, rank = 'Blue Supergiant', color = {r = 130, g = 130, b = 255}, msg = '', msg2 = '', achieved = false},
        {goal = 50000, rank = 'Red Hypergiant', color = {r = 255, g = 90, b = 90}, msg = '', msg2 = '', achieved = false},
        {goal = 75000, rank = 'Neutron Star', color = {r = 200, g = 200, b = 255}, msg = '', msg2 = '', achieved = false},
        {goal = 100000, rank = 'Supernova', color = {r = 200, g = 255, b = 200}, msg = '', msg2 = '', achieved = false},
        {goal = 150000, rank = 'Black Hole', color = {r = 0, g = 0, b = 0}, msg = '', msg2 = '', achieved = false},
        {goal = 1000000, rank = 'Blue Screen', color = {r = 100, g = 100, b = 245}, msg = '', msg2 = '', achieved = false},
        {goal = 10000000, rank = '?????', color = {r = 0, g = 0, b = 0}, msg = '', msg2 = '', achieved = false},
        {goal = 1000000000, rank = '?!??!?', color = {r = 0, g = 0, b = 0}, msg = '', msg2 = '', achieved = false}
    }
end

local function on_player_joined_game(event)
    if not this.satellites_in_space then
        init()
    end
    local player = game.players[event.player_index]
    satellite_score_toggle_button(player)

    if player.gui.left['satellites_in_space'] or this.satellites_in_space > 0 then
        satellites_in_space_gui(player)
    end
end

local function on_gui_click(event)
    if not event then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local player = game.players[event.element.player_index]
    local name = event.element.name

    if name == 'satellite_score_toggle_button' then
        local frame = player.gui.left['satellites_in_space']
        if frame then
            frame.destroy()
        else
            satellites_in_space_gui(player)
        end
    end

    if name == 'level_up_popup_close' then
        player.gui.center['level_up_popup'].destroy()
    end
end

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
