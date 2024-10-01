-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Public = {}

Public.covered1 = {
	name = 'covered1',
	width = 17,
	height = 15,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = { x = -9, y = -8 },
			bp_string = [[0eNqVmMGKwjAURf8l6wreJG2S/srgwtEgAW1L7Qwj0n8fqy5m4YBnJcKxHrxc7sOr+Tx+5WEs3WTaqzl322E19avDWPbL+x/TKlXmcnsJc2XKru/Opv24geXQbY8LMl2GbFpTpnwylem2p+XdjduNecpm+VC3z8tz5k1lpnLMjwcM/blMpe+e37K+f8l6fvWEf2AR2BLYEdgTuCZwQ+BA4EjghEJhEaIMhUIUSlEoRqEc9WaQIh0Q6YBIB0Q6INIBkQ6IdECkAyIdEOmAUAeEOiDUAaEOCHVAqANCHbCkA5Z0wCJri6wdsXbE2iFrh6w9sfbE2iNrj6xrYl0T6xpZ18i6IdYNsW6QdYOsA7EOxDog64CsI7GOxDoi64isE7FOxDoh68RuFnS4C13uYseW4LXFzi12b8GJZBspNJJCKyk2k2I7KTSUQkspNpViWyk0lkJrKTaXYnspNJhCiyk2mWKbKTSaQqspNptiuyk0nELL+aQtoh2iPaJrRLNfMCA6IjqxdGCYLE2xOMXyFAtULNG3S4HuMqHD7ElbRDtEe0TXiGa/YEB0RHRi6cAwWZpicYrlKRaoWKKvS7GpHv+Tt3/+da/Mdx7P9wfYKB+SDd41Ptk4z7+pVIVy]],
		},
		{
			type = 'tiles',
			tile_name = 'green-refined-concrete',
			offset = { x = -1, y = 2 },
			bp_string = [[0eNqV0tsKwjAMBuB3yXWF9bCDfRXxYm5lFLa2tFUco+9uO70QVDCXgS9/CMkGl/mqnNcmgtwgmN4doj1MXo+lvoNsCawg60RAD9YEkKfM9GT6uYC4OgUSdFQLEDD9UqrsBq+igtJkRpVTaDoTiHpWzwBng47amteMap8h0reED0wxmGEw33GFwRSDGQZzDP5zQYHBNQY3v3E+/P4e8u3VCNyUD3s766hoj6wVjPOublJ6AP6T06c=]],
		},
		{
			type = 'tiles',
			tile_name = 'out-of-map',
			offset = { x = -7, y = -6 },
			bp_string = [[0eNqd2s1Kw0AUhuF7mXWEfnPO/OVWxEXVIIGaljaKIrl3G3XhQqWvqxA4nUDOs3qbt3C7exoOx3GaQ/8WTtP2cDXvrx6O4/16/xJ6pS68ni+2dGG820+n0F+fB8eHabtbR+bXwxD6MM7DY+jCtH1c785zd8dhHsL6o+l+WM9Zbrowj7vh84DD/jTO4376esrm4yGb5acTfhkWGY5k2Miwk+FEhjMZLmS4kuGGlsJWiHaoC5coYknEkoglEUsilkQsiVgSsSRiScSSkCUhS0KWIrEUiaVILEViKRJLkViKxFIkliKxFImliCxFZCkiS0YsGbFkxJIRS0YsGbFkxJIRS0YsGbFkyJIhS4YsObHkxJITS04sObHkxJITS04sObHkxJIjS44sObKUiKVELCViKRFLiVhKxFIilhKxlIilRCwlZCkhSwlZysRSJpYysZSJpUwsZWIpE0uZWMrEUiaWMrKUkaVCdBSioxAdhegoREchOgrRUYiOQnQUoqMgHQXpqERHJToq0VGJjkp0VKKjEh2V6KhERyU6KtJRkY5GdDSioxEdjehoREcjOhrR0VDVQSlWqMUKxVihGiuUY4V6rFCQ1eYf77ui6ca2A5d56TZZaGWllaVW1lpZbGW1leVW1ltZcGXFFSZX2FxRRhXqqEIhVaikCqVUoZYqFFOFaqpQThXqqWJBVayoCkVSoUoqlEmFOqlQKBUqpUKpVKiVCsVSoVoqlktl/5Fy8Z+CqJgKJVOhZioUTYWqqVA2FeqmQuFUqJwKpVOxdioWT/VXPb3pPr906L99N9GF5+F4+jggVnlpsbhlb7Euyzuk5qn3]],
		},
		{
			type = 'static',
			force = 'environment',
			offset = { x = 0, y = 0 },
			bp_string = [[0eNqlmNtuozAQht/F11Ax+IR5lVW1Io0VIRGDwOw2qnj3hbKHSGVghr2KUODz2Hwe+PkQl2b0XV+HKMoPMYSqS2Ob3vr6uhy/ixJsIh7zj54SUb+1YRDlt/nE+haqZjklPjovSlFHfxeJCNV9ORpiG3z6s2oasVwWrn4hTa+J8CHWsfYr5fPg8T2M94vv5xO2rk9E1w7zJW34XVD2oteKXvQ0JV8gOQuSbUMkCQL7EEWC5PsQTYLIfYghQdQ+xJIgeh9SkCBmH+JIELsPgYxEKQ4oNGfdAeWftP696/0wpOO8Z/pb386/6cU3ccO+Z4eTP/uwHWM3RrE1CFHqA6uBpjUceA00seHAbKCpDQduA01uOLAbaHqD2W9h4HgYpJo8Y7VCjVCAVwyG4fVli1Aki2IQiuJNCStG8zBYNYY1J4dQLItSIJTifxqRe25EdUD6UM60G5mwzHgYZMaS+dKBbFnJ0xuw9w75Zf2btppvwM6qA1C6v2Q6j06UKT06U571y+NkE2NPCPsXKj+Fvda9f1v/zo/1lWe2iCWMuHPvHNkKd35iKqO7lyPDGMIwcKbFSHQBDWEBVc6UFrFNyTO1G0Lt+HIp3j5RSOWalWhQjGFlGhRjWakGxRSsXINiHCvZYBidsbINigFWukExOSveoBjJyjcohvj0OdJYa16GQTmGF2JQjuWlGJRT8GIMynG8HINxDPPlauW8JutnoPLpo1Iifvh+WJ9BBSjrcqukUS4vpukXJhD2Zw==]],
		},
	},
}

