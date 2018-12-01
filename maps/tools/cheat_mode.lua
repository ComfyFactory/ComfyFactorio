function cheat_mode()
	local surface = game.players[1].surface
	game.player.cheat_mode=true
	game.players[1].insert({name="power-armor-mk2"})
	game.players[1].insert({name="fusion-reactor-equipment", count=4})
	game.players[1].insert({name="personal-laser-defense-equipment", count=8})
	game.players[1].insert({name="rocket-launcher"})		
	game.players[1].insert({name="explosive-rocket", count=200})	
	game.players[1].insert({name="coin", count = 100000})
	game.players[1].insert({name="loader"})
	game.players[1].insert({name="fast-loader"})
	game.players[1].insert({name="express-loader"})
	game.players[1].insert({name="infinity-chest"})
	game.players[1].insert({name="computer", count=2})
	game.players[1].insert({name="raw-fish", count=2000})
	game.players[1].insert({name="submachine-gun", count=1})
	game.players[1].insert({name="uranium-rounds-magazine", count=200})
	game.players[1].insert({name="steel-chest", count=200})
	game.players[1].insert({name="explosives", count=1000})
	game.forces.player.manual_mining_speed_modifier = 100
	game.forces.player.character_reach_distance_bonus = 10000
	game.speed = 1.5
	surface.daytime = 1
	surface.freeze_daytime = 1
	game.player.force.research_all_technologies()
	game.forces["enemy"].evolution_factor = 1
	local chart = 200	
	game.forces["player"].chart(surface, {lefttop = {x = chart*-1, y = chart*-1}, rightbottom = {x = chart, y = chart}})			
end