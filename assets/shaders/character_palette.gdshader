shader_type canvas_item;
uniform vec4 skin_color : source_color = vec4(0.83, 0.57, 0.39, 1.0);
uniform vec4 hair_color : source_color = vec4(0.28, 0.16, 0.10, 1.0);
uniform vec4 top_color : source_color = vec4(0.21, 0.57, 0.54, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.23, 0.27, 0.32, 1.0);
uniform int hair_style = 0;
uniform vec4 bounds = vec4(0.0, 0.0, 1.0, 1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 p = (UV - bounds.xy) / bounds.zw;
	float light = max(c.r, max(c.g, c.b));
	// Darker authored skin pixels must remain skin. The old light > 0.40 gate
	// classified parts of some female faces as hair, producing a black-face artifact.
	// More permissive skin detection to catch darker face tones in female sprites.
	bool skin = c.r > c.g * 1.08 && c.g > c.b * 1.05 && light > 0.16;
	// Expanded face zone to cover more of the head area in female sprites.
	bool face_zone = p.y > 0.12 && p.y < 0.48 && p.x > 0.20 && p.x < 0.80;
	// Hair detection: stricter to avoid marking face as hair.
	bool hair = !skin && !face_zone && p.y < 0.40 && c.r > c.b * 1.20 && light < 0.48;
	// Fringe must NEVER cover the face zone. The old fringe logic painted
	// female faces black when hair_style was 1 or 2. Now fringe is strictly
	// limited to the forehead area above the face and only for hair_style 2.
	bool fringe = skin && hair_style == 2 && p.y < 0.22 && p.y > 0.08 && p.x > 0.25 && p.x < 0.75;
	if (hair || fringe) c.rgb = hair_color.rgb * (0.60 + light);
	else if (skin) c.rgb = skin_color.rgb * (0.55 + light * 0.60);
	else if (p.y > 0.42 && p.y < 0.78 && c.g > c.r * 1.12) c.rgb = top_color.rgb * (0.50 + light);
	else if (p.y > 0.74 && p.y < 0.95 && light < 0.54) c.rgb = bottom_color.rgb * (0.50 + light);
	COLOR = c;
}
