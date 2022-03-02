
local Public = {}

Public.refuel_station = {
	name = 'refuel_station',
	width = 28,
	height = 26,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdnO1O6zoThe8lvxsUf47NrRyhVwWi7kglqdJ0v2dri3s/KaVpWpx2Lf9CQNfjscczY48Rf4vX7aHe9U07FM9/i+ata/fF8z9/i32zadfb48+GP7u6eC6aof4oVkW7/jh+16+bbfG5Kpr2vf63eFafq4eS/VCvP8q63TRtPZPqz5dVUbdDMzT1aeivb/78rz18vNb9yJ4RxmE3v4bya/RVsev2o6prj0OOJCer4k/xXBr5PJpzg9ET5khpy/3Q7RKMODFW43jr06+KIgE0c2C733X9UL7W2+En1Mcn9431T24Evzd9/Xb6gE2QbQ5ZELKDyVItk32C7HGy4siCkzVHDjjZcOQIk52dyBbxoKom9GEMoH7Td+PXJbhbho8O+w7T7jDsDkNqiys+9lwq9tQl+F4PfVv3ZdPu634Yf/eTFCab3a3NOsW+xOF+t22GNPQSJ4D3lGXWOCBr3LRLS4yHpK/ujJRC4zHpFYnGg9JrEo1HpTckOgJbxc9i5jFSV7i1lrNWKxztSbTG0UKiibIYSHRWXXRIVtUuB41Z7XNqgYaslhy0gdCBzvwmeeqKOfEBmWiyQg9aWDOrex/r7bast+PH++at3HXb+m7OOPHbelyx1+7QH0+0Tr+kxpjVxK7ZJlPReWkVUgiNSR+17x3tMLBFwZ4Eu5z9W0EezIo6BaGFDg2VCg0TcvYvZmJW1EELay9Rt3yGm8WDQnKkvcTbrtnVd8/fR2AKoTMcrgM0ZZODjhDasntJx+TsL5HU9F1bvv2q93ePeV/mpUAeA+mHIMnYguCi5QQO6OoIJ2UtSIpz1YOdfTm6La2kU3ReB23TZJWLN366qnJjzfRxJSZV65yZNY7e14lVlWtHpRhwFZqOldovoBw3cZF7E1+Yck4B0lB7yOUc+zTWH6KPfTrZbHM5BQgz0ecc+7CF9YqqbRprjGUVJqgX5LMKE3Qh8pdoe1v3m678/3ozfjaxDZ7EVNYHOeP1UzAuGjkO0vXNyP1uolZP1nrlvY9WeavFKz0pm/b3+MGuHwntYbtNGXSJ2bdD/7t+X9qX4WwHMEmfs5Ww9csqf5jXA7dLoVuqj7k3nu/1uLnxrEIyK0qF11eD1DBReH116WogGi0s0yEUtM2QZcY+WFPnkmtqc7IAdA+WnAuahm7v4q8cVw5deWqz3usT/UQnHwwERs+OTJhLw6OLilwBU4j4COEfIcKjQ6WEhwiV41nohhiyCh50rw0mO0upnxE15rwQUxEVciJKQReMkBNRCroWBY+e3Y7nnBP3mupSVMHq7vHA8MX010xJMcONG7frj9299r5auBqF2XWt2TzeDWdP3e6EdLGKFWamf2RmVNjbs/nGyI9XpPsv0TEn4hR02o6GeLm7sBcuXtGyK7oEcvA95byoQHaPcAQ5R1DpfiFExW9qkaBGOocgT7RVBWMNg4Wfp71jsBrGCoM1MDYyWLiFKJTL4AgTymVwiAnlMjjGhHIZHGSy6LKXVTGMN53TnzbdhqaeFc1poK6ty916+PWV6pcUFlYYegxDj2HpMSw9xvkBINAKoRWeVjhawc/c0ApNKxStqFiFjrSC9rmmfa5pn2va55r2uaKtIiLKn++ItEKzCmIenp7HuWOkaEXFKoh5CD2PQGeGQGeGQGeGQGeGQGeGQGeGQGeGQGeGQGeGQGeGQGeGQEdtoHd7mDUIOAW9VkR8RHonRnonRnonRtqDkfZgpPNupHNipH0e5/0USiG0wtMK2B/HF0Vul5wV+C6ZFJpWKFpBzwP34KQQWuFpBe5BxWaGSVGxCsLniq1Rk4K2StFWKdoqwueK9vm8N8Ep8F2i6V2i6V2i6V2iaQ9q2oOa9iDdmfB0Z+Lc6yP8YWh/GDoGDb26dIflqsvJKfDVtfQ8LL1LLD0Puu8ztW6FVuBjeHoM+l7r6Xvt1F0WWuFphaMV+Dzou8GkcLQCt4o+WV615TkFbJXQp6VJ4WgFbhVdz4Wu50LXc6Fr1KRwtAK3iq4GQlcDoauB0B16oXO70Lld6C7n1asQp8CtonP7pHC0AreKzu1C53ahc7vQuV3o3C50bhc6twud2+VBbn9Znf7/wfPsPyysit91vz89DAZlJWox3trK6M/P/wCdsulv]],
		},
	},
}

