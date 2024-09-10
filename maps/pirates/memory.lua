-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Global = require 'utils.global'
-- local CoreData = require 'maps.pirates.coredata'
local pirates_global_memory = {}
local Public = {}

-- register only this
Global.register(
    pirates_global_memory,
    function(tbl)
        pirates_global_memory = tbl
    end
)

function Public.global_reset_memory()
    for k, _ in pairs(pirates_global_memory) do
        pirates_global_memory[k] = nil
    end

    pirates_global_memory.config = {}
    pirates_global_memory.disband_crews = false -- false = disband crew button hidden by default
    pirates_global_memory.afk_player_indices = {}
    pirates_global_memory.playerindex_to_time_played_continuously = {}
    pirates_global_memory.playerindex_to_captainhood_priority = {}
    pirates_global_memory.player_gui_memories = {}
    pirates_global_memory.crew_memories = {}
    pirates_global_memory.crew_active_ids = {}
    pirates_global_memory.working_id = nil --should only ever be nil, 1, 2 or 3

    pirates_global_memory.lobby_boats = {}

    pirates_global_memory.active_crews_cap_memory = nil
    pirates_global_memory.crew_capacity_min = nil

    pirates_global_memory.crewproposals = {}

    pirates_global_memory.global_delayed_tasks = {}
    pirates_global_memory.global_buffered_tasks = {}

    pirates_global_memory.last_players_health = {} --used to make damage reduction work somewhat properly
end

function Public.initialise_crew_memory(id) --mostly serves as a dev reference of memory entries
    -- but not _everything_ is stored here, it's just a guide to the most important things

    pirates_global_memory.crew_memories[id] = {}
    local memory = pirates_global_memory.crew_memories[id]
    
    memory.game_lost = false
    memory.game_won = false
end

function Public.fallthrough_crew_memory() --could make this a metatable, but metatables and factorio global seem not to play nicely
    return {
        id = 0,
        difficulty = 1,
        force_name = 'player', -- should match Common.lobby_force_name
        boat = {},
        destinations = {},
        spectatorplayerindices = {},
        crewplayerindices = {}
        --[[boat = {
			type = nil,
			state = nil,
			speed = nil,
			speedticker1 = nil,
			speedticker2 = nil,
			speedticker3 = nil,
			stored_resources = {},
			position = nil, --the far right edge of the boat
			decksteeringchests = nil,
			crowsneststeeringchests = nil,
			cannons = nil,
			EEI = nil,
			EEIpower_production = nil,
			EEIelectric_buffer_size = nil,
			dockedposition = nil,
			surface_name = nil,
		}]]
    }
end

function Public.get_crew_memory()
    if pirates_global_memory.working_id and pirates_global_memory.working_id > 0 then
        return pirates_global_memory.crew_memories[pirates_global_memory.working_id] or Public.fallthrough_crew_memory()
    else
        return Public.fallthrough_crew_memory()
    end
end

function Public.get_global_memory()
    return pirates_global_memory
end

function Public.set_working_id(id)
    pirates_global_memory.working_id = id
end

return Public