Public.covered1.red_chest = { x = 2, y = 5 }
Public.covered1.blue_chest = { x = 2, y = 6 }
Public.covered1.walls = {
	{ x = -8, y = -5 },
	{ x = -8, y = -4 },
	{ x = -8, y = -3 },
	{ x = 8, y = -5 },
	{ x = 8, y = -4 },
	{ x = 8, y = -3 },
}

Public.covered1b = {
	name = 'covered1b',
	width = 17,
	height = 15,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = { x = -7, y = -6 },
			bp_string = [[0eNqVmM1qg0AURt9l1gby3ev/q5QsbDMUwaiobROC797YlpJFaXtWInwzzmHO4rtew2P3Esep7ZdQX8PcN+NuGXbPU3vc3s+hVpaEy+3haxLap6GfQ/1wC7bPfdNtkeUyxlCHdomnkIS+OW1v8zL0cffWdF3YlvXHuO20Jn8ujOdxivO864bmGKe7xbYekrC0Xfz8/jjM7dIO/dch9x9n3K/f+9wO+jTFJYbtmz+GRcJGwk7CKQlnJJyTcEHCJQlX6FLYFaI71D8vUcQlEZdEXBJxScQlEZdEXBJxScQlEZeEXBJyScglIy4ZccmIS0ZcMuKSEZeMuGTEJSMuGXHJkEuGXDLkkhOXnLjkxCUnLjlxyYlLTlxy4pITl5y45MglRy45ciklLqXEpZS4lBKXUuJSRgAzApgRwIwAZgQwJ4A5AcwJYE4AcwJYEMCCABYEsCCABQEsCWBJAEsCWBLAkgBWBLAigBUBrAhghYo0GjuF5k6hwVNo8hQaPcUGIjYRsZGIzURsKEJVXairC5V1obYuVNeFSqRQixSqkUI9UqhICtUboX4jVHCEGo5+qTiH5PNPWX33wy4Jr3GaP9ZbqbSorEjNvczydX0HDBNakQ==]],
		},
		{
			type = 'static',
			force = 'ancient-friendly',
			offset = { x = 0, y = 0 },
			bp_string = [[0eNqV1e9qwyAQAPB3uc+mRBOjyauMMdJFipBqiHZrKL77YsqgjPnvUzi4+0W543zAeb6JZZXKwvAAo8alsrq6rHLy8R0GTBFs+6dxCOSnVgaGtz1RXtQ4+xS7LQIGkFZcAYEarz4yVitRfY/zDL5MTcJLDiULxX1ZhTHVrMdJrC/FxL0jEMpKK8XzCEewfajb9bxnDvi/nyNYtNlLtPq9zel5nfpEnT/OH4RkIXUcabKQJo60WQiJIzQLYXGky0L6OMKyEB5HeF6LEz3u85REk3GdxyQ6hDPHNjEtOG9wcZtgmqL5bwNKW6R0AYUWKTSgdEUKDyisSGEBhRcpONSkvojpA5uuLjsMCTC4jMGe2Tf5sfWHl8cHwZdYzVFBOG5ZT1hLmobTzrkfNM8jsg==]],
		},
	},
}

