local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Token = require 'utils.token'

local module_name = Gui.uid_name()

local Public = {}

local function get_sorted_score()
    local list = {}
    for player_index, score_points in pairs(storage.custom_highscore.score_list) do
        table.insert(list, { name = game.players[player_index].name, points = score_points })
    end
    local list_size = #list
    if list_size == 0 then
        return list
    end
    table.sort(
        list,
        function (a, b)
            return a.points > b.points
        end
    )
    return list
end

local function score_list(data)
    local frame = data.frame
    frame.clear()
    frame.style.padding = 4
    frame.style.margin = 0

    local line = frame.add { type = 'line' }
    line.style.top_margin = 4
    line.style.bottom_margin = 4

    local scroll_pane = frame.add { type = 'scroll-pane', name = 'scroll_pane', direction = 'vertical', horizontal_scroll_policy = 'never', vertical_scroll_policy = 'auto' }
    scroll_pane.style.minimal_width = 780
    scroll_pane.style.maximal_height = 360
    scroll_pane.style.minimal_height = 360

    local t = scroll_pane.add { type = 'table', column_count = 3 }

    local label = t.add({ type = 'label', caption = '#' })
    label.style.minimal_width = 30
    label.style.font = 'heading-2'
    label.style.padding = 3
    local player_label = t.add({ type = 'label', caption = 'Player:' })
    player_label.style.minimal_width = 160
    player_label.style.font = 'heading-2'
    player_label.style.padding = 3
    local desc_label = t.add({ type = 'label', caption = storage.custom_highscore.description })
    desc_label.style.minimal_width = 160
    desc_label.style.font = 'heading-2'
    desc_label.style.padding = 3

    for key, score in pairs(get_sorted_score()) do
        local key_label = t.add({ type = 'label', caption = key })
        key_label.style.font = 'heading-2'
        key_label.style.padding = 1
        local scoreName_label = t.add({ type = 'label', caption = score.name })
        scoreName_label.style.font = 'heading-2'
        scoreName_label.style.padding = 1
        scoreName_label.style.font_color = game.players[score.name].chat_color
        local points_label = t.add({ type = 'label', caption = score.points })
        points_label.style.font = 'heading-2'
        points_label.style.padding = 1
    end
end

local score_list_token = Token.register(score_list)

function Public.set_score_description(str)
    storage.custom_highscore.description = str
end

function Public.set_score(player, count)
    local score_lists = storage.custom_highscore.score_list
    score_lists[player.index] = count
end

function Public.get_score(player)
    local score_lists = storage.custom_highscore.score_list
    if not score_lists[player.index] then
        score_lists[player.index] = 0
    end
    return score_lists[player.index]
end

function Public.reset_score()
    storage.custom_highscore = {
        description = 'Won rounds:',
        score_list = {}
    }
end

local function on_init()
    storage.custom_highscore = {
        description = 'Won rounds:',
        score_list = {}
    }
end

Gui.add_tab_to_gui({ name = module_name, caption = 'Map Scores', id = score_list_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player)
    end
)

Event.on_init(on_init)

return Public
