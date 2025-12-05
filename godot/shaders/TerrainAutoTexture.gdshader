shader_type spatial;

// Terrain Auto-Texture Shader
// Automatically applies grass to flat areas and mountain to steep areas
// Based on surface normals and vertex positions

uniform sampler2D grass_texture : source_color;
uniform sampler2D mountain_texture : source_color;
uniform float slope_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float blend_sharpness : hint_range(0.1, 10.0) = 2.0;
uniform float texture_scale : hint_range(0.1, 10.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_normal;
varying vec3 world_position;

void vertex() {
    world_position = VERTEX;
    world_normal = NORMAL;
}

void fragment() {
    // Calculate how "flat" the surface is (0 = vertical, 1 = horizontal)
    float flatness = abs(world_normal.y);
    
    // Sample both textures with scaled UVs
    vec2 scaled_uv = UV * texture_scale;
    vec4 grass_color = texture(grass_texture, scaled_uv);
    vec4 mountain_color = texture(mountain_texture, scaled_uv);
    
    // Create smooth transition between grass and mountain
    // When flatness > slope_threshold, use grass
    // When flatness < slope_threshold, use mountain
    float blend_factor = smoothstep(slope_threshold - 0.1, slope_threshold + 0.1, flatness);
    blend_factor = pow(blend_factor, blend_sharpness);
    
    // Debug: Show flatness as color to understand what's happening
    // Uncomment this line to see flatness values:
    // ALBEDO = vec3(flatness, flatness, flatness); return;
    
    // Mix the textures
    // blend_factor = 0 means pure mountain_color
    // blend_factor = 1 means pure grass_color
    vec4 final_color = mix(mountain_color, grass_color, blend_factor);
    
    ALBEDO = final_color.rgb;
    ROUGHNESS = roughness;
    METALLIC = metallic;
}