Public.covered1b.market = { x = -2, y = -5 }
Public.covered1b.steel_chest = { x = 1, y = -5 }
Public.covered1b.wooden_chests = {
	{ x = -5, y = 1 },
	{ x = -4, y = 3 },
	{ x = -5, y = 5 },
}

Public.covered2 = {
	name = 'covered2',
	width = 17,
	height = 15,
	components = {
		--for some reason tile blueprints need to be offset...
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = { x = -9, y = -8 },
			bp_string = [[0eNqVmMGKwjAURf8l6wreJG2S/srgwtEgAW1L7Qwj0n8fqy5m4YBnJcKxHrxc7sOr+Tx+5WEs3WTaqzl322E19avDWPbL+x/TKlXmcnsJc2XKru/Opv24geXQbY8LMl2GbFpTpnwylem2p+XdjduNecpm+VC3z8tz5k1lpnLMjwcM/blMpe+e37K+f8l6fvWEf2AR2BLYEdgTuCZwQ+BA4EjghEJhEaIMhUIUSlEoRqEc9WaQIh0Q6YBIB0Q6INIBkQ6IdECkAyIdEOmAUAeEOiDUAaEOCHVAqANCHbCkA5Z0wCJri6wdsXbE2iFrh6w9sfbE2iNrj6xrYl0T6xpZ18i6IdYNsW6QdYOsA7EOxDog64CsI7GOxDoi64isE7FOxDoh68RuFnS4C13uYseW4LXFzi12b8GJZBspNJJCKyk2k2I7KTSUQkspNpViWyk0lkJrKTaXYnspNJhCiyk2mWKbKTSaQqspNptiuyk0nELL+aQtoh2iPaJrRLNfMCA6IjqxdGCYLE2xOMXyFAtULNG3S4HuMqHD7ElbRDtEe0TXiGa/YEB0RHRi6cAwWZpicYrlKRaoWKKvS7GpHv+Tt3/+da/Mdx7P9wfYKB+SDd41Ptk4z7+pVIVy]],
		},
		{
			type = 'tiles',
			tile_name = 'green-refined-concrete',
			offset = { x = -4, y = 2 },
			bp_string = [[0eNqV1NEKgjAUxvF3OdcLnO6k7lWiC9MhA52iKxLZuzeti6CCvsvBb+fwv9hWunRXM07WedIrza4aD344tJNttvOddCloIc1BkK0HN5M+RWZbV3Ub8MtoSJP1pidBruq3U3T1ZLyh7ZJrTJwiw1mQt515DhiH2Xo7uNeOZN+hwrcJH1giOEVwtuMEwRLBKYIzBP8ZqJBAhQQqJFAhgQoJZCSQkUBGAhkJZCTwiOAcwcVvHJ/u/sD122ch6Gameb+eFlLlZZqzkhknHMIDrYdkGw==]],
		},
		{
			type = 'tiles',
			tile_name = 'out-of-map',
			offset = { x = -7, y = -6 },
			bp_string = [[0eNqd2c1qwkAYheF7mXUKnpn55ie3UrqwGiSgUTQtLZJ7r9EWurDg21URvqZw8mz6enav27fucOyH0bVndxqWh6dx/7Q59uv584drZY37vPwIU+P61X44ufb5cthvhuV2Phk/D51rXT92O9e4YbmbP13uVsdu7Nz8S8O6m58zvTRu7Lfd7QGH/akf+/3w/VcW1z+ymO494Y9jkWNPjgM5juTYyHEix5kcF3Jc0UthrxC9Qz34EkUsiVgSsSRiScSSiCURSyKWRCyJWBKyJGRJyJInljyx5IklTyx5YskTS55Y8sSSJ5Y8seSRJY8seWQpEEuBWArEUiCWArEUiKVALAViKRBLgVgKyFJAlgKyFImlSCxFYikSS5FYisRSJJYisRSJpUgsRWQpIktGdBjRYUSHER1GdBjRYUSHER1GdBjRYUiHIR2J6EhERyI6EtGRiI5EdCSiIxEdmeycyc6Z7JzJzpnsnMnOmeycyc6F7FzIzoXsXMjOhexcyM6F7FzIzpXsXMnOlexcyc6V7FzJzpXsXPnOhRxX9FLYK3z0/2qU8IQanlDEE6p4QhlPqOMJhTyhkieU8oRanljME6t5YoGOFTqW6FijY5GOVTqW6VinY6GOlTqY6vQfKQ+HX1TrhHKdUK8TCnZCxU4o2Qk1O6FoJ1TthLKdWLcTC3di5U4o3Qm1O6F4J1TvhPKdUL8TCnhCBU8o4Qk1PLGIJ1bxxDKeUMcTCnlCJU8o5Qm1PKGYJ1TzhHKeUM8TCnpiRU8s6f2c332dL83t+/f217f5jXvvjqfrA3xRzNVniwq2sGn6ArBHNd4=]],
		},
		--this needs to appear last, so that the walls connect properly
		{
			type = 'static',
			force = 'environment',
			offset = { x = 0, y = 0 },
			bp_string = [[0eNqlmNFuqzAMht8l1zBhQkjCq0zVEV2jCokGBGFbNfXdD7TaTnVWE5teVajw5Xfi38Z8iX07uX5ofBDVlxh93aehS49Dc1iuP0UFOhHn+UddEtG8dX4U1et8Y3P0dbvcEs69E5VogjuJRPj6tFyNofMu/ajbViyP+YNbSJck+qD77Ac3jmnb1Qc33D2cX3aJcD40oXE3CdeL8x8/nfbznRU8WjwRfTfOj3T+O5oXdQ0ne1GXRc5/kJwEydYhkgSR65CCBMnXIYoEUeuQkgQp1iH61wlP87kOx6Gbf9O9a8NvpL5DJt/p0k2hn4J4sIQh6SzXddoNOg1PJ2Qb1rDMNYhuiGQy0PwAEVcBzREQsQTQPAERUwDNFRCxBdB8ARFjgKZhInkLhlW5coRiWRRAimjGCwkRkwMPg6nh1XSDUCSLohFKwQsJE6N4GExNyTttrGdqFsYiFIO9A6B9AYBSCnP7ROux9+W28cgSMiNrNyztEshgywPnT/Qg4qbIJ1opcQmmnbAMlkw/ISksmX5C6p7k+QmQuicNc3MwOZbJQfQUGesFfembDzHA2x0Ms8UAP1B5Tc9DM7i32995PFkL3liACucNBihGbYhfEeLHa05RsqYRVLlmzSMohtFvnjh0mnl0RKzKWLMNiqG3k2VIeRh0GQ9a0d64bEwtzTAmhik2ZPrPRLO2AXiqK8Wbm1DtJW+MQzmaN4ChHMObwFCO5Y1gGKfMeDMYyuGOGhhnS1f5R42bbZfcvpdVd5/tEvHuhvFWkQwU2uZaFSBVNkv8C+RQcGE=]],
		},
	},
}

