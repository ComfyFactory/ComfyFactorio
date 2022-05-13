
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
			bp_string = [[0eNqV2t1qGkEYBuB7mWOF+Z/UWyk5sMkSFswquv0JwXtvTErpSUufoyCMa9CHj+H93tfw5fB1Op3nZQ2713BZ9qftetw+nefH2+sfYZf6Jrzc/lw3YX44Lpew+/x2cH5a9ofbkfXlNIVdmNfpOWzCsn++vbqsx2Xaft8fDuH2tuVxuj3per8J63yYPh5xOl7mdT4uvz5ne/f+Odu76++nvH3aw3lap7dn/PX4sOPdjjc7Xu14sePZjic6Hum0Pdv+cftW7Cu339Ow/K/EYc6HOR/mfJjzYc6HOR/mfJjzQc4HOR/kfJDzQc4HOR/kfJDzbs67Oe/mvJvzbs67Oe/mvJvzTs47Oe/kvJPzTs47Oe/kvJPzZs6bOW/mvJnzZs6bOW/mvJnzRs4bOW/kvJHzRs4bOW/kvJHzas6rOa/mvJrzas6rOa/mvJrzSs4rOa/kvJLzSs4rOa/kvJLzYs6LOS/mvJjzYs6LOS/mvJjzQs4LOS/kvJDzQs4LOS/kvJDzbM6zOc/mPJvzbM6zOc/mPJvzTM4zOc/kPJPzTM4zOc/kPJPzZM6TOU/mPJnzZM6TOU/mPJnzRM4TOU/kPJHzRM4TOU/kPInzSMwjKY+EPJLxSMQjCY8EPJLvKLyj6I6CO4rtKLSjyI4CO4prG982vW142+y20W2T2wa3zW0a2zS1aWjTzKaRTRObBjbNa7t+2+3bLt9297art9287eJt9266dtOtmy7ddOemKzfduOnCTfdti08sPbHwxLITi04sObHgxHITik0oNaHQhDITikwoMaHAhPISi78t/bbw27Jvi74t+bbg23Jvir0p9abQmzJvirwp8abAm/JuW1/a9tKWl7a7tNWlbS5tcWl7S1pb0taSlpa0s6SVJW0saWFJ+0qrn1j7xMon1j2x6ok1T6x4Yr0Tqp1Q64RKJ9Q5ocoJNU6ocEJ9E6sPWnvQyoPWHbTqoDUHrThovUGqDVJrkEqD1BmkyiA1Bqkw+I++4P3mozG++6N/vgnfpvPl/e35LtXxKY8yRkuxXq8/AdUS1bk=]],
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

