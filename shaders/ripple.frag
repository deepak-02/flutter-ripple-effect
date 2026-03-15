#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform vec4 r1; uniform vec4 r2; uniform vec4 r3; uniform vec4 r4; uniform vec4 r5;

// This is the new image texture we pass from Dart
uniform sampler2D u_image;

out vec4 fragColor;

vec2 calcDisplacement(vec2 uv, vec4 ripple) {
if (ripple.z <= 0.0) return vec2(0.0);

vec2 aspect = vec2(1.0, u_size.y / u_size.x);
float dist = distance(uv * aspect, (ripple.xy / u_size) * aspect);

float diff = dist - ripple.z;
float wave = sin(diff * 80.0) * exp(-abs(diff) * 40.0);

vec2 dir = normalize(uv - (ripple.xy / u_size));
return dir * wave * ripple.w;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / u_size;

    vec2 disp = vec2(0.0);
    disp += calcDisplacement(uv, r1);
    disp += calcDisplacement(uv, r2);
    disp += calcDisplacement(uv, r3);
    disp += calcDisplacement(uv, r4);
    disp += calcDisplacement(uv, r5);

    vec2 final_uv = uv - disp * 0.03; // Adjusted distortion strength

    // Clamp the UV coordinates so the edges don't wrap weirdly when distorted
    final_uv = clamp(final_uv, 0.0, 1.0);

    // Sample the image using the distorted water coordinates
    fragColor = texture(u_image, final_uv);
}