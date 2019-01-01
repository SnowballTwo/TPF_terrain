local tu = require "texutil"

function data()
return {
	detailTex = tu.makeTextureMipmapRepeat("ground_texture/snowball_terrain_rock_albedo.tga", false),
	detailNrmlTex = tu.makeTextureMipmapRepeat("ground_texture/snowball_terrain_rock_normal.tga", false),
	detailSize = { 16.0, 16.0 },
	colorTex = tu.makeTextureMipmapRepeat("ground_texture/snowball_terrain_rock_color.tga", false),
	colorSize = 1024.0, 1024.0,
}
end
