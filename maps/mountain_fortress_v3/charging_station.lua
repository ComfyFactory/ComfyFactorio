--made by Hanakocz
-- modified by gerkiz
--charge your armor equipment from nearby accumulators!
local Event = require 'utils.event'
local SpamProtection = require 'utils.spam_protection'
local BottomFrame = require 'utils.gui.bottom_frame'
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'

local Public = {}
local module_name = '[color=blue][Charging station][/color] '

local function draw_charging_gui(player, activate_custom_buttons)
    local button =
        player.gui.top['charging_station'] or
        player.gui.top.add(
            {
                type = 'sprite-button',
                name = 'charging_station',
                sprite = 'item/battery-mk2-equipment',
                tooltip = {
                    'modules.charging_station_tooltip'
                },
                style = Gui.button_style
            }
        )
    button.style.minimal_height = 38
    button.style.maximal_height = 38

    if activate_custom_buttons then
        if button and button.valid then
            button.destroy()
        end
    end
end

local function discharge_accumulators(surface, position, force, power_needs)
    local accumulators = surface.find_entities_filtered {name = 'accumulator', force = force, position = position, radius = 13}
    local power_drained = 0
    power_needs = power_needs * 1
    for _, accu in pairs(accumulators) do
        if accu.valid then
            if accu.energy > 3000000 and power_needs > 0 then
                if power_needs >= 2000000 then
                    power_drained = power_drained + 2000000
                    accu.energy = accu.energy - 2000000
                    power_needs = power_needs - 2000000
                else
                    power_drained = power_drained + power_needs
                    accu.energy = accu.energy - power_needs
                end
            elseif power_needs <= 0 then
                break
            end
        end
    end
    return power_drained / 1
end

local function charge(player)
    if not player.character then
        return player.print(module_name .. 'It seems that you are not in the realm of living.', Color.warning)
    end
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    if not armor_inventory.valid then
        return player.print(module_name .. 'No valid armor to charge was found.', Color.warning)
    end
    local armor = armor_inventory[1]
    if not armor.valid_for_read then
        return player.print(module_name .. 'No valid armor to charge was found.', Color.warning)
    end
    local grid = armor.grid
    if not grid or not grid.valid then
        return player.print(module_name .. 'No valid armor to charge was found.', Color.warning)
    end
    local equip = grid.equipment
    for _, piece in pairs(equip) do
        if piece.valid and piece.generator_power == 0 then
            local energy_needs = piece.max_energy - piece.energy
            if energy_needs > 0 then
                local energy = discharge_accumulators(player.surface, player.position, player.force, energy_needs)
                if energy > 0 then
                    if piece.energy + energy >= piece.max_energy then
                        piece.energy = piece.max_energy
                    else
                        piece.energy = piece.energy + energy
                    end
                end
            end
        end
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local activate_custom_buttons = BottomFrame.get('activate_custom_buttons')

    draw_charging_gui(player, activate_custom_buttons)
    if activate_custom_buttons then
        BottomFrame.add_inner_frame(
            {
                player = player,
                element_name = 'charging_station',
                tooltip = {
                    'modules.charging_station_tooltip'
                },
                sprite = 'item/battery-mk2-equipment'
            }
        )
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
    if event.element.name == 'charging_station' then
        local player = game.players[event.player_index]
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Charging Station Gui Click')
        if is_spamming then
            return
        end
        charge(player)
        return
    end
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)

Event.add(
    BottomFrame.events.bottom_quickbar_location_changed,
    function(event)
        local player_index = event.player_index
        if not player_index then
            return
        end
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        local bottom_frame_data = event.data
        if bottom_frame_data and bottom_frame_data.top then
            draw_charging_gui(player, false)
        else
            draw_charging_gui(player, true)
        end
    end
)

return Public