Public.small_crashed_ship = {
	name = 'small_crashed_ship',
	width = 20,
	height = 20,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdmdtum0AQQP9lnyGCXfbmX6miyolRgmSDZUhbK+Lfawy2qtZb5uTJQpo5nj07awbzqV72H/Xx1LSD2nyqvt0e86HL307Nbrr+pTa6yNR5+hgz1bx2ba823y6BzVu73U8hw/lYq41qhvqgMtVuD9PVz67b1W3++l73g5oS2119YZXjc6bqdmiGpp4514vz9/bj8FKfLgGPCZk6dv0lqWuXovL4ZK9l5fbJjmP2D0hLQWEFZKQguwKqpKBqBWSFoOLGqR5znJBTrnA83jP9GBTuoObUpTH+hjGPMVFYj1nhlIUQ5FbWVfKuLhMkcVvfJRUJkriv3RqpwickRbL4iKRI0t4Oa8K9qCdXbQdhPXENFOHhT3B0AQ9/iiNt7ZuhhGetoaBUPQae2cSR1dKm1gsn8duoLT1mLgGSdvTtkIWJc7nbDs1+udX+/Y3lfGPP3XhH90PX1vlxO7yrqYZUhsUZFc4wOEPjjFKcEamqSE1FKipST5FqitRSoJYCtRSopUAtBWopUEueWvLUkqeWPLXkqSX/NUv0C+RSHd0FR3fB0V1wdBcc3QVHd2FOkFdkqVVLrVpq1VKrllq11Gq1JBQ0w9EESxMqmmBogtyrwZoM1WSoJk33ek4AExMesfCEhQcsPF9RSXMCXYLYER1b6dBKR1Y6sNJxdY4XHxvacrTjaMPRfqPtVjI9Gi5Xw+VquFz6E6S/slzxag20Y6AdA+0YaMcwO/QmVsFyllnCs3iID9LwZV6k8R7GGxivYXzJ4gsWDumweOg+SsPpExx9gPNMpWcq6VM6fUgPrPrAqqd/rMT/VfOcze/eNn+8ycvUj/rUXwE6lJWP2hvvbVlU4/gb/D3pyQ==]],
		},
		-- {
		-- 	type = 'static_destructible',
		-- 	force = 'ancient-hostile',
		-- 	offset = {x = 0, y = 0},
		-- 	-- bp_string = [[0eNqNkMsKwjAQRf9l1gnYtLSaXxGRPoYaaCclmaql5N9NWhHBjavhwr2Hw6zQDDNOzhCDXsFTPUm2snemS/kJOisELPGoIMC0ljzocyyanuohVXiZEDQYxhEEUD2m9LC2Q5LtDT1DGlKHiRUuApDYsMGds4XlSvPYoIuFD6GfSfLsHHKkTtbHiaW3UrkZySoE8UNQfxHkjshDEtrU9dcjBNzR+a2tjllRnVSVl0VxyFUIL3QmY4M=]],
		-- 	bp_string = [[0eNpNjtsKgzAQRP9lniM0VonNr5RSvCw2oBvJpa2I/97EQunjLGfO7IZuirQ4wwF6g+kte+jrBm9Gbqd8C+tC0DCBZghwO+f0snYgLvoH+YBdwPBAb2i53wSIgwmGvp4jrHeOc0cuAT/DGLkI0TkKybpYnyqW817SNLXACl3Ias/CY1r/fSrwJOcPvmxkpS6lOitVy1PiP3NJRQo=]],
		-- },
	},
}

Public.small_basic_factory = {
	name = 'small_basic_factory',
	width = 22,
	height = 25,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqlW9tu6kgQ/Bc/m6OZnju/sopWwPEm1hqDbGd3o4h/XxOIIWQM3RUpD0mUrumprr7Z5L1YN6/VvqvboVi+F/Vm1/bF8o/3oq+f21Vz/N3wtq+KZVEP1bYoi3a1Pf7U75pVt9iv2qopDmVRt7+r/4qlPpQPLYdu1fb7XTcs1lUzXBnT4aksqnaoh7o6+fDxw9uf7et2XXUj+hxGWex3/Wi2a4+njlALbeIvVxZvxdJE/cuNh/yuu2pz+hN79PIGmyTYfh7bZ7CNBDvIsK0E28mwHca34fDtMWziYIeLSoddWy3+eu3a1abKh/IMbA8ZoDgB1W1fdcP4u/shMxxa08W97appFlUz/nVXbxb7XZN30t4c0Fb188t699od00Sbp8whWmEEOw7BGsxEywInIHw+Fz5txEyHGyK+MJ1KotLELN2WJxU7T3ROKtpJYS0LVpR9RiiOgIkjsMAjBu5Z4AlQXswpj5S0cgRO3EhLYT0Lln5QkUKuIpUu5bKEDKY7ljTIYuAsaZDLTj4ZZLqIbvwuKw7PxjIPscBkS6xLg8kWWeBAsiWV48CIky2xpjYtrb2RBUuYTFkRM2CCsSJmLCSHxJq/DTZsJsUC94DWKKu1INRa4m0IEZ9UzhTwKrBJQlF/Jzi7hShIdzxpWI2Bs6Rhxb2P0o37X5i3doZ5e0nNutu1i81L1WdvQP4Lfg7Kin02d32mrMNgRrLWP4vtf4m1/1lgAUzZBdBGabqwNkArzkJi7etgFrIi5sAsZEXMkXy8+nA7h2Xk49UsFtjyWIuSAxOMtUU7pOVlt2gnbnms1dZJH64k1mrrfvB05XzCl9r4sfGXY5fw41d29fdg1rE04sGsY2nE0w+mDv+dq3zj80Za7FhLq8fWvcTaJb3DwFm7pBf1PprAv20AlAMPmOc8cPmYenE/5gRTRpfVTMJuwdpjgihhlYyiIEpYLQSX7I5XnZIHLtkdr4ZgHrgkW68mYB64JFspCMEl2UpWCC7JVnJCcMnjGxLWmSDJUBLWmSjJUBImUbxk6Krvq+26qdvnxXa1eanHMUnfrWJWncbZ8YB6P61yz9U4Zf77Un28Cv1+HonPm7LrdF4OlNlU1QSkZoCYLy70QyAHL9InzJveMPaaGMvkc+0heukubdXMLh2DPDpmTg2b3X5fdYvNaj3eOHeYuH8S3eNo5FyrUOr8K8DI2zKvrjMT2qTkHKm7GdMP9ebvHEOJ99CVHsoxEdJwrJpZBBMv366AWHtvssgoYpXjFLrkkFGEC+7Fo+DFfTsn5ZyMU5BWKDsTw4hMT1w+EjI9McG14r3iuMKd4UArjeWFm8MjZPZi39tg3s7e3iLDXMbb7Ft15ZBpjo3ueRqwj1kI4jbk7ubuXJ/WChpB2YxAMygXXfQJGlJSdI2MuGx04mlFPdSK/DM0Ot3XytPxY35D3Zw/4/e9kKfPz6gdbh5h7lfDy8fQkHk6+gMbktskK7AJwDmfNgawQXxzgI0HbAJgE+U2SQM2ANeIDhLAdZJw7QG9eSCmnzZJbpMUYKMBG4ADkQ48Hp8UABtJLjggpg6IjwPu4+D7jBufwMYCNdECerOfTxkAGwPYSO5jgF5iAN4MoB0D8PZpQ4CNhAMC6igBdYcADgjgQAPx0YBvGvZNFh8N5IICOFDyekBJfs5kIz9HFJ/JRsAbRcC3KK/Xkw1yjgVsBLMYAbPl2UbGQQA4AGaks43sHGA+mGzk5yC+yXRggfsA8wEB8wEBvZ6AHjzZaLGNqMZPNpL7AL2RgN442RjARnIfoAcT0IMJ6Kek5OfoJOdaP+g/T+XpH0aXV/+ZWhb/VF1/ek4ctQ2JggnB6RHj8D81h5kU]],
		},
	},
}

