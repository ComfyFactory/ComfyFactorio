local Public = {}
local Supporters = require 'utils.datastore.supporters'
local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'
local SessionData = require 'utils.datastore.session_data'

Public.ranks =
{
    'item/burner-mining-drill',
    'item/burner-mining-drill',
    'item/burner-mining-drill',
    'item/burner-inserter',
    'item/burner-inserter',
    'item/burner-inserter',
    'item/stone-furnace',
    'item/stone-furnace',
    'item/stone-furnace',
    'item/light-armor',
    'item/light-armor',
    'item/light-armor',
    'item/steam-engine',
    'item/steam-engine',
    'item/steam-engine',
    'item/inserter',
    'item/inserter',
    'item/inserter',
    'item/transport-belt',
    'item/transport-belt',
    'item/transport-belt',
    'item/underground-belt',
    'item/underground-belt',
    'item/underground-belt',
    'item/splitter',
    'item/splitter',
    'item/splitter',
    'item/assembling-machine-1',
    'item/assembling-machine-1',
    'item/assembling-machine-1',
    'item/long-handed-inserter',
    'item/long-handed-inserter',
    'item/long-handed-inserter',
    'item/electronic-circuit',
    'item/electronic-circuit',
    'item/electronic-circuit',
    'item/electric-mining-drill',
    'item/electric-mining-drill',
    'item/electric-mining-drill',
    'item/heavy-armor',
    'item/heavy-armor',
    'item/heavy-armor',
    'item/steel-furnace',
    'item/steel-furnace',
    'item/steel-furnace',
    'item/gun-turret',
    'item/gun-turret',
    'item/gun-turret',
    'item/fast-transport-belt',
    'item/fast-transport-belt',
    'item/fast-transport-belt',
    'item/fast-underground-belt',
    'item/fast-underground-belt',
    'item/fast-underground-belt',
    'item/fast-splitter',
    'item/fast-splitter',
    'item/fast-splitter',
    'item/assembling-machine-2',
    'item/assembling-machine-2',
    'item/assembling-machine-2',
    'item/fast-inserter',
    'item/fast-inserter',
    'item/fast-inserter',
    'item/radar',
    'item/radar',
    'item/radar',
    'item/defender-capsule',
    'item/defender-capsule',
    'item/defender-capsule',
    'item/pumpjack',
    'item/pumpjack',
    'item/pumpjack',
    'item/chemical-plant',
    'item/chemical-plant',
    'item/chemical-plant',
    'item/chemical-plant',
    'item/solar-panel',
    'item/solar-panel',
    'item/solar-panel',
    'item/advanced-circuit',
    'item/advanced-circuit',
    'item/advanced-circuit',
    'item/modular-armor',
    'item/modular-armor',
    'item/modular-armor',
    'item/accumulator',
    'item/accumulator',
    'item/accumulator',
    'item/construction-robot',
    'item/construction-robot',
    'item/construction-robot',
    'item/distractor-capsule',
    'item/distractor-capsule',
    'item/distractor-capsule',
    'item/bulk-inserter',
    'item/bulk-inserter',
    'item/bulk-inserter',
    'item/electric-furnace',
    'item/electric-furnace',
    'item/electric-furnace',
    'item/express-transport-belt',
    'item/express-transport-belt',
    'item/express-transport-belt',
    'item/express-transport-belt',
    'item/express-underground-belt',
    'item/express-underground-belt',
    'item/express-underground-belt',
    'item/express-splitter',
    'item/express-splitter',
    'item/express-splitter',
    'item/assembling-machine-3',
    'item/assembling-machine-3',
    'item/assembling-machine-3',
    'item/processing-unit',
    'item/processing-unit',
    'item/processing-unit',
    'item/power-armor',
    'item/power-armor',
    'item/power-armor',
    'item/logistic-robot',
    'item/logistic-robot',
    'item/logistic-robot',
    'item/laser-turret',
    'item/laser-turret',
    'item/laser-turret',
    'item/bulk-inserter',
    'item/bulk-inserter',
    'item/bulk-inserter',
    'item/destroyer-capsule',
    'item/destroyer-capsule',
    'item/destroyer-capsule',
    'item/power-armor-mk2',
    'item/power-armor-mk2',
    'item/power-armor-mk2',
    'item/flamethrower-turret',
    'item/flamethrower-turret',
    'item/flamethrower-turret',
    'item/beacon',
    'item/beacon',
    'item/beacon',
    'item/steam-turbine',
    'item/steam-turbine',
    'item/steam-turbine',
    'item/centrifuge',
    'item/centrifuge',
    'item/centrifuge',
    'item/nuclear-reactor',
    'item/nuclear-reactor',
    'item/nuclear-reactor',
    'item/cannon-shell',
    'item/cannon-shell',
    'item/cannon-shell',
    'item/rocket',
    'item/rocket',
    'item/rocket',
    'item/explosive-cannon-shell',
    'item/explosive-cannon-shell',
    'item/explosive-cannon-shell',
    'item/explosive-rocket',
    'item/explosive-rocket',
    'item/explosive-rocket',
    'item/uranium-cannon-shell',
    'item/uranium-cannon-shell',
    'item/uranium-cannon-shell',
    'item/explosive-uranium-cannon-shell',
    'item/explosive-uranium-cannon-shell',
    'item/explosive-uranium-cannon-shell',
    'item/atomic-bomb',
    'item/atomic-bomb',
    'item/atomic-bomb',
    'achievement/so-long-and-thanks-for-all-the-fish',
    'achievement/so-long-and-thanks-for-all-the-fish',
    'achievement/so-long-and-thanks-for-all-the-fish',
    'achievement/watch-your-step',
    'achievement/watch-your-step',
    'achievement/watch-your-step',
    'achievement/golem',
    'achievement/golem',
    'achievement/golem',
    'achievement/you-are-doing-it-right',
    'achievement/you-are-doing-it-right',
    'achievement/you-are-doing-it-right'
}

