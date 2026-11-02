local Event = require 'utils.event'
local Global = require 'utils.global'
local Commands = require 'utils.commands'
local WPT = require 'maps.mountain_fortress_v3.table'
local Orient = require 'maps.mountain_fortress_v3.orientation'
local Buried = require 'maps.mountain_fortress_v3.buried_enemies'
local Rewards = require 'maps.mountain_fortress_v3.flag_rewards'
local RPG = require 'modules.rpg.main'
local Collapse = require 'modules.collapse'
local Alert = require 'utils.alert'
local Token = require 'utils.token'
local Math = require 'utils.math.math'
local Public = {}


local post_name, flag_name = 'mtn-addon-mission-flag-post-medium', 'mtn-addon-mission-flag'
local frame_name, pickup_name, deliver_name = 'mtn_flag_mission', 'mtn_flag_pickup', 'mtn_flag_deliver'
local max_flags_to_spawn = 3
local min_flag_spacing = 64
local wait_ticks = 36000
local spawn_delay_ticks = 7200
local this = { run = 1, serial = 0 }
local debug_warned = false

Global.register(this,
    function (saved)
        this = saved
    end
)

local function is_enabled()
    local enabled = prototypes and prototypes.entity[post_name] and prototypes.item[flag_name]
    if _DEBUG and not enabled and not debug_warned then
        debug_warned = true
        log('Flag mission debug: missing prototype ' .. post_name .. ' or ' .. flag_name)
    end
    return enabled
end

local function train_target()
    local task = WPT.get('current_task')
    local loco = WPT.get('locomotive')
    if WPT.get('game_lost') or not (task and task.done) then return end
    if loco and loco.valid and loco.surface.index == WPT.get('active_surface_index') then return loco end
end

local function is_near(a, b)
    return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 <= 9
end

local function identity(stack, m)
    return stack and stack.valid and stack.valid_for_read and stack.is_item_with_tags
        and stack.name == flag_name and stack.count == 1 and stack.quality.name == 'normal'
        and stack.get_tag('mtn_flag_schema') == 1
        and stack.get_tag('mtn_flag_run_id') == m.run_id
        and stack.get_tag('mtn_flag_mission_id') == m.id
        and stack.get_tag('mtn_flag_generation') == m.generation
end

local function migrate()
    this.missions = this.missions or {}
    this.run = this.run or 1
    this.serial = this.serial or 0
    if this.active then
        local m = this.active
        this.missions[m.id] = m
        this.serial = Math.max(this.serial, tonumber(m.id) or 0)
        this.active = nil
    end
    for _, m in pairs(this.missions) do
        if not m.post_position and m.post and m.post.valid then
            m.post_position = { x = m.post.position.x, y = m.post.position.y }
        end
    end
end

local function has_token(player, m)
    if identity(player.cursor_stack, m) then return true end
    for _, inventory_id in pairs(defines.inventory) do
        local inventory = player.get_inventory(inventory_id)
        if inventory and inventory.valid then
            for i = 1, #inventory do
                if identity(inventory[i], m) then return true end
            end
        end
    end
    return false
end

function Public.is_carrying_active_flag(player)
    migrate()
    if not (player and player.valid) then return false end
    for _, m in pairs(this.missions) do
        if m.phase == 'carried' and m.issued and not m.redeemed
            and m.run_id == tostring(this.run) and m.deadline_tick and game.tick < m.deadline_tick
            and has_token(player, m) then
            return true
        end
    end
    return false
end

RPG.register_spell_cast_validator(
    Token.register(function (player)
        if Public.is_carrying_active_flag(player) then
            return false, 'You cannot cast RPG spells while carrying the active mission flag.'
        end
        return true
    end)
)

local function live_token_mission(m)
    return m.phase == 'carried' and m.issued and not m.redeemed
        and m.run_id == tostring(this.run) and m.deadline_tick and game.tick < m.deadline_tick
end

