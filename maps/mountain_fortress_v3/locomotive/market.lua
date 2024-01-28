local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WD = require 'modules.wave_defense.table'
local Session = require 'utils.datastore.session_data'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local RPG = require 'modules.rpg.main'
local Gui = require 'utils.gui'
local Server = require 'utils.server'
local Alert = require 'utils.alert'
local Math2D = require 'math2d'
local SpamProtection = require 'utils.spam_protection'
local LinkedChests = require 'maps.mountain_fortress_v3.icw.linked_chests'

local format_number = require 'util'.format_number

local concat = table.concat

local main_frame_name = Gui.uid_name()
local close_market_gui_name = Gui.uid_name()
local random = math.random
local round = math.round

local ceil = math.ceil

local shopkeeper = '[color=blue]Shopkeeper:[/color]\n'

local space = {
    minimal_height = 10,
    top_padding = 0,
    bottom_padding = 0
}

local function add_style(frame, style)
    for k, v in pairs(style) do
        frame.style[k] = v
    end
end

local function add_space(frame)
    add_style(frame.add {type = 'line', direction = 'horizontal'}, space)
end

local function get_items()
    local market_limits = Public.get('market_limits')
    local main_market_items = Public.get('main_market_items')
    local flame_turret = Public.get('upgrades').flame_turret.bought
    local upgrades = Public.get('upgrades')
    local fixed_prices = Public.get('marked_fixed_prices')

    local health_cost = round(fixed_prices.health_cost * (1 + upgrades.health_upgrades))
    local pickaxe_cost = round(fixed_prices.pickaxe_cost * (0.1 + upgrades.pickaxe_tier / 2))
    local aura_cost = round(fixed_prices.aura_cost * (1 + upgrades.aura_upgrades))
    local xp_point_boost_cost = round(fixed_prices.xp_point_boost_cost * (1 + upgrades.xp_points_upgrade))
    local explosive_bullets_cost = round(fixed_prices.explosive_bullets_cost)
    local redraw_mystical_chest_cost = round(fixed_prices.redraw_mystical_chest_cost)
    local flamethrower_turrets_cost = round(fixed_prices.flamethrower_turrets_cost * (1 + flame_turret))
    local land_mine_cost = round(fixed_prices.land_mine_cost * (1 + upgrades.landmine.bought))
    local car_health_upgrade_pool = fixed_prices.car_health_upgrade_pool_cost
    local upgraded_tile_when_mining_cost = fixed_prices.tile_when_mining_cost

    local pickaxe_upgrades = Public.pickaxe_upgrades

    local offer = pickaxe_upgrades[upgrades.pickaxe_tier]

    if upgrades.pickaxe_tier >= market_limits.pickaxe_tier_limit then
        main_market_items['upgrade_pickaxe'] = {
            stack = 1,
            value = 'coin',
            price = pickaxe_cost,
            tooltip = ({'main_market.sold_out'}),
            sprite = 'achievement/delivery-service',
            enabled = false,
            upgrade = true,
            static = true
        }
    else
        main_market_items['upgrade_pickaxe'] = {
            stack = 1,
            value = 'coin',
            price = pickaxe_cost,
            tooltip = ({'main_market.purchase_pickaxe', offer, upgrades.pickaxe_tier, market_limits.pickaxe_tier_limit}),
            sprite = 'achievement/delivery-service',
            enabled = true,
            upgrade = true,
            static = true
        }
    end

    if upgrades.health_upgrades >= market_limits.health_upgrades_limit then
        main_market_items['locomotive_max_health'] = {
            stack = 1,
            value = 'coin',
            price = health_cost,
            tooltip = ({'locomotive.limit_reached'}),
            sprite = 'achievement/getting-on-track',
            enabled = false,
            upgrade = true,
            static = true
        }
    else
        main_market_items['locomotive_max_health'] = {
            stack = 1,
            value = 'coin',
            price = health_cost,
            tooltip = ({'main_market.locomotive_max_health', upgrades.health_upgrades, market_limits.health_upgrades_limit}),
            sprite = 'achievement/getting-on-track',
            enabled = true,
            upgrade = true,
            static = true
        }
    end

    if upgrades.locomotive_aura_radius == market_limits.aura_limit then
        main_market_items['locomotive_aura_radius'] = {
            stack = 1,
            value = 'coin',
            price = aura_cost,
            tooltip = ({'locomotive.limit_reached'}),
            sprite = 'achievement/tech-maniac',
            enabled = false,
            upgrade = true,
            static = true
        }
    else
        main_market_items['locomotive_aura_radius'] = {
            stack = 1,
            value = 'coin',
            price = aura_cost,
            tooltip = ({'main_market.locomotive_aura_radius', upgrades.aura_upgrades, upgrades.aura_upgrades_max}),
            sprite = 'achievement/tech-maniac',
            enabled = true,
            upgrade = true,
            static = true
        }
    end

    if upgrades.has_upgraded_health_pool then
        main_market_items['car_health_upgrade_pool'] = {
            stack = 1,
            value = 'coin',
            price = car_health_upgrade_pool,
            tooltip = ({'main_market.sold_out'}),
            sprite = 'achievement/iron-throne-1',
            enabled = false,
            upgrade = true,
            static = true
        }
    else
        main_market_items['car_health_upgrade_pool'] = {
            stack = 1,
            value = 'coin',
            price = car_health_upgrade_pool,
            tooltip = ({'main_market.global_car_health_modifier'}),
            sprite = 'achievement/iron-throne-1',
            enabled = true,
            upgrade = true,
            static = true
        }
    end

    if upgrades.has_upgraded_tile_when_mining then
        main_market_items['upgraded_tile_when_mining_cost'] = {
            stack = 1,
            value = 'coin',
            price = upgraded_tile_when_mining_cost,
            tooltip = ({'main_market.sold_out'}),
            sprite = 'achievement/run-forrest-run',
            enabled = false,
            upgrade = true,
            static = true
        }
    else
        main_market_items['upgraded_tile_when_mining_cost'] = {
            stack = 1,
            value = 'coin',
            price = upgraded_tile_when_mining_cost,
            tooltip = ({'main_market.tile_when_mining'}),
            sprite = 'achievement/run-forrest-run',
            enabled = true,
            upgrade = true,
            static = true
        }
    end

    if upgrades.xp_points_upgrade == market_limits.xp_points_limit then
        main_market_items['xp_points_boost'] = {
            stack = 1,
            value = 'coin',
            price = xp_point_boost_cost,
            tooltip = ({'locomotive.limit_reached'}),
            sprite = 'achievement/trans-factorio-express',
            enabled = false,
            upgrade = true,
            static = true
        }
    else
        main_market_items['xp_points_boost'] = {
            stack = 1,
            value = 'coin',
            price = xp_point_boost_cost,
            tooltip = ({'main_market.xp_points_boost', upgrades.xp_points_upgrade, market_limits.xp_points_limit}),
            sprite = 'achievement/trans-factorio-express',
            enabled = true,
            upgrade = true,
            static = true
        }
    end

    main_market_items['redraw_mystical_chest'] = {
        stack = 1,
        value = 'coin',
        price = redraw_mystical_chest_cost,
        tooltip = ({'main_market.mystical_chest'}),
        sprite = 'achievement/logistic-network-embargo',
        enabled = true,
        upgrade = true,
        static = true
    }

    if upgrades.explosive_bullets_purchased then
        main_market_items['explosive_bullets'] = {
            stack = 1,
            value = 'coin',
            price = explosive_bullets_cost,
            tooltip = ({'main_market.sold_out'}),
            sprite = 'achievement/steamrolled',
            enabled = false,
            upgrade = true,
            static = true
        }
    else
        main_market_items['explosive_bullets'] = {
            stack = 1,
            value = 'coin',
            price = explosive_bullets_cost,
            tooltip = ({'main_market.explosive_bullets'}),
            sprite = 'achievement/steamrolled',
            enabled = true,
            upgrade = true,
            static = true
        }
    end

    main_market_items['flamethrower_turrets'] = {
        stack = 1,
        value = 'coin',
        price = flamethrower_turrets_cost,
        tooltip = ({'main_market.flamethrower_turret', flame_turret}),
        sprite = 'achievement/pyromaniac',
        enabled = true,
        upgrade = true,
        static = true
    }
    main_market_items['land_mine'] = {
        stack = 1,
        value = 'coin',
        price = land_mine_cost,
        tooltip = ({'main_market.land_mine', upgrades.landmine.bought}),
        sprite = 'achievement/watch-your-step',
        enabled = true,
        upgrade = true,
        static = true
    }

    if game.forces.player.technologies['logistics'].researched then
        main_market_items['loader'] = {
            stack = 1,
            value = 'coin',
            price = 128,
            tooltip = ({'entity-name.loader'}),
            upgrade = false,
            static = true
        }
    end
    if game.forces.player.technologies['logistics-2'].researched then
        main_market_items['fast-loader'] = {
            stack = 1,
            value = 'coin',
            price = 256,
            tooltip = ({'entity-name.fast-loader'}),
            upgrade = false,
            static = true
        }
    end
    if game.forces.player.technologies['logistics-3'].researched then
        main_market_items['express-loader'] = {
            stack = 1,
            value = 'coin',
            price = 512,
            tooltip = ({'entity-name.express-loader'}),
            upgrade = false,
            static = true
        }
    end
    main_market_items['linked-chest'] = {
        stack = 1,
        value = 'coin',
        price = 500,
        tooltip = ({'entity-name.linked-chest'}),
        upgrade = false,
        static = true
    }

    main_market_items['small-lamp'] = {
        stack = 1,
        value = 'coin',
        price = 5,
        tooltip = ({'entity-name.small-lamp'}),
        upgrade = false,
        static = false
    }

    if game.forces.player.technologies['discharge-defense-equipment'].researched then
        main_market_items['discharge-defense-equipment'] = {
            stack = 1,
            value = 'coin',
            price = 9216,
            tooltip = ({'equipment-name.discharge-defense-equipment'}),
            upgrade = false,
            static = false
        }
        main_market_items['discharge-defense-remote'] = {
            stack = 1,
            value = 'coin',
            price = 1024,
            tooltip = ({'item-name.discharge-defense-remote'}),
            upgrade = false,
            static = false
        }
    end

    if game.forces.player.technologies['artillery'].researched then
        main_market_items['artillery-turret'] = {
            stack = 1,
            value = 'coin',
            price = 9216,
            tooltip = ({'item-name.artillery-turret'}),
            upgrade = false,
            static = false
        }
        main_market_items['artillery-shell'] = {
            stack = 1,
            value = 'coin',
            price = 1024,
            tooltip = ({'item-name.artillery-shell'}),
            upgrade = false,
            static = false
        }
    end

    main_market_items['wood'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.wood'}),
        upgrade = false,
        static = false
    }
    main_market_items['iron-ore'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.iron-ore'}),
        upgrade = false,
        static = false
    }
    main_market_items['copper-ore'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.copper-ore'}),
        upgrade = false,
        static = false
    }
    main_market_items['stone'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.stone'}),
        upgrade = false,
        static = false
    }
    main_market_items['coal'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.coal'}),
        upgrade = false,
        static = false
    }
    main_market_items['uranium-ore'] = {
        stack = 50,
        value = 'coin',
        price = 12,
        tooltip = ({'item-name.uranium-ore'}),
        upgrade = false,
        static = false
    }
    main_market_items['land-mine'] = {
        stack = 1,
        value = 'coin',
        price = 10,
        tooltip = ({'entity-name.land-mine'}),
        upgrade = false,
        static = false
    }
    main_market_items['raw-fish'] = {
        stack = 1,
        value = 'coin',
        price = 4,
        tooltip = ({'item-name.raw-fish'}),
        upgrade = false,
        static = false
    }
    main_market_items['firearm-magazine'] = {
        stack = 1,
        value = 'coin',
        price = 5,
        tooltip = ({'item-name.firearm-magazine'}),
        upgrade = false,
        static = false
    }
    main_market_items['crude-oil-barrel'] = {
        stack = 1,
        value = 'coin',
        price = 8,
        tooltip = ({'item-name.crude-oil-barrel'}),
        upgrade = false,
        static = false
    }
    main_market_items['car'] = {
        stack = 1,
        value = 'coin',
        price = 4500,
        tooltip = ({'main_market.car'}),
        upgrade = false,
        static = true
    }
    main_market_items['tank'] = {
        stack = 1,
        value = 'coin',
        price = 12000,
        tooltip = ({'main_market.tank'}),
        upgrade = false,
        static = true
    }
    local wave_number = WD.get_wave()

    if wave_number >= 650 then
        main_market_items['tank-cannon'] = {
            stack = 1,
            value = 'coin',
            price = 25000,
            tooltip = ({'item-name.tank-cannon'}),
            upgrade = false,
            static = true,
            enabled = true
        }
    else
        main_market_items['tank-cannon'] = {
            stack = 1,
            value = 'coin',
            price = 25000,
            tooltip = ({'main_market.tank_cannon_na', 650}),
            upgrade = false,
            static = true,
            enabled = false
        }
    end
    if wave_number >= 100 then
        main_market_items['vehicle-machine-gun'] = {
            stack = 1,
            value = 'coin',
            price = 500,
            tooltip = ({'item-name.vehicle-machine-gun'}),
            upgrade = false,
            static = true,
            enabled = true
        }
    else
        main_market_items['vehicle-machine-gun'] = {
            stack = 1,
            value = 'coin',
            price = 500,
            tooltip = ({'main_market.vehicle_machine_gun_na', 100}),
            upgrade = false,
            static = true,
            enabled = false
        }
    end

    return main_market_items
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.get_player(player.name) then
        return false
    end
    return true
