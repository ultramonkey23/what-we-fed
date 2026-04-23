shader_type canvas_item;
render_mode unshaded;

uniform float hit_flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float corruption_amount : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 0.1) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	float offset = chromatic_aberration * (0.25 + corruption_amount);
	vec4 base = texture(TEXTURE, uv) * COLOR;
	vec3 sample_rgb = vec3(
		(texture(TEXTURE, uv + vec2(offset, 0.0)) * COLOR).r,
		base.g,
		(texture(TEXTURE, uv - vec2(offset, 0.0)) * COLOR).b
	);

	float line_noise = sin((uv.y * 900.0) + TIME * 18.0) * 0.5 + 0.5;
	float static_noise = hash(uv * vec2(960.0, 540.0) + TIME * 3.5);
	float corruption_mix = clamp(corruption_amount, 0.0, 1.0);
	float corruption_factor = mix(1.0, line_noise * (0.82 + static_noise * 0.18), corruption_mix);

	vec3 corrupted = sample_rgb * corruption_factor;
	vec3 flashed = mix(corrupted, hit_flash_color.rgb, clamp(hit_flash_intensity, 0.0, 1.0));
	float alpha = base.a;

	COLOR = vec4(flashed, alpha);
}
