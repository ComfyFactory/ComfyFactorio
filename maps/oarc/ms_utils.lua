local Surface = require 'utils.surface'
local MT = require 'maps.oarc.table'
local Alert = require 'utils.alert'
local HD = require 'modules.hidden_dimension.main'
local SessionData = require 'utils.datastore.session_data'

local table_insert = table.insert
local table_remove = table.remove
local random = math.random
local max = math.max
local floor = math.floor
local format = string.format
local abs = math.abs

local Public = {}

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- General Helper Functions
--------------------------------------------------------------------------------

-- Prints flying text.
-- Color is optional
local FlyingText = require 'utils.functions.flying_texts'

function Public.FlyingText(msg, pos, color, surface)
    FlyingText.flying_text(nil, surface, pos, msg, color)
end

-- Requires having an on_tick handler.
function Public.DisplaySpeechBubble(player, text, timeout_secs)
    local this = MT.get()

    if (this.ms_speech_bubbles == nil) then
        this.ms_speech_bubbles = {}
    end

    if (player and player.character) then
        local sp =
            player.surface.create_entity
            {
                name = 'compi-speech-bubble',
                position = player.position,
                text = text,
                source = player.character
            }
        table_insert(
            this.ms_speech_bubbles,
            {
                entity = sp,
                timeout_tick = game.tick + (timeout_secs * this.ticks_per_second)
            }
        )
    end
end

