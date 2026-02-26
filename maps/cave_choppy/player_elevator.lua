--luacheck: ignore
local Event = require 'utils.event'
local Global = require 'utils.global'

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.name] then
        return false
    end
    return true
end

local cooldowns = {}
local chests = {}
local inventories = {}

Global.register(
    {
        chests = chests,
        inventories = inventories
    },
    function (tbl)
        chests = tbl.chests
        inventories = tbl.inventories
    end
)

Global.register(
    {
        cooldowns = cooldowns
    },
    function (tbl)
        cooldowns = tbl.cooldowns
    end
)

local function check_player_ports()
    for _, player in pairs(game.connected_players) do
        if not validate_player(player) then
            goto continue
        end

        if not cooldowns[player.name] then
            cooldowns[player.name] = game.tick
        end

        --if cooldowns[player.name] - game.tick > 0 then goto continue end

        if player.surface.get_tile(player.position.x, player.position.y).name == 'tutorial-grid' then
            if cooldowns[player.name] > game.tick then
                player.play_sound { path = 'utility/armor_insert', volume_modifier = 1 }
                if math.random(1, 3) == 1 then
                    player.create_local_flying_text(
                        {
                            position = player.position,
                            text = math.ceil((cooldowns[tostring(player.name)] - game.tick) / 60),
                            color = { r = math.random(130, 170), g = math.random(130, 170), b = 130 }
                        }
                    )
                end
                goto continue
            end
            local surface_name = player.surface.name == 'cave_miner' and 'choppy' or 'cave_miner'
            local pos = surface_name == 'cave_miner' and { 1, -4 } or { 1, -4 }
            local safe_pos = game.surfaces[surface_name].find_non_colliding_position('character', pos, 20, 1)
            if safe_pos then
                player.teleport(safe_pos, surface_name)
            else
                player.teleport({ 0, -3 }, surface_name)
            end
            cooldowns[player.name] = game.tick + 900
        end
        ::continue::
    end
end


local function tick()
    if not chests['cave_miner'] then
        chests['cave_miner'] = storage.surface_cave_chest
    end

    if not chests['choppy'] then
        chests['choppy'] = storage.surface_choppy_chest
    end

    local cave = chests['cave_miner']
    local tree = chests['choppy']

    if not cave or not tree then
        return
    end
    if not cave.valid or not tree.valid then
        return
    end

    local civ = tree.get_inventory(defines.inventory.chest)
    local oiv = cave.get_inventory(defines.inventory.chest)

    local ci = civ.get_contents()
    local oi = oiv.get_contents()
    for _, data in pairs(ci) do
        local count2 = oi[data.name] or 0
        local diff = data.count - count2
        if diff > 1 then
            count2 = oiv.insert { name = data.name, count = math.floor(diff / 2) }
            if count2 > 0 then
                civ.remove { name = data.name, count = count2 }
            end
        elseif diff < -1 then
            count2 = civ.insert { name = data.name, count = math.floor(-diff / 2) }
            if count2 > 0 then
                oiv.remove { name = data.name, count = count2 }
            end
        end
    end
    for _, data in pairs(oi) do
        if data.count > 1 and not ci[data.name] then
            local count2 = civ.insert { name = data.name, count = math.floor(data.count / 2) }
            if count2 > 0 then
                oiv.remove { name = data.name, count = count2 }
            end
        end
    end
end

Event.add(defines.events.on_tick, tick)
Event.on_nth_tick(60, check_player_ports)
