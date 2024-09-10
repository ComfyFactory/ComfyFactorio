-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Public = {}

Public.step1 = {
	name = 'market1_step1',
	width = 15,
	height = 18,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqVmc1Kw0AYRd9l1hHmfvOfVxEX1QYJ1LS0URTJu9u0Llyo9KxK4DaBe3oDZ/rpHnevw+E4TrPrP91p2hzu5v3d83Hcrtfvrlfq3Mf5oy6dG5/208n19+fg+Dxtdmtk/jgMrnfjPLy4zk2bl/XqnHs6DvPg1i9N22G9z/LQuXncDdcbHPancR730/dT/OUhtvx2hz/CSreldUl7EhYJGwkHEo4kjNrIJFxIuJJwQ1AYQsRQCKIQRSGM7FctBFI3kjSyGCOLMbIYI4sxshgjizGyGCOLMbIYI4sxtBhDizG0GEOLMbQYQ4sxtBhDiwlkMYEsJpDFBLKYgMgERCYgMgGRCYhMJGQiIRMJmUjIRNReRO1F1F4i7SXSXiLtJdJeQu0l1F5C7WXSXibtZdJeJu1l1F5G7WXUXiHtFdJeIe0V0l5B79SC3qkFkSmITEFkKiFTCZlKyFRCpiIyFZGpiExFZCoi0wiZRsg01F9D/TXUX0P9NdSfPDos8Oi0wDN59Mwe4aGIZ/7oWY3szIUdukAHhxIOLRxqOPNwIREXMnEhFRdycSEZF7JxIR0X8nEhIRcycjElF3NyMSkXs3IxLRfzcjExFzNzITUXcnMhORey8+90ROmE0hmlWd8VpRujA2EymmI4xXiKARUjKob05g39dyDx0F3/++l//JPUubfheLrcwKpiaVZSVEg+LcsXIxltDQ==]],
		},
		{
			type = 'tiles',
			tile_name = 'out-of-map',
			offset = {x = 0, y = -1},
			bp_string = [[0eNqd2D1uwkAQQOG7TG0kZn+Yta8SURBYoZXAtmwnCkK+ezCkSJFEvJQrvZkpvm6v8np6y/1Q2kmaq4ztrl9N3eo4lMPy/pCmruQijfq5krLv2lGal1tXju3utBTTpc/SSJnyWSppd+fldev2Q56yLEPtId/W6LytZCqn/FjQd2OZStd+HVnfj7j5pw2/xJ7EgcSRxBsSG4kTiWsS6/q5WomKEhUlKkpUlKgoUVGiokRF/6GiiuonER0Rd0TcEXFHxB0Rd0TcEXFHxB0Sd0jcIXFPxD0R90TcE3FPxD0R90TcE3GPxD0S90g8EPFAxAMRD0Q8EPFAxAMRD0Q8IPFIVCJRiUQlEpVIVCJRiUQlEpWIVDb3GsVKYkdiT+JA4kjiDYmNxInENUJ5ktCItxFvI95GvI14G/E24m3E24i3EW9D3ol4J+KdiHci3ol4J+KdiHci3ol4J+Kd/vDeVo9/iebbJ0cl73kY7/MuabDaWQzq4zrO8yeeGHe9]],
		},
		{
			type = 'static',
			force = 'environment',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqlmN1uozAQhd/F16TC/5BXqaoVaawIiQICZ7dRlXdfsumuqiUHfOgVQjHfHI9nJjP+EIfmHPqhbqPYf4ixrfpd7HanoT7e3t/FXspMXKaHu2aifu3aUeyfp4X1qa2a25J46YPYizqGN5GJtnq7vY2xa8PuV9U04vZZeww30vUlE6GNdazDnfLn5fKjPb8dwjAt+Pd9eO+HMI678/TlcBq66bk7hCZOFvpunABd+ykvf7J3fU92snSsh/B6/9Vlf6V159if4yRkZlA9EjwzIb+YeADRFCR/DDFJkHwZYmf+a7pqcuAcZLb7zG04JLV+SHUL7Pkkz+hlzxRJELUMKZMgdhki8ySKWaHIJIpbjlyZFv9+RYumtCBKWgaUKxSbRClWKC4tpfMV93oOg9QUVG3QgFJSZUo9pqic0oIoksppRFFUUiOKpvIRUQxVGxDFUpmEKGT0goBRZPQiNVz0ekApOTEAo7nwLQFFUpQCUBS3JSRGcxikhmtAJOqFLIcBJU+zBRjJIWMY6uGCWIKU0lwNRhiTcxiQmYYLY4hRs4YwDlU79t0QQTto1zaotyPV/y2memTA0AYcZ8DSBjxnwFHtEvS05zAoBgp6u8Uakqz4aIc2JzlAjyWzxQIMOXIijP7OqGxmEbY+hlnDCTdAuKWaNrh/R3WQEOPZiXmT64rvjMwLFvGQbkuqq0X+cTnV1kIMOa0iDDeuQoxOPnQPjiDh2sJx8ywUyw20EEP+XYDsdX5DJBcwkpOumwqyfiMPlBukyzxB+2cIvGT3O9D9lxvVTPwMw3jP2kIaXypvrTHWu+v1N43K86A=]],
		},
	},
}

