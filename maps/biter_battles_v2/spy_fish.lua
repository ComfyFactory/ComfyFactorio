local function get_border_cords(f)
	local a = {{-1000,-1000},{1000,-10}}
	if f == "south" then a = {{-1000,10},{1000,1000}} end
	local entities = game.surfaces["biter_battles"].find_entities_filtered{area=a,force=f}
	if not entities then return end
	local x_top = entities[1].position.x; local y_top = entities[1].position.y; local x_bot = entities[1].position.x; local y_bot = entities[1].position.y	
	for _, e in pairs(entities) do	
		if e.position.x < x_top then x_top = e.position.x end
		if e.position.y < y_top then y_top = e.position.y end
		if e.position.x > x_bot then x_bot = e.position.x end
		if e.position.y > y_bot then y_bot = e.position.y end
	end
	global.force_area[f] = {}
	global.force_area[f].x_top	= x_top
	global.force_area[f].y_top	= y_top
	global.force_area[f].x_bot	= x_bot
	global.force_area[f].y_bot	= y_bot	
end

local function spy_fish(player)
	local duration_per_unit = 1800 
	local i2 = player.get_inventory(defines.inventory.player_main)
	local owned_fishes = i2.get_item_count("raw-fish")
	owned_fishes = owned_fishes + i2.get_item_count("raw-fish")
	if owned_fishes == 0 then 
		player.print("You have no fish in your inventory.",{ r=0.98, g=0.66, b=0.22})
	else
		local x = i2.remove({name="raw-fish", count=1})
		if x == 0 then i2.remove({name="raw-fish", count=1}) end
		local enemy_team = "south"
		if player.force.name == "south" then enemy_team = "north" end													 
		if global.spy_fish_timeout[player.force.name] - game.tick > 0 then 
			global.spy_fish_timeout[player.force.name] = global.spy_fish_timeout[player.force.name] + duration_per_unit
			player.print(math.ceil((global.spy_fish_timeout[player.force.name] - game.tick) / 60) .. " seconds of enemy vision left.", { r=0.98, g=0.66, b=0.22})
		else
			--get_border_cords(enemy_team)
			game.print(player.name .. " sent a fish to spy on " .. enemy_team .. " team!", {r=0.98, g=0.66, b=0.22})			
			global.spy_fish_timeout[player.force.name] = game.tick + duration_per_unit							
		end		
	end
end

return spy_fish