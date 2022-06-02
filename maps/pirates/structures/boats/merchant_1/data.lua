-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Public = {}

Public.display_name = 'merchant_1'
Public.tile_areas = {
	{{-30,-6},{-5,5}},
	{{-5,-5},{-4,4}},
	{{-4,-4},{-3,3}},
	{{-3,-3},{-2,2}},
	{{-2,-2},{-1,1}},
	{{-1,-1},{0,0}},
}
Public.width = 30
Public.height = 11
Public.entities = {
	static = {
		pos = { x = -17, y = -0.5},
		bp_str = [[0eNqdmd1uozAUhN/F16TCNrYhr7KqVvmxskgEIkK2G1V594W0aquGwWd6iQpfx0dzju3Jq9o2l3jq63ZQ61d1bjen1dCtDn29n57/qbVxmbqqtda3TNW7rj2r9a/xxfrQbprpleF6imqt6iEeVabazXF6eum6fWxXuz/xPKjpw3YfR5a+PWcqtkM91PGNc3+4/m4vx23sxxfmCZk6defxo659F6Wf3lU9udste8CYD8y2PqxiE3dDX+9Wp66JjyxzJ9lRZRvrw59td+knbVVmTOb98wzeClXmyyoLEmPmMU6IsctqvBBjljFBiHHLmFKIKZYx1QfmfNw0TcoK7kulv9nBZLqc84LOhUrDslIttb5PcIyQUyU4UpOXCY7U5TrR01rqc51oOy11uk50jJZ6XSd6RpecTT94Mz6dxtasTyt21WDcGKnhdaLFjXjYJ5rcUONeu/l5PzV4Fuxc7cxnL5yHGBsoNCRKJ+6FxLAw4l5ITAvjv6ysa+PqZbTfAgYtLAgLVCU4pZBTJjhisyemoBWbPTEGrdTsJjEGrXS+m8QYtNIBbxJj0EpdbRJj0EpdbRIDwXryZGUBJ5CcAnBKdvYiQZWsXd2yniKXYYoERnPDA2EMhwG1KT79vOmHumlif10Nl76PC4dYf99A93U/bhn3v/o5MntQd0ChIzkecDx55ER6AslBekryyIn0VCQH6HE5eXRFHE1ywLqcEe5qLsGxJAetqxByioQeR3KQHi/k+IQedlwHwClJTgk4FdlfQI/Pyb5AHNbPiGO4XQiUx1tuF0IY1s1oVY7bhpAcz2dPOn+8jPgKXEY86/IKCGVdPt2rZ0E/DFnuvG/rHqsX8rlVh/yHV+TZ/4JqGzR7UAPFDYbOGEB1g/3B5fbRUGP9xtrORwOhIK+3UCvZQqh45KUUyglsmowyTbpVEKhis1oUj+ZsWotAms1rEciwiS0CWTZQRaCCTVQRyLGRKgJ5NlNFoECHqohU0qkqItEBIyJVOZ2rIpKms0pEMnRYiUiWDgERqaBTQERydF6GSJ4OzBAp0IkZIpV0ZIZIFZ2Zocg/z+nUDKI0nZvdUc/Z26+26y+/AWfqb+zP909MqYtQmVBYX1SmvN3+A/EBuBE=]],
	},}
Public.market_pos = {x = -8.5, y = 0.5}

Public.landingtrack = {
	offset = {x = -5, y = -0.5},
	bp = [[0eNqV3MtuG0cQheF3mbUE+PRM3/QqgReKTTgEZEqQmIth6N0j2YMgmwTzLQkcNWfqr1rorwa/L78+/H56ej5frsvd9+Xlcv90e328/fJ8/vz++a/lbi03y7flruT1Zjl/ery8LHe/vAXPXy73D++R67en03K3nK+nr8vNcrn/+v7pz8fHz6fL7affTi/X5f0PL59Pb2fl9ePNcj0/nH4e8vT4cr6eHy/7N3348UUfXv855e3bPj2frqe3E/4jHAkXCa8S3uiZG6U7pQelJ5XvIJkIxgjGCMYIxgjGEMYQxhDGEMYQxiIYi2AsgrEIxiIYC2EshLEQxkIYC2FcBeMqGFfBuArGVTCuhHEljCthXAnjShg3wbgJxk0wboJxE4wbYdwI40YYN8K4EcYqGKtgrIKxCsYqGCthrISxEsZKGCthbIKxCcYmGJtgbIKxEcZGGBthbISxEcYuGLtg7IKxC8YuGDth7ISxE8ZOGDthHIJxCMYhGIdgHIJxEMZBGAdhHIRxEMYpGKdgnIJxCsYpGCdhnIRxEsZJGKf9+08aJ+RxQiInZHJCKifmcmIyJ2ZzYjon6HNM6JjRMaVjTsekDlod1DrodVDsmNkJqZ2Q2wnJnZDdCemdmN+JCZ6Y4YkpnpjjCUmekOUJaZ6Q5wmJnpjpiamemOuJyZ6Y7QnpnpDvCQmfkPEJKZ+Y84lJn5j1iWmfmPcJiZ+Q+Qmpn5D7CcmfmP2J6Z+Y/4kJoJgBCimgkAMKSaCQBQppoD1d7S0x3izeLT4sPg3RUf5kmkKqKeSaQrIpZJv2dKV0s5rYo8SeJfgw3eLD4tP4H20usmUhXRbyZSFhFjJme7pSulG6WwXtNWPvGXvR2JsGX3VYfFpzHe1c0okhnxgSiiGjGFKKe7pSulG6U3pYva2EsRrGihirYqyMsToGCzmtc49e6yGXW8jlFnK5hVxuIZe7pyulG6U7pQelp9ExPDE+MUAxQjFEMUYxSDFKMUyHJ5TkfCE5X0jOF5LzheT8nq6UbpTulB6UnkYHYRrNGM4YzxjQGNEY0hjTGNQY1cMDbVdp7S6tXaa127SFRrTQiBYa0UIjWmhEi41osREtNqLFRrTYiBYbUbxOjfep8UI13qimHVehHVehHdeerpRulO6UHpS2eh+eotWmaLUpWm2KVpui1abIdpzFdpzFdpyFdn+Fdn97ulK6UbpT2moyKX240Tdr9M0afbNG36zRN2t02/0W2/0WWlvu6UrpRml77kHpSenDvVitF6v1YrVerNaL1XrR1taFlqJ72s7ulB6UnpQ+3C7N2qVZuzRrl2btYnvrQovLPd0pPSg9KX2YaDei3Yh2I2rr30Iruj09KD0pfbjow4o+rOi2iyy00tnTk9KH6zKtLrZeWkmk7+mjj76ad1//TwJ+vPn5Owt3//rVhpvlj9Pzy48DysjWZ+m1blvt7fX1b9tV7YA=]],
}

return Public