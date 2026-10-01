shader_type canvas_item;
// Full-screen grade for the facility, drawn over the world and under the HUD.
// Containment Breach's look in three steps: drain most of the colour, push
// what is left toward a sick green-grey, then darken the edges and add grain.

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float desaturate : hint_range(0.0, 1.0) = 0.35;
uniform vec3 tint = vec3(0.94, 1.0, 0.93);
uniform float vignette : hint_range(0.0, 1.0) = 0.6;
uniform float grain : hint_range(0.0, 0.2) = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(luma), desaturate) * tint;
	// wider than tall, so the falloff follows the screen's shape
	vec2 d = (UV - 0.5) * vec2(1.25, 1.0);
	c *= 1.0 - vignette * smoothstep(0.3, 0.85, length(d));
	// grain steps ~24 times a second, like film. mod() keeps the hash input small,
	// since sin() of a large number loses precision and the grain turns to stripes
	c += (hash(floor(FRAGCOORD.xy / 2.0) + floor(mod(TIME * 24.0, 997.0))) - 0.5) * grain;
	COLOR = vec4(c, 1.0);
}
