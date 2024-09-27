-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Public = {}

-- Unused
Public.refuel_station = {
    name = "refuel_station",
    width = 28,
    height = 26,
    components = {
        {
            type = "static_destructible",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdnO1O6zoThe8lvxsUf47NrRyhVwWi7kglqdJ0v2dri3s/KaVpWpx2Lf9CQNfjscczY48Rf4vX7aHe9U07FM9/i+ata/fF8z9/i32zadfb48+GP7u6eC6aof4oVkW7/jh+16+bbfG5Kpr2vf63eFafq4eS/VCvP8q63TRtPZPqz5dVUbdDMzT1aeivb/78rz18vNb9yJ4RxmE3v4bya/RVsev2o6prj0OOJCer4k/xXBr5PJpzg9ET5khpy/3Q7RKMODFW43jr06+KIgE0c2C733X9UL7W2+En1Mcn9431T24Evzd9/Xb6gE2QbQ5ZELKDyVItk32C7HGy4siCkzVHDjjZcOQIk52dyBbxoKom9GEMoH7Td+PXJbhbho8O+w7T7jDsDkNqiys+9lwq9tQl+F4PfVv3ZdPu634Yf/eTFCab3a3NOsW+xOF+t22GNPQSJ4D3lGXWOCBr3LRLS4yHpK/ujJRC4zHpFYnGg9JrEo1HpTckOgJbxc9i5jFSV7i1lrNWKxztSbTG0UKiibIYSHRWXXRIVtUuB41Z7XNqgYaslhy0gdCBzvwmeeqKOfEBmWiyQg9aWDOrex/r7bast+PH++at3HXb+m7OOPHbelyx1+7QH0+0Tr+kxpjVxK7ZJlPReWkVUgiNSR+17x3tMLBFwZ4Eu5z9W0EezIo6BaGFDg2VCg0TcvYvZmJW1EELay9Rt3yGm8WDQnKkvcTbrtnVd8/fR2AKoTMcrgM0ZZODjhDasntJx+TsL5HU9F1bvv2q93ePeV/mpUAeA+mHIMnYguCi5QQO6OoIJ2UtSIpz1YOdfTm6La2kU3ReB23TZJWLN366qnJjzfRxJSZV65yZNY7e14lVlWtHpRhwFZqOldovoBw3cZF7E1+Yck4B0lB7yOUc+zTWH6KPfTrZbHM5BQgz0ecc+7CF9YqqbRprjGUVJqgX5LMKE3Qh8pdoe1v3m678/3ozfjaxDZ7EVNYHOeP1UzAuGjkO0vXNyP1uolZP1nrlvY9WeavFKz0pm/b3+MGuHwntYbtNGXSJ2bdD/7t+X9qX4WwHMEmfs5Ww9csqf5jXA7dLoVuqj7k3nu/1uLnxrEIyK0qF11eD1DBReH116WogGi0s0yEUtM2QZcY+WFPnkmtqc7IAdA+WnAuahm7v4q8cVw5deWqz3usT/UQnHwwERs+OTJhLw6OLilwBU4j4COEfIcKjQ6WEhwiV41nohhiyCh50rw0mO0upnxE15rwQUxEVciJKQReMkBNRCroWBY+e3Y7nnBP3mupSVMHq7vHA8MX010xJMcONG7frj9299r5auBqF2XWt2TzeDWdP3e6EdLGKFWamf2RmVNjbs/nGyI9XpPsv0TEn4hR02o6GeLm7sBcuXtGyK7oEcvA95byoQHaPcAQ5R1DpfiFExW9qkaBGOocgT7RVBWMNg4Wfp71jsBrGCoM1MDYyWLiFKJTL4AgTymVwiAnlMjjGhHIZHGSy6LKXVTGMN53TnzbdhqaeFc1poK6ty916+PWV6pcUFlYYegxDj2HpMSw9xvkBINAKoRWeVjhawc/c0ApNKxStqFiFjrSC9rmmfa5pn2va55r2uaKtIiLKn++ItEKzCmIenp7HuWOkaEXFKoh5CD2PQGeGQGeGQGeGQGeGQGeGQGeGQGeGQGeGQGeGQGeGQGeGQEdtoHd7mDUIOAW9VkR8RHonRnonRnonRtqDkfZgpPNupHNipH0e5/0USiG0wtMK2B/HF0Vul5wV+C6ZFJpWKFpBzwP34KQQWuFpBe5BxWaGSVGxCsLniq1Rk4K2StFWKdoqwueK9vm8N8Ep8F2i6V2i6V2i6V2iaQ9q2oOa9iDdmfB0Z+Lc6yP8YWh/GDoGDb26dIflqsvJKfDVtfQ8LL1LLD0Puu8ztW6FVuBjeHoM+l7r6Xvt1F0WWuFphaMV+Dzou8GkcLQCt4o+WV615TkFbJXQp6VJ4WgFbhVdz4Wu50LXc6Fr1KRwtAK3iq4GQlcDoauB0B16oXO70Lld6C7n1asQp8CtonP7pHC0AreKzu1C53ahc7vQuV3o3C50bhc6twud2+VBbn9Znf7/wfPsPyysit91vz89DAZlJWox3trK6M/P/wCdsulv]],
        },
    },
}

Public.small_crashed_ship = {
    name = "small_crashed_ship",
    width = 20,
    height = 20,
    components = {
        {
            type = "static_destructible",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdmdGOmzAQRf/Fz2TF2Bjj/Eq1qrIbtIuUhSiwbaMV/94QSFS1QOb0KUG6vpo5HuMb5cu8HD7L46mqO7P9Mm29O266ZvN2qvbD8y+ztWlizsNHn5jqtalbs/12EVZv9e4wSLrzsTRbU3Xlh0lMvfsYnn42zb6sN6/vZduZYWG9Ly9e0j8npqy7qqvK0ef6cP5ef368lKeLYN4hMcemvSxq6qmo9Mlfq8qefN8n/9hYpY2s2zilTbZukylt/LqN1zZ1g+PnfXKtj6z7BLhXYd6muNtUp2bRxE4m+bxJ1Pbk1n0k1Rrl610JneRiwUc7yjdAccFHO8vugU8Gz8SSj4eHYslHPc3FA9BBNYcSHtRTaOuJD4wiPe7Dl9mXYUoP/KKTdqjvlAbLWSdLMS3W5OiJFbvgpB1tuZ01Wbp+PDxssvA6surpvh0TuY735ZbtqsN0xf79whnvmP7u3HZNXW6Ou+7dDCXMyj2T50wemLxg8qiVCyMjjIwwMsLICCMjjIxlZCwjYxkZy8hYRsYyMo6RcYyMY2QcI+MYGfc/ZMRCvbrZjJHPGPmMkc8Y+YyRzxj5US5Oq/eMpGckPSPpGUnPSHpGMr/KUybPmNwzec7kgcnVIAMjExiZwMgUbFdHuajtI6smsn2KbJ8i26fI0MQp10K9PgTBOCkwTwoMlAITpdBImU4/XtQLaKqksZLmShosYbKc9AAQTIsC46LAvCgwME563LD+TApMjQJjo8DcKDA4TnpACMYpgXlKxtTgoF6ELtB3MN7WFuod1Aeop/VHqAcjkdMtyOHPldsC2rPomw4QaoBQA4UaKNQCdgCD3KQHHRS0A5ifJv1SRc/J+D/Z9o9/3RLzozy1VwtbSBaiDV68uDzt+99fs91j]],
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

-- Unused
Public.small_basic_factory = {
    name = "small_basic_factory",
    width = 22,
    height = 25,
    components = {
        {
            type = "static_destructible",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqlW9tu6kgQ/Bc/m6OZnju/sopWwPEm1hqDbGd3o4h/XxOIIWQM3RUpD0mUrumprr7Z5L1YN6/VvqvboVi+F/Vm1/bF8o/3oq+f21Vz/N3wtq+KZVEP1bYoi3a1Pf7U75pVt9iv2qopDmVRt7+r/4qlPpQPLYdu1fb7XTcs1lUzXBnT4aksqnaoh7o6+fDxw9uf7et2XXUj+hxGWex3/Wi2a4+njlALbeIvVxZvxdJE/cuNh/yuu2pz+hN79PIGmyTYfh7bZ7CNBDvIsK0E28mwHca34fDtMWziYIeLSoddWy3+eu3a1abKh/IMbA8ZoDgB1W1fdcP4u/shMxxa08W97appFlUz/nVXbxb7XZN30t4c0Fb188t699od00Sbp8whWmEEOw7BGsxEywInIHw+Fz5txEyHGyK+MJ1KotLELN2WJxU7T3ROKtpJYS0LVpR9RiiOgIkjsMAjBu5Z4AlQXswpj5S0cgRO3EhLYT0Lln5QkUKuIpUu5bKEDKY7ljTIYuAsaZDLTj4ZZLqIbvwuKw7PxjIPscBkS6xLg8kWWeBAsiWV48CIky2xpjYtrb2RBUuYTFkRM2CCsSJmLCSHxJq/DTZsJsUC94DWKKu1INRa4m0IEZ9UzhTwKrBJQlF/Jzi7hShIdzxpWI2Bs6Rhxb2P0o37X5i3doZ5e0nNutu1i81L1WdvQP4Lfg7Kin02d32mrMNgRrLWP4vtf4m1/1lgAUzZBdBGabqwNkArzkJi7etgFrIi5sAsZEXMkXy8+nA7h2Xk49UsFtjyWIuSAxOMtUU7pOVlt2gnbnms1dZJH64k1mrrfvB05XzCl9r4sfGXY5fw41d29fdg1rE04sGsY2nE0w+mDv+dq3zj80Za7FhLq8fWvcTaJb3DwFm7pBf1PprAv20AlAMPmOc8cPmYenE/5gRTRpfVTMJuwdpjgihhlYyiIEpYLQSX7I5XnZIHLtkdr4ZgHrgkW68mYB64JFspCMEl2UpWCC7JVnJCcMnjGxLWmSDJUBLWmSjJUBImUbxk6Krvq+26qdvnxXa1eanHMUnfrWJWncbZ8YB6P61yz9U4Zf77Un28Cv1+HonPm7LrdF4OlNlU1QSkZoCYLy70QyAHL9InzJveMPaaGMvkc+0heukubdXMLh2DPDpmTg2b3X5fdYvNaj3eOHeYuH8S3eNo5FyrUOr8K8DI2zKvrjMT2qTkHKm7GdMP9ebvHEOJ99CVHsoxEdJwrJpZBBMv366AWHtvssgoYpXjFLrkkFGEC+7Fo+DFfTsn5ZyMU5BWKDsTw4hMT1w+EjI9McG14r3iuMKd4UArjeWFm8MjZPZi39tg3s7e3iLDXMbb7Ft15ZBpjo3ueRqwj1kI4jbk7ubuXJ/WChpB2YxAMygXXfQJGlJSdI2MuGx04mlFPdSK/DM0Ot3XytPxY35D3Zw/4/e9kKfPz6gdbh5h7lfDy8fQkHk6+gMbktskK7AJwDmfNgawQXxzgI0HbAJgE+U2SQM2ANeIDhLAdZJw7QG9eSCmnzZJbpMUYKMBG4ADkQ48Hp8UABtJLjggpg6IjwPu4+D7jBufwMYCNdECerOfTxkAGwPYSO5jgF5iAN4MoB0D8PZpQ4CNhAMC6igBdYcADgjgQAPx0YBvGvZNFh8N5IICOFDyekBJfs5kIz9HFJ/JRsAbRcC3KK/Xkw1yjgVsBLMYAbPl2UbGQQA4AGaks43sHGA+mGzk5yC+yXRggfsA8wEB8wEBvZ6AHjzZaLGNqMZPNpL7AL2RgN442RjARnIfoAcT0IMJ6Kek5OfoJOdaP+g/T+XpH0aXV/+ZWhb/VF1/ek4ctQ2JggnB6RHj8D81h5kU]],
        },
    },
}

