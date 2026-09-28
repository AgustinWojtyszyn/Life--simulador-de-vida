shader_type canvas_item;
uniform vec4 paint : source_color = vec4(0.80, 0.42, 0.20, 1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Reuse the complete sedan family; retain glass, tyres, lights and trim.
	if (c.b > c.r * 1.35 && c.b > c.g * 1.15) {
		c.rgb = paint.rgb * (0.35 + max(c.r, max(c.g, c.b)) * 0.95);
	}
	COLOR = c;
}
