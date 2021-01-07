--[[
Exchange Strings

>>>eNp1UT1oFEEUfi/nkcsJonBNwMQrUtjsES/aHOFmTCMp1M5+b
29OB/Z2ztldSLRwixQWQpo0pkmKNCZgJ2gXsVHQIGpjd5LGwiJBE
AvhnNnd2VvX5IN5fPO9/xmAC3AbYuxTgKhdOeMI201vRMmk6ojBg
ElLSJaXpxwZdpkluAqO6N7uLtGeKvNYf9Xq2D7TskqI5QqXwitWK
PuB8P5VAsmYnyRGba2eDaXt8bCf5EZZJODOwZ3X0dos6DN6BPXRS
B/Fhso/hBQqA5WWonTZEV4ghWv5LAi4d7dlhyutnmT3Q+Y5q61+6
AZ84HImKwuN+RgzxYy+4H4QStbqcNufsuYbzWs6zjo17sTyVxoLM
cqOy3s9gPp1dZb01oj4sPb8xrcHGwSTqRs0JUepst8xyrIht+ipr
jlDrubqJN1/5kjSNFAt0qgKHZPEuaadiMf3Dh+/+P2ljX+eHX+62
aEEj4yCOKkScCIzm081XplVwNQcktT1leCH9xo/CJZ1Rk2b7SfKR
M0JwPPnzLV+EcxobVOmRrEX45fZ5NCQz6S4h3qIRV18Vpu32sQNs
8kwoXSdIr1kvNPjEJXfhPwM3fGG70zbN7n+hUH+/4j8HgVljp7wD
VXdsJuZ76VsGvWeHyfNjW7REoyhvvvAetn9CzJb1cQ=<<<
]]
local random = math.random
local Alert = require 'utils.alert'
require "player_modifiers"
require "modules.rocks_broken_paint_tiles"
require "modules.rocks_heal_over_time"
require "modules.rocks_yield_ore_veins"
require "modules.no_deconstruction_of_neutral_entities"
local MT = require "maps.amap.basic_markets"
local asdasd = require 'modules.rpg.table'
local Loot = require "maps.amap.loot"
local get_noise = require "utils.get_noise"
local Player_modifiers = require "player_modifiers"
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local Public = {}
local BiterRolls = require 'modules.wave_defense.biter_rolls'
local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local size_of_rock_raffle = #rock_raffle
local Pets = require 'maps.amap.biter_pets'
local function place_entity(surface, position)
	if math_random(1, 3) ~= 1 then
		surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = position, force = "neutral"})
	end
end

local function is_scrap_area(noise)
	if noise > 0.63 then return end
	if noise < -0.63 then return end
	if noise > 0.35 then return true end	
	if noise < -0.35 then return true end
end

local function hidden_treasure(player, entity)

	local rpg = asdasd.get('rpg_t')

    local magic = rpg[player.index].magicka

       local msg = '哦，看啊，你找到了一个宝藏！'
   
	   Alert.alert_player(player, 5, msg)
        
	
		Loot.add_rare(entity.surface, entity.position, 'wooden-chest', magic)


end

local function move_away_things(surface, area)
	for _, e in pairs(surface.find_entities_filtered({type = {"unit-spawner", "turret", "unit", "tree"}, area = area})) do
		local position = surface.find_non_colliding_position(e.name, e.position, 128, 4)
		if position then 
			surface.create_entity({name = e.name, position = position, force = "enemy"})
			e.destroy()
		end
	end
end

local vectors = {{0,0}, {1,0}, {-1,0}, {0,1}, {0,-1}}
local function hidden_biter_pet(player, entity)

    local pos = entity.position

    BiterRolls.wave_defense_set_unit_raffle(math.sqrt(pos.x ^ 2 + pos.y ^ 2) * 0.25)
    local unit
    if random(1, 3) == 1 then
        unit = entity.surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = pos})
    else
        unit = entity.surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = pos})
    end
    Pets.biter_pets_tame_unit(game.players[player.index], unit, true)
