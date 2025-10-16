local tick_frequency = 200

local Global = require 'utils.global'
local Alert = require 'utils.alert'
local Event = require 'utils.event'
local Task = require 'utils.task_token'
local Config = require 'utils.gui.config'

local this =
{
    settings =
    {
        is_enabled = false,
        offline_players_surface_removal = false,
        active_surface_index = nil, -- needs to be set else this will fail
        required_online_time = 18000, -- nearest prime to 5 minutes in ticks
        clear_player_after_tick = 108000 -- nearest prime to 30 minutes in ticks
    },
    offline_players = {}
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local Public = { events = { remove_surface = Event.generate_event_name('remove_surface') } }
local remove = table.remove
local insert = table.insert

Config.register_scenario_module(
    {
        id = "clear_vacant_players",
        admin_only = false,
        gui_rows = Config.register_token(
            function (_, frame)
                local switch_state = 'right'
                if this.settings.is_enabled then
                    switch_state = 'left'
                end
                Config.add_switch(frame, switch_state, 'vacant_toggle', 'Clear Vacant Players', 'Toggles offline players dropping their inventories on spawn.')

                frame.add({ type = 'line' })
            end),
        handlers =
        {
            ['vacant_toggle'] = Config.register_token(
                function (_, event)
                    local message
                    if event.element.switch_state == 'left' then
                        this.settings.is_enabled = true
                        message = 'has enabled Clear Vacant Players!'
                    else
                        this.settings.is_enabled = false
                        message = 'has disabled Clear Vacant Players!'
                    end
                    Config.get_actor(event, '[Clear Vacant Players]', message, true)
                end),
        }
    })

local zoom_to_pos_token =
    Task.register(
        function (event)
            local player_index = event.player_index
            local player = game.get_player(player_index)
            if not player or not player.valid then
                return
            end

            local data = event.data
            if not data then
                return
            end

            if player.controller_type == defines.controllers.remote or player.controller_type == defines.controllers.cutscene then
                return
            end

            local corpse
            local corpses = player.surface.find_entities_filtered({ position = data.position, type = 'character-corpse' })
            if corpses and corpses[1] then
                corpse = corpses[1]
            end

            local cutscene_1 =
            {
                position = data.position,
                target = corpse,
                zoom = 4,
                transition_time = 200,
                time_to_wait = 200,
            }

            local cutscene_2 =
            {
                position = player.physical_position,
                target = corpse,
                zoom = 1,
                transition_time = 200,
                time_to_wait = 10,
            }

            if not cutscene_1 or not cutscene_2 then
                return
            end

            if not cutscene_1.position or not cutscene_2.position then
                return
            end

            if not player.position or not player.surface then
                return
            end

            player.set_controller(
                {
                    type = defines.controllers.cutscene,
                    waypoints = { cutscene_1, cutscene_2 },
                    start_position = player.position,
                    surface = player.surface,
                    start_zoom = 1
                })
        end
    )

function Public.dump_expired_players()
    if not this.settings.is_enabled then
        return
    end
    local tick = game.tick
    -- Skip initial tick - not everything may be ready.
    if tick < 50 then
        return
    end

    if not this.settings.active_surface_index then
        return error('An active surface index must be set', 2)
    end
    local surface = game.get_surface(this.settings.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    if #this.offline_players > 0 then
        for i = 1, #this.offline_players, 1 do
            if this.offline_players[i] and this.offline_players[i].index then
                local target = game.get_player(this.offline_players[i].index)
                if target and target.valid then
                    if target.connected then
                        remove(this.offline_players, i)
                    else
                        if this.offline_players[i].tick < tick then
                            local player_inv = {}
                            local items = {}

                            local name = target.name
                            player_inv[1] = target.get_main_inventory()
                            player_inv[2] = target.get_inventory(defines.inventory.character_armor)
                            player_inv[3] = target.get_inventory(defines.inventory.character_guns)
                            player_inv[4] = target.get_inventory(defines.inventory.character_ammo)
                            player_inv[5] = target.get_inventory(defines.inventory.character_trash)
                            if this.offline_players_surface_removal then
                                Event.raise(this.events.remove_surface, { target = target })
                            end

                            local found_items = false
                            for index = 1, 5, 1 do
                                if player_inv[index] and player_inv[index].valid and player_inv[index].get_item_count() ~= 0 then
                                    found_items = true
                                end
                            end

                            if not found_items then -- if the player has zero items, don't do anything
                                remove(this.offline_players, i)
                                goto final
                            end

                            local pos = game.forces.player.get_spawn_position(surface)
                            local e =
                                surface.create_entity(
                                    {
                                        name = 'character',
                                        position = pos,
                                        force = 'neutral'
                                    }
                                )
                            if not e or not e.valid then
                                break
                            end

                            local inv = e.get_main_inventory()
                            if not inv then
                                break
                            end

                            ---@diagnostic disable-next-line: assign-type-mismatch
                            e.character_inventory_slots_bonus = #player_inv[1]
                            for ii = 1, 5, 1 do
                                if player_inv[ii] and player_inv[ii].valid then
                                    for iii = 1, #player_inv[ii], 1 do
                                        if player_inv[ii][iii] and player_inv[ii][iii].valid then
                                            insert(items, player_inv[ii][iii])
                                        end
                                    end
                                end
                            end
                            if #items > 0 then
                                for item = 1, #items, 1 do
                                    if items[item].valid then
                                        inv.insert(items[item])
                                    end
                                end

                                local message = ({ 'main.cleaner', name })
                                local data =
                                {
                                    position = pos
                                }
                                Alert.alert_all_players_location(data, message, nil, 40)

                                e.die('neutral')
                            else
                                e.destroy()
                            end

                            for ii = 1, 5, 1 do
                                if player_inv[ii] and player_inv[ii].valid then
                                    player_inv[ii].clear()
                                end
                            end

                            remove(this.offline_players, i)
                            break
                        end
                        ::final::
                    end
                end
            end
        end
    end
end

--- Initializes the module with blank state, receiving all required parameters.
--- <br />The module starts **disabled** by default.
--- @param active_surface_index number The index of the active surface.
---@param is_enabled boolean|nil Optional: when passed, sets the module to be enabled or disabled.
function Public.init(active_surface_index, is_enabled)
    if not active_surface_index then
        return error('An active surface index must be set', 2)
    end
    this.settings.active_surface_index = active_surface_index
    if is_enabled ~= nil then
        this.settings.is_enabled = is_enabled
    end
    Public.reset()
end

--- Returns whether the module is enabled or disabled.
function Public.is_enabled()
    return this.settings.is_enabled
end

--- Enables or disables the vacant-player module.
---@param value boolean
function Public.set_enabled(value)
    this.settings.is_enabled = value or false
end

--- Activates the surface removal for the module IC
---@param value boolean
function Public.set_offline_players_surface_removal(value)
    this.settings.offline_players_surface_removal = value or false
end

--- Sets the active surface for this module, needs to be set else it will fail
---@param value number|string Active surface index. Name of surface will also work.
function Public.set_active_surface_index(value)
    this.settings.active_surface_index = value or nil
end

function Public.reset()
    Public.clear_offline_players()
end

--- Clears the offline table
function Public.clear_offline_players()
    this.offline_players = {}
end

Event.on_nth_tick(tick_frequency, Public.dump_expired_players)

Event.add(
    defines.events.on_pre_player_left_game,
    function (event)
        if not this.settings.is_enabled then
            return
        end

        local player = game.get_player(event.player_index)
        local ticker = game.tick
        if player and player.online_time >= this.settings.required_online_time then
            if player.character then
                insert(
                    this.offline_players,
                    {
                        index = event.player_index,
                        name = player.name,
                        tick = ticker + this.settings.clear_player_after_tick
                    }
                )
            end
        end
    end
)

Event.on_init(
    function ()
        Alert.add_custom_zoom_to_pos(zoom_to_pos_token)
    end)

return Public