Public.small_early_enemy_outpost = {
	name = 'small_early_enemy_outpost',
	width = 32,
	height = 32,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-hostile',
			offset = {x = 0, y = 0},
			bp_string = [[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]],
		},
	},
}

Public.small_nuclear_powerplant = {
	name = 'small_nuclear_powerplant',
	width = 27,
	height = 29,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[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]],
		},
	},
}

Public.small_market_outpost = {
	name = 'small_market_outpost',
	width = 32,
	height = 30,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[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]],
		},
	},
}

Public.small_abandoned_refinery = {
	name = 'small_abandoned_refinery',
	width = 20,
	height = 16,
	components = {
		{
			type = 'static_destructible',
			force = 'crew',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqlmO2OojAUhu+lv2FCv07BW5lsDErXaRYLAZysMd77gu4Co0XOmf0nhvfp+W7phe3Kk60b5zu2uTC3r3zLNu8X1rqDz8vhv+5cW7ZhrrNHFjGfH4enypVxY386b5szu0bM+cL+Zht+jValbVc1+cHGXe5/zaTi+iNi1neuc/Zuwu3hvPWn4842PXsk1K7u5VV8aKqTL3pyXbW9rPLDmj1KZ286Yme2iTmHN92vUbjG7u9viMHEB7SY0Kdj/QwEvoiDAE6GfX3GyslO3YMDKIV3Wk0w9WilCqA1Hq0ntMQEAL6gX9sqw44bAkKEEemIcE3l4/2HbbsAyKzakn0rCTwM40m4iV5VcZI+JTRi/W93a6+8+Mz93hbxwKubam/b1vkDCy3O18Karjsg0OGAh3Cs1iSXK/bNicmCffiegamwkwxT2Fzj7bslLcQAAiNbYBjkiNF8YsECC9cn81gtkQiNMo2+RGMiLxI8G16wg+N/tSvMV2KIIdayOsuEWmBIAmPJDoXdfGY+SVSUCBvGjC1QbMCz0xfsYOWsbSXzyl7YAURKYCxsRyL7ztwMxa8/KHWu/HtKegxPMo6O67wSvI3rvPu4bQqLkpQuAbSE0w0bJYYuwRsm6IYJesQE3RfxH75otETS3Zd0XyTdF0n3RY3HabpEoCXTORstAXqQgV5jQM+LGU9TZMk3VkkkWpLS85LSa2yU4FOZjd+CWAn8m5bc0CWCLMG7P33XGrpE0CWcLMH3Cwhy7wN9jIOkR0ySxwUo+iqKXpaK3PujhJAXRe590PQa0+RGBkPeX4A+xyClr5KurNKf/25XapvZ5V3Eynxny+HNY16W23yX+6KXFNvZDcOnbdr7GTLlymTCSGP0ELLrH2p3Tk8=]],
		},
	},
}

Public.small_roboport_base = {
	name = 'small_roboport_base',
	width = 18,
	height = 14,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqtmN2OmzAQhd/F17jCf3GWV1lVFUlcYonYyJiq6Yp3L4RsUjVhIx+4SpB8Po/PzFgDH2RXd6YJ1kVSfJDWlQ2NnlbBHsbn36Rgm4ychx/RZ6Tctb7uoqHjusa6ihQxdCYjdu9dS4r3gWArV9ajNp4bQwpiozmRjLjyND4Fv/OND5EMNOsOZtyg/54R46KN1kyMy8P5h+tOOxOGBTd17SvbRrun+6NpI22jD2VlBnrj20Hu3TVm9U1dgqbDn77PHog8mShfEMXjCR8Y+URgz/Typj+Zg+1O1NRmH8MQWOPrJ/GIz3jY83hU8gn1C+ImmUg/TcufEzVOpDPIbTpSvUC+3ZA2eDfhvsjHDIXlcMmJGWJ6W1B+Rc4UMUvvi7Fa7sihkaOtr138/8rtZNCmv7eK+WmdOdDh8tgHEw0ZY5qRKUwmMZmAZNhmqSfTmI/TNU45JmOQLE9UKWwztWCz1L0k5r6EUj2pUvcSWIgCazSBNZqADBGQIRwzhGOG8Nkr5Fj+KcNdTYOtjvErBl+BwZYz8uUIDpmIWZ+aZ4aVB1shz2yFPLMV8syW55lB1ymDqoMhec6X5ytfnq58ebbyxclaoXRXqNwVCnd53XJo4OPQMMWh8WZSJQaIzQACOpaAjiXwYyXOGtjIJiEvJOSFRAZYiRgoEQMVZKCCxieFXO0bZFrQUOdrqCw0VBYaybBGMqxfGzi8218+5RX/fDHMyC8T2guGb5nUb1wLrRXLZd//BX8UtTY=]],
		},
		{
			type = 'static_destructible',
			force = 'ancient-hostile',
			offset = {x = 0, y = 0},
			bp_string = [[0eNpNj+8KwjAMxN8ln1tw88+0ryIim4YR2NKSpuKQvrvtFPFTOLj73eUFw5QwCLGCe0HkPlj1dhS6V/0E1xwMLOVss4F+iH5Kirb6AvEITiWhAbp5juDOhUAj91PN6hIQHJDiDAa4n6sSP/jgRaHQiO9YC/LFALKSEn4Yq1iunOYBpRh+6TGx1SSCWojBxxLx/N1p23Wn3efKW1vd33MGHihxtbfHZted2m7bdftms8v5Df+gVeQ=]],
		},
	},
}

