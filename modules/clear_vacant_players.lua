local Global = require 'utils.global'
local Alert = require 'utils.alert'
local Event = require 'utils.event'

local this = {
    settings = {
        offline_players_enabled = false,
        offline_players_surface_removal = false,
        active_surface_index = nil, -- needs to be set else this will fail
        required_online_time = 18000, -- nearest prime to 5 minutes in ticks
        clear_player_after_tick = 108000 -- nearest prime to 30 minutes in ticks
    },
    offline_players = {}
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {events = {remove_surface = Event.generate_event_name('remove_surface')}}
local remove = table.remove

function Public.remove_offline_players()
    if not this.settings.offline_players_enabled then
        return
    end
    local tick = game.tick
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
    local player_inv = {}
    local items = {}
    if #this.offline_players > 0 then
        for i = 1, #this.offline_players, 1 do
            if this.offline_players[i] and this.offline_players[i].index then
                local target = game.get_player(this.offline_players[i].index)
                if target and target.valid then
                    if target.connected then
                        remove(this.offline_players, i)
                    else
                        if this.offline_players[i].tick < tick then
                            local name = this.offline_players[i].name
                            player_inv[1] = target.get_inventory(defines.inventory.character_main)
                            player_inv[2] = target.get_inventory(defines.inventory.character_armor)
                            player_inv[3] = target.get_inventory(defines.inventory.character_guns)
                            player_inv[4] = target.get_inventory(defines.inventory.character_ammo)
                            player_inv[5] = target.get_inventory(defines.inventory.character_trash)
                            if this.offline_players_surface_removal then
                                Event.raise(this.events.remove_surface, {target = target})
                            end

                            if target.get_item_count() == 0 then -- if the player has zero items, don't do anything
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

                            local inv = e.get_inventory(defines.inventory.character_main)
                            if not inv then
                                break
                            end

                            ---@diagnostic disable-next-line: assign-type-mismatch
                            e.character_inventory_slots_bonus = #player_inv[1]
                            for ii = 1, 5, 1 do
                                if player_inv[ii].valid then
                                    for iii = 1, #player_inv[ii], 1 do
                                        if player_inv[ii][iii].valid then
                                            items[#items + 1] = player_inv[ii][iii]
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

                                local message = ({'main.cleaner', name})
                                local data = {
                                    position = pos
                                }
                                Alert.alert_all_players_location(data, message)

                                e.die('neutral')
                            else
                                e.destroy()
                            end

                            for ii = 1, 5, 1 do
                                if player_inv[ii].valid then
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

--- Activates the offline player module
---@param value boolean
function Public.set_offline_players_enabled(value)
    this.settings.offline_players_enabled = value or false
end

--- Activates the surface removal for the module IC
---@param value boolean
function Public.set_offline_players_surface_removal(value)
    this.settings.offline_players_surface_removal = value or false
end

--- Sets the active surface for this module, needs to be set else it will fail
---@param value string
function Public.set_active_surface_index(value)
    this.settings.active_surface_index = value or nil
end

--- Clears the offline table
function Public.clear_offline_players()
    this.offline_players = {}
end

local remove_offline_players = Public.remove_offline_players

Event.on_nth_tick(200, remove_offline_players)

Event.add(
    defines.events.on_pre_player_left_game,
    function(event)
        if not this.settings.offline_players_enabled then
            return
        end

        local player = game.get_player(event.player_index)
        local ticker = game.tick
        if player and player.online_time >= this.settings.required_online_time then
            if player.character then
                this.offline_players[#this.offline_players + 1] = {
                    index = event.player_index,
                    name = player.name,
                    tick = ticker + this.settings.clear_player_after_tick
                }
            end
        end
    end
)

return Public