-- Unused
Public.small_early_enemy_outpost = {
    name = "small_early_enemy_outpost",
    width = 32,
    height = 32,
    components = {
        {
            type = "static_destructible",
            force = "ancient-hostile",
            offset = { x = 0, y = 0 },
            bp_string = [[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]],
        },
    },
}

-- Unused
Public.small_nuclear_powerplant = {
    name = "small_nuclear_powerplant",
    width = 27,
    height = 29,
    components = {
        {
            type = "static_destructible",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqlne1yKjkOhu+F3zDVlr/PrWydmiJJJ6GWAAXN7sxO5d4XEiCd0MZ66F9TZ478Ist6Jdmy+/wzeVju2812seomv/6Z7Fbzzaxbz162i6fjn/+a/JI4nfx9+E9+n07mD7v1ct+1s6PcZrF6mfzqtvt2Olk8rle7ya9/HRAWL6v58ji2+3vTTn5NFl37NplOVvO34592XTt/m3X77cNi1U4OkIvVU3v4FfM+VYxdb+cv7aybr/7dGyrvv6eTdtUtukX7qcPHH/7+c7V/e2i3B+wLwmK7Xs0eX9tdd0DdrHeHIevVaZ75D/8x0eYP/35U5geIXED+u14/tUWYdBvGKmFMcxvHXXAeFi+zdtk+dtvF42yzXrYDYO4D6mDjyapdvLw+rPfbo6WMTF0zFSO/B37BX36h285Xu816280e2uUNy8lB1enkabE9KPPxtzIAG9SwicDGrzVe7dptd/h/RUAzbNJ0gXie77pZGSffxsnqGRpDpmgaPXCDgI3CeBfIwqzNF0He2qfF/q3qlKYH+MMx3dQP+qSxehNYZAKnBxYErKeR8QhYTyTjEHDUA0cEnPTAAQEDxqFYJYBxKFqJUQMLihEiemAUI0TPPEHMEz3zBDFP9MwTxDzRM08Q80TPPEEEkTRcQ13DnlCdCjUrUX0PdagkalB9VkIxsEAr4QioJOxPO7khREsLCx2so6VkacaepH+dbl8UeTz81XbxvH9pb+Ro/wF6gFx8lP37g/cfK4jNdv3Y7nbHfcbQj0Tdj4RRP5I0xnE94wyBZA2Ivw3ivmiye5svl9X6KnxbsR/1lfOFEssZnVXzGKs6DclMrhjEqjS9ZI37NHUKTS85uqSpZ0snzY2la6YuToMdXDsd7S7p7j6LRDgZf2MyfhqbwZloaCehYvYM014cxvENTHRRkz694fvEpAm+XmCgMN/UHjghCHaa0+AZgeXbpqs5hCFgDe1Mbd16tNssF90wyDkH5R9aTSfPi+VxyBcxxKYDwHrfbfbdn5vtYr09/Nzh75ftczdEFX/HHk1nnsh3lTrgO/ZoOuDMd5Uq4NBoPCXc9pRg+EZPp53wrakO2EKSpzLJP2qBQiAOjm8odRPwfAusAw6a1NFUHCKStF8CSXxrq5ti5ptxFXCENeYFfcirjlXK1Mhg4oiG76F1M9BUlhfIwsLFL3JtDqXRZ0NkvV89XUOdkXIByTGDnoP1cbv106A5TU2TB63Jz+pPP1A7Veen9UrgyM+yr5GHqp+YeFmlRL7jYD9rgFPDqygdsOHAOlskUZ3ZXFK5KbSxktXhpBqOPk2dQ5YxGkdNIE0x4MCBpTD52G+vtsvZ8367mj8OhJdwwhlE0Wy5XHGOQ8E4ac49Yn92Vcjc8IhU6tMZDlVYgSyog1ZCsXcERaOha3Z3BEUdsurw0NRmHu4IVCqaZU0hZyxy65xg7S3fXfxbVj9W3m5q3OBhXM7k9LFkXdM02qNiV+GMacy30uhWyC9qIzWIUIWwNYhchXA1iFSF8BUIMVWIULgZU65ZjfKyQFSu+SWSuJKOqiPwPkqVQYc6FlLoDD9wiBjd4FUBcF1C+uiDWIZjlcxpau7vqwh8e2JUbRtjaqRwVd1qnAhVhFBBiFWEqLZPYm7bu8Iw3+3at4flYvUye5s/vh44O5Nbmc8Nn7U/7w/12mO7XE4Gfy+j7GVVkaF3q+G1nXezQvirLrUYnFVK/BJRr9hXciiC2TvAnIof4vTQZdcaXhWvTmnFBQl67XLVinoSiamCJXg5TNx3630P+M3U5DgY9Ht3EpRZzxdUtg3Jel4VPuwdaaSon54yvopltSkplBDc95jS/vX4Ol+93NzvhWEkr4pOTVWjoMKxVZzIcIo2TqSjVVYnq9SpLphrGE5pWr3rAqpkUsShTUvXn+HVSelgcOhdGKg5qYl98OrlUf1eorge/o7YHVRRxwW1dsXVierkVIRI6s1S0Ub5jpTkVYm91+KvQjdF8w9fADZ8i6dEVu8kCn0O462GvbEK47RFfxHBa4v+VEIIWh2KCKpIn6tTSRqYVIXJSJvSpEKDtCnCfDnxav+4bOfb2badP3brm/uRXEITluNLNgpWfRhVnJg+dBchvBqiOJFwR2QrgkVVT0Wqq5RUOPXVzrhSFVUTysRGndDTJ67qfNdEo41GpTnHWmhOVQSLOCJNCccxrhX18aB4uig1DBW01UR5VvGOcinrnEpdqJS1u6dQ0WmXGlxNSKN7nWOU1YSUegNJlCm4jGBJ0ivD1IL6BaF0Lp/YLrSsCTiSafpK1YNUYhvT8lQT2sGVcdjOtIiTdTvTqi9l3c40VnGEn/mJ8t2auo1V1s6pIYoG9zxalfW5o5K5ttZg6Ou1cuEhosjQzeZUevlsMn0vJboz3kxfTEnhqFeaRlmhiC0haGucsg6ijbJFHayySiojOG06/HprHUpY1TreVNVhh45lHFDeSB+smjakSWqL+arF9HXOV/6wugeyNQf/0q5kRGN4H0hpxF4PV/P5hfyJPfAM6xjURAZvXoux6kK0RFHj+LGWdoHUlx/KC8QvP+gCrZhIA3gs6ZhoyI46DbM2/BYOVKXXxlV+cMH2+fzDFT9S4e/ppFssTx9R+dkwOx2CvPftsWpnm3n3+tG7HpbPWnnz+ZKLiTsm7pl4YOKRiScmbqg8tPxhr87k4VIJXCuBiyVwtQQul6jtL5/f7WHilok7Ju6ZeGDikYlDQxoD5QXKQ9MbaHsDjW+gOQ21Z2byAj1ZoD0F2lOgPQV6s0D76wOD/foKl17cMnHHxD0TD0w8MnFqSGhJA9UxVJ/M5PXEOsnD+Qp0HYG+I9B5BHqPwPXSE9ExIjpGRMeY5RizHGOWY8xykFkOplwHmeUgsxxkloNMcZApDjLFQaY4yBQHmeKZ63uWgzxjime+7KEve+jLl2uMXx9dWa8et23XlqUFmlKgLQUaU+9pHnpOYJ4TmOcE5jmBxdjAYmxgfhmgXwbol+Fq23HLLwPy4nBViSikBUlDlxHoMwKdRqDXCHQbPaMiq1pOn22G6BDeUHylV0bklfEq6yukDZJW+nBiZz+JLWliS5pYCE4sBCcWJBMLkgm6Y7o6m6kvk9YZE3KvhNwr3eFe/RCpkFYvUWbOm5nzZua8mTlvZs570p3OFU62f+LwOv/ffPs0O6/XbLt4ee1u2MncP1R/Et6wJTzJC5RXRvGzNg1Vn+pv6AT0R8TnAY4OCHcs93lsHDE2jRib7x/bD6Z4rBkxVkaM9ciPhbl9P0zfFDeQg1etTwV6QNJM8wQ1z1AexA9D44eh8cPQ+GFo/DAj4ocZET/MiPhhRsQPMyJ+mBHxw4yIH9cdcA3DGWVp/EhKcYHh5qo/rUD3SDog6QQ1B+GD9psNbTifB9xFbhlBbhlBbhlBbhlBbhlBbhlB7uuuNx7L/F8YAdRMt2z7Z2A7+yQvUN4i7R2S9kg6IukE55mp3fFC+Xs81I6IQHZEBLIjIpAdEYHsiAhkR0QgOyICWVZeWBZ0LAs6llUjDgYd2Lo/yQuUt0h7h6SZZRK1zF1MdSOY6kYw1Y1gqhvBVDeCqW4EUx1jqmPUc/dQT10eeMgkj5jkEZM8YhK8N2A8TbB+BPX8CAr4Ea7omSt6ljQ881zPPNczzw3QcwPy3IB8Ed4VOMkDX6S3C0wYUR2yywNncWar+zJLuKKVxkUaJm7u1+w+0gZG2sBIGxgLA2MhvI9wkrcI3SHpiKQT1DxDecBxelfjPICZR9seN+yyxlmcWV/NZHYXxMQRTI7wAo+B9zdMQhRI6EwjIQrA2xsn+QzlAQXo/ZDzgIAmrPY6dkXkLO6o53g6QP/IDV7+MPA6h8nIlzMK5xl5fkaen6Hn05slhl4tOQ+gpgfelulDqwY+eYT3SE7ySuc5STsk7ZF0RNKGGhI86aPPrKWhj9zgfQMxaK3Q7QRB9w3k6r6BQjojaW1FJQZd8xOD7vkJfqFMnyjDJrAI8gHUBBZBPiDIBwT5wHXDWCNumDgzotohBZX4Iqh6EkElvgiqnkTQDVsRxj1h3BO0JRfW8RX8JBk2WQU1WQU1WQW1TcUiplrEVMuYahlT7VVBphFnNjfM6GpiW0Zsy4h93cXViLNVFbaqwlZV2KoKW1VhqypsVbXH7wKbpILanoLanuJQGHAoDDjGa8d47RivHeO1Y7x2jKiOUckxKjlGJceoxJqq4hiVWA9WYJdUUJdUUJf0JM00j0g6IemMpNXZ2jMieUYk9sr7LM7MaJgdDTOkMEOqacpawsJawhLgFhU2eQU1eSUg4gW0oQ2IpqjdLAHRNCCaBkbTwJJvYMk3sOQbWMxgT+qFtcUlsCDAetXCnuwLe7MvgeVq1pGWwGJGhDEDvqgX1GQ+SXsknZG0mh2RsYO1i4U1dM/iiYkzy6jZEZn/RlZr0g6xwEf1kmiDIcFPicntRuLv6WTRtW/H7yAv9+1mu1gd/4WY/7Tb3eenb5NxMUu0wbnGyvv7/wEw8RY3]],
        },
    },
}