Public.covered1 = {
	name = 'covered1',
	width = 17,
	height = 15,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = -9, y = -8},
			bp_string = [[0eNqVmMGKwjAURf8l6wreJG2S/srgwtEgAW1L7Qwj0n8fqy5m4YBnJcKxHrxc7sOr+Tx+5WEs3WTaqzl322E19avDWPbL+x/TKlXmcnsJc2XKru/Opv24geXQbY8LMl2GbFpTpnwylem2p+XdjduNecpm+VC3z8tz5k1lpnLMjwcM/blMpe+e37K+f8l6fvWEf2AR2BLYEdgTuCZwQ+BA4EjghEJhEaIMhUIUSlEoRqEc9WaQIh0Q6YBIB0Q6INIBkQ6IdECkAyIdEOmAUAeEOiDUAaEOCHVAqANCHbCkA5Z0wCJri6wdsXbE2iFrh6w9sfbE2iNrj6xrYl0T6xpZ18i6IdYNsW6QdYOsA7EOxDog64CsI7GOxDoi64isE7FOxDoh68RuFnS4C13uYseW4LXFzi12b8GJZBspNJJCKyk2k2I7KTSUQkspNpViWyk0lkJrKTaXYnspNJhCiyk2mWKbKTSaQqspNptiuyk0nELL+aQtoh2iPaJrRLNfMCA6IjqxdGCYLE2xOMXyFAtULNG3S4HuMqHD7ElbRDtEe0TXiGa/YEB0RHRi6cAwWZpicYrlKRaoWKKvS7GpHv+Tt3/+da/Mdx7P9wfYKB+SDd41Ptk4z7+pVIVy]],
		},
		{
			type = 'tiles',
			tile_name = 'green-refined-concrete',
			offset = {x = -1, y = 2},
			bp_string = [[0eNqV0tsKwjAMBuB3yXWF9bCDfRXxYm5lFLa2tFUco+9uO70QVDCXgS9/CMkGl/mqnNcmgtwgmN4doj1MXo+lvoNsCawg60RAD9YEkKfM9GT6uYC4OgUSdFQLEDD9UqrsBq+igtJkRpVTaDoTiHpWzwBng47amteMap8h0reED0wxmGEw33GFwRSDGQZzDP5zQYHBNQY3v3E+/P4e8u3VCNyUD3s766hoj6wVjPOublJ6AP6T06c=]],
		},
		{
			type = 'tiles',
			tile_name = 'out-of-map',
			offset = {x = -7, y = -6},
			bp_string = [[0eNqd2s1Kw0AUhuF7mXWEfnPO/OVWxEXVIIGaljaKIrl3G3XhQqWvqxA4nUDOs3qbt3C7exoOx3GaQ/8WTtP2cDXvrx6O4/16/xJ6pS68ni+2dGG820+n0F+fB8eHabtbR+bXwxD6MM7DY+jCtH1c785zd8dhHsL6o+l+WM9Zbrowj7vh84DD/jTO4376esrm4yGb5acTfhkWGY5k2Miwk+FEhjMZLmS4kuGGlsJWiHaoC5coYknEkoglEUsilkQsiVgSsSRiScSSkCUhS0KWIrEUiaVILEViKRJLkViKxFIkliKxFImliCxFZCkiS0YsGbFkxJIRS0YsGbFkxJIRS0YsGbFkyJIhS4YsObHkxJITS04sObHkxJITS04sObHkxJIjS44sObKUiKVELCViKRFLiVhKxFIilhKxlIilRCwlZCkhSwlZysRSJpYysZSJpUwsZWIpE0uZWMrEUiaWMrKUkaVCdBSioxAdhegoREchOgrRUYiOQnQUoqMgHQXpqERHJToq0VGJjkp0VKKjEh2V6KhERyU6KtJRkY5GdDSioxEdjehoREcjOhrR0VDVQSlWqMUKxVihGiuUY4V6rFCQ1eYf77ui6ca2A5d56TZZaGWllaVW1lpZbGW1leVW1ltZcGXFFSZX2FxRRhXqqEIhVaikCqVUoZYqFFOFaqpQThXqqWJBVayoCkVSoUoqlEmFOqlQKBUqpUKpVKiVCsVSoVoqlktl/5Fy8Z+CqJgKJVOhZioUTYWqqVA2FeqmQuFUqJwKpVOxdioWT/VXPb3pPr906L99N9GF5+F4+jggVnlpsbhlb7Euyzuk5qn3]],
		},
		{
			type = 'static',
			force = 'environment',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqlmNtuozAQht/F11Ax+IR5lVW1Io0VIRGDwOw2qnj3hbKHSGVghr2KUODz2Hwe+PkQl2b0XV+HKMoPMYSqS2Ob3vr6uhy/ixJsIh7zj54SUb+1YRDlt/nE+haqZjklPjovSlFHfxeJCNV9ORpiG3z6s2oasVwWrn4hTa+J8CHWsfYr5fPg8T2M94vv5xO2rk9E1w7zJW34XVD2oteKXvQ0JV8gOQuSbUMkCQL7EEWC5PsQTYLIfYghQdQ+xJIgeh9SkCBmH+JIELsPgYxEKQ4oNGfdAeWftP696/0wpOO8Z/pb386/6cU3ccO+Z4eTP/uwHWM3RrE1CFHqA6uBpjUceA00seHAbKCpDQduA01uOLAbaHqD2W9h4HgYpJo8Y7VCjVCAVwyG4fVli1Aki2IQiuJNCStG8zBYNYY1J4dQLItSIJTifxqRe25EdUD6UM60G5mwzHgYZMaS+dKBbFnJ0xuw9w75Zf2btppvwM6qA1C6v2Q6j06UKT06U571y+NkE2NPCPsXKj+Fvda9f1v/zo/1lWe2iCWMuHPvHNkKd35iKqO7lyPDGMIwcKbFSHQBDWEBVc6UFrFNyTO1G0Lt+HIp3j5RSOWalWhQjGFlGhRjWakGxRSsXINiHCvZYBidsbINigFWukExOSveoBjJyjcohvj0OdJYa16GQTmGF2JQjuWlGJRT8GIMynG8HINxDPPlauW8JutnoPLpo1Iifvh+WJ9BBSjrcqukUS4vpukXJhD2Zw==]],
		},
	},
}

Public.covered1.red_chest = {x = 2, y = 5}
Public.covered1.blue_chest = {x = 2, y = 6}
Public.covered1.walls = {
	{x = -8, y = -5},
	{x = -8, y = -4},
	{x = -8, y = -3},
	{x = 8, y = -5},
	{x = 8, y = -4},
	{x = 8, y = -3},
}

