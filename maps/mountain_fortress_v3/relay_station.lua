local Event = require 'utils.event'
local Global = require 'utils.global'
local WPT = require 'maps.mountain_fortress_v3.table'
local Orent = require 'maps.mountain_fortress_v3.orientation'
local Public = {}

local name = 'mtn-addon-abandoned-relay-station'
local variants =
{
    { name = name, tier = 'small', power = 1 },
    { name = name .. '-medium', tier = 'medium', power = 5 },
    { name = name .. '-large', tier = 'large', power = 10 }
}

local settings = { first = 1024, spacing = 1024, interval = 300, attempts = 12, ahead = 192 }
local this = { readiness_version = 1, closed_through = -2, schema = 2, run = 1, sites = {}, registrations = {}, ready = {}, retired = {}, active = {} }

Global.register(this,
    function (saved)
        this = saved
    end
)

local function available()
    for _, variant in ipairs(variants) do
        if prototypes and prototypes.entity[variant.name] then return true end
    end
    return false
end

local function select_variant(depth)
    local progress = math.min(1, math.max(0, (depth - settings.first) / (settings.spacing * 8)))
    local weights = { 80 - 65 * progress, 18 + 22 * progress, 2 + 43 * progress }
    local total = 0
    for i, variant in ipairs(variants) do
        if prototypes.entity[variant.name] and weights[i] > 0 then total = total + weights[i] end
    end
    local roll = math.random() * total
    local selected
    for i, variant in ipairs(variants) do
        if prototypes.entity[variant.name] and weights[i] > 0 then
            selected = variant
            roll = roll - weights[i]
            if roll < 0 then return variant end
        end
    end
    return selected
end

local function retire(site, reason)
    if site.phase ~= 'placed' and site.phase ~= 'searching' then
        return
    end
    site.phase = reason
    if site.registration then
        this.registrations[site.registration] = nil
    end
end

local function completion(surface, x, y)
    for index in pairs(this.ready) do
        if index ~= surface.index then this.ready[index] = nil end
    end
    local chunks = this.ready[surface.index]
    if not chunks then
        chunks = {}; this.ready[surface.index] = chunks
    end
    local loco = WPT.get('locomotive')
    local lateral = Orent.lateral { x = x * 32, y = y * 32 } / 32
    local depth = Orent.progression { x = x * 32, y = y * 32 } / 32
    if loco and loco.valid and loco.surface.index == surface.index then
        local center = math.floor(Orent.lateral(loco.position) / 32)
        local radius = 0
        for _, variant in ipairs(variants) do
            local box = prototypes and prototypes.entity[variant.name] and prototypes.entity[variant.name].collision_box
            if box then
                radius = math.max(radius, math.abs(box.left_top.x), math.abs(box.left_top.y), math.abs(box.right_bottom.x), math.abs(box.right_bottom.y))
            end
        end
        local margin = math.min(31, math.ceil((128 + radius) / 32) + 1)
        for column in pairs(chunks) do
            if math.abs(column - center) > margin then chunks[column] = nil end
        end
        if math.abs(lateral - center) > margin then
            return
        end
    end
    local ranges = chunks[lateral]
    if not ranges then
        local count = 0
        for _ in pairs(chunks) do count = count + 1 end
        if count >= 64 then return end
        ranges = {}; chunks[lateral] = ranges
    end
    local first, last = depth, depth
    local index = 1
    while index <= #ranges do
        local range = ranges[index]
        if last + 1 < range[1] then break end
        if first <= range[2] + 1 then
            first, last = math.min(first, range[1]), math.max(last, range[2])
            table.remove(ranges, index)
        else
            index = index + 1
        end
    end
    if #ranges >= 64 then
        local center = loco and loco.valid and Orent.progression(loco.position) / 32 or 0
        local distance = math.max(first - center, center - last, 0)
        local farthest, maximum
        for i, range in ipairs(ranges) do
            local gap = math.max(range[1] - center, center - range[2], 0)
            if not maximum or gap > maximum then farthest, maximum = i, gap end
        end
        if distance >= maximum then return end
        table.remove(ranges, farthest)
        if farthest < index then index = index - 1 end
    end
    table.insert(ranges, index, { first, last })
end