Public.small_solar_base = {
	name = 'small_solar_base',
	width = 18,
	height = 28,
	components = {
		{
			type = 'static_destructible',
			force = 'crew',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqVmO+uojAQxd+ln+GmLYWCr3JjDLCNkvAvUDZrjO++4Cp1r0XnfPTm/s6caTszLRdW1JPph6q1bHdhVdm1I9t9X9hYHdu8Xv5mz71hO1ZZ07CAtXmz/Bq7Oh/CPm9Nza4Bq9pf5g/bies+YKa1la3MP5nbj/OhnZrCDPM/rAJFdQxNbUo7VGXYd7WZtftunMmuXaLOapEO2JntQiGjOURrquOp6KZhEZZ6fw1e1KXX3qtu/BXflYX+iq8epYiolDql1K+kaEpKfPQUr0p5WU7NVOe2GzyeoodO4lNJiCrpWxXtsmryug7rvOk9IplLKvEnlaJJKZ9Khm+88vsRHF0fryEhiNvOPzsinmr5tNhiQ4p6rAlSCqpkucr9rGQR+ypZuMM+TsVo85vYq67a1lVeXXf8q6Frw/JkRuvRTT4vgCZui2sRfKNFCGoRiIdQ5pWhVkH00ZGkVkHy1pEkVoHUzlG84UiSOs5TEfCNjiMjdLW1V0bhq72VW4yutt9RQnTkeg7f6DlSI9Ut73M6y16KcL9cCGxV328DP8Gn47MGnG8g5WCsYYuvTSBFAY0CCQrEKMAdMNquNfOG2dM7JMvIhP6vMRJcrQAHAa5QgKNZAHmvY1kSXaVoGtkjQgQC1AgRByM4QIIA2ZJAIwg0gkQjSPCErwC1dziAmsN6SdUoIFGAmvR6QUpRQKNAjAIKBDgagbxx62UvQ4EYBKhjxQHUCI+xIhW1WTokghHySiXoeUrQpU3Q85SAoy5CLxEReolwXzrom6fxzVsRDtoiTyINXugcQO1PKWopQ5NGB7ziYASFDnglUECCZeoAjQIJCsQo4K3r+V1x+yK5e/qAGbA6L+Ynz/2NeLg9gw5FPi6Plt9mGG/qMhVKZ1JHWsfLiLj+BTlvnzs=]],
		},
	},
}

Public.small_mining_base = {
	name = 'small_mining_base',
	width = 16,
	height = 14,
	components = {
		{
			type = 'plain',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdmdtuozAQht/F11D5CEleZVVVJPGmlohBxqy2qvLuCzk0q9RO5+cqoh1/9tjzz4zhk23b0fbB+cg2n2zwTV/GrjwEt5+f/7KNMAX7mH7UqWBu1/mBbX5Nhu7gm3Y2iR+9ZRvmoj2ygvnmOD/Z1u5icLvy6Lzzh3IfXNuymeD3doaeih8ZMTR+6LsQy61t43+D5em1YNZHF529rOb88PHmx+PWhomeYxSs74ZpWOevzvGXi3eleTHTBHsXpnWf/63nFT5wJZkrstwqwVVkroS4msxVENeQuRriVmSugbg1mVtB3BWZW0PcNZlbfh2cegTLBFhwOllgZLrmSomR76obJ/2HQ+im35/0rL/pufjKMr4f53TyfSaF5w2aC3QhliDZ4KlDUVKdqPBcR1vxXYzODzbE6Y/5dKQochF3HQ6x87b8PQbf7GwibVyD45SirAkLq7LxlVqY5HiCmMEplMBRKoOSC9KLzLDUApbIsO4qGY5N25ZfTUTftfZZHpHnw/DWHd633RjmnsDI19QUC+QiSJ1BhYMlCVyDsS2SW7vCttY829k6ubOQegSpK1qgnkyYqgXqyUSpWqIenmEtUE8OpeHaxSnxp8yS6svz1bcbY6b8KlxDNBdqXJs08AopZZwU82s8UDMRoXH55EgCD9OMevQC9WQ0re/icaHz5e7dDk9iMkfRhDPkPziFVxVS7te4IEjFSiMtmCRdNMEOTCa3ESkhpApicAlkjtjgBSQTcEaCXc7tCq2+l2KpU6XYLKgqmVbRaByVaWANLhJNCWaDi4R0ATI1dk7PjmmVPCZQM+ldRTRDurNUuGYywVPhmsnETrWgapgMCn/XRno1WGkgpyZeAr1ODZJrr68zH32qb9fWh4jpm/h+7qQyAxQ4gIP2Fdm+urbn4AAB2qN8Q7Y3qAMGnEChZ3wZQLeX6AQSdVnebqDYAA7aowuiq0CA6xEYn4MnwDF3OabJy+JL1N6A9hq0V5g9eTkSdBeNfgXyUb0rLCEqbHc0eLga3B0NpgaNhb7GcqEB996AqzfYWRnMWbCyPC+9U99x/uq6+e87cMHaZmqJbp3v2+Ub7tu2Gebm9I8Nw+Xt/kroei1rVddGcH06/QOxRNQf]],
		},
		{
			type = 'entities_minable',
			name = 'electric-mining-drill',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			instances = {{position = {x = -6, y = -3}, direction = defines.direction.east}, {position = {x = -6, y = 1}, direction = defines.direction.east}, {position = {x = -6, y = 5}, direction = defines.direction.east}, {position = {x = -2, y = -1}, direction = defines.direction.west}, {position = {x = -2, y = 3}, direction = defines.direction.west}}
		},
	},
}

