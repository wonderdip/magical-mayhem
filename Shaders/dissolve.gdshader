shader_type canvas_item;

uniform vec2 position; // UV space (0–1)
uniform float radius = 0.1;
uniform float borderWidth = 0.02;
uniform float burnMult = 0.135;
uniform sampler2D noiseTexture;
uniform vec4 burnColor : source_color;

void fragment() {
	float noise = texture(noiseTexture, UV).b * burnMult;
	float dist = distance(UV, position) + noise;

	COLOR.rgb = mix(COLOR.rgb, burnColor.rgb, step(dist, radius + borderWidth));
	COLOR.a *= 1.0 - step(dist, radius);
}