-- Unused
Public.small_market_outpost = {
    name = "small_market_outpost",
    width = 32,
    height = 30,
    components = {
        {
            type = "static_destructible",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            bp_string = [[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]],
        },
    },
}

Public.small_cliff_base = {
    name = "small_cliff_base",
    width = 40,
    height = 44,
    components = {
        {
            type = "water_tiles",
            offset = { x = -256, y = 88.5 },
            tile_name = "water",
            positions = {
                { x = 246, y = -110 },
                { x = 246, y = -109 },
                { x = 246, y = -108 },
                { x = 246, y = -107 },
                { x = 247, y = -110 },
                { x = 247, y = -109 },
                { x = 247, y = -108 },
                { x = 247, y = -107 },
                { x = 247, y = -106 },
                { x = 247, y = -105 },
                { x = 247, y = -104 },
                { x = 248, y = -108 },
                { x = 248, y = -107 },
                { x = 248, y = -106 },
                { x = 248, y = -105 },
                { x = 248, y = -104 },
                { x = 249, y = -108 },
                { x = 249, y = -107 },
                { x = 249, y = -106 },
                { x = 249, y = -105 },
                { x = 249, y = -104 },
                { x = 250, y = -108 },
                { x = 250, y = -107 },
                { x = 250, y = -106 },
                { x = 250, y = -105 },
                { x = 250, y = -104 },
                { x = 251, y = -108 },
                { x = 251, y = -107 },
                { x = 251, y = -106 },
                { x = 251, y = -105 },
                { x = 251, y = -104 },
            },
        },
        {
            type = "cliffs",
            offset = { x = -258, y = 85.5 },
            name = "cliff",
            instances = {
                { position = { x = 238, y = -97.5 }, cliff_orientation = "east-to-south" },
                { position = { x = 242, y = -97.5 }, cliff_orientation = "north-to-west" },
                { position = { x = 242, y = -101.5 }, cliff_orientation = "east-to-south" },
                { position = { x = 246, y = -101.5 }, cliff_orientation = "none-to-west" },
                { position = { x = 246, y = -101.5 }, cliff_orientation = "east-to-none" },
                { position = { x = 250, y = -101.5 }, cliff_orientation = "east-to-west" },
                { position = { x = 254, y = -101.5 }, cliff_orientation = "north-to-west" },
                { position = { x = 254, y = -109.5 }, cliff_orientation = "east-to-south" },
                { position = { x = 254, y = -105.5 }, cliff_orientation = "north-to-south" },
                { position = { x = 238, y = -93.5 }, cliff_orientation = "north-to-south" },
                { position = { x = 238, y = -89.5 }, cliff_orientation = "north-to-east" },
                { position = { x = 238, y = -73.5 }, cliff_orientation = "none-to-south" },
                { position = { x = 238, y = -69.5 }, cliff_orientation = "north-to-east" },
                { position = { x = 242, y = -89.5 }, cliff_orientation = "west-to-south" },
                { position = { x = 242, y = -85.5 }, cliff_orientation = "north-to-east" },
                { position = { x = 242, y = -69.5 }, cliff_orientation = "west-to-east" },
                { position = { x = 246, y = -85.5 }, cliff_orientation = "west-to-south" },
                { position = { x = 246, y = -81.5 }, cliff_orientation = "north-to-none" },
                { position = { x = 246, y = -69.5 }, cliff_orientation = "west-to-east" },
                { position = { x = 250, y = -69.5 }, cliff_orientation = "west-to-north" },
                { position = { x = 250, y = -73.5 }, cliff_orientation = "south-to-east" },
                { position = { x = 254, y = -73.5 }, cliff_orientation = "west-to-east" },
                { position = { x = 258, y = -73.5 }, cliff_orientation = "west-to-south" },
                { position = { x = 258, y = -109.5 }, cliff_orientation = "east-to-west" },
                { position = { x = 262, y = -109.5 }, cliff_orientation = "east-to-west" },
                { position = { x = 266, y = -109.5 }, cliff_orientation = "south-to-west" },
                { position = { x = 266, y = -105.5 }, cliff_orientation = "east-to-north" },
                { position = { x = 270, y = -105.5 }, cliff_orientation = "south-to-west" },
                { position = { x = 270, y = -101.5 }, cliff_orientation = "east-to-north" },
                { position = { x = 274, y = -101.5 }, cliff_orientation = "south-to-west" },
                { position = { x = 274, y = -97.5 }, cliff_orientation = "south-to-north" },
                { position = { x = 258, y = -69.5 }, cliff_orientation = "north-to-east" },
                { position = { x = 262, y = -69.5 }, cliff_orientation = "west-to-east" },
                { position = { x = 266, y = -69.5 }, cliff_orientation = "west-to-east" },
                { position = { x = 266, y = -89.5 }, cliff_orientation = "none-to-east" },
                { position = { x = 270, y = -69.5 }, cliff_orientation = "west-to-north" },
                { position = { x = 270, y = -89.5 }, cliff_orientation = "west-to-east" },
                { position = { x = 270, y = -73.5 }, cliff_orientation = "south-to-east" },
                { position = { x = 274, y = -89.5 }, cliff_orientation = "west-to-north" },
                { position = { x = 274, y = -81.5 }, cliff_orientation = "south-to-none" },
                { position = { x = 274, y = -77.5 }, cliff_orientation = "none-to-north" },
                { position = { x = 274, y = -77.5 }, cliff_orientation = "south-to-none" },
                { position = { x = 274, y = -73.5 }, cliff_orientation = "west-to-north" },
                { position = { x = 274, y = -93.5 }, cliff_orientation = "south-to-north" },
            },
        },
        -- although iron is supposed to be limited, I think it's not that much of it to destroy its scarcity (considering max 1-2 of these bases may spawn)
        {
            type = "entities",
            name = "iron-ore",
            amount = 50,
            offset = { x = -256, y = 88.5 },
            force = "ancient-friendly",
            instances = {
                { position = { x = 256.5, y = -98.5 } },
                { position = { x = 255.5, y = -96.5 } },
                { position = { x = 254.5, y = -96.5 } },
                { position = { x = 255.5, y = -97.5 } },
                { position = { x = 257.5, y = -96.5 } },
                { position = { x = 256.5, y = -96.5 } },
                { position = { x = 257.5, y = -97.5 } },
                { position = { x = 256.5, y = -97.5 } },
                { position = { x = 258.5, y = -96.5 } },
                { position = { x = 255.5, y = -95.5 } },
                { position = { x = 256.5, y = -94.5 } },
                { position = { x = 257.5, y = -95.5 } },
                { position = { x = 256.5, y = -95.5 } },
            },
        },
        {
            type = "vehicles",
            name = "car",
            offset = { x = -256, y = 88.5 },
            force = "ancient-friendly",
            instances = {
                { position = { x = 245, y = -88.5 }, direction = defines.direction.east },
            },
        },
        {
            type = "static_destructible",
            force = "ancient-friendly",
            offset = { x = 1, y = -1.5 },
            bp_string = [[0eNqdW+1uq0gMfRd+wxXz6Zm8yqpakZamSAQiILvbvcq7L2k2kI8h+MzPVvUZH8+xx3bS38m2PpaHrmqGZPM7qd7bpk82f/xO+mrXFPX5d8P3oUw2STWU+yRNmmJ//mnoiqY/tN2Qbct6SE5pUjUf5T/JRpzSVeN+KIt9Vja7qilvTOXpLU3KZqiGqrw48fPD95/Ncb8tuxF7RtgXdZ3Vxf4woh7afjRpm/N5ZxhDv0yafCebTOT2lzmdPXpAkhPSoRodfMbQZsbQYQw1YbSfn/1X25XZ4Rh0SNt7sDT5qLry/fInMgCtb0LVNmX2eeya4j3kp7ETcMhH8xCxsh6P7ar37NDW5UroLp42ZbX72rbH7nwjwr8FDrHTIUXfl/ttXTW7bF+8f43Xm4nQKf7xlDEa1Y9QPsfAFN1+NN8V/17k8XQeTedVTV92w/i75zOsmM8wjzG3AVS3pO0AtnqBrQPYHsCWL7BDWhF5nOOa47iYU253bLLh2HVlEPi1DMV9vmVDm+269th8rGSeCmeeUBwFmBsgySKrWbB079+qsIThZzNNDgd5W5aD7gXvoIOEJrDN5yMEnsDCsTJYojw8WO1uT1DP1c6k0qeKQiVPRiYdS4dSxIErFrhkxV6DIpeK+TbfhDxfeJs1n/5tji/BmTg4sQDHy0F779f6tVDcnfPAI982wQKHs+4pNg89RmpsKOdUzpOYdauXqJidpJ6C4d0CUtTL9oO2Glml0O5NPBxwF1hFqQ4WMxWVcN4vRGTOt+340JVdtq+a84Py0VV1/eLR8y4IZwHn7J1zq0VLERpg93DAo3KVCgY4Kv+eOYTaP4X0lgbD1sgrp0Fs5JEjLHG0jML2LGwFYFswJqwGdK5vz9EIqVwbXg9P+dXXUB7qOQ+3bVUHPbspl8SIJJp9N/XTBspbMPW040/6nsIVTXsGdUKomzxKoMQRqIlLLMvCluEdzkspLAxxRrGxaBVLR3FmjcDGRGGz9gLGor2Te3D+LgXGVsyaUBYY4vU7lN/5H0JyUdGQnPJnfBQ2a+yxSMa5Zb+D2IJVtv0yaqhsW8ks2+KKGrovq17N9vJ1j7MwUdk528ZGt+wuDS8jms/zRDotiJvDcQjtCiy6wpybHBdogseMo2ATbC1zupiE5xZ2y5biwuPscnja47AUH/ewXfq7CHbZNM0GbuGZsx5GWogA5UwkuYokYtLWsQo7yShsVmEnBUdgoeCSZiKpVSQDIy188kEWLSrzwtAtjORE8Xkun/N8LBsu+BSSi7p11kNAPgqb9YC5HL69hWbJCRhJLiDFZRBrreRUFDZrH+Y09rS6PMgefpmmDoACL9OYAC748ZqzWHtBrN2Ho5j4Emv+dlE5Rqz528HrxknGFJgaw0XC5zEf2BFrPvMiCps1n3kZs2h69jskGK9ilkFMbB2zxGJim5iFDRPbxkwsTGzClkG00EL5uGTk+eiZc6VY81LkOfapPuklICS/ZjjWdwRELplTglr3U0XVAaafzBfu3PNfYMM+MleH51n1B0adzt/hGar6/y/wPK1yxPUdOT00IYdi+PqZbxZNiG8i8VMkfoq6jsmwifO4iYNNKMIEoK9x+hqnr3H6GqevcfoGp29w+ganb3D6BqdvcfoWp29x+hanb3H6hNMnnD7h9AmnTzh9h9N3OH2H03fXWQI3iTgFiJjHI+bxiHk8YlcTnAvhjhHuGBBkk8NBvpoAQZ5MHG6Cc3EWNzG4icZNFG4icROBm+C3T/jtE377iJIFrmSBK1ngSha4kgWuZIErWeBKFriSBa5kgStZ4EoWuJLxWczgs5iRuMYkrjGJa0ziGpO4xiSuMYlrTOIak7jGJK6xlUn8Lb38a9Dm5t+Q0qQutmV9XgT1ddF8ZJdNy7boz+vdv8quv3yDwAlNXpIxWhuyp9N/2UjJIw==]],
        },
    },
}

Public.small_abandoned_refinery = {
    name = "small_abandoned_refinery",
    width = 20,
    height = 16,
    components = {
        {
            type = "static_destructible",
            force = "crew",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdmGGPojAQhv9LP8OGKS1U/8rlYir03OawEMDNmQ3//UBYl9NWZu6TEt95eDvMTIuf7FhdTNNa17P9J+ucbuK+jk+tLafrP2wPu4hdxw85RMwWtevY/scotCenq0nSXxvD9sz25swi5vR5uqptFbfml3WmvbIp0JVmYg3RZmjX160+mbjX7vcqlA8/I2Zcb3trZgu3i+vBXc5H047sO6GxjZkXUV9cOZKbuhvDaresaPcmb0tK3qY1lbY1xfwrn+w9YPk39nJunmEAflbmYaVoi2KxyB+xwoMVaKxcsCnGrfwHG/Y4wTzhGTJc+MNzcq6kH6T8RRmsCvWU8oiN3+2tVHX5oV1hynhiNW1dmK6z7sQ8991trF+9tg0JOgGwzsBmtQBsGLvjsoAzjnf2VXA5puAgxTpTAWcCC8gDAOkfQ8+ghQNJAPRd/batXVy8m65/kZ8gB98G6RcKULlWaHAWBPvmJWzVfb7G+QZusvUQ78nnAQKgCSEP+BK/L0egdhP8FqCCYN/z5Julfy+1wLzmEk0IjGye0UeWL23jRt/batnlHwKTuf+HdZ86Eze6f78NYa98R5MDYPVAcwNLrxP1aDucZofTksOJ7vl/uQeO1ae01aZE+ynRfkq0L+YDHk0usfLlaIaVZ7RcZrTKyYipz+c9mian4kFg9YqWekUsnEWPflbL+xh6iMxDLSHqJVFPGJpANAREQ7M+I+rxU5zTOheIcxZSYn5SWq+DIPIFseAErX0XvaL6QfcvSGIBSWJHQk6c/UAdQaCod1Av7zAesW7/uuxXf/9ErNJHU03Ks66qgz5qV44h5WH10vxh2m4+pikQ+Y7nEiSkWTIMfwGLOd2Z]],
            -- bp_string = [[0eNqlmO2OojAUhu+lv2FCv07BW5lsDErXaRYLAZysMd77gu4Co0XOmf0nhvfp+W7phe3Kk60b5zu2uTC3r3zLNu8X1rqDz8vhv+5cW7ZhrrNHFjGfH4enypVxY386b5szu0bM+cL+Zht+jValbVc1+cHGXe5/zaTi+iNi1neuc/Zuwu3hvPWn4842PXsk1K7u5VV8aKqTL3pyXbW9rPLDmj1KZ286Yme2iTmHN92vUbjG7u9viMHEB7SY0Kdj/QwEvoiDAE6GfX3GyslO3YMDKIV3Wk0w9WilCqA1Hq0ntMQEAL6gX9sqw44bAkKEEemIcE3l4/2HbbsAyKzakn0rCTwM40m4iV5VcZI+JTRi/W93a6+8+Mz93hbxwKubam/b1vkDCy3O18Karjsg0OGAh3Cs1iSXK/bNicmCffiegamwkwxT2Fzj7bslLcQAAiNbYBjkiNF8YsECC9cn81gtkQiNMo2+RGMiLxI8G16wg+N/tSvMV2KIIdayOsuEWmBIAmPJDoXdfGY+SVSUCBvGjC1QbMCz0xfsYOWsbSXzyl7YAURKYCxsRyL7ztwMxa8/KHWu/HtKegxPMo6O67wSvI3rvPu4bQqLkpQuAbSE0w0bJYYuwRsm6IYJesQE3RfxH75otETS3Zd0XyTdF0n3RY3HabpEoCXTORstAXqQgV5jQM+LGU9TZMk3VkkkWpLS85LSa2yU4FOZjd+CWAn8m5bc0CWCLMG7P33XGrpE0CWcLMH3Cwhy7wN9jIOkR0ySxwUo+iqKXpaK3PujhJAXRe590PQa0+RGBkPeX4A+xyClr5KurNKf/25XapvZ5V3Eynxny+HNY16W23yX+6KXFNvZDcOnbdr7GTLlymTCSGP0ELLrH2p3Tk8=]],
        },
    },
}

Public.small_roboport_base = {
    name = "small_roboport_base",
    width = 18,
    height = 14,
    components = {
        {
            type = "static_destructible",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqlmOGOmzAQhN/Fv+EUA4shr1JVFSEusQQ2Mk51uRPvXiAk1zYkqse/IiTPx3rGa234ZIf2LHurtGP7Tzboqo+diRurjvPzO9vzPGKX6ScdI6Zqowe2/zYtVI2u2nmJu/SS7ZlysmMR01U3P1lzML2xjs0ifZQzZ/weMamdckpeGcvD5Yc+dwdppwV3dWsaNThVx/VJDi4enLFVIyd6b4ZJbvSttPSNluJ2bzSO0QMx8Scmr4np4w4fGMUC2JRnd3knj+rcxbKVtbNTXb1pt8rhaznZdjnkv0F6Tcy9ibcM8m2ggIG0DSy8gclrYHkHKmv0FfYiiicUvsMPW/kE6d8Rt3TnajeR/i2R/4Wcetipdm3gf1burp0zfvWI/Km0PMbTrVFb6SSbK9oUcUSUIKIUKg/blOeuOOJfcu1mRESIKPcTpcibUvxNwk+UIZZnULqryvPQElIgIT1FSE8RZAVBVuSIFTliRf7spjhVH5X90sZWNSf3nJAFEyiYkAcTCshxyHLfIyGQIyGC0xXB6YrgdEVwugK5MAVyJAQUbhGcUxGcUxGcUxGcUxnsQxnsQxnsQxnsA4cGuFWVQSqCVKWnCpr7VlUGqQhSYfvynZ15AtkBzcEcGoQ5NAmvqhJSeZuYQiamyLR0U3le7xwbozlBtwBBx4Og40FQ0IQF/T8T+PSnffk8t//jY1/Efkk7LKCk4JkoE0GceJrvxvE3mqSlIg==]],
        },
        {
            type = "static_destructible",
            force = "ancient-hostile",
            offset = { x = -7, y = -6 },
            bp_string = [[0eNpNj9EKgzAMRf8lzxVWnbr1V8YYOoMUNC0xHRPpv69VNvYULpx7kmzQTwE9WxIwGyzU+UJcMbIdcn6D0Y2CNY0qKrBPRwuYWwLtSN2UEVk9ggErOIMC6uac2PXOOxbIJRowe+JdAZJYsXg49rA+KMw9cgJ+7TFQIYEZJRm9W1LF0fec45qYbftO8/eBghfyssPlRZ/ba9nWutZVc4rxA5klTCk=]],
        },
    },
}

Public.small_solar_base = {
    name = "small_solar_base",
    width = 18,
    height = 28,
    components = {
        {
            type = "static_destructible",
            force = "crew",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqVmFuOozAQRffi79DCxo+QrYyiCGgrQSIGgRlN1Mreh2fS6phO3U+ky+GWq8pl88XyqrdNWzrPDl+sc1kT+To6t+Xn+PyPHbjZsRs7CH3fsbKoXccOfwZheXZZNUr8rbHswEpvr2zHXHYdn7q6ytqoyZyt2Pie+7Qj6n7cMet86Us7Y6aH28n119y2g+AByMtzZCtb+LYsoqau7MBu6m54s3arMT4Z4wPf2fJ8yeu+HanCHO+7F7QIenuBph9qouoPdQ9QEhqFiwWjwhhJxKjf3agHJiuK/tpXma/bV8ycwH2IoGkELrYR5hnLNauqqMquTYCQLKGYcCh7JBQehxApluE0bITH0JKErXBOTLB8Y4ZYtevijnUX5FDr9i1IIh2qZ1bys0O5CnUof5Zz1+edzybSC3S/BZVB6LPCy7Z2UXGxnQ8EHr8L3NBWcG18vtH5nFjoKyXIIFa6eeNFUEs9/sWMoJb6ama/YUaQ9pFHgW7sIyKB1tcEGRJc362QFLa+YTOaZmbdSfjGViIMNFvnma9emuw4jnBfVsv8/vHao1Ae3xoODEVrvWWjpbBaQ2oDqfeQOkXUQj7Vna+dHTLjL7/oFVXPv+1w790saomoRQypJeacHukyQwXNjYC8JzObI2oqW0JsCUUpIScKYiuIrSG2hqpWQ72vId/zIdEgYmqQBgpyPqpoRGwQcYqIeQypITY1M+l8KULEKSKm7vcpFOMyn2PyLhg/L6aAXkFuDKTGIqWWyiqXmByzTs3p8juAniUOZmnWS8gNdUSscoXJiVvLelelmkmgSLFByyUExyYtV5hcQ42nocbTyy8TRJ1C6nCbDufz6V/c4dufvR2rsny4NSx3q9N0kzjlWTce/f/atpvYYs+lSYVRXPFEx/f7f4rDdmk=]],
        },
    },
}