end

local function close_market_gui(player)
    local players = Public.get('players')

    local element = player.gui.screen
    local data = players[player.index].data
    if not data then
        return
    end

    local frame = element[main_frame_name]
    Public.close_gui_player(frame)
    if data then
        players[player.index].data = nil
    end
end

local function redraw_market_items(gui, player, search_text)
    if not validate_player(player) then
        return
    end
    local players = Public.get('players')
    if not players then
        return
    end

    if gui and gui.valid then
        gui.clear()
    end

    local inventory = player.get_main_inventory()
    local player_item_count

    if not (gui and gui.valid) then
        return
    end

    local upgrades_label =
        gui.add(
        {
            type = 'label',
            caption = ({'locomotive.upgrades'})
        }
    )
    upgrades_label.style.font = 'heading-2'

    local upgrade_table = gui.add({type = 'table', column_count = 6})

    for item, data in pairs(get_items()) do
        if data.upgrade then
            if not search_text then
                goto continue
            end
            if not search_text.text then
                goto continue
            end
            if not string.lower(item:gsub('-', ' ')):find(search_text.text) then
                goto continue
            end
            local item_count = data.stack
            local item_cost = data.price

            local frame = upgrade_table.add({type = 'flow'})
            frame.style.vertical_align = 'bottom'

            player_item_count = inventory.get_item_count(data.value)

            local button =
                frame.add(
                {
                    type = 'sprite-button',
                    ---@diagnostic disable-next-line: ambiguity-1
                    sprite = data.sprite or 'item/' .. item,
                    number = item_count,
                    name = item,
                    tooltip = data.tooltip,
                    style = 'slot_button',
                    enabled = data.enabled
                }
            )
            local label =
                frame.add(
                {
                    type = 'label',
                    caption = concat {'[item=', data.value, ']: '} .. format_number(item_cost, true)
                }
            )
            label.style.font = 'default-bold'

            if player_item_count < item_cost then
                button.enabled = false
            end
            ::continue::
        end
    end
    local items_label =
        gui.add(
        {
            type = 'label',
            caption = ({'locomotive.items'})
        }
    )
    items_label.style.font = 'heading-2'

    local slider_value = ceil(players[player.index].data.slider.slider_value)
    local items_table = gui.add({type = 'table', column_count = 6})

    for item, data in pairs(get_items()) do
        if not data.upgrade then
            if not search_text then
                goto continue
            end
            if not search_text.text then
                goto continue
            end
            if not string.lower(item:gsub('-', ' ')):find(search_text.text) then
                goto continue
            end
            local item_count = data.stack * slider_value
            local item_cost = data.price * slider_value

            local frame = items_table.add({type = 'flow'})
            frame.style.vertical_align = 'bottom'

            player_item_count = inventory.get_item_count(data.value)

            local button =
                frame.add(
                {
                    type = 'sprite-button',
                    ---@diagnostic disable-next-line: ambiguity-1
                    sprite = data.sprite or 'item/' .. item,
                    number = item_count,
                    name = item,
                    tooltip = data.tooltip,
                    style = 'slot_button',
                    enabled = data.enabled
                }
            )
            if Public.get('trusted_only_car_tanks') then
                local trustedPlayer = Session.get_trusted_player(player)
                if not trustedPlayer then
                    if item == 'tank' then
                        button.enabled = false
                        button.tooltip = ({'locomotive.not_trusted'})
                    end
                    if item == 'car' then
                        button.enabled = false
                        button.tooltip = ({'locomotive.not_trusted'})
                    end
                end
            end

            local label =
                frame.add(
                {
                    type = 'label',
                    caption = concat {'[item=', data.value, ']: '} .. format_number(item_cost, true)
                }
            )
            label.style.font = 'default-bold'

            if player_item_count < item_cost then
                button.enabled = false
            end
            ::continue::
        end
    end
