shader_type canvas_item;
uniform vec4 skin_color : source_color = vec4(0.83, 0.57, 0.39, 1.0);
uniform vec4 hair_color : source_color = vec4(0.28, 0.16, 0.10, 1.0);
uniform vec4 top_color : source_color = vec4(0.21, 0.57, 0.54, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.23, 0.27, 0.32, 1.0);
uniform int hair_style = 0;
uniform vec4 face_bounds = vec4(0.20, 0.12, 0.60, 0.36);
uniform vec4 bounds = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 p = (UV - bounds.xy) / bounds.zw;
	float light = max(c.r, max(c.g, c.b));

	// Classify the authored pigment first. Geometry alone must never paint
	// eyes, face shading or transparent pixels as a solid fringe.
	bool face_zone = p.y > face_bounds.y && p.y < face_bounds.y + face_bounds.w
		&& p.x > face_bounds.x && p.x < face_bounds.x + face_bounds.z;
	bool warm = c.r > c.g * 1.05 && c.g > c.b * 1.03;
	bool is_hair = !face_zone && p.y < 0.43 && warm && light > 0.10;
	bool is_skin = !is_hair && warm && light > 0.25 && c.r - c.b > 0.08;
	bool fringe = hair_style == 2 && !face_zone && is_hair
		&& p.y > 0.06 && p.y < 0.18 && p.x > 0.22 && p.x < 0.78;

	if (is_hair || fringe) {
		c.rgb = hair_color.rgb * (0.55 + light * 0.65);
	} else if (is_skin) {
		c.rgb = skin_color.rgb * (0.50 + light * 0.70);
	} else if (p.y > 0.42 && p.y < 0.78 && c.g > c.r * 1.10) {
		c.rgb = top_color.rgb * (0.45 + light * 0.65);
	} else if (p.y > 0.74 && p.y < 0.92 && light > 0.12 && light < 0.55 && c.b > c.r * 1.05) {
		c.rgb = bottom_color.rgb * (0.45 + light * 0.65);
	}

	COLOR = c;
}
