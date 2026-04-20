shader_type canvas_item;

uniform vec4 energy_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float energy_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    
    // Create pulsing energy effect
    float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;
    float energy_factor = energy_intensity * pulse;
    
    // Create energy border with glow
    float border_width = 0.15;
    float border = smoothstep(0.5 - border_width, 0.5, dist) * smoothstep(0.5, 0.5 + border_width, dist);
    
    // Add energy glow
    float glow = exp(-dist * 3.0) * energy_factor;
    
    // Combine effects
    vec3 final_color = mix(COLOR.rgb, energy_color.rgb, border + glow * 0.3);
    float alpha = COLOR.a * (1.0 + glow * 0.5);
    
    COLOR = vec4(final_color, alpha);
}
