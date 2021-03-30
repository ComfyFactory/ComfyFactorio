--BITER BATTLES CONFIG--

local bb_config = {
    --Optional custom team names, can also be modified via "Team Manager"
    ['north_side_team_name'] = 'Team North',
    ['south_side_team_name'] = 'Team South',
    --TERRAIN OPTIONS--
    ['match_mirror'] = false, --If both sides should match in terrain generation
    ['border_river_width'] = 36, --Approximate width of the horizontal impassable river seperating the teams. (values up to 100)
    ['builders_area'] = true, --Grant each side a peaceful direction with no nests and biters?
    ['random_scrap'] = true, --Generate harvestable scrap around worms randomly?
    --BITER SETTINGS--
    ['max_active_biters'] = 1280, --Maximum total amount of attacking units per side.
    ['max_group_size'] = 288, --Maximum unit group size.
    ['biter_timeout'] = 162000, --Time it takes in ticks for an attacking unit to be deleted. This prevents perma stuck units.
    ['bitera_area_distance'] = 512, --Distance to the biter area.
    --CHEATY STARTS
    ['spawn_turrets_at_silo'] = false, --This spawns two turrets near the silo of each team.
    ['additional_starting_resources'] = false --This gives each starting player 10 burner-mining-drill to skip the start.
}

return bb_config
