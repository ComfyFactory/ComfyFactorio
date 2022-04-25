
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
	offset = {x = -24, y = -10.5},
	bp = [[0eNqV3M1u20YYRuF74VoB8g7J+dGtFFm4tpAKcCTDVn+CwPdeu2aLblrwWQo4psg5M5vz0fox/fz46+np+Xy5Tccf08vl7unT7frp6/P54f3zH9NxLofp+3QseT1M5/vr5WU6/vQGnr9e7h7fkdv3p9N0nM6307fpMF3uvr1/+v16fThdPt3/cnq5Te9/eHk4vV0rr18O0+38ePq4yNP15Xw7Xy/bN3180efXf67y9m33z6fb6e0K/wFH4CLwLPBC91yJbkR3ogct304zs2icReMsGmfROIvGmTTOpHEmjTNpnEnjIhoX0biIxkU0LqJxIY0LaVxI40IaF9K4isZVNK6icRWNq2hcSeNKGlfSuJLGlTRW0VhFYxWNVTRW0VhJYyWNlTRW0lhJYxONTTQ20dhEYxONjTQ20thIYyONjTR20dhFYxeNXTR20dhJYyeNnTR20thJ4xCNQzQO0ThE4xCNgzQO0jhI4yCNgzTms3jc6BBdiJ6JXuy+q+HN8G74sFXcqygkNCQ0JDQkNCQ0JjQmNCY0JjQmlNJOqO2E4k6o7oTyTqzvxAJPrPDEEk+s8YQiT6jyhDJPqPOEQk+s9MRST6z1xGJPrPaEck+o94SCT6j4hJJPrPnEok+s+sSyT6z7hMJPqPyE0k+o/YTiT6z+xPJPrP/EAlCsAIUSUKgBhSJQqAKFMlCsA8VCUKwExVJQrAWFYlCoBoVyUKgHhYJQrAjFklCsCcWiUKwKhbJQqAuFwlCoDIXS0Eav9pSIV8Ob4d3wYYr2+qf6FMpPof4UClChArXRK9HV1sRuJXYvwZtphnfDh/nf+y4FBbRCAa1QQCsU0AoFtI1eia5EN1tBe8zYc8YeNPakwUfthg/bXHt3LnXFQl2xUFcs1BULdcWNXomuRDeiu623LWFsDWOLGFvF2DLG1jG4kMN27t5jYa/p2Xt69qKevalnr+oVOkSFDlGhQ1ToEH3Qw+yYnpifmKCYoZiimKOYpJilmKbdJ5TifKE4XyjOF4rzheL8Rq9EV6Ib0Z3oYXZQptmM6Yz5jAmNGY0pjTmNSY1Z3X2gadxSaNxSaNxSaNyy0SvRlehGdCd6mB2UaTZjOmM+Y0JjRmNKY05jUncfUZpxFZpxFZpxbfRKdCW6Ed2JtvXefYpWO0WrnaLVTtFqp2i1U2QzzmIzzmIzzkKzv0Kzv41eia5EN6JtTQbRuzd6tY1ebaNX2+jVNnq1jW6z32Kz30Jjy41eia5E2313ogfRu/dis73YbC8224vN9mKzvWhj60JD0Y22azeiO9GD6N3bpdt26bZdum2XbtvF5taFBpcb3YjuRA+idxsdZnSY0WFGbfw704huozvRg+i9i/43HsOL4Xv/UZpGOhs9iN69LrF1sfHSTCF9o3ffunX3+f8i4JfDx28vHP/1Sw6H6bfT88tfFyg9SxulLXNdRumvr38Cd8bxwA==]],
}

return Public