local function location(entity)
    return '[gps=' .. entity.position.x .. ',' .. entity.position.y .. ',' .. entity.surface.name .. ']'
end

local function player_dying(event)
    migrate()
    local player = game.get_player(event.player_index)
    if not (player and player.valid and player.character and player.character.valid) then return end
    for _, m in pairs(this.missions) do
        if live_token_mission(m) and has_token(player, m) then
            Alert.alert_all_players(15, '[color=yellow][CTF][/color] ' .. player.name .. ' died carrying flag #' .. m.id
                .. ' at ' .. location(player.character) .. '. Recover the flag from the corpse and return it before the mission deadline ('
                .. Math.ceil((m.deadline_tick - game.tick) / 60) .. ' seconds remaining).', nil, nil, nil, 'minor')
        end
    end
end

Collapse.register_removal_observer(
    Token.register(function (entity)
        if entity.type ~= 'character-corpse' then return end
        migrate()
        local inventory = entity.get_inventory(defines.inventory.character_corpse)
        if not (inventory and inventory.valid) then return end
        local owner_index = entity.character_corpse_player_index
        local owner = owner_index and game.get_player(owner_index)
        local name = owner and owner.valid and owner.name or 'an unknown player'
        local position = location(entity)
        local lost = {}
        for _, m in pairs(this.missions) do
            if live_token_mission(m) then
                for i = 1, #inventory do
                    if identity(inventory[i], m) then
                        lost[#lost + 1] = m.id
                        break
                    end
                end
            end
        end
        if #lost == 0 then return end
        return function ()
            for _, id in ipairs(lost) do
                Alert.alert_all_players(15, '[color=yellow][CTF][/color] Flag #' .. id .. ' in ' .. name
                    .. "'s corpse at " .. position .. ' was lost to collapse.', nil, nil, nil, 'minor')
            end
        end
    end)
)

local function remove_gui(player)
    local frame = player.gui.screen[frame_name]
    if frame then frame.destroy() end
end

local function cleanup(m)
    if m.post and m.post.valid then m.post.destroy() end
    if m.tag and m.tag.valid then m.tag.destroy() end

    for _, player in pairs(game.players) do
        for _, inventory_id in pairs(defines.inventory) do
            local inventory = player.get_inventory(inventory_id)
            if inventory and inventory.valid then
                for i = 1, #inventory do
                    if identity(inventory[i], m) then inventory[i].clear() end
                end
            end
        end
        if identity(player.cursor_stack, m) then player.cursor_stack.clear() end
        remove_gui(player)
    end
end

local function close(m, phase)
    if not m then return end
    m.phase = phase
    if m.encounter_context then m.encounter_context.cancelled = true end
    this.missions[m.id] = nil
    this.last = m
    cleanup(m)
end

function Public.reset()
    migrate()
    this.run = this.run + 1
    local missions = this.missions
    this.missions = {}
    for _, m in pairs(missions) do
        m.phase = 'cancelled'
        if m.encounter_context then m.encounter_context.cancelled = true end
    end
    for _, m in pairs(missions) do cleanup(m) end
    this.last = nil
    this.next_tick = game.tick + wait_ticks
    this.next_spawn_tick = nil
    for _, player in pairs(game.players) do remove_gui(player) end
end

local function eligible(player, m)
    return player and player.valid and player.controller_type == defines.controllers.character
        and player.character and player.character.valid and player.character.health > 0
        and player.character.force.index == m.force_index
        and player.character.surface.index == m.surface_index
        and player.surface.index == m.surface_index and player.force.index == m.force_index
end

local function valid_mission(loco, m)
    if not m then return end
    if m.redeemed or m.phase == 'redeeming' then
        m.redeemed = true
        close(m, 'reward_unknown')
        return
    end
    if not loco or m.run_id ~= tostring(this.run) or not m.deadline_tick or game.tick >= m.deadline_tick
        or (m.phase ~= 'available' and m.phase ~= 'carried')
        or loco.surface.index ~= m.surface_index or loco.force.index ~= m.force_index
        or (m.phase == 'available' and not (m.post and m.post.valid and m.post.unit_number == m.post_unit)) then
        close(m, 'cancelled')
        return
    end
    if not m.reward then m.reward = Rewards.create(true) end
    return m
end

local function mission_count()
    local count = 0
    for _ in pairs(this.missions) do count = count + 1 end
    return count
end

local function separated(pos, surface_index)
    for _, m in pairs(this.missions) do
        local other = m.post_position
        if other and m.surface_index == surface_index
            and (pos.x - other.x) ^ 2 + (pos.y - other.y) ^ 2 < min_flag_spacing ^ 2 then
            return false
        end
    end
    return true
end

local function spawn(loco)
    if mission_count() >= max_flags_to_spawn then return end
    local surface = loco.surface

    local distances = {}
    if _DEBUG then
        for distance = 8, 48, 8 do distances[#distances + 1] = distance end
    end
    for distance = 256, 512, 32 do distances[#distances + 1] = distance end
    for _, distance in ipairs(distances) do
        for lateral = -96, 96, 16 do
            local pos = Orient.offset(loco.position, lateral, -Orient.sign() * distance)
            if separated(pos, surface.index) and surface.is_chunk_generated({ x = Math.floor(pos.x / 32), y = Math.floor(pos.y / 32) })
                and surface.can_place_entity { name = 'character', position = pos, force = loco.force }
                and surface.can_place_entity { name = post_name, position = pos, force = loco.force } then
                local post = surface.create_entity { name = post_name, position = pos, force = loco.force }
                if post and post.valid then
                    post.minable_flag, post.destructible = false, false
                    if _DEBUG then this.debug_retry_tick = nil end
                    this.serial = this.serial + 1
                    local m =
                    {
                        run_id = tostring(this.run),
                        id = tostring(this.serial),
                        generation = 1,
                        phase = 'available',
                        issued = false,
                        redeemed = false,
                        reward = Rewards.create(),
                        deadline_tick = game.tick + Math.random(15, 25) * 3600,
                        force_index = loco.force.index,
                        surface_index = surface.index,
                        post_position = { x = pos.x, y = pos.y },
                        post = post,
                        post_unit = post.unit_number
                    }
                    this.missions[m.id] = m
                    this.next_spawn_tick = game.tick + spawn_delay_ticks
                    this.next_tick = this.next_spawn_tick
                    Alert.alert_force(loco.force, 15, '[color=yellow][CTF][/color] New mission detected!'
                        .. ' Return the flag for ' .. Rewards.describe(m.reward) .. ' within ' .. ((m.deadline_tick - game.tick) / 3600) .. ' minutes!', 'minor')
                    return m
                end
            end
        end
    end
    this.next_tick = game.tick + 600
    if _DEBUG then this.debug_retry_tick = game.tick + 600 end
end

Commands.new('mtn_spawn_flag', 'Spawn a flag mission on generated terrain, bypassing the mission cooldown.')
    :require_admin()
    :callback(
        function (player)
            migrate()
            if not is_enabled() then
                Alert.alert_player(player, 10, 'Flag mission: missing required flag prototypes.', nil, nil, nil, 'personal')
                return
            end
            local loco = train_target()
            if not loco then
                Alert.alert_player(player, 10, 'Flag mission: round not ready, locomotive unavailable, or game lost.', nil, nil, nil, 'personal')
                return
            end
            for _, m in pairs(this.missions) do valid_mission(loco, m) end
            if mission_count() >= max_flags_to_spawn then
                Alert.alert_player(player, 10, 'Flag mission: all ' .. max_flags_to_spawn .. ' mission slots are full.', nil, nil, nil, 'personal')
                return
            end
            if spawn(loco) then
                Alert.alert_player(player, 10, 'Flag mission: spawned successfully.', nil, nil, nil, 'personal')
            else
                Alert.alert_player(player, 10, 'Flag mission: no valid placement on generated terrain.', nil, nil, nil, 'personal')
            end
        end
    )

local function gui(player, m, loco)
    local visible = false
    if eligible(player, m) then
        if m.phase == 'available' then
            visible = m.post and m.post.valid and m.post.unit_number == m.post_unit
                and is_near(player.character.position, m.post.position)
        elseif m.phase == 'carried' and m.issued and loco and loco.valid
            and is_near(player.character.position, loco.position) then
            local inventory = player.get_main_inventory()
            if inventory and inventory.valid then
                for i = 1, #inventory do
                    if identity(inventory[i], m) then
                        visible = true
                        break
                    end
                end
            end
        end
    end
    if not visible then return false end
    local frame = player.gui.screen[frame_name]
    if not frame then
        frame = player.gui.screen.add { type = 'frame', name = frame_name, direction = 'vertical', caption = 'Capture the flag' }
        frame.force_auto_center()
        frame.add { type = 'label', name = 'status', caption = '' }
        frame.add { type = 'button', name = pickup_name, caption = 'Pick up flag (within 3 tiles)' }
        frame.add { type = 'button', name = deliver_name, caption = 'Deliver flag at locomotive' }
    end
    frame.status.style.single_line = false
    frame[pickup_name].visible = m.phase == 'available'
    frame[deliver_name].visible = m.phase == 'carried'
    frame.tags = { mission_id = m.id }
    frame[pickup_name].tags = { mission_id = m.id }
    frame[deliver_name].tags = { mission_id = m.id }
    frame.status.caption = (m.phase == 'available' and 'Retrieve the flag' or 'Return the flag to the train') .. '\n' .. Math.ceil((m.deadline_tick - game.tick) / 3600)
        .. ' min left\n' .. Rewards.describe(m.reward)
    return true
end

local function movement(m)
    local carrier
    if m.phase == 'carried' and m.issued then
        for _, player in pairs(game.connected_players) do
            if eligible(player, m) and has_token(player, m) then carrier = player end
            if carrier then break end
        end
    end
    local previous = m.movement
    m.movement = nil
    if not carrier then return end
    local character = carrier.character
    local p = character.position
    local walking = not carrier.driving and carrier.walking_state and carrier.walking_state.walking
    m.movement = { player = carrier.index, character = character, x = p.x, y = p.y, walking = walking }
    if not previous or not previous.walking or previous.player ~= carrier.index or previous.character ~= character
        or not walking then
        return
    end
    local distance = Math.sqrt((p.x - previous.x) ^ 2 + (p.y - previous.y) ^ 2)

    if distance > 16 then return end
    m.walked_distance = (m.walked_distance or 0) + distance
    m.encounter_distance = (m.encounter_distance or 0) + distance
    if m.encounter_distance < 8 or game.tick < (m.next_encounter_tick or 0) then return end
    m.encounters = (m.encounters or 0) + 1
    m.encounter_distance = 0
    m.next_encounter_tick = game.tick + 180
    m.encounter_context = m.encounter_context or {}
    local ramp = Math.min(1000, (m.encounters - 1) * 40 + m.walked_distance * 0.5)
    Buried.buried_biter(character.surface, p, Math.min(4, m.encounters), nil,
        {
            difficulty = Math.floor(Math.abs(Orient.progression(p))) * 0.20 + ramp,
            cancellation = m.encounter_context
        })
end

local function tick()
    migrate()
    local loco = is_enabled() and train_target() or nil
    for _, m in pairs(this.missions) do valid_mission(loco, m) end
    if not loco then
        for _, player in pairs(game.players) do remove_gui(player) end
        return
    end
    if not this.next_tick then this.next_tick = game.tick + wait_ticks end
    local next_tick = _DEBUG and (this.debug_retry_tick or 0) or this.next_tick
    if game.tick >= next_tick and game.tick >= (this.next_spawn_tick or 0)
        and mission_count() < max_flags_to_spawn then
        spawn(loco)
    end
    local missions = {}
    for _, m in pairs(this.missions) do
        movement(m)
        missions[#missions + 1] = m
    end
    for _, player in pairs(game.connected_players) do
        local function distance(m)
            local pos = m.phase == 'available' and m.post_position or loco.position
            local origin = player.character and player.character.valid and player.character.position
            if not pos or not origin then return Math.huge end
            return (origin.x - pos.x) ^ 2 + (origin.y - pos.y) ^ 2
        end
        table.sort(missions, function (a, b)
            local da, db = distance(a), distance(b)
            if da == db then return tonumber(a.id) < tonumber(b.id) end
            return da < db
        end)
        local visible = false
        for _, m in ipairs(missions) do
            if gui(player, m, loco) then
                visible = true; break
            end
        end
        if not visible then remove_gui(player) end
    end
end

local function click(event)
    migrate()
    local element = event.element
    if not (element and element.valid and (element.name == pickup_name or element.name == deliver_name)) then return end
    if not is_enabled() then return end
    local loco = train_target()
    local id = element.tags and element.tags.mission_id
    local m = valid_mission(loco, id and this.missions[id])
    local player = game.get_player(event.player_index)
    if not m or not eligible(player, m) then return end
    local inventory = player.get_main_inventory()
    if not (inventory and inventory.valid) then return end
    if element.name == pickup_name then
        if m.phase ~= 'available' or m.issued or not is_near(player.character.position, m.post.position) then return end
        for i = 1, #inventory do
            local slot = inventory[i]
            if slot.valid and not slot.valid_for_read then
                if not slot.set_stack { name = flag_name, count = 1, quality = 'normal' } then return end
                slot.tags =
                {
                    mtn_flag_schema = 1,
                    mtn_flag_run_id = m.run_id,
                    mtn_flag_mission_id = m.id,
                    mtn_flag_generation = m.generation
                }
                m.issued, m.phase = true, 'carried'
                if m.post.valid then m.post.destroy() end
                Alert.alert_force(loco.force, 15, '[color=yellow][CTF][/color] Flag picked up! Return within 3 tiles of the locomotive and click Deliver flag.', 'minor')
                return
            end
        end
        Alert.alert_player(player, 10, '[color=yellow][CTF][/color] Make room in your main inventory for the flag.', nil, nil, nil, 'personal')
    elseif m.phase == 'carried' and m.issued and not m.redeemed and is_near(player.character.position, loco.position) then
        for i = 1, #inventory do
            local stack = inventory[i]
            if identity(stack, m) then
                m.redeemed, m.phase = true, 'redeeming'
                WPT.record_flag_delivery(m.run_id, m.id, m.generation)
                local ok, err = pcall(function ()
                    stack.clear(); Rewards.deliver(loco, m.reward)
                end)
                m.reward_error = not ok and tostring(err) or nil
                if not ok then log('Flag mission reward failed (no retry): ' .. tostring(err)) end
                close(m, ok and 'completed' or 'reward_failed')
                if ok then
                    Alert.alert_force(loco.force, 15, '[color=yellow][CTF][/color] Mission completed! ' .. Rewards.describe(m.reward)
                        .. '.', 'minor')
                    Alert.alert_force(loco.force, 15, 'Items delivered to train cargo or spilled at the locomotive; XP added to the shared pool.', 'minor')
                else
                    Alert.alert_force(loco.force, 15, '[color=yellow][CTF][/color] Flag mission reward failed; some rewards may have been delivered. No retry will be made.', 'minor')
                end
                return
            end
        end
    end
end

local function surface_removed(event)
    migrate()
    for _, m in pairs(this.missions) do
        if m.surface_index == event.surface_index then close(m, 'cancelled') end
    end
end

Event.on_nth_tick(60, tick)
Event.add(defines.events.on_gui_click, click)
Event.add(defines.events.on_pre_player_died, player_dying)
Event.add(defines.events.on_pre_surface_deleted, surface_removed)
Event.add(defines.events.on_pre_surface_cleared, surface_removed)

return Public
