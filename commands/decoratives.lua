function generate_decoratives_for_all_existing_chunks()
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end
	
	for _, surface in pairs(game.surfaces) do	
		for chunk in surface.get_chunks() do		
			surface.regenerate_decorative(decorative_names, {chunk})
		end
	end
end