end

local function redraw_coins_left(gui, player)
    if not validate_player(player) then
        return
    end

    gui.clear()
    local inventory = player.get_main_inventory()
    local player_item_count = inventory.get_item_count('coin')

    local coinsleft =
        gui.add(
        {
            type = 'label',
            caption = ({'locomotive.coins_left', format_number(player_item_count, true)})
        }
    )

    add_space(coinsleft)
end

local function slider_changed(event)
    local player = game.players[event.player_index]
    local players = Public.get('players')
    if not players then
        return
    end
    local slider_value

    slider_value = players
    if not slider_value then
        return
    end
    slider_value = slider_value[player.index].data
    if not slider_value then
        return
    end

    local is_spamming = SpamProtection.is_spamming(player, 2, 'Locomotive Slider Change')
    if is_spamming then
        return
    end
    slider_value = slider_value.slider
    if not slider_value then
        return
    end
    slider_value = slider_value.slider_value
    if not slider_value then
        return
    end
    slider_value = ceil(slider_value)
    if players[player.index] and players[player.index].data and players[player.index].data.text_input then
        players[player.index].data.text_input.text = tostring(slider_value)
        redraw_market_items(players[player.index].data.item_frame, player, players[player.index].data.search_text)
    end
end

local function text_changed(event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end

    local players = Public.get('players')
    if not players then
        return
    end

    local player = game.players[event.player_index]

    local data = players[player.index].data
    if not data then
        return
    end

    local is_spamming = SpamProtection.is_spamming(player, 2, 'Locomotive Text Changed')
    if is_spamming then
        return
    end

    if not data.text_input or not data.text_input.valid then
        return
    end

    if not data.text_input.text then
        return
    end

    local value = tonumber(data.text_input.text)

    if not value then
        return
    end

    if (value > 1e2) then
        data.text_input.text = '100'
        value = 1e2
    elseif (value <= 0) then
        data.text_input.text = '1'
        value = 1
    end

    data.slider.slider_value = tostring(value)

    redraw_market_items(data.item_frame, player, data.search_text)
end

local function gui_opened(event)
    local market = Public.get('market')

    if not event.gui_type == defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if not entity then
        return
    end

    if entity ~= market then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end
    if player.controller_type == defines.controllers.spectator then
        return
    end

    if not validate_player(player) then
        return
    end

    local inventory = player.get_main_inventory()
    local player_item_count = inventory.get_item_count('coin')

    local players = Public.get('players')
    if not players then
        return
    end

    if not players[player.index].data then
        players[player.index].data = {}
    end

    local data = players[player.index].data

    if data.frame then
        data.frame = nil
    end

    local frame, inside_table = Gui.add_main_frame_with_toolbar(player, 'screen', main_frame_name, nil, close_market_gui_name, 'Market')
    if not inside_table then
        return
    end
    frame.auto_center = true

    player.opened = frame

    local search_table = inside_table.add({type = 'table', column_count = 2})
    local search_name = search_table.add({type = 'label', caption = ({'locomotive.search_text'})})
    search_name.style.font = 'heading-2'
    local search_text = search_table.add({type = 'textfield'})
    search_text.style.width = 140

    add_space(inside_table)

    local pane =
        inside_table.add {
        type = 'scroll-pane',
        direction = 'vertical',
        vertical_scroll_policy = 'always',
        horizontal_scroll_policy = 'never'
    }
    pane.style.maximal_height = 200
    pane.style.horizontally_stretchable = true
    pane.style.minimal_height = 200
    pane.style.right_padding = 0

    local flow = inside_table.add({type = 'flow'})

    add_space(flow)

    local bottom_grid = inside_table.add({type = 'table', column_count = 4})
    bottom_grid.style.vertically_stretchable = false

    local bg = bottom_grid.add({type = 'label', caption = ({'locomotive.quantity_text'})})
    bg.style.font = 'default-bold'

    local text_input =
        bottom_grid.add(
        {
            type = 'text-box',
            text = 1
        }
    )
    text_input.style.maximal_height = 28

    local slider =
        inside_table.add(
        {
            type = 'slider',
            minimum_value = 1,
            maximum_value = 1e2,
            value = 1
        }
    )
    slider.style.width = 115
    text_input.style.width = 60

    local coinsleft = inside_table.add({type = 'flow'})

    coinsleft.add(
        {
            type = 'label',
            caption = ({'locomotive.coins_left', format_number(player_item_count, true)})
        }
    )

    players[player.index].data.search_text = search_text
    players[player.index].data.text_input = text_input
    players[player.index].data.slider = slider
    players[player.index].data.frame = inside_table
    players[player.index].data.item_frame = pane
    players[player.index].data.coins_left = coinsleft

    redraw_market_items(pane, player, search_text)
end

local function gui_click(event)
    local players = Public.get('players')
    if not players then
        return
    end

    local element = event.element
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    if not players[player.index] then
        return
    end

    local data = players[player.index].data
    if not data then
        return
    end

    if not element.valid then
        return
    end
    local name = element.name

    if not player.opened then
        return
    end

    if not player.opened == main_frame_name then
        return
    end

    local is_spamming = SpamProtection.is_spamming(player, nil, 'Locomotive Gui Clicked')
    if is_spamming then
        return
    end

    if not data then
        return
    end
    local item = get_items()[name]
    if not item then
        return
    end

    local inventory = player.get_main_inventory()
    local player_item_count = inventory.get_item_count(item.value)
    local slider_value = ceil(data.slider.slider_value)
    local cost = (item.price * slider_value)
    local item_count = item.stack * slider_value

    local this = Public.get()

    if name == 'linked-chest' then
        local converted_chests = LinkedChests.get('converted_chests')
        LinkedChests.set('converted_chests', converted_chests + 1)
    end

    if name == 'upgrade_pickaxe' then
        player.remove_item({name = item.value, count = item.price})

        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        this.upgrades.pickaxe_tier = this.upgrades.pickaxe_tier + item.stack

        local pickaxe_upgrades = Public.pickaxe_upgrades
        local offer = pickaxe_upgrades[this.upgrades.pickaxe_tier]

        local message = ({
            'locomotive.pickaxe_bought_info',
            shopkeeper,
            player.name,
            offer,
            format_number(item.price, true)
        })
        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has upgraded the teams pickaxe to tier ' .. this.upgrades.pickaxe_tier .. ' for ' .. format_number(item.price, true) .. ' coins.'
            }
        )

        local force = game.forces.player

        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + this.pickaxe_speed_per_purchase
        this.upgrades.train_upgrade_contribution = this.upgrades.train_upgrade_contribution + item.price

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end
    if name == 'locomotive_max_health' then
        player.remove_item({name = item.value, count = item.price})
        local message = ({'locomotive.health_bought_info', shopkeeper, player.name, format_number(item.price, true)})

        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has upgraded the train health for ' .. format_number(item.price, true) .. ' coins.'
            }
        )

        local health_per_upgrade = 20000
        this.locomotive_health = this.locomotive_health + health_per_upgrade
        this.locomotive_max_health = this.locomotive_max_health + health_per_upgrade

        if this.locomotive_health >= this.locomotive_max_health then
            this.locomotive_health = this.locomotive_max_health
        end
        --[[
        this.locomotive_max_health = this.locomotive_max_health + (this.locomotive_max_health * 0.5)
        This exists as a reminder to never ever screw up health pool ever again.
       ]]
        local m = this.locomotive_health / this.locomotive_max_health

        if this.carriages then
            for i = 1, #this.carriages do
                local entity = this.carriages[i]
                if not (entity and entity.valid) then
                    return
                end
                local cargo_health = 600
                if entity.type == 'locomotive' then
                    entity.health = 1000 * m
                else
                    entity.health = cargo_health * m
                end
            end
        end

        this.upgrades.train_upgrade_contribution = this.upgrades.train_upgrade_contribution + item.price
        this.upgrades.health_upgrades = this.upgrades.health_upgrades + item.stack
        rendering.set_text(this.health_text, 'HP: ' .. round(this.locomotive_health) .. ' / ' .. round(this.locomotive_max_health))

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end
    if name == 'locomotive_aura_radius' then
        if this.upgrades.locomotive_aura_radius == this.market_limits.aura_limit then
            redraw_market_items(data.item_frame, player, data.search_text)
            player.print(({'locomotive.limit_reached'}), {r = 0.98, g = 0.66, b = 0.22})
            return
        end
        player.remove_item({name = item.value, count = item.price})

        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        local message = ({'locomotive.aura_bought_info', shopkeeper, player.name, format_number(item.price, true)})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has upgraded the train aura radius for ' .. format_number(item.price, true) .. ' coins.'
            }
        )
        this.upgrades.locomotive_aura_radius = this.upgrades.locomotive_aura_radius + 5
        this.upgrades.aura_upgrades = this.upgrades.aura_upgrades + item.stack
        this.upgrades.train_upgrade_contribution = this.upgrades.train_upgrade_contribution + item.price

        if this.circle then
            rendering.destroy(this.circle)
        end
        local difficulty_index = Difficulty.get('index')

        local fill_circle = false
        if difficulty_index == 2 or difficulty_index == 3 then
            fill_circle = true
        end

        this.circle =
            rendering.draw_circle {
            surface = game.surfaces[this.active_surface_index],
            target = this.locomotive,
            color = this.locomotive.color,
            filled = false,
            radius = this.upgrades.locomotive_aura_radius,
            only_in_alt_mode = fill_circle
        }

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end

    if name == 'xp_points_boost' then
        player.remove_item({name = item.value, count = item.price})
        local message = ({'locomotive.xp_bought_info', shopkeeper, player.name, format_number(item.price, true)})

        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has upgraded the train aura XP modifier for ' .. format_number(item.price) .. ' coins.'
            }
        )
        this.upgrades.xp_points = this.upgrades.xp_points + 0.5
        this.upgrades.xp_points_upgrade = this.upgrades.xp_points_upgrade + item.stack
        this.upgrades.train_upgrade_contribution = this.upgrades.train_upgrade_contribution + item.price

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end

    if name == 'redraw_mystical_chest' then
        player.remove_item({name = item.value, count = item.price})
        local message = ({'locomotive.mystical_bought_info', shopkeeper, player.name, format_number(item.price, true)})

        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has rerolled the mystical chest for ' .. format_number(item.price) .. ' coins.'
            }
        )

        Public.init_price_check(this.locomotive, this.mystical_chest)

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end

    if name == 'explosive_bullets' then
        player.remove_item({name = item.value, count = item.price})
        local message = ({
            'locomotive.explosive_bullet_bought_info',
            shopkeeper,
            player.name,
            format_number(item.price, true)
        })

        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has bought the explosive bullet modifier for ' .. format_number(item.price) .. ' coins.'
            }
        )
        RPG.enable_explosive_bullets(true)
        this.upgrades.explosive_bullets_purchased = true

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end

    if name == 'car_health_upgrade_pool' then
        player.remove_item({name = item.value, count = item.price})
        local message = ({
            'locomotive.car_health_upgrade_pool_bought_info',
            shopkeeper,
            player.name,
            format_number(item.price, true)
        })

        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' has bought the global car health modifier for ' .. format_number(item.price) .. ' coins.'
            }
        )
        this.upgrades.has_upgraded_health_pool = true

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end

    if name == 'upgraded_tile_when_mining_cost' then
        player.remove_item({name = item.value, count = item.price})
        local message = ({
            'locomotive.tile_upgrade_bought_info',
            shopkeeper,
            player.name,
            format_number(item.price, true)
        })

        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        Alert.alert_all_players(5, message)
        Server.to_discord_bold(
            table.concat {
                player.name .. ' the global tile replacement from stone-path to concrete-tile for ' .. format_number(item.price) .. ' coins.'
            }
        )
        this.upgrades.has_upgraded_tile_when_mining = true

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end

    if name == 'flamethrower_turrets' then
        player.remove_item({name = item.value, count = item.price})
        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        if item.stack >= 1 then
            local message = ({
                'locomotive.one_flamethrower_bought_info',
                shopkeeper,
                player.name,
                format_number(item.price, true)
            })
            Alert.alert_all_players(5, message)
            Server.to_discord_bold(
                table.concat {
                    player.name .. ' has bought a flamethrower-turret slot for ' .. format_number(item.price, true) .. ' coins.'
                }
            )
        else
            local message = ({
                'locomotive.multiple_flamethrower_bought_info',
                shopkeeper,
                player.name,
                item.stack,
                format_number(item.price, true)
            })
            Alert.alert_all_players(5, message)
            Server.to_discord_bold(
                table.concat {
                    player.name .. ' has bought ' .. item.stack .. ' flamethrower-turret slots for ' .. format_number(item.price, true) .. ' coins.'
                }
            )
        end
        this.upgrades.flame_turret.limit = this.upgrades.flame_turret.limit + item.stack
        this.upgrades.flame_turret.bought = this.upgrades.flame_turret.bought + item.stack

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)

        return
    end
    if name == 'land_mine' then
        player.remove_item({name = item.value, count = item.price})

        Event.raise(Public.events.on_market_item_purchased, {cost = item.price})

        if item.stack >= 1 and this.upgrades.landmine.bought % 10 == 0 then
            local message = ({
                'locomotive.landmine_bought_info',
                shopkeeper,
                player.name,
                format_number(item.price, true)
            })

            Alert.alert_all_players(3, message)

            if item.price >= 1000 then
                Server.to_discord_bold(
                    table.concat {
                        player.name .. ' has bought ' .. item.stack .. ' landmine slots for ' .. format_number(item.price, true) .. ' coins.'
                    }
                )
            end
        end

        this.upgrades.landmine.limit = this.upgrades.landmine.limit + item.stack
        this.upgrades.landmine.bought = this.upgrades.landmine.bought + item.stack

        redraw_market_items(data.item_frame, player, data.search_text)
        redraw_coins_left(data.coins_left, player)
        return
    end

    if player_item_count >= cost then
        if player.can_insert({name = name, count = item_count}) then
            player.play_sound({path = 'entity-close/stone-furnace', volume_modifier = 0.65})
            local inserted_count = player.insert({name = name, count = item_count})
            if inserted_count < item_count then
                player.play_sound({path = 'utility/cannot_build', volume_modifier = 0.65})
                player.print(({'locomotive.full_inventory', inserted_count, name}), {r = 0.98, g = 0.66, b = 0.22})
                player.print(({'locomotive.change_returned'}), {r = 0.98, g = 0.66, b = 0.22})
                player.insert({name = name, count = inserted_count})
                player.remove_item({name = item.value, count = ceil(item.price * (inserted_count / item.stack))})
                Event.raise(Public.events.on_market_item_purchased, {cost = ceil(item.price * (inserted_count / item.stack))})
            else
                player.remove_item({name = item.value, count = cost})
                Event.raise(Public.events.on_market_item_purchased, {cost = cost})
            end
            redraw_market_items(data.item_frame, player, data.search_text)
            redraw_coins_left(data.coins_left, player)
        else
            player.play_sound({path = 'utility/cannot_build', volume_modifier = 0.65})
            if (random(1, 10) > 1) then
                player.print(({'locomotive.notify_full_inventory_1'}), {r = 0.98, g = 0.66, b = 0.22})
                player.print(({'locomotive.notify_full_inventory_2'}), {r = 0.98, g = 0.66, b = 0.22})
            else
                player.print(({'locomotive.notify_full_inventory_2'}), {r = 0.98, g = 0.66, b = 0.22})
            end
        end
    end
