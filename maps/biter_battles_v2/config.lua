--BITER BATTLES CONFIG--

bb_config = {
	--TEAM SETTINGS--
	["team_balancing"] = true,			--Should players only be able to join a team that has less or equal members than the opposing team?
	["only_admins_vote"] = false,		--Are only admins able to vote on the global difficulty?
	
	--Optional custom team names, can also be modified via "Team Manager"
	["north_side_team_name"] = "Team North",		
	["south_side_team_name"] = "Team South",	

	--GENERAL SETTINGS--
	["blueprint_library_importing"] = false,		--Allow the importing of blueprints from the blueprint library?
	["blueprint_string_importing"] = false,		--Allow the importing of blueprints via blueprint strings?

	--MAP PREGENERATION--
	["map_pregeneration_radius"] = 24,	 		--3 horizontal radiuses in chunks to pregenerate at the start of the map.
	["on_init_pregen"] = true,	 					--Generate some chunks on_init?
	["fast_pregen"] = false,	 						--Force fast pregeneration.
	
	--TERRAIN OPTIONS--
	["border_river_width"] = 29,						--Approximate width of the horizontal impassable river seperating the teams. (values up to 100)
	["builders_area"] = true,							--Grant each side a peaceful direction with no nests and biters?
	["random_scrap"] = true,							--Generate harvestable scrap around worms randomly?
	
	--BITER SETTINGS--
	["max_active_biters"] = 2500,					--Maximum total amount of attacking units per side.
	["max_group_size"] = 256,						--Maximum unit group size.
	["biter_timeout"] = 54000,						--Time it takes in ticks for an attacking unit to be deleted. This prevents perma stuck units.	
	["bitera_area_distance"] = 416					--Distance to the biter area.
}