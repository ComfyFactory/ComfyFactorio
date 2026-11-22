local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'
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

    local t = frame.add { type = 'table', column_count = 3 }
    t.style.horizontal_spacing = Style.spacing.xs
    local width = math.max(250, Style.content_width(data.player, frame))
    local widths = Style.column_widths(width - 36 - Style.spacing.xs, { 1, 1 }, Style.spacing.xs)

    local label = t.add({ type = 'label', caption = '#' })
    label.style.width = 36
    Style.table_heading(label)
    label.style.padding = 3
    local player_label = t.add({ type = 'label', caption = 'Player:' })
    player_label.style.width = widths[1]
    Style.table_heading(player_label)
    player_label.style.padding = 3
    local desc_label = t.add({ type = 'label', caption = storage.custom_highscore.description })
    desc_label.style.width = widths[2]
    Style.table_heading(desc_label)
    desc_label.style.padding = 3

    for key, score in ipairs(get_sorted_score()) do
        local key_label = t.add({ type = 'label', caption = key })
        key_label.style.font = 'default'
        key_label.style.padding = 1
        local scoreName_label = t.add({ type = 'label', caption = score.name, tooltip = score.name })
        scoreName_label.style.font = 'default'
        scoreName_label.style.padding = 1
        scoreName_label.style.width = widths[1]
        scoreName_label.style.single_line = true
        scoreName_label.style.font_color = game.players[score.name].chat_color
        local points_label = t.add({ type = 'label', caption = score.points })
        points_label.style.font = 'default'
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
    storage.custom_highscore =
    {
        description = 'Won rounds:',
        score_list = {}
    }
end

local function on_init()
    storage.custom_highscore =
    {
        description = 'Won rounds:',
        score_list = {}
    }
end

Gui.add_tab_to_gui({ name = module_name, caption = 'Map Scores', id = score_list_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player, nil, 'Map Scores')
    end
)

Event.on_init(on_init)

return Public
