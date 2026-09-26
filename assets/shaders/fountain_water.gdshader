shader_type canvas_item;
uniform float water_time = 0.0;

float water_mask(vec4 c) {
	return step(0.045, c.g - c.r) * step(0.045, c.b - c.r) * step(0.25, c.g) * c.a;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float water = water_mask(base);
	// Pixel-stepped movement only inside turquoise water; stone stays untouched.
	vec2 pixel = floor(UV / TEXTURE_PIXEL_SIZE);
	float tick = floor(water_time * 12.0);
	float drift = sin(pixel.y * 0.55 + tick * 0.65);
	vec4 shifted = texture(TEXTURE, UV + vec2(sign(drift), 0.0) * TEXTURE_PIXEL_SIZE);
	vec3 color = mix(base.rgb, shifted.rgb, water * water_mask(shifted) * 0.65);
	float falling = step(0.7, sin(pixel.y * 1.25 - tick * 1.2 + pixel.x * 0.3));
	float ripple = sin(length((UV - vec2(0.5, 0.71)) * vec2(1.0, 2.5)) * 95.0 - water_time * 9.0);
	color += water * (0.10 * falling + 0.075 * ripple);
	COLOR = vec4(color, base.a) * COLOR;
}