Public.covered2.red_chests = {
	{ x = -1, y = 5 },
	{ x = 0, y = 5 },
	{ x = 1, y = 5 },
}
Public.covered2.blue_chest = { x = 0, y = 6 }
Public.covered2.walls = {
	{ x = -8, y = -4 },
	{ x = -8, y = -3 },
	{ x = -8, y = -2 },
	{ x = -8, y = -1 },
	{ x = 8, y = -4 },
	{ x = 8, y = -3 },
	{ x = 8, y = -2 },
	{ x = 8, y = -1 },
}

Public.covered2b = {
	name = 'covered2b',
	width = 17,
	height = 15,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = { x = -7, y = -6 },
			bp_string = [[0eNqV2M1qg0AYheF7+dYGcubHUW+ldJEmQxhIVIwtDcF7b0y76KItfZfCcYRn9To3ezm95nEq/WzdzS79btzMw+Y4lcP6/G6dYmVX6+qlsrIf+ot1T/ddOfa707qYr2O2zsqcz1ZZvzuvT/fdfspztvWl/pDXY5bnyuZyyp8HjMOlzGXovz6yfXxju/x0wi9jkbEjY0/GgYzj/8YiGiIaIhoiGiIaIhqOaDii4YiGIxqOaDii4YmGJxqeaHii4YmGJxqBaASiEYhGIBqBaASiEYlGJBqRaESiEYlGJBo10aiJRk00aqJRE42aaCSikYhGIhqJaCSikYhGQzQaotEQjYZoNESjIRot0WiJRks0WqLREo0W1ReKUaEaFcpRoR4VClKxImVJypqURSmrUpalqEuFwlSoTIXSVKhNheJUqE6F8lSoT4UCVahQhRJVqFGFIlWoUoUyVahThUJVf5Tq/c//cT/QfbtsqOwtT5fH+65RSK1LMcjHbVyWD41XTnY=]],
		},
		{
			type = 'static',
			force = 'ancient-friendly',
			offset = { x = 0, y = -6 },
			bp_string = [[0eNqN01GLgzAMAOD/kuc6rNqp/SvHOPQWRkFTsd3tZPjf1+o9DO6oeQqB5CO0yRP64Y7TbMiDfoKjbsq8zW6zucb8B7RUApYQVgHmy5ID/RHqzI26IVb4ZULQYDyOIIC6MWbOW8Ls0Q0DxDa6YoTWiwAkb7zBXdmS5ZPuY49zKPivX8BkXWix9DtPftoHCnFdxR+kYCEyjZQs5JxGKhai0ohiIU0aObOQOo3UvIc9+J6GpbRppOWNUqQVmfOYg12RvLWV5QHDXNzqnQkHtR2efrtiAd84u62jaGRVt0WtKlmqPNS/ABFaQ/0=]],
		},
	},
}

Public.covered2b.market = { x = -4, y = -5 }
Public.covered2b.wooden_chests = {
	{ x = -7, y = -5 },
	{ x = -6, y = -5 },
	{ x = 6, y = -5 },
	{ x = 7, y = -5 },
}

return Public