Public.small_primitive_mining_base = {
	name = 'small_primitive_mining_base',
	width = 12,
	height = 12,
	components = {
		{
			type = 'plain',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdld2OgyAQhd9lrmGjCLX1VTYbg8q2JIgGabNN47svVLvpj+1CrxQ983EGZuAEldqL3khtoTjBoHmPbYe3RjZ+/ANFmiI4+seIQNadHqD4dEK51Vx5iT32AgqQVrSAQPPWj6q90cLgVmqpt7gxUinw8boRHjmifwmD7bTA347Da3EVS8YvBEJbaaWYrJwHx1Lv20oYB3+CQNB3g4vq9JwYpufEMB29nTsKeZnKI4tcWAgaaUQ9/VstkLNI8uySLLmkfyxpOo3rnRjsIyL9YBPDvSxRWJyjZKqH20zpAncVx2Wh3PytvcluwWQBvA4tnWQmLjA2oQz2nJEm76yc21vXGlaquS/ul2EuAjbeOey53YF38SSABgfQ2Blo7AzTWUQi9VmoPpn7JE5P4uTBbtJL5wfqSaSexrmnce5ZHJ29oru6Pt8OxdVthUDxSiivbLlSpfvaOuBBlFOzlBUffNsdhBmmjl+nNN+QPMtzlibu1P8F5nhJ4Q==]],
		},
		{
			type = 'entities_minable',
			name = 'burner-mining-drill',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			instances = {{position = {x = -4, y = -6}, direction = defines.direction.south}, {position = {x = -6, y = -4}, direction = defines.direction.east},{position = {x = 0, y = 1}, direction = defines.direction.south}, {position = {x = -2, y = 3}, direction = defines.direction.east},{position = {x = 5, y = 1}, direction = defines.direction.south}, {position = {x = 5, y = 5}, direction = defines.direction.north}}
		},
	},
}

Public.small_oilrig_base = {
	name = 'small_oilrig_base',
	width = 18,
	height = 12,
	components = {
		{
			type = 'static_destructible',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdl2GPoyAQhv8Ln3UjINj6VzaXhraky62iUXq5ZuN/P6ztrr3CMrOfWuO8j+8wA6MfZN+cdT8Y60j9QUar+tx1+Wkwx/n6L6mpzMjF/9ApI+bQ2ZHUrz7QnKxq5hB36TWpiXG6JRmxqp2v+nPb/1aHdzKL7FHPnOlXRrR1xhm9MK4Xl509t3s9+IBP9ei6QZ107pR998y+G72oszdDuXgRV0s5exGefzSDPiz32ZQ9YdmXKeOdPuP4Hef/TAEAf8jqOwALycvE84u7moYfLxJ6mtBLcP5FGFA9AJbu6M72GECxNeqhMjIA3kBXJmJsCzZ2J0VAtICnWERTDDUf/WpqM3Q2P7zp0T1TecJfqodlQs/B+cloemUIXILB1cpisjOoQJeWgvxKYMuxyELC9wJdkdL5bsBcEeMG228LbJzI2cEKoD6yXoymDp97W0TOXsbgO1OuUMkVZxzYCTFjJf7I4M8l8yPRmeY2D//XbZbSTOu5aHXeK/dGZkvheAaOr5adXmIFHCkokPHwDCQ2A4nNQCIzkMiafb45QAUlNgOOdERvbxNIAdhQgeQXuJ642RfI+BIZD/bDkH4Y0g//WTzHxYM3wNKeYDcCV1zxEzp46ZF7HbnV5Xdm/By4fkDVq8+xjDRqr5s5slVNs+tMM5jTbq/GeVz90cO4DJENLastq3hVCVqU0/QPomtrlQ==]],
		},
		{
			type = 'entities',
			name = 'pumpjack',
			force = 'ancient-friendly',
			offset = {x = 0, y = 0},
			instances = {{position = {x = 2, y = -4}, direction = defines.direction.south}, {position = {x = -7, y = 1}, direction = defines.direction.south}, {position = {x = 4, y = 4}, direction = defines.direction.north}}
		},
	},
}

Public.small_radioactive_lab = {
	name = 'small_radioactive_lab',
	width = 12,
	height = 12,
	components = {
		{
			type = 'static_destructible',
			force = 'crew',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdl22PoyAQx78Lr2UDgw+tX+VyaehKeiQKBnFzzcbvfthut+2e1MFXhsj8nIf/MPhJju2oeqeNJ/UnGYzsqbf05HQzr/+SmrOMnMMDpozod2sGUv8KG/XJyHbe4s+9IjXRXnUkI0Z286qVRzLvN42aEVO2ajE6afTYUevUgyVMvzOijNdeq+uHL4vzwYzdUbmA/gYMnWxb2squD9DeDsHEmq8YaP5WXKKgxVsxzd78wMCT5y/sxbK9uNtbc6J/ZHC/odoMyvnw/n8g3ICBHMJttFPv1/ewgM/vaQpgd3I2POlRtX4BzZ7RX9m2o+9HTxbgBSqFsJLB8puCiVpgoq5SoubP6NWod5tSCo9wbSLsfaIaWDQt5QJ9bsjVVP/weA3JX+sfHmlL9tj+YRH77f3DMEri+SYpMVS1+b2BfDjEht46vyqkWCLKDSweYVW4osZc2aV0NK4M+/ToIt4Bw6P4CoqnoyIpB9jY+RzTpSASGp+hiHna+Iy0PyR0wE0wqAkAZXppcOAqXYmR0Q+7LWcL4KYU7BPgLJaBEvElwZKuARElCJ7gr1j3N3roCkiXXIFRhhDpkotcicSmqZOjho7YMHQKzJEg8C33ghtu7Zfrff3we5HNY0i1N4EdnGy0lcHkQx2uA+pDueFamB3Pqz1UoqoKzvJp+gecSRog]],
		},
		{
			type = 'tiles',
			tile_name = 'tutorial-grid',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdl8FuwjAQRP/F50SK1wTa3Huo1Ft7qypkwKJWEydKDCpC+fdi4ICqqs3rCUXawbvjWe/OUa3qnet6H6KqjmoItstjm297v0nfn6rSkqlD+hkz5ddtGFT1egr022DrFBIPnVOV8tE1KlPBNulriG1w+ar36w+VcGHj0l+N2Z/I2q5uEDIBsett8Lsmb3t3gzTjW6air90l364dfPRtuBaVz89F5bPxW8qdje8qHfozYHp8eTmgpAB8gqEAgYACxmsYT/OhBU9ndHYhaE4BJQXglAwFCARoGE8Tmk6RoZwaqFIDCzZQpQYSZKBKDSRUqISESkggowIZFcioQEYFMqqpRDVte03v7ArQEDC5awpYcgELKP6Tjmbhk5PXsAEgl5olr5n6BQ4xgTdLXweByhRGJnxL4NNAh5GBjW5gmxhIvoHkw9kIRyOcjOY/dzX5quiyR3c9urnRxQ3uYXANo26EmpESChNaC+gsoLH41VecbOfZn1Y3zjpLttadLKx6eXx6eF4Oja3rZW83vrXr6PdumWxvpvauH87HyJ2eLe5lYRaLUhezcfwC7SoAxg==]],
		},
	},
}