Public.small_mining_base = {
    name = "small_mining_base",
    width = 16,
    height = 14,
    components = {
        {
            type = "plain",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdmd1u4jAQhd/F10mF/xNepaqqAF5qKTiRE1ZbVbz7JkChonY7J1eI9vAxtufMTMwH27RH10cfRrb+YENo+nLsyn30u/n9P7bmumDv04s8FcxvuzCw9fMk9PvQtLNkfO8dWzM/ugMrWGgO8zvXuu0Y/bY8+ODDvtxF37ZsJoSdm6Gn4lfGGJsw9F0cy41rxy8fFqeXgrkw+tG7SzTnN++v4XjYuDjRc4yC9d0wfawL18XZp8vqVk964u98nMI+/1fNAT5gBRlb5bAmgZVkbI1gFRnLVwhX07kc4Ro6VyBcS+dKhFvRuQrh1mTuZ7jiESsSWL4iczXEpZtNQdy7246T7eM+dtPrLzbm32xc3GpL6I9zEfn+RRKuFrQF0A1oIK6G64WgVDdu4PJGi/duQB8GF8fpj/kSJCgW4XfvDWMXXPnnGEOzdalScaGeUpSaEpjMpVYqMLHCi8IMTqE4jhIZlIBLisyQJExSGdLdHcOhadvyNjH0XevytUOejyE4v3/bdMc4t38tXlJfgNtEkYYAA3MliWvBnE5va4Vt662VpvbVJvcVco0iDUALXJNJULnANZkMlbhrdIaEu8ZkSAruVYaSfFIvaLY632y745jpthK3D20FFuZqErdCupcmpXuN52gms9QC52RSS3E4SW2GhBunypDuxvGxC+X2zQ0/JGSOoghHaH9ZE95NKkp6KdwOlsSFhq6K9DyJDl1VciOh9mFJD6QLTJA5Zr2gfWSyTgusE3824vp7IxYq1Yg13lXqTKgKJs2pk0ThPuGkuxeNG6UmcS04MPEfzqlKnhPqG86TO4s9rdCuXBY4J5NDZoFzcklk8AbCM09RBr9c45ySN0YhBZYnnh5fpmnJt9cLzIcPrq5PrQ+Z0zfj23moSsolJjeYnJOj4ZepGpNbTF5h8slSRL3AghcgXmEHq64+oeo1htfYYq+jKCY3mLzC5DVVbrBgDEa32L5bbKkWNGB1uWzG5ByTg8FIMBhyNDW21hqsTSsMz8HCfdVbUE/fHs6xw+Vo8eZYTeBo+eZgBbxd+GJ6DeotqK9APXDC8qcTm4aM84+q6y8/8xasbaYR6HPifb38RPu6aYZ5Jv3r4nC5y6+4srWwmmsuzep0+g/Rks/m]],
        },
        {
            type = "entities_minable",
            name = "electric-mining-drill",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            instances = {
                { position = { x = -6, y = -3 }, direction = defines.direction.east },
                { position = { x = -6, y = 1 }, direction = defines.direction.east },
                { position = { x = -6, y = 5 }, direction = defines.direction.east },
                { position = { x = -2, y = -1 }, direction = defines.direction.west },
                { position = { x = -2, y = 3 }, direction = defines.direction.west },
            },
        },
    },
}

