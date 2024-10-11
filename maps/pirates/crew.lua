-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Event = require("utils.event")
local Balance = require("maps.pirates.balance")
local _inspect = require("utils.inspect").inspect
local Memory = require("maps.pirates.memory")
local Math = require("maps.pirates.math")
local Common = require("maps.pirates.common")
-- local Parrot = require 'maps.pirates.parrot'
local CoreData = require("maps.pirates.coredata")
local Server = require("utils.server")
local Utils = require("maps.pirates.utils_local")
local Surfaces = require("maps.pirates.surfaces.surfaces")
local Islands = require("maps.pirates.surfaces.islands.islands")
local IslandEnum = require("maps.pirates.surfaces.islands.island_enum")
-- local Structures = require 'maps.pirates.structures.structures'
local Boats = require("maps.pirates.structures.boats.boats")
local Crowsnest = require("maps.pirates.surfaces.crowsnest")
local Hold = require("maps.pirates.surfaces.hold")
local Lobby = require("maps.pirates.surfaces.lobby")
local Cabin = require("maps.pirates.surfaces.cabin")
local Roles = require("maps.pirates.roles.roles")
local Classes = require("maps.pirates.roles.classes")
local Token = require("utils.token")
local Task = require("utils.task")
local SurfacesCommon = require("maps.pirates.surfaces.common")
local BottomFrame = require("utils.gui.bottom_frame")

local Public = {}
local enum = {
    ADVENTURING = "adventuring",
    LEAVING_INITIAL_DOCK = "leavinginitialdock",
}
Public.enum = enum

function Public.difficulty_vote(player_index, difficulty_id)
    local memory = Memory.get_crew_memory()

    if not memory.difficulty_votes then
        memory.difficulty_votes = {}
    end
    local player = game.players[player_index]
    if not (player and player.valid) then
        return
    end

    if memory.difficulty_votes[player_index] and memory.difficulty_votes[player_index] == difficulty_id then
        return nil
    else
        local option = CoreData.difficulty_options[difficulty_id]
        if not option then
            return
        end

        local color = option.associated_color
        Common.notify_force(
            memory.force,
            { "pirates.notify_difficulty_vote", player.name, color.r, color.g, color.b, option.text }
        )

        memory.difficulty_votes[player_index] = difficulty_id

        Public.update_difficulty()
    end
end

