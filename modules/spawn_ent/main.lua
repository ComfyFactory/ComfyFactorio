local Market = require 'utils.functions.basic_markets'
local Loot = require 'modules.loot_items'
local Event = require 'utils.event'
local Surface = require 'utils.surface'
local Fort = require 'modules.spawn_ent.fort'
local BiterDefense = require 'modules.spawn_ent.biterDefense'
local Encampment = require 'modules.spawn_ent.encampment'
local MountainRange = require 'modules.spawn_ent.mountainRange'
local Turret = require 'modules.spawn_ent.turrets'
local m_random = math.random
local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'

local Public = {}

local this =
{
    modded = false,
    watery_world = false,
    markets_destructible = false
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

Public.debug = false
local add_chart_token

add_chart_token =
    Token.register(
        function (event)
            local surface = event.surface
            local entity = event.entity
            local text = event.text
            if not entity or not entity.valid then
                return
            end

            if not event.tries then
                event.tries = 0
            end

            local res = game.forces.player.add_chart_tag(
                surface,
                {
                    position = entity.position,
                    text = text,
                    icon = { type = 'entity', name = 'market' }
                }
            )
            if not res then
                if event.tries > 10 then
                    log('Failed to add chart tag for ' .. text)
                    return
                end
                event.tries = event.tries + 1
                Task.set_timeout_in_ticks(30, add_chart_token, event)
            end
        end,
        9999
    )


local function d_print(name, pos)
    if Public.debug then
        game.print('Spawned ' .. name .. ' at: x=' .. pos.x .. ', y=' .. pos.y)
    end
end

local function m_clearArea(center, surface)
    for y = center.y - 8, center.y + 8 do
        for x = center.x - 8, center.x + 8 do
            if not this.watery_world then
                if surface.get_tile(x, y).name == 'water' or surface.get_tile(x, y).name == 'deepwater' then
                    return false
                end
            else
                return true
            end
        end
    end

    for _, entity in pairs(surface.find_entities({ { center.x - 8, center.y - 8 }, { center.x + 8, center.y + 8 } })) do
        if entity.valid and entity.type ~= 'resource' then
            entity.destroy()
        end
    end

    return true
end

local function probability(v1, v2)
    return m_random(v1, v2) >= v2
end

---comment
---@param center MapPosition
---@param surface LuaSurface
---@param destructible boolean
local function spawn_market(center, surface, destructible)
    local force = game.forces.player
    if probability(1, 128) then
        center.x = center.x + m_random(-10, 10)
        center.y = center.y + m_random(-10, 10)
        local pos = { x = center.x, y = center.y }
        if m_clearArea(center, surface) then
            if probability(1, 64) then
                local area = { { pos.x - 64, pos.y - 64 }, { pos.x + 64, pos.y + 64 } }
                if surface.count_entities_filtered({ name = 'market', area = area }) == 0 then
                    local a = Market.super_market(surface, center, math.abs(center.y) * 0.004)
                    if a then
                        rendering.draw_text
                        {
                            text = 'Epic Market',
                            surface = surface,
                            target = { entity = a, offset = { 0, 2 } },
                            color = { r = 0.98, g = 0.66, b = 0.22 },
                            alignment = 'center'
                        }
                        a.destructible = destructible or false
                        force.chart(surface, area)
                        Task.set_timeout_in_ticks(5, add_chart_token,
                            { surface = surface, entity = a, text = 'Epic Market' })

                        d_print('market', pos)
                    end
                end
            elseif probability(1, 2) then
                local area = { { pos.x - 64, pos.y - 64 }, { pos.x + 64, pos.y + 64 } }
                if surface.count_entities_filtered({ name = 'market', area = area }) == 0 then
                    local a = Market.mountain_market(surface, center, math.abs(center.y) * 0.004)
                    if a then
                        rendering.draw_text
                        {
                            text = 'Rare Market',
                            surface = surface,
                            target = { entity = a, offset = { 0, 2 } },
                            color = { r = 0.98, g = 0.66, b = 0.22 },
                            alignment = 'center'
                        }
                        a.destructible = destructible or false
                        force.chart(surface, area)
                        d_print('market', pos)

                        Task.set_timeout_in_ticks(5, add_chart_token,
                            { surface = surface, entity = a, text = 'Rare Market' })
                    end
                end
            else
                local area = { { pos.x - 64, pos.y - 64 }, { pos.x + 64, pos.y + 64 } }
                if surface.count_entities_filtered({ name = 'market', area = area }) == 0 then
                    local a = Market.mountain_market(surface, center, math.abs(center.x) * 0.004)
                    if a then
                        rendering.draw_text
                        {
                            text = 'Common Market',
                            surface = surface,
                            target = { entity = a, offset = { 0, 2 } },
                            color = { r = 0.98, g = 0.66, b = 0.22 },
                            alignment = 'center'
                        }
                        a.destructible = destructible or false
                        force.chart(surface, area)
                        Task.set_timeout_in_ticks(5, add_chart_token,
                            { surface = surface, entity = a, text = 'Common Market' })
                        d_print('market', pos)
                    end
                end
            end
            return
        end
    end
end

local function spawn_turret(center, surface)
    local death_mode = Surface.get('death_mode')
    local prob = 40
    if death_mode then
        prob = 8
    end
    if probability(1, prob) then
        center.x = center.x + math.random(-15, 5)
        center.y = center.y + math.random(-15, 5)
        local pos = { x = center.x, y = center.y }
        if m_clearArea(center, surface) then
            Turret(center, surface)
            d_print('turret', pos)
        end
    end
end

local function spawn_loot(center, surface)
    if probability(1, 96) then
        center.x = center.x + math.random(-5, 5)
        center.y = center.y + math.random(-5, 5)
        local pos = { x = center.x, y = center.y }
        local name = 'crash-site-chest-1'
        if probability(1, 2) then
            name = 'crash-site-chest-2'
        end
        if m_clearArea(center, surface) then
            if probability(1, 18) then
                BiterDefense(center, surface)
            elseif probability(1, 12) then
                Encampment(center, surface)
            elseif probability(1, 8) then
                MountainRange(center, surface)
            elseif probability(1, 2) then
                Loot.add(surface, center, name)
                Fort(center, surface)
            else
                Loot.add(surface, center, name)
                d_print(name, pos)
            end
        end
    end
end

local tiles =
{
    ['water'] = true,
    ['deepwater'] = true,
    ['water-green'] = true,
    ['deepwater-green'] = true
}

---
---@param e EventData.on_chunk_generated
local function ticker(e)
    if e.surface.name ~= 'nauvis' then
        return
    end

    local center =
    {
        x = (e.area.left_top.x + e.area.right_bottom.x) / 2,
        y = (e.area.left_top.y + e.area.right_bottom.y) /
            2
    }
    if math.abs(center.x) < 200 and math.abs(center.y) < 200 then
        return
    end --too close to spawn
    local pos = { x = center.x, y = center.y }
    local t_name = e.surface.get_tile(pos.x, pos.y).name
    if tiles[t_name] and not this.watery_world then
        return
    end
    spawn_market(center, e.surface, this.markets_destructible)
    spawn_loot(center, e.surface)
    spawn_turret(center, e.surface)
end

Event.add(defines.events.on_chunk_generated, ticker)

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.markets_destructible(state)
    this.markets_destructible = state or false
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

return Public