end
local function hidden_biter(player, entity)


    local pos = entity.position

    BiterRolls.wave_defense_set_unit_raffle(math.sqrt(pos.x ^ 2 + pos.y ^ 2) * 0.25)

    local unit
    if random(1, 3) == 1 then

        unit = entity.surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = pos})
    else
        unit = entity.surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = pos})
    end
end
local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.type ~= "simple-entity" then return end
	local surface = entity.surface
	for _, v in pairs(vectors) do
		local position = {entity.position.x + v[1], entity.position.y + v[2]}
		if not surface.get_tile(position).collides_with("resource-layer") then 
			surface.set_tiles({{name = "landfill", position = position}}, true)
		end
	end
	if event.player_index then game.players[event.player_index].insert({name = "coin", count = 1}) end
	local player = game.players[event.player_index]
	--修复挖矿石路
	local rpg = asdasd.get('rpg_t')
	local rpg_char = rpg[player.index]
	if rpg_char.stone_path then
          
		  entity.surface.set_tiles({{name = 'stone-path', position = entity.position}}, true)
        end
	
	--挖出汽车
if random(1,712) < 2 then 
	local position = {entity.position.x , entity.position.y }
	--local player = game.players[event.player_index]
	surface.create_entity({name = 'car', position = position, force = 'player'})
           Public.unstuck_player(player.index)
           local msg = ({'found a car', 'you'})
            Alert.alert_player(player, 15, msg)
    end
	--挖出虫巢
	
if random(1,120) < 2 then

    local position = {entity.position.x , entity.position.y }
	local player = game.players[event.player_index]
	surface.create_entity({name = 'biter-spawner', position = position, force = 'enemy'})
	Public.unstuck_player(player.index)
	end 	
	--挖出宝藏
	if random(1,150)  < 2 then 

	local player = game.players[event.player_index]

	hidden_treasure(player,entity)

	end 
	--挖出宠物
	if random(1,170)  < 3 then 
	local player = game.players[event.player_index]
	hidden_biter_pet(player,entity)
	end
	--来挖个虫子
	if random(1,100)  < 3 then 
	local player = game.players[event.player_index]
	hidden_biter(player,entity)
	end
end

local function on_entity_died(event)	
	if not event.entity.valid then return end
	on_player_mined_entity(event)
end

--图块生成时
local function on_chunk_generated(event)	
	local surface = event.surface
	local seed = surface.map_gen_settings.seed
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	local set_tiles = surface.set_tiles
	local get_tile = surface.get_tile
	local position
	local noise
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do			
			position = {x = left_top_x + x, y = left_top_y + y}				
			if not get_tile(position).collides_with("resource-layer") then 
				noise = get_noise("scrapyard", position, seed)
				if is_scrap_area(noise) then
					set_tiles({{name = "dirt-" .. math_floor(math_abs(noise) * 12) % 4 + 3, position = position}}, true)
					if x+y > 33 and x+y < 40 then
					local b = math_random(1,200)
					--宝藏
					if b < 3 then 
					local chest = 'iron-chest'
					Loot.add(surface, position, chest)
					end
					--中立建筑

                   
                     
					--在我上面添加代码
					end
					--商店代码
					if y == 1 then 
					if x == 1 then 
					 local a = math_random(1,8)
					 if a == 1 then 
					 local q =math_abs(position.x)/20
				   	local w =math_abs(position.y)/20
					 local maxs =q+w+15
					-- game.print(maxs)
					 MT.mountain_market(surface,position,maxs)
					end
					end
					end
					
					place_entity(surface, position)
				end
			end				
		end
	end
	
	move_away_things(surface, event.area)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	local modifiers = Player_modifiers.get_table()	
	--modifiers[player.index].character_mining_speed_modifier["caves"] = 3
	Player_modifiers.update_player_modifiers(player)
end
function Public.unstuck_player(index)
    local player = game.get_player(index)
    local surface = player.surface
    local position = surface.find_non_colliding_position('character', player.position, 32, 0.5)
    if not position then
        return
    end
    player.teleport(position, surface)
end
local function on_init()
	global.rocks_yield_ore_maximum_amount = 999
	global.rocks_yield_ore_base_amount = 100
	global.rocks_yield_ore_distance_modifier = 0.025
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)

require "modules.rocks_yield_ore"