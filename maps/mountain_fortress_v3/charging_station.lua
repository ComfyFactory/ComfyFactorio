--made by Hanakocz
-- modified by gerkiz
--charge your armor equipment from nearby accumulators!
local Event = require 'utils.event'
local SpamProtection = require 'utils.spam_protection'
local BottomFrame = require 'utils.gui.bottom_frame'
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'

local Public = {}
local charging_station_name = Gui.uid_name()

local function draw_charging_gui(player)
    local use_bottom = BottomFrame.is_custom_buttons_enabled() and not BottomFrame.get_player_data(player).top
    local use_mod_gui = Gui.get_mod_gui_top_frame()
    local top = player.gui.top
    local mod_flow = top.mod_gui_button_flow or (top.mod_gui_top_frame and top.mod_gui_top_frame.mod_gui_inner_frame)

    if use_bottom or use_mod_gui then
        Gui.destroy(top[charging_station_name])
    end
    if mod_flow and (use_bottom or not use_mod_gui) then
        Gui.destroy(mod_flow[charging_station_name])
    end
    if use_bottom then
        return
    end

    local spec =
    {
        type = 'sprite-button',
        name = charging_station_name,
        sprite = 'item/battery-mk2-equipment',
        tooltip = { 'modules.charging_station_tooltip' },
        style = Gui.button_style
    }
    local button = use_mod_gui and Gui.add_mod_button(player, spec) or (top[charging_station_name] or top.add(spec))
    button.style.height = use_mod_gui and 36 or 38
    button.style.minimal_width = 40
    button.style.padding = use_mod_gui and -2 or 1
end

local function discharge_accumulators(surface, position, force, power_needs)
    local accumulators = surface.find_entities_filtered { type = 'accumulator', force = force, position = position, radius = 13 }
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
    local warn = { 'mtn_v3_charging.no_armor' }
    if not player.character then
        return player.print({ 'mtn_v3_charging.character_required' }, { color = Color.warning })
    end
    if player.controller_type == defines.controllers.remote then
        return player.print({ 'mtn_v3_charging.character_required' }, { color = Color.warning })
    end
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    if not armor_inventory.valid then
        return player.print(warn, { color = Color.warning })
    end
    local armor = armor_inventory[1]
    if not armor.valid_for_read then
        return player.print(warn, { color = Color.warning })
    end
    local grid = armor.grid
    if not grid or not grid.valid then
        return player.print(warn, { color = Color.warning })
    end

    local ents = player.physical_surface.find_entities_filtered { type = 'accumulator', force = player.force, position = player.physical_position, radius = 13 }
    if not ents or not next(ents) then
        return player.print({ 'mtn_v3_charging.no_accumulators_nearby' }, { color = Color.warning })
    end

    local equip = grid.equipment
    for _, piece in pairs(equip) do
        if piece.valid and piece.generator_power == 0 then
            local energy_needs = piece.max_energy - piece.energy
            if energy_needs > 0 then
                local energy = discharge_accumulators(player.physical_surface, player.physical_position, player.force, energy_needs)
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

    player.play_sound({ path = 'utility/armor_insert', position = player.position, volume_modifier = 1 })
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    draw_charging_gui(player)
    if BottomFrame.is_custom_buttons_enabled() then
        BottomFrame.add_inner_frame(
            {
                player = player,
                element_name = charging_station_name,
                tooltip =
                {
                    'modules.charging_station_tooltip'
                },
                sprite = 'item/battery-mk2-equipment'
            }
        )
    end
end

Gui.on_click(
    charging_station_name,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local is_spamming = SpamProtection.is_spamming(player, nil, 'Charging Station Gui Click')
        if is_spamming then
            return
        end

        charge(player)
    end
)

Event.add(defines.events.on_player_joined_game, on_player_joined_game)

Event.add(
    ServerCommands.events.bottom_quickbar_location_changed,
    function (event)
        local player_index = event.player_index
        if not player_index then
            return
        end
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        draw_charging_gui(player)
    end
)

return Public
