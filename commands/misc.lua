commands.add_command(
    'spaghetti',
    'Does spaghett.',
    function(cmd)
        local player = game.player
        local force = game.forces["player"]
        local p

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("You're not admin!", {r = 1, g = 0.5, b = 0.1})
                    return
                end
			else
                p = log
			end
        end
        if cmd.parameter == nil then player.print("Arguments are true/false", {r=0.22, g=0.99, b=0.99}) return end
        if cmd.parameter == "true" then
			game.print("The world has been spaghettified!", {r = 1, g = 0.5, b = 0.1})
			force.technologies["logistic-system"].enabled = false
			force.technologies["construction-robotics"].enabled = false
			force.technologies["logistic-robotics"].enabled = false
			force.technologies["robotics"].enabled = false
			force.technologies["personal-roboport-equipment"].enabled = false
			force.technologies["personal-roboport-mk2-equipment"].enabled = false
			force.technologies["character-logistic-trash-slots-1"].enabled = false
			force.technologies["character-logistic-trash-slots-2"].enabled = false
			force.technologies["auto-character-logistic-trash-slots"].enabled = false
			force.technologies["worker-robots-storage-1"].enabled = false
			force.technologies["worker-robots-storage-2"].enabled = false
			force.technologies["worker-robots-storage-3"].enabled = false
			force.technologies["character-logistic-slots-1"].enabled = false
			force.technologies["character-logistic-slots-2"].enabled = false
			force.technologies["character-logistic-slots-3"].enabled = false
			force.technologies["character-logistic-slots-4"].enabled = false
			force.technologies["character-logistic-slots-5"].enabled = false
			force.technologies["character-logistic-slots-6"].enabled = false
			force.technologies["worker-robots-speed-1"].enabled = false
			force.technologies["worker-robots-speed-2"].enabled = false
			force.technologies["worker-robots-speed-3"].enabled = false
			force.technologies["worker-robots-speed-4"].enabled = false
			force.technologies["worker-robots-speed-5"].enabled = false
			force.technologies["worker-robots-speed-6"].enabled = false
        elseif cmd.parameter == "false" then
			game.print("The world is no longer spaghett!", {r = 1, g = 0.5, b = 0.1})
			force.technologies["logistic-system"].enabled = true
			force.technologies["construction-robotics"].enabled = true
			force.technologies["logistic-robotics"].enabled = true
			force.technologies["robotics"].enabled = true
			force.technologies["personal-roboport-equipment"].enabled = true
			force.technologies["personal-roboport-mk2-equipment"].enabled = true
			force.technologies["character-logistic-trash-slots-1"].enabled = true
			force.technologies["character-logistic-trash-slots-2"].enabled = true
			force.technologies["auto-character-logistic-trash-slots"].enabled = true
			force.technologies["worker-robots-storage-1"].enabled = true
			force.technologies["worker-robots-storage-2"].enabled = true
			force.technologies["worker-robots-storage-3"].enabled = true
			force.technologies["character-logistic-slots-1"].enabled = true
			force.technologies["character-logistic-slots-2"].enabled = true
			force.technologies["character-logistic-slots-3"].enabled = true
			force.technologies["character-logistic-slots-4"].enabled = true
			force.technologies["character-logistic-slots-5"].enabled = true
			force.technologies["character-logistic-slots-6"].enabled = true
			force.technologies["worker-robots-speed-1"].enabled = true
			force.technologies["worker-robots-speed-2"].enabled = true
			force.technologies["worker-robots-speed-3"].enabled = true
			force.technologies["worker-robots-speed-4"].enabled = true
			force.technologies["worker-robots-speed-5"].enabled = true
			force.technologies["worker-robots-speed-6"].enabled = true
	end
end)