Public.small_primitive_mining_base = {
    name = "small_primitive_mining_base",
    width = 12,
    height = 12,
    components = {
        {
            type = "plain",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdle1ugyAUhu/l/MZG/NZbWRaDetaSIBqkzZrGex8Ut/TDbrJfBnl48h45J16gEUccFZcaqgtMko2BHoK94p1df0JFKYGzfcwEeDvICao3A/K9ZMIi+jwiVMA19kBAst6umqOSqIKeSy73Qae4EGDPyw6tciZ/GiY9SAw+jIe1eHM2mt8JoNRcc3RRrotzLY99g8rIXygIjMNkTg3yuzBX12zDPDiiXwt5MsWLiUDHFbZuJ1vxxn5elzBeS5j8mLgaZNAecNLPgmyXOsUuXZOkfnGcK7svM1nxZp5lhlvF+X/upbj3RiveYmvPpItxxVFu7rvwtcTu/ePT0XC2Y6G5WGbiAXNUOD9EHJk+gE2xitOtOPWzUz97csVzP7zYirsLTfzw3A/fHCZb5n0jnvvhpV/20i/70om5J//Cb5r5+juobn5PBARrUFiyZ0LU5m1vjCes3YzUDZvsuJ1QTW7SC5rkZZSnNKVxZkbkC/PPR4k=]],
        },
        {
            type = "entities_minable",
            name = "burner-mining-drill",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            instances = {
                { position = { x = -4, y = -6 }, direction = defines.direction.south },
                { position = { x = -6, y = -4 }, direction = defines.direction.east },
                { position = { x = 0, y = 1 }, direction = defines.direction.south },
                { position = { x = -2, y = 3 }, direction = defines.direction.east },
                { position = { x = 5, y = 1 }, direction = defines.direction.south },
                { position = { x = 5, y = 5 }, direction = defines.direction.north },
            },
        },
    },
}