Public.covered1b = {
	name = 'covered1b',
	width = 17,
	height = 15,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = -7, y = -6},
			bp_string = [[0eNqVmM1qg0AURt9l1gby3ev/q5QsbDMUwaiobROC797YlpJFaXtWInwzzmHO4rtew2P3Esep7ZdQX8PcN+NuGXbPU3vc3s+hVpaEy+3haxLap6GfQ/1wC7bPfdNtkeUyxlCHdomnkIS+OW1v8zL0cffWdF3YlvXHuO20Jn8ujOdxivO864bmGKe7xbYekrC0Xfz8/jjM7dIO/dch9x9n3K/f+9wO+jTFJYbtmz+GRcJGwk7CKQlnJJyTcEHCJQlX6FLYFaI71D8vUcQlEZdEXBJxScQlEZdEXBJxScQlEZeEXBJyScglIy4ZccmIS0ZcMuKSEZeMuGTEJSMuGXHJkEuGXDLkkhOXnLjkxCUnLjlxyYlLTlxy4pITl5y45MglRy45ciklLqXEpZS4lBKXUuJSRgAzApgRwIwAZgQwJ4A5AcwJYE4AcwJYEMCCABYEsCCABQEsCWBJAEsCWBLAkgBWBLAigBUBrAhghYo0GjuF5k6hwVNo8hQaPcUGIjYRsZGIzURsKEJVXairC5V1obYuVNeFSqRQixSqkUI9UqhICtUboX4jVHCEGo5+qTiH5PNPWX33wy4Jr3GaP9ZbqbSorEjNvczydX0HDBNakQ==]],
		},
		{
			type = 'static',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqV1e9qwyAQAPB3uc+mRBOjyauMMdJFipBqiHZrKL77YsqgjPnvUzi4+0W543zAeb6JZZXKwvAAo8alsrq6rHLy8R0GTBFs+6dxCOSnVgaGtz1RXtQ4+xS7LQIGkFZcAYEarz4yVitRfY/zDL5MTcJLDiULxX1ZhTHVrMdJrC/FxL0jEMpKK8XzCEewfajb9bxnDvi/nyNYtNlLtPq9zel5nfpEnT/OH4RkIXUcabKQJo60WQiJIzQLYXGky0L6OMKyEB5HeF6LEz3u85REk3GdxyQ6hDPHNjEtOG9wcZtgmqL5bwNKW6R0AYUWKTSgdEUKDyisSGEBhRcpONSkvojpA5uuLjsMCTC4jMGe2Tf5sfWHl8cHwZdYzVFBOG5ZT1hLmobTzrkfNM8jsg==]],
		},
	},
}