Public.small_radioactive_centrifuge = {
	name = 'small_radioactive_centrifuge',
	width = 14,
	height = 12,
	components = {
		{
			type = 'static',
			force = 'crew',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqlmW2PoyAQx78Lr3UjCIL9KpvNxbbUI7FoEO9ub+N3P9Q+nZXKrK8a0/E3f4aZgWm/0L7qZGOUtmj3hVpdNLGt49Ko4/D8B+1wGqFP90H6CKlDrVu0e3eGqtRFNZjYz0aiHVJWnlGEdHEenlpbaxn/LqoKDa/poxxIfbT6ojWFbpva2HgvK/vwMuk/IiS1VVbJScL48PlDd+e9NI6+5DxCTd26V2p9WU3yxqblvLF+kDODkCAIvkCSZUgKUuKB0CAIeQ1hN8ipaG08C+4TjT0EJ0JHZeRh+pYssDPfnj1hKQTLg9bNXq9bBGvLfNroAja/YcvCymcYf1C1ulCcrNAyEC0s/fPXccOB+b9SADisAvBKCWAKKiTiocyKoHP9xJSmdp8r+UrGwF/aVN3Zphsa0rOD7H8HVV04D/79TGeJdnOhtM9DWFHgazdIPZEQMIwvoDloW5in0yYgCvVQ7mm/V2UsKxdVow5xU1cLFUUnQYuge+Yf3FdGnbryRU2yMTXcHqpx5zrXZVR3jhtTH2TbKl0ubSO5l0XZ6dh2xki7VBYvZFLYFvrCxoKUTCc/XyTMkr5tKmXtUtpfm6JYb2KEB/ftayPjIc2RhJ8HAsTNwyo/H5HZHJmtV36aBCu/dVPuuZVgOOpZ8hKYwHLSpw92bco9FNiZITwUBr7c+PSEX5PYA2k96Py7p5p4PNX8iSdgV8cMJD4PDgqHcGnyPdEipNgphsEFSDkBdygRcmOlKaw2PVlMgceOp6wog81oniGNZqApzYvhMDW+QU2AJjWvmrBbVbqCYWtTBXsErCY9Cxsr+JoqEjjrBKpKQcOOVxWFjSleDoNVx5RJH64Jq+ryW8Y85ya7/n4nrfXBXdHk2KoXjQnEOL0bG3lSWh7jn8Xfwhzj67txJU/WD6AQbwxinG2VxrcCBERuDjHGSZg1nqZiiDEOTBYyR0NjREDu0q3uUpA7utUdfXIHJTCQ4Ayy0xkIzSFoDkKLrWEWm8OcQ1aXg1Z3mb8TkHUwHFbbeHOgMJmfJd8kBB4wF+sUZE1B1mzzWrLNBA5SLEDWOcg6+FB51bndZWT8H2b38HdQhH5J006XMIEpzwlnmOE0S/r+H5sJhDg=]], --fixed to give beacon space
			-- bp_string = [[0eNqlmdtu4jAQQP/Fz3HlawL8yqqqApispeBEjtPdbsW/r7mVQO3aQ55QYHw8V48nfKJ1O6reauPQ6hMNpu6x63Bj9fb4/BetKC/Qh/9ghwLpTWcGtPrlBXVj6vYo4j56hVZIO7VHBTL1/vg0uM4o/KduW3RcZrbqSDoUyYUbZZzVu7FRk4UsY+Foa6PHPe7sdCU/vBbII7XT6qz46eHjzYz7tbJep5DKBeq7wS/pzMUHuHyRJy9g+SIPR20eMCwPIxMYnocRCYzIw9AERn5hmtqpAIBMAQXaaqs2599ZAFcmcDBalWUjS5i4yKLwBGWZRUlFjRJgLvIIB5rTIsJhwGyM6XPLaueLdOg76/Bate6nlBQ5OUBvib6rB4eTeAbDy2fxMU+UQCCJ6itC+Ooe33b11n//A5Y/QIuvs9X0o0OhPW4Vs9YNVq1fa/UG910bKGl23SZEyqsamfApg1YNjXBuVTP63mEb2/nPZKTZKTAXr3Wji7iNsVCH+yEy5MT1kdH9tLv1ttuoYdCmCe5yq7RmNNiN1qqA9uKietANAhYVFvGmhGFiQSmBwSURTpV/BIn7ECTOCLYAlvQVH9N0mVnDPKZkuoY5eSbVyTTT42xg84nkD2f5AeMT1J0ryhCYwzMhkpxcPBn6mM0yXzUGsvmh7Qx9q50LZtW1/7IMavVkd4y5E1hJBOSC5ZOdN4suCOgaGYm/oKAzM0ZhIEokGILDyjhyhRQChon0eCGz+hq+6BJElCC3xOypQJSYOQvYtBib8pYw58amvMwLFE9gKGxaiGFYauikE0CyPUueO8Pm4fLymSRslKDZNUYpQYfOifLqG7huL29CHj1RXabTw+2q2pmNrzR1avQRcQET5zdxq3baqC3+Xf+r7RZfV+NW7dxPCAbbkYLEyWz96GwCzEAOks4NV3l2XgkSz00d+Q0O9pQEbSjmbyhAG/L5G/LHDcEEBlKZwiJOIXACYhMIms72NJ3raAayDhQVDkJzCFqA0GKuk+S37vIkIfMEk9/6TYY0A0nTubaQuQAK0RdkHMhvoJAE09NfTE5/56wmf0cVqK39dHa83+z91ebN1lvd1f529q7e7l6ivSs7nK9sCyqqJat4VUlK/BzwH/11s2c=]],
		},
		{
			type = 'tiles',
			tile_name = 'tutorial-grid',
			offset = {x = -5, y = -5},
			bp_string = [[0eNqdl82K2zAURt9Fawcs68/yvotCd+2uDMFJ1FSMIxtbGToMfveJk1mEobQ+WRnDuZZ0vivDfRO77hyGMaYsmjcxpXbY5H5zHONhef8jGikL8Xp5lHMh4r5Pk2h+XsB4TG23IPl1CKIRMYeTKERqT8vblPsUNrsx7p/FUpcOYfnUXPy3ch9SHuOv8zHcFVYrCs9jm+L5tOnH+0o1PxUixy7ctj30U8yxTx9nK29Hmz/te2jzb7Es+Ve8YrhiuGG4Zbhbi0tmRjIzkpm54ZrhhuGW4VBkvRavrnjJcMnwiuGK4ZrhhuGW4au9KyZSMZGKiVRMpGIiFROpHhHp1+KaedfMu2beNfOumXfNRGom0rCjGnZUw3rGsH+kYWYs+0da1mKWtZhl3i3zblmLWebdPuJ9dUc6FpNjMTkWk2MxORaTYzE5dpscS9WxVGsWU82818x7zbzXTGTNRNaPiFx9PTzz7tn18Cwmz2LyLCbProdnqXqWqmepepaqLOGsAsc4+c857jLrXofi5m6qL0TX7sJlbhY/vn778n07ndqu247tIfbtPseXsL0buQvxEsbpulxVS+185Yw0Utlynt8B8lo3wQ==]],
		},
	},
}

