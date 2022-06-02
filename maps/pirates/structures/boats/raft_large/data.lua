-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


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
	offset = {x = -8, y = 0},
	bp = [[0eNqVmctqwkAARf9l1hG88578SnFhNUhAk5CkpSL59/padGHBsxSOIznXxRm9mM/jVzOMbTeb+mKmbjus5n51GNv97fWPqa0qcza1wlKZdtd3k6k/rmB76LbHGzKfh8bUpp2bk6lMtz3dXl253djMjbm9qds313O0bCozt8fmccDQT+3c9t3zU9b3D1kvr074BxaBLTqZ0Q7R/j1aRIiIEBEhQkKEhAgJsUSIJUIsEWKREIuEWCTEESGOCHFEiENCHBLikBBPhHgixBMhHgnxSIhHQgIREoiQQIQEJCQgIQEJiURIJEIiERKRkIiERCQkESGJCElESEJCEhKSkJBMhGQiJBMhGQnJSEhGQgoRUoiQQoQUJKQgIYWFGUpVoVYVilWxWhXLVcFeZcHKipUlK2xWGK2sWoWyVahbhcJVrFzF0lWsXYXiVahehfJVrF/FAlasYIUSVqhhhSJWrGLFMlasY4VCVqhkhVJWrGXFYlasZoVyVqhnhYJWrGjFklasaYWiVqhqhbJWrGvFwlasbIXSVqhtheL2STtEs6cMiI6ITojOiC5sHTgmW1NsTrE93/7aoguI0A1E6ArypB2i2VMGREdEJ0RnRBe2DhyTrSk2p9ieb/9ajW6JFt0SLbolPmmHaPaUAdER0QnRGdGFrQPHZGuKzSm25+uv7aZ6/G1X//kTsDLfzTjdD7BZPhWbQvA+pLgsv9RK9k0=]],
}

return Public