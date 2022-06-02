-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
-- local Structures = require 'maps.pirates.structures.structures'
local Token = require 'utils.token'
local Task = require 'utils.task'
-- local SurfacesCommon = require 'maps.pirates.surfaces.common'
local Effects = require 'maps.pirates.effects'

local Public = {}

-- local kraken_width = 31 --not old code, just commented for luacheck
-- local kraken_height = 31 --not old code, just commented for luacheck

local kraken_bps = {
	[[0eNqd2tuOmzAQgOF38TWR8Nj4wKtUe5EmaIuUhSihh9Uq714IdtWLVpp/r1aRvh1mxgQYnA/z9fJ9uN7GaTH9h7lPx+thmQ+vt/G8ff5leuca8779eTRmPM3T3fRfVji+TsfLRpb362B6My7Dm2nMdHzbPv2c5/MwHU7fhvtitn+czsMayz5eGrOMl2EPcp3v4zLOUzmSfR7IhsefMOvhTrdhGdYQ/9HO6rTssSPSCelMtCDtWqSVPdkXVlqkE9LKKv2uEW6Rjkgri+xI2jt2BGeCbYs0iq1tSCA17tgTHAlGOWeCta0u2iKNMpGANOqfdtHjU3cEB4IjwVaQZrFRQwR1RLuQac/EIR2JFhRblN/fvGfCdCRaBGlllbYlJ2zREemEtLaFlbNctHfVypWXNmvJNaLogHRGWnsFr5xlrm66ZU0X1EVBd5/KA+OR8Yw4bIywUrUXjMod49rvqSOPQUVr73KVO8ZhMh3jgfHIeGI8I64+IR16BLAenQOerZJnq+TZKnm2Sp6tkmerxEbDylmpwkrVju4WzYdFe6QtC25h9I7xwHhkPDGeERe2psKSEZaM+gQr8yXSgrRjmbDgFkb3jHeMB8Yj44lx7QkT2RMhm6grd4x7xjvGA+ORce0yJTZzJLZMiTUysUYm1kj2xqFybSMza2RmubO3DtKSubNobeqVB8a1qaORWdi+jNjP5KLea7Fss4VN2CLkjUzRGWl1G9lMK2ymFYcKdahQNucVrh2vK1de7sSjQj0qlI1KhWuHQmHTiaAtI2F7RsIewgtXp452gorukGaZZKTVTWTPghI+00TtdCpoI0bQTkzRCemMtGWpqLvCnnYK1853lf+z1Jdm/wlF/9cPMhrzY7jdnwEkWR+zRO+Cz+sBH78BXJmyLg==]],
	[[0eNqdmt2O2jAQRt/F19lVPPFfeJVqVbFgbSNBQJBti1Z59ybEqaoWtXN6hSKdDJ/HY/sbw4d5Pbzn86XrB7P5MNd+e34aTk9vl24/P383m6apzG3+GCvT7U791Ww+TWD31m8PMzLcztlsTDfko6lMvz3OT99Op33un3Zf8nUw84v9Pk+x7PhSmdwP3dDlJc794fa5fz++5ssEPI5QmfPpOr106osoG579XVb97Mex+iOOKOPUJcwc71GcRhmnkX8EcnRgc8RxTtfQHUqufkeXLxx/Rp4mZ3fJQzbz9z+EhcANgZ0OFg57HbxUaSCwVYZ2JPQCW4doJMQyJRHRSUd7kpIFjgRGMphoQUJEGTsQ2QHNTECDDEh2JLIjKr+IBrnQ4hGNlAhTosxJIglMaLUnlO6FFkF0g2jlntaSlLQoJQstNaK1J2RNdBdaK7zgWuV2OVRbRKu1FFwbXZCWhbY1wz3DA8O12ostsAwXhjcMdwz3DA8MjwxPDNdOk0ML1bG0M/9mmYGzzMFZZuEs83ArztKuPWFWnOVdWN6F5V1Y3rWOwXrSqFjknS0yzxa550K3iFbv7J5tpp4tU8+WqWfL1LNl6tkyZV3LirNpEjZNwqZJvQn4/1lIwjIj2swEcvlQaI9otRcIrNoDq/bAqj2wamfdq2Xt64qzOVWXQEQlENkWFlkNRFYDkdVAZDXAenvLmvsVTwxnk6qugYRqIKEzMrEzMrECS6wE2HWDZfcNKx4ZnhjO8t5o894iU4UuNAqtTiO70ii4dqBSE69Z6Ihoy4JrjcaKC8LVebHkcC90QLRluLZPWnHHcOU6EvSTi7DbmIKrpQuT3iDp7P6j4GrpDZPukHR2oSHsDkFYH77i2pGiTllYTyisJxTWtRVcmBh1HlG3IawfEObYC67eeiOSHtFeykyvMBcrzMVKQtITOkyZtRNm7QT5HfmL33mplj96bH7520hlvubL9f6+JOtiK9E1wbVTGz/+ALfE6PI=]],
	[[0eNqdmctu4kAQRf+l10aiyv3kV0ZZMGBlLBEbgecRRfz7GOgezSZSnawipEP51u1HbuEP9/30czhfxmlxuw93nfbnzTJvXi/j8f75j9v1fefe739unRsP83R1u28rOL5O+9MdWd7Pg9u5cRneXOem/dv90+95Pg7T5vBjuC7u/sXpOKy15PbSuWU8Dc8i5/k6LuM8tSc9HiT+9q/M+rjDZViGtcRndEB0tNH+QXsCBwIjGUy0IiHKaidEZxsdiNmBmB2Qf5VOhNYe0ahJRV1a3Y7EwEh2a0QHMqK1icjtiNxODzoR2Npk+oIQ67LnB50JXAgsSIdVdSFCChJS0B4paGlkS3RX2iq84ioMVyMuTzFbhkeEK6tublWfYiCuDI8MTwwvCDcb2bNWWbYSFq6EpauGJ4Znhlt99+x4eLYjK94z3DM8MDwyPDE8I1yZM+b7+hmKekQXRJuPXmBbILAtENgWYJFYWCZueGY4812Z78p8V2akMiOVGanMSLUaGcnEJWhiEDQyVDohOiOaeWI+pZGdUjYbCRuOGs5sFOajMCPNOSayQBjZHRDZKU1sVdkw2HAoJjE8M9y6qpkdj8yMZBNnwyPDE8OtRhYWCAsLD4W1WtCq6hZl34YLwwPDrdrZWNvwwHAmRpkY66WnylpV1qp+RYz1Bm648eLQnvzTrrTZGDbVKptqK26dUBpuFeNJ9ql0QbS5UTYXKnsvoYFEwkpnRAsrbk0PiqKvouirLBEqS4QVt04nmshEUOmIaGHFhVWHjVrHMM1krlIWepSFHi3kBxBlqaThsLpneGC40Zi+xgxEK6KNtvSClMjnSl665+v33X8v8zv3a7hcH9/XLD4VTb6Pvqyb+fYX8FohZA==]],
	[[0eNqV2dtq4zAQgOF30bUD0ehk+1WWXqSJ6BpSO8TeQyl599qxtOzFLsx/VQJf5NF0LI2UT/N6/ZFv92FcTP9p5vF0OyzT4e0+XLbPv03vXGM+tj+PxgznaZxN/22Fw9t4um5k+bhl05thye+mMePpffv0a5oueTycv+d5MdsXx0tex7KPl8YswzXvg9ymeViGaaxPej7IxsefYdbHne95yesQ/9ESdNo/NcKR4ESwRZpNUVDYoowkPLUnGI3cEtwRbFEc2lxHEkhEgexaPNLKsNMeyRHpRLQ27hZF0qKVYdfikFbG3e2RWKQj0SJIK2dpj3sownhEXJRpsZYFY1kwhXeIi7IUrbDYhcUuLHbHgincMx4Yj4wnxpU7hfUsM4U7xj3jgfHIeGIcJrJDXP02ebZweLREWtQvFK3dkyq3jLPQ1QUZWEEGVpCBFSTrvCpvGWf/VWGJFO3okTTGRQekI9IJ6RZpdTFGVoyRFWNkxci678phZli5CEuksEQKm6qwqcI3wx0Z166miS2+iS2+iRVwYgWcWAGzY1jlLeMd4sIyo72TsOxUWLll3DMeGIdTTYy3jHeIC8uM9tLBdqgL61gNsCN25YnxlnE2VW2vLEeSR2En+MoT4tq+vXLl+isWzZRdD1SeENdu2ZUrXyURVO3CbhMqT4hr3+vKtcE4NlV23i9c2/uIRxXmWejshF24tg8TdL0u6H5d2FFM2GFJ0IFGWCcurD2VRA5uRQek1a8d69gK1zbWwhqNwtWjs/20cO3oju1hju1hhcNgtCcUx3alwv89+kuz/7za//VjbWN+5vv8HEBa61Mnybvou3UZeXwB67xzTA==]]
}

Public.kraken_slots = 4
local kraken_positions = {
	[1] = {first = {x = -40.5, y = -59.5}, second = {x = -15.5, y = -49.5}, third = {x = -32.5, y = -39.5}, final = {x = -24.5, y = -30.5},},
	[2] = {first = {x = 28.5, y = -59.5}, second = {x = 10.5, y = -49.5}, third = {x = 30.5, y = -39.5}, final = {x = 13.5, y = -30.5},},
	[3] = {first = {x = -40.5, y = 59.5}, second = {x = -15.5, y = 49.5}, third = {x = -32.5, y = 39.5}, final = {x = -24.5, y = 29.5},},
	[4] = {first = {x = 28.5, y = 59.5}, second = {x = 10.5, y = 49.5}, third = {x = 30.5, y = 39.5}, final = {x = 13.5, y = 29.5},},
	-- [1] = {first = {x = 96.5, y = 0.5}, second = {x = 81.5, y = 5.5}, third = {x = 66.5, y = -4.5}, final = {x = 51.5, y = 0.5},}
}

local kraken_tick_token =
    Token.register(
    function(data)
		Public.kraken_tick(data.crew_id, data.kraken_id, data.step, data.substep)
	end
)
function Public.kraken_tick(crew_id, kraken_id, step, substep)
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	if not (memory.id and memory.id > 0) then return end --check if crew disbanded
	if memory.game_lost then return end
	local surface = game.surfaces[memory.sea_name]
	local kraken_data = memory.active_sea_enemies.krakens[kraken_id]
	if not kraken_data then return end --check if kraken died
	local kraken_spawner_entity = kraken_data.spawner_entity

	if step == 1 then
		if substep == 1 then
			Effects.kraken_effect_3(surface, kraken_data.position, 10)
		end
		if substep < 32 then
			Effects.kraken_effect_1(surface, kraken_data.position, substep/32 * 6.283)
			Task.set_timeout_in_ticks(1, kraken_tick_token, {crew_id = crew_id, kraken_id = kraken_id, step = 1, substep = substep + 1})
		else
			Task.set_timeout_in_ticks(1, kraken_tick_token, {crew_id = crew_id, kraken_id = kraken_id, step = 2, substep = 1})
		end
	elseif step == 2 then
		local p1 = kraken_positions[kraken_id].first
		local p2 = kraken_positions[kraken_id].second
		local p3 = kraken_positions[kraken_id].third
		local p4 = kraken_positions[kraken_id].final
		if substep <= 30 then
			if substep < 5 then
				Public.kraken_move(kraken_id, p1, substep % 4 + 1)
			elseif substep < 10 then
				Public.kraken_move(kraken_id, Utils.interpolate(p1, p2, (substep-5) / 5), substep % 4 + 1)
			elseif substep < 15 then
				Public.kraken_move(kraken_id, p2, substep % 4 + 1)
			elseif substep < 20 then
				Public.kraken_move(kraken_id, Utils.interpolate(p2, p3, (substep-15) / 5), substep % 4 + 1)
			elseif substep < 25 then
				Public.kraken_move(kraken_id, p3, substep % 4 + 1)
			elseif substep <= 30 then
				Public.kraken_move(kraken_id, Utils.interpolate(p3, p4, (substep-25) / 5), substep % 4 + 1)
			end
			Task.set_timeout_in_ticks(15, kraken_tick_token, {crew_id = crew_id, kraken_id = kraken_id, step = 2, substep = substep + 1})
		else
			Task.set_timeout_in_ticks(6, kraken_tick_token, {crew_id = crew_id, kraken_id = kraken_id, step = 3, substep = 1})
		end
	elseif step == 3 then
		Public.kraken_move(kraken_id, kraken_data.position, substep % 4 + 1)

		-- regen:
		local healthbar = memory.healthbars and memory.healthbars[kraken_spawner_entity.unit_number]
		if healthbar then
			local new_health = Math.min(healthbar.health + Balance.kraken_regen_scale, kraken_data.max_health)
			healthbar.health = new_health
			Common.update_healthbar_rendering(healthbar, new_health)
		end

		local crewmembers = Common.crew_get_crew_members()
		local crewCount = #crewmembers

		-- firing speed now depends on player count:
		local firing_period
		if crewCount <= 12 then
			firing_period = 4
		else
			firing_period = 3
		-- elseif crewCount <= 24 then
		-- 	firing_period = 3
		-- else
		-- 	firing_period = 2
		end

		if substep % firing_period == 0 then
			local p_can_fire_at = {}
			for _, player in pairs(crewmembers) do
				local p = player.position
				if player.surface == surface then -- and Public.on_boat(memory.boat, p)
					p_can_fire_at[#p_can_fire_at + 1] = p
				end
			end

			if #p_can_fire_at > 0 then
				local p_fire = p_can_fire_at[Math.random(#p_can_fire_at)]
				local stream = surface.create_entity{
					name = 'acid-stream-spitter-big',
					position = kraken_data.position,
					force = memory.enemy_force_name,
					source = kraken_data.position,
					target = p_fire,
					max_range = 500,
					speed = 0.1
				}
				memory.kraken_stream_registrations[#memory.kraken_stream_registrations + 1] = {number = script.register_on_entity_destroyed(stream), position = p_fire}
				Effects.kraken_effect_4(surface, kraken_data.position)
			end
		end

		if substep % 50 > 40 then
			-- if substep % 70 == 69 then
			-- 	Public.kraken_spawn_biters(kraken_id)
			-- end
			Task.set_timeout_in_ticks(5, kraken_tick_token, {crew_id = crew_id, kraken_id = kraken_id, step = 3, substep = substep + 1})
		elseif substep % 50 > 30 then
			Task.set_timeout_in_ticks(10, kraken_tick_token, {crew_id = crew_id, kraken_id = kraken_id, step = 3, substep = substep + 1})
		else
			Task.set_timeout_in_ticks(30, kraken_tick_token, {crew_id = crew_id, kraken_id = kraken_id, step = 3, substep = substep + 1})
		end
	end
end

local function on_entity_destroyed(event)
	local registration_number = event.registration_number

	local p
	local memory
	for i = 1,3 do
		Memory.set_working_id(i)
		memory = Memory.get_crew_memory()
		if memory.kraken_stream_registrations then
			for j, r in pairs(memory.kraken_stream_registrations) do
				if r.number == registration_number then
					p = r.position
					memory.kraken_stream_registrations = Utils.ordered_table_with_index_removed(memory.kraken_stream_registrations, j)
					break
				end
			end
		end
		if p then break end
	end
	if p then
		local surface = game.surfaces[memory.sea_name]
		if not surface and surface.valid then return end

		local spits_here = surface.find_entities_filtered{position = p, radius = 0.5, name = 'acid-splash-fire-spitter-big'}
		if spits_here and #spits_here > 0 then
			for _, s in pairs(spits_here) do
				if s.valid then s.destroy() end
			end
		end

		local p2 = surface.find_non_colliding_position('medium-biter', p, 10, 0.2)
		if not p2 then return end
		local name = Common.get_random_unit_type(memory.evolution_factor + Balance.kraken_spawns_base_extra_evo)
		surface.create_entity{name = name, position = p2, force = memory.enemy_force_name}
		Effects.kraken_effect_2(surface, p2)

		local evo_increase = Balance.kraken_evo_increase_per_shot()

		if not memory.kraken_evo then memory.kraken_evo = 0 end
		memory.kraken_evo = memory.kraken_evo + evo_increase
		Common.increment_evo(evo_increase)
	end
end


function Public.try_spawn_kraken()
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[memory.sea_name]
	if not (surface and surface.valid) then return end -- check sea still exists

	if not memory.active_sea_enemies then memory.active_sea_enemies = {} end
	if not memory.active_sea_enemies.krakens then memory.active_sea_enemies.krakens = {} end

	local possible_slots = {}
	for i = 1, Public.kraken_slots do
		if not memory.active_sea_enemies.krakens[i] then
			possible_slots[#possible_slots + 1] = i
		end
	end

	if #possible_slots > 0 then
		local kraken_id = possible_slots[Math.random(#possible_slots)]
		-- if _DEBUG then game.print('spawning kraken in slot ' .. kraken_id) end
		local p = kraken_positions[kraken_id].first
		memory.active_sea_enemies.krakens[kraken_id] = {
			state = 'submerged',
			position = p,
			max_health = Balance.kraken_health(),
			spawner_entity = nil,
			frame = nil,
		}

		Task.set_timeout_in_ticks(10, kraken_tick_token, {crew_id = memory.id, kraken_id = kraken_id, step = 1, substep = 1})
	end
end

function Public.kraken_move(kraken_id, new_p, new_frame)
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[memory.sea_name]
	if not surface and surface.valid then return end -- check sea still exists
	local kraken_data = memory.active_sea_enemies.krakens[kraken_id]

	local kraken_tile = CoreData.kraken_tile

	local old_p = kraken_data.position
	local old_frame = kraken_data.frame

	local new_p_2 = {x = Math.ceil(new_p.x), y = Math.ceil(new_p.y)}
	local old_p_2 = {x = Math.ceil(old_p.x), y = Math.ceil(old_p.y)}

	local new_tile_positions = Common.tile_positions_from_blueprint_arrayform(kraken_bps[new_frame], Utils.psum{new_p_2, {x = -16, y = -16}})
	local old_tile_positions = {}
	if old_frame then
		old_tile_positions = Common.tile_positions_from_blueprint_arrayform(kraken_bps[old_frame], Utils.psum{old_p_2, {x = -16, y = -16}})
	end

	local new_tile_positions2 = Utils.exclude_position_arrays(new_tile_positions, old_tile_positions)

	local tiles1 = {}
	for x, xtab in pairs(new_tile_positions2) do
		for y, _ in pairs(xtab) do
		tiles1[#tiles1 + 1] = {name = kraken_tile, position = {x = x, y = y}}
		end
	end
	surface.set_tiles(tiles1)

	if kraken_data.spawner_entity and kraken_data.spawner_entity.valid then
		kraken_data.spawner_entity.teleport(new_p_2.x - old_p_2.x, new_p_2.y - old_p_2.y)
	else
		kraken_data.spawner_entity = surface.create_entity{name = 'biter-spawner', position = new_p_2, force = memory.enemy_force_name}
		Common.new_healthbar(true, kraken_data.spawner_entity, kraken_data.max_health, kraken_id, kraken_data.max_health, 0.8)
	end

	if old_frame then --cleanup old tiles
		local old_tile_positions2 = Utils.exclude_position_arrays(old_tile_positions, new_tile_positions)
		local tiles2 = {}
		for x, xtab in pairs(old_tile_positions2) do
			for y, _ in pairs(xtab) do
				tiles2[#tiles2 + 1] = {name = 'deepwater', position = {x = x, y = y}}
			end
		end
		surface.set_tiles(tiles2, true, false)
	end

	kraken_data.position = new_p
	kraken_data.frame = new_frame
end

function Public.kraken_die(kraken_id)
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[memory.sea_name]
	if not surface and surface.valid then return end -- check sea still exists
	local kraken_data = memory.active_sea_enemies.krakens[kraken_id]

	if kraken_data.spawner_entity and kraken_data.spawner_entity.valid then
		kraken_data.spawner_entity.destroy()
	end
	Effects.kraken_effect_5(surface, kraken_data.position)

	local tiles2 = {}
	for x = -16, 16 do
		for y = -16, 16 do
			tiles2[#tiles2 + 1] = {name = 'deepwater', position = Utils.psum{kraken_data.position, {x = x, y = y}}}
		end
	end
	surface.set_tiles(tiles2, true, false)

	memory.active_sea_enemies.krakens[kraken_id] = nil

	local reward_items = Balance.kraken_kill_reward_items()
	Common.give_items_to_crew(reward_items)

	local reward_fuel = Balance.kraken_kill_reward_fuel()
	memory.stored_fuel = memory.stored_fuel + reward_fuel

	local message = {'pirates.granted_3', {'pirates.granted_kraken_kill'}, Math.floor(reward_items[2].count/100)/10 .. 'k [item=coin]', reward_fuel .. ' [item=coal]', reward_items[1].count .. ' [item=sulfuric-acid-barrel]'}
	Common.notify_force_light(memory.force,message)

	memory.playtesting_stats.coins_gained_by_krakens = memory.playtesting_stats.coins_gained_by_krakens + reward_items[2].count
end

local event = require 'utils.event'
event.add(defines.events.on_entity_destroyed, on_entity_destroyed)

return Public

