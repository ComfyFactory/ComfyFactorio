--made by Hanakocz
--charge your armor equipment from nearby accumulators!
--change global.charging_station_multiplier if you want different conversion rate than 1:1.
local Event = require 'utils.event'
local SpamProtection = require 'utils.spam_protection'

local function draw_charging_gui()
    for _, player in pairs(game.connected_players) do
        if not player.gui.top.charging_station then
            local b = player.gui.top.add({type = 'sprite-button', name = 'charging_station', sprite = 'item/battery-mk2-equipment', tooltip = {'modules.charging_station_tooltip'}})
            b.style.minimal_height = 38
            b.style.maximal_height = 38
        end
    end
end

local function discharge_accumulators(surface, position, force, power_needs)
    local accumulators = surface.find_entities_filtered {name = 'accumulator', force = force, position = position, radius = 13}
    local power_drained = 0
    power_needs = power_needs * global.charging_station_multiplier
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
                    break
                end
            elseif power_needs <= 0 then
                break
            end
        end
    end
    return power_drained / global.charging_station_multiplier
end

local function charge(player)
    if not player.character then
        return
    end
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    if not armor_inventory.valid then
        return
    end
    local armor = armor_inventory[1]
    if not armor.valid_for_read then
        return
    end
    local grid = armor.grid
    if not grid or not grid.valid then
        return
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

local function on_player_joined_game()
    draw_charging_gui()
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

local function on_init()
    global.charging_station_multiplier = 1
end

Event.on_init(on_init)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