Public.covered1b.market = {x = -2, y = -5}
Public.covered1b.steel_chest = {x = 1, y = -5}
Public.covered1b.wooden_chests = {
	{x = -5, y = 1},
	{x = -4, y = 3},
	{x = -5, y = 5},
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
			offset = {x = -9, y = -8},
			bp_string = [[0eNqVmMGKwjAURf8l6wreJG2S/srgwtEgAW1L7Qwj0n8fqy5m4YBnJcKxHrxc7sOr+Tx+5WEs3WTaqzl322E19avDWPbL+x/TKlXmcnsJc2XKru/Opv24geXQbY8LMl2GbFpTpnwylem2p+XdjduNecpm+VC3z8tz5k1lpnLMjwcM/blMpe+e37K+f8l6fvWEf2AR2BLYEdgTuCZwQ+BA4EjghEJhEaIMhUIUSlEoRqEc9WaQIh0Q6YBIB0Q6INIBkQ6IdECkAyIdEOmAUAeEOiDUAaEOCHVAqANCHbCkA5Z0wCJri6wdsXbE2iFrh6w9sfbE2iNrj6xrYl0T6xpZ18i6IdYNsW6QdYOsA7EOxDog64CsI7GOxDoi64isE7FOxDoh68RuFnS4C13uYseW4LXFzi12b8GJZBspNJJCKyk2k2I7KTSUQkspNpViWyk0lkJrKTaXYnspNJhCiyk2mWKbKTSaQqspNptiuyk0nELL+aQtoh2iPaJrRLNfMCA6IjqxdGCYLE2xOMXyFAtULNG3S4HuMqHD7ElbRDtEe0TXiGa/YEB0RHRi6cAwWZpicYrlKRaoWKKvS7GpHv+Tt3/+da/Mdx7P9wfYKB+SDd41Ptk4z7+pVIVy]],
		},
		{
			type = 'tiles',
			tile_name = 'green-refined-concrete',
			offset = {x = -4, y = 2},
			bp_string = [[0eNqV1NEKgjAUxvF3OdcLnO6k7lWiC9MhA52iKxLZuzeti6CCvsvBb+fwv9hWunRXM07WedIrza4aD344tJNttvOddCloIc1BkK0HN5M+RWZbV3Ub8MtoSJP1pidBruq3U3T1ZLyh7ZJrTJwiw1mQt515DhiH2Xo7uNeOZN+hwrcJH1giOEVwtuMEwRLBKYIzBP8ZqJBAhQQqJFAhgQoJZCSQkUBGAhkJZCTwiOAcwcVvHJ/u/sD122ch6Gameb+eFlLlZZqzkhknHMIDrYdkGw==]],
		},
		{
			type = 'tiles',
			tile_name = 'out-of-map',
			offset = {x = -7, y = -6},
			bp_string = [[0eNqd2c1qwkAYheF7mXUKnpn55ie3UrqwGiSgUTQtLZJ7r9EWurDg21URvqZw8mz6enav27fucOyH0bVndxqWh6dx/7Q59uv584drZY37vPwIU+P61X44ufb5cthvhuV2Phk/D51rXT92O9e4YbmbP13uVsdu7Nz8S8O6m58zvTRu7Lfd7QGH/akf+/3w/VcW1z+ymO494Y9jkWNPjgM5juTYyHEix5kcF3Jc0UthrxC9Qz34EkUsiVgSsSRiScSSiCURSyKWRCyJWBKyJGRJyJInljyx5IklTyx5YskTS55Y8sSSJ5Y8seSRJY8seWQpEEuBWArEUiCWArEUiKVALAViKRBLgVgKyFJAlgKyFImlSCxFYikSS5FYisRSJJYisRSJpUgsRWQpIktGdBjRYUSHER1GdBjRYUSHER1GdBjRYUiHIR2J6EhERyI6EtGRiI5EdCSiIxEdmeycyc6Z7JzJzpnsnMnOmeycyc6F7FzIzoXsXMjOhexcyM6F7FzIzpXsXMnOlexcyc6V7FzJzpXsXPnOhRxX9FLYK3z0/2qU8IQanlDEE6p4QhlPqOMJhTyhkieU8oRanljME6t5YoGOFTqW6FijY5GOVTqW6VinY6GOlTqY6vQfKQ+HX1TrhHKdUK8TCnZCxU4o2Qk1O6FoJ1TthLKdWLcTC3di5U4o3Qm1O6F4J1TvhPKdUL8TCnhCBU8o4Qk1PLGIJ1bxxDKeUMcTCnlCJU8o5Qm1PKGYJ1TzhHKeUM8TCnpiRU8s6f2c332dL83t+/f217f5jXvvjqfrA3xRzNVniwq2sGn6ArBHNd4=]],
		},
		--this needs to appear last, so that the walls connect properly
		{
			type = 'static',
			force = 'environment',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqlmNFuqzAMht8l1zBhQkjCq0zVEV2jCokGBGFbNfXdD7TaTnVWE5teVajw5Xfi38Z8iX07uX5ofBDVlxh93aehS49Dc1iuP0UFOhHn+UddEtG8dX4U1et8Y3P0dbvcEs69E5VogjuJRPj6tFyNofMu/ajbViyP+YNbSJck+qD77Ac3jmnb1Qc33D2cX3aJcD40oXE3CdeL8x8/nfbznRU8WjwRfTfOj3T+O5oXdQ0ne1GXRc5/kJwEydYhkgSR65CCBMnXIYoEUeuQkgQp1iH61wlP87kOx6Gbf9O9a8NvpL5DJt/p0k2hn4J4sIQh6SzXddoNOg1PJ2Qb1rDMNYhuiGQy0PwAEVcBzREQsQTQPAERUwDNFRCxBdB8ARFjgKZhInkLhlW5coRiWRRAimjGCwkRkwMPg6nh1XSDUCSLohFKwQsJE6N4GExNyTttrGdqFsYiFIO9A6B9AYBSCnP7ROux9+W28cgSMiNrNyztEshgywPnT/Qg4qbIJ1opcQmmnbAMlkw/ISksmX5C6p7k+QmQuicNc3MwOZbJQfQUGesFfembDzHA2x0Ms8UAP1B5Tc9DM7i32995PFkL3liACucNBihGbYhfEeLHa05RsqYRVLlmzSMohtFvnjh0mnl0RKzKWLMNiqG3k2VIeRh0GQ9a0d64bEwtzTAmhik2ZPrPRLO2AXiqK8Wbm1DtJW+MQzmaN4ChHMObwFCO5Y1gGKfMeDMYyuGOGhhnS1f5R42bbZfcvpdVd5/tEvHuhvFWkQwU2uZaFSBVNkv8C+RQcGE=]],
		},
	},
}

