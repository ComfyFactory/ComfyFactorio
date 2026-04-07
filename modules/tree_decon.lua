local Global = require 'utils.global'
local SessionData = require 'utils.datastore.session_data'
local Event = require 'utils.event'
local Commands = require 'utils.commands'
local Color = require 'utils.color_presets'

local this =
{
    to_remove = {},
    mine = true,
    valid_types =
    {
        ['tree'] = true,
        ['simple-entity'] = true,
        ['plant'] = true
    },
    tile_replacement_enabled = false,
    tile_replacement = 'grass-1'
}

local ceil = math.ceil

Global.register(
    this,
    function (t)
        this = t
    end
)

local function check_health()
    if not this.to_remove then
        this.to_remove = {}
    end
    if not this.valid_types then
        this.valid_types =
        {
            ['tree'] = true,
            ['simple-entity'] = true,
            ['plant'] = true
        }
    end
end

Event.on_nth_tick(
    3,
    function ()
        local to_remove = this.to_remove
        if not to_remove then
            check_health()
            return
        end
        if #to_remove == 0 then
            return
        end
        for _ = 0, ceil(#to_remove / 10) do
            local data = table.remove(to_remove, 1)
            if data and data.entity and data.entity.valid then
                local entity = data.entity
                if this.mine then
                    local player = game.get_player(data.player_index)
                    if player and player.valid then
                        player.mine_entity(entity, true)
                    end
                else
                    if entity.type == 'deconstructible-tile-proxy' and this.tile_replacement_enabled then
                        if this.tile_replacement then
                            entity.surface.set_tiles({ { name = this.tile_replacement, position = entity.position } })
                        end
                    else
                        entity.destroy()
                    end
                end
            end
        end
    end
)

Event.add(
    defines.events.on_marked_for_deconstruction,
    function (event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        if not event.player_index then
            return
        end

        local player = game.get_player(event.player_index)
        if not player then
            return
        end

        if this.valid_types[entity.type] then
            if SessionData.allowed(player, 'tree-decon') then
                this.to_remove[#this.to_remove + 1] = { player_index = player.index, entity = entity }
            end
        end
    end
)


Commands.new('tree-decon', 'Enable or disable tree deconstruction')
    :callback(function (player, parameter)
        if not parameter then
            return player.print('Please type a parameter.', Color.warning)
        end
        if parameter == 'on' then
            this.mine = true
            player.print('Tree deconstruction enabled')
        elseif parameter == 'off' then
            this.mine = false
            player.print('Tree deconstruction disabled')
        end
    end
    )
