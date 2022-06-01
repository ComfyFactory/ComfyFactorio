-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Public = {}
local CoreData = require 'maps.pirates.coredata'

Public.shelter1 = {
	name = 'shelter1',
	width = 18,
	height = 18,
	components = {
		{
			type = 'static',
			force = 'environment',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqV1t1qhDAQBeB3metYzL/6KqUUtxuWgEbRbFtZfPca24tCOyRztSskHzlh4OQBl+Hu5sWHCN0D1tDPVZyq2+Kv6fsTOm4YbOlnZ+DfprBC93ws9LfQD2lJ3GYHHfjoRmAQ+jF9rXEKrvrohwHStnB1SdpfGLgQffTuWzk/ttdwHy9uORb8t5/BPK3Hlin8HKiyT/o8Uvqz7+wPI8oYk2FkGaMyjCpjdIbRZYzMMKaIySm2SMlFaoqU3P22RUpuZnhdxORmhlNHWCOOIDoGcSTtdjBG0RgslSamkohjiI5CHEuLhTENjcFStbRUyGlETWOQ0whOCoUpgqRgkSQtEjLFQtEYZIqFJmXCFENSsEiW1nVYYza0m8GYllaZWPHWtMrEGE6rTIwRpMrEFEmqTExRpMrEFNoAY4ohNeapHO+/853Y/Xp1Mnh3y3puEA1XthVWWqt5rfb9C+jHZns=]],
		},
		{
			type = 'tiles',
			tile_name = CoreData.world_concrete_tile,
			offset = {x = 0, y = 0},
			bp_string = [[0eNqV2s2KG0cYhtF76bUG/FbXX+tWghcTWxiBLA0jOYkxunePbBOySchZNQ1fVy2+s3v62/L76cvh5fV4vi37b8v1/PzydLs8fXo9fny8/7Xs03fL18fjvluOHy7n67L/7W3w+On8fHqM3L6+HJb9crwdPi+75fz8+fF2vV3Oh6c/n0+n5fHZ+ePhcdL9/W65HU+Hn0e8XK7H2/Fy/nXPux/XvLv/fcbbXR9eD7fD2wn/MhwZLjK8ynCV4SbDXYaHDE8Z3mgptkLaYWiJoS2G1pj/uceI6ojqiOqI6ojqiOqI6ojqiOqI6pDqkOqQ6pDqkOqQ6iKqi6guorqI6iKqi6guorqI6iKqi6gupLqQ6kKqC6kupLqQ6lVUr6J6FdWrqF5F9SqqV1G9iupVVK+ieiXVK6leSfVKqldSvZLqKqqrqK6iuorqKqqrqK6iuorqKqqrqK6kupLqSqorqa6kupLqJqqbqG6iuonqJqqbqG6iuonqJqqbqG6kupHqRqobqW6kupHqLqq7qO6iuovqLqq7qO6iuovqLqq7qO6kupPqTqo7qe6kupPqIaqHqB6ieojqIaqHqB6ieojqIaqHqB6kepDqQaoHqR6kepDqKaqnqJ6ieorqKaqnqJ6ieorqKaqnqJ6kepLqSaonqZ6kepLqTVRvonoT1Zuo3kT1Jqo3Ub2J6k1Ub6J6I9Ubqd5I9UaqN1K9WYWhuBiqi6G8GOqLocAYKoyhxBhqjKHIGKqMscwY64yx0BgrjbHUGGyNFhutNlputN5owdGKoyVHa44WHa06YnbE7ojhEcsjpkdrj6H4GKqPofwY6o+hABkqkKEEGWqQoQgZqpCxDBnrkLEQGSuRsRQZa5GhGBmqkaEcGeqRoSAZKpKhJBlqkqEoGaqSsSwZ65KxMBkrk7E0GWuToTgZqpOhPBnqk6FAGSqUoUQZapShSBmqlLFMGeuUsVAZK5WxVBlrlaFYGaqVoVwZ6pWhYBkqlqFkGWqWoWgZqpaxbBnrlrFwGSuXsXSZ/2qX73c///je/+P/8d3yx+H1+uOAMlPHVkZrtbbR7/fvjZzNAg==]],
		},
	},
}

