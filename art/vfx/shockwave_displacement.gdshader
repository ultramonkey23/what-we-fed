shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec2 center = vec2(0.5, 0.5); // Updated via script to impact pos
uniform float force : hint_range(0.0, 0.1) = 0.05;
uniform float size : hint_range(0.0, 1.0) = 0.2;
uniform float thickness : hint_range(0.0, 0.2) = 0.05;

void fragment() {
    vec2 aspect_ratio = vec2(1.0, SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x);
    vec2 scaled_uv = (SCREEN_UV - vec2(0.5)) * aspect_ratio + vec2(0.5);
    vec2 disp = scaled_uv - center;
    float dist = length(disp);
    
    // Create an expanding ring mask with smooth geodesic falloff
    float mask = smoothstep(size - thickness, size, dist) - smoothstep(size, size + thickness, dist);
    
    // Offset vector with relativistic chromatic dispersion
    vec2 offset = normalize(disp) * force * mask;
    
    // Chromatic dispersion: red and blue rays refract differently across the shock front
    float r = texture(SCREEN_TEXTURE, SCREEN_UV - offset * 1.08).r;
    float g = texture(SCREEN_TEXTURE, SCREEN_UV - offset).g;
    float b = texture(SCREEN_TEXTURE, SCREEN_UV - offset * 0.92).b;
    
    // Subtle high-energy shock caustic brightness on the outer crest
    float caustic = smoothstep(size - thickness * 0.3, size, dist) * (1.0 - smoothstep(size, size + thickness * 0.4, dist));
    vec3 col = vec3(r, g, b) + vec3(0.08, 0.14, 0.22) * caustic * force * 15.0;
    
    COLOR = vec4(col, 1.0);
}
