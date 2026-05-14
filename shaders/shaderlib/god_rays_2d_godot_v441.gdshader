// ============================================
// Shader from godotshaders.com
// ============================================
// Title: God Rays 2D Godot v4.4.1
// Author: GFGW
// License: CC0
// URL: https://godotshaders.com/shader/god-rays-2d-godot-v4-4-1/
// ============================================

/*
Shader from Godot Shaders - the free shader library.
godotshaders.com/shader/god-rays

Modification: Added brightness, contrast, and multiple blend modes.
Blend Mode Index:
 0: Screen
 1: Hard Light
 2: Soft Light
 3: Clamp
 4: Negative
 5: Multiply
 6: Darken
 7: Lighten
 8: Difference
 9: Exclusion

Feel free to adjust and share modifications.
*/

shader_type canvas_item;

//-- Non-hinted uniforms (inline initializers allowed)
uniform float angle = -0.3;
uniform float position = -0.2;
uniform float speed = 1.0;
uniform float ray1_density = 8.0;
uniform float ray2_density = 30.0;
uniform bool hdr = false;
uniform float seed = 5.0;

//-- Uniforms with hints --
// No inline initializers; set defaults in the Inspector.
uniform float spread         : hint_range(0.0, 1.0, 0.01);
uniform float cutoff         : hint_range(-1.0, 1.0, 0.01);
uniform float falloff        : hint_range(0.0, 1.0, 0.01);
uniform float edge_fade      : hint_range(0.0, 1.0, 0.01);
uniform float ray2_intensity : hint_range(0.0, 1.0, 0.01);

// By naming the uniform with _color at the end, it automatically gets a color picker.
uniform vec4 godray_color;

// New uniforms for brightness and contrast adjustment.
uniform float brightness     : hint_range(0.0, 2.0, 0.01);
uniform float contrast       : hint_range(0.0, 2.0, 0.01);

// New uniform for blend mode selection (0-9 as described above).
uniform int blend_mode       : hint_range(0, 9, 1);

//-- Added screen texture uniform with a hint --
// (Replaces the built-in SCREEN_TEXTURE in Godot 4.)
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