commands.add_command(
    'generate_map',
    'Pregenerates map.',
    function(cmd)
        local player = game.player
        local p

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("You're not admin!", {r = 1, g = 0.5, b = 0.1})
                    return
                end
			else
                p = log
			end
        end
        if cmd.parameter == nil then player.print("Must specify radius!", {r=0.22, g=0.99, b=0.99}) return end
        local radius = cmd.parameter
		local surface = game.players[1].surface
			if surface.is_chunk_generated({radius, radius}) then
				game.print("Map generation done!", {r=0.22, g=0.99, b=0.99})
			return
		end
		surface.request_to_generate_chunks({0,0}, radius)
		surface.force_generate_chunk_requests()
		for _, pl in pairs(game.connected_players) do
			pl.play_sound{path="utility/new_objective", volume_modifier=1}
		end
		game.print("Map generation done!", {r=0.22, g=0.99, b=0.99})
end)

commands.add_command(
    'dump_layout',
    'Dump the current map-layout.',
    function()
        local player = game.player
        local p

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("You're not admin!", {r = 1, g = 0.5, b = 0.1})
                    return
                end
			else
                p = log
			end
        end
		local surface = game.players[1].surface
		game.write_file("layout.lua", "" , false)

		local area = {
				left_top = {x = 0, y = 0},
				right_bottom = {x = 32, y = 32}
		}

		local entities = surface.find_entities_filtered{area = area}
		local tiles = surface.find_tiles_filtered{area = area}

		for _, e in pairs(entities) do
			local str = "{position = {x = " ..  e.position.x
			str = str .. ", y = "
			str = str .. e.position.y
			str = str .. '}, name = "'
			str = str .. e.name
			str = str .. '", direction = '
			str = str .. tostring(e.direction)
			str = str .. ', force = "'
			str = str .. e.force.name
			str = str .. '"},'
			if e.name ~= "character" then
				game.write_file("layout.lua", str .. '\n' , true)
			end
		end

		game.write_file("layout.lua",'\n' , true)
		game.write_file("layout.lua",'\n' , true)
		game.write_file("layout.lua",'Tiles: \n' , true)

		for _, t in pairs(tiles) do
			local str = "{position = {x = " ..  t.position.x
			str = str .. ", y = "
			str = str .. t.position.y
			str = str .. '}, name = "'
			str = str .. t.name
			str = str .. '"},'
			game.write_file("layout.lua", str .. '\n' , true)
		end
end)

commands.add_command(
    'creative',
    'Enables creative_mode.',
    function()
        local player = game.player
        local p

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("You're not admin!", {r = 1, g = 0.5, b = 0.1})
                    return
                end
			else
                p = log
			end
        end
        local starting_items = {
            {name = 'submachine-gun', count = 1},
            {name = 'uranium-rounds-magazine', count = 200},
            {name = 'construction-robot', count = 250},
            {name = 'logistic-robot', count = 250},
            {name = 'electric-energy-interface', count = 50},
            {name = 'substation', count = 50},
            {name = 'roboport', count = 10},
            {name = 'infinity-chest', count = 10},
            {name = 'raw-fish', count = 200},
            {name = 'infinity-pipe', count = 10},
            {name = 'heat-interface', count = 10},
            {name = 'selection-tool', count = 1}
        }
        game.print(player.name .. " has activated creative-mode!", {r=0.22, g=0.99, b=0.99})
        log(player.name .. " has activated creative-mode!")
        player.cheat_mode = true
        player.insert{name="power-armor-mk2", count = 1}
        local p_armor = player.get_inventory(5)[1].grid
        p_armor.put({name = "fusion-reactor-equipment"})
        p_armor.put({name = "fusion-reactor-equipment"})
        p_armor.put({name = "fusion-reactor-equipment"})
        p_armor.put({name = "exoskeleton-equipment"})
        p_armor.put({name = "exoskeleton-equipment"})
        p_armor.put({name = "exoskeleton-equipment"})
        p_armor.put({name = "energy-shield-mk2-equipment"})
        p_armor.put({name = "energy-shield-mk2-equipment"})
        p_armor.put({name = "energy-shield-mk2-equipment"})
        p_armor.put({name = "energy-shield-mk2-equipment"})
        p_armor.put({name = "personal-roboport-mk2-equipment"})
        p_armor.put({name = "night-vision-equipment"})
        p_armor.put({name = "battery-mk2-equipment"})
        p_armor.put({name = "battery-mk2-equipment"})
        for _, item in pairs(starting_items) do
            player.insert(item)
        end
end)