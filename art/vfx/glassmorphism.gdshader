shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform vec4 tint : source_color = vec4(0.1, 0.8, 1.0, 0.4); // Cyberpunk cyan

void fragment() {
    // Sample the screen texture using Mipmaps for an incredibly cheap blur
    vec4 bg_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
    COLOR = mix(bg_color, tint, tint.a);
}