Public.small_radioactive_reactor = {
	name = 'small_radioactive_reactor',
	width = 20,
	height = 18,
	components = {
		{
			type = 'static_destructible',
			force = 'crew',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdWO1uozAQfBf/xhX+JnmVU1WRxJdaRwwypmpV5d2PNBegF2+89FdFg4fZ8c6uvZ9k1wy2C85Hsv0kva87Glt6DO5weX4nW7YpyMf4x5wL4vat78n21/iiO/q6ubwSPzpLtsRFeyIF8fXp8tRHW59oHMLOeUsuK/3BXsDORXatH/aNrQMNtt7HNixWc8TqIdTeDSfahuV3xfm5INZHF529BvD18PHih9POhpHYBNC5EbUgXduPL7f+nwq0elJfOlDzpM4XHv8BcCD2eyS1RCrIwQW7v/7OE7giR4xniMkMAMusV9jA5Kq4NFqvSXmRJmjQW6fTANWCShvqo6Wx9n8SQOIGJDERbr7xurqqHfwhAcyWDL8B6wQwK9E5AUTM5nSPo1/6rg2R7mwT77HKG5RCUeNoYAojyxSyQMtZgmqmtonNBum7xsU4/hM2CUYDhdaArxNXY60MbbtBMxPrmFVoYLkOeJNLdZWpDjxrFp1DYGgECSBwfClQYI1J6cPFD/wmMX7jsy1+132kI1sbrqyzHxB3HyimZu27IZLU92bXON/b8NiG0FZptNB8VS3nBsFOrhN42Xasbej+1faPDAPFnLOIyACIEgsApLdgyAaqwQRJnnw42ncMIDa749XWkdr3/Wvtj6m9o5PMPIkkwePpAx+UAC2FpiUes8o1BJUTyPygMJWYwiQq9OZBKm2wCACALNfvPsv7VrLvsAA5mQlPchSMyMGI1bmEiVFiyPEcN4XOLgkmV6oySI2hl5XOYK8g5h8SB4AqpA0hIhusjQEAVWJvMMtIsjIrhutQU2kA9FHZQi4zAHOSN60/0jHDD/ZA4U48XYAgQIlo51Md55h2rhRyD27UUD1Q5Sp8TjmDTC1ofYURSkEhJYWasx1xprxB35+GpyNlO0TgTKlLbOIBRyPN8P1RQCKk2qPma0TgeRHAc7UWPz7HPzjGP9Bcri76KCdohcxkaCv16gEdanygzfoxD+rqqyvslEcBEW+wAMC4wJSrRy4KI5lhyDkGxIsj1wPCGLF2pInKBJObtJpMWAq5/ius5+I6+N4uBvgFaerR05e4TnXTvIT64NrxluLe7Mt8XXmzob8GUTFpNtwIYxQr5fn8FwKOuUc=]],
		},
		{
			type = 'tiles',
			tile_name = 'tutorial-grid',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdmUuL2zAUhf+L1jZYVw8n2Xcx0F1nNwxBccRU1JGN7QwdBv/3xuMWQqGtv65Cgk4k3XPuU+/q1F5jP6Q8qcO7GnPoy6krX4Z0Xr5/Vwe9K9Tb7aOeC5WaLo/q8HRbmF5yaJcl01sf1UGlKV5UoXK4LN/GqcuxPA2p+aYWXD7H5a/m4p/IfG3aGIZyiKGZuuEOLRvQ1yHkdL2U3RDvkGZ+LtSU2rieve/GNKUu/7xgqauPG5Z2/u38fZi+qmXXPyEMRshmxJ5usf/PHTQEVHA9vcF2GlZlljsKqCnAU4CjAHxpQwECAfRE9MrbbVqvF9hTwI4CagpwFGAoQChAQ4CF6+mVt9PsKWueOqenrHlKgqckeGgkR43kqLQdtaqjVnXUqo5a1cHE46ArWBqRLKXNUtosZcHSiGQpbZbSZmF9sa6nB6I3prKgFGzn2FAVGVpcGCoKQ0VhqChWAF1PD+Tg+u2kCSVNqOsLjdhCY4VQHQnVkVAdCZSFQFkIjBUCZSQw8QuUnaai0LgJppRpSIGGFGgYrjWkTEPKNKOsgoGigl5MpxwV87CKsVsxcivGVcVMr6HpNTS9huGQupaGSVWzQkszJUA/h24OvRY6rcDKnmZ3mtxp5qWJl+ZdgUoTpjSYRWESNZBcWm/T6pkWz4YZE1bOsHA2LNvCMtswZmlDTvtx2o5bWH3R7t3CsECbfdq6w87dMmXCvh227bBrt0yZDiqTzuvouI5O6xxUDh3uOSYFx4KUY2R5aHw6gaYDaDp/puNnz9zWMz/0zA9rGNPok0r9N6U9F+tL8uHuPbxQbTjF9vbb48PnT1+O4yW07XEI59SFZkqv8fjrkbpQr3EYP7aSnbb1XmpT105Xdp5/AHeIA5c=]],
		},
	},
}

