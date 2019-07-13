--BITER BATTLES CONFIG FILE--

bb_config = {
	--GENERAL SETTINGS
	["blueprint_library_importing"] = false,		--Allow the importing of blueprints from the blueprint library?
	["blueprint_string_importing"] = false,		--Allow the importing of blueprints via blueprint strings?

	--MAP PREGENERATION
	["map_pregeneration_radius"] = 33,	 		--Radius in chunks to pregenerate at the start of the map.
	["fast_pregen"] = false,	 						--Force fast pregeneration.
	
	--TEAM SETTINGS
	["north_side_team_name"] = "North",		--Name in the GUI of Team North.
	["south_side_team_name"] = "South",		--Name in the GUI of Team South.
	["team_balancing"] = true,						--Should players only be able to join a team that has less or equal members than the opposing team?
	
	--TERRAIN OPTIONS
	["border_river_width"] = 32,						--Approximate width of the horizontal impassable river seperating the teams. (values up to 100)
	
	--BITER SETTINGS
	["max_active_biters"] = 1250,					--Maximum total amount of attacking units per side.
	["biter_timeout"] = 54000						--Time it takes in ticks for an attacking unit to be deleted. This prevents perma stuck units.	
}