end

local function gui_closed(event)
    local player = game.players[event.player_index]
    local players = Public.get('players')
    if not players then
        return
    end

    local type = event.gui_type

    if type == defines.gui_type.custom then
        local data = players[player.index].data
        if not data then
            return
        end
        close_market_gui(player)
    end
end

local function on_player_changed_position(event)
    local players = Public.get('players')
    if not players then
        return
    end
    local player = game.players[event.player_index]
    if not players[player.index] then
        return
    end
    local data = players[player.index].data

    local market = Public.get('market')

    if not (market and market.valid) then
        return
    end

    if data and data.frame and data.frame.valid then
        local position = market.position
        local area = {
            left_top = {x = position.x - 10, y = position.y - 10},
            right_bottom = {x = position.x + 10, y = position.y + 10}
        }
        if Math2D.bounding_box.contains_point(area, player.position) then
            return
        end
        if not data then
            return
        end
        close_market_gui(player)
    end
end

local function create_market(data, rebuild)
    local surface = data.surface
    local this = Public.get()

    if not this.locomotive then
        return
    end

    if not this.locomotive.valid then
        return
    end

    if rebuild then
        local radius = 512
        local area = {{x = -radius, y = -radius}, {x = radius, y = radius}}
        for _, entity in pairs(surface.find_entities_filtered {area = area, name = 'market'}) do
            entity.destroy()
        end
        for _, entity in pairs(surface.find_entities_filtered {area = area, type = 'item-entity', name = 'item-on-ground'}) do
            entity.destroy()
        end
        for _, entity in pairs(surface.find_entities_filtered {area = area, type = 'unit'}) do
            entity.destroy()
        end
        this.market = nil
    end

    local locomotive = this.icw_locomotive

    local loco_surface = this.icw_locomotive.surface

    if not loco_surface.valid then
        return
    end

    local center_position = {
        x = locomotive.area.left_top.x + (locomotive.area.right_bottom.x - locomotive.area.left_top.x) * 0.5,
        y = locomotive.area.left_top.y + (locomotive.area.right_bottom.y - locomotive.area.left_top.y) * 0.5
    }

    if not this.icw_area then
        this.icw_area = center_position
    end

    this.market = surface.create_entity {name = 'market', position = center_position, force = 'player'}

    for y = -1, 0, 0.05 do
        local scale = random(50, 100) * 0.01
        rendering.draw_sprite(
            {
                sprite = 'item/coin',
                orientation = random(0, 100) * 0.01,
                x_scale = scale,
                y_scale = scale,
                tint = {random(60, 255), random(60, 255), random(60, 255)},
                render_layer = 'selection-box',
                target = this.market,
                target_offset = {-0.7 + random(0, 140) * 0.01, y},
                surface = surface
            }
        )
    end

    if this.mystical_chest_enabled then
        if this.mystical_chest and this.mystical_chest.entity then
            this.mystical_chest.entity.destroy()
            this.mystical_chest.entity = nil
        end

        this.mystical_chest = {
            entity = surface.create_entity {name = 'logistic-chest-requester', position = {x = center_position.x, y = center_position.y + 2}, force = 'neutral'}
        }
        this.mystical_chest.entity.minable = false
        this.mystical_chest.entity.destructible = false
        if not this.mystical_chest.price then
            Public.add_mystical_chest()
        end
        rendering.draw_text {
            text = 'Mystical chest',
            surface = surface,
            target = this.mystical_chest.entity,
            scale = 1.2,
            target_offset = {0, 0},
            color = {r = 0.98, g = 0.66, b = 0.22},
            alignment = 'center'
        }
    end

    Public.wintery(this.market, 5.5)

    rendering.draw_text {
        text = 'Market',
        surface = surface,
        target = this.market,
        scale = 1.5,
        target_offset = {0, -2},
        color = {r = 0.98, g = 0.66, b = 0.22},
        alignment = 'center'
    }

    this.market.destructible = false

    Public.spawn_biter()

    for x = center_position.x - 5, center_position.x + 5, 1 do
        for y = center_position.y - 5, center_position.y + 5, 1 do
            if random(1, 2) == 1 then
                loco_surface.spill_item_stack({x + random(0, 9) * 0.1, y + random(0, 9) * 0.1}, {name = 'raw-fish', count = 1}, false)
            end
            loco_surface.set_tiles({{name = 'blue-refined-concrete', position = {x, y}}}, true)
        end
    end
    for x = center_position.x - 3, center_position.x + 3, 1 do
        for y = center_position.y - 3, center_position.y + 3, 1 do
            if random(1, 2) == 1 then
                loco_surface.spill_item_stack({x + random(0, 9) * 0.1, y + random(0, 9) * 0.1}, {name = 'raw-fish', count = 1}, false)
            end
            loco_surface.set_tiles({{name = 'cyan-refined-concrete', position = {x, y}}}, true)
        end
    end
