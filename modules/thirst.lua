--Players will have to carry water barrels or stand next to a water tile, to keep themselves hydrated!

local Global = require 'utils.global'
local Event = require 'utils.event'
local Player_modifiers = require 'utils.player_modifiers'
local Gui = require 'utils.gui'
local random = math.random
local tooltip = 'How thirsty your character is.\nStand next to water,\nor keep water-barrels in your inventory to take a sip.'

local this = {
    hydration = {},
    planet_thirstiness = {
        custom = 1,
        nauvis = 1,
        gleba = 0.6,
        vulcanus = 3,
        aquilo = 0.8,
        fulgora = 1.5,
        platform = 0
    }
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local function update_player_modifiers(player)
    if this.hydration[player.index] <= 0 then
        this.hydration[player.index] = 500
        player.character.die()
        game.print(player.name .. ' forgot to take a sip.')
        return
    end

    local m = ((this.hydration[player.index] - 1000) * 0.001) + 0.2
    Player_modifiers.update_single_modifier(player, 'character_mining_speed_modifier', 'thirst', m)
    Player_modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'thirst', m)
    Player_modifiers.update_single_modifier(player, 'character_crafting_speed_modifier', 'thirst', m)
    Player_modifiers.update_player_modifiers(player)
end

local function update_hydration_meter(player)
    local parent = Gui.get_mod_gui_top_frame() and Gui.get_button_flow(player) or player.gui.top
    local legacy_meter = player.gui.top.hydration_meter
    if legacy_meter and (parent ~= player.gui.top or legacy_meter.type ~= 'button') then
        legacy_meter.destroy()
    end
    local hydration_meter = parent.hydration_meter
    if not hydration_meter then
        hydration_meter = parent.add({ type = 'button', name = 'hydration_meter', style = 'mod_gui_button', tooltip = tooltip })
        hydration_meter.style.minimal_height = 36
        hydration_meter.style.maximal_height = 36
        hydration_meter.style.minimal_width = 150
    end
    hydration_meter.caption = string.format('Hydration: %.0f%%', this.hydration[player.index] / 10)
end

local function local_modifier(surface)
    local planet_name = (surface.platform and 'platform') or (surface.planet and surface.planet.name) or 'custom'
    local modifier = this.planet_thirstiness[planet_name] or this.planet_thirstiness['custom']
    return modifier
end

local function sip(player)
    if not this.hydration[player.index] then
        return
    end
    if random(1, 4) == 1 then
        this.hydration[player.index] = this.hydration[player.index] - (10 * local_modifier(player.physical_surface))
    end
    if this.hydration[player.index] == 1000 then
        return
    end
    local surface = player.physical_surface
    local nearby_tiles = surface.find_tiles_filtered({
        area = { { player.physical_position.x - 1, player.physical_position.y - 1 }, { player.physical_position.x + 1, player.physical_position.y + 1 } }
    })
    local near_water = false
    for _, tile in pairs(nearby_tiles) do
        local fluid = tile.prototype.fluid
        if fluid and fluid.name == 'water' then
            near_water = true
            break
        end
    end
    if near_water then
        this.hydration[player.index] = this.hydration[player.index] + 200
        if this.hydration[player.index] > 1000 then
            this.hydration[player.index] = 1000
        end
        return
    end

    if this.hydration[player.index] > 900 then
        return
    end

    local inventory = player and player.character and player.character.get_main_inventory()
    if not inventory then
        return
    end
    local removed_count = inventory.remove({ name = 'water-barrel', count = 1 })
    if removed_count == 0 then
        return
    end

    this.hydration[player.index] = this.hydration[player.index] + 100
    player.play_sound { path = 'utility/armor_insert', volume_modifier = 0.9 }

    local inserted_count = inventory.insert({ name = 'barrel', count = 1 })
    if inserted_count > 0 then
        return
    end

    surface.spill_item_stack({ position = player.physical_position, stack = { name = 'barrel', count = 1 }, enable_looted = true })
end

local function on_player_changed_position(event)
    if random(1, 320) ~= 1 then
        return
    end
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if not player.character.valid then
        return
    end
    if player.controller_type == defines.controllers.remote or (script.active_mods['space-age'] and player.cargo_pod) then
        return
    end
    if player.vehicle then
        return
    end
    this.hydration[player.index] = (this.hydration[player.index] or 1000) - (10 * local_modifier(player.physical_surface))
end

local function on_player_died(event)
    if not this.hydration[event.player_index] then
        return
    end
    this.hydration[event.player_index] = 500
end

local function tick()
    for _, player in pairs(game.connected_players) do
        if player.character then
            if player.character.valid then
                this.hydration[player.index] = this.hydration[player.index] or 1000
                sip(player)
                update_hydration_meter(player)
                update_player_modifiers(player)
            end
        end
    end
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_died, on_player_died)
Event.on_nth_tick(120, tick)
