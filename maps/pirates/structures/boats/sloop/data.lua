
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
		bp_str = [[0eNqVmu1u2zAMRd/Fv93CJPWZVxmKoR9GF6B1iiTdVhR59yXtgA3Yrsn704B9QMlHEiXxfbh7ep1f9tvlOGzeh8Ny+3J13F097rcPl+efw6bUcXgbNppO47C93y2HYfPl/OL2cbl9urxyfHuZh82wPc7Pwzgst8+Xpx+73cO8XN1/mw/H4fLh8jCfWXK6GYd5OW6P2/mT8/Hw9nV5fb6b9+cX/k8Yh5fd4fzRbvkdlFznj6im63w6jf9gNIiZ1jEWxNg6JgUxuo7JQUxex5QgJq1jahBT1zEtiCnrmB7E9HWMTEFOczhhjx2RJWqyOCpL1GVxZJaozeLoLFGf1YsoarQ6I0OiTqszNiRqtXo+Rr02b0KMim2ORxo125y/plGzzfFIw7O08/s1arY5v1+jZpszOWrUbHOmR42abY6QGjXbnBlSo2Ynx2yLmp28xT5qdnKEtKjZ2RkiFjU7exFFzc7OELFwDuIMEStkhqaAU0mOAE5jewiBol7nut6yFPU6FwckLAg0LbFZdQIcIzkGOIntagQKW92dlkWtzs0BVRaEmtbIvi6A00lOBnuYie1qBIpaXWS9ZTlqdXG6KBsLQk1LZF83wMkkpwJOOL+uTkDh/Lo5oMb+fNS0qNbF1iMqUa+LOiBhQaBphZ2tBZ0XsNN1B5zwxjF7EUXFluSRompL8Uh0hg1JdIoNSXSOjUiVTrIhic6yIUnZsQvErOGJ2xOzRhUvyQmJnboFJH+VzbMFJH+10mMOkRpNQo3rtJUgpsb7DWJqQsuESEqTUOvCghePlGgSah1tOEiVG204SJVbpdcnROINR6ROr0+A1Cd6fUIkodcnRFJ6fUIko8cvIiV6fUKkzK5PSPFe6JkAxVTZBQrGxG4sBWybOruzlIzubiZ2n4JRwu5UMErZvQrqKZmMNgpGldhtBo4q0ygYFT2XN0SizwUrIjX2xAIH1WkVUFThi8ridlX4rrK4fSXsnlPh/Sm76ZSOSPQpIQ6KPifEUdEnhTgq+qwQR8VO6qqIxM7qKugCfGJP5mFQ4bvLPyrAqJQ+nYdRGY2CUSWyfEYNkdj0HJMKWUSDSZWso8GkRpbSYFInq2kgKXyPWV2SkDU1mKRkWQ0mGVlYg0mJLa3BqMwW12BUYctrMKqyBTYY1dgSG4zqbJENRIVvNtUdNOG7TXUNDd9umutV+ILTXK/Cd5zm/sHwLae5XoXvOc2XobJFNxjV2LIbjOps4Q1EZfrgBaPokxeMoo9eMIo+e8Eo+vAFozJbhINRhS3DwahKJ7MQ1dhSnE/UzfhZqr35q/B7HL7P+8PHJ9rOQ7JrTVZS13Y6/QLM+swl]],
		-- bp_str = [[0eNqVmu1qG0EMRd9lfm/CSvPtVymhOMmSGpK1sTdtQ/C7104KLbR3pfvTYB804zMfGuk93D+/Tofjbl7C5j2c5u3hZtnfPB13j9fPP8Om1CG8hY2m8xB2D/v5FDZfLl/cPc3b5+tXlrfDFDZht0wvYQjz9uX66cd+/zjNNw/fptMSrj+cH6cLS853Q5jmZbfspk/Ox4e3r/Pry/10vHzh/4QhHPany4/28++g5DZ/RDXe5vN5+AejTsy4jolOTFzHJCdG1zHZicnrmOLEpHVMdWLqOqY5MWUd052Yvo6R0clpBsftsSGyeE0WQ2XxuiyGzOK1WQydxeuzWhF5jVZDafE6rZZGXqvV8sjrdbQ2RK/Y0fBIvWZH419Tr9nR8Ejdu7SxMarX7Gh4pF6zo7E5qtfsaGyP6jU7Gmar1+xomK1es5NhdvSanazD3mt2MoSMXrOzsUSi1+xsReQ1OxtLJLrvIMYSiYW8oSngVJIjgNPYGUIgr9e5ro8seb3OxQAJCwJDS+ytOgFOJDkRcBI71QjktrobI/NanZsBqiwIDa2Rc10Ap5OcDHKYkZ1qBPJaXWR9ZNlrdTGmKEcWhIaWyLlugJNJTgWcwh7VKKDKnrAI1Ng/Hw3Nq3WJ6xEVr9fFGFoRFgSGVtjdWtB7Abtdd8BxJ47ZisgrtiSL5FVbikWic0dIopNHSKKzR0SqdPoIScKmfZCk7NoFYlb3xm2JWb2Kl2SExG7dAi5/lb1nC7j81UqvOURqNAkNrtNWgpga7zeIqQktEyIpTUKjcwteLFKiSWh0tOHgqtxow8FVuVX6fEIk3nBE6vT5BEh9pM8nRBL6fEIkpc8nRIr0+kWkRJ9PiJTZ8wkp3gu9E6CYKntAwZjYxFJA2tTZzFIyqt2MbJ6CUfRbIEYpm6ugmZIx0kbBqBKbZuCoMo2CUdF7eUMk+l2wIlJjXyxwUJ1WAUXlLlQWc6rctcpizpWwOafC+imbdEpHJPqVEAdFvxPiqOiXQhwV/VaIo2I3dVVEYnd1FVQAH9mXeRiUu3b5RwUYldKv8zCqSKNgVIlsn9GISOz1HJMK2USDSZXso8GkRrbSYFInu2kgyV3HrCZJyJ4aTFKyrQaTItlYg0mJba3BqMw212BUYdtrMKqyDTYY1dgWG4zqbJMNRCU6FcUoOhfFKDoZxSg6G8WoxLbbYFRmM1uMKmzLDUZVtukGoxrbdoNRnW28gSh3xTOatrtrntG03V31TKbt7rpnMm13Vz6Tqai7+JnNheOuf2Y7qkpfZiGqsa04n6i74bNVe/NX4/cQvk/H08dPtF2WZNeaNMaWy/n8C9A5zAo=]],
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
	{x = -17.5, y = -11.5, direction = defines.direction.south, type = 'input'},
	{x = -16.5, y = -11.5, direction = defines.direction.south, type = 'input'},
	{x = -15.5, y = -11.5, direction = defines.direction.south, type = 'input'},
	{x = -52.5, y = -2.5, direction = defines.direction.south, type = 'output'},
	{x = -51.5, y = -2.5, direction = defines.direction.south, type = 'output'},
	{x = -50.5, y = -2.5, direction = defines.direction.south, type = 'output'},
	{x = -52.5, y = 2.5, direction = defines.direction.north, type = 'input'},
	{x = -51.5, y = 2.5, direction = defines.direction.north, type = 'input'},
	{x = -50.5, y = 2.5, direction = defines.direction.north, type = 'input'},
	{x = -52.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -51.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -50.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -17.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -16.5, y = 11.5, direction = defines.direction.south, type = 'output'},
	{x = -15.5, y = 11.5, direction = defines.direction.south, type = 'output'},
}