end

local function place_market()
    local locomotive = Public.get('locomotive')
    if not locomotive then
        return
    end

    if not locomotive.valid then
        return
    end

    local icw_table = ICW.get_table()
    local unit_surface = locomotive.unit_number
    local surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]
    local market = Public.get('market')

    local data = {
        surface = surface
    }
    if not market then
        create_market(data)
    elseif not market.valid then
        create_market(data, true)
    end
end

function Public.close_gui_player(frame)
    if not frame then
        return
    end

    if frame then
        frame.destroy()
    end
end

function Public.refresh_gui()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]

        local gui = player.gui
        local screen = gui.screen

        local player_data = Public.get('players')
        if not players then
            return
        end
        local data = player_data[player.index].data

        if screen and data and data.frame then
            redraw_market_items(data.item_frame, player, data.search_text)
        end
    end
end

local function tick()
    local ticker = game.tick

    if ticker % 30 == 0 then
        place_market()
    end
end

Gui.on_click(
    close_market_gui_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end
        close_market_gui(player)
    end
)

Event.on_nth_tick(5, tick)
Event.add(defines.events.on_gui_click, gui_click)
Event.add(defines.events.on_gui_value_changed, slider_changed)
Event.add(defines.events.on_gui_text_changed, text_changed)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_gui_opened, gui_opened)
Event.add(defines.events.on_gui_closed, gui_closed)

return Public