Public.shelter2 = {
	name = 'shelter2',
	width = 44,
	height = 44,
	components = {
		{
			type = 'tiles',
			tile_name = 'red-desert-2',
			offset = {x = 0, y = 0},
			bp_string = [[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]]
		},
		{
			type = 'tiles',
			tile_name = CoreData.world_concrete_tile,
			offset = {x = 0, y = 0},
			bp_string = [[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]],
		},
		{
			type = 'static',
			force = 'environment',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqVmtFq20AQRf9ln+Wg1e5qtf6VEorTiGJwZBM7bUPwv9dOSlqoLzPnKQisw155dD2ZO2/hYfcyH563yyms38Jx2RxWp/3q+/P28Xr9K6zz0IXX659zF7bf9ssxrL9cPrj9vmx214+cXg9zWIftaX4KXVg2T9er42m/zKufm90uXG9bHucLKZ7vuzAvp+1pO39Q3i9evy4vTw/z8+UDt+7vwmF/vNyyX/4caDXclfcjrYb+rpzP3X+cAXJiu81JLo6JyQyjVBWqarrNGSmn3uZU+HQEZoIYoapRVeNtTuwpqAhQhMIUZ4AcJSxRYVmAMgUlASpQmeKMkKOE+Sp6FftPUhSkyUmKJslZ15MFGpx13UyQ06VHE+S06WqCnJWdTZCzsosJwl49CBA2a3UiZ20nE0T9WnEa5IgnlHx1bepKvrI2v/rkq2qzFpOvqM2XI/lq2nxbk6+kTftIvoo2/Sz5Ctp22OQraNv0U8OmLzq93FOS6jwjfEiKM9CHrZQlqky0ezlTkGg/c4HSFGeEHCWsUmGi38u4BxENaG5QmeCUHnKEsBKpMNHvlYGCRANaElSmOBlylDBv+/HpaeLHtTjbjzhZIG9VNwvkrerRAnnduhqg0WvW2QJ567pYIG9dJwvkdevBAmG3ViDq1orjdGvzCTm7EPMBOZsQ86t3erVVi9Xp1dbLUZ0NiPW2VmcDYvlQdTq1ZUPVOdOzDLZSp1YcatSKQ31acSbororToN0LztRDb1WcCM1ecahFKw51aMWhBq040J8VZmS2qjCVubzCTMxUFaYxjxeY1jNLVZjIHF5hoDErDPRlhYG2rDAFvg2in28j5Ih+vsFZh8JMDKNU0TmHCjZ6OuaQkQ0cc0gOHHNIYXTKURWI2vKkQNCXJQdOOaQwOuVoCkSnHGoyFXs45pCgCOccSlqkcw6ZIcUBBlualFiKpEGZ5VoaVFiKpEEjy7U0qLIUSYMmlmtpEAzHJWiA4bgKbaI3REzmiVg6rg/Edj30eTKKozSnoBhJc0YUa2lORTGS5kwo1tKchmIkyXHGh6afOeND22ET7EE0CO57yO2KBPc95HpFYvsemsP2PbSwCoWpfs8ZIf4FyRUdFopLjjNANIVluJGndrxihit5assrZujTksOW8rQwuOmhdgRjhpseakswZraXpzls0eND2H33sQi6/mettAs/5ufj+x3DdDleG2qqtVz+uTmffwPQ9nqN]],
		},
	},
}

Public.lonely_storage_tank = {
	name = 'lonely_storage_tank',
	width = 4,
	height = 6,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqFkVsKwjAQRfcy34m0aWs1WxGRqEMJ2klIUrFI9m5axQdW/QoD9xxuZi6wPXZonaYA8gKelOXB8Mbp/TCfQRYMepDzyEDvDHmQqxTTDanjEAi9RZCgA7bAgFQ7TD4YpxrkQdEBBpD2mEx5XDNACjpovHnGod9Q127RpcDDYLvWJp81PoUN3avwfFaNbbiIkX3gYrrApya7a9I75SmeNXT63fcaYpov//HZb776w7/haaXj8uXLIRmc0PkREIu8rJeiLuq6yrMyxiu0uZ7v]],
		},
	},
}


Public.swamp_lonely_storage_tank = {
	name = 'swamp_lonely_storage_tank',
	width = 3,
	height = 3,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNptj80KwjAQhN9lz4nYH9uaVxGR1C4l2G5KshVLybubRA8ePC0DM9/O7NBPKy7OEIPawZNeJFs5OjMk/QJVCdhANUGAuVvyoC7RZkbSUzLwtiAoMIwzCCA9J+XZOj2iZE0PSEEaMJKKcBWAxIYNfjhZbDda5x5dNPwnCFisjyFL30ryeDjlVvGGBM3v1c8UAU90PifKrqjbc9nWVVOfyy6EN3scTtM=]],
		},
	},
}



