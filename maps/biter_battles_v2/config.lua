--BITER BATTLES CONFIG FILE--

local config = {
	--MAP PREGENERATION
	["map_pregeneration_radius"] = 32,	 		--Radius in chunks to pregenerate at the start of the map.
	["fast_pregen"] = false,	 							--Force fast pregeneration.
	
	--TEAM SETTINGS
	["north_side_team_name"] = "North",		--Name in the GUI of Team North.
	["south_side_team_name"] = "South",		--Name in the GUI of Team South.
	["team_balancing"] = true,						--Should players only be able to join a team that has less or equal members than the opposing team?
	
	--TERRAIN OPTIONS
	["border_river_width"] = 32						--Approximate width of the horizontal impassable river seperating the teams. (values up to 100)
}

return config