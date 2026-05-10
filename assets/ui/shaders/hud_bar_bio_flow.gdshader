shader_type canvas_item;

uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 under_color : source_color = vec4(0.12, 0.04, 0.06, 0.9);
uniform vec4 fill_color : source_color = vec4(0.78, 0.22, 0.18, 1.0);
uniform vec2 bar_size_px = vec2(256.0, 14.0);

float hn(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	float dome = smoothstep(0.0, 0.09, uv.y) * smoothstep(1.0, 0.91, uv.y);
	float jitter = sin(uv.y * 52.0 + TIME * 5.25) * 0.014;
	float edge = clamp(fill_ratio + jitter, 0.02, 0.995);
	float in_fill = dome * (1.0 - smoothstep(edge - 0.042, edge + 0.042, uv.x));

	vec3 u = under_color.rgb * (0.94 + sin(uv.y * 70.0 + TIME * 1.15) * 0.035);
	vec3 f = fill_color.rgb;

	float flow = sin(uv.y * 40.0 + uv.x * 14.0 - TIME * 6.8) * 0.5 + 0.5;
	f *= mix(0.86, 1.08, flow * in_fill);
	f += hn(uv * vec2(420.0, 180.0) + TIME) * 0.06 * max(in_fill, 0.12);

	vec3 rgb = mix(u, f, in_fill);
	vec2 d_px = fract(uv * max(bar_size_px, vec2(1.0)));
	float dither = hn(d_px * 260.0);
	rgb += (dither - 0.52) * 0.05 * clamp(in_fill + 0.35, 0.0, 1.0);

	float alpha = mix(under_color.a, fill_color.a, clamp(in_fill, 0.0, 1.0));
	COLOR = vec4(rgb * dome, alpha * dome);
}