Public.step1.red_chest = {x = 0, y = -7}
Public.step1.blue_chest = {x = 0, y = 6}
Public.step1.walls = {
	{x = -5, y = -4},
	{x = -5, y = -3},
	{x = -5, y = -2},
	{x = 5, y = -4},
	{x = 5, y = -3},
	{x = 5, y = -2},
}

Public.step2 = {
	name = 'market1_step2',
	width = 17,
	height = 15,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = 0, y = -1},
			bp_string = [[0eNqd2D1uwkAQQOG7TG0kZn+Yta8SURBYoZXAtmwnCkK+ezCkSJFEvJQrvZkpvm6v8np6y/1Q2kmaq4ztrl9N3eo4lMPy/pCmruQijfq5krLv2lGal1tXju3utBTTpc/SSJnyWSppd+fldev2Q56yLEPtId/W6LytZCqn/FjQd2OZStd+HVnfj7j5pw2/xJ7EgcSRxBsSG4kTiWsS6/q5WomKEhUlKkpUlKgoUVGiokRF/6GiiuonER0Rd0TcEXFHxB0Rd0TcEXFHxB0Sd0jcIXFPxD0R90TcE3FPxD0R90TcE3GPxD0S90g8EPFAxAMRD0Q8EPFAxAMRD0Q8IPFIVCJRiUQlEpVIVCJRiUQlEpWIVDb3GsVKYkdiT+JA4kjiDYmNxInENUJ5ktCItxFvI95GvI14G/E24m3E24i3EW9D3ol4J+KdiHci3ol4J+KdiHci3ol4J+Kd/vDeVo9/iebbJ0cl73kY7/MuabDaWQzq4zrO8yeeGHe9]],
		},
		{
			type = 'static',
			force = 'ancient-friendly',
			offset = {x = 3, y = 2},
			bp_string = [[0eNqdkd0KgzAMhd8l11X8xa2vMsbwJ0hB09LGoYjvvlZ3MdjYhVfhkJMvh2SFZpjQWEUMcgVHtYlYR71VXdAzyFTAAjLfBKhWkwN58zbVUz0EAy8GQYJiHEEA1WNQOBuLzkVsa3JGW44aHBgCgjoMzO0uAIkVKzyIu1geNI0N2n3pf5YAo50f1/SOmcTlHjSNy20TX8DsNNBXH7xTFtujm/3A56fxWcjrr7FfUH58Q8ATrTs2XtKiumZVWaR5mXj/CzxjkfE=]],
		},
	},
}

Public.step2.market = {x = 3, y = -6}
Public.step2.steel_chest = {x = 4, y = 1}
Public.step2.wooden_chests = {
	{x = 0, y = -5},
	{x = -4, y = -1},
	{x = -4, y = 3},
}

return Public