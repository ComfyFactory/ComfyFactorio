local Public = {}
local Session = require 'utils.datastore.session_data'
local Jailed = require 'utils.datastore.jail_data'
local Supporters = require 'utils.datastore.supporters'
local Gui = require 'utils.gui'

Public.ranks = {
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
    'item/dummy-steel-axe',
    'item/dummy-steel-axe',
    'item/dummy-steel-axe',
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
    'item/filter-inserter',
    'item/filter-inserter',
    'item/filter-inserter',
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
    'item/stack-inserter',
    'item/stack-inserter',
    'item/stack-inserter',
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
    'item/stack-filter-inserter',
    'item/stack-filter-inserter',
    'item/stack-filter-inserter',
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

Public.pokemessages = {
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

Public.gui_data = function (data)
    local header_label_name = data.header_label_name
    local show_roles_in_list = data.show_roles_in_list
    local locate_player_frame_name = data.locate_player_frame_name
    local rpg_enabled = data.rpg_enabled
    local poke_player_frame_name = data.poke_player_frame_name

    local play_table = Session.get_trusted_table()
    local jailed = Jailed.get_jailed_table()

    local connected_players = #game.connected_players
    local players = game.players

    local gui_data = {}
    gui_data[#gui_data + 1] = {
        width = 40,
        header_width = 35,
        name = '[color=0.1,0.7,0.1]' .. tostring(connected_players) .. '[/color]',
        func = function (player_list_panel_table, player, index)
            local sprite =
                player_list_panel_table.add {
                    type = 'sprite',
                    name = 'player_rank_sprite_' .. index,
                    sprite = player.rank
                }
            sprite.style.height = 32
            sprite.style.width = 32
            sprite.style.stretch_image_to_widget_size = true
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow' }
            local header_label =
                flow.add {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name
                }
            header_label.style.font = 'heading-2'
            header_label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }

            header_label.style.minimal_width = 36
            header_label.style.maximal_width = 36
            header_label.style.horizontal_align = 'right'
        end
    }
    gui_data[#gui_data + 1] = {
        width = 155,
        header_width = 150,
        header = 'username',
        name = 'Online / [color=0.7,0.1,0.1]' .. tostring(#players - connected_players) .. '[/color]' .. ' Offline',
        func = function (player_list_panel_table, player)
            local supporter, supportertbl = Supporters.is_supporter(player.name)
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

            if player.admin then
                trusted = '[color=red][A][/color]' .. trusted
                tooltip = 'This player is an admin of this server.' .. tooltip
            elseif jailed[player.name] then
                trusted = '[color=orange][J][/color]' .. trusted
                tooltip = 'This player is currently jailed.' .. minimap .. tooltip
            elseif play_table[player.name] then
                trusted = '[color=green][T][/color]' .. trusted
                tooltip = 'This player is trusted.' .. minimap .. tooltip
            else
                trusted = '[color=black][U][/color]' .. trusted
                tooltip = 'This player is not trusted.' .. minimap .. tooltip
            end

            tooltip = tooltip .. '\nRight-click to view their inventory!'

            local caption
            if show_roles_in_list or player.admin then
                caption = player.name .. ' ' .. trusted
            else
                caption = player.name
            end

            -- Name

            local name_flow =
                player_list_panel_table.add {
                    type = 'flow'
                }

            local name_label =
                name_flow.add {
                    type = 'label',
                    name = locate_player_frame_name,
                    caption = caption,
                    tooltip = tooltip
                }

            Gui.set_data(name_label, player.index)

            name_label.style.font = 'default'
            name_label.style.font_color = {
                r = .4 + player.color.r * 0.6,
                g = .4 + player.color.g * 0.6,
                b = .4 + player.color.b * 0.6
            }
            name_label.style.minimal_width = 165
            name_label.style.maximal_width = 165
            name_label.style.font = 'default-semibold'
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'username' }
            local header_label =
                flow.add {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = 'Sort by name.'
                }
            header_label.style.font = 'heading-2'
            header_label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
        end
    }
    if rpg_enabled then
        gui_data[#gui_data + 1] = {
            width = 90,
            header = 'rpg',
            header_width = 90,
            name = 'RPG level',
            func = function (player_list_panel_table, player)
                local rpg_level_label =
                    player_list_panel_table.add {
                        type = 'label',
                        caption = player.rpg_level
                    }
                rpg_level_label.style.minimal_width = 90
                rpg_level_label.style.maximal_width = 90
                rpg_level_label.style.font = 'default-semibold'
            end,
            sorter = function (self, player_tbl)
                local flow = player_tbl.add { type = 'flow', name = 'rpg' }
                local header_label =
                    flow.add {
                        type = 'label',
                        name = header_label_name,
                        caption = self.name,
                        tooltip = 'Sort by RPG level.'
                    }
                header_label.style.font = 'heading-2'
                header_label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
            end
        }
    end
    gui_data[#gui_data + 1] = {
        width = 90,
        header = 'coins',
        header_width = 90,
        name = 'Coins',
        func = function (player_list_panel_table, player)
            local coins_label =
                player_list_panel_table.add {
                    type = 'label',
                    caption = player.coins
                }
            coins_label.style.minimal_width = 90
            coins_label.style.maximal_width = 90
            coins_label.style.font = 'default-semibold'
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'coins' }
            local header_label =
                flow.add {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = 'Sort by amount coins (currently only counts the amount of coins that are stored in the player inventory).'
                }
            header_label.style.font = 'heading-2'
            header_label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
        end
    }
    gui_data[#gui_data + 1] = {
        width = 145,
        header = 'total_time',
        header_width = 150,
        name = 'Total Time',
        func = function (player_list_panel_table, player)
            -- Total time
            local total_label =
                player_list_panel_table.add {
                    type = 'label',
                    caption = player.total_played_time,
                    tooltip = 'Total time played across all Comfy servers.'
                }
            total_label.style.minimal_width = 145
            total_label.style.maximal_width = 145
            total_label.style.font = 'default-semibold'
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'total_time' }
            local header_label =
                flow.add {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = 'Sort by total time played.'
                }
            header_label.style.font = 'heading-2'
            header_label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
        end
    }
    gui_data[#gui_data + 1] = {
        width = 165,
        header_width = 175,
        header = 'current_time',
        name = 'Current Time',
        func = function (player_list_panel_table, player)
            -- Current time
            local current_label =
                player_list_panel_table.add {
                    type = 'label',
                    caption = player.played_time,
                    tooltip = 'Current time played on this server.'
                }
            current_label.style.minimal_width = 165
            current_label.style.maximal_width = 165
            current_label.style.font = 'default-semibold'
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'current_time' }
            local header_label =
                flow.add {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = 'Sort by current time played.'
                }
            header_label.style.font = 'heading-2'
            header_label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
        end
    }
    gui_data[#gui_data + 1] = {
        width = 50,
        header_width = 60,
        header = 'poke',
        name = 'Poke',
        func = function (player_list_panel_table, player, index)
            -- Poke
            local poke_flow = player_list_panel_table.add { type = 'flow', name = 'button_flow_' .. index, direction = 'horizontal' }
            poke_flow.style.right_padding = 20
            local poke_label = poke_flow.add { type = 'label', name = 'button_spacer_' .. index, caption = '' }
            local poke_button = poke_flow.add { type = 'button', name = poke_player_frame_name, caption = player.pokes }
            Gui.set_data(poke_button, player.index)
            poke_button.style.font = 'default'
            poke_button.tooltip = 'Poke ' .. player.name .. ' with a random message!\nDoes not work poking yourself :<'
            poke_label.style.font_color = { r = 0.83, g = 0.83, b = 0.83 }
            poke_button.style.minimal_height = 30
            poke_button.style.minimal_width = 30
            poke_button.style.maximal_height = 30
            poke_button.style.maximal_width = 30
            poke_button.style.top_padding = 0
            poke_button.style.left_padding = 0
            poke_button.style.right_padding = 0
            poke_button.style.bottom_padding = 0
        end,
        sorter = function (self, player_tbl)
            local flow = player_tbl.add { type = 'flow', name = 'poke' }
            local header_label =
                flow.add {
                    type = 'label',
                    name = header_label_name,
                    caption = self.name,
                    tooltip = 'Sort by amount of pokes.'
                }
            header_label.style.font = 'heading-2'
            header_label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
        end
    }

    return gui_data
end

local comparators = {
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