Public.small_oilrig_base = {
    name = "small_oilrig_base",
    width = 18,
    height = 12,
    components = {
        {
            type = "static_destructible",
            force = "ancient-friendly",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdl9tuozAQht/F11BhY3N6laqKnMRK3YJB4Kw2qnj3mkC3ZLHLTK+QlX8+/jnYDh/kWF9V12tjSfVBBiO72Lbxpdfnaf2XVDSLyM096BgRfWrNQKpnJ9QXI+tJYm+dIhXRVjUkIkY206q7Nt2bPL2TKcic1cQZXyKijNVWq5lxX9wO5tocVe8E/6IH2/byomIrzbtjdu3gglqzGGJP4u7IPR39rHt1mn9lY7SBsm9L2vncwPgCow7mCU8fMgqHp75gvvPu4ivY/26xE17+HJ4BM+f+8PwhfJ6J9mrOW5BYgR76kXmwBbAmAVcl2NUXSPhBNAGT8lB+vnmj31Os+9bEp1c12C2T0h17e3NL+Q4gBedHeShB7gNzOFisPO5OBhXo3mYgwxlw5PJAJeE7oVyR9vMt4IVMQ2DvCJbQ2cn8GbMECgiUjNEdQLLEF4F4Bi/NirRbcpYCRyHki6MPjWLbMXcNWl0vd+D/hZn7Mq6vQqPiTtpXMhnyynOonM5XHU7OcHKBk4O9M5x3hvPOcN4Zrk3p8h8BKOc47wJnJp/Pepy8gMoLHL3ADUF5lyc4OcXJwW2iCc7NoodvP/orPUPq4Rt2nvoSrE+Rp1P6Kz6FN4AjE+a4nbXoQ4bcuX//SKpWn1wRqeVR1ZOykXV9aHXd68vhKIfpdvqj+mG+NArK85LlggqaZsk4fgLDu2eb]],
        },
        {
            type = "entities",
            name = "pumpjack",
            force = "ancient-friendly",
            offset = { x = -0.5, y = 0 },
            instances = {
                { position = { x = 3, y = -4 }, direction = defines.direction.south },
                { position = { x = -6, y = 1 }, direction = defines.direction.south },
                { position = { x = 6, y = 4 }, direction = defines.direction.north },
            },
        },
    },
}

Public.small_radioactive_lab = {
    name = "small_radioactive_lab",
    width = 12,
    height = 12,
    components = {
        {
            type = "static_destructible",
            force = "crew",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdl29vgyAQxr8Lr3UREPzzVZaloZN0JAoGcVmz+N2H7bq2q9TDV8bI/bzneI7Tb7RvR9lbpR2qv9GgRZ86kx6saub7L1TjLEFHfyFTgtS70QOqX/1CddCinZe4Yy9RjZSTHUqQFt1814o9mtfrRs6IKVmNGK3QauxSY+VNJJneEiS1U07J84tPN8edHru9tB79Bxg60bZpK7reQ3sz+BCjLxpe2ElE9sKmOZd/EHKXdzCaLEfTa7TRh/RD+NSbVOlBWuefP+DoL85jvdBGWfl+fkoW4Pm1QB5rD9b4a7qXrXsEszvwb5XN6PrRoQU0A5WufF46/gdZF0wggosIwfkdeFVwuaGW9BatdIBcRVqAhyrCF+BzA67WmN/lu0bEzw1f3sCWwoH9wgPhWxuGQfyD8w0GYqBdxteOcf60Gnpj3Yp9WKAEPJqUB0gFbCtDe1FG9C8H1b+KlhbIjWRgUr5CwtGkIkAiGzu9gPQloRGdzkHEPGo+lgHVcONfvFJBvEJ49L7AuEW0B6uA8nLDaVLCxhGpItg8pJ8D3kSzqFEfcAHFEflW6/kGz1lKou2GQR9TlEb77QReQm0ZMzgDzRkaP2ce9S+dBhTeb/wJ2H+Sn77d65t/h2QeP7K9OGxnRaOM8CGfcnceTJ/SDuedKXFeVKRgmGHKs2n6AYf9FMs=]],
        },
        {
            type = "tiles",
            tile_name = "tutorial-grid",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdl8Fq4zAURf9FawciS7Yk72dR6K6zG4agJKIjxpGNrZQpxf/eKOkihWHGp6tgOM9+7+o+O/dN7PtzGKeYsujexJz8uMnD5nmKx3L9R3SyrsRr+VkqEQ9DmkX34wLG5+T7guTXMYhOxBxOohLJn8rVnIcUNvspHn6LUpeOodxqqf5b2fv9XUW9ouI8+RTPp80whbtKtfysRI59uPU7DnPMcUgfQ22vM5WRPjU8+vxLlEf+FZfbtby88QyvGa4YrhneMtww3DLcQd1Xn9PN2hCXDK8ZrhiuGW4Y7qAyq6VRTEnFPKnYrIp5UjFpFPSkglJqZhvNbKOZlJpJqZmUGkqpoZQNc2XD9rthB3XDG4avXpGWjdqy3tuvNGNg76ubN8zyhjVvWPOGWd6yL5Rlx2qZMpZZ0jIhLXt3WPgycEwax5bbsQVxTHjHhHfMko4J75iD3dfOaf2f5y1bkQ+e3l9BXkPe0f7XD0DjBc0XkrlT0shAMwMNDf9ODZcYec2b3V1SrkpMDZdIKr4/PH572s0n3/e7yR/j4A85voRdibGVeAnTfH1QbaU2rjaNbKRqt8vyDtor+Uc=]],
        },
    },
}

