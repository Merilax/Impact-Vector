// https://godotshaders.com/shader/color-swap-with-hue-variation-preservation
shader_type canvas_item;

// How to use:
// 1) Store the initial color in `from`
// 2) Store the target color in `to`
// 3) Adjust tolerance to grab a range of hues or set to 0 for exact match

uniform vec4 from : source_color;
uniform vec4 to : source_color;
uniform float tolerance: hint_range(0.0, 1.0);
uniform float brightness : hint_range(-1, 1) = 0;

mat4 brightnessMatrix( float _brightness ) {
    return mat4( vec4(1, 0, 0, 0),
                 vec4(0, 1, 0, 0),
                 vec4(0, 0, 1, 0),
                 vec4(_brightness, _brightness, _brightness, 1));
}

// Color space conversion from https://godotshaders.com/shader/color-range-swap/
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	// we usually want more granularity the closer we are to the original color
	float _tol = tolerance * tolerance;

	vec4 tex = texture(TEXTURE, UV);
	vec3 source_hsv = rgb2hsv(tex.rgb);
	vec3 initial_hsv = rgb2hsv(from.rgb);
	vec3 hsv_shift = rgb2hsv(to.rgb) - initial_hsv;

	float hue = initial_hsv.r;

	// the .r here represents HUE, .g is SATURATION, .b is LUMINANCE

if (hue - source_hsv.r >= -_tol && hue - source_hsv.r <= +_tol)
	{
		vec3 final_hsv = source_hsv + hsv_shift;
		tex.rgb = hsv2rgb(final_hsv);
	}
	COLOR = tex * brightnessMatrix( brightness );
}