Public.maze_defended_camp = {
	name = 'maze_defended_camp',
	width = 20,
	height = 20,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-hostile',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqVkVEKgzAQRO+y3xEaa7TNVUopWhcJ6CbEpFQkd2+iFAq1UL+WgZnHMDtD03s0VpEDOcNItcmczjqr2qSfIHnJYEonMFB3TSPISzSqjuo+WdxkECQohwMwoHpIqvOUOW8tOkgxajGRwpUBklNO4UpZxHQjPzRoo2Erz8DoMUY0vQutfUJgX4D8P4D4TTjuqSC2CMWuDhERR1nGkx+vYPBAOy72/MSL6pxXggt+LA8hvAD1/I5u]],
		},
		{
			type = 'entities_randomlyplaced_border',
			name = 'land-mine',
			force = 'ancient-hostile',
			offset = {x = 0, y = 0},
			count = 20,
			large_r = 10,
			small_r = 7,
		},
		{
			type = 'entities_randomlyplaced',
			name = 'wooden-chest',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			count = 13,
			r = 4,
		},
	},
}

Public.maze_undefended_camp = {
	name = 'maze_undefended_camp',
	width = 20,
	height = 20,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'entities_randomlyplaced_border',
			name = 'land-mine',
			force = 'ancient-hostile',
			offset = {x = 0, y = 0},
			count = 10,
			large_r = 10,
			small_r = 7,
		},
		{
			type = 'entities_randomlyplaced',
			name = 'wooden-chest',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			count = 7,
			r = 4,
		},
	},
}

Public.maze_mines = {
	name = 'maze_mines',
	width = 24,
	height = 24,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'entities_randomlyplaced',
			name = 'land-mine',
			force = 'ancient-hostile',
			offset = {x = 0, y = 0},
			count = 10,
			r = 12,
		},
	},
}

Public.maze_labs = {
	name = 'maze_labs',
	width = 12,
	height = 12,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'entities_randomlyplaced',
			name = 'lab',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			count = 4,
			r = 6,
		},
	},
}

Public.maze_worms = {
	name = 'maze_worms',
	width = 20,
	height = 20,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'entities_randomlyplaced',
			name = 'random-worm',
			force = 'enemy',
			offset = {x = 0, y = 0},
			count = 20,
			r = 10,
		},
	},
}


Public.maze_belts_1 = {
	name = 'maze_belts_1',
	width = 23,
	height = 23,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'entities_grid',
			force = 'ancient-friendly',
			name = 'express-transport-belt',
			direction = defines.direction.east,
			offset = {x = 0, y = 0},
			width = 23,
			height = 23,
		},
	},
}
Public.maze_belts_2 = {
	name = 'maze_belts_2',
	width = 23,
	height = 23,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'entities_grid',
			force = 'ancient-friendly',
			name = 'express-transport-belt',
			direction = defines.direction.west,
			offset = {x = 0, y = 0},
			width = 23,
			height = 23,
		},
	},
}
Public.maze_belts_3 = {
	name = 'maze_belts_3',
	width = 23,
	height = 23,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'entities_grid',
			force = 'ancient-friendly',
			name = 'express-transport-belt',
			direction = defines.direction.south,
			offset = {x = 0, y = 0},
			width = 23,
			height = 23,
		},
	},
}
Public.maze_belts_4 = {
	name = 'maze_belts_4',
	width = 23,
	height = 23,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'entities_grid',
			force = 'ancient-friendly',
			name = 'express-transport-belt',
			direction = defines.direction.north,
			offset = {x = 0, y = 0},
			width = 23,
			height = 23,
		},
	},
}

Public.maze_treasure = {
	name = 'maze_treasure',
	width = 3,
	height = 3,
	components = {
		{
			type = 'tiles',
			tile_name = 'cyan-refined-concrete',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqVksEKgzAMht8l5wqmzrn1VcYOToMEtC21GxPpu691O+wwYb0EAl/+fJCscBvvZB1rD2qFWbe28KYYHPepf4KqBCyxBgHcGT2DukSMB92OCfCLJVDAniYQoNspdZHrHHmCNKR7iikYrgI8j/QOsGZmz0Z/dpTbjjL8StiBMQeW/8GYo4E5GpijIXM0ZI6G3NeI59mOqL4eQsCD3LyNyxMemrNsaqyxOpYhvAAnDLaS]],
		},
		{
			type = 'entities',
			name = 'steel-chest',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			instances = {
				{position = {x = 0, y = 0}},
			}
		}
	},
}

return Public