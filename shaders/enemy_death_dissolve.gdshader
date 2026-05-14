shader_type canvas_item;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.25) = 0.08;
uniform vec4 edge_color : source_color = vec4(1.0, 0.78, 0.25, 1.0);
uniform float noise_scale : hint_range(1.0, 80.0) = 28.0;

float random(vec2 value) {
	return fract(sin(dot(value, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 value) {
	vec2 cell = floor(value);
	vec2 local = fract(value);
	local = local * local * (3.0 - 2.0 * local);

	float a = random(cell);
	float b = random(cell + vec2(1.0, 0.0));
	float c = random(cell + vec2(0.0, 1.0));
	float d = random(cell + vec2(1.0, 1.0));

	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	float mask = noise(UV * noise_scale);
	float visible = step(dissolve_amount, mask);
	float edge = smoothstep(dissolve_amount, dissolve_amount + edge_width, mask) - visible;

	COLOR.rgb = mix(tex.rgb, edge_color.rgb, clamp(edge * 2.5, 0.0, 1.0));
	COLOR.a = tex.a * max(visible, edge);
}