Public.small_radioactive_centrifuge = {
    name = "small_radioactive_centrifuge",
    width = 14,
    height = 12,
    components = {
        {
            type = "static",
            force = "crew",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqlmW2PoyAQx78Lr3UjCIL9KpvNxbbUI7FoEO9ub+N3P9Q+nZXKrK8a0/E3f4aZgWm/0L7qZGOUtmj3hVpdNLGt49Ko4/D8B+1wGqFP90H6CKlDrVu0e3eGqtRFNZjYz0aiHVJWnlGEdHEenlpbaxn/LqoKDa/poxxIfbT6ojWFbpva2HgvK/vwMuk/IiS1VVbJScL48PlDd+e9NI6+5DxCTd26V2p9WU3yxqblvLF+kDODkCAIvkCSZUgKUuKB0CAIeQ1hN8ipaG08C+4TjT0EJ0JHZeRh+pYssDPfnj1hKQTLg9bNXq9bBGvLfNroAja/YcvCymcYf1C1ulCcrNAyEC0s/fPXccOB+b9SADisAvBKCWAKKiTiocyKoHP9xJSmdp8r+UrGwF/aVN3Zphsa0rOD7H8HVV04D/79TGeJdnOhtM9DWFHgazdIPZEQMIwvoDloW5in0yYgCvVQ7mm/V2UsKxdVow5xU1cLFUUnQYuge+Yf3FdGnbryRU2yMTXcHqpx5zrXZVR3jhtTH2TbKl0ubSO5l0XZ6dh2xki7VBYvZFLYFvrCxoKUTCc/XyTMkr5tKmXtUtpfm6JYb2KEB/ftayPjIc2RhJ8HAsTNwyo/H5HZHJmtV36aBCu/dVPuuZVgOOpZ8hKYwHLSpw92bco9FNiZITwUBr7c+PSEX5PYA2k96Py7p5p4PNX8iSdgV8cMJD4PDgqHcGnyPdEipNgphsEFSDkBdygRcmOlKaw2PVlMgceOp6wog81oniGNZqApzYvhMDW+QU2AJjWvmrBbVbqCYWtTBXsErCY9Cxsr+JoqEjjrBKpKQcOOVxWFjSleDoNVx5RJH64Jq+ryW8Y85ya7/n4nrfXBXdHk2KoXjQnEOL0bG3lSWh7jn8Xfwhzj67txJU/WD6AQbwxinG2VxrcCBERuDjHGSZg1nqZiiDEOTBYyR0NjREDu0q3uUpA7utUdfXIHJTCQ4Ayy0xkIzSFoDkKLrWEWm8OcQ1aXg1Z3mb8TkHUwHFbbeHOgMJmfJd8kBB4wF+sUZE1B1mzzWrLNBA5SLEDWOcg6+FB51bndZWT8H2b38HdQhH5J006XMIEpzwlnmOE0S/r+H5sJhDg=]], --fixed to give beacon space
            -- bp_string = [[0eNqlmdtu4jAQQP/Fz3HlawL8yqqqApispeBEjtPdbsW/r7mVQO3aQ55QYHw8V48nfKJ1O6reauPQ6hMNpu6x63Bj9fb4/BetKC/Qh/9ghwLpTWcGtPrlBXVj6vYo4j56hVZIO7VHBTL1/vg0uM4o/KduW3RcZrbqSDoUyYUbZZzVu7FRk4UsY+Foa6PHPe7sdCU/vBbII7XT6qz46eHjzYz7tbJep5DKBeq7wS/pzMUHuHyRJy9g+SIPR20eMCwPIxMYnocRCYzIw9AERn5hmtqpAIBMAQXaaqs2599ZAFcmcDBalWUjS5i4yKLwBGWZRUlFjRJgLvIIB5rTIsJhwGyM6XPLaueLdOg76/Bate6nlBQ5OUBvib6rB4eTeAbDy2fxMU+UQCCJ6itC+Ooe33b11n//A5Y/QIuvs9X0o0OhPW4Vs9YNVq1fa/UG910bKGl23SZEyqsamfApg1YNjXBuVTP63mEb2/nPZKTZKTAXr3Wji7iNsVCH+yEy5MT1kdH9tLv1ttuoYdCmCe5yq7RmNNiN1qqA9uKietANAhYVFvGmhGFiQSmBwSURTpV/BIn7ECTOCLYAlvQVH9N0mVnDPKZkuoY5eSbVyTTT42xg84nkD2f5AeMT1J0ryhCYwzMhkpxcPBn6mM0yXzUGsvmh7Qx9q50LZtW1/7IMavVkd4y5E1hJBOSC5ZOdN4suCOgaGYm/oKAzM0ZhIEokGILDyjhyhRQChon0eCGz+hq+6BJElCC3xOypQJSYOQvYtBib8pYw58amvMwLFE9gKGxaiGFYauikE0CyPUueO8Pm4fLymSRslKDZNUYpQYfOifLqG7huL29CHj1RXabTw+2q2pmNrzR1avQRcQET5zdxq3baqC3+Xf+r7RZfV+NW7dxPCAbbkYLEyWz96GwCzEAOks4NV3l2XgkSz00d+Q0O9pQEbSjmbyhAG/L5G/LHDcEEBlKZwiJOIXACYhMIms72NJ3raAayDhQVDkJzCFqA0GKuk+S37vIkIfMEk9/6TYY0A0nTubaQuQAK0RdkHMhvoJAE09NfTE5/56wmf0cVqK39dHa83+z91ebN1lvd1f529q7e7l6ivSs7nK9sCyqqJat4VUlK/BzwH/11s2c=]],
        },
        {
            type = "tiles",
            tile_name = "tutorial-grid",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdl82K2zAURt9Fawcs68/yvotCd+2uDMFJ1FSMIxtbGToMfveJk1mEobQ+WRnDuZZ0vivDfRO77hyGMaYsmjcxpXbY5H5zHONhef8jGikL8Xp5lHMh4r5Pk2h+XsB4TG23IPl1CKIRMYeTKERqT8vblPsUNrsx7p/FUpcOYfnUXPy3ch9SHuOv8zHcFVYrCs9jm+L5tOnH+0o1PxUixy7ctj30U8yxTx9nK29Hmz/te2jzb7Es+Ve8YrhiuGG4Zbhbi0tmRjIzkpm54ZrhhuGW4VBkvRavrnjJcMnwiuGK4ZrhhuGW4au9KyZSMZGKiVRMpGIiFROpHhHp1+KaedfMu2beNfOumXfNRGom0rCjGnZUw3rGsH+kYWYs+0da1mKWtZhl3i3zblmLWebdPuJ9dUc6FpNjMTkWk2MxORaTYzE5dpscS9WxVGsWU82818x7zbzXTGTNRNaPiFx9PTzz7tn18Cwmz2LyLCbProdnqXqWqmepepaqLOGsAsc4+c857jLrXofi5m6qL0TX7sJlbhY/vn778n07ndqu247tIfbtPseXsL0buQvxEsbpulxVS+185Yw0Utlynt8B8lo3wQ==]],
        },
    },
}

