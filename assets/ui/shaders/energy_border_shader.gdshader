shader_type canvas_item;

uniform vec4 energy_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float energy_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float border_width : hint_range(0.01, 0.1) = 0.05;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Rectangular SDF
    vec2 d = abs(uv - 0.5) * 2.0;
    float dist = max(d.x, d.y);
    
    // Sharper, aggressive pulse
    float pulse = pow(sin(TIME * pulse_speed) * 0.5 + 0.5, 3.0) * 0.4 + 0.6;
    float energy_factor = energy_intensity * pulse;
    
    // Sharp ink border
    float border = smoothstep(1.0 - border_width * 2.0, 1.0 - border_width, dist) - smoothstep(1.0 - border_width, 1.0, dist);
    
    // Ink static noise
    float noise = hash(uv * 100.0 + floor(TIME * 15.0));
    float static_factor = mix(1.0, 0.8 + noise * 0.4, energy_intensity * 0.2);
    
    // Inner glow
    float glow = exp((dist - 1.0) * 4.0) * energy_factor;
    
    vec3 final_color = mix(COLOR.rgb, energy_color.rgb * static_factor, border + glow * 0.5);
    float alpha = COLOR.a * (1.0 + glow * 0.3);
    
    COLOR = vec4(final_color, alpha);
}
