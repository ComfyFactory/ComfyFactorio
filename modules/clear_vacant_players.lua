local tick_frequency = 200

local default_required_online_time = 5 * 3600 -- nearest prime to 5 minutes in ticks
local default_clear_player_after_tick = 30 * 3600 -- nearest prime to 30 minutes in ticks

local Global = require 'utils.global'
local Alert = require 'utils.alert'
local Event = require 'utils.event'

local this = {
    settings = {
        is_enabled = false,
        offline_players_surface_removal = false,
        active_surface_index = nil, -- needs to be set else this will fail, remember to call "init()".
        required_online_time = default_required_online_time,
        clear_player_after_tick = default_clear_player_after_tick,
        surfaces_to_ignore = {},
    },
    offline_players = {}
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = { events = { remove_surface = Event.generate_event_name('remove_surface') } }
local remove = table.remove
local insert = table.insert

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
                                Event.raise(this.events.remove_surface, { target = target })
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
                                local data = {
                                    position = pos
                                }
                                Alert.alert_all_players_location(data, message, nil, 20)

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

--- Initializes the module with blank state, receiving all required parameters.
--- <br />The module starts **disabled** by default.
--- @param active_surface_index number The index of the active surface.
--- @param surfaces_to_ignore table|nil The ids or names of special surfaces to ignore. Players on those surfaces will not have their invontgory dumped if they leave.
---@param is_enabled boolean|nil Optional: when passed, sets the module to be enabled or disabled.
function Public.init(active_surface_index, surfaces_to_ignore, is_enabled)
    if not active_surface_index then
        return error('An active surface index must be set', 2)
    end
    this.settings.active_surface_index = active_surface_index
    this.settings.surfaces_to_ignore = surfaces_to_ignore or {}
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

--- Sets the required online time.
---@param value number The required online time. Resets if anything is sent other than a natural number.
function Public.set_required_online_time(value)
    if value >= 0 then
        this.settings.required_online_time = value
    else
        this.settings.required_online_time = default_required_online_time
    end
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
    Public.clear_offline_players();
end

--- Clears the offline table
function Public.clear_offline_players()
    this.offline_players = {}
end

local function should_ignore_surface(surface)
    if not this.settings.surfaces_to_ignore then
        return false
    end
    for _, item in ipairs(this.settings.surfaces_to_ignore) do
        if item == surface.index or item == surface.name then
            return true
        end
    end
    return false
end

Event.on_nth_tick(tick_frequency, Public.dump_expired_players)

Event.add(
    defines.events.on_pre_player_left_game,
    function(event)
        if not this.settings.is_enabled then
            return
        end

        local player = game.get_player(event.player_index)
        local ticker = game.tick
        if player and player.online_time >= this.settings.required_online_time then
            if not should_ignore_surface(player.surface) then
                if player.character then
                    insert(this.offline_players, {
                        index = event.player_index,
                        name = player.name,
                        tick = ticker + this.settings.clear_player_after_tick
                    })
                end
            end
        end
    end
)

return Public
