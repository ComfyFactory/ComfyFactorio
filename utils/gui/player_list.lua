--[[
Hello there!

This will add a player list with "ranks" to your server.
Oh.. and you can also "poke" a player.
pokemessages = 80% by redlabel

To install, add: require "player_list"
to your scenario control.lua.

---MewMew---

Minor changes by ~~~Gerkiz~~~
--]]
local Event = require 'utils.event'
local Where = require 'utils.commands.where'
local Session = require 'utils.datastore.session_data'
local Jailed = require 'utils.datastore.jail_data'
local Supporters = require 'utils.datastore.supporters'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local SpamProtection = require 'utils.spam_protection'
local RPG = require 'modules.rpg.table'
local Token = require 'utils.token'

local Public = {}

local module_name = Gui.uid_name()

local this = {
    player_list = {
        last_poke_tick = {},
        pokes = {},
        sorting_method = {}
    },
    rpg_enabled = false,
    show_roles_in_list = false
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local symbol_asc = '▲'
local symbol_desc = '▼'

local pokemessages = {
    'a stick',
    'a leaf',
    'a moldy carrot',
    'a crispy slice of bacon',
    'a french fry',
    'a realistic toygun',
    'a broomstick',
    'a thirteen inch iron stick',
    'a mechanical keyboard',
    'a fly fishing cane',
    'a selfie stick',
    'an oversized fidget spinner',
    'a thumb extender',
    'a dirty straw',
    'a green bean',
    'a banana',
    'an umbrella',
    "grandpa's walking stick",
    'live firework',
    'a toilet brush',
    'a fake hand',
    'an undercooked hotdog',
    "a slice of yesterday's microwaved pizza",
    'bubblegum',
    'a biter leg',
    "grandma's toothbrush",
    'charred octopus',
    'a dollhouse bathtub',
    'a length of copper wire',
    'a decommissioned nuke',
    'a smelly trout',
    'an unopened can of deodorant',
    'a stone brick',
    'a half full barrel of lube',
    'a half empty barrel of lube',
    'an unexploded cannon shell',
    'a blasting programmable speaker',
    'a not so straight rail',
    'a mismatched pipe to ground',
    'a surplus box of landmines',
    'decommissioned yellow rounds',
    'an oily pumpjack shaft',
    'a melted plastic bar in the shape of the virgin mary',
    'a bottle of watermelon vitamin water',
    'a slice of watermelon',
    'a stegosaurus tibia',
    "a basking musician's clarinet",
    'a twig',
    'an undisclosed pokey item',
    'a childhood trophy everyone else got',
    'a dead starfish',
    'a titanium toothpick',
    'a nail file',
    'a stamp collection',
    'a bucket of lego',
    'a rolled up carpet',
    'a rolled up WELCOME doormat',
    "Bobby's favorite bone",
    'an empty bottle of cheap vodka',
    'a tattooing needle',
    'a peeled cucumber',
    'a stack of cotton candy',
    'a signed baseball bat',
    'that 5 dollar bill grandma sent for christmas',
    'a stack of overdue phone bills',
    "the 'relax' section of the white pages",
    'a bag of gym clothes which never made it to the washing machine',
    'a handful of peanut butter',
    "a pheasant's feather",
    'a rusty pickaxe',
    'a diamond sword',
    'the bill of rights of a banana republic',
    "one of those giant airport Toblerone's",
    'a long handed inserter',
    'a wiimote',
    'an easter chocolate rabbit',
    'a ball of yarn the cat threw up',
    'a slightly expired but perfectly edible cheese sandwich',
    'conclusive proof of lizard people existence',
    'a pen drive full of high res wallpapers',
    'a pet hamster',
    'an oversized goldfish',
    'a one foot extension cord',
    "a CD from Walmart's 1 dollar bucket",
    'a magic wand',
    'a list of disappointed people who believed in you',
    'murder exhibit no. 3',
    "a paperback copy of 'Great Expectations'",
    'a baby biter',
    'a little biter fang',
    'the latest diet fad',
    'a belt that no longer fits you',
    'an abandoned pet rock',
    'a lava lamp',
    'some spirit herbs',
    'a box of fish sticks found at the back of the freezer',
    'a bowl of tofu rice',
    'a bowl of ramen noodles',
    'a live lobster!',
    'a miniature golf cart',
    'dunce cap',
    'a fully furnished x-mas tree',
    'an orphaned power pole',
    'an horphaned power pole',
    'an box of overpriced girl scout cookies',
    'the cheapest item from the yard sale',
    'a Sharpie',
    'a glowstick',
    'a thick unibrow hair',
    'a very detailed map of Kazakhstan',
    'the official Factorio installation DVD',
    'a Liberal Arts degree',
    'a pitcher of Kool-Aid',
    'a 1/4 pound vegan burrito',
    'a bottle of expensive wine',
    'a hamster sized gravestone',
    'a counterfeit Cuban cigar',
    'an old Nokia phone',
    'a huge inferiority complex',
    'a dead real state agent',
    'a deck of tarot cards',
    'unreleased Wikileaks documents',
    'a mean-looking garden dwarf',
    'the actual mythological OBESE cat',
    'a telescope used to spy on the MILF next door',
    'a fancy candelabra',
    'the comic version of the Kama Sutra',
    "an inflatable 'Netflix & chill' doll",
    'whatever it is redlabel gets high on',
    "Obama's birth certificate",
    'a deck of Cards Against Humanity',
    'a copy of META MEME HUMOR for Dummies',
    'an abandoned, not-so-young-anymore puppy',
    'one of those useless items advertised on TV',
    'a genetic blueprint of a Japanese teen idol'
}

local function get_formatted_playtime(x)
    if x < 5184000 then
        local y = x / 216000
        y = tostring(y)
        local h = ''
        for i = 1, 10, 1 do
            local z = string.sub(y, i, i)

            if z == '.' then
                break
            else
                h = h .. z
            end
        end

        local m = x % 216000
        m = m / 3600
        m = math.floor(m)
        m = tostring(m)

        if h == '0' then
            local str = m .. ' minutes'
            return str
        else
            local str = h .. ' hours '
            str = str .. m
            str = str .. ' minutes'
            return str
        end
    else
        local y = x / 5184000
        y = tostring(y)
        local h = ''
        for i = 1, 10, 1 do
            local z = string.sub(y, i, i)

            if z == '.' then
                break
            else
                h = h .. z
            end
        end

        local m = x % 5184000
        m = m / 216000
        m = math.floor(m)
        m = tostring(m)

        if h == '0' then
            local str = m .. ' days'
            return str
        else
            local str = h .. ' days '
            str = str .. m
            str = str .. ' hours'
            return str
        end
    end
end

local function get_rank(player)
    local play_table = Session.get_session_table()
    local t = 0
    if play_table then
        if play_table[player.name] then
            t = play_table[player.name]
        end
    end

    local m = t / 3600

    local ranks = {
        'item/burner-mining-drill',
        'item/burner-inserter',
        'item/stone-furnace',
        'item/light-armor',
        'item/steam-engine',
        'item/inserter',
        'item/transport-belt',
        'item/underground-belt',
        'item/splitter',
        'item/assembling-machine-1',
        'item/long-handed-inserter',
        'item/electronic-circuit',
        'item/electric-mining-drill',
        'item/dummy-steel-axe',
        'item/heavy-armor',
        'item/steel-furnace',
        'item/gun-turret',
        'item/fast-transport-belt',
        'item/fast-underground-belt',
        'item/fast-splitter',
        'item/assembling-machine-2',
        'item/fast-inserter',
        'item/radar',
        'item/filter-inserter',
        'item/defender-capsule',
        'item/pumpjack',
        'item/chemical-plant',
        'item/solar-panel',
        'item/advanced-circuit',
        'item/modular-armor',
        'item/accumulator',
        'item/construction-robot',
        'item/distractor-capsule',
        'item/stack-inserter',
        'item/electric-furnace',
        'item/express-transport-belt',
        'item/express-underground-belt',
        'item/express-splitter',
        'item/assembling-machine-3',
        'item/processing-unit',
        'item/power-armor',
        'item/logistic-robot',
        'item/laser-turret',
        'item/stack-filter-inserter',
        'item/destroyer-capsule',
        'item/power-armor-mk2',
        'item/flamethrower-turret',
        'item/beacon',
        'item/steam-turbine',
        'item/centrifuge',
        'item/nuclear-reactor',
        'item/cannon-shell',
        'item/rocket',
        'item/explosive-cannon-shell',
        'item/explosive-rocket',
        'item/uranium-cannon-shell',
        'item/explosive-uranium-cannon-shell',
        'item/atomic-bomb',
        'achievement/so-long-and-thanks-for-all-the-fish',
        'achievement/golem'
    }

    --60? ranks

    local time_needed = 240 -- in minutes between rank upgrades
    m = m / time_needed
    m = math.floor(m)
    m = m + 1

    if m > #ranks then
        m = #ranks
    end

    return ranks[m]
end

local comparators = {
    ['pokes_asc'] = function(a, b)
        return a.pokes > b.pokes
    end,
    ['pokes_desc'] = function(a, b)
        return a.pokes < b.pokes
    end,
    ['total_time_played_asc'] = function(a, b)
        return a.total_played_ticks < b.total_played_ticks
    end,
    ['total_time_played_desc'] = function(a, b)
        return a.total_played_ticks > b.total_played_ticks
    end,
    ['time_played_asc'] = function(a, b)
        return a.played_ticks < b.played_ticks
    end,
    ['time_played_desc'] = function(a, b)
        return a.played_ticks > b.played_ticks
    end,
    ['rpg_asc'] = function(a, b)
        return a.rpg_level < b.rpg_level
    end,
    ['rpg_desc'] = function(a, b)
        return a.rpg_level > b.rpg_level
    end,
    ['name_asc'] = function(a, b)
        return a.name:lower() < b.name:lower()
    end,
    ['name_desc'] = function(a, b)
        return a.name:lower() > b.name:lower()
    end
}

local function get_comparator(sort_by)
    return comparators[sort_by]
end

local function get_sorted_list(sort_by)
    local play_table = Session.get_session_table()
    local player_list = {}
    local players = game.connected_players
    for i, player in pairs(players) do
        player_list[i] = {}
        player_list[i].rank = get_rank(player)
        player_list[i].name = player.name

        local t = 0
        if play_table[player.name] then
            t = play_table[player.name]
        end

        if this.rpg_enabled then
            local char = RPG.get_value_from_player(player.index, 'level')
            if not char then
                char = 1
            end

            player_list[i].rpg_level = char
        end

        player_list[i].total_played_time = get_formatted_playtime(t)
        player_list[i].total_played_ticks = t

        player_list[i].played_time = get_formatted_playtime(player.online_time)
        player_list[i].played_ticks = player.online_time

        player_list[i].pokes = this.player_list.pokes[player.index]
        player_list[i].player_index = player.index
    end

    local comparator = get_comparator(sort_by)
    table.sort(player_list, comparator)

    return player_list
end

local function player_list_show(data)
    local player = data.player
    local frame = data.frame
    local sort_by = data.sort_by
    -- Frame management
    frame.clear()
    frame.style.padding = 8
    local play_table = Session.get_trusted_table()
    local jailed = Jailed.get_jailed_table()

    -- Header management
    local t
    local column_widths
    local header_column_widths
    local headers
    local header_modifier

    if this.rpg_enabled then
        t = frame.add {type = 'table', name = 'player_list_panel_header_table', column_count = 6}
        column_widths = {
            ['first_space'] = tonumber(40),
            ['name_label'] = tonumber(155),
            ['rpg_level_label'] = tonumber(138),
            ['total_label'] = tonumber(145),
            ['current_label'] = tonumber(165),
            ['last_space'] = tonumber(50)
        }

        header_column_widths = {
            ['first_space'] = tonumber(35),
            ['name_label'] = tonumber(150),
            ['rpg_level_label'] = tonumber(135),
            ['total_label'] = tonumber(150),
            ['current_label'] = tonumber(168),
            ['last_space'] = tonumber(50)
        }

        for _, w in pairs(header_column_widths) do
            local label = t.add {type = 'label', caption = ''}
            label.style.minimal_width = w
            label.style.maximal_width = w
        end

        headers = {
            [1] = '[color=0.1,0.7,0.1]' .. -- green
                tostring(#game.connected_players) .. '[/color]',
            [2] = 'Online' ..
                ' / ' ..
                    '[color=0.7,0.1,0.1]' .. -- red
                        tostring(#game.players - #game.connected_players) .. '[/color]' .. ' Offline',
            [3] = 'RPG level',
            [4] = 'Total Time',
            [5] = 'Current Time',
            [6] = 'Poke'
        }
        header_modifier = {
            ['name_asc'] = function(h)
                h[2] = h[2] .. symbol_asc
            end,
            ['name_desc'] = function(h)
                h[2] = h[2] .. symbol_desc
            end,
            ['rpg_asc'] = function(h)
                h[3] = h[3] .. symbol_asc
            end,
            ['rpg_desc'] = function(h)
                h[3] = h[3] .. symbol_desc
            end,
            ['total_time_played_asc'] = function(h)
                h[4] = h[4] .. symbol_asc
            end,
            ['total_time_played_desc'] = function(h)
                h[4] = h[4] .. symbol_desc
            end,
            ['time_played_asc'] = function(h)
                h[5] = h[5] .. symbol_asc
            end,
            ['time_played_desc'] = function(h)
                h[5] = h[5] .. symbol_desc
            end,
            ['pokes_asc'] = function(h)
                h[6] = h[6] .. symbol_asc
            end,
            ['pokes_desc'] = function(h)
                h[6] = h[6] .. symbol_desc
            end
        }
    else
        t = frame.add {type = 'table', name = 'player_list_panel_header_table', column_count = 5}
        column_widths = {
            ['first_space'] = tonumber(40),
            ['name_label'] = tonumber(218),
            ['total_label'] = tonumber(220),
            ['current_label'] = tonumber(222),
            ['last_space'] = tonumber(50)
        }
        header_column_widths = {
            ['first_space'] = tonumber(40),
            ['name_label'] = tonumber(210),
            ['total_label'] = tonumber(220),
            ['current_label'] = tonumber(226),
            ['last_space'] = tonumber(50)
        }
        for _, w in pairs(header_column_widths) do
            local label = t.add {type = 'label', caption = ''}
            label.style.minimal_width = w
            label.style.maximal_width = w
        end

        headers = {
            [1] = '[color=0.1,0.7,0.1]' .. -- green
                tostring(#game.connected_players) .. '[/color]',
            [2] = 'Online' ..
                ' / ' ..
                    '[color=0.7,0.1,0.1]' .. -- red
                        tostring(#game.players - #game.connected_players) .. '[/color]' .. ' Offline',
            [3] = 'Total Time',
            [4] = 'Current Time',
            [5] = 'Poke'
        }
        header_modifier = {
            ['name_asc'] = function(h)
                h[2] = symbol_asc .. h[2]
            end,
            ['name_desc'] = function(h)
                h[2] = symbol_desc .. h[2]
            end,
            ['total_time_played_asc'] = function(h)
                h[3] = symbol_asc .. h[3]
            end,
            ['total_time_played_desc'] = function(h)
                h[3] = symbol_desc .. h[3]
            end,
            ['time_played_asc'] = function(h)
                h[4] = symbol_asc .. h[4]
            end,
            ['time_played_desc'] = function(h)
                h[4] = symbol_desc .. h[4]
            end,
            ['pokes_asc'] = function(h)
                h[5] = symbol_asc .. h[5]
            end,
            ['pokes_desc'] = function(h)
                h[5] = symbol_desc .. h[5]
            end
        }
    end

    if sort_by then
        this.player_list.sorting_method[player.index] = sort_by
    else
        sort_by = this.player_list.sorting_method[player.index]
    end

    if not sort_by then
        sort_by = 'total_time_played_desc'
    end

    header_modifier[sort_by](headers)

    for k, v in ipairs(headers) do
        local header_label =
            t.add {
            type = 'label',
            name = 'player_list_panel_header_' .. k,
            caption = v
        }
        header_label.style.font = 'heading-2'
        header_label.style.font_color = {r = 0.98, g = 0.66, b = 0.22}
    end

    -- special style on first header
    local label = t['player_list_panel_header_1']
    label.style.minimal_width = 36
    label.style.maximal_width = 36
    label.style.horizontal_align = 'right'

    -- List management
    local player_list_panel_table =
        frame.add {
        type = 'scroll-pane',
        name = 'scroll_pane',
        direction = 'vertical',
        horizontal_scroll_policy = 'never',
        vertical_scroll_policy = 'auto'
    }
    player_list_panel_table.style.maximal_height = 530

    if this.rpg_enabled then
        player_list_panel_table = player_list_panel_table.add {type = 'table', name = 'player_list_panel_table', column_count = 6}
    else
        player_list_panel_table = player_list_panel_table.add {type = 'table', name = 'player_list_panel_table', column_count = 5}
    end

    local player_list = get_sorted_list(sort_by)
    for i = 1, #player_list, 1 do
        -- fetch the supporter list
        local supporter, supportertbl = Supporters.is_supporter(player_list[i].name)

        -- Icon
        local sprite =
            player_list_panel_table.add {
            type = 'sprite',
            name = 'player_rank_sprite_' .. i,
            sprite = player_list[i].rank
        }
        sprite.style.height = 32
        sprite.style.width = 32
        sprite.style.stretch_image_to_widget_size = true

        local trusted = ''
        local tooltip = ''
        local minimap = '\nLeft-click to show this person on map! '

        if supporter then
            if supportertbl.monthly then
                trusted = '[color=yellow][DM][/color]'
                tooltip = '\nThis player is a monthly supporter.'
            else
                trusted = '[color=yellow][D][/color]'
                tooltip = '\nThis player has supported us.'
            end
        end

        if game.players[player_list[i].name].admin then
            trusted = '[color=red][A][/color]' .. trusted
            tooltip = 'This player is an admin of this server.' .. tooltip
        elseif jailed[player_list[i].name] then
            trusted = '[color=orange][J][/color]' .. trusted
            tooltip = 'This player is currently jailed.' .. minimap .. tooltip
        elseif play_table[player_list[i].name] then
            trusted = '[color=green][T][/color]' .. trusted
            tooltip = 'This player is trusted.' .. minimap .. tooltip
        else
            trusted = '[color=black][U][/color]' .. trusted
            tooltip = 'This player is not trusted.' .. minimap .. tooltip
        end

        local caption
        if this.show_roles_in_list or game.players[player_list[i].name].admin then
            caption = player_list[i].name .. ' ' .. trusted
        else
            caption = player_list[i].name
        end

        -- Name
        local p = game.players[player_list[i].name]
        if not p or not p.valid then
            return
        end

        local name_label =
            player_list_panel_table.add {
            type = 'label',
            name = p.index,
            caption = caption,
            tooltip = tooltip
        }

        local p_color = game.players[player_list[i].player_index]
        name_label.style.font = 'default'
        name_label.style.font_color = {
            r = .4 + p_color.color.r * 0.6,
            g = .4 + p_color.color.g * 0.6,
            b = .4 + p_color.color.b * 0.6
        }
        name_label.style.minimal_width = column_widths['name_label']
        name_label.style.maximal_width = column_widths['name_label']
        name_label.style.font = 'heading-3'

        -- RPG level
        if this.rpg_enabled then
            -- RPG level
            local rpg_level_label =
                player_list_panel_table.add {
                type = 'label',
                name = 'player_list_panel_RPG_level_' .. i,
                caption = player_list[i].rpg_level
            }
            rpg_level_label.style.minimal_width = column_widths['rpg_level_label']
            rpg_level_label.style.maximal_width = column_widths['rpg_level_label']
            rpg_level_label.style.font = 'heading-3'
        end

        -- Total time
        local total_label =
            player_list_panel_table.add {
            type = 'label',
            name = 'player_list_panel_player_total_time_played_' .. i,
            caption = player_list[i].total_played_time
        }
        total_label.style.minimal_width = column_widths['total_label']
        total_label.style.maximal_width = column_widths['total_label']
        total_label.style.font = 'heading-3'

        -- Current time
        local current_label =
            player_list_panel_table.add {
            type = 'label',
            name = 'player_list_panel_player_time_played_' .. i,
            caption = player_list[i].played_time
        }
        current_label.style.minimal_width = column_widths['current_label']
        current_label.style.maximal_width = column_widths['current_label']
        current_label.style.font = 'heading-3'

        -- Poke
        local flow = player_list_panel_table.add {type = 'flow', name = 'button_flow_' .. i, direction = 'horizontal'}
        flow.add {type = 'label', name = 'button_spacer_' .. i, caption = ''}
        local button = flow.add {type = 'button', name = 'poke_player_' .. player_list[i].name, caption = player_list[i].pokes}
        button.style.font = 'default'
        button.tooltip = 'Poke ' .. player_list[i].name .. ' with a random message!'
        label.style.font_color = {r = 0.83, g = 0.83, b = 0.83}
        button.style.minimal_height = 30
        button.style.minimal_width = 30
        button.style.maximal_height = 30
        button.style.maximal_width = 30
        button.style.top_padding = 0
        button.style.left_padding = 0
        button.style.right_padding = 0
        button.style.bottom_padding = 0
    end
end

local player_list_show_token = Token.register(player_list_show)

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local name = element.name
    local player = game.get_player(event.player_index)

    local frame = Gui.get_player_active_frame(player)
    if not frame then
        return
    end
    if frame.name ~= 'Players' then
        return
    end

    local actions
    if this.rpg_enabled then
        actions = {
            ['player_list_panel_header_2'] = function()
                if string.find(element.caption, symbol_desc) then
                    local data = {player = player, frame = frame, sort_by = 'name_asc'}
                    player_list_show(data)
                else
                    local data = {player = player, frame = frame, sort_by = 'name_desc'}
                    player_list_show(data)
                end
            end,
            ['player_list_panel_header_3'] = function()
                if string.find(event.element.caption, symbol_desc) then
                    local data = {player = player, frame = frame, sort_by = 'rpg_asc'}
                    player_list_show(data)
                else
                    local data = {player = player, frame = frame, sort_by = 'rpg_desc'}
                    player_list_show(data)
                end
            end,
            ['player_list_panel_header_4'] = function()
                if string.find(element.caption, symbol_desc) then
                    local data = {player = player, frame = frame, sort_by = 'total_time_played_asc'}
                    player_list_show(data)
                else
                    local data = {player = player, frame = frame, sort_by = 'total_time_played_desc'}
                    player_list_show(data)
                end
            end,
            ['player_list_panel_header_5'] = function()
                if string.find(element.caption, symbol_desc) then
                    local data = {player = player, frame = frame, sort_by = 'time_played_asc'}
                    player_list_show(data)
                else
                    local data = {player = player, frame = frame, sort_by = 'time_played_desc'}
                    player_list_show(data)
                end
            end,
            ['player_list_panel_header_6'] = function()
                if string.find(element.caption, symbol_desc) then
                    local data = {player = player, frame = frame, sort_by = 'pokes_asc'}
                    player_list_show(data)
                else
                    local data = {player = player, frame = frame, sort_by = 'pokes_desc'}
                    player_list_show(data)
                end
            end
        }
    else
        actions = {
            ['player_list_panel_header_2'] = function()
                if string.find(element.caption, symbol_desc) then
                    local data = {player = player, frame = frame, sort_by = 'name_asc'}
                    player_list_show(data)
                else
                    local data = {player = player, frame = frame, sort_by = 'name_desc'}
                    player_list_show(data)
                end
            end,
            ['player_list_panel_header_3'] = function()
                if string.find(element.caption, symbol_desc) then
                    local data = {player = player, frame = frame, sort_by = 'total_time_played_asc'}
                    player_list_show(data)
                else
                    local data = {player = player, frame = frame, sort_by = 'total_time_played_desc'}
                    player_list_show(data)
                end
            end,
            ['player_list_panel_header_4'] = function()
                if string.find(element.caption, symbol_desc) then
                    local data = {player = player, frame = frame, sort_by = 'time_played_asc'}
                    player_list_show(data)
                else
                    local data = {player = player, frame = frame, sort_by = 'time_played_desc'}
                    player_list_show(data)
                end
            end,
            ['player_list_panel_header_5'] = function()
                if string.find(element.caption, symbol_desc) then
                    local data = {player = player, frame = frame, sort_by = 'pokes_asc'}
                    player_list_show(data)
                else
                    local data = {player = player, frame = frame, sort_by = 'pokes_desc'}
                    player_list_show(data)
                end
            end
        }
    end

    if actions[name] then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'PlayerList Gui Click')
        if is_spamming then
            return
        end

        actions[name]()
        return
    end

    if not element.valid then
        return
    end
    --Locate other players
    local index = tonumber(element.name)
    if index and game.get_player(index) and index == game.get_player(index).index then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'PlayerList Locate Player')
        if is_spamming then
            return
        end
        local target = game.get_player(index)
        if not target or not target.valid then
            return
        end
        Where.create_mini_camera_gui(player, target)
    end
    --Poke other players
    if string.sub(element.name, 1, 11) == 'poke_player' then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'PlayerList Poke Player')
        if is_spamming then
            return
        end
        local poked_player = string.sub(element.name, 13, string.len(element.name))
        if player.name == poked_player then
            return
        end
        if this.player_list.last_poke_tick[element.player_index] + 300 < game.tick then
            local str = '>> '
            str = str .. player.name
            str = str .. ' has poked '
            str = str .. poked_player
            str = str .. ' with '
            local z = math.random(1, #pokemessages)
            str = str .. pokemessages[z]
            str = str .. ' <<'
            game.print(str)
            this.player_list.last_poke_tick[element.player_index] = game.tick
            local p = game.players[poked_player]
            this.player_list.pokes[p.index] = this.player_list.pokes[p.index] + 1
        end
    end
end

local function refresh()
    for _, player in pairs(game.connected_players) do
        local frame = Gui.get_player_active_frame(player)
        if frame then
            if frame.name ~= 'Players' then
                return
            end
            local data = {player = player, frame = frame, sort_by = this.player_list.sorting_method[player.index]}
            player_list_show(data)
        end
    end
end

local function on_player_joined_game(event)
    if not this.player_list.last_poke_tick[event.player_index] then
        this.player_list.pokes[event.player_index] = 0
        this.player_list.last_poke_tick[event.player_index] = 0
        this.player_list.sorting_method[event.player_index] = 'total_time_played_desc'
    end
    refresh()
end

local function on_player_left_game()
    refresh()
end

--- If the different roles should be shown in the player_list.
---@param value string
function Public.show_roles_in_list(value)
    this.show_roles_in_list = value or false
    return this.show_roles_in_list
end

--- Notifies player_list if RPG is enabled or not.
---@param value string
function Public.rpg_enabled(value)
    this.rpg_enabled = value or false
    return this.rpg_enabled
end

Gui.add_tab_to_gui({name = module_name, caption = 'Players', id = player_list_show_token, admin = false})

Gui.on_click(
    module_name,
    function(event)
        local player = event.player
        Gui.reload_active_tab(player)
    end
)

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_gui_click, on_gui_click)

return Public
