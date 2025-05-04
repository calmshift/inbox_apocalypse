shader_type canvas_item;

// Glitch effect shader for Inbox Apocalypse
// Parameters
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float speed : hint_range(0.0, 10.0) = 5.0;
uniform float block_size : hint_range(1.0, 50.0) = 10.0;
uniform float color_offset : hint_range(0.0, 10.0) = 3.0;

// Random function
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Base UV coordinates
    vec2 uv = SCREEN_UV;
    
    // Time-based seed for randomness
    float time = TIME * speed;
    
    // Apply glitch effect based on intensity
    if (random(vec2(time, 0.0)) < intensity * 0.5) {
        // Block glitch - shift blocks horizontally
        float block = floor(uv.y * block_size) / block_size;
        float noise = random(vec2(block, time));
        
        // Apply horizontal shift
        uv.x += (noise - 0.5) * intensity * 0.1;
        
        // Occasionally apply vertical shift
        if (random(vec2(time, block)) < intensity * 0.2) {
            uv.y += (random(vec2(block, time * 2.0)) - 0.5) * intensity * 0.05;
        }
    }
    
    // Color channel separation
    if (intensity > 0.0) {
        // Get color from slightly offset UVs for RGB channels
        float r = texture(SCREEN_TEXTURE, uv + vec2(color_offset * intensity * 0.01, 0.0)).r;
        float g = texture(SCREEN_TEXTURE, uv).g;
        float b = texture(SCREEN_TEXTURE, uv - vec2(color_offset * intensity * 0.01, 0.0)).b;
        
        // Combine channels
        COLOR = vec4(r, g, b, 1.0);
        
        // Add scan lines
        float scan_line = sin(uv.y * 500.0) * 0.5 + 0.5;
        COLOR.rgb = mix(COLOR.rgb, COLOR.rgb * (0.9 + 0.1 * scan_line), intensity * 0.3);
        
        // Add noise
        float noise = random(uv + vec2(time, 0.0));
        COLOR.rgb = mix(COLOR.rgb, COLOR.rgb * (0.9 + 0.1 * noise), intensity * 0.2);
    } else {
        // No glitch effect, just pass through
        COLOR = texture(SCREEN_TEXTURE, uv);
    }
}