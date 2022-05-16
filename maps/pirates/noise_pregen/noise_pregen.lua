
local Public = {}

Public.encoding = [[!#$%&'()*+'-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ/^_`abcdefghijklmnopqrstuvwxyz{}|~]]
Public.encoding_length = 91
Public.enc = {}
Public.dec = {}
for i=1,Public.encoding_length do
	Public.enc[i]=Public.encoding:sub(i,i)
	Public.dec[Public.encoding:sub(i,i)]=i
end

Public.island1 = {}
Public.island1.Data = require 'maps.pirates.noise_pregen.perlinwavelength100boxsize1000octaves5gain0p8lacunity2lengthpower1rms0p05423'
Public.island1.upperscale = 100
Public.island1.boxsize = 1000
Public.island1.wordlength = 5
Public.island1.factor = 0.1925/0.05423

Public.forest1 = {}
Public.forest1.Data = require 'maps.pirates.noise_pregen.simplexwavelength100boxsize1000octaves5gain0p65lacunity2lengthpower1p2rms0p06243'
Public.forest1.upperscale = 100
Public.forest1.boxsize = 1000
Public.forest1.wordlength = 5
Public.forest1.factor = 0.1925/0.06243



return Public