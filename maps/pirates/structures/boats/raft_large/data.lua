
local Public = {}

Public.display_name = 'raft_large'
Public.capacity = 38
Public.tile_areas = {
	{{-18,-4},{0,5}},
}
Public.width = 18
Public.height = 9
Public.spawn_point = {x = -6, y = 0}
Public.areas_infront = {
	{{0,-4},{1,5}},
}
Public.areas_behind = {
	{{-19,-4},{-18,5}},
}
Public.areas_offright = {
	{{-18,5},{0,6}},
}
Public.areas_offleft = {
	{{-18,-5},{0,-4}},
}
Public.entities = {
	inaccessible = { --this 'left wall' stops biters from being deleted by water
		pos = { x = -17.5, y = 0},
		bp_str = [[0eNqV08sOwiAQBdB/mTU1ltIXv2KMqXZSSdqhKfhoDP9uQRcmsmF5k7mHWQwvOI83nBdFFuQLDHVzZnU2LKr3+QkyZ7CCbB0DddFkQB62MTVQN/oBu84IEpTFCRhQN/n00LpHyi5XNBZ8kXr0kjsyQLLKKvw4Iawnuk1nXMJTMYHBrM1W0vRdab8rw1L5rnSO/TE8kdnHmSKRKeKMSGR4nCkTmTLOVImMiDN1IlPHmSaRqeJMm8g0ntluMVyt/PkBDO64mFDgTS7qlteiqETLG+fekGkHZg==]],
	},
}

Public.landingtrack = {
	offset = {x = 4.5, y = -7},
	bp = [[0eNqV2M1qwkAYheF7mXWE+eZ/civFhdVBBjQJSSwVyb3XVBddtMV3JYHjBJ85m+NNvZ8uZRhrN6v2pqZuN2zmfnMc62F9/lStmEZd7x9+aVTd992k2rd7sB673WmNzNehqFbVuZxVo7rdeX265/ZjmYtav9QdynrOsm3UXE/lccDQT3Wuffd8y+b5Gr38dsafcWFxA0+neQvz7tW8MBxhOMJwBOIIxBGIoxmOZjia4WiIoyGOZjgZ2WREk5FMZjCZuWTGkhBLQiwJsSTGkhhLYiwRsUTEEhFLZCyRsUTGEhBLQCwBsQTGEhhLYCwesXjE4hGLZyyesXjG4hCLQywOsTjG4hiLYywWsVjEYhHLI21Rmv1Kj9IBpSNKJ5TO7HbgZbLbFHadwu7z5dqyWcJWCRslBtXWoNoaVFuDamtQbQ2qrUG1Nay2htUWbkY4GeliZJuITSK2iFBtBdVWUG0F1VZQbQXVVlBthdVWWG3pmod79Z/abpvHv0btj/+gGvVRxun7AJPExWyiDc5pa5blC6gg570=]],
}

return Public