Public.small_radioactive_reactor = {
    name = "small_radioactive_reactor",
    width = 20,
    height = 18,
    components = {
        {
            type = "static_destructible",
            force = "crew",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdWO1u4yAQfBd+25XBfNh5lVNV0YRL0TnYwrhqVeXdz2la272wYblfkRMzmZ3dWRY+yHM3mcFbF8jug4xOD2Xoy6O3h8vzG9nRtiDv84c6F8TuezeS3a/5RXt0uru8Et4HQ3bEBnMiBXH6dHkag9GnMkz+2TpDLivdwVzAzkVyrZv2ndG+9EbvQ+83qxli9eS1s9Op7P32f+vzY0GMCzZYcw3g8+H9yU2nZ+NnYgvAYGfUggz9OL/cu28VHsRVhgdxvrD4ZzkDIr/B4RucghysN/vrryyCWidIqfukeCqmRFACGxTNikqiYb9QRZyeQqaMxZc3Gxq910dTBu3+3MLILxiOia39wenqpH5yh1vYZsPuB6yMwNIKWQlArHQt7zD7Yxx6H8pn04WIatUXVI0ixtDALYTLY7g1WsiFMMMkiK6mGIfOhjB/CRuDIxQQeGlZlrQSa18o6QrPrM5i1uCBeRZwmwiZ3+8ILGWTOrGeItdzYD1DVy2HukpMF1Znu4xjXMZWM/zWYyhnpsZfGSfgxQ18sWzHbpgCif3b6hTrRuPvWw9KkcQ3BpbTuZnCsONZ8m63GGO6cv9ixnsmgWJO2YIm6rqusABAYdcUuVlSCRVIdL5hSL8pgNbqixejQ2ne9i/aHWOZE99IURwODp+gAxqAkkBTWkSPc0q2f5EQR2U3owbTjOoGmTRIoRa5vgWm2io76bRKm5XTn7BxbuJ+bJxhQGQCpM4vIVSEHENu6ZoQO4FvwGBdxZoBlyh6ieriCn26WE5P0PGpwToQqtQWCwAEIypk22XbUJJKC4rbl3hCIJFq3yIFsFZ617tjOZf5wRxKeP9NpUxwxCbegmLFXCMEdutbkoA6iIhkf0/Kr7DlBSI0CLk4GFZUrrXm09PkAn17OljGyX4KwDwpK2z5AQckSdGtTIIixLZIyTJEUAgRwJla1v87wUfSidGc53d/nB+kQFczlE6ZfQmHmlKlyr7UoahjnWyw93vAWC5bLAB0hVblX7NQ1HFKUfTlI8SNoREAeVSdf4GJqgiVvFlNCi/QCJ/BPRbXa+7d5rq+IJ2ePX6J7qS77snrg+3nU4t9NU/r8eXV+PEaSEO5apkSVNBaVufzX66Zt4A=]],
        },
        {
            type = "tiles",
            tile_name = "tutorial-grid",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdmV2Lm0AYhf/LXBvw1fnMfS8WetfelSVMkmE71GhQs3RZ/O+NiQuhlNanV8HwjJk55zia47vaN5d07nM7qu27Gtp43ozd5qXPx/n4p9qKL9Tb9cNNhcqHrh3U9tsVzC9tbGZkfDsntVV5TCdVqDae5qNh7Nq02ff58EPN49pjmk81Ff8c2V4OTYr9pk/xMHb9w+hqxehLH9t8OW26Pj2MrKfnQo25Sfe5n7shj7lrlwWWt/WZ6bfJn+P4Xc0/+UfcMtytxYWdXf7n7J7hgeFSQb5ey1d3nuEVw+FkNMMNwy3DHRSSCg8XK6tXW9/4kuHC8IrhmuGW4Y7hHipTQx4udr2xmjml2SWomVOaSa+Z9BpKY5g0hoXYMCUNU9IwJQ1T0sDbiIGht2y3scwoy4yyTHnLdhvLjLLMKMseDxYhoZICpaQ5EKi9rBbfseA49oTgWBIcS4JjSViWWkIearPeKget8swqz65xzzZjz7YEz3LjWW48y42HQfAwCB7uCR4Gx8O7uIdBCywKgXkbmFkBih+g+AFuyAGaFaBZAZolJdsWFl5D3tD5lHQAXQH4C19Czz4GrDdBoAkCTaCNC61caOdCSxehoRAaCtzrCA2FwCtZKvYML7A6EtgdCax3BPY7AguehfeQD1RPTQesVwh2QgJLIYG9jcDiZuEDnT9eMF3x+tux0HZIaD0kGpoM+6SFryBfQ15DnupjIe8hH6j+2DDqgFALhHoAQmpgSGFVJ7CrE1jWLbyFvIO8UIHAzmWoZbCEW/ga8hryDvIe8gHyQgUClyVsswTWWfL3xum5uL8X3j683S5UE/epuX739enzpy+74RSbZtfHY+7iYcyvaffxyrlQr6kfbj9WedEuVM6IkdqW0/QLDVP83g==]],
        },
    },
}

Public.uranium_miners = {
    name = "uranium_miners",
    width = 22,
    height = 12,
    components = {
        {
            type = "static_destructible",
            force = "crew",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqlWNuO4yAM/Reek1EgQC6/MlpVacNWSAmJCBltNcq/L0mn285sXIz6mJZzsI9tbPgkx25Wo9XGkfqTTKYZUzekZ6vb9fsPqRlNyIXUNFsSok+DmUj97hfqs2m6dYm7jIrURDvVk4SYpl+/VKdOzupT2mujzTltre46sjKYVnlSuiRBjlH7H+8QhoDMtjF67tPBPiLz5VdClHHaaXW1fvu4HMzcH5X11nzfMyHjMPnFg7lJ8CY2DbI3saxW/ICzADx/Ds+/wa/qD7NpYSK6T8TRRPzBooS02vpobf/KHVqBpqVZDK8MyFY9l60IwCl7rlaJxQP7V3hZ8hhZaIYnLiFitkccSvNbVrB9hyk2zyF8HsCXAfxDfs/9uCMH/QcPiyGQ2QcZI7HpAxEE8zckZzCBQ3pWIYLiOQG7Z6rzB+80DtalR9W5/6luBwP/GRu+x3tP1N/N5FKf+8peawCgpxC9j9JXoxhmN86O7G3H0G5IcJ893jzWDRF2QxvICx67W/GSaCI6RvwV7yQ6RlREBamI9kO+pFsZux/LXtGtii5RiSnRPIseWgoUL0X2GAnMUgzZ4yA8tkdB+HsVTvNxcs0GhTpVuUshcG1OYtI7xw5ZkD8FfhhhD4Heo0IPXJAtFbZjAgQ8wzY8iIBiWy5EgG81NzFKzDTDc/zxGMXLkeVYAf4KJL4E8DL6SlNhyoIXaL1ElF5lfLmUmHORV9jiASIhIm4VFJJyz2VB4+9BqBgJhicuYIv91X97I6gfHjoS0jU+2ush3Tddd7BNq4fGQz7U4esJ4XB9uPBLP5Sdrlwl5UXFCkEFzWW2LH8B5NSQ4w==]],
        },
        {
            type = "tiles",
            tile_name = "tutorial-grid",
            offset = { x = 0, y = 0 },
            bp_string = [[0eNqdmMGOmzAQht/FZ5CwMdhw72Gl3tpbtYpIYqVWwSBwVl2t8u6FhEMqVa2/HkHfDDP/jPQbf4hjf3XT7EMU7YdYQjflccwvsz9vzz9Fq2Qm3kUr5S0T/jSGRbTfVtBfQtdvSHyfnGiFj24QmQjdsD0tcQwuP87+9ENsceHs1lRrin9Gut6d4hqXDz74cMnPs+/7pxwqIcd17oK/Dvk4u6fI8vaaieh79+hgGhcf/Rj2Not7l2v231uYuvhdbJ/8I14y3DDcpuL7hBiuGK4ZXjG8ZrhheLKQigmpmJCK7Yxiuiumu2K6l0z3kun+wJtUXLNiNMtesSWo73jBcJhdM7xieM1ww3DL8OQxGaa7YcoYpoxhylhWu2U7Y9nOWDYmy8bUsFYb1mrDWm2gexTQWAtolfBYIKnRy//Kn37uUGy4EvqrhJ4moantvIF8uj4l1KeE+kDflBrWo2E9Gp4sNZwvdHJZwfzQy3deQd5CPr1fA+uBLiehze28hbxMHwB0xp2vIF9D3kDeQj59IaD7Smi/O19CXkO+gryBfPr/ITR49VeDf80e9xbt0x1MJvru6Pr13deXz5++HJah6/vD3J392J2if3OH/XLj8LgfWQPe3LzcP6ms1KZRppKVLOvidvsF+s6+8A==]],
        },
        {
            type = "entities",
            name = "electric-mining-drill",
            force = "crew",
            offset = { x = 0, y = 0 }, --this was at y=1 but was one too low. If observed to be in the wrong position again, needs to be a half-integer
            instances = {
                { position = { x = 2, y = -1 }, direction = defines.direction.east },
                { position = { x = 8, y = -1 }, direction = defines.direction.west },
                { position = { x = 5, y = -3 }, direction = defines.direction.south },
                { position = { x = 5, y = 1 }, direction = defines.direction.north },
                { position = { x = -7, y = -1 }, direction = defines.direction.east },
                { position = { x = -1, y = -1 }, direction = defines.direction.west },
                { position = { x = -4, y = -3 }, direction = defines.direction.south },
                { position = { x = -4, y = 1 }, direction = defines.direction.north },
            },
        },
        {
            type = "entities",
            name = "uranium-ore",
            amount = 1000,
            offset = { x = 0, y = 1 },
            instances = {
                { position = { x = 2, y = -1 } },
                { position = { x = 8, y = -1 } },
                { position = { x = 5, y = -3 } },
                { position = { x = 5, y = 1 } },
                { position = { x = -7, y = -1 } },
                { position = { x = -1, y = -2 } },
                { position = { x = -4, y = -3 } },
                { position = { x = -5, y = 1 } },
            },
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
