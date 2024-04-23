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

--- Searches nearby electric accumulators at position and drains them up to required power.
---@param surface LuaSurface
---@param position MapPosition
---@param power_needs number The amount of power (capacity) you want to draw in Joules (native electricity unit)
local function discharge_accumulators(surface, position, force, power_needs)
    local accu_min_limit = 3000000 -- 3 MJ

    local accumulators = surface.find_entities_filtered {type = 'accumulator', force = force, position = position, radius = 13}
    local power_drained = 0
    power_needs = power_needs

    for _, accu in pairs(accumulators) do
        if power_needs <= 0 then
            break
        end

        if accu.valid and accu.energy > accu_min_limit then
            local accu_max_capacity = accu.electric_buffer_size
            local accu_energy_available = math.min(accu.energy, accu_max_capacity) - accu_min_limit

            local charge_delta = math.min(accu_energy_available, power_needs)

            accu.energy = accu.energy - charge_delta
            power_drained = power_drained + charge_delta
            power_needs = power_needs - charge_delta
        end
    end

    return power_drained
end

--- Charge player's equipped armor and modules by draining power from nearby accumulators.
---@param expensive_mult number? Optional multiplier to make charging cheaper/more costly. Default: 1.
local function charge(player, expensive_mult)
    if not player.character then
        return player.print(module_name .. 'It seems that you are not in the realm of living.', Color.warning)
    end
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    if not armor_inventory.valid then
        return player.print(module_name .. 'No valid armor inventory was found for charging.', Color.warning)
    end
    local armor = armor_inventory[1]
    if not armor.valid_for_read then
        return player.print(module_name .. 'No valid armor to charge was found.', Color.warning)
    end
    local grid = armor.grid
    if not grid or not grid.valid then
        return player.print(module_name .. 'No valid armor grid to charge was found.', Color.warning)
    end

    local discharged_modules = {}
    local total_energy_needed = 0

    local armor_modules = grid.equipment
    for _, piece in pairs(armor_modules) do
        if piece.valid and piece.generator_power == 0 then

            local energy_needs = piece.max_energy - piece.energy
            if energy_needs > 0 then
                table.insert(discharged_modules, piece)
                total_energy_needed = total_energy_needed + energy_needs
            end
        end
    end

    if total_energy_needed == 0 then
        return player.print(module_name .. 'Your armor is fully charged!', Color.success)
    end

    expensive_mult = expensive_mult or 1

    local energy_available = discharge_accumulators(
        player.surface, player.position, player.force,
        total_energy_needed * expensive_mult -- multiply our requirements
    )
    -- and pretend internally nothing happened
    energy_available = energy_available / expensive_mult

    if energy_available <= 0 then
        return player.print(module_name .. 'No accumulators nearby or they are all empty!', Color.warning)
    end

    for i = 1, #discharged_modules do
        if energy_available <= 0 then
            break
        end

        local piece = discharged_modules[i]

        local piece_energy = piece.energy
        local charge_delta = math.min(energy_available, piece.max_energy - piece_energy)

        piece.energy = piece_energy + charge_delta
        energy_available = energy_available - charge_delta
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