Public.crewname_rendering_position = {x = -67, y = -18.5}
Public.comfy_rendering_position = {x = -59.5, y = 0}

Public.landingtrack = {
	offset = {x = -53, y = -24},
	bp = [[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yuiGrG7K6IasbsrohqxuyuiGrG7K6Masbs7oxqxuzujGrG7O6Masbs7oxqxuzujGrG7O6Masbs7ohqxuyuiGrG7K6IasbsrohqxuyuiGrG7K6Masbs7oxqxuzujGrG7O6Masbs7oxqxuzujGrG7O6Masbs7ohqxuyuiGrG7K6IasbsrohqxuyuiGrG7K6Masbs7oxqxuzujGrG7O6Masbs7oxqxuzujGrG7O6Masbs7ohqxuyuiGrG7K6IasbsrohqxuyuiGrG7K6Masbs7oxqxuzujGrG7O6Masbs7oxqxuzujGrG7O6Masbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7olq1uyuiWrW7K6Jatbsrolq1uyuiWrW7K6Natbs7o1q1uzujWrW7O6Natbs7o1q1uzujWrW7O6Natbs7pLVnfJ6i5Z3SWru2R1l6zuktVdsrpLVnfJ6q5Z3TWru2Z116zumtVds7prVnfN6q5Z3TWru2Z116zumtVds7pLVnfJ6i5Z3SWru2R1l6zuktVdsrpLVnfJ6q5Z3TWru2Z116zumtVds7prVnfN6q5Z3TWru2Z116zumtVds7pLVnfJ6i5Z3SWru2R1l6zuktVdsrpLVnfJ6q5Z3TWr+/44xmlnXjv02qnXjr127mvnvnbua+e++DmyD9Jaqmupfri7SAIvSeAlCbwkgZck8JIEXpLASxJ4SQIvSeA1Cbwmgd8ftzjH8qwFWku0Fmkt01qotVTXUl1LdS3VxU+ppbqW6lqqH25GUsxLinlJMS8p5iXFvKSYlxTzkmJeUsxLinlNMa8p5vfHLc6xPMcCrb168dXtvtQuTO3G1K5M7c6s3Zm1O7N2ZxY7wFJdS3Ut1Q/3LvnuJd+95LuXfPeS717y3Uu+e8l3L/nuJd+95rvXfPf74xbnWJ5jgY4lWryK9t5r77343u061u5j7ULWbuTajVy7kWupLjaMpbqW6lqqH251cvVLrn7J1S+5+iVXv+Tql1z9kqtfcvVLrn7N1a+5+vfHLc6xPMcCHUt0LNLayRQvup1M7WRqJ1M8Gbvtteteu+9r930t1bVUF/vLUl1LdS3VD39n0LTE0rTE0rTE0rTE0rTE0rTE0rTE0rTE0rTE0rTE2rTE2rTE++MW51ieY4GOJToW6VimtXOvnXvxY2TnXjv32rnXzr147vZhqn2a1lJdS3Ut1cV2tFTXUl1L9cPfSDRhszRhszRhszRhszRhszRhszRhszRhszRhszRhszZhszZh8/64xTmW51igY4mORTqW6ViosVRrqdZSLX5ILdVaqrVUa6nWUq2lWkt1LdW1VNdSXexeS3Ut1bVUP/x9RzNfSzNfSzNfSzNfSzNfSzNfSzNfSzNfSzNfSzNfazNfazNf749bnGN5jgU6luhYpGOZjoU6lmrs1WOvXrsztTtTrAC7M7U7U7sztTtTuzO1VGuprqW6lupaqovNbqmupbqW6ke/TQ9NLR6aWjw0tXhoavHQ1OKhqcVDU4uHphYPTS0em1o8NrX4/rjFOZbnWKBjiY5FOvipsFDHUo2lGnvvsfcee++19167kcWCsRtZu5G1G1m7kbVUa6nWUl1LdS3VtVQXvzcs1bVUP/rte2jw9tDg7aHB20ODt4cGbw8N3h4avD00eHts8PbY4O374xbnWJ5jgY4lOhbpWKZjoY6lGks1lmrwI20nEzuZ2MnUTqZ2MsX6svteu++1+15LtZZqLdVaqmuprqW6lurit5Kl+uGvXxoePzQ8fmh4/NDw+KHh8UPD44eGx48Njx8bHj82PP7+uOU5FuhYomORjmU6FupYqrFUY6nGUo2de+zcY+ceO/fYudfOvXbutXOvfZpqn6ZiU1uqtVRrqdZSXUt1LdW1VBe/8z6aKu0oOLSj4NCOgkM7Cg7tKDi0o+DYjoJjOwqO7Sg4tqPg/XELdCzRsUjHMh0LdSzVWKqxVGOpxlKNpRpLNZZqLNVYqrFUa6nWUq2lWku1lmot1VqqtVRrqdZSXUt1LdW1VD/8BUzbKg5tqzi0reLQtopD2yqObas4tq3i2LaKY9sqjm2reH/cEh2LdCzTsVDHUo2lGks1lmos1ViqsVRjqcZSjaUaS7WWai3VWqq1VGup1lKtpVpLtZZqLdW1VNdS/fB3JC3/OLT849Dyj0PLP44t/zi2/OPY8o9jyz+OLf84tvzj/XGLdCzTsVDHUo2lGks1lmos1ViqsVRjqcZSjaUaS7WWai3VWqq1VGup1lKtpVpLtZZqLdW1VD/8NUYLSQ4tJDm0kOTYQpJjC0mOLSQ5tpDk2EKSYwtJji0keX/cMh0LdSzVWKqxVGOpxlKNpRpLNZZqLNVYqrFUa6nWUq2lWku1lmot1VqqtVRrqdZS/fA3DW0aObRp5NimkWObRo5tGjm2aeTYppFjm0aObRo5tmnk/XELdSzVWKqxVGOpxlKNpRpLNZZqLNVYqrFUa6nWUq2lWku1lmot1VqqtVRrqX74y4D2cBzbw3FsD8exPRzH9nAc28NxbA/HsT0cx/ZwHNvD8f64pRpLNZZqLNVYqrFUY6nGUo2lGks1lmot1VqqtVRrqdZSraVaS7WW6of72lY9HFv1cGzVw7FVD8dWPRxb9XBs1cOxVQ/HVj0cW/Xw78djqcZSjaUaSzWWaizVWKqxVGOpxlKtpVpLtZZqLdVaqrVUa6l+tFKvze9fm9+/Nr9/bX7/2vz+tfn9a/P71+b3r83vX5vff3/cUo2lGks1lmos1ViqsVRjqcZSraVaS7WWai3VWqq1VD9aetempq9NTV+bmr42NX1tavra1PS1qelrU9PXpqavTU2/P26pxlKNpRpLNZZqLNVYqrFUa6nWUq2lWku1luqHa8mGSa8Nk14bJr02THptmPTaMOm1YdJrw6TXhkmvDZO+P26pxlKNpRpLNZZqLNVYqrVUa6nWUq2l+uHisCG4a0Nw14bgrg3BXRuCuzYEd20I7toQ3LUhuGtDcNeG4K4NwV0bgrs2BHdtCO7aENy1IbhrQ3DXhuCuDcFdm665Nl1zbbrm2nTNtemaa9M116Zrrk3XXJuuuTZdc2265tp0zbXpmmvTNdema65N11ybrrk2XXNN7V9T+9fU/jW1f03tX1P719T+NbV/Te1fU/vX1P41tX9N7V9T+9fU/jW1fw0DX8PA1zDwNQx8DQNfw8DXMPA1DHwNA1/DwNcw8DUMfA0DX8PA14jhNWJ4jRheI4bXiOE1YniNGF4jhteI4TVieI0YXiOG19zSNbd0zS1dc0vX3NI1t3TNLV1zS9fc0jW3dM1CXLMQ1yzENQtxzUJcsxDXLMQ1C/Gw31cf9vvqw35ffdjvqw/7ffVhv68+7Debh/1m87DfbB72m83D/h348f/9O/Cfvnn7/PXTD7/9tz9///dPP/38+cvXt2/e/vPTz7/86wXynH288tjeff32af/1vwFDR15t]],
}

Public.upgrade_chests = {
	pos = { x = -67, y = -12},
	bp_str = [[0eNqVmstuGzEMRf9F60lgkXr6V4qgcJJBOkAyNuxJ2yDwv9dOumjR3iHv0oB9QElHNCXxPdw/v46H4zQvYfseTvPucLPsb56O0+P188+wLXUIb2Er6TyE6WE/n8L2y+WL09O8e75+ZXk7jGEbpmV8CUOYdy/XTz/2+8dxvnn4Np6WcP3h/DheWPF8N4RxXqZlGj85Hx/evs6vL/fj8fKF/xOGcNifLj/az7+Dirf5I6rNbT6fh38w4sRs1jHqxOg6Jjkxso7JTkxexxQnJq1jqhNT1zHNiSnrmO7E9HVM3Dg5zeC4PTZEjl6To6Fy9LocDZmj1+Zo6By9PosVkddoMXZG9Dotxt6IXqvF8tHrtVoJ0Su2Gh6J12w1Vk28ZqvhkbiztLH84jVbjeUXr9lqJEfxmq1GehSv2WoIKV6z1ciQ4jU7GWar1+xk/dl7zU6GkOo1OxtbRL1mZysir9nZ2CLqrkGMLaKFrNAEcCrJiYDT2BlCIK/Xua6PLHm9zsUARRYEhpbYqjoBjpIcBZzETjUCua3uxsi8VudmgCoLQkNr5FwXwOkkJ4MzzIadagTyWl3i+siy1+piTFFWFoSGlsi5boCTSU4FHHd9XY2A3PV1M0CNXXw0NK/WRdcjKl6vixigyILA0AqbrSO6L2DTdQecxNagMKLMFqGQVNgqFJIqW4ZCUmPrUEii7QZLV912ZyOk6tY7GSHReoPyqLJ6R1Ae1UQbgEiZJqHBFXrhEKnSJDQ6d/IuFqnTJDC6tmElAIVbiywIFG5N6GyJSEpnS0RKdLZEJN5wRCp0tkSkymZLKEGj9wqKqbPpEsXUacNBmdtpw0GZ24UtKyFJ2boSkhJbWMJpyrRNKKbCVoQwpkqTUEzssTKCcrez58pY0csNfbJEMcUNfbbEUdGnSxwVfb7EUbEnTIHvZewZM3ZEKvTFGQyq0irAqBp7EYOj6iwKRhXZZC6CSGw2l4hIwt6g4qCUVgFGlehbVBhVplEwqkK2OYgiEnv/jUmNbHbApE72O0CS+9Uym6RIdj1gkpCND5ikZO8DJiWy/QGTMtkAgUmFbYHAqMo2QWBUY9sgMKqzjRAQ5X7DFDMq9yummHvG/Y4p5qZxv2SKaaj7LVNNr9yvmWp65X7PVHsFK9sYgVGNbY3AqM42R0CU+2VTzRTqfttUM4cm+sIFo+gbF4yir1wwir5zwSj60gWjKtssgVGNbZfAqE4Xswjlf/H8e+PcDZ8ttds/GnSH8H08nj5+Iu0ydV1q0pK6tPP5F4e7DS8=]],
	-- bp_str = [[0eNqVmstu20AMRf9l1kqgIefpXymCIg8hNZDIhq0UDQL/e22nixbNFXmXBqQDceaIJsX5CA8vb9P+sJ2XsPkIx/l+f7Psbp4P26fL719hU+oQ3sNG0mkI28fdfAybb+cLt8/z/cvlkuV9P4VN2C7TaxjCfP96/XXYzTePP6bjEi63zU/TmRRPd0OY5mW7bKdPyvXH+/f57fVhOpwv+Or+Iex3x/Mtu/nPA423+fpE6TafTsN/EHFB4jpEXRBZhyQXRNch2QVJ65DiguR1SHVByjqkuSB1HdJdkLYOiaOL0g2Kz9loSBud1hraRp+30RA3+syNhrrR565YGJ+9YrwD0eevWNr4DBbLG5/DaiU7n8RqeCM+i9XwRnwWq7Hh4rNYjQ0XZ/410p74LFYj8YnPYjVSn/gsVsNi8VmshsXiszgZFqvP4mT9afssTobF6rM4Wxifxdl4GdRncTZeBvVZnI2XQQtVohVAqRQlA0rjQkIYn8O5rGPSyGHA0iSfw7kaGKFWuAGKUpQKKIkLCWGcBjcDUzgMWhqfwrkbmEat8KWM/BLTKUwHrcbIxYQwPoWL9TTCYdDaZJ/EJVqcxG2VAEzmMBFgCvdfBx+ncn+9kNPIVUZx+UwuYnDKSHJAXMUps1ocLiFH1MhzGfnSoX2JSVwvBB8nc80Q5BSuG4KcyvUxkNO4tgpyOmkP2K/qtDlZHKfN2YirkjaDKqWSNoPSqybSHsTJJAeF5bO5FItTSQ6Kq5G7jjid5IC42shtO6idGve5OIKCsAmZCxFHyVyIOKzNiJPJHIY4hcypiFPJHIa2vZE5FXFYm0FcnbNZQHnZSZtB1dyFrAsRR8m6EHESWYchTuY4cJkLV6dCTiUtRHFxDaCA8rJzDaBENBMZuaYLg8gmEAUWR+GaUgwi+0AcGtcICpw/cZ2gKOKQXzQwqJIgGFnjvvhgUCc3H4UWySRdEIfL0pIRR7ivhRikJAhGlrivqRiUyc2HoXHfmqUiTqWG+ZjTqJMFmNOpkT7keGd/JidSg33MEeqUAeYoNd7HnESdNcCczI34MahQJw4wp3JTfgxq3KkDDOrcgQEIck4CxQZF7tAABpHtIQYp19dhUOIaTQzKXGeHQYVrNTGocpN/DGrcSQQM6tz0H4Kc80E106NzQqimkM4ZoZoJ0jkmTKbZzkmhmmY7Z4XJNNs5LUym2d55of1EjTsPgEGdO58AQd6x4b9m3w2fR0Y3fx1AHcLP6XC83iLtvGRdahLVlsvp9Bv09JQH]],
}

return Public