//-- Random and noise functions --
float random(vec2 _uv) {
    return fract(sin(dot(_uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(in vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f); // Cubic Hermite interpolation.
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

mat2 rotate(float _angle) {
    return mat2(vec2(cos(_angle), -sin(_angle)),
                vec2(sin(_angle),  cos(_angle)));
}

//-- Blend mode functions --

// Screen blend mode.
vec3 blend_screen(vec3 base, vec3 blend) {
    return 1.0 - (1.0 - base) * (1.0 - blend);
}

// Hard light blend mode.
vec3 blend_hard_light(vec3 base, vec3 blend) {
    return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(0.5, blend));
}

// Soft light blend mode.
vec3 blend_soft_light(vec3 base, vec3 blend) {
    vec3 result;
    result.r = (blend.r < 0.5)
         ? (2.0 * base.r * blend.r + base.r * base.r * (1.0 - 2.0 * blend.r))
         : (sqrt(base.r) * (2.0 * blend.r - 1.0) + 2.0 * base.r * (1.0 - blend.r));
    result.g = (blend.g < 0.5)
         ? (2.0 * base.g * blend.g + base.g * base.g * (1.0 - 2.0 * blend.g))
         : (sqrt(base.g) * (2.0 * blend.g - 1.0) + 2.0 * base.g * (1.0 - blend.g));
    result.b = (blend.b < 0.5)
         ? (2.0 * base.b * blend.b + base.b * base.b * (1.0 - 2.0 * blend.b))
         : (sqrt(base.b) * (2.0 * blend.b - 1.0) + 2.0 * base.b * (1.0 - blend.b));
    return result;
}

// Clamp blend mode: simply clamps the base color.
vec3 blend_clamp(vec3 base, vec3 blend) {
    return clamp(base, 0.0, 1.0);
}

// Negative blend mode: inverts the base color.
vec3 blend_negative(vec3 base, vec3 blend) {
    return 1.0 - base;
}

// Multiply blend mode.
vec3 blend_multiply(vec3 base, vec3 blend) {
    return base * blend;
}

// Darken blend mode: takes the minimum channel value.
vec3 blend_darken(vec3 base, vec3 blend) {
    return min(base, blend);
}

// Lighten blend mode: takes the maximum channel value.
vec3 blend_lighten(vec3 base, vec3 blend) {
    return max(base, blend);
}

// Difference blend mode: absolute difference.
vec3 blend_difference(vec3 base, vec3 blend) {
    return abs(base - blend);
}

// Exclusion blend mode.
vec3 blend_exclusion(vec3 base, vec3 blend) {
    return base + blend - 2.0 * base * blend;
}

void fragment() {
    // Rotate, skew, and move the UVs.
    vec2 transformed_uv = (rotate(angle) * (UV - position))
                           / ((UV.y + spread) - (UV.y * spread));

    // Animate the rays based on the transformed UVs.
    vec2 ray1 = vec2(transformed_uv.x * ray1_density +
                      sin(TIME * 0.1 * speed) * (ray1_density * 0.2) + seed, 1.0);
    vec2 ray2 = vec2(transformed_uv.x * ray2_density +
                      sin(TIME * 0.2 * speed) * (ray1_density * 0.2) + seed, 1.0);

    // Cut off the ray's edges.
    float cut = step(cutoff, transformed_uv.x) * step(cutoff, 1.0 - transformed_uv.x);
    ray1 *= cut;
    ray2 *= cut;

    // Create the ray effect using noise.
    float rays;
    if (hdr) {
        rays = noise(ray1) + (noise(ray2) * ray2_intensity);
    } else {
        rays = clamp(noise(ray1) + (noise(ray2) * ray2_intensity), 0.0, 1.0);
    }

    // Fade out the ray's edges.
    rays *= smoothstep(0.0, falloff, (1.0 - UV.y));
    rays *= smoothstep(cutoff, edge_fade + cutoff, transformed_uv.x);
    rays *= smoothstep(cutoff, edge_fade + cutoff, 1.0 - transformed_uv.x);

    // Calculate the initial ray brightness.
    vec3 base_shine = vec3(rays) * godray_color.rgb;

    // Sample the screen texture.
    vec3 screen_col = texture(screen_texture, SCREEN_UV).rgb;

    // Select blend mode based on uniform blend_mode.
    vec3 blended;
    if (blend_mode == 0) {
        blended = blend_screen(screen_col, godray_color.rgb);
    } else if (blend_mode == 1) {
        blended = blend_hard_light(screen_col, godray_color.rgb);
    } else if (blend_mode == 2) {
        blended = blend_soft_light(screen_col, godray_color.rgb);
    } else if (blend_mode == 3) {
        blended = blend_clamp(screen_col, godray_color.rgb);
    } else if (blend_mode == 4) {
        blended = blend_negative(screen_col, godray_color.rgb);
    } else if (blend_mode == 5) {
        blended = blend_multiply(screen_col, godray_color.rgb);
    } else if (blend_mode == 6) {
        blended = blend_darken(screen_col, godray_color.rgb);
    } else if (blend_mode == 7) {
        blended = blend_lighten(screen_col, godray_color.rgb);
    } else if (blend_mode == 8) {
        blended = blend_difference(screen_col, godray_color.rgb);
    } else if (blend_mode == 9) {
        blended = blend_exclusion(screen_col, godray_color.rgb);
    } else {
        blended = screen_col;
    }

    // Use the blended color as the final "shine".
    vec3 shine = blended;

    // Apply brightness and contrast adjustments.
    // Contrast adjustment: (col - 0.5) * contrast + 0.5, then multiplied by brightness.
    vec3 adjusted = ((shine - vec3(0.5)) * contrast + vec3(0.5)) * brightness;

    COLOR = vec4(adjusted, rays * godray_color.a);
}