function Public.update_difficulty()
    local memory = Memory.get_crew_memory()

    local vote_counts = {}
    for _, difficulty_id in pairs(memory.difficulty_votes) do
        if not vote_counts[difficulty_id] then
            vote_counts[difficulty_id] = 1
        else
            vote_counts[difficulty_id] = vote_counts[difficulty_id] + 1
        end
    end

    local modal_id = 1
    local modal_count = 0
    for difficulty_id, votes in pairs(vote_counts) do
        if votes > modal_count or (votes == modal_count and difficulty_id < modal_id) then
            modal_count = votes
            modal_id = difficulty_id
        end
    end

    if modal_id ~= memory.difficulty_option then
        local color = CoreData.difficulty_options[modal_id].associated_color

        local message1 = {
            "pirates.notify_difficulty_change",
            color.r,
            color.g,
            color.b,
            CoreData.difficulty_options[modal_id].text,
        }

        Common.notify_force(memory.force, message1)

        -- local message2 = 'Difficulty changed to ' .. CoreData.difficulty_options[modal_id].text .. '.'

        -- why print this? if enabling it again, print message to discord without [color] tags (they don't work there)
        -- Server.to_discord_embed_raw({'', CoreData.comfy_emojis.kewl .. '[' .. memory.name .. '] ', message1}, true)

        memory.difficulty_option = modal_id
        memory.difficulty = CoreData.difficulty_options[modal_id].value

        Cabin.update_captains_market_offers_based_on_difficulty(memory.difficulty_option)
    end
end

function Public.try_add_extra_time_at_sea(ticks)
    local memory = Memory.get_crew_memory()

    if not memory.extra_time_at_sea then
        memory.extra_time_at_sea = 0
    end

    if memory.extra_time_at_sea >= CoreData.max_extra_seconds_at_sea * 60 then
        return false
    end

    -- if memory.boat and memory.boat.state and memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP then return false end

    memory.extra_time_at_sea = memory.extra_time_at_sea + ticks
    return true
end

function Public.get_crewmembers_printable_string()
    local crewmembers_string = ""
    for _, player in pairs(Common.crew_get_crew_members()) do
        if player.valid then
            if crewmembers_string ~= "" then
                crewmembers_string = crewmembers_string .. ", "
            end
            crewmembers_string = crewmembers_string .. player.name
        end
    end
    if crewmembers_string ~= "" then
        crewmembers_string = crewmembers_string .. "."
    end

    return crewmembers_string
end

function Public.try_lose(loss_reason)
    local memory = Memory.get_crew_memory()

    if not memory.game_lost then
        -- if (not memory.game_lost) and (not memory.game_won) then
        memory.game_lost = true
        memory.crew_disband_tick_message = game.tick + 60 * 10
        memory.crew_disband_tick = game.tick + 60 * 40
        memory.crew_disband_tick_cannot_be_prevented = true

        local playtimetext = Utils.time_longform((memory.age or 0) / 60)

        local message = {
            "",
            loss_reason,
            " ",
            {
                "pirates.loss_rest_of_message_long",
                playtimetext,
                memory.overworldx,
                Public.get_crewmembers_printable_string(),
            },
        }

        Server.to_discord_embed_raw({ "", CoreData.comfy_emojis.trashbin .. "[" .. memory.name .. "] ", message }, true)

        local message2 = {
            "",
            loss_reason,
            " ",
            {
                "pirates.loss_rest_of_message_short",
                "[font=default-large-semibold]" .. playtimetext .. "[/font]",
                memory.overworldx,
            },
        }

        Common.notify_game({ "", "[" .. memory.name .. "] ", message2 }, CoreData.colors.notify_gameover)

        local force = memory.force
        if not (force and force.valid) then
            return
        end

        force.play_sound({ path = "utility/game_lost", volume_modifier = 0.75 }) --playing to the whole game might scare ppl
    end
end

function Public.try_win()
    local memory = Memory.get_crew_memory()

    if not (memory.game_lost or memory.game_won) then
        -- if (not memory.game_lost) and (not memory.game_won) then
        memory.completion_time = Math.floor((memory.age or 0) / 60)

        local speedrun_time = (memory.age or 0) / 60
        local speedrun_time_str = Utils.time_longform(speedrun_time)
        memory.game_won = true
        -- memory.crew_disband_tick = game.tick + 1200

        Server.to_discord_embed_raw({
            "",
            CoreData.comfy_emojis.goldenobese
                .. "["
                .. memory.name
                .. "] Victory, on v"
                .. CoreData.version_string
                .. ", ",
            CoreData.difficulty_options[memory.difficulty_option].text,
            ", capacity "
                .. CoreData.capacity_options[memory.capacity_option].text3
                .. ". Playtime: "
                .. speedrun_time_str
                .. " since 1st island. Crewmembers: "
                .. Public.get_crewmembers_printable_string(),
        }, true)

        Common.notify_game({
            "",
            "[" .. memory.name .. "] ",
            {
                "pirates.victory",
                CoreData.version_string,
                CoreData.difficulty_options[memory.difficulty_option].text,
                CoreData.capacity_options[memory.capacity_option].text3,
                speedrun_time_str,
                Public.get_crewmembers_printable_string(),
            },
        }, CoreData.colors.notify_victory)

        game.play_sound({ path = "utility/game_won", volume_modifier = 0.9 })

        memory.boat.state = Boats.enum_state.ATSEA_VICTORIOUS
        memory.victory_continue_reminder = game.tick + 60 * 14
        memory.victory_continue_message = true
    end
end

function Public.choose_crew_members()
    -- local global_memory = Memory.get_global_memory()
    local memory = Memory.get_crew_memory()
    local capacity = memory.capacity
    local boat = memory.boat

    local crew_members = {}
    local crew_members_count = 0

    if crew_members_count < capacity then
        for _, player in pairs(game.connected_players) do
            if
                crew_members_count < capacity
                and not crew_members[player.index]
                and player.surface.name == CoreData.lobby_surface_name
                and Boats.on_boat(boat, player.position)
            then
                crew_members[player.index] = player
                crew_members_count = crew_members_count + 1
            end
        end
    end

    for _, player in pairs(crew_members) do
        player.force = memory.force
        memory.crewplayerindices[#memory.crewplayerindices + 1] = player.index
    end

    return crew_members
end

function Public.join_spectators(player, crewid)
    if crewid == 0 then
        return
    end

    Memory.set_working_id(crewid)
    local memory = Memory.get_crew_memory()

    local force = memory.force
    if not (force and force.valid and Common.validate_player(player)) then
        return
    end

    local surface = game.surfaces[CoreData.lobby_surface_name]

    local adventuring = false
    local spectating = false
    if memory.crewstatus and memory.crewstatus == enum.ADVENTURING then
        for _, playerindex in pairs(memory.crewplayerindices) do
            if player.index == playerindex then
                adventuring = true
            end
        end
        for _, playerindex in pairs(memory.spectatorplayerindices) do
            if player.index == playerindex then
                spectating = true
            end
        end
    end

    if spectating then
        return
    end

    if adventuring then
        local char = player.character

        if char and char.valid then
            local p = char.position
            -- local surface_name = char.surface.name
            if p then
                Common.notify_force(force, { "pirates.crew_to_spectator", player.name })
                -- Server.to_discord_embed_raw(CoreData.comfy_emojis.feel .. '[' .. memory.name .. '] ' .. message)
            end
            -- if p then
            -- 	Common.notify_force(force, message .. ' to become a spectator.' .. ' [gps=' .. Math.ceil(p.x) .. ',' .. Math.ceil(p.y) .. ',' .. surface_name ..']')
            -- 	-- Server.to_discord_embed_raw(CoreData.comfy_emojis.feel .. '[' .. memory.name .. '] ' .. message)
            -- end

            local player_surface_type = SurfacesCommon.decode_surface_name(player.surface.name).type
            local boat_surface_type = SurfacesCommon.decode_surface_name(memory.boat.surface_name).type

            if not memory.temporarily_logged_off_player_data then
                memory.temporarily_logged_off_player_data = {}
            end

            memory.temporarily_logged_off_player_data[player.index] = {
                on_island = (player_surface_type == Surfaces.enum.ISLAND),
                on_boat = (player_surface_type == boat_surface_type)
                    and Boats.on_boat(memory.boat, player.character.position),
                surface_name = player.surface.name,
                position = player.character.position,
                tick = game.tick,
            }

            Common.temporarily_store_logged_off_character_items(player)

            char.die(memory.force_name)

            player.set_controller({ type = defines.controllers.spectator })
        else
            Common.notify_force(force, { "pirates.crew_to_spectator", player.name })
            -- Server.to_discord_embed_raw(CoreData.comfy_emojis.feel .. '[' .. memory.name .. '] ' .. message)
            player.set_controller({ type = defines.controllers.spectator })
        end

        local c = surface.create_entity({
            name = "character",
            position = surface.find_non_colliding_position("character", Common.lobby_spawnpoint, 32, 0.5)
                or Common.lobby_spawnpoint,
            force = Common.lobby_force_name,
        })

        player.associate_character(c)

        player.set_controller({ type = defines.controllers.spectator })

        memory.crewplayerindices = Utils.ordered_table_with_values_removed(memory.crewplayerindices, player.index)

        Roles.player_left_so_redestribute_roles(player)
    else
        local c = player.character
        player.set_controller({ type = defines.controllers.spectator })
        player.teleport(memory.spawnpoint, game.surfaces[memory.boat.surface_name])
        player.force = force
        player.associate_character(c)

        Common.notify_force(force, { "pirates.lobby_to_spectator", player.name })
        Common.notify_lobby({ "pirates.lobby_to_spectator_2", player.name, memory.name })
    end

    memory.spectatorplayerindices[#memory.spectatorplayerindices + 1] = player.index

    if not _DEBUG then
        memory.tempbanned_from_joining_data[player.index] = game.tick
    end

    if #Common.crew_get_crew_members() == 0 then
        local exists_disband_tick = memory.crew_disband_tick and memory.crew_disband_tick > game.tick

        if Common.autodisband_hours and not exists_disband_tick and Server.get_current_time() then
            memory.crew_disband_tick = game.tick + Common.autodisband_hours * 60 * 60 * 60
        end
    end

    if not memory.difficulty_votes then
        memory.difficulty_votes = {}
    end
    memory.difficulty_votes[player.index] = nil
end

function Public.leave_spectators(player, quiet)
    quiet = quiet or false
    local memory = Memory.get_crew_memory()
    local surface = game.surfaces[CoreData.lobby_surface_name]

    if not Common.validate_player(player) then
        return
    end

    if not quiet then
        Common.notify_force(player.force, { "pirates.spectator_to_lobby", player.name })
    end

    local chars = player.get_associated_characters()
    if #chars > 0 then
        player.teleport(chars[1].position, surface)
        player.set_controller({ type = defines.controllers.character, character = chars[1] })
    else
        player.set_controller({ type = defines.controllers.god })
        player.teleport(
            surface.find_non_colliding_position("character", Common.lobby_spawnpoint, 32, 0.5)
                or Common.lobby_spawnpoint,
            surface
        )
        player.create_character()
    end

    memory.spectatorplayerindices = Utils.ordered_table_with_values_removed(memory.spectatorplayerindices, player.index)

    if #Common.crew_get_crew_members() == 0 then
        local exists_disband_tick = memory.crew_disband_tick and memory.crew_disband_tick > game.tick

        if Common.autodisband_hours and not exists_disband_tick and Server.get_current_time() then
            memory.crew_disband_tick = game.tick + Common.autodisband_hours * 60 * 60 * 60
        end
    end

    player.force = Common.lobby_force_name
end

function Public.join_crew(player, rejoin)
    local memory = Memory.get_crew_memory()

    if not Common.validate_player(player) then
        return
    end

    -- local startsurface = game.surfaces[CoreData.lobby_surface_name]

    local boat = memory.boat
    local surface
    if boat and boat.surface_name and game.surfaces[boat.surface_name] and game.surfaces[boat.surface_name].valid then
        surface = game.surfaces[boat.surface_name]
    else
        surface = game.surfaces[Common.current_destination().surface_name]
    end

    -- local adventuring = false
    local spectating = false
    if memory.crewstatus == enum.ADVENTURING then
        -- for _, playerindex in pairs(memory.crewplayerindices) do
        -- 	if player.index == playerindex then adventuring = true end
        -- end
        for _, playerindex in pairs(memory.spectatorplayerindices) do
            if player.index == playerindex then
                spectating = true
            end
        end
    end

    if spectating then
        local chars = player.get_associated_characters()
        for _, char in pairs(chars) do
            char.destroy()
        end

        player.teleport(
            surface.find_non_colliding_position("character", memory.spawnpoint, 32, 0.5) or memory.spawnpoint,
            surface
        )

        player.set_controller({ type = defines.controllers.god })
        player.create_character()

        memory.spectatorplayerindices =
            Utils.ordered_table_with_values_removed(memory.spectatorplayerindices, player.index)
    else
        if not (player.character and player.character.valid) then
            player.set_controller({ type = defines.controllers.god })
            player.create_character()
        end

        player.force = memory.force

        Common.notify_lobby({ "pirates.lobby_to_crew_2", player.name, memory.name })

        player.teleport(
            surface.find_non_colliding_position("character", memory.spawnpoint, 32, 0.5) or memory.spawnpoint,
            surface
        )

        if rejoin then
            if memory.temporarily_logged_off_player_data[player.index] then
                local rejoin_data = memory.temporarily_logged_off_player_data[player.index]
                local rejoin_surface = game.surfaces[rejoin_data.surface_name]

                -- If surface where player left the game still exists, place him there.
                if rejoin_surface and rejoin_surface.valid then
                    -- Edge case: if player left the game while he was on the boat, it could be that boat position
                    -- changed when he left the game vs when he came back.
                    if not (rejoin_data.on_boat and rejoin_data.on_island) then
                        player.teleport(
                            rejoin_surface.find_non_colliding_position("character", rejoin_data.position, 32, 0.5)
                                or memory.spawnpoint,
                            rejoin_surface
                        )
                    end
                end

                Common.give_back_items_to_temporarily_logged_off_player(player)

                memory.temporarily_logged_off_player_data[player.index] = nil
            end
        end
    end

    Common.notify_force(player.force, { "pirates.lobby_to_crew", player.name })
    -- Server.to_discord_embed_raw(CoreData.comfy_emojis.yum1 .. '[' .. memory.name .. '] ' .. message)

    memory.crewplayerindices[#memory.crewplayerindices + 1] = player.index

    -- don't give them items if they've been in the crew recently
    -- just using tempbanned_from_joining_data as a quick proxy for whether the player has ever been in this run before
    if
        not (memory.tempbanned_from_joining_data and memory.tempbanned_from_joining_data[player.index]) and not rejoin
    then
        for item, amount in pairs(Balance.starting_items_player_late) do
            player.insert({ name = item, count = amount })
        end
    end

    if (not memory.run_is_protected) or Common.is_officer(player.index) then
        Roles.confirm_captain_exists(player)
    end

    if
        #Common.crew_get_crew_members() == 1
        and memory.crew_disband_tick
        and not memory.crew_disband_tick_cannot_be_prevented
    then
        memory.crew_disband_tick = nil
    end

    if memory.overworldx > 0 then
        local color = CoreData.difficulty_options[memory.difficulty_option].associated_color

        Common.notify_player_announce(player, {
            "pirates.personal_join_string_1",
            memory.name,
            CoreData.capacity_options[memory.capacity_option].text3,
            color.r,
            color.g,
            color.b,
            CoreData.difficulty_options[memory.difficulty_option].text,
        })
    else
        Common.notify_player_announce(
            player,
            { "pirates.personal_join_string_1", memory.name, CoreData.capacity_options[memory.capacity_option].text3 }
        )
    end
end

function Public.leave_crew(player, to_lobby, quiet)
    quiet = quiet or false
    local memory = Memory.get_crew_memory()
    local surface = game.surfaces[CoreData.lobby_surface_name]

    if not Common.validate_player(player) then
        return
    end

    local char = player.character
    if char and char.valid then
        -- local p = char.position
        -- local surface_name = char.surface.name
        if not quiet then
            Common.notify_force(player.force, { "pirates.crew_leave", player.name })
            -- else
            -- 	message = player.name .. ' left.'
        end
        -- if p then
        -- 	Common.notify_force(player.force, message .. ' [gps=' .. Math.ceil(p.x) .. ',' .. Math.ceil(p.y) .. ',' .. surface_name ..']')
        -- 	-- Server.to_discord_embed_raw(CoreData.comfy_emojis.feel .. '[' .. memory.name .. '] ' .. message)
        -- end

        local player_surface_type = SurfacesCommon.decode_surface_name(player.surface.name).type
        local boat_surface_type = SurfacesCommon.decode_surface_name(memory.boat.surface_name).type

        -- @TODO: figure out why surface_name can be nil

        if not memory.temporarily_logged_off_player_data then
            memory.temporarily_logged_off_player_data = {}
        end

        memory.temporarily_logged_off_player_data[player.index] = {
            on_island = (player_surface_type == Surfaces.enum.ISLAND),
            on_boat = (player_surface_type == boat_surface_type)
                and Boats.on_boat(memory.boat, player.character.position),
            surface_name = player.surface.name,
            position = player.character.position,
            tick = game.tick,
        }

        Common.temporarily_store_logged_off_character_items(player)

        char.die(memory.force_name)

        -- else
        -- 	if not quiet then
        -- 		-- local message = player.name .. ' left the crew.'
        -- 		-- Common.notify_force(player.force, message)
        -- 	end
    end

    if to_lobby then
        player.set_controller({ type = defines.controllers.god })

        player.teleport(
            surface.find_non_colliding_position("character", Common.lobby_spawnpoint, 32, 0.5)
                or Common.lobby_spawnpoint,
            surface
        )
        player.force = Common.lobby_force_name
        player.create_character()
        Event.raise(BottomFrame.events.bottom_quickbar_respawn_raise, { player_index = player.index })
    end

    memory.crewplayerindices = Utils.ordered_table_with_values_removed(memory.crewplayerindices, player.index)

    -- setting it to this won't ban them from rejoining, it just affects the loot they spawn in with:
    memory.tempbanned_from_joining_data[player.index] = game.tick - Common.ban_from_rejoining_crew_ticks

    if not memory.difficulty_votes then
        memory.difficulty_votes = {}
    end
    memory.difficulty_votes[player.index] = nil

    Roles.player_left_so_redestribute_roles(player)

    if #Common.crew_get_crew_members() == 0 then
        local exists_disband_tick = memory.crew_disband_tick and memory.crew_disband_tick > game.tick

        if Common.autodisband_hours and not exists_disband_tick and Server.get_current_time() then
            memory.crew_disband_tick = game.tick + Common.autodisband_hours * 60 * 60 * 60
        end

        -- if _DEBUG then memory.crew_disband_tick = game.tick + 30*60*60 end
    end
end

function Public.get_unaffiliated_players()
    local global_memory = Memory.get_global_memory()

    local playerlist = {}
    for _, player in pairs(game.connected_players) do
        local found = false
        for _, id in pairs(global_memory.crew_active_ids) do
            Memory.set_working_id(id)
            for _, player2 in pairs(Common.crew_get_crew_members_and_spectators()) do
                if player == player2 then
                    found = true
                end
            end
        end
        if not found then
            playerlist[#playerlist + 1] = player
        end
    end
    return playerlist
end

function Public.plank(captain, player)
    local memory = Memory.get_crew_memory()

    if Utils.contains(Common.crew_get_crew_members(), player) then
        if captain.index ~= player.index then
            Server.to_discord_embed_raw(
                CoreData.comfy_emojis.despair .. string.format("%s planked %s!", captain.name, player.name)
            )

            Common.notify_force(player.force, { "pirates.plank", captain.name, player.name })

            Public.join_spectators(player, memory.id)
            memory.tempbanned_from_joining_data[player.index] = game.tick + 60 * 120
            return true
        else
            Common.notify_player_error(player, { "pirates.plank_error_self" })
            return false
        end
    else
        Common.notify_player_error(player, { "pirates.plank_error_invalid_player" })
        return false
    end
end

function Public.disband_crew(donotprint)
    local global_memory = Memory.get_global_memory()
    local memory = Memory.get_crew_memory()

    if not memory.name then
        return
    end

    local id = memory.id
    local players = Common.crew_get_crew_members_and_spectators()

    for _, player in pairs(players) do
        if player.controller_type == defines.controllers.editor then
            player.toggle_map_editor()
        end
        player.force = Common.lobby_force_name
    end

    if not donotprint then
        local message = { "pirates.crew_disband", memory.name, Utils.time_longform((memory.real_age or 0) / 60) }
        Common.notify_game(message)
        Server.to_discord_embed_raw({ "", CoreData.comfy_emojis.despair, message }, true)

        -- if memory.game_won then
        --		 game.print({'chronosphere.message_game_won_restart'}, {r=0.98, g=0.66, b=0.22})
        -- end
    end

    memory.game_lost = true -- only necessary to avoid printing research notifications
    Public.reset_crew_and_enemy_force(id)

    local lobby = game.surfaces[CoreData.lobby_surface_name]
    for _, player in pairs(players) do
        if player.character then
            player.character.destroy()
            player.character = nil
        end

        player.set_controller({ type = defines.controllers.god })

        if player.get_associated_characters() and #player.get_associated_characters() == 1 then
            local char = player.get_associated_characters()[1]
            player.teleport(char.position, char.surface)

            player.set_controller({ type = defines.controllers.character, character = char })
        else
            local pos = lobby.find_non_colliding_position("character", Common.lobby_spawnpoint, 32, 0.5)
                or Common.lobby_spawnpoint
            player.teleport(pos, lobby)
            player.create_character()
        end
    end

    if memory.sea_name then
        local seasurface = game.surfaces[memory.sea_name]
        if seasurface then
            game.delete_surface(seasurface)
        end
    end

    for i = 1, memory.hold_surface_count do
        local holdname = Hold.get_hold_surface_name(i)
        if game.surfaces[holdname] then
            game.delete_surface(game.surfaces[holdname])
        end
    end

    local cabinname = Cabin.get_cabin_surface_name()
    if game.surfaces[cabinname] then
        game.delete_surface(game.surfaces[cabinname])
    end

    local s = Hold.get_hold_surface(1)
    if s and s.valid then
        log("hold failed to delete")
    end

    s = Cabin.get_cabin_surface()
    if s and s.valid then
        log(_inspect(cabinname))
        log("cabin failed to delete")
    end

    local crowsnestname = SurfacesCommon.encode_surface_name(memory.id, 0, Surfaces.enum.CROWSNEST, nil)
    if game.surfaces[crowsnestname] then
        game.delete_surface(game.surfaces[crowsnestname])
    end

    for _, destination in pairs(memory.destinations) do
        if game.surfaces[destination.surface_name] then
            game.delete_surface(game.surfaces[destination.surface_name])
        end

        Islands[IslandEnum.enum.CAVE].cleanup_cave_surface(destination)
    end

    global_memory.crew_memories[id] = nil
    for k, idd in pairs(global_memory.crew_active_ids) do
        if idd == id then
            table.remove(global_memory.crew_active_ids, k)
        end
    end

    Lobby.place_starting_dock_showboat(id)
end

function Public.generate_new_crew_id(player_position)
    local global_memory = Memory.get_global_memory()
    local max_crews = Common.starting_ships_count
    local closest_id = nil
    local closest_distance = math.huge

    for id = 1, max_crews do
        if not global_memory.crew_memories[id] then
            local boat_position = Lobby.StartingBoats[id].position
            local distance = Math.distance(player_position, boat_position)
            if distance < closest_distance then
                closest_distance = distance
                closest_id = id
            end
        end
    end

    return closest_id
end

function Public.player_abandon_proposal(player)
    local global_memory = Memory.get_global_memory()

    for k, proposal in pairs(global_memory.crewproposals) do
        if proposal.created_by_player and proposal.created_by_player == player.index then
            Common.notify_lobby({ "pirates.proposal_retracted", proposal.name })
            -- Server.to_discord_embed(message)
            global_memory.crewproposals[k] = nil
        end
    end
end

local crowsnest_delayed = Token.register(function(data)
    Memory.set_working_id(data.crew_id)
    Crowsnest.crowsnest_surface_delayed_init()
end)
function Public.initialise_crowsnest()
    local memory = Memory.get_crew_memory()
    Crowsnest.create_crowsnest_surface()
    Task.set_timeout_in_ticks(5, crowsnest_delayed, { crew_id = memory.id })
end

function Public.initialise_crowsnest_1()
    Crowsnest.create_crowsnest_surface()
end

function Public.initialise_crowsnest_2()
    Crowsnest.crowsnest_surface_delayed_init()
end

function Public.initialise_crew(accepted_proposal, player_position)
    local global_memory = Memory.get_global_memory()

    local new_id = Public.generate_new_crew_id(player_position)
    if not new_id then
        return
    end

    game.reset_time_played() -- affects the multiplayer lobby view

    global_memory.crew_active_ids[#global_memory.crew_active_ids + 1] = new_id

    global_memory.crew_memories[new_id] = {}

    Memory.set_working_id(new_id)

    local memory = Memory.get_crew_memory()

    memory.id = new_id

    memory.game_lost = false
    memory.game_won = false

    local secs = Server.get_current_time()
    if not secs then
        secs = 0
    end
    memory.secs_id = secs

    memory.force_name = Common.get_crew_force_name(new_id)
    memory.enemy_force_name = Common.get_enemy_force_name(new_id)
    memory.ancient_enemy_force_name = Common.get_ancient_hostile_force_name(new_id)
    memory.ancient_friendly_force_name = Common.get_ancient_friendly_force_name(new_id)

    memory.force = game.forces[memory.force_name]
    memory.enemy_force = game.forces[memory.enemy_force_name]
    memory.ancient_enemy_force = game.forces[memory.ancient_enemy_force_name]
    memory.ancient_friendly_force = game.forces[memory.ancient_friendly_force_name]

    memory.evolution_factor = 0

    memory.delayed_tasks = {}
    memory.buffered_tasks = {}
    memory.crewplayerindices = {}
    memory.spectatorplayerindices = {}
    memory.tempbanned_from_joining_data = {}
    memory.destinations = {}
    -- memory.temporarily_logged_off_characters = {}
    memory.temporarily_logged_off_characters_items = {}
    memory.temporarily_logged_off_player_data = {}
    memory.class_renderings = {}
    memory.class_auxiliary_data = {}

    memory.elite_biters = {}
    memory.elite_biters_stream_registrations = {}
    memory.pet_biters = {}

    memory.hold_surface_count = 1

    memory.speed_boost_characters = {}

    memory.original_proposal = accepted_proposal
    memory.name = accepted_proposal.name
    memory.difficulty_option = accepted_proposal.difficulty_option
    memory.capacity_option = accepted_proposal.capacity_option
    -- memory.mode_option = accepted_proposal.mode_option
    memory.difficulty = CoreData.difficulty_options[accepted_proposal.difficulty_option].value
    memory.capacity = CoreData.capacity_options[accepted_proposal.capacity_option].value
    -- memory.mode = CoreData.mode_options[accepted_proposal.mode_option].value
    memory.run_has_blueprints_disabled = accepted_proposal.run_has_blueprints_disabled
    memory.run_is_protected = accepted_proposal.run_is_protected
    memory.run_is_private = accepted_proposal.run_is_private
    memory.private_run_password = accepted_proposal.private_run_password

    memory.destinationsvisited_indices = {}
    memory.stored_fuel = Balance.starting_fuel
    memory.playtesting_stats = {
        coins_gained_by_biters = 0,
        coins_gained_by_nests_and_worms = 0,
        coins_gained_by_trees_and_rocks = 0,
        coins_gained_by_ore = 0,
        coins_gained_by_rocket_launches = 0,
        coins_gained_by_markets = 0,
        coins_gained_by_krakens = 0,
        fuel_spent_at_sea = 0,
        fuel_spent_at_destinations_passively = 0,
        fuel_spent_at_destinations_while_moving = 0,
    }

    memory.captain_accrued_time_data = {}
    memory.max_players_recorded = 0

    memory.officers_table = {}

    memory.classes_table = {} -- stores all unlocked taken classes
    memory.spare_classes = {} -- stores all unlocked untaken classes
    memory.recently_purchased_classes = {} -- stores recently unlocked classes to add it back to available class pool list later
    memory.unlocked_classes = {} -- stores all unlocked classes just for GUI (to have consistent order)
    memory.available_classes_pool = Classes.initial_class_pool() -- stores classes that can be randomly picked for unlocking
    memory.class_entry_count = 0 -- used to track whether new class entries should be added during "full_update"

    memory.healthbars = {}
    memory.overworld_krakens = {}
    memory.kraken_stream_registrations = {}

    memory.overworldx = 0
    memory.overworldy = 0

    memory.hold_surface_destroyable_wooden_chests = {}
    memory.hold_surface_timers_of_wooden_chests_queued_for_destruction = {}

    memory.seaname = SurfacesCommon.encode_surface_name(memory.id, 0, SurfacesCommon.enum.SEA, enum.DEFAULT)

    local surface = game.surfaces[CoreData.lobby_surface_name]
    memory.spawnpoint = Common.lobby_spawnpoint

    memory.force.set_spawn_position(memory.spawnpoint, surface)

    local message = { "pirates.crew_launch", accepted_proposal.name }
    Common.notify_game(message)
    -- Server.to_discord_embed_raw(CoreData.comfy_emojis.pogkot .. message .. ' Difficulty: ' .. CoreData.difficulty_options[memory.difficulty_option].text .. ', Capacity: ' .. CoreData.capacity_options[memory.capacity_option].text3 .. '.')
    Server.to_discord_embed_raw({
        "",
        CoreData.comfy_emojis.pogkot,
        message,
        " Capacity: ",
        CoreData.capacity_options[memory.capacity_option].text3,
        ".",
    }, true)
    game.surfaces[CoreData.lobby_surface_name].play_sound({ path = "utility/new_objective", volume_modifier = 0.75 })

    memory.boat = global_memory.lobby_boats[new_id]
    local boat = memory.boat

    for _, e in pairs(memory.boat.cannons_temporary_reference or {}) do
        Common.new_healthbar(true, e, Balance.cannon_starting_hp, nil, e.health, 0.3, -0.1, memory.boat)
    end

    boat.dockedposition = boat.position
    boat.speed = 0
    boat.cannonscount = 2

    Public.set_initial_damage_modifiers()

    memory.seconds_until_alert_sound_can_be_played_again = 0
end

function Public.set_initial_damage_modifiers()
    local memory = Memory.get_crew_memory()
    local force = memory.force

    local ammo_damage_modifiers = Balance.player_ammo_damage_modifiers()
    local turret_attack_modifiers = Balance.player_turret_attack_modifiers()
    local gun_speed_modifiers = Balance.player_gun_speed_modifiers()

    for category, factor in pairs(ammo_damage_modifiers) do
        force.set_ammo_damage_modifier(category, factor)
    end

    for category, factor in pairs(turret_attack_modifiers) do
        force.set_turret_attack_modifier(category, factor)
    end

    for category, factor in pairs(gun_speed_modifiers) do
        force.set_gun_speed_modifier(category, factor)
    end
end

function Public.buff_all_damage(amount)
    local memory = Memory.get_crew_memory()
    local force = memory.force

    local ammo_damage_modifiers = Balance.player_ammo_damage_modifiers()
    local turret_attack_modifiers = Balance.player_turret_attack_modifiers()

    for category, factor in pairs(ammo_damage_modifiers) do
        local current_modifier = force.get_ammo_damage_modifier(category)
        force.set_ammo_damage_modifier(category, current_modifier + amount * (1 + factor))
    end

    for category, factor in pairs(turret_attack_modifiers) do
        local current_modifier = force.get_turret_attack_modifier(category)
        force.set_turret_attack_modifier(category, current_modifier + amount * (1 + factor))
    end
end

function Public.summon_crew()
    local memory = Memory.get_crew_memory()
    local boat = memory.boat

    local print = false
    for _, player in pairs(game.connected_players) do
        if
            player.surface
            and player.surface.valid
            and boat.surface_name
            and player.surface.name == boat.surface_name
            and (not Boats.on_boat(boat, player.position))
        then
            local p = player.surface.find_non_colliding_position("character", memory.spawnpoint, 5, 0.1)
            if p then
                player.teleport(p)
            else
                player.teleport(memory.spawnpoint)
            end
            print = true
        end
    end
    if print then
        Common.notify_force(memory.force, { "pirates.crew_summon" })
    end
end

-- NOTE: Connected with common.lua item blacklist
function Public.reset_crew_and_enemy_force(id)
    local crew_force = game.forces[Common.get_crew_force_name(id)]
    local enemy_force = game.forces[Common.get_enemy_force_name(id)]
    local ancient_friendly_force = game.forces[Common.get_ancient_friendly_force_name(id)]
    local ancient_enemy_force = game.forces[Common.get_ancient_hostile_force_name(id)]

    crew_force.reset()
    enemy_force.reset()
    ancient_friendly_force.reset()
    ancient_enemy_force.reset()

    ancient_enemy_force.set_turret_attack_modifier("gun-turret", 0.2)

    enemy_force.reset_evolution()
    for _, tech in pairs(crew_force.technologies) do
        crew_force.set_saved_technology_progress(tech, 0)
    end
    local lobby = game.surfaces[CoreData.lobby_surface_name]
    crew_force.set_spawn_position(Common.lobby_spawnpoint, lobby)

    enemy_force.ai_controllable = true

    crew_force.set_friend(Common.lobby_force_name, true)
    game.forces[Common.lobby_force_name].set_friend(crew_force, true)
    crew_force.set_friend(ancient_friendly_force, true)
    ancient_friendly_force.set_friend(crew_force, true)
    enemy_force.set_friend(ancient_friendly_force, true)
    ancient_friendly_force.set_friend(enemy_force, true)
    enemy_force.set_friend(ancient_enemy_force, true)
    ancient_enemy_force.set_friend(enemy_force, true)

    -- enemy_force.set_friend(environment_force, true)
    -- environment_force.set_friend(enemy_force, true)

    -- environment_force.set_friend(ancient_enemy_force, true)
    -- ancient_enemy_force.set_friend(environment_force, true)

    -- environment_force.set_friend(ancient_friendly_force, true)
    -- ancient_friendly_force.set_friend(environment_force, true)

    -- maybe make these dependent on map... it could be slower to mine on poor maps, so that players jump more often rather than getting every last drop
    crew_force.mining_drill_productivity_bonus = 1
    -- crew_force.mining_drill_productivity_bonus = 1.25
    crew_force.manual_mining_speed_modifier = 3
    crew_force.character_inventory_slots_bonus = 0
    -- crew_force.character_inventory_slots_bonus = 10
    crew_force.laboratory_productivity_bonus = 0
    crew_force.ghost_time_to_live = 12 * 60 * 60
    crew_force.worker_robots_speed_modifier = 0.5
    crew_force.research_queue_enabled = true

    for k, v in pairs(Balance.player_ammo_damage_modifiers()) do
        crew_force.set_ammo_damage_modifier(k, v)
    end
    for k, v in pairs(Balance.player_gun_speed_modifiers()) do
        crew_force.set_gun_speed_modifier(k, v)
    end
    for k, v in pairs(Balance.player_turret_attack_modifiers()) do
        crew_force.set_turret_attack_modifier(k, v)
    end

    -- Kovarex is auto-installed as a recipe in the uranium island centrifuges. If the players want more kovarex than that, they need to research it.
    -- crew_force.technologies['kovarex-enrichment-process'].researched = true

    -- crew_force.technologies['circuit-network'].researched = true
    -- crew_force.technologies['uranium-processing'].researched = true
    -- crew_force.technologies['gun-turret'].researched = true
    -- crew_force.technologies['electric-energy-distribution-1'].researched = true
    -- crew_force.technologies['electric-energy-distribution-2'].researched = true
    -- crew_force.technologies['advanced-material-processing'].researched = true
    -- crew_force.technologies['advanced-material-processing-2'].researched = true
    -- crew_force.technologies['solar-energy'].researched = true
    -- crew_force.technologies['inserter-capacity-bonus-1'].researched = true --needed to make stack inserters different to fast inserters
    -- crew_force.technologies['inserter-capacity-bonus-2'].researched = true

    --as prerequisites for uranium ammo and automation 3:
    -- crew_force.technologies['speed-module'].researched = true
    -- crew_force.technologies['tank'].researched = true

    -- Trying out having this be researched by default, in order to make coal (the resource needed to power the ship) interchangeable with oil, thereby making coal more precious:
    -- crew_force.technologies['coal-liquefaction'].researched = true

    -- crew_force.technologies['toolbelt'].enabled = false --trying this. we don't actually want players to carry too many things manually, and in fact in a resource-tight scenario that's problematic

    -- crew_force.technologies['railway'].researched = true --needed for purple sci

    -- crew_force.technologies['land-mine'].enabled = false
    crew_force.technologies["landfill"].enabled = false
    crew_force.technologies["cliff-explosives"].enabled = false

    crew_force.technologies["rail-signals"].enabled = false

    crew_force.technologies["logistic-system"].enabled = false

    crew_force.technologies["rocketry"].enabled = false
    crew_force.technologies["artillery"].enabled = false
    -- crew_force.technologies['destroyer'].enabled = false
    crew_force.technologies["spidertron"].enabled = false
    -- crew_force.technologies['atomic-bomb'].enabled = false -- experimenting
    crew_force.technologies["explosive-rocketry"].enabled = false

    -- crew_force.technologies['research-speed-1'].enabled = false
    -- crew_force.technologies['research-speed-2'].enabled = false
    -- crew_force.technologies['research-speed-3'].enabled = false
    -- crew_force.technologies['research-speed-4'].enabled = false
    -- crew_force.technologies['research-speed-5'].enabled = false
    -- crew_force.technologies['research-speed-6'].enabled = false
    -- crew_force.technologies['follower-robot-count-1'].enabled = false
    -- crew_force.technologies['follower-robot-count-2'].enabled = false
    -- crew_force.technologies['follower-robot-count-3'].enabled = false
    -- crew_force.technologies['follower-robot-count-4'].enabled = false

    -- crew_force.technologies['inserter-capacity-bonus-3'].enabled = false
    -- crew_force.technologies['inserter-capacity-bonus-4'].enabled = false
    -- crew_force.technologies['inserter-capacity-bonus-5'].enabled = false
    -- crew_force.technologies['inserter-capacity-bonus-6'].enabled = false
    -- crew_force.technologies['refined-flammables-3'].enabled = false
    -- crew_force.technologies['refined-flammables-4'].enabled = false
    -- crew_force.technologies['refined-flammables-5'].enabled = false

    -- for lategame balance:
    -- crew_force.technologies['worker-robots-storage-1'].enabled = false
    -- crew_force.technologies['worker-robots-storage-2'].enabled = false
    -- crew_force.technologies['worker-robots-storage-3'].enabled = false
    -- crew_force.technologies['worker-robots-speed-5'].enabled = false
    -- crew_force.technologies['worker-robots-speed-6'].enabled = false
    -- crew_force.technologies['follower-robot-count-5'].enabled = false
    -- crew_force.technologies['follower-robot-count-6'].enabled = false
    -- crew_force.technologies['follower-robot-count-7'].enabled = false
    -- crew_force.technologies['inserter-capacity-bonus-6'].enabled = false
    -- crew_force.technologies['inserter-capacity-bonus-7'].enabled = false

    -- crew_force.technologies['weapon-shooting-speed-6'].enabled = false
    -- crew_force.technologies['laser-shooting-speed-6'].enabled = false
    -- crew_force.technologies['laser-shooting-speed-7'].enabled = false
    -- crew_force.technologies['refined-flammables-5'].enabled = false
    -- crew_force.technologies['refined-flammables-6'].enabled = false
    -- crew_force.technologies['refined-flammables-7'].enabled = false
    -- crew_force.technologies['energy-weapons-damage-5'].enabled = false --5 makes krakens too easy
    -- crew_force.technologies['energy-weapons-damage-6'].enabled = false
    -- crew_force.technologies['energy-weapons-damage-7'].enabled = false
    -- crew_force.technologies['physical-projectile-damage-5'].enabled = false
    -- crew_force.technologies['physical-projectile-damage-6'].enabled = false
    -- crew_force.technologies['physical-projectile-damage-7'].enabled = false
    -- crew_force.technologies['stronger-explosives-5'].enabled = false
    -- crew_force.technologies['stronger-explosives-6'].enabled = false
    -- crew_force.technologies['stronger-explosives-7'].enabled = false
    -- these require 2000 white sci each:
    crew_force.technologies["artillery-shell-range-1"].enabled = false --infinite techs
    crew_force.technologies["artillery-shell-speed-1"].enabled = false --infinite techs

    -- crew_force.technologies['steel-axe'].enabled = false

    crew_force.technologies["nuclear-power"].enabled = true

    crew_force.technologies["effect-transmission"].enabled = true

    -- exploit?:
    crew_force.technologies["gate"].enabled = true

    -- crew_force.technologies['productivity-module'].enabled = false
    -- crew_force.technologies['productivity-module-2'].enabled = false
    -- crew_force.technologies['productivity-module-3'].enabled = false

    -- crew_force.technologies['speed-module'].enabled = true
    -- crew_force.technologies['speed-module-2'].enabled = false
    -- crew_force.technologies['speed-module-3'].enabled = false
    -- crew_force.technologies['effectivity-module'].enabled = true
    -- crew_force.technologies['effectivity-module-2'].enabled = false
    -- crew_force.technologies['effectivity-module-3'].enabled = false
    -- crew_force.technologies['automation-3'].enabled = false
    -- crew_force.technologies['rocket-control-unit'].enabled = false
    -- crew_force.technologies['rocket-silo'].enabled = false
    -- crew_force.technologies['space-scienkce-pack'].enabled = false
    crew_force.technologies["mining-productivity-3"].enabled = false --huge trap. even the earlier ones are a trap?
    crew_force.technologies["mining-productivity-4"].enabled = false
    -- crew_force.technologies['logistics-3'].enabled = true
    -- crew_force.technologies['nuclear-fuel-reprocessing'].enabled = true

    -- crew_force.technologies['railway'].enabled = false
    crew_force.technologies["automated-rail-transportation"].enabled = false
    crew_force.technologies["braking-force-1"].enabled = false
    crew_force.technologies["braking-force-2"].enabled = false
    crew_force.technologies["braking-force-3"].enabled = false
    crew_force.technologies["braking-force-4"].enabled = false
    crew_force.technologies["braking-force-5"].enabled = false
    crew_force.technologies["braking-force-6"].enabled = false
    crew_force.technologies["braking-force-7"].enabled = false
    crew_force.technologies["fluid-wagon"].enabled = false

    crew_force.technologies["production-science-pack"].enabled = true
    crew_force.technologies["utility-science-pack"].enabled = true

    crew_force.technologies["modular-armor"].enabled = false
    crew_force.technologies["power-armor"].enabled = false
    crew_force.technologies["solar-panel-equipment"].enabled = false
    crew_force.technologies["personal-roboport-equipment"].enabled = false
    crew_force.technologies["personal-laser-defense-equipment"].enabled = false
    crew_force.technologies["night-vision-equipment"].enabled = false
    crew_force.technologies["energy-shield-equipment"].enabled = false
    crew_force.technologies["belt-immunity-equipment"].enabled = false
    crew_force.technologies["exoskeleton-equipment"].enabled = false
    crew_force.technologies["battery-equipment"].enabled = false
    crew_force.technologies["fusion-reactor-equipment"].enabled = false
    crew_force.technologies["power-armor-mk2"].enabled = false
    crew_force.technologies["energy-shield-mk2-equipment"].enabled = false
    crew_force.technologies["personal-roboport-mk2-equipment"].enabled = false
    crew_force.technologies["battery-mk2-equipment"].enabled = false
    crew_force.technologies["discharge-defense-equipment"].enabled = false

    -- crew_force.technologies['distractor'].enabled = false
    -- crew_force.technologies['military-4'].enabled = true
    -- crew_force.technologies['uranium-ammo'].enabled = true

    Public.disable_recipes(crew_force)
end

-- NOTE: Connected with common.lua item blacklist
function Public.disable_recipes(crew_force)
    crew_force.recipes["pistol"].enabled = false
    -- crew_force.recipes['centrifuge'].enabled = false
    -- crew_force.recipes['flamethrower-turret'].enabled = false
    crew_force.recipes["locomotive"].enabled = false
    -- crew_force.recipes['car'].enabled = false
    crew_force.recipes["cargo-wagon"].enabled = false
    -- crew_force.recipes['slowdown-capsule'].enabled = false
    -- crew_force.recipes['nuclear-fuel'].enabled = false
    -- crew_force.recipes['rail'].enabled = false
    -- crew_force.recipes['speed-module'].enabled = false
    -- crew_force.recipes['tank'].enabled = false
    -- crew_force.recipes['cannon-shell'].enabled = false
    -- crew_force.recipes['explosive-cannon-shell'].enabled = false
    -- and since we can't build tanks anyway, let's disable this for later:
    -- crew_force.recipes['uranium-cannon-shell'].enabled = false
    -- crew_force.recipes['explosive-uranium-cannon-shell'].enabled = false

    -- need these for nuclear related buildings
    -- crew_force.recipes['concrete'].enabled = false
    -- crew_force.recipes['hazard-concrete'].enabled = false
    -- crew_force.recipes['refined-concrete'].enabled = false
    -- crew_force.recipes['refined-hazard-concrete'].enabled = false

    crew_force.recipes["speed-module-2"].enabled = false
    crew_force.recipes["speed-module-3"].enabled = false
end

return Public
