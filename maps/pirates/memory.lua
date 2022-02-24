
local Global = require 'utils.global'
local CoreData = require 'maps.pirates.coredata'
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
	pirates_global_memory.afk_player_indices = {}
	pirates_global_memory.playerindex_to_time_played_continuously = {}
	pirates_global_memory.playerindex_to_priority = {}
	pirates_global_memory.player_gui_memories = {}
	pirates_global_memory.offline_players = {}
	pirates_global_memory.crew_memories = {}
	pirates_global_memory.crew_active_ids = {}
	pirates_global_memory.working_id = nil --should only ever be nil, 1, 2 or 3
	
	pirates_global_memory.lobby_boats = {}
	
	pirates_global_memory.active_crews_cap = nil
	pirates_global_memory.crew_capacity_min = nil
	
	pirates_global_memory.crewproposals = {}

	pirates_global_memory.global_delayed_tasks = {}
	pirates_global_memory.global_buffered_tasks = {}
end




function Public.reset_crew_memory(id) --also serves as a dev reference of memory entries
	pirates_global_memory.crew_memories[id] = {}
	local memory = pirates_global_memory.crew_memories[id]

	memory.secs_id = nil

	memory.id = nil
	memory.age = nil
	memory.real_age = nil
	memory.completion_time = nil

	memory.force_name = nil
	memory.enemy_force_name = nil

	memory.original_proposal = nil
	memory.name = nil
	memory.difficulty_option = nil
	memory.capacity_option = nil
	-- memory.mode_option = nil
	memory.difficulty = nil
	memory.capacity = nil
	-- memory.mode = nil
	
	memory.destinations = nil
	memory.currentdestination_index = nil

	memory.hold_surface_count = nil
	memory.merchant_ships_unlocked = nil

	memory.boat = nil
	
	memory.crewplayerindices = nil
	memory.spectatorplayerindices = nil
	memory.tempbanned_from_joining_data = nil
	memory.playerindex_captain = nil
	memory.captain_accrued_time_data = nil

	memory.speed_boost_characters = nil

	memory.enemyboats = nil
	memory.overworld_krakens = nil
	memory.active_sea_enemies = nil
	memory.kraken_stream_registrations = nil

	memory.mainshop_availability_bools = nil

	memory.delayed_tasks = nil
	memory.buffered_tasks = nil
	memory.game_lost = false
	memory.game_won = false
	memory.crew_disband_tick = nil
	memory.destinationsvisited_indices = nil
	memory.overworldx = nil
	memory.overworldy = nil
	memory.mapbeingloadeddestination_index = nil
	memory.loadingticks = nil
	memory.stored_fuel = nil
	memory.spawnpoint = nil

	memory.scripted_biters = nil
	memory.scripted_unit_groups = nil
	memory.floating_pollution = nil
end

function Public.fallthrough_crew_memory() --could make this a metatable
	return {
		id = 0,
		difficulty = 1,
		force_name = 'player',
		boat = {},
		destinations = {},
		spectatorplayerindices = {},
		crewplayerindices = {},
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