Public.covered2.red_chests = {
	{x = -1, y = 5},
	{x = 0, y = 5},
	{x = 1, y = 5},
}
Public.covered2.blue_chest = {x = 0, y = 6}
Public.covered2.walls = {
	{x = -8, y = -4},
	{x = -8, y = -3},
	{x = -8, y = -2},
	{x = -8, y = -1},
	{x = 8, y = -4},
	{x = 8, y = -3},
	{x = 8, y = -2},
	{x = 8, y = -1},
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
			offset = {x = -7, y = -6},
			bp_string = [[0eNqV2M1qg0AYheF7+dYGcubHUW+ldJEmQxhIVIwtDcF7b0y76KItfZfCcYRn9To3ezm95nEq/WzdzS79btzMw+Y4lcP6/G6dYmVX6+qlsrIf+ot1T/ddOfa707qYr2O2zsqcz1ZZvzuvT/fdfspztvWl/pDXY5bnyuZyyp8HjMOlzGXovz6yfXxju/x0wi9jkbEjY0/GgYzj/8YiGiIaIhoiGiIaIhqOaDii4YiGIxqOaDii4YmGJxqeaHii4YmGJxqBaASiEYhGIBqBaASiEYlGJBqRaESiEYlGJBo10aiJRk00aqJRE42aaCSikYhGIhqJaCSikYhGQzQaotEQjYZoNESjIRot0WiJRks0WqLREo0W1ReKUaEaFcpRoR4VClKxImVJypqURSmrUpalqEuFwlSoTIXSVKhNheJUqE6F8lSoT4UCVahQhRJVqFGFIlWoUoUyVahThUJVf5Tq/c//cT/QfbtsqOwtT5fH+65RSK1LMcjHbVyWD41XTnY=]],
		},
		{
			type = 'static',
			force = 'ancient-friendly',
			offset = {x = 0, y = -6},
			bp_string = [[0eNqN01GLgzAMAOD/kuc6rNqp/SvHOPQWRkFTsd3tZPjf1+o9DO6oeQqB5CO0yRP64Y7TbMiDfoKjbsq8zW6zucb8B7RUApYQVgHmy5ID/RHqzI26IVb4ZULQYDyOIIC6MWbOW8Ls0Q0DxDa6YoTWiwAkb7zBXdmS5ZPuY49zKPivX8BkXWix9DtPftoHCnFdxR+kYCEyjZQs5JxGKhai0ohiIU0aObOQOo3UvIc9+J6GpbRppOWNUqQVmfOYg12RvLWV5QHDXNzqnQkHtR2efrtiAd84u62jaGRVt0WtKlmqPNS/ABFaQ/0=]],
		},
	},
}

Public.covered2b.market = {x = -4, y = -5}
Public.covered2b.wooden_chests = {
	{x = -7, y = -5},
	{x = -6, y = -5},
	{x = 6, y = -5},
	{x = 7, y = -5},
}