Public.pokemessages =
{
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

local function short_playtime(ticks)
    local minutes = math.floor(ticks / 3600)
    local hours = math.floor(minutes / 60)
    if hours >= 24 then
        return string.format('%dd %dh', math.floor(hours / 24), hours % 24)
    end
    if hours > 0 then
        return string.format('%dh %dm', hours, minutes % 60)
    end
    return string.format('%dm', minutes)
end

Public.gui_data = function (data)
    local header_label_name = data.header_label_name
    local show_roles_in_list = data.show_roles_in_list
    local locate_player_frame_name = data.locate_player_frame_name
    local rpg_enabled = data.rpg_enabled
    local poke_player_frame_name = data.poke_player_frame_name
    local columns = rpg_enabled and 7 or 6
    local fixed_width = 28 + 56 + 38 + (rpg_enabled and 72 or 0)
    local flexible_width = math.max(250, data.content_width - fixed_width - (columns - 1) * Style.spacing.xs)
    local preferred_widths = data.wide and { 210, 152, 152 } or { 140, 122, 122 }
    local widths = Style.column_widths(flexible_width, preferred_widths)
    local player_width, total_width, current_width = widths[1], widths[2], widths[3]

    local play_table = storage.tokens.utils_datastore_session_data.trusted
    local jailed = storage.tokens.utils_datastore_jail_data.jailed

    local connected_players = #game.connected_players
    local players = game.players

    local gui_data = {}
    gui_data[#gui_data + 1] =
    {
        width = 28,
        header_width = 28,
        name = '[color=0.1,0.7,0.1]' .. tostring(connected_players) .. '[/color]',
        func = function (player_list_panel_table, player, index)
            local flow = player_list_panel_table.add { type = 'flow' }
            flow.style.minimal_width = 28
            flow.style.maximal_width = 28
            flow.style.horizontal_align = 'center'
            local sprite =
                flow.add
                {
                    type = 'sprite',
                    name = 'player_rank_sprite_' .. index,
                    sprite = player.rank
                }
            sprite.style.height = 24
            sprite.style.width = 24
            sprite.style.stretch_image_to_widget_size = true
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow' }
            flow.style.width = self.header_width
            flow.style.horizontal_align = 'center'
            local header_label =
                flow.add
                {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name
                }
            Style.table_heading(header_label)

            header_label.style.width = self.header_width
            header_label.style.single_line = true
            header_label.style.horizontal_align = 'center'
        end
    }
    gui_data[#gui_data + 1] =
    {
        width = player_width,
        header_width = player_width,
        header = 'username',
        name = 'Online / [color=0.7,0.1,0.1]' .. tostring(#players - connected_players) .. '[/color]' .. ' Offline',
        func = function (player_list_panel_table, player)
            local supporter, supportertbl = Supporters.is_supporter(player.name)
            local verified = SessionData.get_verified_player(player.name)
            local trusted = ''
            local tooltip_lines = {}
            local show_minimap_tooltip = false

            if supporter then
                if supportertbl.monthly then
                    trusted = '[color=yellow][DM][/color]'
                    tooltip_lines[#tooltip_lines + 1] = 'This player is a monthly supporter.'
                else
                    trusted = '[color=yellow][D][/color]'
                    tooltip_lines[#tooltip_lines + 1] = 'This player has supported us.'
                end
            end

            local role_tooltip
            local Role = SessionData.get_role(player.name)
            if Role and Role.name then
                role_tooltip = 'Role: [color=' .. Role.role_color.r .. ',' .. Role.role_color.g .. ',' .. Role.role_color.b .. ']' .. Role.name .. '[/color]'
            end

            if player.admin then
                trusted = '[color=red][A][/color]' .. trusted
                tooltip_lines[#tooltip_lines + 1] = 'This player is an admin of this server.'
            elseif jailed[player.name] then
                trusted = '[color=orange][J][/color]' .. trusted
                tooltip_lines[#tooltip_lines + 1] = 'This player is currently jailed.'
                show_minimap_tooltip = true
            elseif verified then
                trusted = '[color=blue][V][/color]' .. trusted
                tooltip_lines[#tooltip_lines + 1] = 'This player is verified.'
                show_minimap_tooltip = true
            elseif play_table[player.name] then
                trusted = '[color=green][T][/color]' .. trusted
                tooltip_lines[#tooltip_lines + 1] = 'This player is trusted.'
                show_minimap_tooltip = true
            elseif not play_table[player.name] and not player.admin then
                trusted = '[color=black][U][/color]' .. trusted
                tooltip_lines[#tooltip_lines + 1] = 'This player is not trusted.'
                show_minimap_tooltip = true
            end

            if show_minimap_tooltip then
                tooltip_lines[#tooltip_lines + 1] = 'Left-click to show this person on map!'
            end
            if role_tooltip then
                tooltip_lines[#tooltip_lines + 1] = role_tooltip
            end
            tooltip_lines[#tooltip_lines + 1] = 'Right-click to view their inventory!'

            local tooltip = player.name .. '\n' .. table.concat(tooltip_lines, '\n')

            local caption
            if show_roles_in_list or player.admin then
                caption = player.name .. ' ' .. trusted
            else
                caption = player.name
            end

            -- Name

            local name_flow =
                player_list_panel_table.add
                {
                    type = 'flow'
                }
            name_flow.style.minimal_width = player_width
            name_flow.style.maximal_width = player_width
            name_flow.style.vertical_align = 'center'

            local name_label =
                name_flow.add
                {
                    type = 'label',
                    name = locate_player_frame_name,
                    caption = caption,
                    tooltip = tooltip
                }

            Gui.set_data(name_label, player.index)

            name_label.style.font = 'default'
            name_label.style.font_color =
            {
                r = .4 + player.color.r * 0.6,
                g = .4 + player.color.g * 0.6,
                b = .4 + player.color.b * 0.6
            }
            name_label.style.minimal_width = player_width
            name_label.style.maximal_width = player_width
            name_label.style.minimal_height = 24
            name_label.style.vertical_align = 'center'
            name_label.style.font = 'default-semibold'
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'username' }
            flow.style.width = self.header_width
            flow.style.horizontal_align = 'left'
            local header_label =
                flow.add
                {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = self.name .. '\nSort by name.'
                }
            Style.table_heading(header_label)
            header_label.style.width = self.header_width
            header_label.style.single_line = true
            header_label.style.horizontal_align = 'left'
        end
    }
    if rpg_enabled then
        gui_data[#gui_data + 1] =
        {
            width = 72,
            header = 'rpg',
            header_width = 72,
            name = 'RPG level',
            func = function (player_list_panel_table, player)
                local rpg_level_label =
                    player_list_panel_table.add
                    {
                        type = 'label',
                        caption = player.rpg_level
                    }
                rpg_level_label.style.minimal_width = 72
                rpg_level_label.style.maximal_width = 72
                rpg_level_label.style.minimal_height = 24
                rpg_level_label.style.horizontal_align = 'center'
                rpg_level_label.style.vertical_align = 'center'
                rpg_level_label.style.font = 'default-semibold'
            end,
            sorter = function (self, player_tbl)
                local flow = player_tbl.add { type = 'flow', name = 'rpg' }
                flow.style.width = self.header_width
                flow.style.horizontal_align = 'center'
                local header_label =
                    flow.add
                    {
                        type = 'label',
                        name = header_label_name,
                        caption = self.name,
                        tooltip = 'Sort by RPG level.'
                    }
                Style.table_heading(header_label)
                header_label.style.width = self.header_width
                header_label.style.single_line = true
                header_label.style.horizontal_align = 'center'
            end
        }
    end
    gui_data[#gui_data + 1] =
    {
        width = 56,
        header = 'coins',
        header_width = 56,
        name = 'Coins',
        func = function (player_list_panel_table, player)
            local coins_label =
                player_list_panel_table.add
                {
                    type = 'label',
                    caption = player.coins
                }
            coins_label.style.minimal_width = 56
            coins_label.style.maximal_width = 56
            coins_label.style.minimal_height = 24
            coins_label.style.horizontal_align = 'center'
            coins_label.style.vertical_align = 'center'
            coins_label.style.font = 'default-semibold'
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'coins' }
            flow.style.width = self.header_width
            flow.style.horizontal_align = 'center'
            local header_label =
                flow.add
                {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = 'Sort by amount coins (currently only counts the amount of coins that are stored in the player inventory).'
                }
            Style.table_heading(header_label)
            header_label.style.width = self.header_width
            header_label.style.single_line = true
            header_label.style.horizontal_align = 'center'
        end
    }
    gui_data[#gui_data + 1] =
    {
        width = total_width,
        header = 'total_time',
        header_width = total_width,
        name = 'Total Time',
        func = function (player_list_panel_table, player)
            -- Total time
            local total_label =
                player_list_panel_table.add
                {
                    type = 'label',
                    caption = data.wide and player.total_played_time or short_playtime(player.total_played_ticks),
                    tooltip = player.total_played_time .. '\nTotal time played across all Comfy servers.'
                }
            total_label.style.width = total_width
            total_label.style.minimal_height = 24
            total_label.style.horizontal_align = 'center'
            total_label.style.vertical_align = 'center'
            total_label.style.font = 'default-semibold'
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'total_time' }
            flow.style.width = self.header_width
            flow.style.horizontal_align = 'center'
            local header_label =
                flow.add
                {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = 'Sort by total time played.'
                }
            Style.table_heading(header_label)
            header_label.style.width = self.header_width
            header_label.style.single_line = true
            header_label.style.horizontal_align = 'center'
        end
    }
    gui_data[#gui_data + 1] =
    {
        width = current_width,
        header_width = current_width,
        header = 'current_time',
        name = 'Current Time',
        func = function (player_list_panel_table, player)
            -- Current time
            local current_label =
                player_list_panel_table.add
                {
                    type = 'label',
                    caption = data.wide and player.played_time or short_playtime(player.played_ticks),
                    tooltip = player.played_time .. '\nCurrent time played on this server.'
                }
            current_label.style.width = current_width
            current_label.style.minimal_height = 24
            current_label.style.horizontal_align = 'center'
            current_label.style.vertical_align = 'center'
            current_label.style.font = 'default-semibold'
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'current_time' }
            flow.style.width = self.header_width
            flow.style.horizontal_align = 'center'
            local header_label =
                flow.add
                {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = 'Sort by current time played.'
                }
            Style.table_heading(header_label)
            header_label.style.width = self.header_width
            header_label.style.single_line = true
            header_label.style.horizontal_align = 'center'
        end
    }
    gui_data[#gui_data + 1] =
    {
        width = 38,
        header_width = 38,
        header = 'poke',
        name = 'Poke',
        func = function (player_list_panel_table, player, index)
            -- Poke
            local poke_flow = player_list_panel_table.add { type = 'flow', name = 'button_flow_' .. index, direction = 'horizontal' }
            poke_flow.style.minimal_width = 38
            poke_flow.style.maximal_width = 38
            poke_flow.style.horizontal_align = 'center'
            poke_flow.style.vertical_align = 'center'
            local poke_button = poke_flow.add { type = 'button', name = poke_player_frame_name, caption = player.pokes }
            Gui.set_data(poke_button, player.index)
            poke_button.style.font = 'default'
            poke_button.tooltip = 'Poke ' .. player.name .. ' with a random message!\nDoes not work poking yourself :<'
            poke_button.style.minimal_height = 24
            poke_button.style.minimal_width = 24
            poke_button.style.maximal_height = 24
            poke_button.style.maximal_width = 24
            poke_button.style.top_padding = 0
            poke_button.style.left_padding = 0
            poke_button.style.right_padding = 0
            poke_button.style.bottom_padding = 0
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'poke' }
            flow.style.width = self.header_width
            flow.style.horizontal_align = 'center'
            local header_label =
                flow.add
                {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = 'Sort by amount of pokes.'
                }
            Style.table_heading(header_label)
            header_label.style.width = self.header_width
            header_label.style.single_line = true
            header_label.style.horizontal_align = 'center'
        end
    }

    return gui_data
end

local comparators =
{
    ['poke_asc'] = function (a, b)
        if not a.pokes then
            return
        end
        return a.pokes > b.pokes
    end,
    ['poke_desc'] = function (a, b)
        if not a.pokes then
            return
        end
        return a.pokes < b.pokes
    end,
    ['total_time_asc'] = function (a, b)
        if not a.total_played_ticks then
            return
        end
        return a.total_played_ticks < b.total_played_ticks
    end,
    ['total_time_desc'] = function (a, b)
        if not a.total_played_ticks then
            return
        end
        return a.total_played_ticks > b.total_played_ticks
    end,
    ['current_time_asc'] = function (a, b)
        if not a.played_ticks then
            return
        end
        return a.played_ticks < b.played_ticks
    end,
    ['current_time_desc'] = function (a, b)
        if not a.played_ticks then
            return
        end
        return a.played_ticks > b.played_ticks
    end,
    ['rpg_asc'] = function (a, b)
        if not a.rpg_level then
            return
        end
        return a.rpg_level < b.rpg_level
    end,
    ['rpg_desc'] = function (a, b)
        if not a.rpg_level then
            return
        end
        return a.rpg_level > b.rpg_level
    end,
    ['coins_asc'] = function (a, b)
        if not a.coins then
            return
        end
        return a.coins < b.coins
    end,
    ['coins_desc'] = function (a, b)
        if not a.coins then
            return
        end
        return a.coins > b.coins
    end,
    ['username_asc'] = function (a, b)
        if not a.name then
            return
        end
        return a.name:lower() < b.name:lower()
    end,
    ['username_desc'] = function (a, b)
        if not a.name then
            return
        end
        return a.name:lower() > b.name:lower()
    end
}

Public.get_comparator = function (sort_by)
    return comparators[sort_by]
end

return Public
