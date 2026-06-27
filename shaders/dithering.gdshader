shader_type canvas_item;
uniform sampler2D blue_noise_texture : filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float darkness_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float transition_width : hint_range(0.0, 0.5) = 0.05;
uniform float spacing : hint_range(0.0, 0.95) = 0.0;
uniform vec3 dot_color : source_color = vec3(0.0);
uniform bool use_scene_dots = false;
uniform vec3 bg_color : source_color = vec3(1.0);
uniform bool use_scene_background = false;
uniform float filter_opacity : hint_range(0.0, 1.0) = 1.0;
uniform int blend_mode : hint_range(0, 4) = 0;

void fragment() {
    vec3 scene_color = texture(screen_texture, SCREEN_UV).rgb;
    float luminance = dot(scene_color, vec3(0.299, 0.587, 0.114));
    
    float pattern_size = float(textureSize(blue_noise_texture, 0).x);
    vec2 noise_uv = fract(FRAGCOORD.xy / pattern_size);
    float noise_value = texture(blue_noise_texture, noise_uv).r;
    noise_value = clamp((noise_value - spacing) / (1.0 - spacing), 0.0, 1.0);
    
    float normalized_luminance = luminance / max(darkness_threshold, 0.001);
    float dot_on = step(noise_value, normalized_luminance);
    
    vec3 actual_background = use_scene_background ? scene_color : bg_color;
    vec3 actual_dot_color = use_scene_dots ? scene_color : dot_color;
    vec3 dithered_color = mix(actual_background, actual_dot_color, dot_on);
    
    vec3 blended_color = scene_color;
    if (blend_mode == 0) {
        blended_color = dithered_color;
    } else if (blend_mode == 1) {
        blended_color = scene_color * dithered_color;
    } else if (blend_mode == 2) {
        blended_color = scene_color + dithered_color;
    } else if (blend_mode == 3) {
        blended_color = 1.0 - (1.0 - scene_color) * (1.0 - dithered_color);
    } else if (blend_mode == 4) {
        vec3 result;
        for (int i = 0; i < 3; i++) {
            if (scene_color[i] < 0.5) {
                result[i] = 2.0 * scene_color[i] * dithered_color[i];
            } else {
                result[i] = 1.0 - 2.0 * (1.0 - scene_color[i]) * (1.0 - dithered_color[i]);
            }
        }
        blended_color = result;
    }
    
    float fade = 1.0 - smoothstep(darkness_threshold - transition_width, darkness_threshold, luminance);
    float effect_strength = fade * filter_opacity;
    vec3 final_color = mix(scene_color, blended_color, effect_strength);
    
    COLOR = vec4(final_color, 1.0);
}