shader_type canvas_item;

uniform sampler2D screenTexture : hint_screen_texture, filter_linear;
uniform vec2 velocity = vec2(0.0);

void fragment() {
	float jitter = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	vec4 color = vec4(0.0);
	float totalWeight = 0.0;
	const int SAMPLES = 16;
	for (int i = 0; i < SAMPLES; i++) {
		float t = (float(i) + jitter) / float(SAMPLES);
		float weight = 1.0 - t;
		color += texture(screenTexture, SCREEN_UV + velocity * t) * weight;
		totalWeight += weight;
	}
	COLOR = color / totalWeight;
}
