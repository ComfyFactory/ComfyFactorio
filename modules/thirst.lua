--Players will have to carry water barrels or stand next to a water tile, to keep themselves hydrated!

local Global = require 'utils.global'
local Event = require 'utils.event'
local Player_modifiers = require 'utils.player_modifiers'
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
    local hydration_meter = player.gui.top.hydration_meter

    if not hydration_meter then
        this.hydration[player.index] = 1000

        hydration_meter = player.gui.top.add({ type = 'frame', name = 'hydration_meter' })
        hydration_meter.style.padding = 3
        hydration_meter.tooltip = tooltip

        local label = hydration_meter.add({ type = 'label', caption = 'Hydration:' })
        label.style.font = 'heading-2'
        label.style.font_color = { 125, 125, 255 }
        label.tooltip = tooltip
        local label2 = hydration_meter.add({ type = 'label', caption = 100 })
        label2.style.font = 'heading-2'
        label2.style.font_color = { 175, 175, 175 }
        label2.tooltip = tooltip
        local label3 = hydration_meter.add({ type = 'label', caption = '%' })
        label3.style.font = 'heading-2'
        label3.style.font_color = { 175, 175, 175 }
        label3.tooltip = tooltip
        return
    end

    hydration_meter.children[2].caption = this.hydration[player.index] / 10
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
    local water_tiles = player.surface.count_tiles_filtered({
        name = { 'water', 'deepwater', 'water-mud', 'water-shallow' },
        area = { { player.position.x - 1, player.position.y - 1 }, { player.position.x + 1, player.position.y + 1 } }
    })
    if water_tiles > 0 then
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

    player.surface.spill_item_stack(player.position, { name = 'barrel', count = 1 }, true)
end

local function on_player_changed_position(event)
    if random(1, 320 ) ~= 1 then
        return
    end
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if not player.character.valid then
        return
    end
    if player.vehicle then
        return
    end
    this.hydration[player.index] = this.hydration[player.index] - (10 * local_modifier(player.physical_surface))
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
