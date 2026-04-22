shader_type canvas_item;

uniform vec2 scroll_speed = vec2(0.05, 0.03);
uniform float noise_intensity = 0.08;

void fragment() {
	vec2 uv = UV + (scroll_speed * TIME);
	vec4 noise = texture(TEXTURE, uv);
	COLOR = vec4(1.0, 1.0, 1.0, noise.r * noise_intensity);
}