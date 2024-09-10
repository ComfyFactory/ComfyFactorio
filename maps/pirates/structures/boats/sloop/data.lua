-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Public = {}

-- NOTE:

Public.display_name = 'sloop'
Public.tile_areas = {
	{{-1,-1},{0,1}},
	{{-2,-2},{-1,2}},
	{{-3,-3},{-2,3}},
	{{-4,-4},{-3,4}},
	{{-5,-5},{-4,5}},
	{{-6,-6},{-5,6}},
	{{-7,-7},{-6,7}},
	{{-8,-8},{-7,8}},
	{{-9,-9},{-8,9}},
	{{-10,-10},{-9,10}},
	{{-11,-11},{-10,11}},
	{{-67,-12},{-11,12}},

	{{-41,-13},{-38,-12}},
	{{-41,12},{-38,13}},
}
Public.width = 67
Public.height = 24
Public.spawn_point = {x = -47.5, y = 0}
Public.parrot_resting_position = {x = -69, y = 0}
Public.right_gate_tile_areas = {
		{{-53,11},{-44,12}},
		{{-24,11},{-15,12}},
}
Public.left_gate_tile_areas = {
		{{-53,-12},{-44,-11}},
		{{-24,-12},{-15,-11}},
}
Public.leftmost_gate_position = -53
Public.rightmost_gate_position = -15
Public.upmost_gate_position = -12
Public.downmost_gate_position = 12
Public.areas_infront = {
	{{0,-1},{1,1}},

	{{-1,-2},{0,-1}},
	{{-1,1},{0,2}},
	{{-2,-3},{-1,-2}},
	{{-2,2},{-1,3}},
	{{-3,-4},{-2,-3}},
	{{-3,3},{-2,4}},
	{{-4,-5},{-3,-4}},
	{{-4,4},{-3,5}},
	{{-5,-6},{-4,-5}},
	{{-5,5},{-4,6}},
	{{-6,-7},{-5,-6}},
	{{-6,6},{-5,7}},
	{{-7,-8},{-6,-7}},
	{{-7,7},{-6,8}},
	{{-8,-9},{-7,-8}},
	{{-8,8},{-7,9}},
	{{-9,-10},{-8,-9}},
	{{-9,9},{-8,10}},
	{{-10,-11},{-9,-10}},
	{{-10,10},{-9,11}},
	{{-11,-12},{-10,-11}},
	{{-11,11},{-10,12}},

	{{-38,-13},{-37,-12}},
	{{-38,12},{-37,13}},
}
Public.areas_behind = {
	{{-68,-12},{-67,12}},

	{{-42,-13},{-41,-12}},
	{{-42,12},{-41,13}},
}
Public.areas_offright = {
	{{-1,1},{0,2}},
	{{-2,2},{-1,3}},
	{{-3,3},{-2,4}},
	{{-4,4},{-3,5}},
	{{-5,5},{-4,6}},
	{{-6,6},{-5,7}},
	{{-7,7},{-6,8}},
	{{-8,8},{-7,9}},
	{{-9,9},{-8,10}},
	{{-10,10},{-9,11}},
	{{-11,11},{-10,12}},

	{{-38,12},{-11,13}},
	{{-67,12},{-41,13}},

	{{-41,13},{-38,14}},
}
Public.areas_offleft = {
	{{-1,-2},{0,-1}},
	{{-2,-3},{-1,-2}},
	{{-3,-4},{-2,-3}},
	{{-4,-5},{-3,-4}},
	{{-5,-6},{-4,-5}},
	{{-6,-7},{-5,-6}},
	{{-7,-8},{-6,-7}},
	{{-8,-9},{-7,-8}},
	{{-9,-10},{-8,-9}},
	{{-10,-11},{-9,-10}},
	{{-11,-12},{-10,-11}},

	{{-38,-13},{-11,-12}},
	{{-67,-13},{-41,-12}},

	{{-41,-14},{-38,-13}},
}
Public.entities = {
	static = {
		pos = { x = -34, y = 0},
		-- This bp should only contain boxes, otherwise upgrading boxes (in harder difficulties won't work)
		bp_str = [[0eNqVmutqGzEQhd9FvzdldZf8s69RQnGSpTU4a2M7bUPwu3edlCbQHs85EAg264+Z1ZE0txd3t32a9ofNfHKrF3ec1/ub0+7m22HzcPn8y61KHdyzW4V0Htzmfjcf3erL8uDm27zeXh45Pe8nt3Kb0/ToBjevHy+ffu52D9N8c/99Op7c5Yfzw7Sw/Pl2cNN82pw20xvn9cPz1/np8W46LA/8nzC4/e64/Gg3/zFq/JRfrVr+n8/DP5hAYvx1TCQx4TomkZh4HZNJTLqOKSQmX8dUElOuYxq7UsaKd5ZjLLkfWZCx6J6VsjeW3bNiDhaIlrOx9J4VdDCk6FlJh26AWFFHa/lZWUdDj54VdrRWjVV2NAQZWGVHY/kDq+xoLH9glR2rAWKVHY3TKNBHtSHIwCo7NgPEKjsZyg6sspN1t7LKTpYgWWVnY4tEVtnZsCiyys6GsiOr7GzstRjFgMgDThI5AXCy6hgyiA5DimFRVUHIIlbXuRoWdfFdRxA2jiInAY5XHUMG0apuhkVRBSGLWFnnbliUxXedAaeInAI4VXUMGcSqunjDIlbVxXAtjyoIuJbVZLECThA5DXDo+LoaIDq+bgYoq4uPXhEr6xINi+i0MRigpoKQa+pp3UFarZ7WHuXndOKYLRJdBkkWiZW2rxaJ1bYvFimrsTokFTVYh6SqRuuQ1NRwHZK6Gq8jUh3VUwDslcpKvCQDxCq8WHulyoE2iP6qGml7EI/WLO9eRCoyCTknJ5HQJl3fyKYuawCQ2iiTgHeNFnixSEEmIe9khYNYuckKB9F7y/JNh0i6whGpyvcTIjX5zkSkLt90gNRH+aZDJC/fdIgU5JMAkaJ80yFSUm86tFl6Vq86SCry6YS8q+oGBqlcbyoIpHK9q6kTIvlxVJMnjPJq+oRelB+DLChoVVQzH4xKMgo6qBZQfEMktYTiKyLJRRRslFxGwVbJhRSI8nIpBTro1WJKgH1PtZziOyJFuSILjZILhdiqrBYvMaqoKOygeqaHgEjqoR48InW1WQCNopuX71JAVtHty/fOA0QFGQUdVKPzEBEpicMvmJTF+RdMKuIIDCZVcQoGk5o4CINJXZyFgSS6k+lNGdC9TG/qgO5melMIdD/Tm0qgW5rBRmV1oAWjijpkg1FVnY7BqKaOtWBUV0dtIIpucEZTV3SPM5pioLuc0VxBus8ZTV3Rnc6/szIYldVpGYwqamUCo6pamsCoptYmMKqrxQmIovueyVQ73fnMptrp5me2rYpyuAdRSR3EeUPdDm9zyKsPU82D267vpu3y3ecP3/2YDsdXTGiL9HqouSx/qZ3PvwGS43Tx]],
	},
	inaccessible = {
		pos = { x = -60, y = 0},
		bp_str = [[]],
	},
}
Public.EEIs = {
	{x = -64, y = -10},
	{x = -64, y = 10},
}
Public.upstairs_poles = {
	{x = -39.0, y = -5.0},
	{x = -39.0, y = 5.0},
}
Public.power1_rendering_position = {x = -64, y = 9.5}
Public.power2_rendering_position = {x = -64, y = -10.5}
Public.upstairs_fluid_storages = {
	{x = -58.5, y = -10.5},
	{x = -58.5, y = 10.5},
}

Public.cannons = {
	{x = -39.5, y = 11.5},
	{x = -39.5, y = -11.5},
}
Public.cabin_car = {x = -51, y = 0}
Public.steering_boxes = {
	left = {x = -2.5, y = -1.5},
	right = {x = -2.5, y = 1.5}
}
Public.crowsnest_center = {x = -26.5, y = 0}
Public.entercrowsnest_cars = {
	left = {x = -25, y = 0},
	right = {x = -28, y = 0}
}
Public.loco_pos = {x = -39, y = 0}
Public.deck_whitebelts_lrtp_order = {
	{x = -52.5, y = -11.5, direction = defines.direction.north, type = 'input'},
	{x = -51.5, y = -11.5, direction = defines.direction.north, type = 'input'},
	{x = -50.5, y = -11.5, direction = defines.direction.north, type = 'input'},
	{x = -49.5, y = -11.5, direction = defines.direction.north, type = 'input'},
	{x = -18.5, y = -11.5, direction = defines.direction.south, type = 'input'},
	{x = -17.5, y = -11.5, direction = defines.direction.south, type = 'input'},
	{x = -16.5, y = -11.5, direction = defines.direction.south, type = 'input'},
	{x = -15.5, y = -11.5, direction = defines.direction.south, type = 'input'},
	{x = -52.5, y = -2.5, direction = defines.direction.south, type = 'output'},
	{x = -51.5, y = -2.5, direction = defines.direction.south, type = 'output'},
	{x = -50.5, y = -2.5, direction = defines.direction.south, type = 'output'},
	{x = -49.5, y = -2.5, direction = defines.direction.south, type = 'output'},
	{x = -52.5, y = 2.5, direction = defines.direction.north, type = 'input'},
	{x = -51.5, y = 2.5, direction = defines.direction.north, type = 'input'},
	{x = -50.5, y = 2.5, direction = defines.direction.north, type = 'input'},
	{x = -49.5, y = 2.5, direction = defines.direction.north, type = 'input'},
	{x = -52.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -51.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -50.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -49.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -18.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -17.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -16.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -15.5, y = 11.5, direction = defines.direction.south, type = 'output'},
}

Public.crewname_rendering_position = {x = -67, y = -18.5}
Public.comfy_rendering_position = {x = -59.5, y = 0}

Public.landingtrack = {
	offset = {x = -17, y = 0},
	bp = [[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yuiGrG7K6IasbsrohqxuyuiGrG7K6Masbs7oxqxuzujGrG7O6Masbs7oxqxuzujGrG7O6Masbs7ohqxuyuiGrG7K6IasbsrohqxuyuiGrG7K6Masbs7oxqxuzujGrG7O6Masbs7oxqxuzujGrG7O6Masbs7ohqxuyuiGrG7K6IasbsrohqxuyuiGrG7K6Masbs7oxqxuzujGrG7O6Masbs7oxqxuzujGrG7O6Masbs7ohqxuyuiGrG7K6IasbsrohqxuyuiGrG7K6Masbs7oxqxuzujGrG7O6Masbs7oxqxuzujGrG7O6Masbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7pLVnfJ6i5Z3SWru2R1l6zuktVdsrpLVnfJ6q5Z3TWru2Z116zumtVds7prVnfN6q5Z3TWru2Z116zumtVds7p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]],
}

Public.upgrade_chests = {
	pos = { x = -67, y = -12},
	-- bp_str = [[0eNqVmt1qG0EMRt9lrjdlNZpfX/Y1SihOsrQGZ23sTdsQ/O61k9IE2s/SB4Fg4xykneOJZqSXcLd9mvaHzbyE1Us4zuv9zbK7+XbYPFxe/wqrUofwHFYxnYawud/Nx7D6cv7g5tu83l4+sjzvp7AKm2V6DEOY14+XVz93u4dpvrn/Ph2XcPnD+WE6s+R0O4RpXjbLZnrjvL54/jo/Pd5Nh/MH/k8Ywn53PP/Rbv4T1Pgpv0Z1/n06Df9gohMj1zHqxMTrmOTE6HVMdmLSdUxxYvJ1THViynVM866UseLdyzGWXEYvyFh08aosxrKLV+Zogdw6G0svXqGjoaJ4lY7dAHmlVmv5vVqr4aN4xVZr1bxmqyFk9JqtxvJHr9lqLH/0mq3VAHnNVmM3iu6t2hAyes3WZoC8ZifD7Og1O1n/W71mJ0tIr9nZ+Iqo1+xsRKRes7NhtnrNzsZ3TZUsiARwEsmJgJPZxFBA7jKkGBFVFoQi8nqdqxFRJ5+1grJxJDkJcIRNDAXktroZESkLQhF5tc7diCiTzzoDTiE5BXAqmxgKyGt1ESMir9XFSC2PLAikltnDYgWcSHIa4Ljr62qA3PV1M0CZXXz0iLxaFzUich8bowFqLAilxu7WHRyr2d1a0Plc2BoUkiJbhEKSslUoJCW2DIWkzNahkETbjRxw250MkNvubOXG6i2gqqm036DOqkIbgEiRJqHklH7eiJRoEsrOvXkXi1RoEsqushKAeqs2FgQqwNrp3RKQ2kjvlogk9G6JSLzhiKT0bolIid0tkQQts9slJBX6W4eyow0HZW6jDQdlbutsWYlIfWTrSkgStrBEj6lH2iYUk7IVISQlmoSyY4+VAsrdzp4rBZS7nT5YwpDokyWMiT5aIpKM9OESpScje7yMsKXEHjClI5LSd1QwKPrqBEeV2escjCosCifI7uQxIhK7lUdBpM5en8Kg3I3KdxVQVO5W5ftdLERFGgUTZK++oyJSIscBMCmTEwGYVMihAEyq5FwAJjVyNACTOjkdAEnurqWYGrj7lmJ64O5ciimCu3cppgnu7mW0UZlt8WNUYccOMKqy8wIY1dhGP0Z1dvgAotydTDW9cvcy1ZTB3c1UcwXd/Uw1vXK3NP9OD2BUZucHMKqw9xEYVdkLCYxq7I0ERnX2SgKi3A3OZNru73Gatvu7nHZUSpd7EJXY0YQ31O3wNpm5+jDnOYTt+m7ant/7/OG9H9Ph+IqJTVLtseZy/kntdPoNku6GLw==]],
}

return Public