Public.v2_covered_market = {
	name = 'v2_covered_market',
	width = 15,
	height = 18,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = -8, y = -9},
			bp_string = [[0eNqVmc1Kw0AYRd9l1hHmfvOfVxEX1QYJ1LS0URTJu9u0Llyo9KxK4DaBe3oDZ/rpHnevw+E4TrPrP91p2hzu5v3d83Hcrtfvrlfq3Mf5oy6dG5/208n19+fg+Dxtdmtk/jgMrnfjPLy4zk2bl/XqnHs6DvPg1i9N22G9z/LQuXncDdcbHPancR730/dT/OUhtvx2hz/CSreldUl7EhYJGwkHEo4kjNrIJFxIuJJwQ1AYQsRQCKIQRSGM7FctBFI3kjSyGCOLMbIYI4sxshgjizGyGCOLMbIYI4sxtBhDizG0GEOLMbQYQ4sxtBhDiwlkMYEsJpDFBLKYgMgERCYgMgGRCYhMJGQiIRMJmUjIRNReRO1F1F4i7SXSXiLtJdJeQu0l1F5C7WXSXibtZdJeJu1l1F5G7WXUXiHtFdJeIe0V0l5B79SC3qkFkSmITEFkKiFTCZlKyFRCpiIyFZGpiExFZCoi0wiZRsg01F9D/TXUX0P9NdSfPDos8Oi0wDN59Mwe4aGIZ/7oWY3szIUdukAHhxIOLRxqOPNwIREXMnEhFRdycSEZF7JxIR0X8nEhIRcycjElF3NyMSkXs3IxLRfzcjExFzNzITUXcnMhORey8+90ROmE0hmlWd8VpRujA2EymmI4xXiKARUjKob05g39dyDx0F3/++l//JPUubfheLrcwKpiaVZSVEg+LcsXIxltDQ==]],
		},
		{
			type = 'tiles',
			tile_name = 'out-of-map',
			offset = {x = -6, y = -7},
			bp_string = [[0eNqd2D1uwkAQQOG7TG0kZn+Yta8SURBYoZXAtmwnCkK+ezCkSJFEvJQrvZkpvm6v8np6y/1Q2kmaq4ztrl9N3eo4lMPy/pCmruQijfq5krLv2lGal1tXju3utBTTpc/SSJnyWSppd+fldev2Q56yLEPtId/W6LytZCqn/FjQd2OZStd+HVnfj7j5pw2/xJ7EgcSRxBsSG4kTiWsS6/q5WomKEhUlKkpUlKgoUVGiokRF/6GiiuonER0Rd0TcEXFHxB0Rd0TcEXFHxB0Sd0jcIXFPxD0R90TcE3FPxD0R90TcE3GPxD0S90g8EPFAxAMRD0Q8EPFAxAMRD0Q8IPFIVCJRiUQlEpVIVCJRiUQlEpWIVDb3GsVKYkdiT+JA4kjiDYmNxInENUJ5ktCItxFvI95GvI14G/E24m3E24i3EW9D3ol4J+KdiHci3ol4J+KdiHci3ol4J+Kd/vDeVo9/iebbJ0cl73kY7/MuabDaWQzq4zrO8yeeGHe9]],
		},
		{
			type = 'static',
			force = 'environment',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqlmN2OmzAQhd/F16TCfxjyKtWqIhsrQiIGgdNutMq7F5JW3So5xIdcIRTzzbEzczz2p9i1J98PTYhi+ynGUPeb2G0OQ7Of3z/EVspMnKdHcclE896FUWy/TwObQ6jbeUg8915sRRP9UWQi1Mf5bYxd8JtfdduK+bOw9zPp8pYJH2ITG3+jXF/OP8LpuPPDNODR95nou3H6pAt/BOXf7FXR9LxcsjuISoLIZYhOgqhliEmC6GWITYKYZUiRBLHLEJcEKZYhZRLELUOqJEi5DJF5EqV6QknLWfkkaaWiUl8BiqZyH1EMRZGA8i9x/Uc/+HHcnCYbGA5DNz03O99GPL+ZmYl9M/j326/T8vz1mdCfongUsKBqFk3eUUWLKOWKyavnk+9OEc2+uovYdvUU8oFXPI5SJERROWUkYHWUpDwNURTlRyBNlaYoSIvhXABhLIdBcyooM9GA4jgxCFNSYkpAqSiKA7t6zk0JiNGk5yM1nOdL1KpoClMBCpnBUA2ZwkgOl8ISFJR2HAYUlC65HRGpuffoONRh7Lshgj3BfkX+vyk8ajhzOoDjAkg6QMEFUHSA8smqG031eRDDFgjisB4PctIUXE4agHGvtGlmRZ9myGIC+4rhdgSEsfkrnZpZ06pZybZqa5bZqvVmg9ZKJwt3QHiRINys+EfKVzLSWs4hQCnZgsOgVV5TkTJ/LSVL0pSQ9oqrbQuuK3KuthFGUmc5iFHUwRJiNHV2ghhDHZ4gxlIXMRBTcIcwhHHUjQ7ElFwFIkxFVsOV85bd7kC3X25UM/HTD+OtDEtpXKWcNVLbfBr/G8eu84M=]],
		},
	},
}

Public.v2_covered_market.red_chest = {x = 0, y = -6}
Public.v2_covered_market.blue_chest = {x = 0, y = 6}
Public.v2_covered_market.walls = {
	{x = -8, y = -5},
	{x = -8, y = -4},
	{x = -8, y = -3},
	{x = 8, y = -5},
	{x = 8, y = -4},
	{x = 8, y = -3},
}

