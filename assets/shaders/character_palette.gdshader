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

	// Face zone is PROTECTED from hair recoloring.
	// No pixel in this zone can ever be classified as hair or fringe.
	bool face_zone = p.y > 0.12 && p.y < 0.48 && p.x > 0.20 && p.x < 0.80;

	// Hair zone: only above the face, never overlapping it.
	bool hair_zone = !face_zone && p.y < 0.40;

	// Fringe: strictly limited to forehead area, well above the face zone.
	// Only for hair_style 2, and never extends into face_zone.
	bool fringe = hair_style == 2 && p.y > 0.06 && p.y < 0.18 && p.x > 0.22 && p.x < 0.78;

	// Skin detection: warm tones (R > G > B) with reasonable brightness.
	bool is_skin = c.r > c.g * 1.05 && c.g > c.b * 1.03 && light > 0.12;

	// Hair detection: dark warm tones, only in hair zone.
	bool is_hair = hair_zone && !is_skin && c.r > c.b * 1.15 && light < 0.50;

	if (is_hair || fringe) {
		c.rgb = hair_color.rgb * (0.55 + light * 0.65);
	} else if (is_skin) {
		c.rgb = skin_color.rgb * (0.50 + light * 0.70);
	} else if (p.y > 0.42 && p.y < 0.78 && c.g > c.r * 1.10) {
		c.rgb = top_color.rgb * (0.45 + light * 0.65);
	} else if (p.y > 0.74 && p.y < 0.95 && light < 0.55) {
		c.rgb = bottom_color.rgb * (0.45 + light * 0.65);
	}

	COLOR = c;
}