Public.uranium_miners = {
	name = 'uranium_miners',
	width = 22,
	height = 12,
	components = {
		{
			type = 'static_destructible',
			force = 'crew',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqlmNtuozAQQP/Fz1DhG7dfqaqIBDeyBAYZU21U8e9rQtqkXWY9Vh5JPGfuHtuf5NjNarTaOFJ/ksk0Y+qG9Gx1u37/ITWjCbmQmmZLQvRpMBOpX/1CfTZNty5xl1GRmminepIQ0/Trl+rUyVl9SntttDmnrdVdR1aCaZWH0iUJMkbtf7yLMITIbBuj5z4d7KMkX94SoozTTqvN+uvH5WDm/qist+anzoSMw+QXD+YWgrR4kdcgpOJFLqsdvwAsBMgDAP4DsGVgmE37PxTfRwk8Sj5alZBWW5+16//5DliiwVkUNw8FLwsErwgAWCBiJVYe0F+hA8OjAkMzNLgEwWwPHCz478pg+y5TfMVDBB4i0BDhodLnfvyXQO/i4ZBIdBVC5uTYMoIAoTrmIUCokMsQoAoAigCA3SvW+a14Ggfr0qPq3E48qy9W9js/Yo98L9n3ZnKp7wJlt26AFJSgAp+p2/gYZjfOjuwpZHhXOKxpj8yjXREIV7SBPBHR+thzoZOxCp/zL0dnSsYlqoj1I38ubmWsPpo9Fbgqvlsppll5Fn+cYSgwxY4dCpyzGHbyQQD02IIA926c5uPkmqssMLv4LkGi5h7FlDhHH74gdwp0qtlDpvdI2GMYZEmFHJ+AvMiQww+Sp8jpC8lHDJwvUzjmaCM4HlxGgQW2G4GDs5BYAHTXyeMvO6ijtyjwMRNRMSuj+4VjdkZRIbsHSIXEb9kUCuSev5JGX45wl1GG5hawvW/J9oBQP7yCJKRrfKbX/blvuu5gm1YPjRf5UIfb+8Jhe9XwSz+UnTZWSUVRsYIXhaSZWJa/2sGVNQ==]],
		},
		{
			type = 'tiles',
			tile_name = 'tutorial-grid',
			offset = {x = 0, y = 0},
			bp_string = [[0eNqdmE1vozAQhv+LzyBhm4DDvYdKe9veqipyEitr1RgETtSq4r8XSg/RSrvLs0eieccz78xkPj7EMVxdP/iYRPMhxmj7PHX5ZfDn5ftNNEpm4l00Uk6Z8KcujqJ5ngX9JdqwiKT33olG+ORakYlo2+VrTF10+XHwp1ex4OLZzapmFf9EuuBOacblrY8+XvLz4EO406E26LgONvprm3eDu0Pq6SUTyQe3etB3o0++i99u5rL48jPX029e9Db9Esurf0IoisCA7TbtV5NKCsAvSAgooDzVr6D8docNpdRQSg3NI0NjYGAMDIxBDWNQwxis8ttDUEF7Kqh/R3OiXAE7CsAvSAgooDzVr6C8hvLbCdI0BBoSpCFBGhKkqAOK5pCiOaRgzBSMmaQuS+qypC5LFrUCGlRAe+BEQfmR/6N+cz7QjKYJrVgFK1bAinEDa4X+XWnIjWalSBsY7V8lHJpg94LNYse0V5CcCjpbsdSB00wNralZmcDZEI6Gq/hm5ukwDwdnODcbRo1h1BiWBnuYxHTV3MMthy6acM+EayPcGiXt438/Dbxk64mjuTvXZCLYowvzb0+PPx5+HsbWhnAY7Nl39pT8zR2+7yCH9ZQyA25uGL+eVEaW9V7Vuq53siin6RN6AsVA]],
		},
		{
			type = 'entities',
			name = 'electric-mining-drill',
			force = 'crew',
			offset = {x = 0, y = 0},
			instances = {
				{position = {x = 2, y = -1}, direction = defines.direction.east},
				{position = {x = 8, y = -1}, direction = defines.direction.west},
				{position = {x = 5, y = -3}, direction = defines.direction.south},
				{position = {x = 5, y = 1}, direction = defines.direction.north},
				{position = {x = -7, y = -1}, direction = defines.direction.east},
				{position = {x = -1, y = -1}, direction = defines.direction.west},
				{position = {x = -4, y = -3}, direction = defines.direction.south},
				{position = {x = -4, y = 1}, direction = defines.direction.north},
			}
		},
		{
			type = 'entities',
			name = 'uranium-ore',
			amount = 1000,
			offset = {x = 0, y = 0},
			instances = {
				{position = {x = 2, y = -1}},
				{position = {x = 8, y = -1}},
				{position = {x = 5, y = -3}},
				{position = {x = 5, y = 1}},
				{position = {x = -7, y = -1}},
				{position = {x = -1, y = -2}},
				{position = {x = -4, y = -3}},
				{position = {x = -5, y = 1}},
			}
		},
	},
}

-- Public.namehere = {
-- 	name = '',
-- 	width = ,
-- 	height = ,
-- 	components = {
-- 		{
-- 			type = 'static_destructible',
-- 			force = 'ancient-friendly',
-- 			offset = {x = 0, y = 0},
-- 			bp_string = [[]],
-- 		},
-- 	},
-- }

return Public