Public.v2_covered_market_b = {
	name = 'v2_covered_market_b',
	width = 17,
	height = 15,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = -7, y = -6},
			bp_string = [[0eNqd2D1uwkAQQOG7TG0kZn+Yta8SURBYoZXAtmwnCkK+ezCkSJFEvJQrvZkpvm6v8np6y/1Q2kmaq4ztrl9N3eo4lMPy/pCmruQijfq5krLv2lGal1tXju3utBTTpc/SSJnyWSppd+fldev2Q56yLEPtId/W6LytZCqn/FjQd2OZStd+HVnfj7j5pw2/xJ7EgcSRxBsSG4kTiWsS6/q5WomKEhUlKkpUlKgoUVGiokRF/6GiiuonER0Rd0TcEXFHxB0Rd0TcEXFHxB0Sd0jcIXFPxD0R90TcE3FPxD0R90TcE3GPxD0S90g8EPFAxAMRD0Q8EPFAxAMRD0Q8IPFIVCJRiUQlEpVIVCJRiUQlEpWIVDb3GsVKYkdiT+JA4kjiDYmNxInENUJ5ktCItxFvI95GvI14G/E24m3E24i3EW9D3ol4J+KdiHci3ol4J+KdiHci3ol4J+Kd/vDeVo9/iebbJ0cl73kY7/MuabDaWQzq4zrO8yeeGHe9]],
		},
		{
			type = 'static',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdkd0KgzAMhd8l11X8xa2vMsbwJ0hB09LGoYjvvlZ3MdjYhVfhkJMvh2SFZpjQWEUMcgVHtYlYR71VXdAzyFTAAjLfBKhWkwN58zbVUz0EAy8GQYJiHEEA1WNQOBuLzkVsa3JGW44aHBgCgjoMzO0uAIkVKzyIu1geNI0N2n3pf5YAo50f1/SOmcTlHjSNy20TX8DsNNBXH7xTFtujm/3A56fxWcjrr7FfUH58Q8ATrTs2XtKiumZVWaR5mXj/CzxjkfE=]],
		},
	},
}

Public.v2_covered_market_b.market = {x = 3, y = -5}
Public.v2_covered_market_b.steel_chest = {x = 4, y = 2}
Public.v2_covered_market_b.wooden_chests = {
	{x = 0, y = -3},
	{x = -4, y = 3},
	{x = -4, y = 4},
}



Public.v2_covered_furnace = {
	name = 'v2_covered_furnace',
	width = 14,
	height = 15,
	components = {
		--for some reason tile blueprints need to be offset...
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = -7, y = -8},
			bp_string = [[0eNqVmM1qwkAYRd9l1ink+5n8vUpxYXWQAU1CTEtF8u412kUXbfGsQuB4E7gH7phreDu+p3HK/Ry6azj32/FlHl4OU96v95+hEy/C5XaJSxHybujPoXu9gfnQb48rMl/GFLqQ53QKRei3p/Xuxu2mNKew/qjfpzVn2RRhzsf0CBiHc57z0H8/pXw8ZPkt4Q9YCWwEdgJHAlcErgncELglsJSIRh0KKlGebFHudElgIbASGL2zEzgSuCJwTeCGwC0qhVWIOhRUIjNPnqxRiadKPFXiqRJPlXiqxFMlnirxVImnSjxV5KkiTxV5qshTRZ4a8dSIp0Y8NeKpEU+NeGrEUyOeGvHUiKeGPDXkqSFPDXlqyFMn6jlRz4l6TtRzop6Tzh117qhzR5076jySFiOKrkh0haJrEl2j6IZENyi6JdEtOwqhv3QCT/js1A4PceioJWx5Be2joIEUtJCCJlLQRgoaSUErKWgmBe2ksKEUtpTCplL+28pN8fjk0v34gFOEjzSd7wHaiNet1tHFYhmX5QubhLg2]],
		},
		{
			type = 'tiles',
			tile_name = 'out-of-map',
			offset = {x = -5, y = -6},
			bp_string = [[0eNqV2EFuwjAQQNG7zDpIxJ6xTa5SsaBgIUuQREmoilDuXgJddNFW/KWl77Hkt5ubvJ8uuR9KO0lzk7Hd9aupWx2HcljOn9JsKrlKU9dzJWXftaM0b/euHNvdaSmma5+lkTLls1TS7s7L6d7thzxlWS61h3wfU8/bSqZyys8BfTeWqXTt9yPrxyM6/zbhj9hIHF6L60e8JnFNYkdiT2IlsZEYfV0kcSLxBqG8SOiItyPejng74u2ItyPejng74u2ItyPeDnl74u2Jtyfennh74u2Jtyfennh74u2Jt0feSryVeCvxVuKtxFuJtxJvJd5KvJV4K/I24m3E24i3EW8j3ka8jXgb8TbibcTbkHcg3oF4B+IdiHcg3oF4B+IdiHcg3oF4B+QdiXck3pF4R+IdiXck3pF4R+IdiXck3hF5J+KdiHci3ol4J+KdiHci3ol4J+KdiHf6x3tbPdcGzY8dRCUfeRgf912qNW5cNK29rW2evwC3J1mB]],
		},
		--this needs to appear last, so that the walls connect properly
		{
			type = 'static',
			force = 'environment',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqlmNtuozAURf/Fz1DhG7dfGVUjkngiJGoQmJlGVf59oOlDNJMdvMsTQsLrXNjn2Mcf4tDNbhhbH0T9ISbfDGno0/PYntb3d1FLk4jL8rDXRLTH3k+i/rF82J59062fhMvgRC3a4N5EInzztr5Nofcu/dN0nViX+ZNbSddkc6F7H0Y3TWnXNyc33i1W19dEOB/a0LqbC58vl59+fjssX9bykfFEDP20LOn9VzTZi72F82Kvqzv/QFQURD6H6P+imZcYxvPYL8/04LqAkYt/S8xfqennMMxBPDBhovxUz/20URD9HJJ/I1jNBVt8w4TiTJRRqTDPU1FFQexziMyiKPkGJa4aig1KXDmUGxQdV1QbapVxmpcbepUW9RpYkyZGQTKn+o8G3hU7eoe613rrkaMl5agCjlbRadRMGlUWzVUUV+7oU3GJVWpHn4o0oak+BUSmDEUBClCWq0eEyTkMiqmgVG0AhasNCygVlV9A0RlFARFpyaUXYRSHQTHdHY06dwxje0x/zaNvjg6XRgFYhvpXOaBYioJ8IUWMnCk4DPKGU3EJKBVFqR5TDKdiRCFVDEIypIqRN5o+QkgZ0d0Np2iZAfc4SUtwUDI5vcPHRVnQO3wclzzDo7C55o1+gs3I0yrikMpHYVnFiQLs1nbPbCtV3DBmyToARwJruWEeYfZMuNEh75lxo42U3K0BSkjF3RsATM7tDBAjuakbYRTnDaiPXHPTO/LGcOM7wlhufkeYnBzgEYc83kBOSXLQz6r2NDMTNbEV2Z7uEWlD7mkej2y8Jrdr2frudjgRv904fQJUKU1RqcIaqW225PYv7EY6nw==]],
		},
	},
}