-- Every second, check a global table to see if we have any speech bubbles to kill.
function Public.TimeoutSpeechBubblesOnTick()
    local this = MT.get()
    if ((game.tick % (this.ticks_per_second)) == 3) then
        if (this.ms_speech_bubbles and (#this.ms_speech_bubbles > 0)) then
            for k, sp in pairs(this.ms_speech_bubbles) do
                if (game.tick > sp.timeout_tick) then
                    if (sp.entity ~= nil) and (sp.entity.valid) then
                        sp.entity.start_fading_out()
                    end
                    table_remove(this.ms_speech_bubbles, k)
                end
            end
        end
    end
end

-- Broadcast messages to all connected players
function Public.SendBroadcastMsg(msg)
    local color = { r = 0, g = 255, b = 171 }
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Alert.alert_player(player, 10, msg, color)
    end
end

-- Send a message to a player, safely checks if they exist and are online.
function Public.SendMsg(playerName, msg)
    if ((game.players[playerName] ~= nil) and (game.players[playerName].connected)) then
        game.players[playerName].print(msg)
    end
end

-- Useful for displaying game time in mins:secs format
function Public.formattime(ticks)
    local secs = ticks / 60
    local minutes = floor((secs) / 60)
    local seconds = floor(secs - 60 * minutes)
    return format('%dm:%02ds', minutes, seconds)
end

-- Useful for displaying game time in mins:secs format
function Public.formattime_hours_mins(ticks)
    local seconds = ticks / 60
    local minutes = floor((seconds) / 60)
    local hours = floor((minutes) / 60)
    local min = floor(minutes - 60 * hours)
    return format('%dh:%02dm', hours, minutes, min)
end

-- Simple function Public.to get total number of items in table
function Public.TableLength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function Public.shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

-- Get a random KEY from a table.
function Public.GetRandomKeyFromTable(t)
    local keyset = {}
    for k, _ in pairs(t) do
        table.insert(keyset, k)
    end
    return keyset[math.random(#keyset)]
end

function Public.GetRandomValueFromTable(t)
    return t[Public.GetRandomKeyFromTable(t)]
end

-- Simple function Public.to get distance between two positions.
function Public.getDistance(posA, posB)
    -- Get the length for each of the components x and y
    local xDist = posB.x - posA.x
    local yDist = posB.y - posA.y

    return math.sqrt((xDist ^ 2) + (yDist ^ 2))
end

-- Given a table of positions, returns key for closest to given pos.
function Public.GetClosestPosFromTable(pos, pos_table)
    local closest_dist

    for _, p in pairs(pos_table) do
        local new_dist = Public.getDistance(pos, p)
        if (closest_dist == nil) then
            closest_dist = new_dist
        elseif (closest_dist > new_dist) then
            closest_dist = new_dist
        end
    end
end

-- Chart area for a force
function Public.ChartArea(force, position, chunkDist, surface)
    local this = MT.get()
    force.chart(
        surface,
        {
            {
                position.x - (this.chunk_size * chunkDist),
                position.y - (this.chunk_size * chunkDist)
            },
            {
                position.x + (this.chunk_size * chunkDist),
                position.y + (this.chunk_size * chunkDist)
            }
        }
    )
end

-- Give player these default items.
function Public.GivePlayerItems(player)
    local this = MT.get()
    for _, item in pairs(this.player_respawn_start_items) do
        player.insert(item)
    end
end

-- Starter only items
function Public.GivePlayerStarterItems(player, state, starter_items)
    local this = MT.get()
    if not this.town_only_layout or starter_items then
        for _, item in pairs(this.player_spawn_start_items) do
            player.insert(item)
        end
    end

    if this.enable_power_armor and state then
        Public.GiveQuickStartPowerArmor(player)
    end
end

-- Cheater's quick start
function Public.GiveQuickStartPowerArmor(player)
    player.insert { name = 'modular-armor', count = 1 }

    if player and player.get_inventory(defines.inventory.character_armor) ~= nil and player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
        local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
        if p_armor ~= nil then
            p_armor.put({ name = 'battery-equipment' })
            p_armor.put({ name = 'personal-roboport-equipment' })
            p_armor.put({ name = 'battery-equipment' })
            p_armor.put({ name = 'solar-panel-equipment' })
            p_armor.put({ name = 'solar-panel-equipment' })
            p_armor.put({ name = 'solar-panel-equipment' })
            p_armor.put({ name = 'solar-panel-equipment' })
            p_armor.put({ name = 'solar-panel-equipment' })
            p_armor.put({ name = 'solar-panel-equipment' })
            p_armor.put({ name = 'solar-panel-equipment' })
        end
        player.insert { name = 'construction-robot', count = 25 }
    end
end

-- Create area given point and radius-distance
function Public.GetAreaFromPointAndDistance(point, dist)
    local area =
    {
        left_top =
        {
            x = point.x - dist,
            y = point.y - dist
        },
        right_bottom =
        {
            x = point.x + dist,
            y = point.y + dist
        }
    }
    return area
end

-- Check if given position is in area bounding box
function Public.CheckIfInArea(point, area)
    if ((point.x >= area.left_top.x) and (point.x < area.right_bottom.x)) then
        if ((point.y >= area.left_top.y) and (point.y < area.right_bottom.y)) then
            return true
        end
    end
    return false
end

-- Set all forces to ceasefire
function Public.SetCeaseFireBetweenAllForces()
    for name, team in pairs(game.forces) do
        if name ~= 'neutral' and name ~= 'enemy' then
            for x, _ in pairs(game.forces) do
                if x ~= 'neutral' and x ~= 'enemy' then
                    team.set_cease_fire(x, true)
                    team.set_friend(x, true)
                end
            end
        end
    end
end

-- For each other player force, share a chat msg.
function Public.ShareChatBetweenForces(player, msg)
    for _, force in pairs(game.forces) do
        if (force ~= nil) then
            if ((force.name ~= 'enemy') and (force.name ~= 'neutral') and (force.name ~= player) and (force ~= player.force)) then
                force.print(player.name .. ': ' .. msg, player.chat_color)
            end
        end
    end
end

-- Merges force2 INTO force1 but keeps all research between both forces.
function Public.MergeForcesKeepResearch(force1, force2)
    for techName, luaTech in pairs(force2.technologies) do
        if (luaTech.researched) then
            force1.technologies[techName].researched = true
            force1.technologies[techName].level = luaTech.level
        end
    end
    game.merge_forces(force2, force1)
end

-- Undecorator
function Public.RemoveDecorationsArea(surface, area)
    surface.destroy_decoratives { area = area }
end

-- Remove fish
function Public.RemoveFish(surface, area)
    for _, entity in pairs(surface.find_entities_filtered { area = area, type = 'fish' }) do
        entity.destroy()
    end
end

-- Render a path
function Public.RenderPath(path, ttl, players)
    local surface_name = Surface.get_surface_name()
    local last_pos = path[1].position
    local color

    for i, v in pairs(path) do
        if (i ~= 1) then
            color = { r = 1 / (1 + (i % 3)), g = 1 / (1 + (i % 5)), b = 1 / (1 + (i % 7)), a = 0.5 }
            rendering.draw_line
            {
                color = color,
                width = 2,
                from = v.position,
                to = last_pos,
                surface = game.surfaces[surface_name],
                players = players,
                time_to_live = ttl
            }
        end
        last_pos = v.position
    end
end

-- Get a random 1 or -1
function Public.RandomNegPos()
    if (random(0, 1) == 1) then
        return 1
    else
        return -1
    end
end

-- Create a random direction vector to look in
function Public.GetRandomVector()
    local randVec = { x = 0, y = 0 }
    while ((randVec.x == 0) and (randVec.y == 0)) do
        randVec.x = random(-3, 3)
        randVec.y = random(-3, 3)
    end
    log('direction: x=' .. randVec.x .. ', y=' .. randVec.y)
    return randVec
end

-- Check for ungenerated chunks around a specific chunk
-- +/- chunkDist in x and y directions
function Public.IsChunkAreaUngenerated(chunkPos, chunkDist, surface)
    for x = -chunkDist, chunkDist do
        for y = -chunkDist, chunkDist do
            local checkPos =
            {
                x = chunkPos.x + x,
                y = chunkPos.y + y
            }
            if (surface.is_chunk_generated(checkPos)) then
                return false
            end
        end
    end
    return true
end

-- Clear out enemies around an area with a certain distance
function Public.ClearNearbyEnemies(pos, safeDist, surface)
    local safeArea =
    {
        left_top =
        {
            x = pos.x - safeDist,
            y = pos.y - safeDist
        },
        right_bottom =
        {
            x = pos.x + safeDist,
            y = pos.y + safeDist
        }
    }

    for _, entity in pairs(surface.find_entities_filtered { area = safeArea, force = 'enemy' }) do
        entity.destroy()
    end
end

-- function Public.to find coordinates of ungenerated map area in a given direction
-- starting from the center of the map
function Public.FindMapEdge(directionVec, surface)
    local this = MT.get()
    local position = { x = 0, y = 0 }
    local chunkPos = { x = 0, y = 0 }

    -- Keep checking chunks in the direction of the vector
    while (true) do
        -- Set some absolute limits.
        if ((abs(chunkPos.x) > 1000) or (abs(chunkPos.y) > 1000)) then
            -- If chunk is already generated, keep looking
            break
        elseif (surface.is_chunk_generated(chunkPos)) then
            -- Found a possible ungenerated area
            chunkPos.x = chunkPos.x + directionVec.x
            chunkPos.y = chunkPos.y + directionVec.y
        else
            chunkPos.x = chunkPos.x + directionVec.x
            chunkPos.y = chunkPos.y + directionVec.y

            -- Check there are no generated chunks in a 10x10 area.
            if Public.IsChunkAreaUngenerated(chunkPos, 10, surface) then
                position.x = (chunkPos.x * this.chunk_size) + (this.chunk_size / 2)
                position.y = (chunkPos.y * this.chunk_size) + (this.chunk_size / 2)
                break
            end
        end
    end

    -- log("spawn: x=" .. position.x .. ", y=" .. position.y)
    return position
end

-- Find random coordinates within a given distance away
-- maxTries is the recursion limit basically.
function Public.FindUngeneratedCoordinates(minDistChunks, maxDistChunks, surface)
    local this = MT.get()
    local position = { x = 0, y = 0 }
    local chunkPos = { x = 0, y = 0 }

    local maxTries = 100
    local tryCounter = 0

    local minDistSqr = minDistChunks ^ 2
    local maxDistSqr = maxDistChunks ^ 2

    while (true) do
        chunkPos.x = random(0, maxDistChunks) * Public.RandomNegPos()
        chunkPos.y = random(0, maxDistChunks) * Public.RandomNegPos()

        local distSqrd = chunkPos.x ^ 2 + chunkPos.y ^ 2

        -- Enforce a max number of tries
        tryCounter = tryCounter + 1
        if (tryCounter > maxTries) then
            log('FindUngeneratedCoordinates - Max Tries Hit!')
            break
        elseif (distSqrd >= minDistSqr and distSqrd <= maxDistSqr)
            and Public.IsChunkAreaUngenerated(chunkPos, this.check_spawn_ungenerated_chunk_radius, surface) then
            position.x = (chunkPos.x * this.chunk_size) + (this.chunk_size / 2)
            position.y = (chunkPos.y * this.chunk_size) + (this.chunk_size / 2)
            break -- SUCCESS
        end
    end

    -- log('spawn: x=' .. position.x .. ', y=' .. position.y)
    return position
end

-- General purpose function Public.for removing a particular recipe
function Public.RemoveRecipe(force, recipeName)
    local recipes = force.recipes
    if recipes[recipeName] then
        recipes[recipeName].enabled = false
    end
end

-- General purpose function Public.for adding a particular recipe
function Public.AddRecipe(force, recipeName)
    local recipes = force.recipes
    if recipes[recipeName] then
        recipes[recipeName].enabled = true
    end
end

-- General command for disabling a tech.
function Public.DisableTech(force, techName)
    if force.technologies[techName] then
        force.technologies[techName].enabled = false
        force.technologies[techName].visible_when_disabled = true
    end
end

-- General command for enabling a tech.
function Public.EnableTech(force, techName)
    if force.technologies[techName] then
        force.technologies[techName].enabled = true
    end
end

-- Get an area given a position and distance.
-- Square length = 2x distance
function Public.GetAreaAroundPos(pos, dist)
    return
    {
        left_top =
        {
            x = pos.x - dist,
            y = pos.y - dist
        },
        right_bottom =
        {
            x = pos.x + dist,
            y = pos.y + dist
        }
    }
end

-- Gets chunk position of a tile.
function Public.GetChunkPosFromTilePos(tile_pos)
    return { x = floor(tile_pos.x / 32), y = floor(tile_pos.y / 32) }
end

function Public.GetCenterTilePosFromChunkPos(c_pos)
    return { x = c_pos.x * 32 + 16, y = c_pos.y * 32 + 16 }
end

-- Get the left_top
function Public.GetChunkTopLeft(pos)
    return { x = pos.x - (pos.x % 32), y = pos.y - (pos.y % 32) }
end

-- Get area given chunk
function Public.GetAreaFromChunkPos(chunk_pos)
    return
    {
        left_top = { x = chunk_pos.x * 32, y = chunk_pos.y * 32 },
        right_bottom = { x = chunk_pos.x * 32 + 31, y = chunk_pos.y * 32 + 31 }
    }
end

-- Get area given pos
function Public.GetAreaFromPos(pos)
    local area =
    {
        left_top = { x = pos.x - 32, y = pos.y - 32 },
        right_bottom = { x = pos.x + 32, y = pos.y + 32 }
    }
    return area
end

-- Removes the entity type from the area given
function Public.RemoveInArea(surface, area, type)
    for _, entity in pairs(surface.find_entities_filtered { area = area, type = type }) do
        if entity.valid and entity and entity.position then
            entity.destroy()
        end
    end
end

-- Removes the entity type from the area given
-- Only if it is within given distance from given position.
function Public.RemoveInCircle(surface, area, type, pos, dist)
    for _, entity in pairs(surface.find_entities_filtered { area = area, type = type }) do
        if entity.valid and entity and entity.position and entity.name ~= 'character' then
            if ((pos.x - entity.position.x) ^ 2 + (pos.y - entity.position.y) ^ 2 < dist ^ 2) then
                entity.destroy()
            end
        end
    end
end

-- Create another surface so that we can modify map settings and not have a screwy nauvis map.
function Public.CreateGameSurface()
    local this = MT.get()
    -- Get starting surface settings.
    local nauvis_settings = game.surfaces['nauvis'].map_gen_settings

    if this.enable_vanilla_spawns then
        Surface.set_island(true)
        nauvis_settings.starting_points = Public.CreateVanillaSpawns(this.vanilla_spawn_count,
            this.vanilla_spawn_distance)

        -- ENFORCE ISLAND MAP GEN
        if (this.silo_island_mode) then
            nauvis_settings.property_expression_names.elevation = '0_17-island'
        end
    end
end

--------------------------------------------------------------------------------
-- Functions for removing/modifying enemies
--------------------------------------------------------------------------------

-- Convenient way to remove aliens, just provide an area
function Public.RemoveAliensInArea(surface, area)
    for _, entity in pairs(surface.find_entities_filtered { area = area, force = 'enemy' }) do
        entity.destroy()
    end
end

-- Make an area safer
-- Reduction factor divides the enemy spawns by that number. 2 = half, 3 = third, etc...
-- Also removes all big and huge worms in that area
function Public.ReduceAliensInArea(surface, area, reductionFactor)
    for _, entity in pairs(surface.find_entities_filtered { area = area, force = 'enemy' }) do
        if (random(0, reductionFactor) > 0) then
            entity.destroy()
        end
    end
end

-- Downgrades worms in an area based on chance.
-- 100% small would mean all worms are changed to small.
function Public.DowngradeWormsInArea(surface, area, small_percent, medium_percent, big_percent)
    local worm_types = { 'small-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'behemoth-worm-turret' }

    for _, entity in pairs(surface.find_entities_filtered { area = area, name = worm_types }) do
        -- Roll a number between 0-100
        local rand_percent = random(0, 100)
        local worm_pos = entity.position
        local worm_name = entity.name

        -- If number is less than small percent, change to small
        if (rand_percent <= small_percent) then
            -- ELSE If number is less than medium percent, change to small
            if (not (worm_name == 'small-worm-turret')) then
                entity.destroy()
                surface.create_entity { name = 'small-worm-turret', position = worm_pos, force = game.forces.enemy }
            end
        elseif (rand_percent <= medium_percent) then
            -- ELSE If number is less than big percent, change to small
            if (not (worm_name == 'medium-worm-turret')) then
                entity.destroy()
                surface.create_entity { name = 'medium-worm-turret', position = worm_pos, force = game.forces.enemy }
            end
        elseif (rand_percent <= big_percent) then
            if (not (worm_name == 'big-worm-turret')) then
                entity.destroy()
                surface.create_entity { name = 'big-worm-turret', position = worm_pos, force = game.forces.enemy }
            end

            -- ELSE ignore it.
        end
    end
end

function Public.DowngradeWormsDistanceBasedOnChunkGenerate(event)
    local this = MT.get()
    if (Public.getDistance({ x = 0, y = 0 }, event.area.left_top) < (this.near_max_dist * this.chunk_size)) then
        Public.DowngradeWormsInArea(event.surface, event.area, 100, 100, 100)
    elseif (Public.getDistance({ x = 0, y = 0 }, event.area.left_top) < (this.far_min_dist * this.chunk_size)) then
        Public.DowngradeWormsInArea(event.surface, event.area, 50, 90, 100)
    elseif (Public.getDistance({ x = 0, y = 0 }, event.area.left_top) < (this.far_max_dist * this.chunk_size)) then
        Public.DowngradeWormsInArea(event.surface, event.area, 20, 80, 97)
    else
        Public.DowngradeWormsInArea(event.surface, event.area, 0, 20, 90)
    end
end

-- A function Public.to help me remove worms in an area.
-- Yeah kind of an unecessary wrapper, but makes my life easier to remember the worm types.
function Public.RemoveWormsInArea(surface, area, small, medium, big, behemoth)
    local worm_types = {}

    if (small) then
        table_insert(worm_types, 'small-worm-turret')
    end
    if (medium) then
        table_insert(worm_types, 'medium-worm-turret')
    end
    if (big) then
        table_insert(worm_types, 'big-worm-turret')
    end
    if (behemoth) then
        table_insert(worm_types, 'behemoth-worm-turret')
    end

    -- Destroy
    if (Public.TableLength(worm_types) > 0) then
        for _, entity in pairs(surface.find_entities_filtered { area = area, name = worm_types }) do
            entity.destroy()
        end
    else
        log('RemoveWormsInArea had empty worm_types list!')
    end
end

-- Add Long Reach to Character
function Public.GivePlayerLongReach(player)
    local this = MT.get()
    player.character.character_build_distance_bonus = this.build_dist_bonus
    player.character.character_reach_distance_bonus = this.reach_dist_bonus
    -- player.character.character_resource_reach_distance_bonus  = this.resource_dist_bonus
end

-- General purpose cover an area in tiles.
function Public.CoverAreaInTiles(surface, area, tile_name)
    local tiles = {}
    for x = area.left_top.x, area.left_top.x + 31 do
        for y = area.left_top.y, area.left_top.y + 31 do
            table_insert(tiles, { name = tile_name, position = { x = x, y = y } })
        end
    end
    surface.set_tiles(tiles, true)
end

--------------------------------------------------------------------------------
-- Anti-griefing Stuff & Gravestone (My own version)
--------------------------------------------------------------------------------
function Public.SetItemBlueprintTimeToLive(event)
    local type = event.entity.type
    if type == 'entity-ghost' or type == 'tile-ghost' then
        local ghost_ttl = MT.get('ghost_ttl')
        if ghost_ttl ~= 0 then
            event.entity.time_to_live = ghost_ttl
        end
    end
end

--------------------------------------------------------------------------------
-- Gravestone soft mod. With my own modifications/improvements.
--------------------------------------------------------------------------------
-- Return steel chest entity (or nil)
function Public.DropEmptySteelChest(player)
    local pos = player.surface.find_non_colliding_position('steel-chest', player.position, 15, 1)
    if not pos then
        return nil
    end
    local grave = player.surface.create_entity { name = 'steel-chest', position = pos, force = 'neutral' }
    return grave
end

function Public.DropGravestoneChests(player)
    local grave_inv
    local grave
    local count = 0

    -- Make sure we save stuff we're holding in our hands.
    player.clear_cursor()

    -- Loop through a players different inventories
    -- Put it all into a chest.
    -- If the chest is full, create a new chest.
    for _, id in ipairs
    {
        defines.inventory.character_armor,
        defines.inventory.character_main,
        defines.inventory.character_guns,
        defines.inventory.character_ammo,
        defines.inventory.character_vehicle,
        defines.inventory.character_trash
    } do
        local inv = player.get_inventory(id)

        -- No idea how inv can be nil sometimes...?
        if (inv ~= nil) then
            if ((#inv > 0) and not inv.is_empty()) then
                for j = 1, #inv do
                    if inv[j].valid_for_read then
                        -- Create a chest when counter is reset
                        if (count == 0) then
                            grave = Public.DropEmptySteelChest(player)
                            if (grave == nil) then
                                -- player.print("Not able to place a chest nearby! Some items lost!")
                                return
                            end
                            grave_inv = grave.get_inventory(defines.inventory.chest)
                        end
                        count = count + 1

                        -- Copy the item stack into a chest slot.
                        grave_inv[count].set_stack(inv[j])

                        -- Reset counter when chest is full
                        if (count == #grave_inv) then
                            count = 0
                        end
                    end
                end
            end

            -- Clear the player inventory so we don't have duplicate items lying around.
            inv.clear()
        end
    end

    if (grave ~= nil) then
        player.print('Successfully dropped your items into a chest! Go get them quick!')
    end
end

-- Dump player items into a chest after the body expires.
function Public.DropGravestoneChestFromCorpse(corpse)
    if ((corpse == nil) or (corpse.character_corpse_player_index == nil)) then
        return
    end

    local grave, grave_inv
    local count = 0

    local inv = corpse.get_inventory(defines.inventory.character_corpse)

    -- No idea how inv can be nil sometimes...?
    if (inv ~= nil) then
        if ((#inv > 0) and not inv.is_empty()) then
            for j = 1, #inv do
                if inv[j].valid_for_read then
                    -- Create a chest when counter is reset
                    if (count == 0) then
                        grave = Public.DropEmptySteelChest(corpse)
                        if (grave == nil) then
                            -- player.print("Not able to place a chest nearby! Some items lost!")
                            return
                        end
                        grave_inv = grave.get_inventory(defines.inventory.chest)
                    end
                    count = count + 1

                    -- Copy the item stack into a chest slot.
                    grave_inv[count].set_stack(inv[j])

                    -- Reset counter when chest is full
                    if (count == #grave_inv) then
                        count = 0
                    end
                end
            end
        end

        -- Clear the player inventory so we don't have duplicate items lying around.
        -- inv.clear()
    end

    if (grave ~= nil) and (game.players[corpse.character_corpse_player_index] ~= nil) then
        game.players[corpse.character_corpse_player_index].print(
            'Your corpse got eaten by biters! They kindly dropped your items into a chest! Go get them quick!')
    end
end

--------------------------------------------------------------------------------
-- Resource patch and starting area generation
--------------------------------------------------------------------------------

-- Enforce a circle of land, also adds trees in a ring around the area.
function Public.CreateCropCircle(surface, centerPos, chunkArea, tileRadius, fillTile)
    local tileRadSqr = tileRadius ^ 2
    local scenario_config = MT.get('scenario_config')

    local dirtTiles = {}
    for i = chunkArea.left_top.x, chunkArea.right_bottom.x, 1 do
        for j = chunkArea.left_top.y, chunkArea.right_bottom.y, 1 do
            -- This ( X^2 + Y^2 ) is used to calculate if something
            -- is inside a circle area.
            local distVar = floor((centerPos.x - i) ^ 2 + (centerPos.y - j) ^ 2)

            -- Fill in all unexpected water in a circle
            if (distVar < tileRadSqr) then
                if (surface.get_tile(i, j).collides_with('water_tile') or scenario_config.gen_settings.force_grass) then
                    table_insert(dirtTiles, { name = fillTile, position = { i, j } })
                end
            end

            if scenario_config.gen_settings.trees_enabled then
                -- Create a circle of trees around the spawn point.
                if ((distVar < tileRadSqr - 200) and (distVar > tileRadSqr - 400)) then
                    surface.create_entity({ name = 'tree-02', amount = 2, position = { i, j } })
                end
            end
        end
    end

    surface.set_tiles(dirtTiles)
end

function Public.CreateCropCircleNoTrees(surface, centerPos, chunkArea, tileRadius, fillTile)
    local tileRadSqr = tileRadius ^ 2
    local scenario_config = MT.get('scenario_config')

    local dirtTiles = {}
    for i = chunkArea.left_top.x, chunkArea.right_bottom.x, 1 do
        for j = chunkArea.left_top.y, chunkArea.right_bottom.y, 1 do
            -- This ( X^2 + Y^2 ) is used to calculate if something
            -- is inside a circle area.
            local distVar = floor((centerPos.x - i) ^ 2 + (centerPos.y - j) ^ 2)

            -- Fill in all unexpected water in a circle
            if (distVar < tileRadSqr) then
                if (surface.get_tile(i, j).collides_with('water_tile') or scenario_config.gen_settings.force_grass) then
                    table_insert(dirtTiles, { name = fillTile, position = { i, j } })
                end
            end
        end
    end

    surface.set_tiles(dirtTiles)
end

function Public.CreateCropSquare(surface, centerPos, area, tileRadius, fillTile)
    local left_top = area.left_top
    local right_bottom = area.right_bottom
    local scenario_config = MT.get('scenario_config')

    local dirtTiles = {}
    for i = left_top.x, right_bottom.x - 1, 1 do
        for j = left_top.y, right_bottom.y - 1, 1 do
            -- This ( X^2 + Y^2 ) is used to calculate if something
            -- is inside a circle area.

            local distVar = floor(max(abs(centerPos.x - i) - 10, abs(centerPos.y - j) + 20))
            --local distVar = floor((centerPos.x - i)^2 + (centerPos.y - j)^2)

            -- Fill in all unexpected water in a circle
            if (distVar < tileRadius) then
                if (surface.get_tile(i, j).collides_with('water_tile') or scenario_config.gen_settings.force_grass) then
                    table_insert(dirtTiles, { name = fillTile, position = { i, j } })
                end
            end
            if scenario_config.gen_settings.trees_enabled then
                -- Create a circle of trees around the spawn point.
                if ((distVar < tileRadius) and (distVar > tileRadius - 3)) then
                    surface.create_entity({ name = 'tree-02', amount = 1, position = { i, j } })
                end
            end
        end
    end

    surface.set_tiles(dirtTiles)
end

-- COPIED FROM jvmguy!
-- Enforce a square of land, with a tree border
-- this is equivalent to the CreateCropCircle code
function Public.CreateCropOctagon(surface, centerPos, chunkArea, tileRadius, fillTile)
    local dirtTiles = {}
    local scenario_config = MT.get('scenario_config')
    for i = chunkArea.left_top.x, chunkArea.right_bottom.x, 1 do
        for j = chunkArea.left_top.y, chunkArea.right_bottom.y, 1 do
            local distVar1 = floor(max(abs(centerPos.x - i), abs(centerPos.y - j)))
            local distVar2 = floor(abs(centerPos.x - i) + abs(centerPos.y - j))
            local distVar = max(distVar1 * 1.1, distVar2 * 0.707 * 1.1)

            -- Fill in all unexpected water in a circle
            if (distVar < tileRadius + 2) then
                if (surface.get_tile(i, j).collides_with('water_tile') or scenario_config.gen_settings.force_grass) then
                    table_insert(dirtTiles, { name = fillTile, position = { i, j } })
                end
            end

            if scenario_config.gen_settings.trees_enabled then
                -- Create a tree ring
                if ((distVar < tileRadius) and (distVar > tileRadius - 2)) then
                    surface.create_entity({ name = 'tree-01', amount = 1, position = { i, j } })
                end
            end
        end
    end
    surface.set_tiles(dirtTiles)
end

function Public.CreateMoat(surface, centerPos, chunkArea, tileRadius)
    local tileRadSqr = tileRadius ^ 2
    local waterTiles = {}
    local scenario_config = MT.get('scenario_config')
    for i = chunkArea.left_top.x, chunkArea.right_bottom.x, 1 do
        for j = chunkArea.left_top.y, chunkArea.right_bottom.y, 1 do
            -- This ( X^2 + Y^2 ) is used to calculate if something
            -- is inside a circle area.
            local distVar = floor((centerPos.x - i) ^ 2 + (centerPos.y - j) ^ 2)

            -- Create a circle of water
            if ((distVar < tileRadSqr + (1500 * scenario_config.gen_settings.moat_size_modifier)) and (distVar > tileRadSqr)) then
                table_insert(waterTiles, { name = 'water', position = { i, j } })
            end
        end
    end
    surface.set_tiles(waterTiles)
end

function Public.CreateMoatSquare(surface, centerPos, chunkArea, tileRadius)
    local waterTiles = {}
    local insert = table_insert
    for i = chunkArea.left_top.x, chunkArea.right_bottom.x - 1, 1 do
        for j = chunkArea.left_top.y, chunkArea.right_bottom.y - 1, 1 do
            local distVar = floor(max(abs(centerPos.x - i) - 22, abs(centerPos.y - j) + 18))

            -- Create a water ring
            if ((distVar < tileRadius) and (distVar > tileRadius - 3)) then
                insert(waterTiles, { name = 'deepwater', position = { i, j } })
            end
        end
    end
    surface.set_tiles(waterTiles)
end

-- Create a horizontal line of water
function Public.CreateWaterStrip(surface, leftPos, length)
    local waterTiles = {}
    for i = 0, length, 1 do
        table_insert(waterTiles, { name = 'water', position = { leftPos.x + i, leftPos.y } })
    end

    surface.set_tiles(waterTiles)
end

-- function to generate a resource patch, of a certain size/amount at a pos.
function Public.GenerateResourcePatch(surface, resourceName, diameter, pos, amount)
    local midPoint = floor(diameter / 2)
    if (diameter == 0) then
        return
    end
    local scenario_config = MT.get('scenario_config')
    for y = -midPoint, midPoint do
        for x = -midPoint, midPoint do
            if (not scenario_config.gen_settings.resources_circle_shape or ((x) ^ 2 + (y) ^ 2 < midPoint ^ 2)) then
                surface.create_entity(
                    {
                        name = resourceName,
                        amount = random(amount * 0.9, amount),
                        position = { pos.x + x, pos.y + y }
                    }
                )
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Holding pen for new players joining the map
--------------------------------------------------------------------------------
function Public.CreateWall(surface, pos)
    local main_force_name = MT.get('main_force_name')
    local wall = surface.create_entity({ name = 'stone-wall', position = pos, force = main_force_name })
    if wall then
        wall.destructible = false
        wall.minable_flag = false
    end
end

function Public.CreateHoldingPen(surface, chunkArea, sizeTiles, sizeMoat)
    local this = MT.get()
    if
        (((chunkArea.left_top.x >= -(sizeTiles + sizeMoat + this.chunk_size)) and (chunkArea.left_top.x <= (sizeTiles + sizeMoat + this.chunk_size))) and
            ((chunkArea.left_top.y >= -(sizeTiles + sizeMoat + this.chunk_size)) and (chunkArea.left_top.y <= (sizeTiles + sizeMoat + this.chunk_size))))
    then
        -- Remove stuff
        Public.RemoveAliensInArea(surface, chunkArea)
        Public.RemoveInArea(surface, chunkArea, 'tree')
        Public.RemoveInArea(surface, chunkArea, 'resource')
        Public.RemoveInArea(surface, chunkArea, 'cliff')

        -- This loop runs through each tile
        local grassTiles = {}
        local waterTiles = {}
        for i = chunkArea.left_top.x, chunkArea.right_bottom.x, 1 do
            for j = chunkArea.left_top.y, chunkArea.right_bottom.y, 1 do
                -- Are we within the moat area?
                if ((i > -(sizeTiles + sizeMoat)) and (i < ((sizeTiles + sizeMoat) - 1)) and (j > -(sizeTiles + sizeMoat)) and (j < ((sizeTiles + sizeMoat) - 1))) then
                    -- Are we within the land area? Place land.
                    if ((i > -(sizeTiles)) and (i < ((sizeTiles) - 1)) and (j > -(sizeTiles)) and (j < ((sizeTiles) - 1))) then
                        -- Else, surround with water.
                        table_insert(grassTiles, { name = 'grass-1', position = { i, j } })
                    else
                        table_insert(waterTiles, { name = 'water', position = { i, j } })
                    end
                end
            end
        end
        surface.set_tiles(waterTiles)
        surface.set_tiles(grassTiles)
    end
end

--------------------------------------------------------------------------------
-- Town Funcs
--------------------------------------------------------------------------------

local town_radius = 27
local ore_amount = 1500

local town_wall_vectors = {}
for x = 2, town_radius, 1 do
    table_insert(town_wall_vectors, { x, town_radius })
    table_insert(town_wall_vectors, { x * -1, town_radius })
    table_insert(town_wall_vectors, { x, town_radius * -1 })
    table_insert(town_wall_vectors, { x * -1, town_radius * -1 })
end
for y = 2, town_radius - 1, 1 do
    table_insert(town_wall_vectors, { town_radius, y })
    table_insert(town_wall_vectors, { town_radius, y * -1 })
    table_insert(town_wall_vectors, { town_radius * -1, y })
    table_insert(town_wall_vectors, { town_radius * -1, y * -1 })
end

local gate_vectors_horizontal = {}
for x = -1, 1, 1 do
    table_insert(gate_vectors_horizontal, { x, town_radius })
    table_insert(gate_vectors_horizontal, { x, town_radius * -1 })
end
local gate_vectors_vertical = {}
for y = -1, 1, 1 do
    table_insert(gate_vectors_vertical, { town_radius, y })
    table_insert(gate_vectors_vertical, { town_radius * -1, y })
end

local resource_vectors = {}
resource_vectors[1] = {}
for x = 7, 24, 1 do
    for y = 7, 24, 1 do
        table_insert(resource_vectors[1], { x, y })
    end
end
resource_vectors[2] = {}
for _, vector in pairs(resource_vectors[1]) do
    table_insert(resource_vectors[2], { vector[1] * -1, vector[2] })
end
resource_vectors[3] = {}
for _, vector in pairs(resource_vectors[1]) do
    table_insert(resource_vectors[3], { vector[1] * -1, vector[2] * -1 })
end
resource_vectors[4] = {}
for _, vector in pairs(resource_vectors[1]) do
    table_insert(resource_vectors[4], { vector[1], vector[2] * -1 })
end

local additional_resource_vectors = {}
additional_resource_vectors[1] = {}
for x = 10, 22, 1 do
    for y = -4, 4, 1 do
        table_insert(additional_resource_vectors[1], { x, y })
    end
end
additional_resource_vectors[2] = {}
for _, vector in pairs(additional_resource_vectors[1]) do
    table_insert(additional_resource_vectors[2], { vector[1] * -1, vector[2] })
end
additional_resource_vectors[3] = {}
for y = 10, 22, 1 do
    for x = -4, 4, 1 do
        table_insert(additional_resource_vectors[3], { x, y })
    end
end
additional_resource_vectors[4] = {}
for _, vector in pairs(additional_resource_vectors[3]) do
    table_insert(additional_resource_vectors[4], { vector[1], vector[2] * -1 })
end

local clear_blacklist_types =
{
    ['simple-entity'] = true,
    ['resource'] = true,
    ['cliff'] = true
}

local starter_supplies =
{
    { name = 'raw-fish', count = 3 },
    { name = 'grenade', count = 3 },
    { name = 'stone', count = 32 },
    { name = 'land-mine', count = 4 },
    { name = 'iron-gear-wheel', count = 16 },
    { name = 'iron-plate', count = 32 },
    { name = 'copper-plate', count = 16 },
    { name = 'shotgun', count = 1 },
    { name = 'shotgun-shell', count = 8 },
    { name = 'firearm-magazine', count = 16 },
    { name = 'firearm-magazine', count = 16 },
    { name = 'gun-turret', count = 2 }
}

local function count_nearby_ore(surface, position, ore_name)
    local count = 0
    local r = town_radius + 8
    for _, e in pairs(surface.find_entities_filtered({ area = { { position.x - r, position.y - r }, { position.x + r, position.y + r } }, force = 'neutral', name = ore_name })) do
        count = count + e.amount
    end
    return count
end

local function create_market(player, position)
    local market_items = {}
    -- coin purchases
    table_insert(market_items,
        { price = { { name = 'coin', count = 1 } }, offer = { type = 'give-item', item = 'raw-fish', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'coin', count = 1 } }, offer = { type = 'give-item', item = 'wood', count = 6 } })
    table_insert(market_items,
        { price = { { name = 'coin', count = 1 } }, offer = { type = 'give-item', item = 'iron-ore', count = 6 } })
    table_insert(market_items,
        { price = { { name = 'coin', count = 1 } }, offer = { type = 'give-item', item = 'copper-ore', count = 6 } })
    table_insert(market_items,
        { price = { { name = 'coin', count = 1 } }, offer = { type = 'give-item', item = 'stone', count = 6 } })
    table_insert(market_items,
        { price = { { name = 'coin', count = 1 } }, offer = { type = 'give-item', item = 'coal', count = 6 } })
    table_insert(market_items,
        { price = { { name = 'coin', count = 1 } }, offer = { type = 'give-item', item = 'uranium-ore', count = 4 } })

    -- scrap selling
    table_insert(market_items,
        { price = { { name = 'raw-fish', count = 1 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'wood', count = 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'iron-ore', count = 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'copper-ore', count = 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'stone', count = 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'coal', count = 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'uranium-ore', count = 5 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'copper-cable', count = 12 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'iron-gear-wheel', count = 3 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'iron-stick', count = 12 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items,
        { price = { { name = 'barrel', count = 1 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })

    local market = player.surface.create_entity({ name = 'market', position = position, force = player.force })

    for _, item in pairs(market_items) do
        market.add_market_item(item)
    end
end

Public.create_market = create_market

local function draw_town_spawn(player, position)
    local force = player.force
    local surface = player.surface

    local area = { { position.x - (town_radius + 1), position.y - (town_radius + 1) }, { position.x + (town_radius + 1), position.y + (town_radius + 1) } }

    -- for _, t in pairs(surface.find_tiles_filtered({area = area, name = {'water', 'deepwater'}})) do
    --     surface.set_tiles({{name = get_replacement_tile(surface, t.position), position = t.position}})
    -- end

    for _, t in pairs(surface.find_tiles_filtered({ area = area })) do
        surface.set_tiles({ { name = 'tutorial-grid', position = t.position } })
    end

    for _, e in pairs(surface.find_entities_filtered({ area = area, force = 'neutral' })) do
        if not clear_blacklist_types[e.type] then
            e.destroy()
        end
    end

    for _, vector in pairs(gate_vectors_horizontal) do
        local p = { position.x + vector[1], position.y + vector[2] }
        p = surface.find_non_colliding_position('gate', p, 64, 1)
        if p then
            surface.create_entity({ name = 'gate', position = p, force = force, direction = 2 })
        end
    end
    for _, vector in pairs(gate_vectors_vertical) do
        local p = { position.x + vector[1], position.y + vector[2] }
        p = surface.find_non_colliding_position('gate', p, 64, 1)
        if p then
            surface.create_entity({ name = 'gate', position = p, force = force, direction = 0 })
        end
    end

    for _, vector in pairs(town_wall_vectors) do
        local p = { position.x + vector[1], position.y + vector[2] }
        p = surface.find_non_colliding_position('stone-wall', p, 64, 1)
        if p then
            surface.create_entity({ name = 'stone-wall', position = p, force = force })
        end
    end

    local ores = { 'iron-ore', 'copper-ore', 'stone', 'coal' }
    table.shuffle_table(ores)

    for i = 1, 4, 1 do
        if count_nearby_ore(surface, position, ores[i]) < 200000 then
            for _, vector in pairs(resource_vectors[i]) do
                local p = { position.x + vector[1], position.y + vector[2] }
                p = surface.find_non_colliding_position(ores[i], p, 64, 1)
                if p then
                    surface.create_entity({ name = ores[i], position = p, amount = ore_amount })
                end
            end
        end
    end

    for _, item_stack in pairs(starter_supplies) do
        local m1 = -8 + random(0, 16)
        local m2 = -8 + random(0, 16)
        local p = { position.x + m1, position.y + m2 }
        p = surface.find_non_colliding_position('wooden-chest', p, 64, 1)
        if p then
            local e = surface.create_entity({ name = 'wooden-chest', position = p, force = force })
            local inventory = e.get_inventory(defines.inventory.chest)
            inventory.insert(item_stack)
        end
    end

    local vector_indexes = { 1, 2, 3, 4 }
    table.shuffle_table(vector_indexes)

    local tree = 'tree-0' .. random(1, 9)
    for _, vector in pairs(additional_resource_vectors[vector_indexes[1]]) do
        if random(1, 6) == 1 then
            local p = { position.x + vector[1], position.y + vector[2] }
            p = surface.find_non_colliding_position(tree, p, 64, 1)
            if p then
                surface.create_entity({ name = tree, position = p })
            end
        end
    end

    local market_pos
    local map_area = { { position.x - town_radius * 1.5, position.y - town_radius * 1.5 }, { position.x + town_radius * 1.5, position.y + town_radius * 1.5 } }
    if surface.count_tiles_filtered({ name = { 'water', 'deepwater' }, area = map_area }) < 8 then
        for _, vector in pairs(additional_resource_vectors[vector_indexes[2]]) do
            local p = { position.x + vector[1], position.y + vector[2] }
            market_pos = p
            if surface.get_tile(p).name ~= 'out-of-map' then
                surface.set_tiles({ { name = 'water', position = p } })
            end
        end
    end
    create_market(player, market_pos)

    if count_nearby_ore(surface, position, 'uranium-ore') < 100000 then
        for _, vector in pairs(additional_resource_vectors[vector_indexes[3]]) do
            local p = { position.x + vector[1], position.y + vector[2] }
            p = surface.find_non_colliding_position('uranium-ore', p, 64, 1)
            if p then
                surface.create_entity({ name = 'uranium-ore', position = p, amount = ore_amount * 2 })
            end
        end
    end
    local vectors = additional_resource_vectors[vector_indexes[4]]
    for _ = 1, 3, 1 do
        local vector = vectors[random(1, #vectors)]
        local p = { position.x + vector[1], position.y + vector[2] }
        p = surface.find_non_colliding_position('crude-oil', p, 64, 1)
        if p then
            surface.create_entity({ name = 'crude-oil', position = p, amount = 500000 })
        end
    end
end

local function draw_town_spawn_new(player, position)
    local force = player.force
    local surface = player.surface

    local area = { { position.x - (town_radius), position.y - (town_radius) }, { position.x + (town_radius), position.y + (town_radius) } }

    -- remove other than cliffs, rocks and ores and trees
    --for _, e in pairs(surface.find_entities_filtered({area = area, force = 'neutral'})) do
    --    if not clear_whitelist_types[e.type] then
    --        e.destroy()
    --    end
    --end

    -- for _, t in pairs(surface.find_tiles_filtered({area = area, name = {'water', 'deepwater'}})) do
    --     surface.set_tiles({{name = get_replacement_tile(surface, t.position), position = t.position}})
    -- end

    for _, t in pairs(surface.find_tiles_filtered({ area = area })) do
        surface.set_tiles({ { name = 'tutorial-grid', position = t.position } })
    end

    surface.destroy_decoratives { area = area }

    -- create walls
    for _, vector in pairs(gate_vectors_horizontal) do
        local p = { position.x + vector[1], position.y + vector[2] }
        --p = surface.find_non_colliding_position("gate", p, 64, 1)
        if p then
            surface.create_entity({ name = 'gate', position = p, force = force, direction = 4 })
        end
    end
    for _, vector in pairs(gate_vectors_vertical) do
        local p = { position.x + vector[1], position.y + vector[2] }
        --p = surface.find_non_colliding_position("gate", p, 64, 1)
        if p then
            surface.create_entity({ name = 'gate', position = p, force = force, direction = 0 })
        end
    end

    for _, vector in pairs(town_wall_vectors) do
        local p = { position.x + vector[1], position.y + vector[2] }
        --p = surface.find_non_colliding_position("stone-wall", p, 64, 1)
        if p then
            surface.create_entity({ name = 'stone-wall', position = p, force = force })
        end
    end

    -- ore patches
    --[[ local ores = {'iron-ore', 'copper-ore', 'stone', 'coal'}
    table.shuffle_table(ores)

    for i = 1, 4, 1 do
        if count_nearby_ore(surface, position, ores[i]) < 200000 then
            for _, vector in pairs(resource_vectors[i]) do
                local p = {position.x + vector[1], position.y + vector[2]}
                p = surface.find_non_colliding_position(ores[i], p, 64, 1)
                if p then
                    surface.create_entity({name = ores[i], position = p, amount = ore_amount})
                end
            end
        end
    end ]]
    local scenario_config = MT.get('scenario_config')

    local rad = {}
    for k, _ in pairs(scenario_config.resource_tiles_town) do
        if (k ~= '') then
            table.insert(rad, k)
        end
    end
    table.shuffle_table(rad)

    local count

    if SessionData.allowed(player, 'bonus-ore-x4') then
        count = 4
    elseif SessionData.allowed(player, 'bonus-ore-x3') then
        count = 3
    elseif SessionData.allowed(player, 'bonus-ore-x2') then
        count = 2
    else
        count = 1
    end

    local i = 0
    for _, name in pairs(rad) do
        local amount = scenario_config.resource_tiles_town[name]
        i = i + 1
        for _, vector in pairs(resource_vectors[i]) do
            local p = { position.x + vector[1], position.y + vector[2] }
            p = surface.find_non_colliding_position(name, p, 64, 1)
            if p then
                if count and count >= 2 then
                    surface.create_entity({ name = name, position = p, amount = amount * count })
                else
                    surface.create_entity({ name = name, position = p, amount = random(amount * 0.9, amount) })
                end
            end
        end
    end

    local town_only_layout = MT.get('town_only_layout')

    if town_only_layout then
        -- starter chests
        for _, item_stack in pairs(starter_supplies) do
            local m1 = -8 + random(0, 16)
            local m2 = -8 + random(0, 16)
            local p = { position.x + m1, position.y + m2 }
            p = surface.find_non_colliding_position('wooden-chest', p, 64, 1)
            if p then
                local e = surface.create_entity({ name = 'iron-chest', position = p, force = force })
                local inventory = e.get_inventory(defines.inventory.chest)
                inventory.insert(item_stack)
            end
        end
    end

    local vector_indexes = { 1, 2, 3, 4 }
    table.shuffle_table(vector_indexes)

    -- trees
    local car_pos

    local tree = 'tree-0' .. random(1, 9)
    for _, vector in pairs(additional_resource_vectors[vector_indexes[1]]) do
        if random(1, 6) == 1 then
            local p = { position.x + vector[1], position.y + vector[2] }
            p = surface.find_non_colliding_position(tree, p, 64, 1)
            car_pos = p

            if p then
                surface.create_entity({ name = tree, position = p })
            end
        end
    end
    if car_pos then
        local hidden_dimension_enabled = MT.get('hidden_dimension_enabled')
        if SessionData.allowed(player, 'personal_hidden_dimension') and hidden_dimension_enabled then
            HD.create(player, car_pos)
        end
    end

    --local area = {{position.x - town_radius * 1.5, position.y - town_radius * 1.5}, {position.x + town_radius * 1.5, position.y + town_radius * 1.5}}

    -- pond
    local market_pos
    for _, vector in pairs(additional_resource_vectors[vector_indexes[2]]) do
        local x = position.x + vector[1]
        local y = position.y + vector[2]
        local p = { x = x, y = y }
        market_pos = p
        if surface.get_tile(p).name ~= 'out-of-map' then
            surface.set_tiles({ { name = 'water-shallow', position = p } })
        end
    end

    create_market(player, market_pos)

    -- fish
    for _, vector in pairs(additional_resource_vectors[vector_indexes[2]]) do
        local x = position.x + vector[1] + 0.5
        local y = position.y + vector[2] + 0.5
        local p = { x = x, y = y }
        if random(1, 5) == 1 then
            if surface.can_place_entity({ name = 'fish', position = p }) then
                surface.create_entity({ name = 'water-splash', position = p })
                surface.create_entity({ name = 'fish', position = p })
            end
        end
    end

    -- uranium ore
    --if count_nearby_ore(surface, position, "uranium-ore") < 100000 then
    --	for _, vector in pairs(additional_resource_vectors[vector_indexes[3]]) do
    --		local p = {position.x + vector[1], position.y + vector[2]}
    --		p = surface.find_non_colliding_position("uranium-ore", p, 64, 1)
    --		if p then
    --			surface.create_entity({name = "uranium-ore", position = p, amount = ore_amount * 2})
    --		end
    --	end
    --end

    -- oil patches
    --local vectors = additional_resource_vectors[vector_indexes[4]]
    --for _ = 1, 3, 1 do
    --	local vector = vectors[random(1, #vectors)]
    --	local p = {position.x + vector[1], position.y + vector[2]}
    --	p = surface.find_non_colliding_position("crude-oil", p, 64, 1)
    --	if p then
    --		surface.create_entity({name = "crude-oil", position = p, amount = 500000})
    --	end
    --end
end

function Public.get_owner_of_town(town_name, callback)
    local towns = MT.get('towns')
    for _, town in pairs(towns) do
        if town_name == town.force then
            local force = game.forces[town_name]
            if force then
                callback(town, force)
            end
        end
    end
end

function Public.get_towns(callback)
    local towns = MT.get('towns')
    for _, town in pairs(towns) do
        callback(town)
    end
end

function Public.get_size_of_town(town_name)
    local count = 1
    local towns = MT.get('towns')
    for _, town in pairs(towns) do
        if town_name == town.force then
            count = count + 1
        end
    end
    return count
end

function Public.create_town_in_tbl(player, position)
    local towns = MT.get('towns')
    local main_force_name = MT.get('main_force_name')
    local surface_name = Surface.get_surface_name()

    local main_surface = game.get_surface(surface_name)

    if not main_surface or not main_surface.valid then
        return
    end

    if not towns[main_force_name] then
        towns[main_force_name] =
        {
            position = { x = 0, y = 0 },
            surface = main_surface.index,
            force = main_force_name,
            owner = main_force_name,
            evolution =
            {
                biters = 0,
                spitters = 0,
                worms = 0
            },
            creation_tick = game.tick
        }
    end

    if player and player.valid then
        towns[player.name] =
        {
            position = position,
            surface = main_surface.index,
            force = player.force.name,
            owner = player.name,
            evolution =
            {
                biters = 0,
                spitters = 0,
                worms = 0
            },
            creation_tick = game.tick
        }
    end
end

function Public.create_new_town(player, position, new)
    if not player then
        return
    end

    Public.create_town_in_tbl(player, position)

    if new then
        draw_town_spawn_new(player, position)
    else
        draw_town_spawn(player, position)
    end

    return true
end

--------------------------------------------------------------------------------
-- Misc functions
--------------------------------------------------------------------------------

function Public.recreate_fishes()
    local towns = MT.get('towns')
    for _, town in pairs(towns) do
        local surface_index = town.surface
        local surface = game.get_surface(surface_index)
        if not surface or not surface.valid then
            return
        end

        local position = town.position
        local fishes = surface.find_entities_filtered({ name = 'fish', position = position, radius = 27 })
        if #fishes == 0 then
            return
        end
        if #fishes >= 128 then
            return
        end

        local t = random(1, #fishes)
        local fish = fishes[t]
        local guppy = false
        for i, f in pairs(fishes) do
            if i ~= t then
                if floor(fish.position.x) == floor(f.position.x) and floor(fish.position.y) == floor(f.position.y) then
                    guppy = true
                end
            end
        end
        if guppy == true then
            surface.create_entity({ name = 'water-splash', position = fish.position })
            surface.create_entity({ name = 'fish', position = fish.position })
        end
    end
end

--------------------------------------------------------------------------------
-- EVENT SPECIFIC FUNCTIONS
--------------------------------------------------------------------------------

-- Display messages to a user everytime they join
function Public.PlayerJoinedMessages(event)
    local player = game.players[event.player_index]
    local welcome_msg = MT.get('welcome_msg')
    player.print(welcome_msg)
end

-- Remove decor to save on file size
function Public.UndecorateOnChunkGenerate(event)
    local surface = event.surface
    local chunkArea = event.area
    Public.RemoveDecorationsArea(surface, chunkArea)
    -- Public.RemoveFish(surface, chunkArea)
end

-- Give player items on respawn
-- Intended to be the default behavior when not using separate spawns
function Public.PlayerRespawnItems(event)
    Public.GivePlayerItems(game.players[event.player_index])
end

-- Map loaders to logistics tech for unlocks.
local loaders_technology_map =
{
    ['logistics'] = 'loader',
    ['logistics-2'] = 'fast-loader',
    ['logistics-3'] = 'express-loader'
}

function Public.EnableLoaders(event)
    local research = event.research
    local recipe = loaders_technology_map[research.name]
    if recipe then
        research.force.recipes[recipe].enabled = true
    end
end

return Public
