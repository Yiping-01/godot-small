// ============================================
// Shader from godotshaders.com
// ============================================
// Title: Pixel Dissolve TextureRect
// Author: BodenDev
// License: MIT
// URL: https://godotshaders.com/shader/pixel-dissolve-texturerect/
// ============================================

shader_type canvas_item;

uniform float dissolve_amount : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.78, 0.22, 1.0);
uniform float edge_width : hint_range(0.0, 0.25, 0.001) = 0.08;

float random_coord(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898,96.233))) * 43758.5453);
}

void fragment() {
	vec2 texture_resolution = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 pixel_within_texture = floor(UV * texture_resolution);
	vec4 texture_color = texture(TEXTURE, UV) * COLOR;
	float pixel_noise = random_coord(pixel_within_texture);
	float visible = step(dissolve_amount, pixel_noise);
	float edge = smoothstep(dissolve_amount, dissolve_amount + edge_width, pixel_noise) - visible;

	COLOR.rgb = mix(texture_color.rgb, edge_color.rgb, clamp(edge * 2.5, 0.0, 1.0));
	COLOR.a = texture_color.a * max(visible, edge);
}
