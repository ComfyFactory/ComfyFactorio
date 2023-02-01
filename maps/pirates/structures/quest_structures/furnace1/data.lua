-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Public = {}

Public.step1 = {
	name = 'furnace1_step1',
	width = 14,
	height = 15,
	components = {
		--for some reason tile blueprints need to be offset...
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = -1, y = 0},
			bp_string = [[0eNqV2M1Kw0AUhuF7mXUKPT+Tv1sRF1WHMlCTkExFkdy7iXXhQsV3UUrh60npOQ+cmffwcLmmac5DCf17WIbTdCjj4Tznp/3za+glVuFte2vWKpwelvFyLemw56Y8nENf5muqQn4chyX0d1uFfB5Ol/275W1KoQ+5pOdQheH0vH/aco9zKils1fLwlPYHrPdVKPmSbgWmccklj8PX44+3p68/VfglrCRsJOwkHEm4JuGGhFsS7khYjiiNeiioiYK6KKiN8s8+ymf6SMJCwkrCRsJOwujfqEm4IeGWhDvUFNZC1ENBTRTURUFtZFMt/2ykEgNKDCgxoMSAEgNKDCgxoMSAEgNKDCgyoMiAIgOKDCgyoMiAIgNGDBgxYMSAEQNGDBgxYMSAEQNGDBgxYMiAIQOGDBgyYMiAIQOGDDgx4MSAEwNODDgx4MSAEwNODDgx4MSAIwOODDgy4MiAIwOODDgyEImBSAxEYiASA5EYiMRAJAYiGr6Ihi+i4Yto+CIavoiGL6Lhq8mI1OhnN6R0g0q3pHSLSnekdMcOVOjWSdgdhLDDPzwKolOVsB1b0LoqbHkRtAcIWgQEbQKCVgFBu4CgZUDQNiBoHRC2DwhbCIRtBMJWAvlrJ7ivbhfU/bd78Cq8pHn5LKCteNNpU8ftJc26fgDbkmjB]],
		},
		{
			type = 'tiles',
			tile_name = 'out-of-map',
			offset = {x = 1.5, y = 0},
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

Public.step1.red_chests = {
	{x = -6, y = -2},
	{x = -5, y = -2},
	{x = -4, y = -2},
}
Public.step1.blue_chests = {
	{x = -6, y = 2},
	{x = -5, y = 2},
	{x = -4, y = 2},
}
Public.step1.walls = {
	{x = 2, y = -6},
	{x = 3, y = -6},
	{x = 4, y = -6},
	{x = 2, y = 6},
	{x = 3, y = 6},
	{x = 4, y = 6},
}

Public.step2 = {
	name = 'furnace1_step2',
	width = 17,
	height = 15,
	doNotDestroyExistingEntities = true,
	components = {
		{
			type = 'tiles',
			tile_name = 'orange-refined-concrete',
			offset = {x = 1.5, y = 0},
			bp_string = [[0eNqV2EFuwjAQQNG7zDpIxJ6xTa5SsaBgIUuQREmoilDuXgJddNFW/KWl77Hkt5ubvJ8uuR9KO0lzk7Hd9aupWx2HcljOn9JsKrlKU9dzJWXftaM0b/euHNvdaSmma5+lkTLls1TS7s7L6d7thzxlWS61h3wfU8/bSqZyys8BfTeWqXTt9yPrxyM6/zbhj9hIHF6L60e8JnFNYkdiT2IlsZEYfV0kcSLxBqG8SOiItyPejng74u2ItyPejng74u2ItyPeDnl74u2Jtyfennh74u2Jtyfennh74u2Jt0feSryVeCvxVuKtxFuJtxJvJd5KvJV4K/I24m3E24i3EW8j3ka8jXgb8TbibcTbkHcg3oF4B+IdiHcg3oF4B+IdiHcg3oF4B+QdiXck3pF4R+IdiXck3pF4R+IdiXck3hF5J+KdiHci3ol4J+KdiHci3ol4J+KdiHf6x3tbPdcGzY8dRCUfeRgf912qNW5cNK29rW2evwC3J1mB]],
		},
		{
			type = 'static',
			force = 'ancient-friendly',
			offset = {x = -1, y = 0},
			bp_string = [[0eNqV01FvgyAQAOD/cs+4COpU/krTLNZeOxI9DGAz0/jfh2wPTYZdeSKX3H054O4Op2HGyShyIO9gqZsyp7OrUect/gJZMFhAcr4yUL0mC/Lg89SVumHLcMuEIEE5HIEBdeMWWYc4ZP0nWgdbHZ3RS3w9MkByyin8YUKwfNA8ntD4hCjAYNLW12j67Sh/q0JP/lxX9kcRaQqPK8VrCn+ulGnKzo2qB0UTZpfZUNdjxAlKETPe016ljndSpylNXGnSlDautGlvu6PwPHFcdv6Ivzi84j9HJA5ecPxihQ2UD+vM4IbGhgrR8LJuRV2VvKhyn/8NRt5ISg==]],
		},
	},
}

Public.step2.market = {x = 4, y = 0}
Public.step2.wooden_chests = {
	{x = 5, y = -5},
	{x = 5, y = -4},
	{x = 5, y = 4},
	{x = 5, y = 5},
}

return Public