Public.v2_covered_furnace.red_chests = {
	{x = -4, y = 2},
	{x = -3, y = 2},
	{x = -2, y = 2},
}
Public.v2_covered_furnace.blue_chests = {
	{x = -4, y = -2},
	{x = -3, y = -2},
	{x = -2, y = -2},
}
Public.v2_covered_furnace.walls = {
	{x = 3, y = -6},
	{x = 4, y = -6},
	{x = 5, y = -6},
	{x = 3, y = 6},
	{x = 4, y = 6},
	{x = 5, y = 6},
}

Public.v2_covered_furnace_b = {
	name = 'v2_covered_furnace_b',
	width = 17,
	height = 15,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = -7, y = -6},
			bp_string = [[0eNqV2M1qg0AYheF7+dYGcubHUW+ldJEmQxhIVIwtDcF7b0y76KItfZfCcYRn9To3ezm95nEq/WzdzS79btzMw+Y4lcP6/G6dYmVX6+qlsrIf+ot1T/ddOfa707qYr2O2zsqcz1ZZvzuvT/fdfspztvWl/pDXY5bnyuZyyp8HjMOlzGXovz6yfXxju/x0wi9jkbEjY0/GgYzj/8YiGiIaIhoiGiIaIhqOaDii4YiGIxqOaDii4YmGJxqeaHii4YmGJxqBaASiEYhGIBqBaASiEYlGJBqRaESiEYlGJBo10aiJRk00aqJRE42aaCSikYhGIhqJaCSikYhGQzQaotEQjYZoNESjIRot0WiJRks0WqLREo0W1ReKUaEaFcpRoR4VClKxImVJypqURSmrUpalqEuFwlSoTIXSVKhNheJUqE6F8lSoT4UCVahQhRJVqFGFIlWoUoUyVahThUJVf5Tq/c//cT/QfbtsqOwtT5fH+65RSK1LMcjHbVyWD41XTnY=]],
		},
		{
			type = 'static',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqV01FvgyAQAOD/cs+4COpU/krTLNZeOxI9DGAz0/jfh2wPTYZdeSKX3H054O4Op2HGyShyIO9gqZsyp7OrUect/gJZMFhAcr4yUL0mC/Lg89SVumHLcMuEIEE5HIEBdeMWWYc4ZP0nWgdbHZ3RS3w9MkByyin8YUKwfNA8ntD4hCjAYNLW12j67Sh/q0JP/lxX9kcRaQqPK8VrCn+ulGnKzo2qB0UTZpfZUNdjxAlKETPe016ljndSpylNXGnSlDautGlvu6PwPHFcdv6Ivzi84j9HJA5ecPxihQ2UD+vM4IbGhgrR8LJuRV2VvKhyn/8NRt5ISg==]],
		},
	},
}

Public.v2_covered_furnace_b.market = {x = 4, y = 0}
Public.v2_covered_furnace_b.wooden_chests = {
	{x = 5, y = -5},
	{x = 5, y = -4},
	{x = 5, y = 4},
	{x = 5, y = 5},
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
			offset = {x = -1, y = -1},
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