local function compact_ready()
    if this.readiness_version == 1 then return end
    local old = this.ready
    this.ready = {}
    local active = WPT.get('active_surface_index')
    for surface_index, chunks in pairs(old) do
        if surface_index == active and not this.retired[surface_index] then
            local ordered = {}
            for key, value in pairs(chunks) do
                local x, y = key:match('^(-?%d+):(-?%d+)$')
                if value and x then ordered[#ordered + 1] = { x = tonumber(x), y = tonumber(y) } end
            end
            table.sort(ordered, function (a, b)
                local ac, bc = Orent.lateral(a), Orent.lateral(b)
                if ac ~= bc then return ac < bc end
                return Orent.progression(a) < Orent.progression(b)
            end)
            for _, chunk in ipairs(ordered) do completion({ index = surface_index }, chunk.x, chunk.y) end
        end
    end
    for _, site in pairs(this.sites) do
        if site.band then this.closed_through = math.max(this.closed_through or -2, site.band - 1) end
    end
    this.readiness_version = 1
end

function Public.reset()
    for _, site in pairs(this.sites) do retire(site, 'retired') end
    this.run = this.run + 1
    this.sites, this.registrations, this.ready, this.retired, this.active = {}, {}, {}, {}, {}
    this.schema = 2
    this.readiness_version, this.closed_through = 1, -2
end

function Public.begin_round_surface(surface)
    if not (surface and surface.valid) or surface.index ~= WPT.get('active_surface_index') then
        return
    end
    this.active = this.active or {}
    if this.active[surface.index] == this.run then
        return
    end
    this.active[surface.index] = this.run
    this.retired[surface.index] = nil
    this.ready = {}
    return this.run
end

function Public.surface_generation(surface)
    if not (surface and surface.valid) or this.retired[surface.index] then
        return
    end
    return this.active and this.active[surface.index]
end

function Public.chunk_ready(surface, top, generation)
    if not generation or generation ~= Public.surface_generation(surface) then
        return
    end
    if not (surface and surface.valid) or this.retired[surface.index] then
        return
    end
    if surface.index ~= WPT.get('active_surface_index') then
        return
    end
    compact_ready()
    completion(surface, math.floor(top.x / 32), math.floor(top.y / 32))
end

local function safe(surface, pos, force, selected)
    local prototype = prototypes.entity[selected]
    if not prototype then return false, 'not_placeable' end
    local chunks = this.ready[surface.index]
    if not chunks then return false, 'missing_ready' end
    local box = prototype.collision_box
    local left, right = box.left_top, box.right_bottom
    local x1, y1 = math.floor(pos.x + left.x), math.floor(pos.y + left.y)
    local x2, y2 = math.ceil(pos.x + right.x), math.ceil(pos.y + right.y)
    for x = math.floor(x1 / 32), math.floor(x2 / 32) do
        for y = math.floor(y1 / 32), math.floor(y2 / 32) do
            local lateral = Orent.lateral { x = x, y = y }
            local depth = Orent.progression { x = x, y = y }
            local complete = false
            for _, range in ipairs(chunks[lateral] or {}) do
                if depth >= range[1] and depth <= range[2] then
                    complete = true; break
                end
            end
            if not complete then return false, 'missing_ready' end
            if not surface.is_chunk_generated { x = x, y = y } then
                return false, 'ungenerated_chunk'
            end
        end
    end
    if not surface.can_place_entity { name = selected, position = pos, force = force } then
        return false, 'not_placeable'
    end
    return true
end

local function place(site, loco, debug)
    site.attempts = site.attempts + 1
    local surface = loco.surface
    site.rejections = { missing_ready = 0, ungenerated_chunk = 0, not_placeable = 0, create_failed = 0 }
    site.candidates = 0
    for step = 0, 21 do
        local depth = debug and (-Orent.sign() * Orent.progression(loco.position) + 24 + step * 8)
            or (settings.first + site.band * settings.spacing + step * 16)
        for offset = 0, 21 do
            local lateral = (48 + math.floor(offset / 2) * 8) * (offset % 2 == 0 and 1 or -1)
            local pos = Orent.world(Orent.lateral(loco.position) + lateral, -Orent.sign() * depth)
            site.candidates = site.candidates + 1
            local ok, reason = safe(surface, pos, loco.force, site.name)
            if ok then
                local entity = surface.create_entity { name = site.name, position = pos, force = loco.force }
                if entity and entity.valid then
                    entity.destructible = true
                    entity.minable_flag = false
                    site.last_result = 'placed'
                    site.phase, site.entity, site.unit_number = 'placed', entity, entity.unit_number
                    site.position, site.force_index = pos, loco.force.index
                    site.registration = script.register_on_object_destroyed(entity)
                    this.registrations[site.registration] = site.id
                    if _DEBUG then
                        loco.force.print('[Relay] Abandoned ' .. site.tier .. ' relay station (' .. site.power .. ' MW) discovered at [gps=' .. pos.x .. ',' .. pos.y .. ',' .. surface.name .. ']. Protect it: destruction is permanent.')
                    end
                    return
                end
                reason = 'create_failed'
            end
            site.last_result = reason
            site.rejections[reason] = site.rejections[reason] + 1
        end
    end
    if site.attempts >= settings.attempts then retire(site, 'failed') end
end

local function migrate()
    if this.schema == 2 then return end
    local task, loco = WPT.get('current_task'), WPT.get('locomotive')
    if WPT.get('game_lost') or not (task and task.done and loco and loco.valid) then return end
    local surface = loco.surface
    if not surface.valid or surface.index ~= WPT.get('active_surface_index') then return end
    local recover = WPT.recover_relay_chunks
    if not recover then return end
    this.active = this.active or {}
    if this.retired[surface.index] then
        for _, site in pairs(this.sites) do
            if site.surface_index == surface.index then
                this.schema = 2
                return
            end
        end
        if this.run < 2 then
            this.schema = 2; return
        end
        if not recover(surface, this.run, true) then return end
        Public.begin_round_surface(surface)
        recover(surface, this.run, false)
    else
        this.active[surface.index] = this.run
    end
    this.schema = 2
end

local function tick()
    compact_ready()
    migrate()
    for id, site in pairs(this.sites) do
        if site.phase == 'placed' and not (site.entity and site.entity.valid and site.entity.unit_number == site.unit_number) then
            retire(site, 'destroyed')
        end
        if site.band and site.band <= (this.closed_through or -2) and site.phase ~= 'placed' then
            if site.registration then this.registrations[site.registration] = nil end
            this.sites[id] = nil
        end
    end
    if not available() then return end
    local task, loco = WPT.get('current_task'), WPT.get('locomotive')
    if WPT.get('game_lost') or not (task and task.done and loco and loco.valid) then return end
    local surface = loco.surface
    if surface.index ~= WPT.get('active_surface_index') or this.retired[surface.index] then return end
    local depth = -Orent.sign() * Orent.progression(loco.position)
    local band = math.floor((depth + settings.ahead - settings.first) / settings.spacing)
    local debug = _DEBUG and band < 0
    if debug then band = -1 end
    if band < 0 and not debug then return end
    this.closed_through = math.max(this.closed_through or -2, band - 1)
    for key, old in pairs(this.sites) do
        if old.band and old.band <= this.closed_through and old.phase ~= 'placed' then
            if old.registration then this.registrations[old.registration] = nil end
            this.sites[key] = nil
        end
    end
    if band <= this.closed_through then return end
    local id = tostring(this.run) .. ':' .. tostring(band)
    local site = this.sites[id]
    if not site then
        site = { id = id, run = this.run, band = band, phase = 'searching', attempts = 0, surface_index = surface.index }
        local target = debug and (depth + 24) or (settings.first + band * settings.spacing)
        local variant = select_variant(target)
        site.name, site.tier, site.power = variant.name, variant.tier, variant.power
        this.sites[id] = site
    end
    if not site.name then
        site.name, site.tier, site.power = name, 'small', 1
    end
    if site.placement_version ~= 1 then
        if site.phase == 'failed' and not site.entity and not site.unit_number and not site.registration
            and site.run == this.run and site.surface_index == surface.index then
            site.phase, site.attempts = 'searching', 0
        end
        site.placement_version = 1
    end
    if site.phase ~= 'searching' then return end
    if site.surface_index ~= surface.index then
        retire(site, 'retired'); return
    end
    if not debug and depth >= settings.first + band * settings.spacing then
        retire(site, 'failed'); return
    end
    place(site, loco, debug)
end

local function surface_removed(e)
    this.retired[e.surface_index] = true
    this.ready[e.surface_index] = nil
    for _, site in pairs(this.sites) do
        if site.surface_index == e.surface_index then retire(site, 'destroyed') end
    end
end

Event.on_nth_tick(settings.interval, tick)
Event.add(defines.events.on_pre_surface_deleted, surface_removed)
Event.add(defines.events.on_pre_surface_cleared, surface_removed)

Event.add(defines.events.on_object_destroyed,
    function (e)
        local id = this.registrations[e.registration_number]
        if id and this.sites[id] then
            retire(this.sites[id], 'destroyed')
        end
    end
)
Event.add(defines.events.on_entity_died,
    function (e)
        local entity = e.entity
        if not (entity and entity.valid) then return end
        local matches = false
        for _, variant in ipairs(variants) do
            if entity.name == variant.name then
                matches = true; break
            end
        end
        if not matches then return end
        for _, site in pairs(this.sites) do
            if site.phase == 'placed' and site.unit_number == entity.unit_number then
                retire(site, 'destroyed')
            end
        end
    end
)

return Public
