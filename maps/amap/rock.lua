local WPT = require 'maps.amap.table'
local Event = require 'utils.event'
local Public = {}
local Alert = require 'utils.alert'
local WD = require 'modules.wave_defense.table'
local RPG = require 'modules.rpg.table'
local wave_defense_table = WD.get_table()
local Task = require 'utils.task'
function Public.spawn(surface, position)
    local this = WPT.get()
	this.rock = surface.create_entity{name = "rocket-silo", position = position, force=game.forces.player}

    this.rock.minable = false
    game.forces.player.set_spawn_position({0,0}, surface)
end

function Public.market(surface)
local market = surface.create_entity{name = "market", position = {x=0, y=-10}, force=game.forces.player}
	local market_items = {
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = "raw-fish", count = 1}},
		{price = {{"coin", 1000}}, offer = {type = 'give-item', item = 'car', count = 1}},
		{price = {{"coin", 5000}}, offer = {type = 'give-item', item = 'tank', count = 1}},
		{price = {{"coin", 20000}}, offer = {type = 'give-item', item = 'spidertron', count = 1}}
		--{price = {{"coin", 5000}}, offer = {type = 'give-item', item = 'locomotive', count = 1}},
		--{price = {{"coin", 5000}}, offer = {type = 'give-item', item = 'cargo-wagon', count = 1}},
		--{price = {{"coin", 5000}}, offer = {type = 'give-item', item = 'fluid-wagon', count = 1}}
	}
market.last_user = nil
		if market ~= nil then
			market.destructible = false
			if market ~= nil then
				for _, item in pairs(market_items) do
					market.add_market_item(item)
				end
			end
		end
end
local function abc ()
local this = WPT.get()


wave_defense_table.game_lost = true
    wave_defense_table.target = nil
    this.game_lost = true
    
	game.forces.enemy.set_friend('player', true)
game.print('设置敌军友好')
    game.forces.player.set_friend('enemy', true)
game.print('设置敌军友好')
	--reset_map()
	this.game_reset_tick=5400

end

local function on_rocket_launched(Event)
local wave_number = WD.get('wave_number')
for _, p in pairs(game.connected_players) do
	Alert.alert_player(player, 25, '你通关了，你一定是第一个通关的吧？通关波数：' .. wave_number .. '。NB 就完事了')
    end
local rpg_t = RPG.get('rpg_t')
  for k, p in pairs(game.connected_players) do
	 local player = game.connected_players[k]

	rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+100
    player.insert{name='coin', count = '3000'}
	game.print('科技研发完成，所有玩家奖励100技能点，3000金币。', {r = 0.22, g = 0.88, b = 0.22})
 end	
end
local function on_entity_died(Event)
local this = WPT.get()
if Event.entity == this.rock then

	game.print('游戏失败！游戏稍后将自动重启',{r = 1, g = 0, b = 0, a = 0.5})
	local wave_number = WD.get('wave_number')

	for _, p in pairs(game.connected_players) do

	Alert.alert_player(p, 25, '火箭发射井被摧毁了，游戏失败！你存活了' .. wave_number .. '波，下次好运。')
	
    end
	 local Reset_map = require 'maps.amap.main'.reset_map
	 wave_defense_table.game_lost = true
        wave_defense_table.target = nil
	game.forces.enemy.set_friend('player', true)
--game.print('设置右军友好')
    game.forces.player.set_friend('enemy', true)
--game.print('设置敌军友好')
		Reset_map()
		
	--abc()
end
end
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
Event.add(defines.events.on_entity_died, on_entity_died)
return Public